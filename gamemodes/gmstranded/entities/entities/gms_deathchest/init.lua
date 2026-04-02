AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/treasurechest/treasurechest.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	
	self.contents = {}
	self.IsLooted = false
	
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:Wake()
		-- Relying on high mass and zero buoyancy for natural sinking
		phys:SetMass(500) 
		phys:SetBuoyancyRatio(0) 
		phys:SetMaterial("metal") 
	end
end

function ENT:Think()
	local phys = self:GetPhysicsObject()
	if not IsValid(phys) then return end

	-- Combined Attraction Mechanic (Average Location + Closest Neighbor)
	local myPos = self:GetPos()
	local sumPos = Vector(0, 0, 0)
	local count = 0
	local closestEnt = nil
	local closestDist = 2000 -- Detection radius

	-- Loop through all death chests to find the group center and the closest individual
	for _, ent in ipairs(ents.FindByClass("gms_deathchest")) do
		if ent == self or ent.IsLooted then continue end
		
		local dist = myPos:Distance(ent:GetPos())
		if dist < closestDist then
			-- Calculate Average (Centroid) data
			sumPos = sumPos + ent:GetPos()
			count = count + 1
			
			-- Track the Closest individual
			if not closestEnt or dist < myPos:Distance(closestEnt:GetPos()) then
				closestEnt = ent
			end
		end
	end

	-- Apply the combined force
	if count > 0 and IsValid(closestEnt) then
		local avgPos = sumPos / count
		local dirToAverage = (avgPos - myPos):GetNormalized()
		local dirToClosest = (closestEnt:GetPos() - myPos):GetNormalized()
		
		-- Average the two directions for a balanced pull
		local combinedDir = (dirToAverage + dirToClosest):GetNormalized()
		
		-- Add a slight upward lift (0.3 bias) to help navigate seafloor bumps
		local moveDir = (combinedDir + Vector(0, 0, 0.3)):GetNormalized()
		
		local forceAmount = phys:GetMass() * 8 
		phys:ApplyForceCenter(moveDir * forceAmount)
	end

	self:NextThink(CurTime() + 0.5) 
	return true
end

-- Merging Logic: When two chests touch, consolidate them into one
function ENT:PhysicsCollide(data, phys)
	local ent = data.HitEntity
	if IsValid(ent) and ent:GetClass() == "gms_deathchest" then
		-- Only the older entity (lower index) absorbs the newer one
		if self:EntIndex() < ent:EntIndex() then
			for res, amt in pairs(ent.contents) do
				self.contents[res] = (self.contents[res] or 0) + amt
			end
			
			self:EmitSound("physics/cardboard/cardboard_box_impact_soft1.wav", 70, 80)
			self:SetNetworkedString("Owner", "Combined Lost Loot")
			
			ent.IsLooted = true 
			ent:Remove()
		end
	end
end

function ENT:Use(activator, caller)
	if not IsValid(activator) or not activator:IsPlayer() then return end
	if self.IsLooted then return end
	
	-- Integration with Stranded process state to prevent overlapping actions
	if activator.inprocess == true then return end 

	self:StartLooting(activator)
end

function ENT:StartLooting(ply)
	local lootTime = 5 
	
	ply:Freeze(true)
	ply.inprocess = true
	ply.processtype = "gathering"
	
	ply.sound = CreateSound(ply, "physics/cardboard/cardboard_box_scrape_smooth_loop1.wav")
	ply.sound:Play()
	
	ply:SetNWString("action", "Opening Chest...")
	SGS_StartTimer(ply, "Opening Chest...", lootTime) 
	
	timer.Create(ply:UniqueID() .. "chesttimer", lootTime, 1, function() 
		if IsValid(self) then self:StopLooting(ply) end
	end)
end

function ENT:StopLooting(ply)
	if not IsValid(ply) then return end
	
	ply:Freeze(false)
	ply.inprocess = false
	ply.processtype = "idle"
	ply:SetNWString("action", "Idle")
	
	if ply.sound then ply.sound:Stop() end
	
	if self.IsLooted then return end 
	self.IsLooted = true

	local foundLoot = false
	for resType, amt in pairs(self.contents) do
		if amt > 0 then
			-- Add recovered items back to player inventory
			ply:AddResource(resType, amt) 
			foundLoot = true
		end
	end
	
	if foundLoot then
		ply:EmitSound("items/ammo_pickup.wav", 65, 100, 0.5)
		ply:SendMessage("You recovered the lost loot!", 60, Color(0, 255, 0))
	else
		ply:SendMessage("The chest was empty.", 60, Color(255, 100, 100))
	end
	
	self:Remove()
end