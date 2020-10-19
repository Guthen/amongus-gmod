ENT.Base = "base_entity"
ENT.Type = "anim"

ENT.AmongUsUsable = true
ENT.HaloColor = Color( 213, 33, 11 )

ENT.Author = "Nogitsu"
ENT.Spawnable = false

function ENT:SetupDataTables()
    self:NetworkVar( "String", 0, "VentGroup" )
end