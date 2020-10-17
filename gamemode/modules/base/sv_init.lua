util.AddNetworkString( "AmongUs:ColorizeRagdoll" )

function GM:PlayerSpawn( ply )
    player_manager.SetPlayerClass( ply, AmongUs.BasePlayerClass.Name )
    player_manager.RunClass( ply, "Loadout" )

    ply:SetCustomCollisionCheck( true )
    ---ply:SendLua( "player_manager.RunClass( LocalPlayer(), 'Loadout' )" )
end

function GM:PlayerDeathSound()
    return true
end

function GM:PlayerDeath( ply, inf, atk )
    local ragdoll = ply:GetRagdollEntity()

    --  > New ragdoll
    local new_ragdoll = ents.Create( "prop_ragdoll" )
    new_ragdoll:SetModel( ply:GetModel() )
    new_ragdoll:SetPos( ragdoll:GetPos() )
    new_ragdoll:SetAngles( ply:GetAngles() )
    new_ragdoll:Spawn()
    new_ragdoll:SetColor( ply:GetPlayerColor():ToColor() )
    new_ragdoll:SetCollisionGroup( COLLISION_GROUP_WORLD )
    --[[ print( new_ragdoll:GetPhysicsObject():SetMaterial( "player" ) )
 ]]
    -------------   > TODO: FIX RAGDOLLs COLOR
    --[[ net.Start( "AmongUs:ColorizeRagdoll" )
        net.WriteEntity( new_ragdoll )
        net.WriteVector( ply:GetPlayerColor() )
    net.Broadcast() ]]

    ragdoll:Remove()

    --  > Role Win
    AmongUs.CheckRoleWinner()
end

function GM:PlayerSilentDeath( ply )
    AmongUs.CheckRoleWinner()
end

function GM:PlayerDeathThink( ply )
    return true
end

function GM:KeyPress( ply, key )
    if key == IN_USE then
        local body = AmongUs.GetEntityAtTrace( ply, AmongUs.IsDeadBody )
        if not body or body:GetPos():Distance( ply:GetPos() ) > AmongUs.Settings.UseDistance then return end

        AmongUs.LaunchVoting( ply )
    end 
end