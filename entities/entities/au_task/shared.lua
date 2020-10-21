ENT.Base = "base_entity"
ENT.Type = "anim"

ENT.AmongUsUsable = true
ENT.AmongUsHaloColor = Color( 232, 241, 70 )

ENT.Author = "Nogitsu"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar( "String", 0, "TaskType" )

    if SERVER then
        self:SetTaskType( "default" )
    end
end