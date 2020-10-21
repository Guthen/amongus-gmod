util.AddNetworkString( "AmongUs:PlaySound" )
function AmongUs.PlaySound( path )
    net.Start( "AmongUs:PlaySound" )
        net.WriteString( path )
    net.Broadcast()
end

util.AddNetworkString( "AmongUs:ColorizeRagdoll" )

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
    local color = ply:GetPlayerColor()
    local new_ragdoll = ents.Create( "prop_ragdoll" )
    new_ragdoll:SetModel( ply:GetModel() )
    new_ragdoll:SetPos( ragdoll:GetPos() )
    new_ragdoll:SetAngles( ply:GetAngles() )
    new_ragdoll:SetCollisionGroup( COLLISION_GROUP_WORLD )
    function new_ragdoll:GetPlayerColor()
        return color
    end
    new_ragdoll:Spawn()

    --  > Network Ragdoll Color
    timer.Simple( 0.1, function()
        net.Start( "AmongUs:ColorizeRagdoll" )
            net.WriteEntity( new_ragdoll )
            net.WriteVector( color )
        net.Broadcast()    
    end )

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

        AmongUs.OpenSplashScreen( "report", { color = body:GetPlayerColor():ToColor() } )
        AmongUs.LaunchVoting( ply )
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
        local current_vent = ply:GetNWEntity( "AmongUs:Vent" )
        if not IsValid( current_vent ) then return end

        local role = AmongUs.GetRoleOf( ply )
        if role and not role.can_vent then return end

        for k, v in ipairs( ents.FindByClass( "au_vent" ) ) do
            if v:GetVentGroup() ~= current_vent:GetVentGroup() then continue end
            
            local ang = ( v:GetPos() - ply:EyePos() - AmongUs.ViewOffset ):Angle() - ply:GetAngles()
            ang:Normalize()

            local dist = 3
            if math.abs( ang.x ) < dist and math.abs( ang.y ) < dist then
                v:PlayerPressed( ply )

                return
            end
        end
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

--  > Tchat
util.AddNetworkString( "AmongUs:Tchat" )

AmongUs.TchatMessages = {}
function AmongUs.AddMessage( ply, text )
    local message = {
        player = ply,
        name = ply:GetName(),
        color = ply:GetPlayerColor(),
        text = text:sub( 0, AmongUs.Settings.LimitTchatLetters ), --  > crop to limit
        i_voted = AmongUs.Votes and AmongUs.Votes[ply] and AmongUs.Votes[ply].has_voted,
        dead = ply:Alive(),
    }
    AmongUs.TchatMessages[#AmongUs.TchatMessages + 1] = message

    net.Start( "AmongUs:Tchat" )
        net.WriteUInt( 1, 3 )
        net.WriteTable( { message } )
    if not ply:Alive() then -- > send message to ghosts
        net.SendOmit( AmongUs.GetAlivePlayers() )
    else --  > send message to everyone
        net.Broadcast()
    end

    --  > Test
    if not ply:IsBot() then
        timer.Simple( .5 + math.random() * 2, function()
            local bot = table.Random( player.GetBots() )
            if not IsValid( bot ) then return end
            if bot:Alive() == ply:Alive() then
                AmongUs.AddMessage( bot, "you sus" )
            end
        end )
    end
end

function GM:PlayerCanSeePlayersChat( text, team, listner, speaker ) --  > Disable default tchat
    return false
end

net.Receive( "AmongUs:Tchat", function( len, ply )
    local method = net.ReadUInt( 3 )
    --  > Add message
    if method == 1 then
        local text = net.ReadString()
        if #text > AmongUs.Settings.LimitTchatLetters then return end --  > haha you tried to bypass
        AmongUs.AddMessage( ply, text )
    --  > Send all messages
    elseif method == 2 then
        if #AmongUs.TchatMessages <= 0 then return end
        net.Start( "AmongUs:Tchat" )
            net.WriteUInt( 1, 3 )
            net.WriteTable( AmongUs.TchatMessages )
        net.Send( ply )
    end
end )