DFRL:NewDefaults("TargetCastbar", {
    enabled = {true},
    enemyCastbar = {false, "checkbox", nil, nil, "enemy castbar", 1, "Enable enemy target castbar", "Requires ShaguTweaks", nil},
    enemyCastbarIcon = {true, "checkbox", nil, "enemyCastbar", "enemy castbar", 2, "Show enemy castbar spell icon", nil, nil},
    enemyCastbarText = {true, "checkbox", nil, "enemyCastbar", "enemy castbar", 3, "Show enemy castbar spell text", nil, nil},
    enemyCastbarTime = {true, "checkbox", nil, "enemyCastbar", "enemy castbar", 4, "Show enemy castbar time", nil, nil},
    enemyCastbarWidth = {140, "slider", {100, 250}, "enemyCastbar", "enemy castbar", 5, "Change enemy castbar width", nil, nil},
    enemyCastbarHeight = {10, "slider", {8, 24}, "enemyCastbar", "enemy castbar", 6, "Change enemy castbar height", nil, nil},
    enemyCastbarFontSize = {10, "slider", {6, 18}, "enemyCastbar", "enemy castbar", 7, "Change enemy castbar font size", nil, nil},
    enemyCastbarX = {-12, "slider", {-100, 100}, "enemyCastbar", "enemy castbar", 8, "Change enemy castbar X offset", nil, nil},
    enemyCastbarY = {-4, "slider", {-120, 40}, "enemyCastbar", "enemy castbar", 9, "Change enemy castbar Y offset", nil, nil},
})

DFRL:NewMod("TargetCastbar", 1, function()
    local string = string
    local GetTime = GetTime
    local UnitCastingInfo, UnitChannelInfo

    local Setup = {
        frame = nil,
        barTexture = nil,
        spark = nil,
        backdrop = nil,
        borderframe = nil,
        dropshadow = nil,
        text = nil,
        timeText = nil,
        icon = nil,

        config = {
            width = 140,
            height = 10,
            bgTexture = "Interface\\AddOns\\DragonflightUI-Reforged\\media\\tex\\castbar\\CastingBarBackground.blp",
            barTexture = "Interface\\AddOns\\DragonflightUI-Reforged\\media\\tex\\castbar\\CastingBarStandard3.blp",
            dropshadow = "Interface\\AddOns\\DragonflightUI-Reforged\\media\\tex\\castbar\\CastingBarFrameDropShadow.blp",
            borderframe = "Interface\\AddOns\\DragonflightUI-Reforged\\media\\tex\\castbar\\CastingBarFrame.blp",
            spark = "Interface\\CastingBar\\UI-CastingBar-Spark",
            barColor = { r = 1, g = 0.82, b = 0 },
            font = "Fonts\\FRIZQT__.TTF",
            fontSize = 10,
            textColor = { r = 1, g = 1, b = 1 },
        },

        state = {
            casting = false,
            channeling = false,
            startTime = 0,
            endTime = 0,
            currentProgress = 0,
            spell = nil,
            texture = nil,
            nextPoll = 0,
            layoutKey = nil,
            enabled = false,
        },
    }

    function Setup:GetCastFont()
        local fontValue = DFRL:GetTempDB("Cast", "castFont")
        if fontValue == "Expressway" then
            return "Interface\\AddOns\\DragonflightUI-Reforged\\media\\fnt\\Expressway.ttf"
        elseif fontValue == "Homespun" then
            return "Interface\\AddOns\\DragonflightUI-Reforged\\media\\fnt\\Homespun.ttf"
        elseif fontValue == "Hooge" then
            return "Interface\\AddOns\\DragonflightUI-Reforged\\media\\fnt\\Hooge.ttf"
        elseif fontValue == "Myriad-Pro" then
            return "Interface\\AddOns\\DragonflightUI-Reforged\\media\\fnt\\Myriad-Pro.ttf"
        elseif fontValue == "Prototype" then
            return "Interface\\AddOns\\DragonflightUI-Reforged\\media\\fnt\\Prototype.ttf"
        elseif fontValue == "PT-Sans-Narrow-Bold" then
            return "Interface\\AddOns\\DragonflightUI-Reforged\\media\\fnt\\PT-Sans-Narrow-Bold.ttf"
        elseif fontValue == "PT-Sans-Narrow-Regular" then
            return "Interface\\AddOns\\DragonflightUI-Reforged\\media\\fnt\\PT-Sans-Narrow-Regular.ttf"
        elseif fontValue == "RobotoMono" then
            return "Interface\\AddOns\\DragonflightUI-Reforged\\media\\fnt\\RobotoMono.ttf"
        elseif fontValue == "BigNoodleTitling" then
            return "Interface\\AddOns\\DragonflightUI-Reforged\\media\\fnt\\BigNoodleTitling.ttf"
        elseif fontValue == "Continuum" then
            return "Interface\\AddOns\\DragonflightUI-Reforged\\media\\fnt\\Continuum.ttf"
        elseif fontValue == "DieDieDie" then
            return "Interface\\AddOns\\DragonflightUI-Reforged\\media\\fnt\\DieDieDie.ttf"
        end

        return "Fonts\\FRIZQT__.TTF"
    end

    function Setup:GetCastColor()
        local intensity = DFRL:GetTempDB("Cast", "castDarkMode")
        local castColor = DFRL:GetTempDB("Cast", "castColor")
        return castColor[1] * (1 - intensity), castColor[2] * (1 - intensity), castColor[3] * (1 - intensity)
    end

    function Setup:ApplyStyle()
        local r, g, b = self:GetCastColor()
        local font = self:GetCastFont()
        local fontSize = DFRL:GetTempDB("TargetCastbar", "enemyCastbarFontSize")

        self.backdrop:SetVertexColor(r, g, b)
        self.borderframe:SetVertexColor(r, g, b)
        self.text:SetFont(font, fontSize, "OUTLINE")
        self.timeText:SetFont(font, fontSize, "OUTLINE")

        if DFRL:GetTempDB("Cast", "showShadow") then
            self.dropshadow:Show()
        else
            self.dropshadow:Hide()
        end
    end

    function Setup:ApplySize()
        self.config.width = DFRL:GetTempDB("TargetCastbar", "enemyCastbarWidth")
        self.config.height = DFRL:GetTempDB("TargetCastbar", "enemyCastbarHeight")

        self.frame:SetWidth(self.config.width)
        self.frame:SetHeight(self.config.height)
        self.barTexture:SetHeight(self.config.height)
        self.dropshadow:SetWidth(self.config.width + 1)
        self.dropshadow:SetHeight(self.config.height + 9)
        self.spark:SetHeight(self.config.height + 15)
        self:UpdateBarVisual(self.state.currentProgress)
        self:UpdatePosition(true)
    end

    function Setup:TargetCastbar()
        local f = CreateFrame("Frame", "DFRLTargetCastbar", TargetFrame)
        f:SetHeight(self.config.height)
        f:SetWidth(self.config.width)
        f:Hide()

        local bd = f:CreateTexture(nil, "BACKGROUND", 7)
        bd:SetAllPoints(f)
        bd:SetTexture(self.config.bgTexture)
        self.backdrop = bd

        local bar = f:CreateTexture(nil, "BORDER")
        bar:SetPoint("LEFT", f, "LEFT", 0, 0)
        bar:SetHeight(self.config.height)
        bar:SetWidth(0)
        bar:SetTexture(self.config.barTexture)
        bar:SetVertexColor(self.config.barColor.r, self.config.barColor.g, self.config.barColor.b)
        self.barTexture = bar

        local borderFrame = f:CreateTexture(nil, "ARTWORK")
        borderFrame:SetAllPoints(f)
        borderFrame:SetTexture(self.config.borderframe)
        self.borderframe = borderFrame

        local dropshadow = f:CreateTexture(nil, "BACKGROUND", 1)
        dropshadow:SetWidth(self.config.width + 1)
        dropshadow:SetHeight(self.config.height + 9)
        dropshadow:SetPoint("TOP", f, "BOTTOM", 0, 5)
        dropshadow:SetTexture(self.config.dropshadow)
        self.dropshadow = dropshadow

        local spark = f:CreateTexture(nil, "OVERLAY")
        spark:SetHeight(self.config.height + 15)
        spark:SetWidth(25)
        spark:SetTexture(self.config.spark)
        spark:SetBlendMode("ADD")
        spark:Hide()
        self.spark = spark

        local icon = CreateFrame("Frame", nil, f)
        icon:SetPoint("RIGHT", f, "LEFT", -2, 0)
        icon:SetHeight(20)
        icon:SetWidth(20)
        icon:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        icon.texture = icon:CreateTexture(nil, "BACKGROUND")
        icon.texture:SetPoint("CENTER", 0, 0)
        icon.texture:SetWidth(16)
        icon.texture:SetHeight(16)
        icon:Hide()
        self.icon = icon

        local ts = f:CreateFontString(nil, "OVERLAY")
        ts:SetFont(self.config.font, self.config.fontSize, "OUTLINE")
        ts:SetPoint("LEFT", f, "LEFT", 4, -14)
        ts:SetPoint("RIGHT", f, "RIGHT", -4, -14)
        ts:SetTextColor(self.config.textColor.r, self.config.textColor.g, self.config.textColor.b)
        self.text = ts

        local tt = f:CreateFontString(nil, "OVERLAY")
        tt:SetFont(self.config.font, self.config.fontSize, "OUTLINE")
        tt:SetPoint("RIGHT", f, "RIGHT", -4, -14)
        tt:SetTextColor(self.config.textColor.r, self.config.textColor.g, self.config.textColor.b)
        self.timeText = tt

        self.frame = f
        self:UpdatePosition(true)
    end

    function Setup:GetLayoutKey()
        local targetOfTarget = TargetofTargetFrame and TargetofTargetFrame:IsShown() and 1 or 0
        local debuff11 = TargetFrameDebuff11 and TargetFrameDebuff11:IsShown() and 1 or 0
        local debuff7 = TargetFrameDebuff7 and TargetFrameDebuff7:IsShown() and 1 or 0
        local buff1 = TargetFrameBuff1 and TargetFrameBuff1:IsShown() and 1 or 0
        return targetOfTarget .. debuff11 .. debuff7 .. buff1 .. DFRL:GetTempDB("TargetCastbar", "enemyCastbarX") .. DFRL:GetTempDB("TargetCastbar", "enemyCastbarY")
    end

    function Setup:UpdatePosition(force)
        if not self.frame then return end

        local layoutKey = self:GetLayoutKey()
        if not force and self.state.layoutKey == layoutKey then return end
        self.state.layoutKey = layoutKey

        local x = DFRL:GetTempDB("TargetCastbar", "enemyCastbarX")
        local y = DFRL:GetTempDB("TargetCastbar", "enemyCastbarY")
        local targetOfTarget = TargetofTargetFrame and TargetofTargetFrame:IsShown()
        local debuff11 = TargetFrameDebuff11 and TargetFrameDebuff11:IsShown()
        local debuff7 = TargetFrameDebuff7 and TargetFrameDebuff7:IsShown()
        local buff1 = TargetFrameBuff1 and TargetFrameBuff1:IsShown()

        if targetOfTarget then
            y = y - 20
            if debuff11 then
                y = y - 21
                if buff1 then
                    y = y - 20
                end
            end
        elseif debuff7 then
            y = y - 20
        end

        self.frame:ClearAllPoints()
        self.frame:SetPoint("BOTTOM", TargetFrame, "BOTTOM", x, y)
    end

    function Setup:UpdateBarVisual(progress)
        if progress < 0 then progress = 0 end
        if progress > 1 then progress = 1 end

        local width = self.config.width
        local newWidth = progress * width
        if newWidth < 0.1 then newWidth = 0.1 end

        self.barTexture:SetPoint("LEFT", self.frame, "LEFT", 0, 0)
        self.barTexture:SetWidth(newWidth)
        self.barTexture:SetTexCoord(0, progress, 0, 1)

        if progress > 0 and progress < 1 then
            self.spark:SetPoint("CENTER", self.frame, "LEFT", newWidth, 0)
            self.spark:Show()
        else
            self.spark:Hide()
        end
    end

    function Setup:Hide()
        if self.frame then self.frame:Hide() end
        if self.icon then self.icon:Hide() end
        if self.spark then self.spark:Hide() end
        self.state.casting = false
        self.state.channeling = false
        self.state.spell = nil
        self.state.texture = nil
    end

    function Setup:GetCastQuery()
        local unit = TargetFrame.unit or "target"
        local query = unit

        if ShaguTweaks and ShaguTweaks.superwow_active and unit and not UnitIsUnit(unit, "player") then
            local _, guid = UnitExists(unit)
            query = guid or query
        end

        return query, unit
    end

    function Setup:GetCastInfo()
        local query, unit = self:GetCastQuery()
        local spell, _, _, texture, startTime, endTime = UnitCastingInfo(query)
        local channeling = false

        if not spell then
            spell, _, _, texture, startTime, endTime = UnitChannelInfo(query)
            channeling = spell and true or false
        end

        if not spell and query ~= unit then
            spell, _, _, texture, startTime, endTime = UnitCastingInfo(unit)
            if not spell then
                spell, _, _, texture, startTime, endTime = UnitChannelInfo(unit)
                channeling = spell and true or false
            else
                channeling = false
            end
        end

        return spell, texture, startTime, endTime, channeling
    end

    function Setup:Poll()
        if not self.state.enabled then
            self:Hide()
            return
        end

        if not UnitCastingInfo or not UnitChannelInfo or not TargetFrame or not TargetFrame:IsShown() then
            self:Hide()
            return
        end

        local spell, texture, startTime, endTime, channeling = self:GetCastInfo()
        if not spell or not startTime or not endTime then
            self:Hide()
            return
        end

        self.state.casting = not channeling
        self.state.channeling = channeling
        self.state.startTime = startTime
        self.state.endTime = endTime
        self.state.spell = spell
        self.state.texture = texture

        self:ApplyStyle()
        self:UpdatePosition(true)
        self.frame:SetAlpha(1)
        self.frame:Show()
    end

    function Setup:Render()
        local s = self.state
        if not s.casting and not s.channeling then return end

        local now = GetTime()
        local startSeconds = s.startTime / 1000
        local endSeconds = s.endTime / 1000
        local duration = endSeconds - startSeconds
        if duration <= 0 then
            self:Hide()
            return
        end

        local progress
        if s.channeling then
            progress = (endSeconds - now) / duration
        else
            progress = (now - startSeconds) / duration
        end

        if progress < 0 or progress > 1 then
            self:Hide()
            return
        end

        self:UpdatePosition()
        self:UpdateBarVisual(progress)

        if DFRL:GetTempDB("TargetCastbar", "enemyCastbarText") then
            self.text:SetText(s.spell)
            self.text:Show()
        else
            self.text:Hide()
        end

        if DFRL:GetTempDB("TargetCastbar", "enemyCastbarTime") then
            local remaining = endSeconds - now
            if remaining < 0 then remaining = 0 end
            if remaining >= 10 then
                self.timeText:SetText(string.format('%.0f', remaining))
            else
                self.timeText:SetText(string.format('%.1f', remaining))
            end
            self.timeText:Show()
        else
            self.timeText:Hide()
        end

        if DFRL:GetTempDB("TargetCastbar", "enemyCastbarIcon") and s.texture then
            self.icon.texture:SetTexture(s.texture)
            self.icon:Show()
        else
            self.icon:Hide()
        end

        s.currentProgress = progress
    end

    function Setup:PollUpdate()
        local now = GetTime()
        if now < self.state.nextPoll then return end

        self.state.nextPoll = now + 0.05
        self:Poll()
    end

    function Setup:IsActive()
        return self.state.casting or self.state.channeling
    end

    DFRL:OnShaguReady(function()
        UnitCastingInfo = ShaguTweaks.UnitCastingInfo
        UnitChannelInfo = ShaguTweaks.UnitChannelInfo
    end)

    Setup:TargetCastbar()
    Setup:ApplySize()
    Setup:ApplyStyle()

    local updateFrame = CreateFrame("Frame")
    updateFrame:SetScript("OnUpdate", function()
        if Setup.state.enabled then
            Setup:PollUpdate()
        elseif Setup.frame:IsShown() then
            Setup:Hide()
            return
        end

        if Setup:IsActive() then
            Setup:Render()
        end
    end)

    local callbacks = {}

    callbacks.enemyCastbar = function(value)
        Setup.state.enabled = value
        if value then
            Setup:Poll()
        else
            Setup:Hide()
        end
    end

    callbacks.enemyCastbarIcon = function(value)
        if not value then Setup.icon:Hide() end
    end

    callbacks.enemyCastbarText = function(value)
        if value then
            Setup.text:Show()
        else
            Setup.text:Hide()
        end
    end

    callbacks.enemyCastbarTime = function(value)
        if value then
            Setup.timeText:Show()
        else
            Setup.timeText:Hide()
        end
    end

    callbacks.enemyCastbarWidth = function()
        Setup:ApplySize()
    end

    callbacks.enemyCastbarHeight = function()
        Setup:ApplySize()
    end

    callbacks.enemyCastbarFontSize = function()
        Setup:ApplyStyle()
    end

    callbacks.enemyCastbarX = function()
        Setup:UpdatePosition(true)
    end

    callbacks.enemyCastbarY = function()
        Setup:UpdatePosition(true)
    end

    DFRL:NewCallbacks("TargetCastbar", callbacks)
end)
