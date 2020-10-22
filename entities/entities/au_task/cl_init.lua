include( "shared.lua" )

function ENT:Draw()
    self:DrawModel()
end

function ENT:CanHalo()
    return AmongUs.PlayerTasks and tobool( AmongUs.PlayerTasks[self:GetTaskType()] ) and not AmongUs.PlayerTasks[self:GetTaskType()].completed
end