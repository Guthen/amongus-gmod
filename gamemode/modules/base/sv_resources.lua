function AmongUs.AddResources( path )
    local files, folders = file.Find( path .. "/*", "GAME" )

    for i, v in ipairs( files ) do
        resource.AddSingleFile( path .. "/" .. v )
    end

    for i, v in ipairs( folders ) do
        AmongUs.AddResources( path .. "/" .. v )
    end
end

AmongUs.AddResources( "resource/fonts" )
AmongUs.AddResources( "materials/amongus" ) 
AmongUs.AddResources( "sound/amongus" )