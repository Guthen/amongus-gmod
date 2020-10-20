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
function AmongUs.LaunchGame( force_impostors )
    AmongUs.GameOver = false
    AmongUs.Votes = nil

    --  > Clean
    game.CleanUpMap()

    --  > Give roles with a maximum capacity first
    local players, roles = player.GetAll(), table.Copy( AmongUs.Roles )
    for i, v in pairs( roles ) do
        if v.max then
            for i = 1, v.max() do
                local ply
                --  > Force impostors (by name)
                if force_impostors and #force_impostors > 0 then
                    for i, name in ipairs( force_impostors ) do
                        for k, p in ipairs( players ) do
                            if p:GetName() == name then
                                ply = p
                                table.remove( force_impostors, i )
                                table.remove( players, k )
                                break
                            end
                        end
                    end
                end

                --  > Random selection
                if not IsValid( ply ) then
                    ply = table.remove( players, math.random( #players ) )
                end

                if IsValid( ply ) then
                    AmongUs.SetRole( ply, v )
                end
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
        v:ScreenFade( SCREENFADE.IN, Color( 0, 0, 0 ), .25, 1 )

        if table.Count( colors ) > 0 then
            local color, name = table.Random( colors )
            colors[ name ] = nil

            if v:IsBot() then
                v:SetNWString( "AmongUs:FakeName", name )
            end

            set_color( v, color )
        else
            set_color( v, VectorRand( 0, 255 ) )

            if v:IsBot() then
                v:SetNWString( "AmongUs:FakeName", v:Name() )
            end
        end
    end

    --  > Set position
    AmongUs.RespawnAlivePlayers()

    --  > Open Start menu
    timer.Simple( .25, function()
        net.Start( "AmongUs:GameState" )
            net.WriteBool( true ) --  > starting
        net.Broadcast()
    end )

    print( "AmongUs: launched" )
end
concommand.Add( "au_launch_game", function( ply, cmd, args )
    AmongUs.LaunchGame( args )
end )

--  > Voting
AmongUs.Votes = nil

util.AddNetworkString( "AmongUs:Voting" )
local function send_voting( method, speaker, target )
    net.Start( "AmongUs:Voting" )
        net.WriteUInt( method, 3 ) --  > 0: start a vote session; 1: votes someone; 2: reveal votes; 3: clear votes
        if speaker then --  > 0: guy who start the vote session; 1: guy who votes someone; 3: player to be clear
            net.WriteEntity( speaker ) 
        end 
        if target then --  > 1: guy voted by player; 2: is tie; 3: table of voters to clear
            if isbool( target ) then 
                net.WriteBool( target ) 
            elseif istable( target ) then
                net.WriteTable( target )
            else
                net.WriteEntity( target ) 
            end
        end 
    net.Broadcast()
end

function AmongUs.LaunchVoting( speaker )
    --  > Reset votes
    AmongUs.Votes = {}

    --  > Freeze players
    local players = AmongUs.GetAlivePlayers()
    for i, v in ipairs( players ) do
        v:Freeze( true )
    end

    --  > Open tablet
    send_voting( 0, speaker )

    ---  > Prepare times
    timer.Create( "AmongUs:VoteBegins", AmongUs.Settings.DiscussionTime, 1, function()
        --  > Ready
        AmongUs.VotesBegins = true
        
        --  > Vote bots
        local players = AmongUs.GetAlivePlayers()
        players[ #players + 1 ] = AmongUs.SkipVoteID
        for i, v in ipairs( player.GetBots() ) do
            if not v:Alive() then continue end

            if v:IsBot() then
                timer.Simple( math.random() * 4, function()
                    AmongUs.PlayerVoteFor( v, table.Random( players ) )
                end )
            end
        end
    end )

    --  > Force Proceed
    timer.Create( "AmongUs:VoteEnds", AmongUs.Settings.DiscussionTime + AmongUs.Settings.VoteTime, 1, function()
        AmongUs.ProceedVotes()
    end )
end
concommand.Add( "au_launch_voting", AmongUs.LaunchVoting )

function AmongUs.PlayerVoteFor( ply, target )
    if not AmongUs.VotesBegins or not AmongUs.Votes then return end

    send_voting( 1, ply, isentity( target ) and target or NULL )

    --  > Count vote
    AmongUs.Votes[target] = AmongUs.Votes[target] or {}
    AmongUs.Votes[target][#AmongUs.Votes[target] + 1] = ply

    --print( ply:GetName() .. " voted for " .. ( isentity( target ) and target:GetName() or AmongUs.SkipVoteID ) )

    --  > Count votes
    AmongUs.CheckVotes()
end

function AmongUs.ProceedVotes()
    if not AmongUs.Votes then return end

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
    local sentence = isentity( voted ) and AmongUs.GetRoleOf( voted ):get_eject_sentence( voted )
    timer.Simple( AmongUs.Settings.ProceedingTime, function()
        --  > Eject
        if isentity( voted ) then
            if IsValid( voted ) then
                voted:KillSilent()
            end
            MsgAll( sentence )
        elseif voted == AmongUs.SkipVoteID then
            MsgAll( "No one was ejected. (Skipped)" )
        else
            MsgAll( "No One was ejected. (Tie)" )
        end

        --  > Clear Corpses
        for i, v in ipairs( ents.FindByClass( "prop_ragdoll" ) ) do
            v:Remove()
        end

        --  > Spawn players
        timer.Simple( AmongUs.Settings.EjectTime + .5, AmongUs.RespawnAlivePlayers )
    end )

    AmongUs.Votes = nil
    AmongUs.VotesBegins = false
    timer.Remove( "AmongUs:VoteEnds" )
end

function AmongUs.CheckVotes()
    if not AmongUs.Votes then return end

    local players = AmongUs.GetAlivePlayers()
    local votes = 0
    for k, v in pairs( AmongUs.Votes ) do
        votes = votes + #v
    end

    if votes == #players then
        AmongUs.ProceedVotes()
    end
end

net.Receive( "AmongUs:Voting", function( len, ply )
    if not AmongUs.Votes then return end
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

--  > Undo vote
function GM:PlayerDisconnected( ply )
    if AmongUs.Votes then
        local players = AmongUs.GetAlivePlayers()
        players[ #players + 1 ] = AmongUs.SkipVoteID

        local vote_remove = false
        for k, v in pairs( AmongUs.Votes ) do
            --  > Remove votes towards player
            if k == ply then
                send_voting( 3, ply, v )

                --  > Roll vote of bots
                for i, voter in ipairs( v ) do
                    if voter:IsBot() then
                        timer.Simple( math.random() * 4, function()
                            AmongUs.PlayerVoteFor( voter, table.Random( players ) )
                        end )
                    end
                end

                AmongUs.Votes[k] = nil
            end
            --  > Remove his vote
            if not vote_remove then
                for i, voter in ipairs( v ) do
                    if voter == ply then
                        table.remove( v, i )
                        vote_remove = true
                        break
                    end
                end
            end
        end

        AmongUs.CheckVotes()
    end
end

--  > Splash Screen
util.AddNetworkString( "AmongUs:SplashScreen" )
function AmongUs.OpenSplashScreen( type, info )
    net.Start( "AmongUs:SplashScreen" )
        net.WriteString( type )
        net.WriteTable( info or {} )
    net.Broadcast()
end