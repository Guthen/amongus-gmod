AmongUs = AmongUs or {}

function AmongUs.requireFolder( path )
    local abs_path = ( "%s/gamemode/%s" ):format( GM.FolderName, path )
    local files, folders = file.Find( abs_path .. "/*", "LUA" )

    local n = 0
    for i, v in ipairs( files ) do
        local _path = abs_path .. "/" .. v
        
        if v:StartWith( "sh_" ) then
            if SERVER then 
                AddCSLuaFile( _path ) 
            end
            include( _path )
        elseif v:StartWith( "sv_" ) then
            include( _path )
        elseif v:StartWith( "cl_" ) then
            if SERVER then 
                AddCSLuaFile( _path ) 
            else 
                include( _path ) 
            end
        end

        n = n + 1
    end

    for i, v in ipairs( folders ) do n = n + AmongUs.requireFolder( path .. "/" .. v ) end

    return n
end

GM.Name = "Among Us"
GM.Author = "Guthen"

print( "Among Us: loading necessited files" )
print( ( "\tmodules: %d files" ):format( AmongUs.requireFolder( "modules" ) ) )
print( ( "\tplayerclasses: %d files" ):format( AmongUs.requireFolder( "playerclasses" ) ) )