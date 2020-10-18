include( "shared.lua" )

local arrow = Material( "amongus/vent_arrow.png" )
function ENT:Draw()
    self:DrawModel()
end

hook.Add( "HUDPaint", "AmongUs:ShowLinkedVents", function()
    local ply = LocalPlayer()
    local role = AmongUs.GetRoleOf( ply )

    if not role or not role.can_vent then return end

    surface.SetDrawColor( color_white )
    surface.SetMaterial( arrow )
    
    for k, v in ipairs( ents.FindByClass( "au_vent" ) ) do
        local pos = v:GetPos():ToScreen()
        local size = 32

        --if not pos.visible then return end -- > Later, draw it on the sides

        surface.DrawTexturedRectRotated( pos.x, pos.y, size, size, 180 )
    end
end )