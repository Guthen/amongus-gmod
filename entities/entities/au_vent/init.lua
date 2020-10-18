include( "shared.lua" )

AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

function ENT:Initialize()
    self:SetModel( "models/hunter/plates/plate2x4.mdl" )

	self:SetUseType( SIMPLE_USE )
end