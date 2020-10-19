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
        ply:SetNoDraw( false )

        ply:SetPos( self:GetPos() )
        ply:SetNWEntity( "AmongUs:Vent", NULL )
        self:EmitSound( "amongus/vent_out.wav" )
    else -- > Enter a vent or switch from another
        ply:SetNoDraw( true )

        ply:SetPos( self:GetPos() - ply:GetUp() * 40 )
        ply:SetNWEntity( "AmongUs:Vent", self )

        if IsValid( current_vent ) then
            current_vent:EmitSound( "amongus/vent_move0" .. math.random( 1, 3 ) .. ".wav" )
        end

        self:EmitSound( IsValid( current_vent ) and "amongus/vent_move0" .. math.random( 1, 3 ) .. ".wav" or "amongus/vent_in.wav" )
    end
end

function ENT:UpdateTransmitState()	
	return TRANSMIT_ALWAYS 
end