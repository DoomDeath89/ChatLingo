local addonName, addon = ...

local queue = ChatLingoDB

function addon.Enqueue(text, sourceLang, targetLang)
    if not text or text == "" then return end
    queue.pending = queue.pending or {}
    local id = (#queue.pending or 0) + 1
    queue.pending[id] = {
        id = id,
        text = text,
        source = sourceLang or "auto",
        target = targetLang or "es",
        timestamp = time(),
    }
    return id
end

function addon.GetResult(id)
    if not queue.results then return nil end
    for i, r in ipairs(queue.results) do
        if r.id == id then
            return r.translated, i
        end
    end
    return nil
end

function addon.RemoveResult(id)
    if not queue.results then return end
    local _, idx = addon.GetResult(id)
    if idx then tremove(queue.results, idx) end
end

function addon.ClearPending()
    queue.pending = {}
end

function addon.ClearResults()
    queue.results = {}
end

function addon.ClearCache()
    if ChatLingoDB.config and ChatLingoDB.config.cache then
        ChatLingoDB.config.cache = {}
    end
end
