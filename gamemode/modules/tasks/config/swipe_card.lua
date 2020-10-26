local materials = CLIENT and AmongUs.GetMaterialsInFolder( "amongus/tasks/swipe_card" )

local function is_collide( a_x, a_y, a_w, a_h, b_x, b_y, b_w, b_h )
    return a_x <= b_x + b_w and a_y <= b_y + b_h and b_x <= a_x + a_w and b_y <= a_y + a_h
end

return {
    name = "Swipe Card",
    type = AU_TASK_SHORT,
    w = AmongUs.SquareTaskSize,
    h = AmongUs.SquareTaskSize,
    min_time = .5, --  > Minimal time toke to do this task (used by anti-cheat system)
    no_clipping = true, --  > Draw outside canvas
    calc_x = function( self, x )
        return x * self.w / materials.base:Width()
    end,
    calc_y = function( self, y )
        return y * self.h / materials.base:Height()
    end,
    init = function( self )
        surface.PlaySound( "amongus/generic_appear.wav" )

        --  > Maths
        self.console_h = self:calc_y( materials.console:Height() )
        self.console_mask_h = self:calc_y( materials.console_mask:Height() ) * .75
        
        self.wallet_w = self:calc_x( materials.wallet:Width() )
        self.wallet_h = self:calc_y( materials.wallet:Height() )

        self.wallet_mask_w = self:calc_x( materials.wallet_mask:Width() )
        self.wallet_mask_h = self:calc_y( materials.wallet_mask:Height() )

        self.card = {
            x = self:calc_x( 55 ),
            y = self:calc_y( 389 ),
            w = self:calc_x( materials.card:Width() ),
            h = self:calc_y( materials.card:Height() ),
            size_factor = .75,
            anim_speed = 4, 
            inserted = false,
            dragged_x = nil,
        }
        self.card.to_size_factor = self.card.size_factor

        self.console_text = "PLEASE INSERT CARD"
    end,
    update = function( self, dt )
        if self.card.inserted and not self.card.dragged_x then
            self.card.x = Lerp( dt * self.card.anim_speed, self.card.x, -self.card.w / 2 )
            self.card.y = Lerp( dt * self.card.anim_speed, self.card.y, self.console_h - self.card.h / 2 )
        end

        self.card.size_factor = Lerp( dt * self.card.anim_speed, self.card.size_factor, self.card.to_size_factor )
    end,
    paint = function( self, w, h )
        --  > Base
        AmongUs.DrawMaterial( materials.base, 0, 0, w, h )

        AmongUs.DrawMaterial( materials.console_mask, 0, h / 2 - self.console_mask_h + 1, w, self.console_mask_h )

        --  > Wallet
        AmongUs.DrawMaterial( materials.wallet, w / 2 - self.wallet_w / 2, h - self.wallet_h, self.wallet_w, self.wallet_h )

        --  > Card
        AmongUs.DrawMaterial( materials.card, self.card.x, self.card.y, self.card.w * self.card.size_factor, self.card.h * self.card.size_factor )

        --  > Card Hiders
        AmongUs.DrawMaterial( materials.console, 0, 0, w, self.console_h )
        AmongUs.DrawMaterial( materials.wallet_mask, w / 2 - self.wallet_w / 2 + self:calc_x( 11 ), h - self.wallet_mask_h, self.wallet_mask_w, self.wallet_mask_h )
    
        --  > Text
        draw.SimpleText( self.console_text, "AmongUs:SwipeCard", self:calc_x( CurTime() % 3 <= 1.5 and 50 or 47 ), self:calc_y( 20 ) )
    end,
    click = function( self, x, y, button, is_down )
        if not is_down then 
            self.card.dragged_x = nil 
            return 
        end

        if is_collide( self.card.x, self.card.y, self.card.w * self.card.size_factor, self.card.h * self.card.size_factor, x, y, 1, 1 ) then
            if not self.card.inserted then
                self.card.inserted = true
                self.card.to_size_factor = .95
                self.console_text = "PLEASE SWIPE CARD"
            else
                self.card.dragged_x = x - self.card.x 
            end
        end
    end,
    cursor_moved = function( self, x, y )
        if self.card.dragged_x then
            self.card.x = self.card.dragged_x + x - self.card.w
        end
    end,
    close = function( self )
        surface.PlaySound( "amongus/generic_disappear.wav" )
    end,
}