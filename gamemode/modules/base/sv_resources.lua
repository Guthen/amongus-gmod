function AmongUs.AddResources( path, matches )
    matches = matches or {}

    local files, folders = file.Find( path .. "/*", "GAME" )

    for i, v in ipairs( files ) do
        local valid = true

        for i, match in ipairs( matches ) do
            if not v:find( match ) then 
                valid = false
                --AmongUs.Print( "Ignore resource %q", v, match )
                break 
            end
        end

        if not valid then continue end
        resource.AddSingleFile( path .. "/" .. v )
        AmongUs.Print( "Add resource %q", v )
    end

    for i, v in ipairs( folders ) do
        AmongUs.AddResources( path .. "/" .. v, matches )
    end
end

--  > Player Models
resource.AddWorkshop( "2227901495" )

--  > Gamemodes Ressources
AmongUs.AddResources( "maps", { "au_.+%.bsp$" } )
AmongUs.AddResources( "resource/fonts", { "au_.+%.ttf" } )
AmongUs.AddResources( "materials/amongus", { ".png" } ) 
AmongUs.AddResources( "sound/amongus" )