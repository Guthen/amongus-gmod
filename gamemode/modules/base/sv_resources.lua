function AmongUs.AddResources( path )
    for i, v in ipairs( file.Find( path .. "/*", "GAME" ) ) do
        resource.AddSingleFile( path .. "/" .. v )
    end
end

AmongUs.AddResources( "resource/fonts" )
AmongUs.AddResources( "materials/amongus" )
AmongUs.AddResources( "sound/amongus" )