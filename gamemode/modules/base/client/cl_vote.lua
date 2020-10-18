AmongUs.VotePanel = nil

local background_color = Color( 170, 200, 229 )
local line_color, line_shadow_color, line_disable_color = Color( 233, 241, 248 ), Color( 114, 134, 153 ), Color( 148, 156, 163 )

local w, h = ScrW() * .75, ScrH() * .9
local padding = h * .022
local speaker = Material( "amongus/speaker.png" )
local function create_model( ply, parent, x, y, size )
    local model = parent:Add( "DModelPanel" )
    model:SetPos( x, y )
    model:SetSize( size, size )
    model:SetFOV( 40 )
    model:SetModel( ply:GetModel() )
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
    function model.Entity:GetPlayerColor()
        return ply:GetPlayerColor()
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
    --  > Main
    local line, model = container:Add( "DButton" )
    line:SetSize( w / 2 - padding * 2, h * .125 )
    line:InvalidateParent( true )
    line.is_active = IsValid( ply ) and ply:Alive()
    line.player = ply
    line.votes = {}
    function line:Paint( w, h )
        --  > Shadow
        local space = w * .007
        draw.RoundedBox( 8, space, space, w - space, h - space, line_shadow_color )

        --  > Line
        draw.RoundedBox( 8, 0, 0, w - space, h - space, self.is_active and line_color or line_disable_color )
    
        --  > Name
        local role = AmongUs.GetRoleOf( ply )
        local text, color = ply:GetName(), role and role:get_name_color( LocalPlayer() ) or color_white
        if not ply:Alive() then color = ColorAlpha( color, 100 ) end
        AmongUs.DrawText( text, model:GetWide() + padding, padding * .35, color, nil, TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT )
    
        --  > Speaker
        if is_speaker then
            AmongUs.DrawMaterial( speaker, w * .8, 1, h, h - space )
        end

        return true
    end
    function line:DoClick()
        if not self.is_active or container.voted then return end

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
    model = create_model( ply, line, padding, padding, line:GetTall() - padding * 2 )
    line.model = model

    --  > Dead Cross
    if not line.is_active then
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
    local image = AmongUs.VotePanel.content:Add( "DImage" )
    image:SetPos( container:GetParent():GetParent().x + container.x + line.x - padding, container:GetParent():GetParent().y + container.y + line.y - padding )
    image:SetSize( voted_size, voted_size )
    image:SetImage( "amongus/voted.png" )
    image:SetVisible( false )
    line.i_voted = image

    return line
end

local tablet, skip = Material( "amongus/tablet.png" )
function AmongUs.OpenVoteTablet( speaker )
    if IsValid( AmongUs.VotePanel ) then AmongUs.VotePanel:Remove() end

    local start = CurTime()
    local main = vgui.Create( "DFrame" )
    main:SetDraggable( false )
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
        AmongUs.DrawText( "Who Is The Impostor?", w / 2, h / 2, nil, "AmongUs:Medium" )
    end

    --  > Players
    local players = player.GetAll()
    table.sort( players, function( a, b ) return a:Alive() and not b:Alive() end )

    --  > Scroll Panel
    local scroll = content:Add( "DScrollPanel" )
    scroll:Dock( FILL )
    scroll:DockMargin( 0, padding, 0, 0 )
    scroll:GetVBar():SetWide( 0 )
    scroll:InvalidateParent( true )

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
            self.voted = true

            net.Start( "AmongUs:Voting" )
                net.WriteEntity( parent.player )
            net.SendToServer()
        end
        self.yes = yes
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
            timer.Simple( i * .75, function()
                local model = create_model( ply, line, x, y, size )
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
    end

    --  > Bottom
    local bottom = content:Add( "DPanel" )
    bottom:Dock( BOTTOM )
    bottom:SetTall( h * .05 )
    function bottom:Paint( w, h )
        local cooldown = ( start + AmongUs.Settings.VoteTime ) - CurTime()
        AmongUs.DrawText( ( "Voting Ends in: %ds" ):format( cooldown ), w - 1, h / 2, cooldown > 10 and color_white or Color( 230, 15, 15 ), "AmongUs:Little", TEXT_ALIGN_RIGHT )
    end

    --  > Skip
    local skip = bottom:Add( "DImageButton" )
    skip:Dock( LEFT )
    skip:SetWide( w * .13 )
    skip:SetImage( "amongus/skip.png" )
    skip.votes = {}
    function skip:DoClick()
        if container.voted then return end

        if IsValid( container.yes ) or IsValid( container.no ) then
            container:RemoveVoteButtons()
            if container.yes:GetParent() == self then return end
        end

        local button_size = bottom:GetTall()
        container:CreateVoteButtons( skip.x + skip:GetWide() + padding + button_size + padding / 2, bottom, button_size, padding / 2 )
    end
    main.Skip = skip
end
concommand.Add( "au_vote_tablet", AmongUs.OpenVoteTablet )