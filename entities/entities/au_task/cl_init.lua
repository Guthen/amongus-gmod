include( "shared.lua" )

function ENT:Draw()
    self:DrawModel()
end

AmongUs.BlockedEntities = {}
function ENT:CanHalo()
    return not AmongUs.BlockedEntities[self] and AmongUs.PlayerTasks and tobool( AmongUs.PlayerTasks[self:GetTaskType()] ) and not AmongUs.PlayerTasks[self:GetTaskType()].completed
end

hook.Add( "AmongUs:GameStart", "AmongUs:ResetBlockedEntities", function()
    AmongUs.BlockedEntities = {}
end )