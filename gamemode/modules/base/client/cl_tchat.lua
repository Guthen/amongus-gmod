AmongUs.TchatMessages = {
    {
        player = Entity(1),
        text = "This tchat is working, yea man"
    }
}

local color_black, background_color = Color( 0, 0, 0 ), Color( 107, 113, 123, 200 )
local line_color, line_shadow_color, line_disable_color = Color( 233, 241, 248 ), Color( 68, 73, 80 ), Color( 148, 156, 163 )

local padding = ScrH() * .022
local function create_model( ply, parent, x, y, size )
    if not IsValid( ply ) then return end

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
    local color = ply:GetPlayerColor()
    function model.Entity:GetPlayerColor()
        return color
    end

    return model
end

local function create_line( parent, message, w, h )
    local ply = message.player
    local role = AmongUs.GetRoleOf( ply )
    local text, color = ply:GetName(), role and role:get_name_color( AmongUs.GetRoleOf( LocalPlayer() ) ) or color_white

    --  > Line
    local line, model = parent:Add( "DPanel" )
    line:SetSize( w / 2 - padding * 2, h * .125 )
    line:InvalidateParent( true )
    line.is_active = IsValid( ply ) and ply:Alive()
    line.player = ply
    function line:Paint( w, h )
        self.is_active = IsValid( ply ) and ply:Alive()

        --  > Shadow
        local space = w * .007
        draw.RoundedBox( 8, space, space, w - space, h - space, line_shadow_color )

        --  > Line
        draw.RoundedBox( 8, 0, 0, w - space, h - space, self.is_active and line_color or line_disable_color )
    
        --  > Name
        local color = color
        if not self.is_active then color = ColorAlpha( color, 100 ) end
        AmongUs.DrawText( text, model:GetWide() + padding, padding * .35, color, nil, TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT )

        return true
    end

    --  > ModelPanel
    local padding = padding / 2
    model = create_model( ply, line, padding, padding, line:GetTall() - padding * 2 )
    line.model = model

    --  > I voted
    --[[ local voted_size = w * .0375
    local image = line:Add( "DImage" )
    image:SetPos( parent.x + line.x - padding, parent.y + line.y - padding )
    image:SetSize( voted_size, voted_size )
    image:SetImage( "amongus/voted.png" )
    image:SetVisible( false )
    image:NoClipping( true )
    line.i_voted = image ]]

    --  > Text
    local text = line:Add( "DLabel" )
    text:SetPos( padding * 2 + model:GetWide(), line:GetTall() - padding )
    text:SetText( message.text )
    text:SetFont( "AmongUs:Little" )
    text:SetWrap( true )
    text:SetContentAlignment( 9 )

    return line
end

function AmongUs.OpenTchat()
    local w, h = ScrW() * .6, ScrH() * .75

    --  > Main
    local container, textbox
    local border_wide, corner_radius = 6, 12
    local main = vgui.Create( "DFrame" )
    main:SetSize( w, h )
    main:SetTitle( "" )
    main:SetDraggable( false )
    main:SetSizable( false )
    main:MakePopup()
    main:DockPadding( 15, 15, 15, 15 )
    function main:Paint( w, h )
        draw.RoundedBox( corner_radius * .8, border_wide, border_wide, w - border_wide * 2, h - border_wide * 2, background_color )
        AmongUs.DrawOutlinedRoundedRect( corner_radius, 0, 0, w, h, border_wide, color_black )
    
        --  > Count letters
        local left, top, right, bottom = container:GetDockPadding()
        draw.SimpleText( ( "%d/%d" ):format( #textbox:GetValue(), AmongUs.Settings.LimitTchatLetters ), "AmongUs:Mini", w - right * 1.5, h - bottom * 1.5 - textbox:GetTall() * 1.5, color_black, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM )
    end

    --  > Messages
    local scroll = main:Add( "DScrollPanel" )
    scroll:Dock( FILL )
    scroll:InvalidateParent( true )

    for i, v in ipairs( AmongUs.TchatMessages ) do
        create_line( scroll, v, scroll:GetSize() )
    end

    --  > Textbox
    container = main:Add( "DPanel" )
    container:Dock( BOTTOM )
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
    textbox:InvalidateParent( true )

    send_button = container:Add( "DImageButton" )
    send_button:Dock( RIGHT )
    send_button:SetSize( textbox:GetTall(), textbox:GetTall() )
    send_button:SetImage( "amongus/send.png" )
end
concommand.Add( "au_tchat", AmongUs.OpenTchat )
