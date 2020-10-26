local materials = {
    base = Material( "amongus/tasks/prime_shields/base.png" ),
    big_shield = Material( "amongus/tasks/prime_shields/big_shield.png" ),
    shield = Material( "amongus/tasks/prime_shields/shield.png" ),
}

local colors = {
    big_shield_red = Color( 212, 127, 130 ),
    shield_red = Color( 235, 31, 24 ),
}

return {
    name = "Prime Shields",
    type = AU_TASK_SHORT,
    w = AmongUs.SquareTaskSize,
    h = AmongUs.SquareTaskSize,
    min_time = .1, --  > Minimal time toke to do this task (used by anti-cheat system)
    init = function( self )
        surface.PlaySound( "amongus/generic_appear.wav" )

        --  > Big shield maths
        self.big_shield_angle = 0
        self.big_shield_size = self.w * .885

        --  > Doing maths, yea again
        local w, h = self.big_shield_size / 3, self.big_shield_size / 3.5
        self.shields = {}
        self.shield_radius = materials.shield:Width() / 2 * 1.5

        --  > Create shields
        local space = self.big_shield_size * .01
        local x, y = self.big_shield_size / 2 - w * 1.11, self.big_shield_size / 2 - h * .8
        for i = 1, 7 do
            self.shields[i] = {
                id = i,
                x = x,
                y = y,
                w = w,
                h = h,
                active = true,
            }

            y = y + h + space
            if i == 2 then
                x = x + w / 1.3 + space
                y = y - ( h + space ) * 2 - h / 2
            elseif i == 5 then
                x = x + w / 1.3 + space
                y = y - ( h + space ) * 3 + h / 2
            end
        end

        --  > Disactive shields
        local shields = table.Copy( self.shields )
        for i = 1, math.random( #self.shields ) do
            self.shields[table.remove( shields, math.random( #shields ) ).id].active = false
        end
    end,
    can_submit = function( self )
        for i, v in ipairs( self.shields ) do
            if not v.active then return false end
        end

        return true
    end,
    update = function( self, dt )
        if self.done then
            self.big_shield_angle = self.big_shield_angle + dt * 50
        end
    end,
    paint = function( self, w, h )
        --  > Base
        AmongUs.DrawMaterial( materials.base, 0, 0, w, h )

        --  > Big Shield
        local disactives = 0
        for i, v in ipairs( self.shields ) do
            if not v.active then
                disactives = disactives + 1
            end
        end
        AmongUs.DrawMaterial( materials.big_shield, w / 2, h / 2, self.big_shield_size, self.big_shield_size, AmongUs.LerpColor( disactives / #self.shields, color_white, colors.shield_red ), self.big_shield_angle )
    
        --  > Shields
        for i, v in ipairs( self.shields ) do
            AmongUs.DrawMaterial( materials.shield, v.x, v.y, v.w, v.h, v.active and color_white or colors.shield_red )
        end
    end,
    click = function( self, x, y, button, is_down )
        if self.done or not is_down then return end

        local should_check = false
        for i, v in ipairs( self.shields ) do
            if math.Distance( v.x + v.w / 2, v.y + v.h / 2, x, y ) <= self.shield_radius then
                v.active = not v.active
                should_check = true

                surface.PlaySound( v.active and "amongus/shield_on.wav" or "amongus/shield_off.wav" )
                break
            end
        end

        --  > Check
        if should_check and self:can_submit() then
            self:submit()
            self.done = true
        end
    end,
    cursor_moved = function( self, x, y )
    end,
    close = function( self )
        surface.PlaySound( "amongus/generic_disappear.wav" )
    end,
}