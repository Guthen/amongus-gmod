ENT.Base = "base_entity"
ENT.Type = "anim"

ENT.AmongUsUsable = true

ENT.Author = "Nogitsu"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar( "String", 0, "TaskType" )
end