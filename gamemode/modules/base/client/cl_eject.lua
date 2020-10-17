local color_black = Color( 0, 0, 0 )
local scenes = {
    {
        init = function( self, w, h )
            --  > Generate stars
            self.stars = {}
            for i = 1, 75 do
                self.stars[i] = { 
                    x = math.random( w ), 
                    y = math.random( h ),
                    radius = math.random() * w * .002,
                }
            end

            --  > Variables
            if isentity( self.target ) then
                self.final_text = AmongUs.GetRoleOf( self.target ):get_eject_sentence( self.target )
            elseif self.target == "Skip" then
                self.final_text = "No One was ejected (Skipped)"
            else
                self.final_text = "No One was ejected (Tie)"
            end
            self.text_state = 0
            self.alpha = 0

            self.sound_played = false
        end,
        update = function( self, dt )
            --  > Move stars
            for i, v in ipairs( self.stars ) do
                if v.x > self.w then
                    v.x = -math.random() * v.radius
                else
                    v.x = v.x + v.radius * dt * 25
                end
            end
            
            --  > Reveal role
            if self.model_x > self.w / 2 - self.model_w / 1.5 then
                self.text_state = math.min( self.text_state + dt * #self.final_text / 2, #self.final_text )
                if not self.sound_played then
                    self.sound_played = true
                    surface.PlaySound( "amongus/typing.wav" )    
                end
            end

            --  > Alpha
            self.alpha = Lerp( FrameTime(), self.alpha, 255 )
        end,
        paint = function( self, w, h )
            draw.RoundedBox( 0, 0, 0, w, h, color_black )

            --  > Stars
            local color = ColorAlpha( color_white, self.alpha )
            for i, v in ipairs( self.stars ) do
                AmongUs.DrawCircle( v.x, v.y, v.radius, nil, nil, color )
            end

            --  > Text
            AmongUs.DrawText( self.final_text:sub( 0, math.ceil( self.text_state ) ), w / 2, h / 2, color, "AmongUs:Little" )
        end,
    }
}

function AmongUs.OpenEjectScene( target )
    local time = .75
    LocalPlayer():ScreenFade( SCREENFADE.OUT, color_black, time - .25, 1 )

    --  > Remove tablet
    if IsValid( AmongUs.VotePanel ) then 
        AmongUs.VotePanel:AlphaTo( 0, time, 0, function()
            AmongUs.VotePanel:Remove()
        end )
    end

    timer.Simple( time, function()
        --  > Create scene
        local w, h = ScrW(), ScrH()
        local scene = setmetatable( {}, { __index = scenes[1] } )
        scene.w, scene.h = w, h
        scene.target = target
        scene:init( w, h )

        target = isentity( target ) and target or NULL

        --  > Scene
        local main = vgui.Create( "DFrame" )
        main:SetSize( w, h )
        main:SetTitle( "" )
        main:SetDraggable( false )
        main:SetSizable( false )
        --main:ShowCloseButton( false )
        main:MakePopup()
        function main:Think()
            scene:update( FrameTime() )
        end
        function main:Paint( w, h )
            scene:paint( w, h )
        end
        scene.main = main
        
        --  > Player
        local size = w * .15
        local model = main:Add( "DModelPanel" )
        --model:Dock( FILL )
        model:SetSize( size, size )
        model.y = h / 2 - size / 2
        model:SetCursor( "none" )
        if IsValid( target ) then 
            model:SetModel( target:GetModel() ) 
            local color = target:GetPlayerColor()
            function model.Entity:GetPlayerColor()
                return color
            end
        end
        --model:SetEntity( target )
        model:SetCamPos( Vector( 0, 75, 36 ) )
        model:MoveTo( w, model.y, 6, 0, .5 )
        --  > https://wiki.facepunch.com/gmod/DModelPanel:SetLookAng
        local yaw = 0
        function model:LayoutEntity(ent)
            local lookAng = ( self.vLookatPos - self.vCamPos ):Angle()
            lookAng:RotateAroundAxis( Vector( 0, 1, 0 ), yaw )

            self:SetLookAng( lookAng )
            
            ent:SetAngles( Angle( 0, RealTime() * 25,  0 ) )
            yaw = yaw + 1
        end
        function model:Think()
            scene.model_x, scene.model_y = model:GetPos()
            scene.model_w, scene.model_h = model:GetSize()

            if model.x >= w then 
                main:Remove()
                LocalPlayer():ScreenFade( SCREENFADE.IN, color_black, .75, 0 )
            end
        end

        scene.model_x, scene.model_y = model:GetPos()
        scene.model_w, scene.model_h = model:GetSize()
    end )
end
concommand.Add( "au_eject_scene", AmongUs.OpenEjectScene )