include( "shared.lua" )

AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

function ENT:Initialize()
    self:SetModel( "models/props_junk/vent001.mdl" )

    self:SetUseType( SIMPLE_USE )
end

function ENT:KeyValue( key, value )
    if key == "vent_group" then
        self:SetVentGroup( value )
    end
end

function ENT:PlayerPressed( ply )

end