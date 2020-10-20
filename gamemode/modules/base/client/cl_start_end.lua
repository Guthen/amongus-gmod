local beam_mat = Material( "effects/lamp_beam" )
local color_black = Color( 0, 0, 0 )
function AmongUs.OpenGameScreen( is_start, role_winner )
    local ply = LocalPlayer()
    local w, h = ScrW(), ScrH()

    local alpha, second_alpha, is_in, text_y, oval_w = -50, 0, true, 0, 0
    local role = AmongUs.GetRoleOf( ply )
    assert( role, "You must be in game to get this screen (you don't have role)" )
    local winner = AmongUs.Roles[role_winner]
    local victory = role == winner
    role = is_start and role or winner

    local main = vgui.Create( "DFrame" )
    main:SetSize( w, h )
    main:SetTitle( "" )
    main:SetDraggable( false )
    main:SetSizable( false )
    main:ShowCloseButton( false )
    main:MakePopup()
    function main:Paint( w, h )
        draw.RoundedBox( 0, 0, 0, w, h, color_black )

        --  > Animation
        alpha = Lerp( FrameTime() * ( is_in and .5 or 5 ), alpha, is_in and 255 or 0 )
        if not is_in and alpha <= 1 then
            main:Remove()
            ply:ScreenFade( SCREENFADE.IN, color_black, .5, 0 )
        end
        text_y = math.Approach( text_y, 50, FrameTime() * 15 )
        if alpha >= 50 then
            oval_w = Lerp( FrameTime(), oval_w, w / 2 )
            if oval_w >= w / 4 then
                second_alpha = Lerp( FrameTime() * ( is_in and .5 or 5 ), second_alpha, is_in and 255 or 0 )
            end
        end
        
        --  > Role
        local color = ColorAlpha( is_start and role.color or victory and AmongUs.Settings.VictoryColor or AmongUs.Settings.DefeatColor, math.max( alpha, 0 ) )
        draw.SimpleText( is_start and role.name or victory and "Victory" or "Defeat", "AmongUs:Role", w / 2, h / 5 + text_y, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    
        --  > Second sentence
        if is_start and role.second_reveal_sentence then
            surface.SetAlphaMultiplier( second_alpha / 255 * alpha / 255 )
            AmongUs.DrawColoredText( w / 2, h / 2.5, "AmongUs:RoleLittle", role:second_reveal_sentence() )
        end
    end

    --  > Place players
    local players, entities = is_start and role:get_scene_players() or team.GetPlayers( role.id ), {}
    table.sort( players, function( a, b ) return a == ply end )
    local z, x, factor = 0, 0, 1
    for i, v in ipairs( players ) do
        --  > Create model
        local ent = ClientsideModel( v:GetModel() )
        ent:SetPos( Vector( -200 + z * 50, 50 + x * ( 35 + i * 1.5 ) * factor, -5 ) )
        ent:SetNoDraw( true )
        ent:SetIK( false )

        --  > Change positions
        if i % 2 == 1 then 
            z = z - 1
            x = x - 1
        end
        factor = factor == 1 and -1 or 1

        --  > Set Player Color
        local color = v:GetPlayerColor()
        function ent:GetPlayerColor()
            return color
        end

        --  > Add entity
        entities[i] = ent
    end
    if not IsValid( entities[1] ) then return main:Remove() end

    local beam_tall = h / 2.35
    local scene = main:Add( "DModelPanel" )
    scene:SetCursor( "blank" )
    scene:Dock( FILL )
    scene:SetEntity( ply )
    scene:SetLookAt( entities[1]:GetPos() + Vector( 0, 0, 62 ) )
    function scene:PreDrawModel( ent )
        --  > Beam
        local color = ColorAlpha( is_start and role.color or victory and AmongUs.Settings.VictoryColor or AmongUs.Settings.DefeatColor, alpha )
        render.SetMaterial( beam_mat )
        render.StartBeam( 2 )
            render.AddBeam( Vector( -200, -oval_w, 25 ), beam_tall, 1, color )
            render.AddBeam( Vector( -200, oval_w, 25 ), beam_tall, 1, color )
        render.EndBeam()

        --  > Players
        for i, v in ipairs( entities ) do
            --  > Compute alpha effect
            local alpha = alpha
            if i > 1 and is_in then 
                alpha = math.min( ( oval_w * 1.25 - math.abs( v:GetPos().x ) + math.abs( v:OBBCenter().x ) ), 255 ) 
            end
            --  > Ghosts
            local blend = render.GetBlend()
            if not players[i]:Alive() then 
                render.SetBlend( .75 )
            end
            render.ResetModelLighting( alpha / 255, alpha / 255, alpha / 255 )

            --  > Draw Model
            v:DrawModel()
            render.SetBlend( blend )

            --  > Name Texts
            if role.show_player_name_reveal then
                local name = players[i]:GetName()
                local font = "AmongUs:Medium"
                surface.SetFont( font )
                local scale = 0.1
                local text_w = surface.GetTextSize( name ) * scale

                cam.Start3D2D( v:LocalToWorld( Vector( 0, -text_w / 2, 2 ) ), Angle( 0, 90, 90 ), scale )
                    AmongUs.DrawText( name, 0, 0, ColorAlpha( is_start and color_white or role:get_name_color( role ), alpha ), font, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
                cam.End3D2D()
            end
        end

        return false
    end
    function main:OnRemove()
        for i, v in ipairs( entities ) do
            if IsValid( v ) then 
                v:Remove() 
            end
        end
    end

    timer.Simple( is_start and 3 or 6, function()
        is_in = false
    end )
    surface.PlaySound( is_start and "amongus/reveal.wav" or victory and "amongus/victory.wav" or "amongus/defeat.wav" )
end
concommand.Add( "au_start_scene", function()
    AmongUs.OpenGameScreen( true )
end )
concommand.Add( "au_end_scene", function()
    AmongUs.OpenGameScreen( false, IMPOSTOR )
end )

net.Receive( "AmongUs:GameState", function()
    local is_start, winner = net.ReadBool(), net.ReadUInt( 7 )
    if IsValid( AmongUs.EjectScene ) then
        function AmongUs.EjectScene:OnRemove()
            AmongUs.OpenGameScreen( is_start, winner )
        end
    else
        AmongUs.OpenGameScreen( is_start, winner )
    end
end )
--RunConsoleCommand( "gnlib_resetpanels" )