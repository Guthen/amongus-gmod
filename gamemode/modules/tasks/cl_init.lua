AmongUs.SquareTaskSize = math.floor( ScrH() * 0.85 )

AmongUs.TasksRatio = AmongUs.TasksRatio or 0
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
    --main:MakePopup()
    if task.no_clipping then main:NoClipping( true ) end
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
        gui.EnableScreenClicker( false )
        close:Remove()
    end

    --  > task:update
    function main:Think()
        --if self.mouse_capture then self:MouseCapture( true ) end
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
        --if x < 0 or x > self:GetWide() or y < 0 or y > self:GetTall() then self.mouse_capture = false end
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
    gui.EnableScreenClicker( true )
    
    --  > Launch Task
    task.w, task.h = w, h
    task:init()

    function task:submit( force )
        if isfunction( on_submit ) then
            on_submit( type )
        end

        --  > Close
        if force or not AmongUs.PlayerTasks[type].max_stages or AmongUs.PlayerTasks[type].stages + 1 >= AmongUs.PlayerTasks[type].max_stages then
            timer.Simple( 1, function()
                if not IsValid( main ) then return end
                self.completed = true
                main:Close()
            end )
        end
    end
end
concommand.Add( "au_task_panel", function( ply, cmd, args )
    AmongUs.OpenTaskPanel( args[1] or "default" )
end )

--  > Find Task Entities
local task_places = {}
local function find_task_places()
    task_places = {}

    --timer.Simple( .1, function()
        for i, v in ipairs( ents.FindByClass( "au_task" ) ) do
            task_places[v:GetTaskType()] = v:GetPlaceName()
        end
    --end )
end
hook.Add( "AmongUs:RoundStart", "AmongUs:FindTaskPlaces", find_task_places )

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

    --  > Draw
    local w, h = ScrW(), ScrH()
    local space = w * .01
    local x, y = space, space
    local box_w, box_h = w * .35, draw.GetFontHeight( "AmongUs:Mini" ) * 1.5
    ratio = Lerp( FrameTime() * 5, ratio, AmongUs.TasksRatio )

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

    ---  > Task List
    local font = "AmongUs:Little"
    local height = draw.GetFontHeight( font )
    local tasks = AmongUs.PlayerTasks

    --  > Compute Max Wide
    local wide = 0
    surface.SetFont( font )
    for k, v in pairs( AmongUs.PlayerTasks ) do
        v.text = ( "%s: %s" ):format( task_places[k] or "N/A", AmongUs.Tasks[k].name .. ( v.stages and ( " (%d/%d)" ):format( v.stages, v.max_stages ) or "" ) )
        wide = math.max( surface.GetTextSize( v.text ), wide )
    end
    wide = wide + space * 2

    --  > Background
    local background_color = ColorAlpha( colors.light_gray, 100 )
    draw.RoundedBox( 0, space, y + box_h + space, wide, space * 2 + table.Count( tasks ) * height, background_color )

    --  > "Tasks"
    local text = "Tasks"
    local text_w, text_h = surface.GetTextSize( text )
    draw.RoundedBox( 0, space + wide, y + box_h + space, text_h, text_w * 1.5, background_color )

    --  > https://wiki.facepunch.com/gmod/cam.PushModelMatrix
    local ang = -90
    local rad = -math.rad( ang )
	local text_x = -( math.cos( rad ) * text_w / 2 + math.sin( rad ) * text_h / 2 )
	local text_y = ( math.sin( rad ) * text_w / 2 + math.cos( rad ) * text_h / 2 )

	local m = Matrix()
	m:SetAngles( Angle( 0, ang, 0 ) )
	m:SetTranslation( Vector( space + wide + text_h * .45 + text_x, y + box_h + space + text_w * .75 + text_y, 0 ) )
	cam.PushModelMatrix( m )
        AmongUs.DrawText( text, 0, 0, nil, font, TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT )
	cam.PopModelMatrix()

    --  > Tasks
    local i = 0
    for k, v in pairs( AmongUs.PlayerTasks ) do
        AmongUs.DrawText( v.text, space * 2, y + box_h + space * 2 + i * height, v.completed and Color( 0, 221, 0 ) or v.in_progress and Color( 245, 246, 18 ) or color_white, font, TEXT_ALIGN_LEFT, TEXT_ALIGN_LEFT )
        i = i + 1
    end
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
local can_play_progress_sound = true
net.Receive( "AmongUs:Task", function()
    local method = net.ReadUInt( 3 )
    --  > Open Task Panel
    if method == 1 then
        local ent = net.ReadEntity()
        if not IsValid( ent ) then return end

        AmongUs.PlayerTasks[ent:GetTaskType()].in_progress = true
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
        AmongUs.TasksRatio = 0
        PrintTable( AmongUs.PlayerTasks )
    --  > Complete Task
    elseif method == 3 then
        local id = net.ReadString()
        local task = AmongUs.PlayerTasks[id]
        if not task then return end

        if task.stages then
            task.stages = task.stages + 1
            if task.stages >= task.max_stages then
                task.completed = true
            end
        else
            task.completed = true
        end

        --  > Effect
        if task.completed then
            task_completed_show = true
            surface.PlaySound( "amongus/task_complete.wav" )
        elseif can_play_progress_sound then
            surface.PlaySound( "amongus/task_progress.wav" )

            can_play_progress_sound = false
            timer.Simple( 1, function()
                can_play_progress_sound = true
            end )
        end
    --  > Progress In Global Tasks
    elseif method == 4 then
        AmongUs.TasksRatio = net.ReadFloat()
    end
end )