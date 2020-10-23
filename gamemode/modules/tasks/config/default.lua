return {
    name = "Default",
    w = nil,
    h = nil,
    background_color = Color( 0, 0, 0 ),
    init = function( self )
        self.clicks = {}

        for i = 1, math.random( 10, 15 ) do
            self:add_click()
        end
    end,
    add_click = function( self, id )
        if not id and #self.clicks >= 50 then return end

        local radius = math.random( 16, 32 )
        self.clicks[ id or ( #self.clicks + 1 ) ] = {
            x = math.random( 32, self.w - radius * 2 ),
            y = math.random( 32, self.h - radius * 2 ),
            radius = radius,
            color = ColorRand(),
        } 
    end,
    update = function( self, dt )
        for i, v in ipairs( self.clicks ) do
            v.radius = v.radius - dt * 2

            if v.radius <= 0 then
                self:add_click( i )
                self:add_click()
            end
        end
    end,
    paint = function( self, w, h )
        for i, v in ipairs( self.clicks ) do
            AmongUs.DrawCircle( v.x, v.y, v.radius, nil, nil, v.color )
        end
    end,
    click = function( self, x, y, button, is_down )
        if not is_down then return end

        for i, v in ipairs( self.clicks ) do
            if math.Distance( v.x, v.y, x, y ) <= v.radius then
                table.remove( self.clicks, i )

                if #self.clicks == 0 then
                    self:submit()
                end
                
                break
            end
        end
    end,
    cursor_moved = function( self, x, y )
    end,
    close = function( self )
    end,
}