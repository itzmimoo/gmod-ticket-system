-- mTickets
-- sv_core.lua (NOT COMPLETE)

mTickets = mTickets or {}
mTickets.Tickets = {}
mTickets._nextID = 1

-- nw strings

util.AddNetworkString("mTickets_OpenMenu")
util.AddNetworkString("mTickets_SubmitTicket")
util.AddNetworkString("mTickets_Notify")
util.AddNetworkString("mTickets_AdminAction")

-- need to put claim, close, bring, goto nd ticket list

-- helpers

local function Log(msg)
    print("[mTickets] " .. tostring(msg))
end

local function IsAdmin(ply)
    return ply:IsSuperAdmin() -- need to add CAMI support
end

-- ensure data folder exists

local function EnsureDataFolder()
    if not file.IsDir(mTickets.Config.DataPath, "DATA") then
        file.CreateDir(mTickets.Config.DataPath)
    end
end

-- txt persistence

local function TicketPath(id)
    return mTickets.Config.DataPath .. "ticket_" .. id .. ".txt"
end

local function SaveTicket(ticket)
    EnsureDataFolder()

    local lines = {
        "id=" .. ticket.id,
        "steamid=" .. ticket.steamid,
        "reporter=" .. ticket.reporterName,
        "targetName=" .. ticket.targetName,
        "targetSID=" .. ticket.targetSteamID,
        "reason=" .. ticket.reason,
        "info=" .. ticket.info,
        "status=" .. ticket.status,
        "openTime=" .. ticket.openTime,
    }

    file.Write(TicketPath(ticket.id), table.concat(lines, "\n"))
end

local function DeleteTicket(id)
    local path = TicketPath(id)
    if file.Exists(path, "DATA") then
        file.Delete(path)
    end
end

local function ParseTicketFile(raw)
    local t = {}

    for _, line in ipairs(string.Explode("\n", raw)) do
        local k, v = line:match("^(.-)=(.+)$")
        if k and v then
            t[k] = v
        end
    end

    if not t.id then
        return nil
    end

    return {
        id = tonumber(t.id),
        steamid = t.steamid or "N/A",
        reporterName = t.reporter or "N/A",
        targetName = t.targetName or "N/A",
        targetSteamID = t.targetSID or "N/A",
        reason = t.reason or "N/A",
        info = t.info or "",
        status = t.status or "open",
        openTime = tonumber(t.openTime) or os.time(),
    }
end

-- load all tickets from disk on server start

local function LoadTickets()
    EnsureDataFolder()

    local files, _ = file.Find(mTickets.Config.DataPath .. "ticket_*.txt", "DATA")
    local highest = 0

    for _, fname in ipairs(files) do
        local raw = file.Read(mTickets.Config.DataPath .. fname, "DATA")

        if raw then
            local ticket = ParseTicketFile(raw)

            if ticket then
                mTickets.Tickets[ticket.id] = ticket

                if ticket.id > highest then
                    highest = ticket.id
                end

                Log("Loaded ticket #" .. ticket.id .. " from disk")
            end
        end
    end

    mTickets._nextID = highest + 1
end

LoadTickets()

-- Ticket API

function mTickets.OpenTicket(reporter, target, reason, info)
    local id = mTickets._nextID
    mTickets._nextID = id + 1

    local targetName = IsValid(target) and target:Nick() or "N/A"
    local targetSteamID = IsValid(target) and target:SteamID() or "N/A"

    local ticket = {
        id = id,
        steamid = reporter:SteamID(),
        reporterName = reporter:Nick(),
        targetName = targetName,
        targetSteamID = targetSteamID,
        reason = reason,
        info = info:sub(1, mTickets.Config.MaxInfoLength),
        status = "open",
        openTime = os.time(),
    }

    mTickets.Tickets[id] = ticket
    SaveTicket(ticket)

    Log("Ticket #" .. id .. " opened by " .. reporter:Nick())

    -- need to notify admins, schedule auto-close

    for _, o in ipairs(player.GetAll()) do
        if IsAdmin(p) then
            net.Start("mTickets_Notify")
            net.WriteInt(ticket.id, 32)
            net.WriteString(ticket.reporterName)
            net.WriteString(ticket.targetName)
            net.WriteString(ticket.reason)
            net.WriteString(ticket.info)
            net.Send(p)
        end
    end
end

function mTickets.CloseTicket(id, closer)
    local ticket = mTickets.Tickets[id]

    if not ticket then
        return false
    end

    ticket.status = "closed"

    DeleteTicket(id)

    mTickets.Tickets[id] = nil

    local closerName = IsValid(closer) and closer:Nick() or "auto"

    Log("Ticket #" .. id .. " closed by " .. closerName)

    return true
end

function mTickets.ClaimTicket(id, admin)
    local ticket = mTickets.Tickets[id]

    if not ticket then
        return false
    end

    ticket.status = "claimed"
    ticket.claimedBy = admin:SteamID()
    ticket.claimedName = admin:Nick()

    SaveTicket(ticket)

    Log("Ticket #" .. id .. " claimed by " .. admin:Nick())

    return true
end

-- net receivers

net.Receive("mTickets_SubmitTicket", function(len, ply)
    local targetName = net.ReadString()
    local reason = net.ReadString()
    local info = net.ReadString()

    -- get target name to a player object so it can grab their SteamID

    local target = nil

    if targetName ~= "N/A" then
        for _, p in ipairs(player.GetAll()) do
            if p:Nick() == targetName then
                target = p
                break
            end
        end
    end

    mTickets.OpenTicket(ply, target, reason, info)
end)

-- chat trigger

hook.Add("PlayerSay", "mTickets_ChatTrigger", function(ply, text)
    if text:sub(1, #mTickets.Config.ChatTrigger) == mTickets.Config.ChatTrigger then
        net.Start("mTickets_OpenMenu")
        net.Send(ply)

        return ""
    end
end)

net.Receive("mTickets_AdminAction", function(len, ply)
    if not IsAdmin(ply) then return end

    local action = net.ReadString()
    local id = net.ReadInt()
    local ticket = mTickets.Tickets[id]

    if not ticket then return end

    if action == "claim" then
        mTickets.ClaimTicket(id, ply)

    elseif action == "close" then
        if ticket.targetName ~= "N/A" then
            for _, p in ipairs(player.GetAll()) do
                if p:Nick() == ticket.targetName or p:SteamID() == ticket.steamid then
                    ply:ConCommand("ulx return " .. p:Nick())
                end
            end
        end
        mTickets.CloseTicket(id, ply)
    elseif action == "bring" then
        local reporter = player.GetBySteamID(ticket.steamid)
        if IsValid(reporter) then
            ply:ConCommand("ulx bring " .. reporter:Nick())
        end
        if ticket.targetName ~= "N/A" then
            for _, p in ipairs(player.GetAll) do
                if p:Nick() == ticket.targetName then
                    ply:ConCommand("ulx bring " .. p:Nick())
                    break
                end 
            end
        end
    elseif action == "goto" then
        local reporter = player.GetBySteamID(ticket.steamid)
        if IsValid(reporter) then
            ply:ConCommand("ulx goto " .. reporter:Nick())
        end
    end
end)
