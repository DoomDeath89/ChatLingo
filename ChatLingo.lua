local addonName, addon = ...

ChatLingoDB = ChatLingoDB or {}
ChatLingoDB.debug = ChatLingoDB.debug or {}
local dl = ChatLingoDB.debug
local dlog = function(msg) tinsert(dl, msg) if #dl > 50 then tremove(dl, 1) end end
dlog("INICIO")

local defaults = {
    targetLang = "es",
    enabled = true,
    pollInterval = 2,
    channels = {
        SAY = true, YELL = true, PARTY = true, RAID = true,
        GUILD = true, OFFICER = true, TRADE = true, WHISPER = true,
        INSTANCE_CHAT = true, CHANNEL = true,
    },
    cache = {},
}
dlog("defaults OK")

ChatLingoDB.config = ChatLingoDB.config or defaults
local config = ChatLingoDB.config
local queue = ChatLingoDB
queue.pending = queue.pending or {}
queue.results = queue.results or {}
dlog("config OK")

local chatEvents = {
    "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_PARTY",
    "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_TRADE",
    "CHAT_MSG_WHISPER", "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_CHANNEL",
}
dlog("events OK")

local eventToChannel = {}
for _, event in ipairs(chatEvents) do
    local channel = strmatch(event, "^CHAT_MSG_(.+)$")
    if channel then
        eventToChannel[event] = channel
    end
end
dlog("eventToChannel OK")
dlog("STEP before msgId")
local msgId = 0
dlog("STEP after msgId")

local function addToQueue(text, sourceLang, targetLang, event)
    if not text or strmatch(text, "^%s*$") then return end
    msgId = msgId + 1
    tinsert(queue.pending, {
        id = msgId,
        text = text,
        source = sourceLang or "auto",
        target = targetLang or config.targetLang,
        event = event or "CHAT_MSG_SAY",
    })
    return msgId
end
dlog("STEP addToQueue OK")

local function getResult(id)
    if not queue.results then return nil end
    for _, result in ipairs(queue.results) do
        if result.id == id then
            return result.translated
        end
    end
    return nil
end
dlog("STEP getResult OK")

local function cleanupResult(id)
    if not queue.results then return end
    for i, result in ipairs(queue.results) do
        if result.id == id then
            tremove(queue.results, i)
            return
        end
    end
end
dlog("STEP cleanupResult OK")

local pendingMsgIds = {}
for _, item in ipairs(queue.pending) do
    if item and item.id then
        pendingMsgIds[item.id] = { text = item.text, event = item.event or "CHAT_MSG_SAY" }
    end
end
dlog("STEP pendingMsgIds OK")

local function OnChatMsg(self, event, text, sender, ...)
    local channel = eventToChannel[event]
    if not channel or not config.enabled or not config.channels[channel] then return end
    if config.cache[text] then return end

    local id = addToQueue(text, "auto", config.targetLang, event)
    if id then
        pendingMsgIds[id] = { text = text, sender = sender, event = event }
        config.cache[text] = true
    end
end
dlog("STEP OnChatMsg OK")

local eventFrame = CreateFrame("Frame")
dlog("STEP CreateFrame OK")
dlog("STEP before RegisterEvent")
for _, event in ipairs(chatEvents) do
    local ok, err = pcall(eventFrame.RegisterEvent, eventFrame, event)
    if not ok then dlog("REGERR: " .. event .. " - " .. tostring(err)) end
end
dlog("STEP RegisterEvent OK")
eventFrame:SetScript("OnEvent", OnChatMsg)
dlog("STEP SetScript OK")
dlog("eventFrame OK")

local pollFrame = CreateFrame("Frame")
pollFrame:SetScript("OnUpdate", function(self, elapsed)
    self.timer = (self.timer or 0) + elapsed
    if self.timer < config.pollInterval then return end
    self.timer = 0

    for id, info in pairs(pendingMsgIds) do
        local translated = getResult(id)
        if translated and ChatFrame1 then
            local color = ChatTypeInfo[info.event]
            ChatFrame1:AddMessage("|cff00ccff[TR]|r " .. translated, color.r, color.g, color.b)
            pendingMsgIds[id] = nil
            cleanupResult(id)
        end
    end
end)
dlog("pollFrame OK")

SLASH_CHATLINGO1 = "/cl"
SLASH_CHATLINGO2 = "/chatlingo"
dlog("SLASH vars OK before SlashCmdList")

SlashCmdList["CHATLINGO"] = function()
    dlog("SLASH CALLED")
    if ChatLingoConfig and ChatLingoConfig.frame then
        dlog("frame exists, toggling")
        ChatLingoConfig.frame:SetShown(not ChatLingoConfig.frame:IsShown())
    else
        dlog("ChatLingoConfig.frame nil")
    end
end
dlog("FIN COMPLETO")
