local materials = CLIENT and AmongUs.GetMaterialsInFolder( "amongus/tasks/align_engine_output" )

--  > https://wiki.facepunch.com/gmod/surface.DrawTexturedRectRotated
local function draw_textured_rect_rotated_point( x, y, w, h, rot, x0, y0 )
	local c = math.cos( math.rad( rot ) )
	local s = math.sin( math.rad( rot ) )
	
	local newx = y0 * s - x0 * c
	local newy = y0 * c + x0 * s
	
	surface.DrawTexturedRectRotated( x + newx, y + newy, w, h, rot )
end

local function angle_to( a_x, a_y, b_x, b_y )
    return math.deg( math.atan2( b_y - a_y, b_x - a_x ) )
end

local green, red = Color( 39, 240, 30 ), Color( 230, 6, 9 )
return {
    name = "Align Engine Output",
    type = AU_TASK_SHORT,
    w = AmongUs.SquareTaskSize,
    h = AmongUs.SquareTaskSize,
    disable_entity_task = true, --  > Disable Task Entity to be redone on the same player
    max_stages = 2,
    --no_clipping = true,
    init = function( self )
        surface.PlaySound( "amongus/generic_appear.wav" )

        self.mouse = { x = 0, y = 0 }

        --  > Screen
        local img_w, img_h = materials.base:Width(), materials.base:Height()
        self.screen = {
            x = 38 * self.w / img_w,
            y = 35 * self.h / img_h,
            w = 342 * self.w / img_w,
            h = 464 * self.h / img_h,
            color = Color( 10, 29, 10 ),
        }
        self.screen.w = self.screen.w - self.screen.x
        self.screen.h = self.screen.h - self.screen.y

        --  > Slider
        self.slider = {
            origin_x = 500 * self.w / img_w,
            origin_y = 250 * self.h / img_h,
            radius_x = 90 * self.w / img_w,
            radius_y = 245 * self.h / img_h,
            w = 95 * self.w / materials.base:Width(),
            h = 41 * self.h / materials.base:Height(),
            angle = 0,
            shadow_angle_diff = 1,
            max_angle = 60,
            angle_tolerance = 5,
        }
        self.slider.angle = math.random( self.slider.angle_tolerance * 2, self.slider.max_angle ) * ( math.random( 0, 1 ) == 0 and -1 or 1 )
    end,
    update = function( self, dt )
        self.slider.x = self.slider.origin_x - math.cos( math.rad( self.slider.angle ) ) * self.slider.radius_x
        self.slider.y = self.slider.origin_y - math.sin( math.rad( self.slider.angle ) ) * self.slider.radius_y

        if self.grabbed then
            self.slider.angle = math.Clamp( angle_to( self.mouse.x, self.mouse.y, self.slider.origin_x + self.slider.radius_x, self.slider.origin_y ), -self.slider.max_angle, self.slider.max_angle )
        end
    end,
    draw_line = function( self, y, color )
        local img_w, img_h = materials.dotted_line:Width() * self.w / self.screen.w, materials.dotted_line:Height() * self.h / self.screen.h * 1.5
        for i = 0, math.ceil( self.screen.w / img_w ) do
            AmongUs.DrawMaterial( materials.dotted_line, self.screen.x + self.screen.w - i * img_w - ( CurTime() * img_w % img_w ), self.screen.y + y - img_h / 2, img_w, img_h, color )
        end
    end,
    paint = function( self, w, h )
        --  > Screen
        draw.RoundedBox( 0, self.screen.x, self.screen.y, self.screen.w, self.screen.h, self.screen.color )
    
        --  > Engine
        local img_w, img_h = self.screen.w * 1.25, materials.engine:Height() * 1.7
        surface.SetMaterial( materials.engine )
        surface.SetDrawColor( red )
        draw_textured_rect_rotated_point( self.screen.x + self.screen.w, self.screen.y + self.screen.h / 2, img_w, img_h, -self.slider.angle * .7, img_w / 2, 0 )
        
        --  > Target Line
        self:draw_line( self.screen.h / 2, math.abs( self.slider.angle ) <= self.slider.angle_tolerance and green or red )
        if self.done and CurTime() % .5 <= .25 then
            self:draw_line( self.screen.h / 2 - img_h / 2 )
            self:draw_line( self.screen.h / 2 + img_h / 2 )
        end

        --  > Base
        AmongUs.DrawMaterial( materials.base, 0, 0, w, h )

        --  > Slider
        --[[ surface.SetDrawColor( red )
        local last_x, last_y = 0, 0
        for i = 0, 360, 2 do
            local ang = math.rad( i )
            local x, y = math.cos( ang ) * self.slider.radius_x, math.sin( ang ) * self.slider.radius_y
            surface.DrawLine( self.slider.origin_x + x, self.slider.origin_y + y, self.slider.origin_x + last_x, self.slider.origin_y + last_y )
            last_x, last_y = x, y
        end

        surface.DrawLine( self.slider.origin_x, self.slider.origin_y, self.mouse.x, self.mouse.y )
        local angle = angle_to( self.mouse.x, self.mouse.y, self.slider.origin_x + self.slider.radius_x, self.slider.origin_y )
        draw.SimpleText( angle )
        draw.RoundedBox( 0, self.slider.x, self.slider.y, self.slider.w, self.slider.h, color_white )]]
        
        local slider_angle = -self.slider.angle
        AmongUs.DrawMaterial( materials.slider_shadow, self.slider.origin_x - math.cos( math.rad( self.slider.angle - self.slider.shadow_angle_diff ) ) * self.slider.radius_x, self.slider.origin_y - math.sin( math.rad( self.slider.angle - self.slider.shadow_angle_diff ) ) * self.slider.radius_y, self.slider.w, self.slider.h, nil, slider_angle )
        AmongUs.DrawMaterial( materials.slider, self.slider.x, self.slider.y, self.slider.w, self.slider.h, nil, slider_angle )
    end,
    click = function( self, x, y, button, is_down )
        if is_down then
            if math.Distance( x, y, self.slider.x, self.slider.y ) <= ( self.slider.w + self.slider.h ) / 2 then
                self.grabbed = true
            end
        else
            self.grabbed = false

            if math.abs( self.slider.angle ) <= self.slider.angle_tolerance then
                self:submit( true )
                self.done = true
            end
        end
    end,
    cursor_moved = function( self, x, y )
        self.mouse.x = x
        self.mouse.y = y
    end,
    close = function( self )
        surface.PlaySound( "amongus/generic_disappear.wav" )
    end,
}