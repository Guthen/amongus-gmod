local size = CLIENT and ScrH() * 0.9

return {
    name = "Fix Wiring",
    w = size,
    h = size,
    wire_h = CLIENT and size / 20,
    wire_w = CLIENT and size * 0.04,
    wires = {
        left = {},
        right = {}
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
        surface.PlaySound( "amongus/wires_open.wav" )
        
        local colors_left = table.Copy( self.colors )
        local colors_right = table.Copy( self.colors )

        for i = 1, 4 do
            self.wires.left[ i ] = {
                color = table.remove( colors_left, math.random( #colors_left ) )
            }

            self.wires.right[ i ] = {
                color = table.remove( colors_right, math.random( #colors_right ) )
            }
        end
    end,
    update = function( self, dt )
    end,
    paint = function( self, w, h )
        for i, v in ipairs( self.wires.left ) do
            local pos = i * h / 5

            draw.RoundedBox( 0, 0, pos, self.wire_w, self.wire_h, v.color )
            draw.RoundedBox( 0, 0, pos - self.wire_h, self.wire_w, self.wire_h, self.colors[1] )

            if v.wired then
                surface.SetDrawColor( v.color )
                surface.DrawLine( self.wire_w, pos + self.wire_h / 2, self.w - self.wire_w * 1.5, v.wired * h / 5 + self.wire_h / 2 )
            end
        end

        for i, v in ipairs( self.wires.right ) do
            local pos = i * h / 5

            draw.RoundedBox( 0, w - self.wire_w, pos, self.wire_w, self.wire_h, v.color )
            draw.RoundedBox( 0, w - self.wire_w * 1.5, pos, self.wire_w / 2, self.wire_h, Color( 117, 74, 24 ) )

            draw.RoundedBox( 0, w - self.wire_w, pos - self.wire_h, self.wire_w, self.wire_h, v.good and self.colors[1] or color_white )
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

                        surface.PlaySound( ( "amongus/wire0%d.wav" ):format( math.random( 1, 3 ) ) )

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
        surface.PlaySound( "amongus/wires_close.wav" )
    end,
}