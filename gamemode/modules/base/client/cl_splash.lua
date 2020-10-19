
AmongUs.SplashScreens = {
    emergency = {
        time = 1.5,
        sound = "amongus/emergency.wav",
        images = {
            hand = Material( "amongus/sequences/emergency/hand.png" ),
            player = Material( "amongus/sequences/emergency/player.png" ),
            glass = Material( "amongus/sequences/emergency/glass.png" ),
            table = Material( "amongus/sequences/emergency/table.png" ),
            text = Material( "amongus/sequences/emergency/text.png" ),
        },
        draw = function( self, w, h )
            --  > Text
            local img_w, img_h = w / 4, h / 5
            AmongUs.DrawMaterial( self.images.text, w / 2 - img_w / 2, h / 2, img_w, img_h )
        
            --  > Player
            local img_w, img_h = w / 11.7, h / 8.1
            AmongUs.DrawMaterial( self.images.player, w / 2 - img_w / 1.15, h / 2 - img_h * 1.9, img_w, img_h, self.color )
            AmongUs.DrawMaterial( self.images.glass, w / 2 - img_w / 1.15, h / 2 - img_h * 1.9, img_w, img_h )

            --  > Table
            local img_w, img_h = w / 6, h / 8
            AmongUs.DrawMaterial( self.images.table, w / 2 - img_w / 2, h / 2 - img_h * 1.35, img_w, img_h )
        
            --  > Hand
            local img_w, img_h = w / 25, h / 25
            AmongUs.DrawMaterial( self.images.hand, w / 2 - img_w / 8, h / 2 - img_h * 3.4, img_w, img_h, self.color )
        end,
    },
    report = {
        time = 2.5,
        sound = "amongus/report_body.wav",
        images = {
            text = Material( "amongus/sequences/report/text.png" ),
            body = Material( "amongus/sequences/report/body.png" ),
            glass = Material( "amongus/sequences/report/glass.png" ),
            bubble = Material( "amongus/sequences/report/bubble.png" ),
        },
        draw = function( self, w, h )
            --  > Text
            local img_w, img_h = w / 3.5, h / 3.8
            AmongUs.DrawMaterial( self.images.text, w / 2 - img_w / 1.68, h / 2 - img_h / 4.8, img_w, img_h )
        
            --  > Body
            local img_w, img_h = w / 6.8, h / 6.5
            AmongUs.DrawMaterial( self.images.body, w / 2 - img_w / 1.45, h / 2 - img_h * 1.35, img_w, img_h, self.color )
            AmongUs.DrawMaterial( self.images.glass, w / 2 - img_w / 1.45, h / 2 - img_h * 1.35, img_w, img_h )

            --  > Bubble
            local img_size = w / 10
            AmongUs.DrawMaterial( self.images.bubble, w / 2 - img_size * .9, h / 2 - img_size * 2.15, img_size, img_size )
        end,
    },
}

local bolt = Material( "amongus/bolt.png" )
local bolt_sequences = {
    {
        ang = 25,
        scale_x = 1.5,
        scale_y = .4,
        time = .1,
    },
    {
        ang = -15,
        scale_x = 1.5,
        scale_y = .75,
        time = .1,
    },
    {
        ang = 0,
        scale_x = 1,
        scale_y = 1,
        type_control = true,
    },
    {
        ang = 0,
        scale_x = 1,
        scale_y = .5,
        time = .1,
    },
}

AmongUs.SplashPanel = nil
function AmongUs.OpenSplashScreen( type, info )
    info = info or { color = LocalPlayer():GetPlayerColor():ToColor() }

    local time, sequence_id = 0, 1
    local w, h = ScrW(), ScrH()

    local splash_type = AmongUs.SplashScreens[type]
    assert( splash_type, ( "type: %q doesn't exists" ):format( type or "" ) )
    if splash_type.sound then surface.PlaySound( splash_type.sound ) end
    table.Merge( splash_type, info )

    local main = vgui.Create( "DFrame" )
    main:SetSize( w, h )
    main:SetTitle( "" )
    main:SetDraggable( false )
    main:SetSizable( false )
    main:MakePopup()
    function main:Paint( w, h )
        local sequence = bolt_sequences[sequence_id]

        --  > Draw Bolt
        local img_w, img_h = bolt:Width(), bolt:Height() * 2
        AmongUs.DrawMaterial( bolt, w / 2, h / 2, w * sequence.scale_x, img_h * sequence.scale_y, nil, sequence.ang )
    
        --  > Draw Type
        local splash_type = AmongUs.SplashScreens[type] -- hot reload
        if splash_type and sequence.type_control then
            splash_type:draw( w, h )
        end
    end
    function main:Think()
        time = time + FrameTime()
        if time >= ( bolt_sequences[sequence_id].time or splash_type.time ) then
            if sequence_id >= #bolt_sequences then
                main:Remove()
                return 
            end
            sequence_id = sequence_id + 1
            time = 0
        end
    end
    AmongUs.SplashPanel = main
end
concommand.Add( "au_splash_screen", function( ply, cmd, args )
    AmongUs.OpenSplashScreen( args[1] )
end )

net.Receive( "AmongUs:SplashScreen", function()
    AmongUs.OpenSplashScreen( net.ReadString(), net.ReadTable() )
end )