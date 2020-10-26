AmongUs.TasksRatio = AmongUs.TasksRatio or 0
AmongUs.PlayersTasks = AmongUs.PlayersTasks or {}

util.AddNetworkString( "AmongUs:Task" )
function AmongUs.GivePlayerTasks( ply )
    local copy_tasks = table.GetKeys( AmongUs.Tasks )

    --  > Generate Tasks
    local tasks = {}
    for i = 0, AmongUs.Settings.CommonTasks - 1 do
        local task = AmongUs.Tasks[table.remove( copy_tasks, math.random( #copy_tasks ) )]
        --local id = AmongUs.Tasks["default"].id
        tasks[task.id] = { 
            id = task.id,
            completed = false,
            stages = task.max_stages and 0 or nil,
            max_stages = task.max_stages,
        }
    end

    AmongUs.PlayersTasks[ply] = tasks

    --  > Network
    net.Start( "AmongUs:Task" )
        net.WriteUInt( 2, 3 )
        net.WriteTable( tasks )
    net.Send( ply )
end
concommand.Add( "au_give_tasks", function( ply, cmd, args )
    AmongUs.GivePlayerTasks( args[1] and IsValid( Entity( args[1] ) ) and Entity( args[1] ) or ply )
end )

function AmongUs.CompletePlayerTask( ply, id, ent )
    local task = AmongUs.PlayersTasks[ply][id]
    assert( task, ( "Task %q doesn't exists on %s" ):format( id, ply ) )
    
    --  > Completion/Stage
    if task.stages then
        task.stages = task.stages + 1
        if task.stages >= task.max_stages then
            task.completed = true
        end
    else
        task.completed = true
    end

    --  > Network Completion
    net.Start( "AmongUs:Task" )
        net.WriteUInt( 3, 3 )
        net.WriteString( id )
        net.WriteEntity( ent )
    net.Send( ply )

    --  > Network Progress
    if not task.completed then return false end
    local count, max = 0, 0
    for ply, tasks in pairs( AmongUs.PlayersTasks ) do
        if ply:IsBot() then continue end
        if not AmongUs.GetRoleOf( ply ).can_do_task then continue end
        
        for id, task in pairs( tasks ) do
            if task.completed then
                count = count + 1
            end
            max = max + 1
        end
    end
    AmongUs.TasksRatio = count / max

    --  > Send Progression
    net.Start( "AmongUs:Task" )
        net.WriteUInt( 4, 3 )
        net.WriteFloat( count / max )
    net.Broadcast()

    --  > Check Wins
    if AmongUs.TasksRatio >= 1 then
        AmongUs.CheckRoleWinner()
    end

    return true
end