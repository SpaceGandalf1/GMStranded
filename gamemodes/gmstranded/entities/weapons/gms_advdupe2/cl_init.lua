include("shared.lua")

-- The base gmod_tool handles drawing the tool HUD (top right) and the prop ghosts.
-- Since we inherit from it and force the mode to "advdupe2" in shared.lua, 
-- the default Toolgun client logic will automatically take over and do the heavy lifting.

-- If you ever want to override the screen on the physical toolgun model itself 
-- to say something custom instead of the default, you would do it here:
function SWEP:DrawToolScreen( width, height )
    -- Right now, we just pass it back to the base toolgun to handle normally.
    if self.BaseClass and self.BaseClass.DrawToolScreen then
        self.BaseClass.DrawToolScreen( self, width, height )
    end
end