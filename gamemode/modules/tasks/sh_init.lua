AmongUs.Tasks = {}

--  > Enums
AU_TASK_COMMON = 0
AU_TASK_SHORT = 1
AU_TASK_LONG = 2

--  > Loader
local path = ( "%s/gamemode/modules/tasks/config" ):format( GM.FolderName )
AmongUs.Print( "Searching tasks..." )

for i, v in ipairs( file.Find( path .. "/*", "LUA" ) ) do
    if SERVER then AddCSLuaFile( path .. "/" .. v ) end

    local key = v:gsub( "%.%w+$", "" )
    AmongUs.Tasks[key] = include( path .. "/" .. v )
    AmongUs.Tasks[key].id = key
    
    AmongUs.Print( "\tLoaded task %q", key )
end

AmongUs.Print( "Registered %d tasks", table.Count( AmongUs.Tasks ) )