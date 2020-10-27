local materials = CLIENT and AmongUs.GetMaterialsInFolder( "amongus/tasks/swipe_card" )

local function is_collide( a_x, a_y, a_w, a_h, b_x, b_y, b_w, b_h )
    return a_x <= b_x + b_w and a_y <= b_y + b_h and b_x <= a_x + a_w and b_y <= a_y + a_h
end

local gray, green = Color( 125, 125, 125 ), Color( 100, 195, 100 )
return {
    name = "Swipe Card",
    type = AU_TASK_SHORT,
    w = AmongUs.SquareTaskSize,
    h = AmongUs.SquareTaskSize,
    min_time = .5, --  > Minimal time toke to do this task (used by anti-cheat system)
    no_clipping = true, --  > Draw outside canvas
    mouse_outside_canvas = true, --  > Enables custom mouse callbacks (allow clicks/drags outside canvas)
    texts = {
        insert = "PLEASE INSERT CARD",
        swipe = "PLEASE SWIPE CARD",
        bad_read = "BAD READ. TRY AGAIN.",
        too_slow = "TOO SLOW. TRY AGAIN.",
        too_fast = "TOO FAST. TRY AGAIN.",
        accepted = "ACCEPTED. THANK YOU.",
    },
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

        self.red_del_x = self:calc_x( 408 )
        self.red_del_color = gray
        self.green_del_x = self:calc_x( 449 )
        self.green_del_color = gray
        self.del_size = self:calc_x( materials.red_del:Width() )
        self.del_y = self:calc_y( 116 )

        self.card = {
            x = 0,
            y = 0,
            origin_x = self:calc_x( 55 ),
            origin_y = self:calc_y( 389 ),
            w = self:calc_x( materials.card:Width() ),
            h = self:calc_y( materials.card:Height() ),
            start_time = 0,
            size_factor = 0,
            to_size_factor = 0,
            origin_size_factor = .75,
            anim_speed = 4,
            inserted = false,
            done = false,
            dragged_x = nil,
            min_time = .5,
            max_time = .85,
        }
        self.card.x = self.card.origin_x
        self.card.y = self.card.origin_y
        self.card.size_factor = self.card.origin_size_factor
        self.card.to_size_factor = self.card.size_factor

        self.console_text = self.texts.insert
    end,
    update = function( self, dt )
        --  > Anim Position
        if self.card.inserted then
            if self.card.done then
                self.card.x = Lerp( dt * self.card.anim_speed, self.card.x, self.card.origin_x )
                self.card.y = Lerp( dt * self.card.anim_speed, self.card.y, self.card.origin_y )
            else
                if not self.card.dragged_x then
                    self.card.x = Lerp( dt * self.card.anim_speed, self.card.x, -self.card.w / 2 )
                end
                self.card.y = Lerp( dt * self.card.anim_speed, self.card.y, self.console_h - self.card.h / 2.5 )
            end
        end

        --  > DELs
        if self.card.inserted and not self.card.dragged_x then
            self.green_del_color = self.red_del_color == color_white and gray or green
        else
            self.green_del_color = gray
            self.red_del_color = gray
        end

        --  > Size
        self.card.size_factor = Lerp( dt * self.card.anim_speed, self.card.size_factor, self.card.done and self.card.origin_size_factor or self.card.to_size_factor )
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
    
        --  > DELs
        AmongUs.DrawMaterial( materials.red_del, self.red_del_x, self.del_y, self.del_size, self.del_size, self.red_del_color )
        AmongUs.DrawMaterial( materials.green_del, self.green_del_x, self.del_y, self.del_size, self.del_size, self.green_del_color )

        --  > Text
        draw.SimpleText( self.console_text, "AmongUs:SwipeCard", self:calc_x( CurTime() % 3 <= 1.5 and 50 or 47 ), self:calc_y( 20 ) )
    end,
    click = function( self, x, y, button, is_down )
        if self.card.done then return end

        if not is_down then
            if self.card.size_factor < .94 then return end
            self.card.dragged_x = nil

            if self.card.x >= ( self.w - self.card.w / 2 ) * .95 then
                --  > Too Fast
                if self.card.start_time + self.card.min_time > CurTime() then
                    surface.PlaySound( "amongus/tasks/swipe_card/deny.wav" )
                    self.red_del_color = color_white
                    self.console_text = self.texts.too_fast
                --  > Too Slow
                elseif self.card.start_time + self.card.max_time < CurTime() then
                    surface.PlaySound( "amongus/tasks/swipe_card/deny.wav" )
                    self.red_del_color = color_white
                    self.console_text = self.texts.too_slow
                --  > Purfect
                else
                    surface.PlaySound( "amongus/tasks/swipe_card/accept.wav" )
                    self.console_text = self.texts.accepted
                    self.green_del_color = color_white
                    self.card.done = true
                    self:submit()
                end
            --  > Bad Read
            else
                surface.PlaySound( "amongus/tasks/swipe_card/deny.wav" )
                self.console_text = self.texts.bad_read
                self.red_del_color = color_white
            end

            timer.Create( "AmongUs:SwipeCardText", 1, 1, function()
                self.console_text = self.texts.swipe
                self.red_del_color = gray
            end )

            return 
        else
            if is_collide( self.card.x, self.card.y, self.card.w * self.card.size_factor, self.card.h * self.card.size_factor, x, y, 1, 1 ) then
                if not self.card.inserted then
                    self.card.inserted = true
                    self.card.to_size_factor = .95
                    self.console_text = self.texts.swipe

                    surface.PlaySound( "amongus/tasks/swipe_card/walletout.wav" )
                else
                    self.card.dragged_x = self.card.x - x
                    self.card.start_time = CurTime()
                    surface.PlaySound( ( "amongus/tasks/swipe_card/move0%d.wav" ):format( math.random( 3 ) ) )
                end
            end
        end
    end,
    cursor_moved = function( self, x, y )
        if not self.card.inserted then return end
        
        if self.card.dragged_x then
            self.card.x = math.Clamp( self.card.dragged_x + x, -self.card.w / 2, self.w - self.card.w / 2 )
        end
    end,
    close = function( self )
        surface.PlaySound( "amongus/generic_disappear.wav" )
    end,
}