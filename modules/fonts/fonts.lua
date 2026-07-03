-- UnicodeFont optional dependency module for DragonflightUI-Capybara
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
    unicodeFontScale = {1.0,   "slider", {0.6, 1.4, 0.05}, nil, "unicode font", 5,
                        "Scale multiplier applied on top of each frame's default font size", nil, nil},
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
        local scale = DFRL:GetTempDB("Fonts", "unicodeFontScale") or 1.0
        local path  = enable and GetUnicodeFontPath()

        -- Helper: set font or revert to the frame's own stored font path.
        local function Apply(obj, defaultPath, size, outline)
            if not obj then return end
            if path then
                SafeSetFont(obj, path, size * scale, outline)
            else
                SafeSetFont(obj, defaultPath, size, outline)
            end
        end

        -- Grab the font DFRL's unit modules are currently using (stored in
        -- their config tables, which are module-local). We read from the
        -- actual FontString instead so we don't need to poke into their
        -- private upvalues.
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
            Apply(PlayerFrame.name, "Fonts\\FRIZQT__.TTF", s or 9, "")
        end
        if PlayerLevelText then
            local _, s = CurrentFont(PlayerLevelText)
            Apply(PlayerLevelText, "Fonts\\FRIZQT__.TTF", s or 9, "")
        end

        -- Target frame
        if TargetFrame and TargetFrame.name then
            local _, s = CurrentFont(TargetFrame.name)
            Apply(TargetFrame.name, "Fonts\\FRIZQT__.TTF", s or 9, "")
        end
        if TargetLevelText then
            local _, s = CurrentFont(TargetLevelText)
            Apply(TargetLevelText, "Fonts\\FRIZQT__.TTF", s or 9, "")
        end
        if TargetDeadText then
            Apply(TargetDeadText, "Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        end

        -- Target-of-target frame
        if TargetofTargetFrame and TargetofTargetFrame.name then
            local _, s = CurrentFont(TargetofTargetFrame.name)
            Apply(TargetofTargetFrame.name, "Fonts\\FRIZQT__.TTF", s or 9, "")
        end

        -- Pet frame
        if PetFrame and PetFrame.name then
            local _, s = CurrentFont(PetFrame.name)
            Apply(PetFrame.name, "Fonts\\FRIZQT__.TTF", s or 9, "")
        end

        -- Party frames
        for i = 1, 4 do
            local f = _G["PartyMemberFrame" .. i]
            if f and f.name then
                local _, s = CurrentFont(f.name)
                Apply(f.name, "Fonts\\FRIZQT__.TTF", s or 9, "")
            end
        end
    end

    -- ---------------------------------------------------------------
    -- Chat font
    -- ---------------------------------------------------------------
    local function ApplyUnicodeChat(enable)
        local scale = DFRL:GetTempDB("Fonts", "unicodeFontScale") or 1.0
        local path  = enable and GetUnicodeFontPath()
        local size  = 14 * scale

        for i = 1, NUM_CHAT_WINDOWS do
            local frame = _G["ChatFrame" .. i]
            if frame and frame.SetFont then
                if path then
                    frame:SetFont(path, size)
                else
                    frame:SetFont("Fonts\\ARIALN.TTF", 14)
                end
            end
        end

        if ChatFontNormal then
            if path then
                SafeSetFont(ChatFontNormal, path, size)
            else
                SafeSetFont(ChatFontNormal, "Fonts\\ARIALN.TTF", 14)
            end
        end
    end

    -- ---------------------------------------------------------------
    -- Tooltip font
    -- ---------------------------------------------------------------
    local function ApplyUnicodeTooltip(enable)
        local scale = DFRL:GetTempDB("Fonts", "unicodeFontScale") or 1.0
        local path  = enable and GetUnicodeFontPath()

        local tooltipFonts = {
            {obj = GameTooltipText,        size = 13},
            {obj = GameTooltipHeaderText,  size = 14},
            {obj = GameTooltipTextSmall,   size = 11},
        }

        for i = 1, 30 do
            local l = _G["GameTooltipTextLeft"  .. i]
            local r = _G["GameTooltipTextRight" .. i]
            if l then table.insert(tooltipFonts, {obj = l, size = 13}) end
            if r then table.insert(tooltipFonts, {obj = r, size = 13}) end
        end

        for _, entry in ipairs(tooltipFonts) do
            if entry.obj then
                if path then
                    SafeSetFont(entry.obj, path, entry.size * scale)
                else
                    SafeSetFont(entry.obj, "Fonts\\FRIZQT__.TTF", entry.size)
                end
            end
        end
    end

    -- ---------------------------------------------------------------
    -- Callbacks
    -- ---------------------------------------------------------------
    local callbacks = {}

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
        ApplyUnicodeChat(value)
    end

    callbacks.unicodeTooltip = function(value)
        if not DFRL.addon5 then return end
        ApplyUnicodeTooltip(value)
    end

    callbacks.unicodeFontScale = function(value)
        if not DFRL.addon5 then return end
        if DFRL:GetTempDB("Fonts", "unicodeUnitFrames") then ApplyUnicodeUnitFrames(true) end
        if DFRL:GetTempDB("Fonts", "unicodeChat")       then ApplyUnicodeChat(true)       end
        if DFRL:GetTempDB("Fonts", "unicodeTooltip")    then ApplyUnicodeTooltip(true)    end
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
