include( "shared.lua" )

local arrow = Material( "amongus/vent_arrow.png" )
function ENT:Draw()
    self:DrawModel()
end

hook.Add( "HUDPaint", "AmongUs:ShowLinkedVents", function()
    local ply = LocalPlayer()
    local role = AmongUs.GetRoleOf( ply )
    local current_vent = ply:GetNWEntity( "AmongUs:Vent" )
    local w, h = ScrW(), ScrH()
    
    if not IsValid( current_vent ) then return end
    if not role or not role.can_vent then return end

    surface.SetDrawColor( color_white )
    surface.SetMaterial( arrow )
    
    for k, v in ipairs( ents.FindByClass( "au_vent" ) ) do
        if current_vent == v then continue end
        if current_vent:GetVentGroup() ~= v:GetVentGroup() then continue end

        local pos = v:GetPos():ToScreen()
        local size = 32

        local ang = 180

        if pos.x < size / 2 then
            ang = 90
        elseif pos.x > w - size / 2 then
            ang = -90
        end

        if pos.y < size / 2 then
            if ang == 90 then
                ang = 45
            elseif ang == -90 then
                ang = -45
            else
                ang = 0
            end
        elseif pos.y > h - size / 2 then
            if ang == 90 then
                ang = 125
            elseif ang == -90 then
                ang = -125
            else
                ang = 180
            end
        end

        pos.x = math.Clamp( pos.x, size / 2, w - size / 2 )
        pos.y = math.Clamp( pos.y, size / 2, h - size / 2 )

        if pos.x > w / 2 - size and pos.x < w / 2 + size and pos.y > h / 2 - size and pos.y < h / 2 + size then
            size = size * 2
        end

        surface.DrawTexturedRectRotated( pos.x, pos.y, size, size, ang )
    end
end )