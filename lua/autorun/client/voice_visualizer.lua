-- Code based on Garry's Base Gamemode
local vv                = {}
local PANEL             = {}
local PlayerVoicePanels = {}

-- Color
vv.BarColor = {
  [0]  = Color(0  , 255, 0), -- Low amplitude 0% -> Green
  [25] = Color(255, 255, 0), -- Middle amplitude 25 % -> Yellow
  [50] = Color(255,   0, 0)  -- High amplitude 50% -> Red
}

-- Adjust Bar Height
-- This is a PERFECT setting - Be sure before changing it
-- Default: 40
vv.BarHeightMultiplier = CreateClientConVar("vv_bar_height", "40", true, false, "Adjust Bar Height")

-- Update Rate
-- If you want it faster, increase the rate
-- If you want it slower, decrease the rate
-- Default: 0.1
vv.UpdateRate = CreateClientConVar("vv_update_rate", "0.1", true, false, "Update Rate\nIf you want it faster, increase the rate\nIf you want it slower, decrease the rate")

-- Single Bar Width
-- If you want more bars, decrease the value
-- and increase the Bar Count
-- Default: 5
vv.SingleBarWidth = CreateClientConVar("vv_bar_width", "5", true, false, "Single Bar Width")

-- Bar Count
-- How many bars do you want to be displayed?
-- Default: 30 (Perfect setting with bar width 5)
vv.BarCount = CreateClientConVar("vv_bar_count", "30", true, false, "Bar Count")

-- Bar Distance
-- Distance between 2 Bars
-- Default: 2
vv.BarDistance = CreateClientConVar("vv_bar_distance", "2", true, false, "Distance between Bars")

-- Background Color
-- Background Color of the bar itself
-- This HAS to be a function
-- Default: Black
vv.BackgroundColor = function(panel, ply)
    -- Tip if you have a TTT server
    -- This will normalize the background color of the panel (Green for Info, Blue for Detective and Red in private Traitor Voice Channel)
    -- Change the line under me to: return panel.Color
    return Color(0,0,0)
end

-- Name Color
-- Color of the name
-- This HAS to be a function
-- Default: White
vv.NameColor = function(panel, ply)
    return Color(255,255,255)
end

-- Name Font
-- Font of the name
-- This HAS to be a function
-- Default: GModNotify
vv.NameFont = function(panel, ply)
    return "GModNotify"
end

-- Call Gamemode Paint function
-- I highly recommend this stays turned off
-- for example: If your gamemode draws a box, it will draw over the bar and stuff
-- That would not be good
-- Default: false (you should keep it that way)
vv.CallGamemodePaintFunc = CreateClientConVar("vv_call_gm_paint_func", "0", true, false, "Call Gamemode Paint function\nI highly recommend this stays turned off\nfor example: If your gamemode draws a box, it will draw over the bar and stuff. That would not be good")

-- Gamemode Paint Function call
-- You have to test this function out on your gamemode
-- This sets ether the gamemode paint function should be called before (true) or after (false) my paint function
-- Again, test it out yourself
-- NOTE: If you have set vv.CallGamemodePaintFunc to false, this will be ignored!
-- Default: false
vv.CallGamemodePaintFuncFirst = CreateClientConVar("vv_call_gm_paint_func_first", "0", true, false, "Gamemode Paint Function call\nThis sets wether the gamemode paint function should be called before (true) or after (false) my paint function\nNOTE: If you have set 'vv_call_gm_paint_func' to '0', this will be ignored!")

--[[
 * DO NOT EDIT ANYTHING FROM HERE !
]]

function PANEL:Init()
  self.Avatar = vgui.Create("AvatarImage", self)
  self.Avatar:Dock(LEFT)
  self.Avatar:SetSize(32, 32)

  self.Color = Color(0,0,0)

  self:SetSize(250, 32 + 8)
  self:DockPadding(4, 4, 4, 4)
  self:DockMargin(2, 2, 2, 2)
  self:Dock(BOTTOM)

  self.Past = {}
end

function PANEL:Setup(ply)
  self.ply = ply
  --self.LabelName:SetText(ply:Nick())
  self.Avatar:SetPlayer(ply)

  self.Color = team.GetColor(ply:Team())
    timer.Create("PanelThink" .. ply:UniqueID(), vv.UpdateRate:GetFloat(), 0, function()
        if self:IsValid() then
            if self.UpdatePast ~= nil then
                self:UpdatePast()
            end
        end
    end)

  self:InvalidateLayout()

    -- wow.. This is for the shitty gamemodes that overwrite my paint function -.-
    timer.Simple(0, function()
        if self ~= nil then
            if self:IsValid() then
                local PaintFunc = self.Paint

                self.Paint = function(s, w, h)
                    if s ~= nil then
                        if s:IsValid() then
                            -- Idiots
                            if PaintFunc ~= nil and vv.CallGamemodePaintFunc:GetBool() and vv.CallGamemodePaintFuncFirst:GetBool() == true then
                                PaintFunc(s,w,h)
                            end

                            s:VVPaint(w, h)

                            -- Idiots
                            if PaintFunc ~= nil and vv.CallGamemodePaintFunc:GetBool() and vv.CallGamemodePaintFuncFirst:GetBool() == false then
                                PaintFunc(s,w,h)
                            end
                        end
                    end
                end
            end
        end
    end)
end

function PANEL:UpdatePast()
    if self ~= nil and self:IsValid() then
        table.insert(self.Past, self.ply:VoiceVolume())

        local len = #self.Past
        if len > (vv.BarCount:GetInt()-1) then
            table.remove(self.Past, 1)
        end
    end
end

function PANEL:GetBarColor(p)
    local barcolor = Color(0,0,0)

    for i,v in pairs(vv.BarColor) do
        if p > i then
            barcolor = v
        end
    end

    return barcolor
end

function PANEL:VVPaint(w, h)
  if not IsValid(self.ply) or not self:IsValid() then return end
  draw.RoundedBox(4, 0, 0, w, h, vv.BackgroundColor(self, self.ply))

    for i,v in pairs(self.Past) do
        local barh = v * vv.BarHeightMultiplier:GetFloat()
        local barcolor = self:GetBarColor(v * 100)
        surface.SetDrawColor(barcolor)
        surface.DrawRect(35 + i * (vv.BarDistance:GetFloat() + vv.SingleBarWidth:GetFloat()), 36 - barh, vv.SingleBarWidth:GetFloat(), barh)
    end

    -- Draw Name
    surface.SetFont(vv.NameFont(self, self.ply))
    local w,h = surface.GetTextSize(self.ply:Nick())

    surface.SetTextColor(vv.NameColor(self, self.ply))
    surface.SetTextPos(40, 40/2 - h/2)
    surface.DrawText(self.ply:Nick())
end

function PANEL:Think()
    if self:IsValid() then
        if self.fadeAnim then
            self.fadeAnim:Run()
        end
    end
end

function PANEL:FadeOut(anim, delta, data)
  if anim.Finished then

    if IsValid(PlayerVoicePanels[self.ply]) then
      PlayerVoicePanels[self.ply]:Remove()
      PlayerVoicePanels[self.ply] = nil
      return
    end

    return
  end

  self:SetAlpha(255 - (255 * (delta*2)))
end

derma.DefineControl("VoiceNotify", "", PANEL, "DPanel")

-- Support for the shitty gamemodes that like creating there own voice panel -.-
local function HookVoiceVGUI()
    timer.Simple(0, function()
        g_VoicePanelList.OriginalAdd = g_VoicePanelList.Add
        g_VoicePanelList.Add = function(s, what)
            return g_VoicePanelList.OriginalAdd(s, "VoiceNotify")
        end
    end)
end

hook.Add("InitPostEntity", "VVHookVoiceVGUI", HookVoiceVGUI)
