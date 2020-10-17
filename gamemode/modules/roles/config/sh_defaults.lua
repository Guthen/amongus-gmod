AmongUs.Roles = {}

--  > Crewmate
AmongUs.AddRole( "Crewmate", {
    color = Color( 141, 255, 253 ),
    has_won = function( self )
        local plys = AmongUs.GetAlivePlayers()

        for i, v in ipairs( plys ) do
            if not ( AmongUs.GetRoleOf( v ) == self ) then 
                return false 
            end
        end

        return true
    end,
    get_eject_sentence = function( self, ply )
        return ( "%s was not An Impostor" ):format( ply:GetName(), self.name )
    end,
    --  > Client:
    hud_paint = function( self, ply )
        --  > Use
        local x, y = ScrW() - AmongUs.RealIconSize, ScrH() - AmongUs.RealIconSize
        AmongUs.DrawIcon( AmongUs.Icons.Use, x, y, false )
    end,
    get_name_color = function( self, ply )
        return color_white
    end,
} )

--  > Impostor
AmongUs.AddRole( "Impostor", {
    color = Color( 238, 72, 79 ), --  > Name/Halos color
    weapons = { --  > Spawned weapons
        "au_kill",
    },
    max = function( self ) return math.ceil( player.GetCount() / 6 ) end, --  > Max players in this role
    immortal = true, --  > Immunise to 'au_kill' SWEP?
    has_won = function( self ) --  > Called everytime a player has gone
        local n = team.NumPlayers( self.id )
        return #AmongUs.GetAlivePlayers() - n <= n
    end,
    get_eject_sentence = function( self, ply )
        return ( "%s was An Impostor" ):format( ply:GetName() )
    end,
    --  > Client:
    hud_paint = function( self, ply )
        --  > Can Kill
        local can_kill, kill_weapon, cooldown = false, ply:GetWeapon( "au_kill" ), -1
        if IsValid( kill_weapon ) then
            can_kill, cooldown = kill_weapon:CanKill()

            local target = AmongUs.GetFacingTarget( ply )
            if can_kill and IsValid( target ) then
                local role = AmongUs.GetRoleOf( target )
                if not role or not role.immortal then 
                    can_kill = true
                else
                    can_kill = false
                end
            else
                can_kill = false
            end
        end

        --  > Kill
        local x, y = ScrW() - AmongUs.RealIconSize * 2, ScrH() - AmongUs.RealIconSize
        AmongUs.DrawIcon( AmongUs.Icons.Kill, x, y, can_kill )

        --  > Cooldown animation
        if not can_kill and cooldown >= 0 then
            AmongUs.DrawStencil( function()
                draw.RoundedBox( 0, x, y + ( 1 - cooldown / kill_weapon:GetNWInt( "AmongUs:MaxCooldown", 0 ) ) * AmongUs.IconSize, AmongUs.IconSize, AmongUs.IconSize, color_white )
            end, function()
                AmongUs.DrawIcon( AmongUs.Icons.Kill, x, y, false )
            end )

            AmongUs.DrawText( math.ceil( cooldown ), x + AmongUs.IconSize / 2, y + AmongUs.IconSize / 2, nil, "AmongUs:Big" )
        end

        --  > Sabotage
        AmongUs.DrawIcon( AmongUs.Icons.Sabotage, x + AmongUs.RealIconSize, y, true )
    end,
    get_name_color = function( self, ply )
        --  > See as impostor if looker is also impostor 
        return AmongUs.IsRole( ply, self.name ) and self.color or color_white
    end,
} )