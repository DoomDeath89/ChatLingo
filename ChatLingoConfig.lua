ChatLingoConfig = {}
local config = ChatLingoDB.config

local langs = {
    { text = "Espanol", value = "es" },
    { text = "Ingles", value = "en" },
    { text = "Frances", value = "fr" },
    { text = "Aleman", value = "de" },
    { text = "Portugues", value = "pt" },
    { text = "Italiano", value = "it" },
    { text = "Ruso", value = "ru" },
    { text = "Chino simplificado", value = "zh-CN" },
    { text = "Japones", value = "ja" },
    { text = "Coreano", value = "ko" },
}

local function CreateConfigFrame()
    local frame = CreateFrame("Frame", "ChatLingoConfigFrame", UIParent)
    frame:SetWidth(340)
    frame:SetHeight(380)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:Hide()

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(0, 0, 0, 0.9)

    local borderTop = frame:CreateTexture(nil, "BORDER")
    borderTop:SetPoint("TOPLEFT", -1, 1)
    borderTop:SetPoint("TOPRIGHT", 1, 1)
    borderTop:SetHeight(2)
    borderTop:SetTexture(0.4, 0.6, 1, 1)

    local borderBottom = frame:CreateTexture(nil, "BORDER")
    borderBottom:SetPoint("BOTTOMLEFT", -1, -1)
    borderBottom:SetPoint("BOTTOMRIGHT", 1, -1)
    borderBottom:SetHeight(2)
    borderBottom:SetTexture(0.4, 0.6, 1, 1)

    local borderLeft = frame:CreateTexture(nil, "BORDER")
    borderLeft:SetPoint("TOPLEFT", -1, 1)
    borderLeft:SetPoint("BOTTOMLEFT", -1, -1)
    borderLeft:SetWidth(2)
    borderLeft:SetTexture(0.4, 0.6, 1, 1)

    local borderRight = frame:CreateTexture(nil, "BORDER")
    borderRight:SetPoint("TOPRIGHT", 1, 1)
    borderRight:SetPoint("BOTTOMRIGHT", 1, -1)
    borderRight:SetWidth(2)
    borderRight:SetTexture(0.4, 0.6, 1, 1)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -12)
    title:SetText("ChatLingo - Configuraci¢n")

    -- Language label
    local langLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    langLabel:SetPoint("TOPLEFT", 16, -40)
    langLabel:SetText("Idioma destino:")

    -- Language dropdown
    local dropFrame = CreateFrame("Frame", "ChatLingoLangDrop", frame, "UIDropDownMenuTemplate")
    dropFrame:SetPoint("TOPLEFT", 16, -55)
    UIDropDownMenu_SetWidth(dropFrame, 120)
    UIDropDownMenu_SetText(dropFrame, "Espa¤ol")

    local function DropdownInit()
        for _, lang in ipairs(langs) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = lang.text
            info.value = lang.value
            info.checked = (config.targetLang == lang.value)
            info.func = function()
                config.targetLang = lang.value
                UIDropDownMenu_SetText(dropFrame, lang.text)
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info)
        end
    end

    dropFrame:SetScript("OnMouseDown", function()
        UIDropDownMenu_Initialize(dropFrame, DropdownInit, "MENU")
        ToggleDropDownMenu(1, nil, dropFrame)
    end)

    -- Channels
    local chanLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    chanLabel:SetPoint("TOPLEFT", 16, -95)
    chanLabel:SetText("Canales a traducir:")

    local channelDefs = {
        {"SAY", 30, -115}, {"YELL", 130, -115},
        {"PARTY", 30, -135}, {"RAID", 130, -135},
        {"GUILD", 30, -155}, {"OFFICER", 130, -155},
        {"TRADE", 30, -175}, {"WHISPER", 130, -175},
        {"INSTANCE", 30, -195},
    }

    local checkButtons = {}
    for i, def in ipairs(channelDefs) do
        local name, cx, cy = def[1], def[2], def[3]
        local chName = (name == "INSTANCE") and "INSTANCE_CHAT" or name
        local cb = CreateFrame("CheckButton", "ChatLingoCheck" .. name, frame, "UICheckButtonTemplate")
        cb:SetPoint("TOPLEFT", cx, cy)
        local ct = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ct:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        ct:SetText(name)
        cb:SetChecked(config.channels[chName])
        cb:SetScript("OnClick", function(self)
            config.channels[chName] = self:GetChecked()
        end)
        checkButtons[chName] = cb
    end

    -- Poll slider
    local pollLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pollLabel:SetPoint("TOPLEFT", 16, -225)
    pollLabel:SetText("Intervalo de polling: " .. config.pollInterval .. "s")

    local slider = CreateFrame("Slider", nil, frame)
    slider:SetPoint("TOPLEFT", 16, -240)
    slider:SetWidth(200)
    slider:SetHeight(20)
    slider:SetMinMaxValues(1, 10)
    slider:SetValueStep(1)
    slider:SetValue(config.pollInterval)
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    thumb:SetWidth(16)
    thumb:SetHeight(16)
    slider:SetThumbTexture(thumb)

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        config.pollInterval = value
        pollLabel:SetText("Intervalo de polling: " .. value .. "s")
    end)

    -- Clear Cache
    local clearBtn = CreateFrame("Button", nil, frame)
    clearBtn:SetPoint("TOPLEFT", 16, -290)
    clearBtn:SetWidth(110)
    clearBtn:SetHeight(22)
    clearBtn:SetText("Limpiar cache")
    clearBtn:SetNormalFontObject("GameFontNormal")
    clearBtn:SetHighlightFontObject("GameFontHighlight")
    clearBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
    clearBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
    clearBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    clearBtn:SetScript("OnClick", function()
        config.cache = {}
        if ChatFrame1 then
            ChatFrame1:AddMessage("|cff00ccff[ChatLingo]|r Cache limpiado.", 0, 1, 0)
        end
    end)

    -- Reset
    local resetBtn = CreateFrame("Button", nil, frame)
    resetBtn:SetPoint("TOPLEFT", 140, -290)
    resetBtn:SetWidth(130)
    resetBtn:SetHeight(22)
    resetBtn:SetText("Restablecer valores")
    resetBtn:SetNormalFontObject("GameFontNormal")
    resetBtn:SetHighlightFontObject("GameFontHighlight")
    resetBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
    resetBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
    resetBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    resetBtn:SetScript("OnClick", function()
        ChatLingoDB.config = {
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
        config = ChatLingoDB.config
        UIDropDownMenu_SetText(dropFrame, "Espa¤ol")
        for chName, cb in pairs(checkButtons) do
            cb:SetChecked(config.channels[chName])
        end
        slider:SetValue(config.pollInterval)
        pollLabel:SetText("Intervalo de polling: " .. config.pollInterval .. "s")
        if ChatFrame1 then
            ChatFrame1:AddMessage("|cff00ccff[ChatLingo]|r Valores restablecidos.", 0, 1, 0)
        end
    end)

    -- Close
    local closeBtn = CreateFrame("Button", nil, frame)
    closeBtn:SetPoint("BOTTOM", 0, 12)
    closeBtn:SetWidth(60)
    closeBtn:SetHeight(22)
    closeBtn:SetText("Cerrar")
    closeBtn:SetNormalFontObject("GameFontNormal")
    closeBtn:SetHighlightFontObject("GameFontHighlight")
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
    closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    ChatLingoConfig.frame = frame
    ChatLingoConfig.checkButtons = checkButtons
end

local function OnInit()
    local ok, err = pcall(CreateConfigFrame)
    if ok then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[ChatLingo]|r Addon cargado. Usa /cl para configurar.", 0, 1, 0)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[ChatLingo]|r Error: " .. tostring(err), 1, 0, 0)
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, name)
    if name == "ChatLingo" then
        self:UnregisterEvent("ADDON_LOADED")
        OnInit()
    end
end)
