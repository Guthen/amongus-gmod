AmongUs.VotePanel = nil

local votes = {}
local background_color = Color( 170, 200, 229 )
local line_color, line_shadow_color, line_disable_color = Color( 233, 241, 248 ), Color( 114, 134, 153 ), Color( 148, 156, 163 )

local w, h = ScrW() * .75, ScrH() * .9
local padding = h * .022
local speaker = Material( "amongus/speaker.png" )
local function create_model( ply, parent, x, y, size )
    if not IsValid( ply ) then return end

    local model = parent:Add( "DModelPanel" )
    model:SetPos( x, y )
    model:SetSize( size, size )
    model:SetFOV( 40 )
    model:SetModel( AmongUs.BasePlayerClass.Model )
    function model:LayoutEntity( ent )
        local eyepos = ent:GetBonePosition( 6 )
    
        self:SetLookAt( eyepos )
        self:SetCamPos( eyepos + Vector( 45, -15, 0 ) )
    end
    function model:PreDrawModel( ent )
        if not IsValid( AmongUs.VotePanel ) then return end
        local alpha = AmongUs.VotePanel:GetAlpha()
        render.ResetModelLighting( alpha / 255, alpha / 255, alpha / 255 )
    end
    local color = ply:GetPlayerColor()
    function model.Entity:GetPlayerColor()
        return color
    end

    return model
end

local function size_from( panel, width, height, time )
    local to_width, to_height = panel:GetSize()
    panel:SetSize( width, height )
    panel:SizeTo( to_width, to_height, time, 0 )
    --panel:MoveTo( panel.x + ( width - to_width ) / 2, panel.y + ( height - to_height ) / 2, time )
end

local function create_line( container, ply, w, h, is_speaker )
    local role = AmongUs.GetRoleOf( ply )
    local text, color = ply:GetName(), role and role:get_name_color( AmongUs.GetRoleOf( LocalPlayer() ) ) or color_white

    --  > Main
    local line, model = container:Add( "DButton" )
    line:SetSize( w / 2 - padding * 2, h * .125 )
    line:InvalidateParent( true )
    line.is_active = IsValid( ply ) and ply:Alive()
    line.player = ply
    line.votes = {}
    function line:Paint( w, h )
        self.is_active = AmongUs.VotePanel.time_id >= 2 and IsValid( ply ) and ply:Alive()

        --  > Shadow
        local space = w * .007
        draw.RoundedBox( 8, space, space, w - space, h - space, line_shadow_color )

        --  > Line
        draw.RoundedBox( 8, 0, 0, w - space, h - space, self.is_active and line_color or line_disable_color )
    
        --  > Name
        local color = color
        if not self.is_active then color = ColorAlpha( color, 100 ) end
        AmongUs.DrawText( text, model:GetWide() + padding, padding * .35, color, nil, TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT )
    
        --  > Speaker
        if is_speaker then
            AmongUs.DrawMaterial( speaker, w * .8, 1, h, h - space )
        end

        return true
    end
    function line:DoClick()
        if AmongUs.VotePanel.time_id >= #AmongUs.VotePanel.times then return end
        if not self.is_active or AmongUs.VotePanel.Lines[LocalPlayer():UserID()].i_voted:IsVisible() then return end

        --  > Remove button
        if IsValid( container.yes ) and IsValid( container.no ) then
            container:RemoveVoteButtons()
            if container.yes:GetParent() == self then return end
        end

        --  > Create votes buttons
        local button_size = self:GetTall() * .75
        container:CreateVoteButtons( self:GetWide() - button_size - padding, self, button_size )
    end

    --  > ModelPanel
    local padding = padding / 2

    --  > Crew Model
    model = create_model( ply, line, padding, padding * .5, line:GetTall() - padding * 2 )
    line.model = model

    --  > Dead Cross
    if not IsValid( ply ) or not ply:Alive() then
        local x, y = container.x + line.x + model.x, container.y + line.y + model.y
        local w, h = model:GetSize()

        local space = padding * 2
        local image = container:GetParent():Add( "DImage" )
        image:SetPos( x - space, y - space )
        image:SetSize( w + space * 2, h + space * 2 )
        image:SetImage( "amongus/cross.png" )

        --  > Animation
        local time = 1.25
        space = padding * .25
        image:MoveTo( x - space, y - space, time )
        image:SizeTo( w + space * 2, h + space * 2, time )
    end

    --  > I voted
    local voted_size = w * .0375
    local image = AmongUs.VotePanel.content.scroll:Add( "DImage" )
    image:SetPos( container.x + line.x - padding, container.y + line.y - padding )
    image:SetSize( voted_size, voted_size )
    image:SetImage( "amongus/voted.png" )
    image:SetVisible( false )
    image:NoClipping( true )
    line.i_voted = image

    return line
end

local tablet, skip = Material( "amongus/tablet.png" )
function AmongUs.OpenVoteTablet( speaker, time_delay )
    if IsValid( AmongUs.VotePanel ) then AmongUs.VotePanel:Remove() end

    local start = CurTime()
    local main = vgui.Create( "DFrame" )
    main:SetDraggable( false )
    main:SetSizable( false )
    main:ShowCloseButton( false )
    main:SetTitle( "" )
    main:SetSize( w, h )
    main:Center()
    main:MakePopup()
    function main:Paint( w, h )
        --  > Blur
        Derma_DrawBackgroundBlur( self, start )

        --  > Tablet Image
        surface.SetDrawColor( color_white )
        surface.SetMaterial( tablet )
        surface.DrawTexturedRect( 0, 0, w, h )
    end
    function main:OnRemove()
        if IsValid( AmongUs.TchatPanel ) then
            AmongUs.TchatPanel:Remove()
        end
    end
    AmongUs.VotePanel = main

    --  > Content
    local content = main:Add( "DPanel" )
    content:SetPos( w * 65 / tablet:Width(), h * 59 / tablet:Height() )
    content:SetSize( w * 1385 / tablet:Width() - content.x, h * 974 / tablet:Height() - content.y )
    content:DockPadding( padding, padding, padding, padding )
    function content:Paint( w, h )
        draw.RoundedBox( 16, 0, 0, w, h, background_color )
    end
    main.content = content
    local w, h = content:GetSize()

    --  > Title
    local title = content:Add( "DPanel" )
    title:Dock( TOP )
    title:SetHeight( h * .09 )
    function title:Paint( w, h )
        AmongUs.DrawText( main.time_id == #main.times and "Voting Results" or "Who Is The Impostor?", w / 2, h / 2, nil, "AmongUs:Medium" )
    end

    --  > Tchat
    AmongUs.TchatDialog:SetParent( content )
    AmongUs.TchatDialog:SetPos( content:GetWide() - AmongUs.TchatDialog:GetWide() - padding / 2, padding / 2 )
    main.notification = AmongUs.TchatDialog.notification

    --  > Players
    local players = player.GetAll()
    table.sort( players, function( a, b ) return a:Alive() and not b:Alive() end )

    --  > Scroll Panel
    local scroll = content:Add( "DScrollPanel" )
    scroll:Dock( FILL )
    scroll:DockMargin( 0, padding, 0, 0 )
    scroll:GetVBar():SetWide( 0 )
    scroll:InvalidateParent( true )
    content.scroll = scroll

    --  > Container
    local container = scroll:Add( "DIconLayout" )
    container:SetSize( scroll:GetSize() )
    container:SetSpaceX( padding )
    container:SetSpaceY( padding )
    function container:RemoveVoteButtons()
        if IsValid( self.yes ) then self.yes:Remove() end
        if IsValid( self.no ) then self.no:Remove() end
    end
    function container:CreateVoteButtons( x, parent, button_size, space )
        if not LocalPlayer():Alive() then return end

        --  > No
        local no = parent:Add( "DImageButton" )
        no.x = x
        no:SetSize( button_size, button_size )
        no:SetImage( "amongus/no.png" )
        no:CenterVertical()
        no.DoClick = function()
            self:RemoveVoteButtons()
        end
        self.no = no

        --  > Yes
        local yes = parent:Add( "DImageButton" )
        yes.x = no.x - button_size - ( space or padding )
        yes:SetSize( button_size, button_size )
        yes:SetImage( "amongus/yes.png" )
        yes:CenterVertical()
        yes.DoClick = function()
            self:RemoveVoteButtons()

            net.Start( "AmongUs:Voting" )
                net.WriteEntity( parent.player )
            net.SendToServer()
        end
        self.yes = yes
    end
    function container:OnRemove()
        votes = {}
    end

    --  > Create Players lines
    local lines = {}
    for k, v in ipairs( players ) do
        lines[v:UserID()] = create_line( container, v, w, h, v == speaker )
    end

    --  > Reveal votes
    main.Lines = lines
    function main:ShowVotes()
        local size = padding * 2
        local function show_model( i, ply, line, x, y )
            timer.Simple( i * .65, function()
                local model = create_model( ply, line, x, y, size )
                if not model then return end
                size_from( model, model:GetWide() * 1.25, model:GetTall() * 1.25, .75 )
            end )
        end

        --  > Lines
        local model_total_space = size * 1.1
        for k, line in pairs( lines ) do
            for i, ply in ipairs( line.votes ) do
                show_model( i, ply, line, line.model:GetWide() + padding + ( i - 1 ) * model_total_space, line.model.y + line.model:GetTall() - size + 1 )
            end
        end

        --  > Skip
        for i, ply in ipairs( main.Skip.votes ) do
            show_model( i, ply, main.Skip:GetParent(), main.Skip:GetWide() + padding + ( i - 1 ) * model_total_space, 0 )
        end

        --  > Force Proceeding
        main.time_id = #main.times
        main.time = 0
    end

    --  > Bottom  
    local text_color, alert_color = color_white, Color( 230, 15, 15 )
    main.times = {
        {
            name = "Voting Begins",
            max_time = AmongUs.Settings.DiscussionTime,
            alert_time = 0,
        },
        {
            name = "Voting Ends",
            max_time = AmongUs.Settings.VoteTime,
            alert_time = 10,
            alert_critical = true, --  > bip every second
        },
        {
            name = "Proceeding",
            max_time = AmongUs.Settings.ProceedingTime,
            alert_time = AmongUs.Settings.ProceedingTime,
        }
    }
    main.time_id, main.time = 1, time_delay or 0

    local sound_played = false
    local bottom = content:Add( "DPanel" )
    bottom:Dock( BOTTOM )
    bottom:DockMargin( 0, padding, 0, 0 )
    bottom:SetTall( h * .05 )
    function bottom:Paint( w, h )
        local time = main.times[main.time_id]
        local cooldown = time.max_time - main.time

        --  > Alert Color
        if cooldown <= time.alert_time then
            --  > Reset Color
            if time.alert_critical and cooldown - math.floor( cooldown ) <= .5 and not ( text_color == color_white ) then 
                text_color = color_white
                if not sound_played then
                    EmitSound( "amongus/vote_timer.wav", Vector(), -1, nil, nil, nil, nil, 75 + time.max_time * 5 - cooldown * 5 )
                    sound_played = true
                end
            else
                sound_played = false
            end

            --  > Compute Color
            local t = FrameTime() * 5
            text_color = Color( Lerp( t, text_color.r, alert_color.r ), Lerp( t, text_color.g, alert_color.g ), Lerp( t, text_color.b, alert_color.b ) )
        end

        AmongUs.DrawText( ( "%s in: %ds" ):format( time.name, cooldown ), w - 1, h / 2, text_color, "AmongUs:Little", TEXT_ALIGN_RIGHT )
    end
    function bottom:Think()
        local time = main.times[main.time_id]
        main.time = math.min( main.time + FrameTime(), time.max_time )

        if not main.times[main.time_id + 1] then return end
        if main.time >= time.max_time then
            main.time_id = main.time_id + 1
            main.time = 0
        end
    end

    --  > Skip
    local skip = bottom:Add( "DImageButton" )
    skip:Dock( LEFT )
    skip:SetWide( w * .13 )
    skip:SetImage( "amongus/skip.png" )
    skip.votes = {}
    function skip:DoClick()
        if lines[LocalPlayer():UserID()].i_voted:IsVisible() then return end

        if IsValid( container.yes ) or IsValid( container.no ) then
            container:RemoveVoteButtons()
            if container.yes:GetParent() == self then return end
        end

        local button_size = bottom:GetTall()
        container:CreateVoteButtons( skip.x + skip:GetWide() + padding + button_size + padding / 2, bottom, button_size, padding / 2 )
    end
    main.Skip = skip

    --  > Add votes who wasn't added
    for i, v in ipairs( votes ) do
        main.Lines[v.voter:UserID()].i_voted:SetVisible( true )
        if IsValid( v.target ) then
            main.Lines[v.target:UserID()].votes[#main.Lines[v.target:UserID()].votes + 1] = v.voter
        else
            main.Skip.votes[#main.Skip.votes + 1] = v.voter
        end
    end
end
concommand.Add( "au_vote_tablet", function()
    AmongUs.OpenVoteTablet()
end )

net.Receive( "AmongUs:Voting", function()
    local method = net.ReadUInt( 3 )
    
    --  > Open tablet
    local ply = net.ReadEntity()
    if method == 0 then
        if IsValid( AmongUs.SplashPanel ) then
            function AmongUs.SplashPanel:OnRemove()
                AmongUs.OpenVoteTablet( ply, self.total_time )
            end            
        else
            AmongUs.OpenVoteTablet( ply )
        end

    --  > Vote
    elseif method == 1 then
        local target = net.ReadEntity()
        if not IsValid( AmongUs.VotePanel ) then 
            votes[#votes + 1] = {
                voter = ply,
                target = target,
            }
            return
        end

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
            AmongUs.OpenEjectScene( IsValid( ply ) and ply or tie and "Tie" or AmongUs.SkipVoteID )
        end )
    --  > Clear votes
    elseif method == 3 then
        local votes = net.ReadTable()
        local main = AmongUs.VotePanel
        if not IsValid( main ) then return end

        votes[#votes + 1] = ply
        for i, v in ipairs( votes ) do
            local line = main.Lines[v:UserID()]
            if not line then continue end

            --  > haha vote go brrrr
            line.i_voted:SetVisible( false )

            --  > Clear votes
            for k, voter in ipairs( line.votes ) do
                for i, to_check in ipairs( votes ) do
                    if voter == to_check then
                        table.remove( line.votes, k )
                    end
                end
            end

            --  > Reset votes on target
            if ply == v then line.votes = {} end
        end
    end
end )