include("shared.lua")

ENT.RenderGroup = RENDERGROUP_BOTH

-- Bubble Generator
function ENT:Think()
	local state = self:GetNWInt("State", 0)
	
	-- Only emit bubbles if diving or surfacing
	if state > 0 then
		self.BubbleTimer = self.BubbleTimer or 0
		if CurTime() > self.BubbleTimer then
			self.BubbleTimer = CurTime() + 0.05 

			local vOffset = self:GetPos() + Vector(0, 0, 20)

			local emitter = ParticleEmitter(vOffset, false)
			if IsValid(emitter) then
				local particle = emitter:Add("effects/bubble", vOffset + VectorRand() * 10)
				if particle then
					-- Bubbles float up regardless of dive/surface state
					particle:SetVelocity(Vector(0, 0, math.Rand(50, 100)) + VectorRand() * 10)
					particle:SetDieTime(3.0)
					particle:SetStartAlpha(200)
					particle:SetStartSize(math.Rand(2, 5))
					particle:SetEndSize(math.Rand(5, 10))
					particle:SetRoll(math.Rand(-0.2, 0.2))
					particle:SetColor(255, 255, 255)
				end
				emitter:Finish()
			end
		end
	end
end

-- The Holographic Status UI
function ENT:Draw()
	self:DrawModel()

	local fuel = self:GetNWInt("Fuel", 0)
	local state = self:GetNWInt("State", 0)
	local maxFuel = 1000

	local pos = self:GetPos() + self:GetRight() * 25 + self:GetUp() * 10
	local plyAng = LocalPlayer():EyeAngles()
	local ang = Angle(0, plyAng.y - 90, 90)

	cam.Start3D2D(pos, ang, 0.1)
		
		surface.SetDrawColor(0, 0, 0, 200)
		surface.DrawRect(-100, -30, 200, 60)

		local statusText = "NEUTRAL"
		local statusColor = Color(200, 200, 200)
		
		if state == 1 then
			statusText = "DIVING"
			statusColor = Color(0, 150, 255)
		elseif state == 2 then
			statusText = "SURFACING"
			statusColor = Color(0, 255, 0)
		end
		
		draw.SimpleText(statusText, "Trebuchet24", 0, -15, statusColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("Air Pressure: " .. fuel .. "/" .. maxFuel, "Trebuchet24", 0, 15, Color(0, 200, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		
	cam.End3D2D()
end