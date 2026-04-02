include("shared.lua")

function ENT:Draw()
	self:DrawModel()
	
	local ply = LocalPlayer()
	if not IsValid(ply) then return end
	
	-- Only draw the text if the player is within 500 units
	local dist = ply:GetPos():DistToSqr(self:GetPos())
	if dist > 250000 then return end 
	
	local ownerName = self:GetNetworkedString("Owner", "Unknown Loot")
	
	-- Make the text face the player
	local ang = LocalPlayer():EyeAngles()
	ang:RotateAroundAxis(ang:Forward(), 90)
	ang:RotateAroundAxis(ang:Right(), 90)
	
	-- Draw the floating text
	cam.Start3D2D(self:GetPos() + Vector(0, 0, 35), ang, 0.1)
		draw.SimpleTextOutlined(ownerName, "DermaLarge", 0, 0, Color(255, 215, 0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
		draw.SimpleTextOutlined("Press 'E' to Recover", "Trebuchet24", 0, 30, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
	cam.End3D2D()
end