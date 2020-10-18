AmongUs.SkipVoteID = "Skip" --  > just to be consistent on client and server

function AmongUs.GetAlivePlayers()
    local plys = {}

    for i, v in ipairs( player.GetAll() ) do
        if v:Alive() then plys[#plys + 1] = v end
    end

    return plys
end

function AmongUs.IsDeadBody( ent )
    return IsValid( ent ) and ent:GetClass() == "prop_ragdoll"
end

function AmongUs.IsUseable( ent )
    return IsValid( ent ) and ent.AmongUsUsable
end

function AmongUs.IsVent( ent )
    return IsValid( ent ) and ent:GetClass() == "au_vent"
end

AmongUs.ViewOffset = Vector( 0, 0, 12 )
function AmongUs.GetEntityAtTrace( ply, filter, radius, use_distance )
    local pos = util.TraceLine( {
        start = ply:EyePos() - AmongUs.ViewOffset,
        endpos = ply:EyePos() - AmongUs.ViewOffset + ply:EyeAngles():Forward() * 32768,
        filter = filter
    } ).HitPos

    --local pos = ply:GetEyeTrace().HitPos
    for i, v in ipairs( ents.FindInSphere( pos, radius or 5 ) ) do
        if filter( v ) then 
            if use_distance and v:GetPos():Distance( ply:GetPos() ) > AmongUs.Settings.UseDistance then continue end
            return v
        end
    end
end

function GM:StartCommand( ply, cmd )
    if ply:IsBot() then
        cmd:ClearMovement()
    end

    --  > Remove Jump, Alt-Walking and Crouch abilities
    cmd:RemoveKey( IN_JUMP )
    cmd:RemoveKey( IN_DUCK )
    cmd:RemoveKey( IN_WALK )
end

function GM:ShouldCollide( ent_1, ent_2 )
    if ent_1:IsPlayer() and ent_2:IsPlayer() then return false end

    return true
end

--  > Disable spawn sound
sound.Add( {
    name = "Player.DrownStart",
    channel = CHAN_STATIC,
    volume = 0,
    level = 0,
    pitch = 0,
    sound = "amongus/spawn.wav"
} )