util.AddNetworkString( "AmongUs:GameState" )
function AmongUs.CheckRoleWinner()
    if timer.Exists( "AmongUs:NextGame" ) then return end
    timer.Create( "AmongUs:RoleWinCheck", 0, 1, function() 
        for i, v in ipairs( AmongUs.Roles ) do
            if v.has_won and v:has_won() then
                timer.Simple( 1, function()
                    net.Start( "AmongUs:GameState" )
                        net.WriteBool( false ) --  > ending
                        net.WriteUInt( i, 7 ) --  > role winner
                    net.Broadcast()
                end )

                AmongUs.GameOver = true
                timer.Create( "AmongUs:NextGame", 8, 1, function()
                    for i, v in ipairs( player.GetAll() ) do
                        v:SetTeam( TEAM_UNASSIGNED )
                        v:Spawn()
                    end
                end )
                break
            end
        end
    end )
end

function AmongUs.RespawnAlivePlayers()
    local players = AmongUs.GetAlivePlayers()
    local ang = 0
    local radius = math.max( 200, #players * 16 )
    local origin = Vector( 0, 0, 0 )

    for i, v in ipairs( players ) do
        ang = i * math.rad( 360 / #players )
        v:SetPos( origin + Vector( math.cos( ang ) * radius, math.sin( ang ) * radius, 0 ) )
        v:SetEyeAngles( ( origin - v:GetPos() ):Angle() )
        v:DropToFloor()
        v:Freeze( false )

        --  > Reset weapons
        for kw, w in ipairs( v:GetWeapons() ) do
            w:Equip()
        end
    end
end

AmongUs.GameOver = true
function AmongUs.LaunchGame()
    AmongUs.GameOver = false

    --  > Clean
    game.CleanUpMap()

    --  > Give roles with a maximum capacity first
    local players, roles = player.GetAll(), table.Copy( AmongUs.Roles )
    for i, v in pairs( roles ) do
        if v.max then
            for i = 1, v.max() do
                local id = math.random( #players )
                local ply = players[id]

                AmongUs.SetRole( ply, v )
                table.remove( players, id )
            end

            table.remove( roles, i )
        end
    end

    --  > Give last roles
    for i, v in ipairs( players ) do
        AmongUs.SetRole( v, math.random( #roles ) )
    end

    --  > Give color
    local function set_color( ply, color )
        ply:SetPlayerColor( Vector( color.r / 255, color.g / 255, color.b / 255 ) )
    end

    --  > Set Color
    local colors = table.Copy( AmongUs.Settings.Colors )
    for i, v in ipairs( player.GetAll() ) do
        v:Spawn()
        if #colors > 0 then
            local color = table.remove( colors, math.random( #colors ) )
            set_color( v, color )
        else
            set_color( v, VectorRand( 0, 255 ) )
        end
    end

    --  > Set position
    AmongUs.RespawnAlivePlayers()

    --  > Open Start menu
    timer.Simple( .15, function()
        net.Start( "AmongUs:GameState" )
            net.WriteBool( true ) --  > starting
        net.Broadcast()
    end )

    print( "AmongUs: launched" )
end
concommand.Add( "au_launch_game", AmongUs.LaunchGame )

--  > Voting
AmongUs.Votes = nil

util.AddNetworkString( "AmongUs:Voting" )
local function send_voting( method, speaker, target )
    net.Start( "AmongUs:Voting" )
        net.WriteUInt( method, 3 ) --  > 0: start a vote session; 1: votes someone; 2: reveal votes
        if speaker then net.WriteEntity( speaker ) end --  > 0: guy who start the vote session; 1: guy who votes someone
        if target then --  > 1: guy voted by player; 2: is tie
            if isbool( target ) then 
                net.WriteBool( target ) 
            else
                net.WriteEntity( target ) 
            end
        end 
    net.Broadcast()
end

function AmongUs.LaunchVoting( speaker )
    game.CleanUpMap()

    --  > Reset votes
    AmongUs.Votes = {}

    --  > Freeze players
    local players = AmongUs.GetAlivePlayers()
    for i, v in ipairs( players ) do
        v:Freeze( true )
    end

    players[ #players + 1 ] = AmongUs.SkipVoteID
    for i, v in ipairs( player.GetBots() ) do
        if not v:Alive() then continue end
        --  > Vote bots
        if v:IsBot() then
            timer.Simple( math.random() * 4, function()
                AmongUs.PlayerVoteFor( v, table.Random( players ) )
            end )
        end
    end

    --  > Open tablet
    send_voting( 0, speaker )
end
concommand.Add( "au_launch_voting", AmongUs.LaunchVoting )

function AmongUs.PlayerVoteFor( ply, target )
    send_voting( 1, ply, isentity( target ) and target or NULL )

    --  > Count vote
    AmongUs.Votes[target] = AmongUs.Votes[target] or {}
    AmongUs.Votes[target][#AmongUs.Votes[target] + 1] = ply

    --print( ply:GetName() .. " voted for " .. ( isentity( target ) and target:GetName() or AmongUs.SkipVoteID ) )

    --  > Count votes
    local players = AmongUs.GetAlivePlayers()
    local votes = 0
    for k, v in pairs( AmongUs.Votes ) do
        votes = votes + #v
    end

    if votes == #players then
        --  > Get voted player
        local voted, max_votes = nil, 0
        for k, v in pairs( AmongUs.Votes ) do
            if #v > max_votes then
                max_votes = #v
                voted = k
            elseif #v == max_votes then
                voted = nil
            end
        end

        --  > Reveal votes
        send_voting( 2, isentity( voted ) and voted or NULL, not ( voted == AmongUs.SkipVoteID ) )

        --  > Proceeding Game
        timer.Simple( AmongUs.Settings.ProceedingTime, function()
            --  > Eject
            if isentity( voted ) then
                MsgAll( AmongUs.GetRoleOf( voted ):get_eject_sentence( voted ) )
                voted:KillSilent()
            elseif voted == AmongUs.SkipVoteID then
                MsgAll( "No one was ejected. (Skipped)" )
            else
                MsgAll( "No One was ejected. (Tie)" )
            end

            --  > Spawn players
            timer.Simple( AmongUs.Settings.EjectTime + 1, AmongUs.RespawnAlivePlayers )
        end )

        AmongUs.Votes = nil
    end
end

net.Receive( "AmongUs:Voting", function( len, ply )
    if not ply:Alive() then return end

    local target = net.ReadEntity()

    --  > Check if has already voted
    for target, votes in pairs( AmongUs.Votes ) do
        for i, v in ipairs( votes ) do
            if v == ply then return end
        end
    end

    --  > Vote
    AmongUs.PlayerVoteFor( ply, IsValid( target ) and target or "AmongUs.SkipVoteID" )
end )