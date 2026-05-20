-- mTickets
-- cl_init.lua


hook.Add("PlayerButtonDown", "mTickets.Keybind", function(ply, btn)
    if btn == mTickets.Config.OpenKey then
        if mTickets.OpenReportMenu then
            mTickets.OpenReportMenu()
        end
    end
end)

net.Receive("mTickets_OpenMenu" , function()
    if mTickets.OpenReportMenu then
        mTickets.OpenReportMenu()
    end
end)