local materials = {
    base = Material( "amongus/tasks/clear_asteroids/base.png" ),
    cursor = Material( "amongus/tasks/clear_asteroids/cursor.png" ),
    explosion = Material( "amongus/tasks/clear_asteroids/explosion.png" ),
    asteroids = {},
}

--  > Get asteroids images
for i = 1, 5 do
    materials.asteroids[i] = {
        [true] = Material( ( "amongus/tasks/clear_asteroids/asteroid0%d.png" ):format( i ) ),
        [false] = Material( ( "amongus/tasks/clear_asteroids/asteroid0%d_dead.png" ):format( i ) ),
    }
end

local function is_collide( a_x, a_y, a_w, a_h, b_x, b_y, b_w, b_h )
    return a_x <= b_x + b_w and a_y <= b_y + b_h and b_x <= a_x + a_w and b_y <= a_y + a_h
end

local function angle_to( a_x, a_y, b_x, b_y )
    return math.deg( math.atan2( a_y - b_y, b_x - a_x ) )
end

--  > https://wiki.facepunch.com/gmod/surface.DrawTexturedRectRotated
local function draw_textured_rect_rotated_point( x, y, w, h, rot, x0, y0 )
	local c = math.cos( math.rad( rot ) )
	local s = math.sin( math.rad( rot ) )
	
	local newx = y0 * s - x0 * c
	local newy = y0 * c + x0 * s
	
	surface.DrawTexturedRectRotated( x + newx, y + newy, w, h, rot )
end

return {
    name = "Clear Asteroids",
    type = AU_TASK_LONG,
    w = AmongUs.SquareTaskSize,
    h = AmongUs.SquareTaskSize,
    max_stages = 20, --  > Stages: represent number of step before accomplishement
    sprites_size_factor = .65,
    asteroid_hitbox_factor = .8,
    init = function( self )
        --  > Base
        self.base = {}
        self.base.pos = 29 * self.w / materials.base:Width()
        self.base.size = 479 * self.w / materials.base:Height() - self.base.pos

        --  > Fire
        self.fire_time, self.fire_max_time = 0, .25

        --  > Asteroids
        self.asteroids = {}
        self.asteroid_time, self.asteroid_max_time, self.asteroid_max = 0, .5, 5

        --  > Explosion
        self.explosions = {}

        --  > Cursor
        local size = self.w * .14
        self.cursor = {
            x = self.w / 2 - size / 2,
            y = self.h / 2 - size / 2,
            size_factor = 1,
            size = size,
        }

        --  > Alpha
        self.alpha = {
            min = .5,
            max = .85,
            increase = true
        }
        self.alpha.value = self.alpha.min
        self.alpha.factor = self.alpha.max - self.alpha.min
    end,
    add_asteroid = function( self )
        if #self.asteroids >= self.asteroid_max then return end

        local asteroid = {
            x = math.random( self.base.pos + self.base.size, self.w ),
            get_size = function( asteroid )
                local img = asteroid.images[asteroid.alive]
                return img:Width() * self.w / materials.base:Width() * self.sprites_size_factor, img:Height() * self.w / materials.base:Height() * self.sprites_size_factor
            end,
            vel_x = math.random( -self.base.size / 4, -self.base.size / 2 ) * 2.5,
            angle = math.random( 360 ),
            angle_speed = math.random( 360 ),
            images = table.Random( materials.asteroids ),
            alive = true,
            dead_time = .15,
        }
        local w, h = asteroid:get_size()
        asteroid.y = math.random( self.base.pos, self.base.pos + self.base.size - h / 2 )
        asteroid.vel_y = math.random( self.base.size / 4, asteroid.vel_x / 4 )

        self.asteroids[#self.asteroids + 1] = asteroid
    end,
    update = function( self, dt )
        --  > Alpha
        self.alpha.value = math.Approach( self.alpha.value, self.alpha.increase and self.alpha.max or self.alpha.min, dt * self.alpha.factor )
        if self.alpha.value >= self.alpha.max or self.alpha.value <= self.alpha.min then
            self.alpha.increase = not self.alpha.increase
        end

        --  > Fire
        self.fire_time = self.fire_time + dt

        --  > Asteroids
        for i, v in ipairs( self.asteroids ) do
            local img = v.images[v.alive]
            if v.x < self.base.size and not is_collide( self.base.pos, self.base.pos, self.base.size, self.base.size, v.x, v.y, img:Width(), img:Height() ) then
                table.remove( self.asteroids, i )
            else
                if v.alive then
                    if not v.explosion then
                        v.x = v.x + dt * v.vel_x
                        v.y = v.y + dt * v.vel_y
                        v.angle = v.angle + dt * v.angle_speed
                    elseif v.explosion.dead then
                        v.alive = false
                    end
                else
                    v.dead_time = v.dead_time - dt
                    if v.dead_time <= 0 then
                        table.remove( self.asteroids, i )
                    end
                end
            end
        end

        --  > Explosions
        for i, v in ipairs( self.explosions ) do
            v.scale = Lerp( dt * 50, v.scale, v.increment and 1 or 0 )
            if v.scale >= .95 then
                v.increment = false
            elseif v.scale <= .01 then
                v.dead = true
                table.remove( self.explosions, i )
            end
        end

        --  > Spawn Asteroids
        self.asteroid_time = self.asteroid_time + dt
        if AmongUs.PlayerTasks[self.id].stages < self.max_stages and self.asteroid_time >= self.asteroid_max_time then
            self:add_asteroid()
            self.asteroid_time = 0
        end
    end,
    paint = function( self, w, h )
        --  > Base
        surface.SetAlphaMultiplier( self.alpha.value )
        AmongUs.DrawMaterial( materials.base, 0, 0, w, h )
        surface.SetAlphaMultiplier( 1 )
        
        --  > Lines
        draw.NoTexture()
        surface.SetDrawColor( 36, 97, 63 )

        --  > Left Line
        local x, y = self.base.pos, self.base.pos + self.base.size
        local line_w, line_h = math.Distance( self.cursor.x + self.cursor.size / 2, self.cursor.y + self.cursor.size / 2, x, y ), h * .015
        local angle = angle_to( x, y, self.cursor.x + self.cursor.size / 2, self.cursor.y + self.cursor.size / 2 )
        draw_textured_rect_rotated_point( x, y, line_w, line_h, angle, -line_w / 2, 0 )

        --  > Right Line
        x = self.base.pos + self.base.size
        line_w = math.Distance( self.cursor.x + self.cursor.size / 2, self.cursor.y + self.cursor.size / 2, x, y ), h * .015
        angle = angle_to( x, y, self.cursor.x + self.cursor.size / 2, self.cursor.y + self.cursor.size / 2 )
        draw_textured_rect_rotated_point( x, y, line_w, line_h, angle, -line_w / 2, 0 )

        --  > Scene
        AmongUs.DrawStencil( function()
            draw.RoundedBox( 0, self.base.pos, self.base.pos, self.base.size, self.base.size, color_white )
        end,
        function()
            --  > Asteroids
            for i, v in ipairs( self.asteroids ) do
                local img = v.images[v.alive]
                local w, h = v:get_size()
                AmongUs.DrawMaterial( img, v.x + w / 2, v.y + h / 2, w, h, nil, v.angle )
            end

            --  > Explosions
            for i, v in ipairs( self.explosions ) do
                AmongUs.DrawMaterial( materials.explosion, v.x, v.y, v.w * v.scale, v.h * v.scale, Color( 120, 240, 177 ), 0 )
            end

            --  > Cursor
            AmongUs.DrawMaterial( materials.cursor, self.cursor.x, self.cursor.y, self.cursor.size, self.cursor.size )
        end )

        --  > Counter
        draw.SimpleText( "Destroyed: " .. AmongUs.PlayerTasks[self.id].stages, "AmongUs:Asteroids", w / 2, self.base.size, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
    end,
    click = function( self, x, y, button, is_down )
        if not is_down then return end
        if AmongUs.PlayerTasks[self.id].stages >= self.max_stages then return end
        if self.fire_time < self.fire_max_time then return end
        if not is_collide( self.base.pos, self.base.pos, self.base.size, self.base.size, x, y, 1, 1 ) then return end

        self.fire_time = 0

        --  > Positionate Cursor
        self.cursor.x = x - self.cursor.size / 2
        self.cursor.y = y - self.cursor.size / 2
        surface.PlaySound( "amongus/tasks/clear_asteroids/fire.wav" )

        --  > Destroy Asteroid
        timer.Simple( .1, function()
            local destroyed = 0
            for i, v in ipairs( self.asteroids ) do
                local w, h = v:get_size()
                if v.alive and not v.explosion and is_collide( v.x + w * ( 1 - self.asteroid_hitbox_factor ), v.y + h * ( 1 - self.asteroid_hitbox_factor ), w * self.asteroid_hitbox_factor, h * self.asteroid_hitbox_factor, self.cursor.x, self.cursor.y, self.cursor.size, self.cursor.size ) then
                    destroyed = destroyed + 1

                    --  > Add explosion
                    local explosion = {
                        x = v.x + w / 2,
                        y = v.y + h / 2,
                        w = materials.explosion:Width() * self.w / materials.base:Width() * self.sprites_size_factor,
                        h = materials.explosion:Height() * self.h / materials.base:Height() * self.sprites_size_factor,
                        scale = .1,
                        increment = true,
                    }
                    self.explosions[#self.explosions + 1] = explosion
                    v.explosion = explosion

                    surface.PlaySound( ( "amongus/tasks/clear_asteroids/hit0%d.wav" ):format( math.random( 1, 3 ) ) )
                end
            end

            if destroyed > 0 then
                for i = 1, destroyed do --  > submit up stages to 1 so as we can destroy multiple asteroids..
                    self:submit( AmongUs.PlayerTasks[self.id].stages + destroyed >= self.max_stages )
                end
            end
        end )
    end,
    cursor_moved = function( self, x, y )
    end,
    custom_close = function( self, time, main, close )
        local new_tall = main:GetTall() * .2
        main:SizeTo( main:GetWide(), new_tall, time / 2, 0, 1, function()
            main:SizeTo( 0, 0, time / 2, 0, 1, function()
                main:Remove()
            end )
            main:MoveTo( ScrW() / 2, ScrH() / 2, time / 2, 0, 1 )

            close:SizeTo( 0, close:GetTall(), time / 2, 0, 1 )
        end )
        main:MoveTo( main.x, ScrH() / 2 - new_tall / 2, time / 2, 0, 1 )

        close:SizeTo( close:GetWide(), close:GetTall() * .2, time / 2, 0, 1 )
    end,
    close = function( self )
        surface.PlaySound( "amongus/generic_disappear.wav" )
    end,
}