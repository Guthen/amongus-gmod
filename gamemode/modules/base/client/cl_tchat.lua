AmongUs.TchatMessages = {}

local color_black, background_color = Color( 0, 0, 0 ), Color( 107, 113, 123, 200 )
local line_color, line_shadow_color, line_disable_color = Color( 233, 241, 248 ), Color( 68, 73, 80 ), Color( 148, 156, 163 )

local padding = ScrH() * .022
local function create_model( ply, scroll, x, y, size, look_left )
    if not IsValid( ply ) then return end

    local model = scroll:Add( "DModelPanel" )
    model:SetPos( x, y )
    model:SetSize( size, size )
    model:SetFOV( 40 )
    model:SetModel( ply:GetModel() )
    function model:LayoutEntity( ent )
        local eyepos = ent:GetBonePosition( 6 )
    
        self:SetLookAt( eyepos )
        self:SetCamPos( eyepos + Vector( 45, 0, 0 ) + Vector( 0, -15, 0 ) * ( look_left and -1 or 1 ) )
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

local function create_line( scroll, message, w, h )
    local ply = message.player
    if not IsValid( ply ) then return end

    local is_self = ply == LocalPlayer()
    local role = AmongUs.GetRoleOf( ply )
    local text, color = ply:GetName(), role and role:get_name_color( AmongUs.GetRoleOf( LocalPlayer() ) ) or color_white

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
    line.is_active = IsValid( ply ) and ply:Alive()
    line.player = ply
    function line:Paint( w, h )
        self.is_active = IsValid( ply ) and ply:Alive()

        --  > Shadow
        draw.RoundedBox( 8, space, space, w - space, h - space, line_shadow_color )

        --  > Line
        draw.RoundedBox( 8, 0, 0, w - space, h - space, self.is_active and line_color or line_disable_color )
    
        --  > Name
        local color = color
        if not self.is_active then color = ColorAlpha( color, 100 ) end
        local x, y = is_self and w - space * 2 - padding * 3.8 or model:GetWide() + padding, padding * .35
        AmongUs.DrawText( text, x, y, color, nil, is_self and TEXT_ALIGN_RIGHT or TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT )

        local font = "AmongUs:Little"
        draw.SimpleText( message.text, font, x, y + draw.GetFontHeight( font ) * 1.15, color_black, is_self and TEXT_ALIGN_RIGHT or TEXT_ALIGN_LEFT )

        return true
    end

    --  > ModelPanel
    local padding = padding / 2
    local size = line:GetTall() - padding * 2
    model = create_model( ply, line, is_self and line:GetWide() - space * 2 - size or padding, padding * .5, size, is_self )
    line.model = model

    scroll:ScrollToChild( line )

    --  > I voted
    --[[ local voted_size = w * .0375
    local image = line:Add( "DImage" )
    image:SetPos( scroll.x + line.x - padding, scroll.y + line.y - padding )
    image:SetSize( voted_size, voted_size )
    image:SetImage( "amongus/voted.png" )
    image:SetVisible( false )
    image:NoClipping( true )
    line.i_voted = image ]]

    return line
end

AmongUs.TchatPanel = nil
function AmongUs.OpenTchat()
    local w, h = ScrW() * .6, ScrH() * .75

    --  > Main
    local container, textbox
    local border_wide, corner_radius = 6, 12
    local main = vgui.Create( "DFrame" )
    main:DockPadding( 15, 24, 15, 15 )
    main:SetSize( w, h )
    main:SetTitle( "" )
    main:SetDraggable( false )
    main:SetSizable( false )
    main:MakePopup()
    main:Center()
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
    function textbox:OnEnter()
        if #textbox:GetValue() <= 0 then return end

        net.Start( "AmongUs:Tchat" )
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
end
concommand.Add( "au_tchat", AmongUs.OpenTchat )

net.Receive( "AmongUs:Tchat", function()
    local messages = net.ReadTable()
    if not messages --[[ or not message.text ]] then return end
    --if #message.text > AmongUs.Settings.LimitTchatLetters then return end --  > server sus

    table.Add( AmongUs.TchatMessages, messages )

    if IsValid( AmongUs.TchatPanel ) then
        for i, v in ipairs( messages ) do
            AmongUs.TchatPanel:AddMessage( v )
        end
    end
    surface.PlaySound( "amongus/message.wav" )
end )