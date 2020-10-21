AmongUs.PlayersTasks = AmongUs.PlayersTasks or {}

util.AddNetworkString( "AmongUs:Task" )
function AmongUs.GivePlayerTasks( ply )
    --  > Generate Tasks
    local tasks = {}
    for i = 0, AmongUs.Settings.CommonTasks - 1 do
        local id = table.Random( AmongUs.Tasks ).id
        --local id = AmongUs.Tasks["default"].id
        tasks[id] = { 
            id = id,
            completed = false,
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
    
    task.completed = true

    --  > Network Completion
    net.Start( "AmongUs:Task" )
        net.WriteUInt( 3, 3 )
        net.WriteString( id )
    net.Send( ply )

    --  > Network Progress
    local count = 0
    for ply, tasks in pairs( AmongUs.PlayersTasks ) do
        for id, task in pairs( tasks ) do
            if task.completed then
                count = count + 1
            end
        end
    end

    net.Start( "AmongUs:Task" )
        net.WriteUInt( 4, 3 )
        net.WriteUInt( count, 10 )
    net.Broadcast()
end