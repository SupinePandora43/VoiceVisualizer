if SERVER then
    AddCSLuaFile()
    return
end
local PANEL = {}
local PlayerVoicePanels = {}
function PANEL:Init()
    self.Avatar = vgui.Create("AvatarImage", self)
    self.Avatar:Dock(LEFT)
    self.Avatar:SetSize(32, 32)
    self:SetSize(250, 32 + 8)
    self:DockPadding(4, 4, 4, 4)
    self:DockMargin(2, 2, 2, 2)
    self:Dock(BOTTOM)
    self.Nick = ""
    self.Past = {}
end
function PANEL:Setup(ply)
    self.ply = ply
    self.Avatar:SetPlayer(ply)
    self.Color = team.GetColor(ply:Team())
    self:InvalidateLayout()
end
function PANEL:Paint(w, h)
    if self ~= nil and self:IsValid() then
        table.insert(self.Past, self.ply:VoiceVolume())
        local len = #self.Past
        if len > (42 - 1) then table.remove(self.Past, 1) end
    end
    if not self then return end
    if not IsValid(self.ply) or not self:IsValid() then return end
    draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0))
    for i, v in pairs(self.Past) do
        local barh = v * 40
        surface.SetDrawColor(self:GetBarColor(v * 100))
        surface.DrawRect(35 + i * 5, 36 - barh, 5, barh)
    end
    surface.SetFont("GModNotify")
    local _, h = surface.GetTextSize(self.ply:Nick())
    surface.SetTextColor(Color(255, 255, 255))
    surface.SetTextPos(40, 40 / 2 - h / 2)
    surface.DrawText(self.ply:Nick())
end
function PANEL:GetBarColor(p)
    if p >= 70 then
        return Color(255, 0, 0)
    elseif p >= 60 then
        return Color(255, 255, 0)
    elseif p >= 10 then
        return Color(0, 255, 0)
    else
        return Color(0, 0, 0)
    end
end
function PANEL:Think()
    if self:IsValid() then if self.fadeAnim then self.fadeAnim:Run() end end
end
function PANEL:FadeOut(anim, delta, data)
	self:SetAlpha(255 - (255 * delta*50))
	if anim.Finished then
        if IsValid(PlayerVoicePanels[self.ply]) then
            PlayerVoicePanels[self.ply]:Remove()
            PlayerVoicePanels[self.ply] = nil
            return
        end
        return
    end
end
derma.DefineControl("VoiceNotify", "", PANEL, "DPanel")
PANEL = nil
