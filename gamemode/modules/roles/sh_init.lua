AmongUs.Roles = AmongUs.Roles or {}

function AmongUs.AddRole( name, tbl )
    tbl.name = name
    tbl.id = #AmongUs.Roles + 1
    AmongUs.Roles[tbl.id] = tbl

    team.SetUp( tbl.id, name, tbl.color, tbl.id == 0 )
    print( ( "AmongUs: new role %q" ):format( name ) )
end

function AmongUs.SetRole( ply, role )
    role = isnumber( role ) and AmongUs.Roles[role] or role
    assert( role, "Role argument is nil" )

    ply:SetTeam( role.id )
    ply:Spawn()
    print( ply:GetName(), role.name )
end

function AmongUs.GetRoleOf( ply )
    return AmongUs.Roles[ply:Team()]
end

function AmongUs.IsRole( ply, role_name )
    local role = AmongUs.GetRoleOf( ply )
    return role and role.name == role_name
end