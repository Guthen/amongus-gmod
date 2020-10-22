AmongUs.SquareTaskSize = math.floor( ScrH() * 0.85 )

AmongUs.TasksCompleted = 0
AmongUs.PlayerTasks = AmongUs.PlayerTasks or nil

AmongUs.TaskPanel = AmongUs.TaskPanel or nil
function AmongUs.OpenTaskPanel( type, on_submit )
    local task_base = AmongUs.Tasks[type]
    assert( task_base, ( "Task %q doesn't exists" ):format( type or "" ) )

    --  > Instantiate Task
    local task = setmetatable( {}, { __index = task_base } )

    --  > Create Main
    local time = .25
    local w, h = task.w or ScrW() * .75, task.h or ScrH() * .75
    local main, close = vgui.Create( "DFrame" )
    main:SetSize( w, h )
    main:SetPos( ScrW() / 2 - w / 2, ScrH() )
    main:MoveTo( main.x, ScrH() / 2 - h / 2, time, 0, 1 )
    main:SetDraggable( false )
    main:SetSizable( false )
    main:ShowCloseButton( false )
    main:SetTitle( "" )
    main:MakePopup()
    function main:Close()
        task:close()

        if task.custom_close then 
            task:custom_close( time, self, close ) 
        else
            self:MoveTo( self.x, ScrH(), time, 0, 1, function()
                self:Remove()
            end )
        end

        if not task.completed then
            net.Start( "AmongUs:Task" )
                net.WriteUInt( 2, 3 )
            net.SendToServer()
        end
    end
    function main:OnRemove()
        close:Remove()
    end

    --  > task:update
    function main:Think()
        task:update( FrameTime() )
    end

    --  > task:paint
    function main:Paint( w, h )
        if task.background_color then
            draw.RoundedBox( 0, 0, 0, w, h, task.background_color )
        end

        task:paint( w, h )
    end
    
    --  > task:click
    function main:OnMousePressed( button )
        local x, y = self:ScreenToLocal( input.GetCursorPos() )
        task:click( x, y, button, true )
    end
    function main:OnMouseReleased( button )
        local x, y = self:ScreenToLocal( input.GetCursorPos() )
        task:click( x, y, button, false )
    end
    
    --  > task:cursor_moved
    function main:OnCursorMoved( x, y )
        task:cursor_moved( x, y )
    end

    --  > Close Button
    local size = w * .098
    close = vgui.Create( "DImageButton" )
    close:SetSize( size, size )
    close:SetImage( "amongus/close.png" )
    function close:DoClick()
        main:Close()
    end
    function close:Think()
        self.x = main.x - size * 1.01
        self.y = main.y
    end
    
    --  > Launch Task
    task.w, task.h = w, h
    task:init()

    function task:submit()
        if isfunction( on_submit ) then
            on_submit( type )
        end

        timer.Simple( 1, function()
            if not IsValid( main ) then return end
            self.completed = true
            main:Close()
        end )
    end
end
concommand.Add( "au_task_panel", function( ply, cmd, args )
    AmongUs.OpenTaskPanel( args[1] or "default" )
end )

--  > HUD
local colors = {
    black = Color( 0, 0, 0 ),
    dark_gray = Color( 51, 51, 51 ),
    light_gray = Color( 170, 187, 187 ),
    dark_green = Color( 46, 64, 46 ),
    light_green = Color( 68, 216, 68 )
}
local outline = 4
local ratio = 0
hook.Add( "HUDPaint", "AmongUs:Tasks", function()
    --  > Tasks Counter
    if not AmongUs.PlayerTasks then return end

    --  > Compute max
    local max = 0
    for i, v in ipairs( AmongUs.GetAlivePlayers() ) do
        max = max + AmongUs.Settings.CommonTasks
    end

    --  > Draw
    local w, h = ScrW(), ScrH()
    local x, y = w * .01, w * .01
    local box_w, box_h = w * .35, draw.GetFontHeight( "AmongUs:Mini" ) * 1.5
    ratio = Lerp( FrameTime(), ratio, AmongUs.TasksCompleted / max )

    --  > Black
    draw.RoundedBox( 2, x, y, box_w, box_h + outline * 5, colors.black )

    --  > Gray
    x = x + outline
    y = y + outline
    draw.RoundedBox( 2, x, y, box_w - outline * 2, box_h + outline * 3, colors.light_gray )

    x = x + outline
    y = y + outline
    draw.RoundedBox( 1, x, y, box_w - outline * 4, box_h + outline, colors.dark_gray )

    --  > Green
    x = x + 1
    y = y + 2
    draw.RoundedBox( 1, x, y, box_w - outline * 4 - 2, box_h, colors.dark_green )
    draw.RoundedBox( 1, x, y, ( box_w - outline * 4 - 2 ) * ratio, box_h, colors.light_green )

    --  > Text
    AmongUs.DrawText( "TOTAL TASKS COMPLETED", x + outline, y + box_h / 2, nil, "AmongUs:Mini", TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER )
end )

--  > Task Completed message
local task_completed_show, got_middle = false, false
local font, delay = "AmongUs:Medium", 0
local h = ScrH()
local y = h
hook.Add( "PostRenderVGUI", "AmongUs:TaskCompleted", function()
    if not task_completed_show then return end

    local speed = FrameTime() * 12
    --  > Go up
    if got_middle and delay >= 1.5 then
        y = Lerp( speed, y, -draw.GetFontHeight( font ) )

        --  > Reset
        if y <= 0 then
            y, delay, got_middle, task_completed_show = h, 0, false, false
        end
    --  > Go to center
    else
        delay = delay + FrameTime()
        y = Lerp( speed, y, h / 2 )

        got_middle = y + 1 >= h / 2
    end

    AmongUs.DrawText( "Task Completed!", ScrW() / 2, y, nil, font )
end )

--  > Network
net.Receive( "AmongUs:Task", function()
    local method = net.ReadUInt( 3 )
    --  > Open Task Panel
    if method == 1 then
        local ent = net.ReadEntity()
        if not IsValid( ent ) then return end

        AmongUs.OpenTaskPanel( ent:GetTaskType(), function( task )
            if not IsValid( ent ) then return end

            net.Start( "AmongUs:Task" )
                net.WriteUInt( 1, 3 )
                net.WriteEntity( ent )
                net.WriteString( task )
            net.SendToServer()
        end )
    --  > Get Player Tasks
    elseif method == 2 then
        AmongUs.PlayerTasks = net.ReadTable()
        PrintTable( AmongUs.PlayerTasks )
    --  > Complete Task
    elseif method == 3 then
        local id = net.ReadString()
        AmongUs.PlayerTasks[id].completed = true

        --  > Effect
        task_completed_show = true
        surface.PlaySound( "amongus/task_complete.wav" )
    --  > Progress In Global Tasks
    elseif method == 4 then
        AmongUs.TasksCompleted = net.ReadUInt( 10 )
    end
end )