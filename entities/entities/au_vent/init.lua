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

function ENT:KeyValue( key, value )
    if key == "vent_group" then
        self:SetVentGroup( value )
    end
end

function ENT:PlayerPressed( ply )
    --  > Check
    local role = AmongUs.GetRoleOf( ply )
    if role and not role.can_vent then return end

    --  > Use
    local current_vent = ply:GetNWEntity( "AmongUs:Vent" )
    if IsValid( current_vent ) and current_vent == self then -- > Leave the vent
        ply:SetPos( self:GetPos() )
        ply:SetNWEntity( "AmongUs:Vent", NULL )
    else -- > Enter a vent or switch from another
        ply:SetPos( self:GetPos() - ply:GetUp() * 40 )
        ply:SetNWEntity( "AmongUs:Vent", self )
    end
end