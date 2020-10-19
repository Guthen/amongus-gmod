util.AddNetworkString( "AmongUs:PlaySound" )
function AmongUs.PlaySound( path )
    net.Start( "AmongUs:PlaySound" )
        net.WriteString( path )
    net.Broadcast()
end

util.AddNetworkString( "AmongUs:ColorizeRagdoll" )

function GM:PlayerInitialSpawn( ply )
    --  > Get a fake name for bots
    if ply:IsBot() then
        ply:SetNWString( "AmongUs:FakeName", table.Random( AmongUs.BasePlayerClass.Names ) )
    end
end

concommand.Add( "au_reload_fake_names", function()
    for k, v in ipairs( player.GetBots() ) do
        v:SetNWString( "AmongUs:FakeName", table.Random( AmongUs.BasePlayerClass.Names ) )
    end
end )

function GM:PlayerSpawn( ply )
    player_manager.SetPlayerClass( ply, AmongUs.BasePlayerClass.Name )
    player_manager.RunClass( ply, "Loadout" )

    ply:SetCustomCollisionCheck( true )
end

function GM:PlayerDeathSound()
    return true
end

function GM:PlayerDeath( ply, inf, atk )
    local ragdoll = ply:GetRagdollEntity()

    --  > New ragdoll
    local new_ragdoll = ents.Create( "prop_ragdoll" )
    new_ragdoll:SetModel( ply:GetModel() )
    new_ragdoll:SetPos( ragdoll:GetPos() )
    new_ragdoll:SetAngles( ply:GetAngles() )
    new_ragdoll:Spawn()
    new_ragdoll:SetColor( ply:GetPlayerColor():ToColor() )
    new_ragdoll:SetCollisionGroup( COLLISION_GROUP_WORLD )
    --[[ print( new_ragdoll:GetPhysicsObject():SetMaterial( "player" ) )
 ]]
    -------------   > TODO: FIX RAGDOLLs COLOR
    --[[ net.Start( "AmongUs:ColorizeRagdoll" )
        net.WriteEntity( new_ragdoll )
        net.WriteVector( ply:GetPlayerColor() )
    net.Broadcast() ]]

    ragdoll:Remove()

    --  > Role Win
    AmongUs.CheckRoleWinner()
end

function GM:PlayerSilentDeath( ply )
    AmongUs.CheckRoleWinner()
end

function GM:PlayerDeathThink( ply )
    return true
end

--  > USE Commands
local use_checks = {
    --  > Body Report
    function( ply )
        local body = AmongUs.GetEntityAtTrace( ply, AmongUs.IsDeadBody, nil, true )
        if not body then return end

        AmongUs.LaunchVoting( ply )
        AmongUs.PlaySound( "amongus/report_body.wav" )
        return true
    end,

    --  > Usable & Vents
    function( ply )
        local usable = AmongUs.GetEntityAtTrace( ply, AmongUs.IsUseable, nil, true )
        if not usable then return end

        usable:PlayerPressed( ply )
        return true
    end,
}
function GM:KeyPress( ply, key )
    if AmongUs.GameOver then return end
    
    if key == IN_USE then
        for i, v in ipairs( use_checks ) do
            if v( ply ) then return end
        end
    elseif key == IN_ATTACK then
        if not IsValid( ply:GetNWEntity( "AmongUs:Vent" ) ) then return end

        --[[ local vent = AmongUs.GetEntityAtTrace( ply, function( ent ) 
            return AmongUs.IsVent( ent ) and not ( ply:GetNWEntity( "AmongUs:Vent" ) == ent )
        end, nil, true ) ]]
        local role = AmongUs.GetRoleOf( ply )
        if ( role and not role.can_vent ) then return end

        --local dir = ply:GetE
        if not vent then return end 

        --[[ print( vent, ply:GetNWEntity( "AmongUs:Vent" ) ) ]]

        vent:PlayerPressed( ply )
    end 
end

--  > Footsteps
local sounds = {
    concrete = { name = "tile0", max = 7 },
    metal = { name = "metal0", max = 8 },
}
function GM:PlayerFootstep( ply, pos, foot, path, volume, rf )
    local id = path:match( "player/footsteps/(%D+)" )
    local sound = sounds[id] or sounds["concrete"]
    --print( path, id, sound )
    
    ply:EmitSound( "amongus/footsteps/" .. sound.name .. math.random( 1, sound.max ) .. ".wav" )
    return true
end