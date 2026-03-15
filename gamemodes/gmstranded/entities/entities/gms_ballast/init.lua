AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	-- A good industrial model for a ballast tank
	self:SetModel("models/props_c17/canister01a.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:SetMass(150) -- Needs to be heavy to help sink
		phys:Wake()
	end
	
	self:StartMotionController()
	
	self.MaxFuel = 1000
	self.FuelPerTank = 500
	
	-- States: 0 = OFF, 1 = DIVE, 2 = SURFACE
	self:SetNWInt("State", 0) 
	self:SetNWInt("Fuel", 0)
end

function ENT:Use(activator, caller)
	if not IsValid(activator) or not activator:IsPlayer() then return end

	-- SHIFT + E: Refuel the Ballast with Oxygen
	if activator:KeyDown(IN_SPEED) then
		
		if activator:GetResource("oxygen_tank") >= 1 then
			local currentFuel = self:GetNWInt("Fuel", 0)
			
			if currentFuel < self.MaxFuel then
				activator:SubResource("oxygen_tank", 1) 
				
				local newFuel = math.Clamp(currentFuel + self.FuelPerTank, 0, self.MaxFuel)
				self:SetNWInt("Fuel", newFuel)
				
				self:EmitSound("items/suitchargeok1.wav", 75, 100)
				activator:PrintMessage(HUD_PRINTCENTER, "Ballast Pressurized!")
			else
				activator:PrintMessage(HUD_PRINTCENTER, "Ballast pressure is at maximum!")
			end
		else
			activator:PrintMessage(HUD_PRINTCENTER, "You need an Oxygen Tank to pressurize this!")
		end

	-- REGULAR E: Toggle States (Off -> Dive -> Surface -> Off)
	else
		if (self.NextToggle or 0) > CurTime() then return end
		self.NextToggle = CurTime() + 1
		
		local currentFuel = self:GetNWInt("Fuel", 0)
		local currentState = self:GetNWInt("State", 0)
		
		if currentFuel <= 0 and currentState == 0 then
			self:EmitSound("buttons/button10.wav", 75, 100)
			activator:PrintMessage(HUD_PRINTCENTER, "Not enough pressure!")
			return
		end

		-- Cycle the state
		local nextState = (currentState + 1) % 3
		self:SetNWInt("State", nextState)
		
		if nextState == 1 then
			self:EmitSound("ambient/water/water_flush1.wav", 75, 100) -- Venting air, taking in water
		elseif nextState == 2 then
			self:EmitSound("physics/surfaces/underwater_impact_bullet1.wav", 75, 100) -- Blowing ballast
		else
			self:EmitSound("vehicles/airboat/engine_stop.wav", 75, 100)
		end
	end
end

-- Global Vertical Physics
function ENT:PhysicsSimulate( phys, deltatime )
	local state = self:GetNWInt("State", 0)
	if state == 0 then return SIM_NOTHING end
	if self:GetNWInt("Fuel", 0) <= 0 then return SIM_NOTHING end

	local BallastWorldPos = phys:GetPos()
	local ForceAmount = 60000 -- Adjust this to balance submarine speed
	
	-- Global Z vector: Positive is up (surface), Negative is down (dive)
	local BallastWorldForce = Vector(0, 0, 0)
	if state == 1 then
		BallastWorldForce = Vector(0, 0, -ForceAmount)
	elseif state == 2 then
		BallastWorldForce = Vector(0, 0, ForceAmount)
	end
	
	local linear, angular = phys:CalculateVelocityOffset( BallastWorldForce, BallastWorldPos )
	return angular, phys:WorldToLocalVector(linear), SIM_LOCAL_ACCELERATION
end

-- Pressure Drain Logic
function ENT:Think()
	local state = self:GetNWInt("State", 0)
	
	if state > 0 then
		local currentFuel = self:GetNWInt("Fuel", 0)
		
		if currentFuel > 0 then
			self:SetNWInt("Fuel", currentFuel - 1)
			self:NextThink(CurTime() + 0.2)
			return true
		else
			self:SetNWInt("State", 0)
			self:EmitSound("vehicles/airboat/engine_stop.wav", 75, 80)
		end
	end
end