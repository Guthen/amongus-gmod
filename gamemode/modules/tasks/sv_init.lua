AmongUs.PlayersTasks = AmongUs.PlayersTasks or {}

util.AddNetworkString( "AmongUs:Task" )
function AmongUs.GivePlayerTasks( ply )
    --  > Generate Tasks
    local tasks = {}
    for i = 0, AmongUs.Settings.CommonTasks - 1 do
        local task = table.Random( AmongUs.Tasks )
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

function AmongUs.CompletePlayerTask( ply, id )
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
    net.Send( ply )

    --  > Network Progress
    if not task.completed then return false end
    local count, max = 0, 0
    for ply, tasks in pairs( AmongUs.PlayersTasks ) do
        if not AmongUs.GetRoleOf( ply ).can_do_task then continue end
        for id, task in pairs( tasks ) do
            if task.completed then
                count = count + 1
            end
            max = max + 1
        end
    end

    net.Start( "AmongUs:Task" )
        net.WriteUInt( 4, 3 )
        net.WriteFloat( count / max )
    net.Broadcast()

    return true
end