-- mTickets loader

AddCSLuaFile("config.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_ui.lua")

include("config.lua")

if SERVER then
    include("sv_core.lua")
    include("sv_autoclose.lua")
    include("sv_commands.lua")

end

if CLIENT then
    include("cl_init.lua")
    include("cl_ui.lua")
end