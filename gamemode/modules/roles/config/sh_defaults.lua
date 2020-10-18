AmongUs.Roles = {}

--  > Crewmate
CREWMATE = AmongUs.AddRole( "Crewmate", {
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
        return ( "%s was not An Impostor." ):format( ply:GetName(), self.name )
    end,
    get_scene_players = function( self )
        return AmongUs.GetAlivePlayers()
    end,
    show_player_name_reveal = false, --  > Whenever we show players names on role reveal
    second_reveal_sentence = function( self )
        local impostor = AmongUs.Roles[IMPOSTOR]
        local count = #AmongUs.GetRolePlayers( impostor )
        return "There ", count > 1 and "are" or "is", impostor.color, ( " %d %s" ):format( count, impostor.name .. ( count > 1 and "s" or "" ) ), color_white, " among us."
    end,
    --  > Client:
    hud_paint = function( self, ply )
        --  > Use
        local x, y = ScrW() - AmongUs.RealIconSize, ScrH() - AmongUs.RealIconSize
        AmongUs.DrawIcon( AmongUs.Icons.Use, x, y, AmongUs.GetEntityAtTrace( ply, AmongUs.IsUseable, nil, true ) )
    end,
    get_name_color = function( self, ply )
        return color_white
    end,
} )

--  > Impostor
IMPOSTOR = AmongUs.AddRole( "Impostor", {
    color = Color( 238, 72, 79 ), --  > Name/Halos color
    weapons = { --  > Spawned weapons
        "au_kill",
    },
    max = function( self ) 
        return 2
    end, --  > Max players in this role
    immortal = true, --  > Immunise to 'au_kill' SWEP?
    has_won = function( self ) --  > Called everytime a player has gone
        local n = #AmongUs.GetRolePlayers( self )
        return #AmongUs.GetAlivePlayers() - n <= n
    end,
    get_eject_sentence = function( self, ply )
        return ( "%s was An Impostor." ):format( ply:GetName() )
    end,
    get_scene_players = function( self ) --  > Must return players list to show on role reveal scene
        return team.GetPlayers( self.id )
    end,
    show_player_name_reveal = true, --  > Whenever we show players names on role reveal
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