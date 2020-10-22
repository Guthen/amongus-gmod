local materials = {
    base = Material( "amongus/tasks/stabilize_steering/base.png" ),
    graph = Material( "amongus/tasks/stabilize_steering/graph.png" ),
    target = Material( "amongus/tasks/stabilize_steering/target.png" ),
}

return {
    name = "Stabilize Steering",
    w = AmongUs.SquareTaskSize,
    h = AmongUs.SquareTaskSize,
    background_color = Color( 0, 0, 0, 0 ),
    min_time = .1, --  > Minimal time toke to do this task (used by anti-cheat system)
    init = function( self )
        self.space = self.w * 0.037

        self.x = math.random( self.space * 3, self.w - self.space * 3 )
        self.y = math.random( self.space * 3, self.h - self.space * 3 )
    end,
    check_submit = function( self )
        if math.Distance( self.w / 2, self.h / 2, self.x, self.y ) > self.bar * 4 then return end

        self.good = CurTime()

        self.x = self.w / 2
        self.y = self.h / 2

        self:submit()
    end,
    update = function( self, dt )
    end,
    paint = function( self, w, h )
        AmongUs.DrawMaterial( materials.graph, self.space, self.space, w - self.space * 2, h - self.space * 2 )

        local col = self.good and ( CurTime() * 8 % 2 > 1 and Color( 255, 202, 0 ) or color_white ) or color_white
        if self.good and self.good + 0.6 <= CurTime() then
            col = Color( 0, 204, 0 )
        end

        local size = w * 0.28
        AmongUs.DrawMaterial( materials.target, self.x - size / 2, self.y - size / 2, size, size, col )

        self.bar = size * 0.05
        draw.RoundedBox( 0, 0, self.y - self.bar / 2, w, self.bar, col )
        draw.RoundedBox( 0, self.x - self.bar / 2, 0, self.bar, h, col )

        AmongUs.DrawMaterial( materials.base, 0, 0, w, h )
    end,
    click = function( self, x, y, button, is_down )
        if self.good then return end
        if button ~= MOUSE_LEFT then return end
        if math.Distance( self.w / 2, self.h / 2, x, y ) > ( self.w - self.space * 2 ) / 2 then return end

        self.x = x
        self.y = y

        if is_down then return end
        self:check_submit()
    end,
    cursor_moved = function( self, x, y )
        if self.good then return end
        if not input.IsButtonDown( MOUSE_LEFT ) then return end
        if math.Distance( self.w / 2, self.h / 2, x, y ) > ( self.w - self.space * 2 ) / 2 then return end

        self.x = x
        self.y = y
    end,
    close = function( self )
    end,
}