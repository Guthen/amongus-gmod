AddCSLuaFile()

ENT.Base = "base_entity"
ENT.Type = "anim"
ENT.AmongUsUsable = true

ENT.Author = "Nogitsu"
ENT.Spawnable = false

function ENT:Initialize()
    self:SetModel( "models/dav0r/buttons/button.mdl" )
    self:SetModelScale( 2, 0 )
end

function ENT:Draw() --  > yea, it's needed to show the entity
    self:DrawModel()
end

function ENT:PlayerPressed( ply ) --  > custom hook (cuz ENT:Use doesn't work here and isn't suit for custom Use press)
    if AmongUs.GameOver or AmongUs.Votes then return end

    AmongUs.OpenSplashScreen( "emergency", { color = ply:GetPlayerColor():ToColor() } )
    AmongUs.LaunchVoting( ply )
end

--[[ if SERVER then
    local function create_emergency_button( ply )
        for k, v in ipairs( ents.FindByClass( "au_emergency_button" ) ) do
            v:Remove()
        end

        local button = ents.Create( "au_emergency_button" )
        if IsValid( ply ) then button:SetPos( ply:GetEyeTrace().HitPos ) end
        button:Spawn()

        print( IsValid( button ) )
    end

    concommand.Add( "au_create_emergency_button", create_emergency_button )
    hook.Add( "InitPostEntity", "AmongUs:EmergencyButton", create_emergency_button )
end ]]