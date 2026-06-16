-- unitname_translate.lua
-- Translates Chinese unit names on target, target-of-target, pet, party, and raid
-- frames using WoWTranslate (glossary → persistent cache → async DLL API).
--
-- Load order: must come AFTER modules\unit\target.lua and modules\unit\mini.lua
-- Priority 2 (same as Fonts) so it runs after all priority-1 unit modules.
--
-- Dependency: WoWTranslate addon (optional). When absent the module is a no-op.

DFRL:NewDefaults("UnitNameTranslate", {
    enabled         = {true},
    translateTarget = {true,  "checkbox", nil, nil, "Translation", 1,
                        "Translate Chinese target names (requires WoWTranslate)", nil, nil},
    translateTot    = {true,  "checkbox", nil, nil, "Translation", 2,
                        "Translate Chinese target-of-target names (requires WoWTranslate)", nil, nil},
    translatePet    = {true,  "checkbox", nil, nil, "Translation", 3,
                        "Translate Chinese pet names (requires WoWTranslate)", nil, nil},
    translateParty  = {true,  "checkbox", nil, nil, "Translation", 4,
                        "Translate Chinese party member names (requires WoWTranslate)", nil, nil},
    translateRaid   = {true,  "checkbox", nil, nil, "Translation", 5,
                        "Translate Chinese raid member names (requires WoWTranslate)", nil, nil},
})

DFRL:NewMod("UnitNameTranslate", 2, function()

    -- -------------------------------------------------------------------------
    -- Helpers
    -- -------------------------------------------------------------------------

    -- Returns true if the string contains at least one CJK Unified Ideograph
    -- (U+4E00–U+9FFF) encoded as UTF-8 (3-byte sequences where the first byte is 228-233).
    -- Optimized to use native C-level pattern matching and safe decimal escape sequences.
    local function HasChinese(str)
        if not str then return false end
        return string.find(str, "[\228-\233][\128-\191][\128-\191]") ~= nil
    end

    -- Fast glossary + cache lookup; returns translation or nil.
    local function QuickLookup(name)
        -- 1. WoWTranslate glossary (WoW-specific terms, 100 % accuracy)
        if WoWTranslateGlossary and WoWTranslateGlossary[name] then
            return WoWTranslateGlossary[name]
        end
        -- 2. Persistent cross-session cache (SavedVariables)
        local cached = WoWTranslate_CacheGet and WoWTranslate_CacheGet(name)
        if cached then return cached end
        return nil
    end

    -- Save a successful translation to the persistent cache so later lookups
    -- are instant.
    local function SaveToCache(original, translation)
        if WoWTranslate_CacheSave then
            WoWTranslate_CacheSave(original, translation)
        end
    end

    -- Applies translated text to a FontString, putting English first
    -- followed by the original CJK name in brackets:
    --   "龙王" → "Dragon King [龙王]"
    local function ApplyName(fontString, original, translation)
        if not fontString then return end
        if translation and translation ~= "" then
            fontString:SetText(translation .. " [" .. original .. "]")
        else
            fontString:SetText(original)
        end
    end

    -- -------------------------------------------------------------------------
    -- Per-unit translation entry point
    -- -------------------------------------------------------------------------

    -- Translate `name` and apply it to `fontString`.  The function:
    --   1. Does nothing if name is not Chinese.
    --   2. Applies an instant result from glossary/cache if available.
    --   3. Tags the widget to prevent async race conditions.
    --   4. Falls back to async DLL request; updates the FontString on completion.
    local function TranslateName(fontString, name)
        if not fontString or not name or name == "" then return end
        if not HasChinese(name) then return end

        -- Instant path (No closures or memory allocations created here)
        local fast = QuickLookup(name)
        if fast then
            ApplyName(fontString, name, fast)
            return
        end

        -- Async path --
        if not (WoWTranslate_API and WoWTranslate_API.IsAvailable and WoWTranslate_API.IsAvailable()) then
            return
        end

        -- Improvement 1: Widget Tagging. Stamp the expected name directly onto the UI table.
        fontString.trackingName = name

        WoWTranslate_API.Translate(name, function(translation, err)
            if translation and translation ~= "" then
                SaveToCache(name, translation)
                
                -- Improvement 1: Strict equality check ensures that even if a player target-cycles 
                -- lightning-fast, the translation matches exactly what the frame is *currently* showing.
                if fontString.trackingName == name then
                    ApplyName(fontString, name, translation)
                end
            end
        end, "zh")
    end

    -- -------------------------------------------------------------------------
    -- Frame Update Wrappers
    -- -------------------------------------------------------------------------
    local function UpdateTargetName()
        if not DFRL:GetTempDB("UnitNameTranslate", "translateTarget") then return end
        if not UnitExists("target") then return end
        local name = UnitName("target")
        if not name then return end
        TranslateName(TargetFrame.name, name)
    end

    local function UpdateTotName()
        if not DFRL:GetTempDB("UnitNameTranslate", "translateTot") then return end
        if not UnitExists("targettarget") then return end
        local name = UnitName("targettarget")
        if not name then return end
        if TargetofTargetFrame and TargetofTargetFrame.name then
            TranslateName(TargetofTargetFrame.name, name)
        end
    end

    local function UpdatePetName()
        if not DFRL:GetTempDB("UnitNameTranslate", "translatePet") then return end
        if not UnitExists("pet") then return end
        local name = UnitName("pet")
        if not name then return end
        if PetName then
            TranslateName(PetName, name)
        end
    end

    local function UpdatePartyNames()
        if not DFRL:GetTempDB("UnitNameTranslate", "translateParty") then return end
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) then
                local name = UnitName(unit)
                local fontString = _G["PartyMemberFrame" .. i .. "Name"]
                if name and fontString then
                    TranslateName(fontString, name)
                end
            end
        end
    end

    -- Improvement 4: Added 40-man Raid Frame translation processing loop
    local function UpdateRaidNames()
        if not DFRL:GetTempDB("UnitNameTranslate", "translateRaid") then return end
        for i = 1, 40 do
            local unit = "raid" .. i
            if UnitExists(unit) then
                local name = UnitName(unit)
                local fontString = _G["RaidGroupButton" .. i .. "Name"]
                if name and fontString then
                    TranslateName(fontString, name)
                end
            end
        end
    end

    -- -------------------------------------------------------------------------
    -- Event driver
    -- -------------------------------------------------------------------------
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("PARTY_MEMBERS_CHANGED")
    f:RegisterEvent("RAID_ROSTER_UPDATE")   -- Listens for raid group changes
    f:RegisterEvent("UNIT_PET")
    f:RegisterEvent("UNIT_TARGET")         -- Catches target switching their own target
    f:RegisterEvent("UNIT_NAME_UPDATE")    -- Handles late-resolving or clearing unit strings

    f:SetScript("OnEvent", function()
        -- Note: event and arg1 are global variables exposed inside 1.12 OnEvent layouts
        if event == "PLAYER_TARGET_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
            UpdateTargetName()
            UpdateTotName()    
            UpdatePartyNames() 
            UpdateRaidNames()
        elseif event == "UNIT_TARGET" and arg1 == "target" then
            UpdateTotName()
        elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
            UpdatePartyNames()
            UpdateRaidNames()
        elseif event == "UNIT_NAME_UPDATE" then
            if arg1 == "target" then 
                UpdateTargetName()
            elseif arg1 == "targettarget" then 
                UpdateTotName()
            elseif arg1 and string.find(arg1, "party") then 
                UpdatePartyNames() 
            elseif arg1 and string.find(arg1, "raid") then 
                UpdateRaidNames() 
            end
        elseif event == "UNIT_PET" then
            UpdatePetName()
        end
    end)

    -- -------------------------------------------------------------------------
    -- Improvement 2: Secure Function Hooking
    -- Forces our translated string over top of Blizzard's native frame draws
    -- right as they complete, eliminating visual raw CJK flickering.
    -- -------------------------------------------------------------------------
    if TargetFrame_Update then
        local old_TargetFrame_Update = TargetFrame_Update
        TargetFrame_Update = function()
            old_TargetFrame_Update() -- Let native engine draw first
            UpdateTargetName()       -- Instantly clamp our custom layout over it
        end
    end

    if TargetofTarget_Update then
        local old_TargetofTarget_Update = TargetofTarget_Update
        TargetofTarget_Update = function()
            old_TargetofTarget_Update()
            UpdateTotName()
        end
    end

    -- Initial population on module load (handles /reload or late-load scenarios)
    UpdateTargetName()
    UpdateTotName()
    UpdatePetName()
    UpdatePartyNames()
    UpdateRaidNames()

end)