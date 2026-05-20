-- mTickets
-- sv_commands.lua

concommand.Add("!tickets", function(ply, cmd, args)
    if not ply:IsSuperAdmin() then
        ply:ChatPrint("You don't have permission to use this.")
        return
    end
end)

-- TODO: need to add vgui for ticket list