-- mTICKET SYSTEM :))
-- this is a project i've made by myself, trying to improve my lua skills and more!

mTickets = mTickets or {}
mTickets.Config = {

    -- TTL (yes i know this isnt an IP packet)
    AutoCloseTime = 1200,

    -- keybind for report
    OpenKey = KEY_F11,

    -- chat trigger for report
    ChatTrigger = "@",

    -- reason for report tab
    Reasons = {
        "RDM",
        "FailRP",
        "Harassment",
        "Other",
    },

    -- max characters allowed in the extra info field
    MaxInfoLength = 100,

    -- folder used for txt ticket storage (inside garrysmod/data/)
    DataPath = "mTickets/",

}