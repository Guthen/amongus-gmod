--  > Hooks
local color_black = Color( 0, 0, 0 )
function GM:PostPlayerDraw( ply )
    local pos = ply:GetPos() + Vector( 0, 0, 65 )
    local ang = Angle( 0, ( ply:GetPos() - LocalPlayer():GetPos() ):Angle().y - 90, 90 )
    local scale = .15

    local role = AmongUs.GetRoleOf( ply )
    local color = role and role:get_name_color( LocalPlayer() ) or color_white
    cam.Start3D2D( pos, ang, scale )
        AmongUs.DrawText( ply:GetName(), 0, 0, color )
    cam.End3D2D()
end

--  > Icons HUD
AmongUs.Icons = {
    Kill = Material( "amongus/kill.png" ),
    Sabotage = Material( "amongus/sabotage.png" ),
    Use = Material( "amongus/use.png" ),
    Report = Material( "amongus/report.png" ),
}

AmongUs.IconSize, AmongUs.IconSpace = ScreenScale( 60 ), ScreenScale( 10 )
AmongUs.RealIconSize = AmongUs.IconSize + AmongUs.IconSpace

function GM:HUDPaint()
    local ply = LocalPlayer()
    local role = AmongUs.GetRoleOf( ply )
    if not role or not role.hud_paint then return end

    role:hud_paint( ply )

    --  > Report
    local ent = AmongUs.GetEntityAtTrace( ply, AmongUs.IsDeadBody )
    local can_report = IsValid( ent )
    if can_report then
        can_report = ent:GetPos():Distance( ply:GetPos() ) <= AmongUs.Settings.UseDistance
    end

    AmongUs.DrawIcon( AmongUs.Icons.Report, ScrW() - AmongUs.RealIconSize, ScrH() - AmongUs.RealIconSize * 2, can_report )
end

local hud_hide = {
    ["CHudHealth"] = true,
}
hook.Add( "HUDShouldDraw", "AmongUs:HUD", function( element )
    if hud_hide[element] then return false end
end )

function GM:CalcView( ply, pos, ang, fov, znear, zfar )
    return {
        origin = pos - Vector( 0, 0, 12 ),
        angles = ang,
        fov = fov,
        --drawviewer = true,
    }
end

--  > Colorize Ragdoll
net.Receive( "AmongUs:ColorizeRagdoll", function()
    local ragdoll, color = net.ReadEntity(), net.ReadVector()
    print( ragdoll )
    if not IsValid( ragdoll ) then return end
    
    function ragdoll:GetPlayerColor()
        return color
    end
    print( ragdoll, color )
end )