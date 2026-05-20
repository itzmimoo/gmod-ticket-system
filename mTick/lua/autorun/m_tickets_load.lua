-- mTickets loader

AddCSLuaFile( "mTickets/config.lua" )
AddCSLuaFile( "mTickets/cl_init.lua" )
AddCSLuaFile( "mTickets/cl_ui.lua" )

include( "mTickets/config.lua" )

if SERVER then
    include( "mTickets/sv_core.lua" )
    include( "mTickets/sv_autoclose.lua" )
end

if CLIENT then
    include( "mTickets/cl_init.lua" )
    include( "mTickets/cl_ui.lua" )
end