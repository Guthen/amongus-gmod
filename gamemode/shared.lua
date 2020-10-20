AmongUs = AmongUs or {}

function AmongUs.Print( text, ... )
    print( "Among Us - " .. ( #{ ... } > 0 and text:format( ... ) or text ) )
end

function AmongUs.RequireFolder( path, verbose )
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

    for i, v in ipairs( folders ) do n = n + AmongUs.RequireFolder( path .. "/" .. v ) end

    if verbose then AmongUs.Print( "Load %q: %d files", path, n ) end
    return n
end

GM.Name = "Among Us"
GM.Author = "Guthen"

AmongUs.Print( "Loading necessited files" )
AmongUs.RequireFolder( "modules", true )
AmongUs.RequireFolder( "playerclasses", true )