include( "shared.lua" )

AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

function ENT:Initialize()
    self:PhysicsInit( SOLID_VPHYSICS )

    local phys = self:GetPhysicsObject()
    if IsValid( phys ) then
        phys:EnableMotion( false )
    end

    self.PlayersBlocked = {} --  > Used for 'disable_entity_task' option on tasks
end

function ENT:KeyValue( key, value )
    if key == "task_type" then
        self:SetTaskType( AmongUs.Tasks[ value ] and value or "default" )
    elseif key == "model" then
        self:SetModel( value )
    elseif key == "place_name" then
        self:SetPlaceName( value )
    end
end

local current_tasks = {}
function ENT:PlayerPressed( ply )
    if self.PlayersBlocked[ply] then return end --  > entity blocked for this player
    if not AmongUs.PlayersTasks[ply][self:GetTaskType()] then return end --  > don't have this task
    if AmongUs.PlayersTasks[ply][self:GetTaskType()].completed then return end --  > already done this task
    if not AmongUs.GetRoleOf( ply ).can_do_task then return end

    if current_tasks[ply] and not current_tasks[ply].task == self:GetTaskType() then
        ply:Kick( "Our anti-cheat system detected that you were already in a task." )

        return
    end

    current_tasks[ply] = { ent = self, task = self:GetTaskType(), started_at = CurTime() }
    ply.AmongUs_Task = self

    net.Start( "AmongUs:Task" )
        net.WriteUInt( 1, 3 )
        net.WriteEntity( self )
    net.Send( ply )
end

function ENT:UpdateTransmitState()	
	return TRANSMIT_ALWAYS 
end

net.Receive( "AmongUs:Task", function( _, ply )
    local method = net.ReadUInt( 3 )
    --  > Task Done
    if method == 1 then
        local ent = net.ReadEntity()
        local task = net.ReadString()
        if not ent or not task then return end
        local current = current_tasks[ply]

        --  > The task isn't registered for this player
        if not current then
            ply:Kick( "Our anti-cheat system detected that you weren't in a task while trying to submit it." )

            return
        end

        --  > The registered entity isn't the same
        if current.ent ~= ent or ply.AmongUs_Task ~= ent then
            ply:Kick( "Our anti-cheat system detected that you tried to submit a task from an invalid entity." )

            return
        end

        --  > The registered task isn't the same
        if current.task ~= task then
            ply:Kick( "Our anti-cheat system detected that you tried to submit a task you weren't doing." )
            
            return
        end

        --  > The player was too fast to finish it
        if current.started_at + ( AmongUs.Tasks[current.task].min_time or 1 ) > CurTime() then
            ply:Kick( "Our anti-cheat system detected that you were too fast." )
            
            return
        end

        --  > Task is valid, done !
        if AmongUs.CompletePlayerTask( ply, current.task, ent ) then
            current_tasks[ply] = nil
        end

        --  > Block player if 'disable_entity_task' is active
        if AmongUs.Tasks[ent:GetTaskType()].disable_entity_task then
            ent.PlayersBlocked[ply] = true
        end
    --  > Cancel Task
    elseif method == 2 then
        current_tasks[ply] = nil
    end
end )

--  > Reset Current Tasks
hook.Add( "AmongUs:RoundStart", "AmongUs:ResetCurrentTasks", function()
    current_tasks = {}
end )