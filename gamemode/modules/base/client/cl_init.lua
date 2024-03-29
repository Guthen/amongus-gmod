hook.Add( "PreDrawHalos", "AmongUs:UsableEntities", function()
    local ply = LocalPlayer()
    local role = AmongUs.GetRoleOf( ply )

    if role and role.can_vent then
        local ent = AmongUs.GetEntityAtTrace( ply, AmongUs.IsVent, nil, true )
        if IsValid( ent ) then
            halo.Add( { ent }, role.color, 3, 3, 5, true )
            
            return
        end
    end

    local ent = AmongUs.GetEntityAtTrace( ply, AmongUs.IsUseable, nil, true )
    if not IsValid( ent ) or AmongUs.IsVent( ent ) then
        return
    end

    if ent.CanHalo and not ent:CanHalo() then return end
    halo.Add( { ent }, ent.AmongUsHaloColor or color_white, 3, 3, 5, true )
end )

--  > Hooks
local color_black = Color( 0, 0, 0 )
function GM:PostPlayerDraw( ply )
    local pos = ply:GetPos() + Vector( 0, 0, 68 )
    local ang = Angle( 0, ( ply:GetPos() - LocalPlayer():GetPos() ):Angle().y - 90, 90 )
    local scale = .08

    local role = AmongUs.GetRoleOf( ply )
    local color = role and role:get_name_color( AmongUs.GetRoleOf( LocalPlayer() ) ) or color_white
    cam.Start3D2D( pos, ang, scale )
        AmongUs.DrawText( ply:GetName(), 0, 0, color, "AmongUs:Big" )
    cam.End3D2D()
end

--  > Icons HUD
AmongUs.Icons = {
    Kill = Material( "amongus/kill.png" ),
    Sabotage = Material( "amongus/sabotage.png" ),
    Use = Material( "amongus/use.png" ),
    Report = Material( "amongus/report.png" ),
    Vent = Material( "amongus/vent.png" ),
}

AmongUs.IconSize, AmongUs.IconSpace = ScreenScale( 60 ), ScreenScale( 10 )
AmongUs.RealIconSize = AmongUs.IconSize + AmongUs.IconSpace

function GM:HUDPaint()
    local ply = LocalPlayer()

    --  > Create Tchat
    if not IsValid( AmongUs.TchatDialog ) then
        AmongUs.CreateTchatButton()
    elseif not IsValid( AmongUs.VotePanel ) then
        local padding = ScrH() * .022
        AmongUs.TchatDialog:SetParent()
        AmongUs.TchatDialog:SetPos( ScrW() - AmongUs.TchatDialog:GetWide() - padding, padding )
    end

    local role = AmongUs.GetRoleOf( ply )
    if not role or not role.hud_paint then return end

    --  > Custom HUD
    if not ply:Alive() then return end
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
    ["CHudChat"] = true,
}
hook.Add( "HUDShouldDraw", "AmongUs:HUD", function( element )
    if hud_hide[element] then return false end
end )

--  > Disable default Tchat
function GM:PlayerBindPress( ply, bind, pressed )
    if bind:StartWith( "messagemode" ) then
        if pressed and IsValid( AmongUs.TchatDialog ) and AmongUs.TchatDialog:GetAlpha() == 255 then
            AmongUs.TchatDialog:DoClick()
        end
        return true
    end
end

--  > Custom view
function GM:CalcView( ply, pos, ang, fov, znear, zfar )
    return {
        origin = pos - AmongUs.ViewOffset,
        angles = ang,
        fov = fov,
    }
end

--  > Colorize Ragdoll
net.Receive( "AmongUs:ColorizeRagdoll", function()
    local ragdoll, color = net.ReadEntity(), net.ReadVector()
    if not IsValid( ragdoll ) then return end
    
    function ragdoll:GetPlayerColor()
        return color
    end
end )

--  > Play Sound
net.Receive( "AmongUs:PlaySound", function()
    local path = net.ReadString()
    surface.PlaySound( path )
end )

--  > Network Hook
net.Receive( "AmongUs:NetworkHook", function()
    local name, args = net.ReadString(), net.ReadTable()
    hook.Run( name, args )
end )