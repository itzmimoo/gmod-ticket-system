-- mTickets
-- sv_autoclose.lua
-- automatically close ticket after some time.


timer.Create( "mTickets_autoclose", 60, 0, function()
    local now = os.time()
    local ttl = mTickets.Config.AutoCloseTime

    for id, ticket in pairs(mTickets.Tickets) do
        if ticket.status == "open" then
            if(now - ticket.openTime) >= ttl then
                mTickets.CloseTicket(id, nil)

                for _, ply in ipairs(player.GetAll()) do
                ply:ChatPrint("[mTickets] Ticket #" .. id .. "was automatically closed (no admins claimed it in time).")
                end

                Log("Ticket #" .. id .. " finished TTL.")
            end
        end
    end
end )