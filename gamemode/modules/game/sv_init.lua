function AmongUs.CheckRoleWinner()
    timer.Create( "AmongUs:RoleWinCheck", .5, 1, function() 
        for i, v in ipairs( AmongUs.Roles ) do
            if v.has_won and v:has_won() then
                print( v.name .. " won!" )
                timer.Simple( 1, AmongUs.LaunchGame )
                break
            end
        end
    end )
end

function AmongUs.LaunchGame()
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

    --  > Give colors
    local function set_color( ply, color )
        ply:SetPlayerColor( Vector( color.r / 255, color.g / 255, color.b / 255 ) )
    end

    local colors = table.Copy( AmongUs.Settings.Colors )
    for i, v in ipairs( player.GetAll() ) do
        if #colors > 0 then
            local color = table.remove( colors, math.random( #colors ) )
            set_color( v, color )
        else
            set_color( v, VectorRand( 0, 255 ) )
        end
    end

    print( "AmongUs: launched" )
end
concommand.Add( "au_launch_game", AmongUs.LaunchGame )

--  > Voting
AmongUs.Votes = {}

util.AddNetworkString( "AmongUs:Voting" )
local function send_voting( method, speaker, target )
    net.Start( "AmongUs:Voting" )
        net.WriteUInt( method, 3 ) --  > 0: start a vote session; 1: votes someone; 2: reveal votes
        if speaker then net.WriteEntity( speaker ) end --  > 0: guy who start the vote session; 1: guy who votes someone
        if target then net.WriteEntity( target ) end --  > 1: guy voted by player
    net.Broadcast()
end

function AmongUs.LaunchVoting( speaker )
    game.CleanUpMap()

    --  > Reset votes
    AmongUs.Votes = {}

    --  > Spawn every alived players
    local players = AmongUs.GetAlivePlayers()
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
    send_voting( 1, ply, target )

    --  > Count vote
    AmongUs.Votes[target] = AmongUs.Votes[target] or {}
    AmongUs.Votes[target][#AmongUs.Votes[target] + 1] = ply

    print( ply:GetName() .. " voted for " .. target:GetName() )

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
        send_voting( 2, voted )
        
        --  > Proceeding Game
        timer.Simple( AmongUs.Settings.ProceedingTime, function()
            --  > Eject
            if IsValid( voted ) then
                MsgAll( AmongUs.GetRoleOf( voted ):get_eject_sentence( voted ) )
                voted:KillSilent()
            else
                print( "No One is ejected (Tie)" )
            end

            --  > Spawn players
            for i, v in ipairs( players ) do
                if v == voted then continue end
                v:Spawn()
            end
        end )
    end
end

net.Receive( "AmongUs:Voting", function( len, ply )
    if not ply:Alive() then return end

    local target = net.ReadEntity()
    if not IsValid( target ) then return end

    --  > Check if has already voted
    for target, votes in pairs( AmongUs.Votes ) do
        for i, v in ipairs( votes ) do
            if v == ply then return end
        end
    end

    --  > Vote
    AmongUs.PlayerVoteFor( ply, target )
end )