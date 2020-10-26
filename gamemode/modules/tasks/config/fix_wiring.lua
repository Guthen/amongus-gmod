local materials = {
    base = Material( "amongus/tasks/fix_wiring/base.png" ),
    broke01 = Material( "amongus/tasks/fix_wiring/broke01.png" ),
    broke02 = Material( "amongus/tasks/fix_wiring/broke02.png" ),
    broke03 = Material( "amongus/tasks/fix_wiring/broke03.png" ),
    copper01 = Material( "amongus/tasks/fix_wiring/copper01.png" ),
    copper02 = Material( "amongus/tasks/fix_wiring/copper02.png" ),
    copper03 = Material( "amongus/tasks/fix_wiring/copper03.png" ),
    wire = Material( "amongus/tasks/fix_wiring/wire.png" ),
}

return {
    name = "Fix Wiring",
    type = AU_TASK_COMMON,
    max_stages = 3,
    w = AmongUs.SquareTaskSize,
    h = AmongUs.SquareTaskSize,
    wire_h = CLIENT and math.floor( AmongUs.SquareTaskSize / materials.base:Height() * 17 ),
    wire_w = CLIENT and math.floor( AmongUs.SquareTaskSize / materials.base:Width() * 31 ),
    wires = {
        left = {},
        right = {}
    },
    y_pos = {
        96,
        200,
        303,
        406
    },
    colors = {
        Color( 253, 235, 0 ),
        Color( 255, 0, 0 ),
        Color( 255, 0, 255 ),
        Color( 0, 0, 255 )
    },
    can_submit = function( self )
        for i, v in ipairs( self.wires.right ) do
            if not v.good then return end
        end

        return true
    end,
    init = function( self )
        surface.PlaySound( "amongus/tasks/fix_wiring/open.wav" )
        
        local colors_left = table.Copy( self.colors )
        local colors_right = table.Copy( self.colors )

        for i = 1, 4 do
            self.wires.left[ i ] = {
                color = table.remove( colors_left, math.random( #colors_left ) ),
                img = math.random( 3 )
            }

            self.wires.right[ i ] = {
                color = table.remove( colors_right, math.random( #colors_right ) ),
                img = math.random( 3 )
            }
        end
    end,
    update = function( self, dt )
    end,
    paint = function( self, w, h )
        paint.Start( materials.base, 0, 0, w, h )
            --  > Right wires
            for i, v in ipairs( self.wires.right ) do
                local y = self.y_pos[i]

                --  > Electricity light
                paint.Rect( 471, y - 15, 31, 12, Color( 226, 208, 4 ) )

                --  > Wire receptor
                paint.Draw( materials[ "copper0" .. v.img ], 471 - 45, y - 5, 40, 27, nil, 180 )
                paint.Draw( materials[ "broke0" .. v.img ], 471 - 13, y, 13, 17, v.color, 180 )

                --  > Wire base
                paint.Draw( materials.wire, 471, y, 31, 17, v.color )
            end

            --  > Left wires
            for i, v in ipairs( self.wires.left ) do
                local y = self.y_pos[i]

                --  > Electricity light
                paint.Rect( 5, y - 15, 31, 12, Color( 226, 208, 4 ) )

                --  > Wire base
                paint.Draw( materials.wire, 5, y, 31, 17, v.color )
            end
        paint.End()

        if true then return end
        AmongUs.DrawMaterial( materials.base, 0, 0, w, h )
        local light = h * 0.023

        for i, v in ipairs( self.wires.left ) do
            local pos = self.y_pos[i] * h / materials.base:Height()

            --  > Electricity light
            draw.RoundedBox( 0, w * 0.01, pos - light - h * 0.006, self.wire_w, light, Color( 226, 208, 4 ) )

            --  > Wire
            --AmongUs.DrawMaterial( materials.wire, 5 * w / materials.base:Width(), pos, self.wire_w, self.wire_h, v.color )
            draw.RoundedBox( 0, math.floor( 5 * w / materials.base:Width() ), pos, self.wire_w, self.wire_h, v.color )

            --  > Linked wire
            if v.wired then
                surface.SetDrawColor( v.color )
                surface.DrawLine( self.wire_w, pos + self.wire_h / 2, self.w - self.wire_w * 1.5, v.wired * h / 5 + self.wire_h / 2 )
            end
        end

        for i, v in ipairs( self.wires.right ) do
            local pos = self.y_pos[i] * h

            --  > Wire
            AmongUs.DrawMaterial( materials.wire, w * 0.995 - self.wire_w, pos, self.wire_w, self.wire_h, v.color )

            draw.RoundedBox( 0, w - self.wire_w * 1.5, pos, self.wire_w / 2, self.wire_h, Color( 117, 74, 24 ) )

            --draw.RoundedBox( 0, w - self.wire_w, pos - self.wire_h, self.wire_w, self.wire_h, v.good and self.colors[1] or color_white )
        end

        if not self.grabbed or not self.mx or not self.my or not self.wires.left[ self.grabbed ] then return end
        surface.SetDrawColor( self.wires.left[ self.grabbed ].color )
        surface.DrawLine( self.wire_w, self.grabbed * h / 5 + self.wire_h / 2, self.mx, self.my )
    end,
    click = function( self, x, y, button, is_down )
        if button ~= MOUSE_LEFT then return end

        if is_down then
            if x < self.wire_w then -- > On the left
                for i, v in ipairs( self.wires.left ) do
                    local pos = i * self.h / 5

                    if y > pos and y < pos + self.wire_h then
                        if v.wired then continue end

                        self.grabbed = i

                        self.mx = x
                        self.my = y

                        return
                    end
                end
            elseif x > self.w - self.wire_w * 1.5 and x < self.w - self.wire_w then -- > On the right
                for i, v in ipairs( self.wires.right ) do
                    local pos = i * self.h / 5

                    if y > pos and y < pos + self.wire_h then
                        if not v.wired then continue end

                        self.grabbed = v.wired

                        self.wires.left[ v.wired ].wired = nil
                        v.wired = nil

                        self.mx = x
                        self.my = y

                        return
                    end
                end
            end
        else
            if not self.grabbed then return end

            if x > self.w - self.wire_w * 1.5 and x < self.w - self.wire_w then
                for i, v in ipairs( self.wires.right ) do
                    if v.wired then continue end

                    local pos = i * self.h / 5
    
                    if y > pos and y < pos + self.wire_h then
                        local left = self.wires.left[ self.grabbed ]
                        left.wired = i
                        v.wired = self.grabbed

                        v.good = v.color == left.color

                        surface.PlaySound( ( "amongus/tasks/fix_wiring/wire0%d.wav" ):format( math.random( 1, 3 ) ) )

                        if self:can_submit() then
                            self:submit()
                        end
    
                        break
                    end
                end
            end

            self.grabbed = nil
        end
    end,
    cursor_moved = function( self, x, y )
        self.mx = x
        self.my = y
    end,
    close = function( self )
        surface.PlaySound( "amongus/tasks/fix_wiring/close.wav" )
    end,
}