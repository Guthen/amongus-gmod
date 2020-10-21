AmongUs.TchatMessages = {}

local color_black, background_color = Color( 0, 0, 0 ), Color( 107, 113, 123, 200 )
local line_color, line_shadow_color, line_disable_color = Color( 233, 241, 248 ), Color( 68, 73, 80 ), Color( 148, 156, 163 )

local padding = ScrH() * .022
local function create_model( message, parent, x, y, size, look_left )
    local model = parent:Add( "DModelPanel" )
    model:SetPos( x, y )
    model:SetSize( size, size )
    model:SetFOV( 40 )
    model:SetModel( AmongUs.BasePlayerClass.Model )
    function model:LayoutEntity( ent )
        local eyepos = ent:GetBonePosition( 6 )
    
        self:SetLookAt( eyepos )
        self:SetCamPos( eyepos + Vector( 45, 0, 0 ) + Vector( 0, -15, 0 ) * ( look_left and -1 or 1 ) )
    end
    function model:PreDrawModel( ent )
        if not IsValid( AmongUs.TchatPanel ) then return end
        local alpha = AmongUs.TchatPanel:GetAlpha()
        render.ResetModelLighting( alpha / 255, alpha / 255, alpha / 255 )
    end
    function model.Entity:GetPlayerColor()
        return message.color
    end

    return model
end

local function create_line( scroll, message, w, h )
    local ply = message.player

    local is_self = ply == LocalPlayer()
    local role = IsValid( ply ) and AmongUs.GetRoleOf( ply )
    local color = role and role:get_name_color( AmongUs.GetRoleOf( LocalPlayer() ) ) or color_white

    --  > Line
    local container = scroll:Add( "DPanel" )
    container:Dock( TOP )
    container:DockMargin( 0, padding / 2, 0, 0 )
    container:SetTall( h * .125 )
    container:InvalidateParent( true )
    container:SetPaintBackground( false )

    local space = w * .007
    local line, model = container:Add( "DPanel" )
    line:Dock( is_self and RIGHT or LEFT )
    line:SetWide( w * .9 )
    line:InvalidateParent( true )
    line.is_active = message.dead
    line.player = ply
    function line:Paint( w, h )
        --  > Shadow
        draw.RoundedBox( 8, space, space, w - space, h - space, line_shadow_color )

        --  > Line
        draw.RoundedBox( 8, 0, 0, w - space, h - space, self.is_active and line_color or line_disable_color )
    
        --  > Name
        local color = color
        if not self.is_active then color = ColorAlpha( color, 100 ) end
        local x, y = is_self and w - space * 2 - padding * 3.8 or model:GetWide() + padding, padding * .35
        AmongUs.DrawText( message.name, x, y, color, nil, is_self and TEXT_ALIGN_RIGHT or TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT )

        local font = "AmongUs:Little"
        draw.SimpleText( message.text, font, x, y + draw.GetFontHeight( font ) * 1.15, color_black, is_self and TEXT_ALIGN_RIGHT or TEXT_ALIGN_LEFT )

        return true
    end

    --  > ModelPanel
    local padding = padding / 2
    local size = line:GetTall() - padding * 2
    model = create_model( message, line, is_self and line:GetWide() - space * 2 - size or padding, padding * .5, size, is_self )
    line.model = model

    scroll:ScrollToChild( line )

    --  > I voted
    if message.i_voted then
        local voted_size = w * .0375
        local image = line:Add( "DImage" )
        image:SetPos( model.x + ( is_self and size - padding * 3 or -padding * .5 ), model.y + size - padding * 2.2 )
        image:SetSize( voted_size, voted_size )
        image:SetImage( "amongus/voted.png" )
    end

    return line
end

AmongUs.TchatPanel = nil
function AmongUs.OpenTchat( parent )
    local animation_time = .25 
    local w, h = ScrW() * .6, ScrH() * .75

    local x, y = w, 0
    if parent then
        x, y = parent:LocalToScreen( parent:GetWide() / 2, parent:GetTall() / 3 )
    end

    --  > Main
    local container, textbox
    local border_wide, corner_radius = 6, 12
    local main = vgui.Create( "DFrame" )
    main:DockPadding( 15, 24, 15, 15 )
    main:SetPos( x, y )
    main:SetSize( w, h )
    main:SizeTo( w, h, animation_time, 0, 1 )
    main:MoveTo( x - w, y, animation_time, 0, 1 )
    main:SetTitle( "" )
    main:SetDraggable( false )
    main:SetSizable( false )
    main:ShowCloseButton( false )
    main:MakePopup()
    function main:Close()
        main:SizeTo( 0, 0, animation_time, 0, 1, function()
            main:Remove()
        end )
        main:MoveTo( x, y, animation_time, 0, 1 )
    end
    function main:Think()
        self:MoveToFront()
    end
    function main:Paint( w, h )
        draw.RoundedBox( corner_radius * .8, border_wide, border_wide, w - border_wide * 2, h - border_wide * 2, background_color )
        AmongUs.DrawOutlinedRoundedRect( corner_radius, 0, 0, w, h, border_wide, color_black )
    
        --  > Count letters
        local left, top, right, bottom = container:GetDockPadding()
        draw.SimpleText( ( "%d/%d" ):format( #textbox:GetValue(), AmongUs.Settings.LimitTchatLetters ), "AmongUs:Mini", w - right * 1.5, h - bottom * 1.5 - textbox:GetTall() * 1.5, color_black, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM )
    end
    AmongUs.TchatPanel = main

    --  > Messages
    local scroll = main:Add( "DScrollPanel" )
    scroll:Dock( FILL )
    scroll:GetVBar():SetWide( 0 )
    scroll:InvalidateParent( true )

    local scroll_w, scroll_h = scroll:GetSize()
    function main:AddMessage( message )
        create_line( scroll, message, scroll_w, scroll_h )
    end

    for i, v in ipairs( AmongUs.TchatMessages ) do
        main:AddMessage( v )
    end

    --  > Textbox
    container = main:Add( "DPanel" )
    container:Dock( BOTTOM )
    container:DockMargin( 0, padding * 1.5, 0, 0 )
    container:DockPadding( 15, 15, 15, 15 )
    container:SetTall( h * .1 )
    function container:Paint( w, h )
        draw.RoundedBox( corner_radius, border_wide, border_wide, w - border_wide * 2, h - border_wide * 2, color_white )
        AmongUs.DrawOutlinedRoundedRect( corner_radius, 0, 0, w, h, border_wide, color_black )
    end

    textbox = container:Add( "DTextEntry" )
    textbox:Dock( FILL )
    textbox:SetFont( "AmongUs:Little" )
    textbox:SetDrawLanguageID( false )
    textbox:RequestFocus()
    function textbox:Paint( w, h )
        self:DrawTextEntryText( color_black, color_black, color_black )
    end
    function textbox:OnChange()
        if #self:GetValue() > AmongUs.Settings.LimitTchatLetters then
            self:SetText( self:GetValue():sub( 0, AmongUs.Settings.LimitTchatLetters ) )
        end
    end
    local on_key_code_typed = textbox.OnKeyCodeTyped
    function textbox:OnKeyCodeTyped( key )
        if key == KEY_ESCAPE then
            main:Close()
            gui.HideGameUI()
        else
            on_key_code_typed( self, key )
        end
    end
    function textbox:OnEnter()
        if #textbox:GetValue() <= 0 then return end

        net.Start( "AmongUs:Tchat" )
            net.WriteUInt( 1, 3 )
            net.WriteString( textbox:GetValue() )
        net.SendToServer()

        textbox:SetText( "" )
        textbox:RequestFocus()
    end
    textbox:InvalidateParent( true )

    send_button = container:Add( "DImageButton" )
    send_button:Dock( RIGHT )
    send_button:SetSize( textbox:GetTall(), textbox:GetTall() )
    send_button:SetImage( "amongus/send.png" )
    send_button.DoClick = textbox.OnEnter

    --  > Animation purpose
    main:SetSize( 0, 0 )
end
--[[ concommand.Add( "au_tchat", function()
    AmongUs.OpenTchat()
end ) ]]

AmongUs.TchatDialog = AmongUs.TchatDialog or nil
function AmongUs.CreateTchatButton()
    if IsValid( AmongUs.TchatDialog ) then AmongUs.TchatDialog:Remove() end
    
    local dialog, notification = vgui.Create( "DImageButton" )
    dialog:SetWide( padding * 4 )
    dialog:SetTall( dialog:GetWide() )
    dialog:SetImage( "amongus/dialog.png" )
    dialog:SetAutoDelete( false )
    function dialog:DoClick( open )
        if IsValid( AmongUs.TchatPanel ) then
            AmongUs.TchatPanel:Close()
        else
            AmongUs.OpenTchat( self )
        end

        notification:SetVisible( false )
    end
    function dialog:Think()
        local ply = LocalPlayer()
        local good = IsValid( AmongUs.VotePanel ) or ply:Team() == TEAM_UNASSIGNED or not ply:Alive()
        self:SetAlpha( good and 255 or 0 )
    end 
    AmongUs.TchatDialog = dialog

    notification = dialog:Add( "DImage" )
    notification:SetWide( padding * 2 )
    notification:SetTall( notification:GetWide() )
    notification:SetPos( -dialog:GetWide() * .1, dialog:GetTall() - notification:GetTall() * 1.25 )
    notification:SetImage( "amongus/notification.png" )
    notification:NoClipping( true )
    notification:SetVisible( false )
    function notification:Notify()
        if IsValid( AmongUs.TchatPanel ) then return end

        local x, y = self:GetPos()
        local to_y = self:GetTall() / 4
        self:MoveTo( x, y - to_y, .1, 0, nil, function()
            self:MoveTo( x, y + to_y, .1, 0, nil, function()
                self:MoveTo( x, y, .1 )
            end )
        end )

        self:SetVisible( true )
    end
    dialog.notification = notification

    return dialog, notification
end

hook.Add( "InitPostEntity", "AmongUs:Tchat", function()
    net.Start( "AmongUs:Tchat" )
        net.WriteUInt( 2, 3 )
    net.SendToServer()
end )

net.Receive( "AmongUs:Tchat", function()
    local method = net.ReadUInt( 3 )
    if method == 1 then --  > receive messages
        local messages = net.ReadTable()
        if not messages --[[ or not message.text ]] then return end
        --if #message.text > AmongUs.Settings.LimitTchatLetters then return end --  > server sus

        --  > Store messages
        table.Add( AmongUs.TchatMessages, messages )

        --  > Add messages to active tchat
        if IsValid( AmongUs.TchatPanel ) then
            for i, v in ipairs( messages ) do
                AmongUs.TchatPanel:AddMessage( v )
            end
        end
        surface.PlaySound( "amongus/message.wav" )

        --  > Notify on tablet
        if IsValid( AmongUs.TchatDialog ) then
            AmongUs.TchatDialog.notification:Notify()
        end
    elseif method == 2 then --  > clear messages
        AmongUs.TchatMessages = {}
    end
end )