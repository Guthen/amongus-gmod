
net.Receive( "AmongUs:Voting", function()
    local method = net.ReadUInt( 3 )
    
    --  > Open tablet
    local ply = net.ReadEntity()
    if method == 0 then
        AmongUs.OpenVoteTablet( ply )
    --  > Vote
    elseif method == 1 then
        local target = net.ReadEntity()
        if not IsValid( AmongUs.VotePanel ) then return end

        --  > Vote
        local main = AmongUs.VotePanel
        main.Lines[ply:UserID()].i_voted:SetVisible( true )
        if IsValid( target ) then
            main.Lines[target:UserID()].votes[#main.Lines[target:UserID()].votes + 1] = ply
        else
            main.Skip.votes[#main.Skip.votes + 1] = ply
        end
        surface.PlaySound( "amongus/vote.wav" )
    --  > Reveal votes
    elseif method == 2 then
        local tie = net.ReadBool()
        local main = AmongUs.VotePanel
        if not IsValid( main ) then return end
        main:ShowVotes()

        timer.Simple( AmongUs.Settings.ProceedingTime, function()
            AmongUs.OpenEjectScene( tie and "Tie" or IsValid( ply ) and ply or "Skip" )
        end )
    end
end )