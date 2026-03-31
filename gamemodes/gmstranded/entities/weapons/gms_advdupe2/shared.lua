if SERVER then
    AddCSLuaFile("shared.lua")
    SWEP.Weight             = 5
    SWEP.AutoSwitchTo       = false
    SWEP.AutoSwitchFrom     = false
end

if CLIENT then
    SWEP.PrintName          = "Adv Dupe 2"
    SWEP.DrawAmmo           = false
    SWEP.DrawCrosshair      = true
    SWEP.ViewModelFOV       = 55
    SWEP.ViewModelFlip      = false
    SWEP.CSMuzzleFlashes    = false
    SWEP.Slot               = 4
    SWEP.SlotPos            = 5 -- Adjust this to place it where you want in the tool hotbar
end

SWEP.Author         = "Wiremod & GMStranded"
SWEP.Contact        = ""
SWEP.Purpose        = "Advanced Duplicator 2"
SWEP.Instructions   = "Primary: Paste. Secondary: Copy. Reload: Rotate/Cancel. [E + Reload]: Open UI."

SWEP.Spawnable          = false
SWEP.AdminSpawnable     = false

-- THIS IS THE MAGIC: We inherit the standard GMod Toolgun completely
SWEP.Base = "gmod_tool" 

SWEP.ViewModel          = "models/weapons/v_toolgun.mdl"
SWEP.WorldModel         = "models/weapons/w_toolgun.mdl"

SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = false
SWEP.Primary.Ammo           = "none"

SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo         = "none"

-- Override the engine's tool check to force this SWEP to ALWAYS be AdvDupe2
function SWEP:GetMode()
    return "advdupe2"
end

-- We need a way to open the UI since the Q-Menu is disabled.
-- We will hijack the Reload key, but ONLY if they are holding USE (E).
function SWEP:Reload()
    if not IsValid(self.Owner) then return end
    
    -- Check if they are holding USE (E) while pressing Reload (R)
    if self.Owner:KeyDown(IN_USE) then
        if CLIENT and IsFirstTimePredicted() then
            self:OpenAdvDupeMenu()
        end
        
        -- Prevent spamming the menu
        self:SetNextPrimaryFire(CurTime() + 0.5)
        self:SetNextSecondaryFire(CurTime() + 0.5)
        return
    end
    
    -- If they aren't holding E, run the normal AdvDupe2 Reload logic (Rotate/Cancel selection)
    if self.BaseClass.Reload then
        self.BaseClass.Reload(self)
    end
end

if CLIENT then
    local AD2MenuFrame
    
    function SWEP:OpenAdvDupeMenu()
        -- If the menu is already built, just toggle it on/off
        if IsValid(AD2MenuFrame) then
            AD2MenuFrame:SetVisible(not AD2MenuFrame:IsVisible())
            if AD2MenuFrame:IsVisible() then 
                AD2MenuFrame:MakePopup() 
            end
            return
        end

        -- Create a new draggable popup window for the File Browser
        AD2MenuFrame = vgui.Create("DFrame")
        AD2MenuFrame:SetSize(350, 600)
        AD2MenuFrame:SetTitle("Advanced Duplicator 2")
        AD2MenuFrame:Center()
        AD2MenuFrame:MakePopup()
        -- We hide it on close instead of deleting it so they don't lose their place in the file browser
        AD2MenuFrame.OnClose = function(s) s:SetVisible(false) return true end 

        local scroll = vgui.Create("DScrollPanel", AD2MenuFrame)
        scroll:Dock(FILL)

        -- Create a fake Tool Control Panel to trick AdvDupe2 into building its UI
        local cp = vgui.Create("ControlPanel", scroll)
        cp:Dock(FILL)
        cp:SetPadding(10)

        -- Call the official AdvDupe2 UI builder script
        if AdvDupe2 and AdvDupe2.BuildCPanel then
            AdvDupe2.BuildCPanel(cp)
        end
    end
end