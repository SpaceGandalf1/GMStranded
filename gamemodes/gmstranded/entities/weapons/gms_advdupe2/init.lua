AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

-- 1. Intercept the spawn attempt to allow AdvDupe2 to place it temporarily
hook.Add("PlayerSpawnSENT", "GMS_AdvDupe2_CheckGMSProp", function(ply, class)
    if class == "gms_prop" then
        local wep = ply:GetActiveWeapon()
        -- UPDATED CHECK: Now checks for the custom gms_advdupe2 weapon class
        local isUsingAdvDupe = IsValid(wep) and wep:GetClass() == "gms_advdupe2"
        
        if isUsingAdvDupe then
            return true -- Explicitly allow it so it spawns and we can check its model
        end
    end
end)

-- 2. After it spawns, find its exact cost in the build menu and charge the player
hook.Add("PlayerSpawnedSENT", "GMS_AdvDupe2_ChargeGMSProp", function(ply, ent)
    if ent:GetClass() == "gms_prop" then
        local wep = ply:GetActiveWeapon()
        -- UPDATED CHECK: Now checks for the custom gms_advdupe2 weapon class
        local isUsingAdvDupe = IsValid(wep) and wep:GetClass() == "gms_advdupe2"
        
        if isUsingAdvDupe then
            -- Normalize the model string so it matches the ones in your prop list
            local model = string.lower(ent:GetModel() or "")
            local propCost = nil
            local propName = "Prop"
            
            -- ==========================================
            -- A. FIND EXACT COST FROM sh_proplist.lua
            -- ==========================================
            -- SGS.props is the global table created by your prop list file
            if SGS and SGS.props then
                for category, items in pairs(SGS.props) do
                    for _, itemData in pairs(items) do
                        if itemData.model and string.lower(itemData.model) == model then
                            propCost = itemData.cost
                            propName = itemData.title or propName
                            break
                        end
                    end
                    if propCost then break end
                end
            end
            
            -- ==========================================
            -- B. CHECK RESOURCES AND CHARGE
            -- ==========================================
            if not propCost then
                -- The model wasn't found in your build menu! 
                -- Delete it immediately to prevent them from pasting illegal/free props.
                ent:Remove()
                ply:SendMessage("You cannot duplicate unapproved models!", 3, Color(255, 0, 0))
                return
            end
            
            -- Check if the player has enough of EVERY resource required
            local canAfford = true
            for resName, amount in pairs(propCost) do
                if ply:GetResource(resName) < amount then
                    canAfford = false
                    break
                end
            end
            
            if canAfford then
                -- Deduct the exact resources from the player's inventory
                for resName, amount in pairs(propCost) do
                    ply:DecResource(resName, amount)
                end
                
                -- ==========================================
                -- C. APPLY NORMAL GMS_PROP BEHAVIOR
                -- ==========================================
                ent.spawning = true
                ent.ToTime = 3 
                ent.EdTime = CurTime() + ent.ToTime
                
                local phys = ent:GetPhysicsObject()
                if IsValid(phys) then
                    phys:EnableMotion(false)
                end
                
                ent.Owner = ply
                
            else
                -- Player is too poor! Delete the prop and tell them what they are missing.
                ent:Remove()
                
                -- Format a nice string showing them what they needed
                local costString = ""
                for resName, amount in pairs(propCost) do
                    costString = costString .. amount .. " " .. string.Capitalize(resName) .. ", "
                end
                costString = string.sub(costString, 1, -3) -- Remove the trailing comma
                
                ply:SendMessage("Not enough resources to paste " .. propName .. "! (Need: " .. costString .. ")", 3, Color(255, 0, 0))
            end
        end
    end
end)