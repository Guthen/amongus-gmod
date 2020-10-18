include( "shared.lua" )

AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

function ENT:Initialize()
    local ang = self:GetAngles()
    ang:RotateAroundAxis( self:GetForward(), 90 )
    self:SetAngles( ang )

    self:SetModel( "models/props_junk/vent001.mdl" )

	self:SetUseType( SIMPLE_USE )
end