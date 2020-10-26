local materials = CLIENT and AmongUs.GetMaterialsInFolder( "amongus/tasks/unlock_manifolds" )

local function is_collide( a_x, a_y, a_w, a_h, b_x, b_y, b_w, b_h )
    return a_x <= b_x + b_w and a_y <= b_y + b_h and b_x <= a_x + a_w and b_y <= a_y + a_h
end

local green, red = Color( 0, 191, 91 ), Color( 200, 18, 66 )
return {
    name = "Unlock Manifolds",
    type = AU_TASK_SHORT,
    w = AmongUs.SquareTaskSize,
    h = CLIENT and AmongUs.SquareTaskSize / 2,
    no_clipping = true, --  > Make drawing possible outside panel
    init = function( self )
        surface.PlaySound( "amongus/generic_appear.wav" )

        --  > Pos
        self.screen = {
            x = 36 * self.w / materials.screen:Width(),
            y = 37 * self.h / materials.screen:Height(),
            w = 430 * self.w / materials.screen:Width(), 
            h = 175 * self.h / materials.screen:Height(),
        }

        self.max_fail_time = .75
        self.fail_blank_time = self.max_fail_time * .25

        --  > Generate numbers
        local numbers = {}
        for i = 1, 10 do
            numbers[i] = i
        end

        self.numbers = {}
        local x, y = 0, 0
        local space = self.w * .0035
        local img_w, img_h = self.screen.w / 5, self.screen.h / 2
        for i = 1, 10 do
            self.numbers[i] = {
                value = table.remove( numbers, math.random( #numbers ) ),
                x = self.screen.x + space + x * img_w,
                y = self.screen.y + space + y * img_h,
                w = img_w - space * 2,
                h = img_h - space * 2,
                active = false,
            }

            if i == 5 then 
                y = 1 
                x = 0 
            else
                x = x + 1
            end
        end

        self.last_checked_number = nil
    end,
    update = function( self, dt )
        if self.fail_time then
            self.fail_time = self.fail_time - dt
            if self.fail_time <= 0 then 
                self.fail_time = nil 
            end
        end
    end,
    paint = function( self, w, h )
        --  > Supports
        AmongUs.DrawMaterial( materials.bottom_support, w * .02, h * .96, w * .2, h * 1.1 )
        local img_w, img_h = w * .3, h * 2.1
        AmongUs.DrawMaterial( materials.left_support, -img_w / 3.5, -img_w / 3, img_w, img_h )

        --  > Base
        AmongUs.DrawMaterial( materials.screen, 0, 0, w, h )

        --  > Numbers
        for i, v in ipairs( self.numbers ) do
            AmongUs.DrawMaterial( materials["touch" .. v.value], v.x, v.y, v.w, v.h, v.active and green or ( self.fail_time and ( self.fail_time > self.max_fail_time / 2 + self.fail_blank_time / 2 or self.fail_time < self.max_fail_time / 2 - self.fail_blank_time / 2 ) and red ) or color_white )
        end

        --  > Overlay
        AmongUs.DrawMaterial( materials.screen_overlay, self.screen.x, self.screen.y, self.screen.w, self.screen.h, Color( 255, 255, 255, 150 ) )
    end,
    click = function( self, x, y, button, is_down )
        if not is_down then return end
        if self.fail_time then return end

        for i, v in ipairs( self.numbers ) do
            if is_collide( v.x, v.y, v.w, v.h, x, y, 1, 1 ) then
                v.active = true
                --  > Good number
                if v.value == ( self.last_checked_number or 0 ) + 1 then
                    if v.value == 10 then
                        self:submit()
                    end
                    self.last_checked_number = v.value
                --  > Bad number
                else
                    for i, v in ipairs( self.numbers ) do
                        v.active = false
                    end
                    self.last_checked_number = nil

                    self.fail_time = .75
                    surface.PlaySound( "amongus/tasks/unlock_manifolds/fail.wav" )
                end

                EmitSound( "amongus/tasks/unlock_manifolds/correct.wav", Vector(), -1, nil, nil, nil, nil, 100 + v.value * 5 )
                break
            end
        end
    end,
    cursor_moved = function( self, x, y )
    end,
    close = function( self )
        surface.PlaySound( "amongus/generic_disappear.wav" )
    end,
}