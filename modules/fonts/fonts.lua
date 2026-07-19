-- UnicodeFont optional dependency module for DragonflightUI-Reforged
-- Originally contributed by thezephyrsong for DragonflightUI-Capybara
-- (https://github.com/thezephyrsong/DragonflightUI-Capybara)
--
-- Applies the WarSansTT-Bliz-500 Unicode font from the UnicodeFont addon to
-- nameplates, unit frame names/levels, chat, and tooltips when UnicodeFont is
-- installed and each option is enabled. Safe to load without UnicodeFont present.

DFRL:NewDefaults("Fonts", {
    enabled          = {true},
    unicodePlates    = {true,  "checkbox", nil, nil, "unicode font", 1,
                        "Use UnicodeFont for nameplates (requires UnicodeFont addon)", nil, nil},
    unicodeUnitFrames = {true, "checkbox", nil, nil, "unicode font", 2,
                        "Use UnicodeFont for unit frame names and levels (requires UnicodeFont addon)", nil, nil},
    unicodeChat      = {true,  "checkbox", nil, nil, "unicode font", 3,
                        "Use UnicodeFont for chat frames (requires UnicodeFont addon)", nil, nil},
    unicodeTooltip   = {true,  "checkbox", nil, nil, "unicode font", 4,
                        "Use UnicodeFont for tooltips (requires UnicodeFont addon)", nil, nil},
})

DFRL:NewMod("Fonts", 2, function()

    -- ---------------------------------------------------------------
    -- Helpers
    -- ---------------------------------------------------------------

    local function GetUnicodeFontPath()
        if UNICODEFONT then
            return UNICODEFONT
        end
        if IsAddOnLoaded("UnicodeFont") then
            return "Interface\\AddOns\\UnicodeFont\\WarSansTT-Bliz-500.ttf"
        end
        return nil
    end

    local function SafeSetFont(obj, path, size, outline)
        if type(obj) == "table"
            and obj.SetFont
            and obj.IsObjectType
            and not obj:IsObjectType("SimpleHTML")
        then
            obj:SetFont(path, size, outline or "")
        end
    end

    -- ---------------------------------------------------------------
    -- Nameplate font
    -- The global NAMEPLATE_FONT is read by the client each time a new
    -- nameplate widget is created. We also need to force-recycle any
    -- existing plates by hiding/showing them.
    -- ---------------------------------------------------------------
    local function ApplyUnicodePlates(enable)
        local path = enable and GetUnicodeFontPath()
        if path then
            NAMEPLATE_FONT = path
        else
            NAMEPLATE_FONT = "Fonts\\FRIZQT__.TTF"
        end
        -- Recycle existing plates so they pick up the new global immediately.
        HideNameplates()
        ShowNameplates()
    end

    -- ---------------------------------------------------------------
    -- Unit frame name / level text
    --
    -- DFRL builds custom FontStrings in player.lua, target.lua, and
    -- mini.lua but stores them on the frame objects. We reach them
    -- directly by the same global handles Blizzard exposes.
    -- ---------------------------------------------------------------
    local function ApplyUnicodeUnitFrames(enable)
        local path  = enable and GetUnicodeFontPath()

        local function ApplyUnicode(obj, defaultPath, size, outline)
            if not obj then return end
            SafeSetFont(obj, path or defaultPath, size, outline or "")
        end

        local function CurrentFont(obj)
            if obj and obj.GetFont then
                local f, s = obj:GetFont()
                return f, s
            end
            return "Fonts\\FRIZQT__.TTF", 9
        end

        -- Player frame
        if PlayerFrame and PlayerFrame.name then
            local _, s = CurrentFont(PlayerFrame.name)
            ApplyUnicode(PlayerFrame.name, "Fonts\\FRIZQT__.TTF", s or 9, "")
        end
        if PlayerLevelText then
            local _, s = CurrentFont(PlayerLevelText)
            ApplyUnicode(PlayerLevelText, "Fonts\\FRIZQT__.TTF", s or 9, "")
        end

        -- Target frame
        if TargetFrame and TargetFrame.name then
            local _, s = CurrentFont(TargetFrame.name)
            ApplyUnicode(TargetFrame.name, "Fonts\\FRIZQT__.TTF", s or 9, "")
        end
        if TargetLevelText then
            local _, s = CurrentFont(TargetLevelText)
            ApplyUnicode(TargetLevelText, "Fonts\\FRIZQT__.TTF", s or 9, "")
        end
        if TargetDeadText then
            ApplyUnicode(TargetDeadText, "Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        end

        -- Target-of-target frame
        if TargetofTargetFrame and TargetofTargetFrame.name then
            local _, s = CurrentFont(TargetofTargetFrame.name)
            ApplyUnicode(TargetofTargetFrame.name, "Fonts\\FRIZQT__.TTF", s or 9, "")
        end

        -- Pet frame
        if PetFrame and PetFrame.name then
            local _, s = CurrentFont(PetFrame.name)
            ApplyUnicode(PetFrame.name, "Fonts\\FRIZQT__.TTF", s or 9, "")
        end

        -- Party frames
        for i = 1, 4 do
            local f = _G["PartyMemberFrame" .. i]
            if f and f.name then
                local _, s = CurrentFont(f.name)
                ApplyUnicode(f.name, "Fonts\\FRIZQT__.TTF", s or 9, "")
            end
        end
    end

    -- ---------------------------------------------------------------
    -- Chat font
    -- ---------------------------------------------------------------
    local function ApplyUnicodeChat(enable)
        local path     = enable and GetUnicodeFontPath()
        local fallback = "Fonts\\ARIALN.TTF"

        for i = 1, NUM_CHAT_WINDOWS do
            local frame = _G["ChatFrame" .. i]
            if frame and frame.SetFont then
                local currentSize = 14
                if frame.GetFont then
                    local _, size = frame:GetFont()
                    currentSize = size or 14
                end
                frame:SetFont(path or fallback, currentSize)
            end
        end

        if ChatFontNormal then
            local currentSize = 14
            if ChatFontNormal.GetFont then
                local _, size = ChatFontNormal:GetFont()
                currentSize = size or 14
            end
            SafeSetFont(ChatFontNormal, path or fallback, currentSize)
        end
    end

    -- ---------------------------------------------------------------
    -- Tooltip font
    -- ---------------------------------------------------------------
    local function ApplyUnicodeTooltip(enable)
        local path     = enable and GetUnicodeFontPath()
        local fallback = "Fonts\\FRIZQT__.TTF"

        local tooltipFonts = {
            GameTooltipText,
            GameTooltipHeaderText,
            GameTooltipTextSmall,
        }
        for i = 1, 30 do
            local l = _G["GameTooltipTextLeft"  .. i]
            local r = _G["GameTooltipTextRight" .. i]
            if l then table.insert(tooltipFonts, l) end
            if r then table.insert(tooltipFonts, r) end
        end

        for _, obj in ipairs(tooltipFonts) do
            if obj then
                local currentSize = 14
                if obj.GetFont then
                    local _, size = obj:GetFont()
                    currentSize = size or 14
                end
                SafeSetFont(obj, path or fallback, currentSize)
            end
        end
    end

    -- ---------------------------------------------------------------
    -- Callbacks
    -- ---------------------------------------------------------------
    local callbacks = {}

    -- Track last applied value so TriggerAllCallbacks (e.g. on profile
    -- switch) can skip when the setting hasn't actually changed, preserving
    -- any manual tweaks the user made (e.g. chat font size).
    local lastUnicodeChat    = nil

    callbacks.unicodePlates = function(value)
        if not DFRL.addon5 then return end
        ApplyUnicodePlates(value)
    end

    callbacks.unicodeUnitFrames = function(value)
        if not DFRL.addon5 then return end
        ApplyUnicodeUnitFrames(value)
    end

    callbacks.unicodeChat = function(value)
        if not DFRL.addon5 then return end
        if value == lastUnicodeChat then return end
        lastUnicodeChat = value
        ApplyUnicodeChat(value)
    end

    callbacks.unicodeTooltip = function(value)
        if not DFRL.addon5 then return end
        ApplyUnicodeTooltip(value)
    end

    -- Re-apply unit frame and tooltip fonts after target changes, because
    -- DFRL's own callbacks rewrite fonts when the target frame updates.
    local rehookFrame = CreateFrame("Frame")
    rehookFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
    rehookFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    rehookFrame:SetScript("OnEvent", function()
        if not DFRL.addon5 then return end
        if DFRL:GetTempDB("Fonts", "unicodeUnitFrames") then
            ApplyUnicodeUnitFrames(true)
        end
    end)

    -- Re-apply tooltip font on show (Blizzard code can reset it).
    if GameTooltip then
        local prevOnShow = GameTooltip:GetScript("OnShow")
        GameTooltip:SetScript("OnShow", function()
            if prevOnShow then prevOnShow() end
            if DFRL.addon5 and DFRL:GetTempDB("Fonts", "unicodeTooltip") then
                ApplyUnicodeTooltip(true)
            end
        end)
    end

    DFRL:NewCallbacks("Fonts", callbacks)
end)
