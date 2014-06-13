
local TE		= {}
TE.default		= {
	anchor 		= { TOPLEFT, TOPLEFT, 0, 0},
	nbEmote 		= 0,
	nbRow		= 20,
	fav			= {},
	movable		= true,
	opacity		= 1,
	color			= {}
			}
	
TE.nbEmote = 0
TE.nbRow = 20
TE.fav = {}
TE.showList = false
TE.movable = true
TE.opacity = 1
TE.color = {}
TE.fontColor = { 	{0.77,0.76,0.62,1},	-- default 
			{0.39,0.75,0.29,1},	-- green
			{0.59,0.47,0.86,1}, 	-- purple
			{0.83,0.62,0.37,1},	-- orange
			{0.86,0.47,0.70,1}, 	-- pink
			{0.86,0.47,0.47,1}, 	-- red
			{0.47,0.68,0.86,1}	-- blue
		}
TE.maxColor = table.getn(TE.fontColor)
TE.sliderOffset = 0
TE.alphaList = {}

local tex = "ESOUI/art/lorelibrary/lorelibrary_scroll.dds"
	
function TE:OnAddOnLoaded( eventCode, addOnName )
	
	if ( addOnName ~= "TiEmote") then return end
	
	TiEmote:SetHandler( "OnMouseUp", function()  TiEmoteSaveAnchor() end )
		
	TE.vars = ZO_SavedVars:New("TiEmote_Vars",1,"TiEmote",TE.default)
	
	-- Need to clear anchors, since SetAnchor() will just keep adding new ones.
	TiEmote:ClearAnchors();
	TiEmote:SetAnchor(TE.vars.anchor[1], TiEmote.parent, TE.vars.anchor[2], TE.vars.anchor[3], TE.vars.anchor[4])
	
	-- sort list
	self:InitAlphaList()
	
	-- setup emote button
	self:UpdateEmote()
		
	TE.nbRow = TE.vars.nbRow
	TE.fav = TE.vars.fav
	TE.nbRow = TE.vars.nbRow
	TE.movable = TE.vars.movable
	TE.opacity = TE.vars.opacity
	TE.color = TE.vars.color
	
	--for i = 0, TE.nbEmote-1 do
	for i=0, TE.nbRow-1 do
		local ButtonControl = CreateControlFromVirtual("TE_EmoteButton", TE_EmotePanel, "TE_EmoteButton", i)
		isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = ButtonControl:GetAnchor()
		ButtonControl:SetAnchor(point, relativeTo, relativePoint, offsetX, 30+i*DEFAULT_BUTTON_HEIGHT)
		ButtonControl:SetText(TE:GetEmoteSlashName(i+1,0))
		ButtonControl:SetHandler("OnClicked", function(self,button)
					if button==1 then
						TE:PlayEmote((i+1),0) 
					else
						TE:ToggleFav((i+1),0)
					end
				end)
		ButtonControl:SetHandler("OnMouseWheel", function(self, delta) TE:OnMouseWheel(delta) end)
		ButtonControl:SetHandler("OnMouseDoubleClick", function(self) TE:NextColor(i+TE.sliderOffset) end)
	end
	
	-- slider
	TE.slider = CreateControl("TESlider",TE_EmotePanel,CT_SLIDER)
	TE.slider:SetDimensions(30,TE.nbRow*DEFAULT_BUTTON_HEIGHT)
	TE.slider:SetMouseEnabled(true)
	TE.slider:SetThumbTexture(tex,tex,tex,30,50,0,0,1,1)
	TE.slider:SetMinMax(0,TE.nbEmote-TE.nbRow)
	TE.slider:SetValueStep(1)
	TE.slider:SetAnchor(TOPLEFT,EmoteLabel,TOPLEFT,220,30)
	TE.slider:SetHandler("OnValueChanged",function(self,value,eventReason)
			TE:OnSliderMove(value) end)
			
	-- mousewheel interaction
	-- sometimes the mouse lose focus on panel and it zoom/dezoom cam, so i ve put it on button
	--TE_EmotePanel:SetHandler("OnMouseWheel", function(self, delta) TE:OnMouseWheel(delta) end)
			
	-- update button visibility
	self:UpdateButton()--0,TE.nbRow-1)
	
	-- list visibility
	self:ShowList()
	
	-- init fav
	self:InitFav()
	
	-- fix or movable
	self:UpdateMovable()
	
	-- set opacity
	self:UpdateOpacity(false)
	
	-- update color button
	self:UpdateColor()
	
	-- init config panel
	self:InitConfigPanel()
	
	
end

function TE:OnReticleHidden(eventCode, hidden)
	if (hidden) and not ZO_Compass:IsHidden() then
		TiEmote:SetHidden(false)
	else
		TiEmote:SetHidden(true)
	end
end


EVENT_MANAGER:RegisterForEvent("TiEmote" , EVENT_ADD_ON_LOADED , function(_event, _name) TE:OnAddOnLoaded(_event, _name) end)
EVENT_MANAGER:RegisterForEvent("TiEmote" , EVENT_RETICLE_HIDDEN_UPDATE, function(_event, _hidden) TE:OnReticleHidden(_event, _hidden) end)


function TiEmoteUpdate()
	if ZO_Compass:IsHidden() or not ZO_Loot:IsHidden() then
		TiEmote:SetHidden(true)
	end
end


function  TiEmoteSaveAnchor()
	
	-- Get the new position
	local isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = TiEmote:GetAnchor()
	
	-- Save the anchors
	if ( isValidAnchor ) then
	
	TE.vars.anchor = { point, relativePoint, offsetX, offsetY }
	
	else
	
	d("TiEmote - anchor not valid")
	
	end
end

function TE:InitAlphaList()
	local alpha = {}
	for i=1, GetNumEmotes() do
		table.insert(alpha,{i,GetEmoteSlashName(i)})
	end
	table.sort(alpha, function(a,b) return a[2] < b[2] end)
	for i=1, GetNumEmotes() do
		--d(tostring(alpha[i][2]))
		table.insert(TE.alphaList, {i, alpha[i][1]})
	end
	table.sort(TE.alphaList, function(a,b) return a[1] < b[1] end)
end

function TE:UpdateEmote()
	TE.nbEmote = GetNumEmotes()
	TE.vars.nbEmote = TE.nbEmote
end

function TE:OnSliderMove(value)
	TE.sliderOffset = value
	self:UpdateButton()--value, value+TE.nbRow-1)
	self:UpdateColor()
end

function TE:OnMouseWheel(delta)
	
	local offset = TESlider:GetValue()
	offset = offset - delta
	if (offset < 0) then offset = 0 end
	if (offset > TE.nbEmote-TE.nbRow) then offset = TE.nbEmote-TE.nbRow end
	
	TE.sliderOffset = offset

	TESlider:SetValue(offset)
end

function TE:UpdateButton()--(min,max)
	
	--button = GetControl("EmoteButton"..tostring(1))
	--button:SetText("test")
	--for i = 0, TE.nbEmote-1 do
	--	local button = GetControl("TE_EmoteButton"..tostring(i))
	--	if i<min or i>max then
	--		button:SetHidden(true)
	--	else
	--		button:SetHidden(false)
	--		isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = button:GetAnchor()
	--		button:SetAnchor(point, relativeTo, relativePoint, offsetX, 30+(i-min)*DEFAULT_BUTTON_HEIGHT)
	--	end
	--end
	
	for i= 1, TE.nbRow do
		local button = GetControl("TE_EmoteButton"..tostring(i-1))
				
		button:SetText(TE:GetEmoteSlashName(i,0))
		button:SetHandler("OnClicked", function(self,button)
					if button==1 then
						TE:PlayEmote(i,0) 
					else
						TE:ToggleFav(i,0)
					end
				end)
		button:SetHandler("OnMouseWheel", function(self, delta) TE:OnMouseWheel(delta) end)
		button:SetHandler("OnMouseDoubleClick", function(self) TE:NextColor(i -1) end)
	end
	
end


function TE:GetEmIndexFromEmListIndex(emListId)
	local emIndex = TE.sliderOffset + emListId
	return self.alphaList[emIndex][2]
end

function TE:GetEmListIndexFromEmIndex(emId)
	local bFound = false
	local emAlphaIndex = 0
	for i=1,self.nbEmote do
		if (self.alphaList[i][2] == emId) then
			emAlphaIndex = self.alphaList[i][1]
			bFound = true
			break
		end
	end
	
	if not bFound then
		d("TiEmote - error: emote not found")
		return 1
	end
	
	local emListIndex = emAlphaIndex - TE.sliderOffset
	return emListIndex
end


-- fav = emListIndex or favIndex
function TE:ToggleFav(fav, list)

	local bFav = false
	local idFav = 0
	local emIndex = 0
	
	if list == 0 then -- from emote list
		emIndex = self:GetEmIndexFromEmListIndex(fav)
	else -- from fav
		emIndex = fav
	end
	
	for i=1,table.getn(TE.fav) do
		if (TE.fav[i] == emIndex) then
			bFav = true
			idFav = i
			break
		end
	end

	if bFav then
		--d("already fav -> remove")
		table.remove(TE.fav,idFav)
		self:RemoveFavButton()
	else
		--d("not in fav -> add")
		table.insert(TE.fav,emIndex)
		self:AddFavButton(emIndex)
	end
	
	TE.vars.fav = TE.fav
end

function TiEmoteToggleList()
	TE.showList = not TE.showList
	TE:ShowList()
end

function TE:ShowList()
	if (TE.showList) then
		TE_EmotePanel:SetHidden(false)
	else
		TE_EmotePanel:SetHidden(true)
	end
end

function TE:InitFav()
	local n = table.getn(TE.fav)
	
	for i=1, n do
		local buttonControl = CreateControlFromVirtual("TE_FavButton", TiEmote, "TE_FavButton", i)
		isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = buttonControl:GetAnchor()
		buttonControl:SetAnchor(TOPLEFT, TiEmoteLabel, TOPLEFT, -40, 30+(i-1)*DEFAULT_BUTTON_HEIGHT)
		--buttonControl:SetAnchor(point, relativeTo, relativePoint, offsetX, 30+(i-1)*DEFAULT_BUTTON_HEIGHT)
		buttonControl:SetText(TE:GetEmoteSlashName(TE.fav[i],1))
		buttonControl:SetHandler("OnClicked", function(self,button)
			if (button==1) then
				TE:PlayEmote(TE.fav[i],1) 
			else	
				TE:ToggleFav(TE.fav[i],1)
			end
		end)
	end
end

function TE:AddFavButton(fav)

	local n = table.getn(TE.fav)

	-- check if already exist but is hidden
	local buttonControl = GetControl("TE_FavButton"..tostring(n))
	if buttonControl == nil then
		buttonControl = CreateControlFromVirtual("TE_FavButton", TiEmote, "TE_FavButton", n)
	else
		buttonControl:ClearAnchors();
		buttonControl:SetHidden(false)
	end
	
	isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = buttonControl:GetAnchor()
	buttonControl:SetAnchor(TOPLEFT, TiEmoteLabel, TOPLEFT, -40, 30+(n-1)*DEFAULT_BUTTON_HEIGHT)
	--buttonControl:SetAnchor(point, relativeTo, relativePoint, offsetX, 30+(n-1)*DEFAULT_BUTTON_HEIGHT)
	buttonControl:SetText(TE:GetEmoteSlashName(fav,1))
	buttonControl:SetHandler("OnClicked", function(self,button)
		if (button==1) then
			TE:PlayEmote(fav,1) 
		else
			TE:ToggleFav(fav,1)
		end
	end)

end

function TE:RemoveFavButton()

	local n = table.getn(TE.fav)

	local lastButton = GetControl("TE_FavButton"..tostring(n+1))
	lastButton:SetHidden(true)
	
	-- update
	for i = 1, n do
		local button = GetControl("TE_FavButton"..tostring(i))
		button:ClearAnchors();
		isValidAnchor, point, relativeTo, relativePoint, offsetX, offsetY = button:GetAnchor()
		button:SetAnchor(TOPLEFT, TiEmoteLabel, TOPLEFT, -40, 30+(i-1)*DEFAULT_BUTTON_HEIGHT)
		--button:SetAnchor(point, relativeTo, relativePoint, offsetX, 30+(i-1)*DEFAULT_BUTTON_HEIGHT)
		button:SetText(TE:GetEmoteSlashName(TE.fav[i],1))
		button:SetHidden(false)
		button:SetHandler("OnClicked", function(self,button)
			if (button==1) then
				TE:PlayEmote(TE.fav[i],1)
			else
				TE:ToggleFav(TE.fav[i],1)
			end
		end)
	end
end

function TE:PlayEmote(emListId, list)
	local emId = 0
	if list == 0 then
		emId = TE:GetEmIndexFromEmListIndex(emListId)
	else
		emId = emListId
	end
	PlayEmote(emId)
end

function TE:GetEmoteSlashName(emListId, list)
	local emId = 0
	if list == 0 then
		emId = self:GetEmIndexFromEmListIndex(emListId)
	else
		emId = emListId
	end
	--d("emlistid:"..tostring(emListId).." emid:"..tostring(emid).." =>"..GetEmoteSlashName(emId))
	return GetEmoteSlashName(emId)
end

function TE:UpdateMovable()
	TiEmote:SetMovable(TE.movable)
end

function TE:ToggleMovable()
	TE.movable = not TE.movable
	self:UpdateMovable()
	TE.vars.movable = TE.movable
	return TE.movable
end

function TE:UpdateOpacity(bMousein)
	if bMousein then
		TiEmote:SetAlpha(1)
	else
		TiEmote:SetAlpha(TE.opacity)
	end
end

function TE:SetOpacity(alpha)
	TE.opacity = alpha
	TE.vars.opacity = alpha
	self:UpdateOpacity(false)
end

function TE:GetColor(idcolor)
	return TE.fontColor[idcolor+1]
end

function TE:NextColor(idbutton)
	local button = GetControl("TE_EmoteButton"..tostring(idbutton))
	local emId = self:GetEmIndexFromEmListIndex(idbutton+1)
	
	local bColor = false
	local idColor = 0
	
	for i=1,table.getn(TE.color) do
		if (TE.color[i][1] == emId) then
			bColor = true
			idColor = i
			break
		end
	end
	
	local color = self:GetColor(0)
	if bColor then
		local numColor = TE.color[idColor][2]
		
		if numColor < TE.maxColor - 1 then
			TE.color[idColor][2] = numColor + 1
			color = self:GetColor(numColor+1)
		else
			color = self:GetColor(0)
			table.remove(TE.color,idColor)
		end
	else
		color = self:GetColor(1)
		table.insert(TE.color,{emId,1})
	end
	
	button:SetNormalFontColor(color[1], color[2], color[3], color[4])
	button:SetMouseOverFontColor(color[1], color[2], color[3], color[4])
	button:SetPressedFontColor(color[1], color[2], color[3], color[4])
	
	TE.vars.color = TE.color
end

function TE:UpdateColor()
	--for i=1, table.getn(TE.color) do
	--	
	--	local emId = TE.color[i][1] + 1
	--	local emListId = self:GetEmListIndexFromEmIndex(emId)
	--	if emListId > 0 and emListId <= TE.nbRow then
	--		local button = GetControl("TE_EmoteButton"..tostring(emListId-1))
	--		if (button ~= nil) then
	--			local idcolor = TE.color[i][2]
	--			local color = self:GetColor(idcolor)
	--			button:SetNormalFontColor(color[1], color[2], color[3], color[4])
	--			button:SetMouseOverFontColor(color[1], color[2], color[3], color[4])
	--			button:SetPressedFontColor(color[1], color[2], color[3], color[4])
	--		end
	--	end
	--end
	
	for i=1, TE.nbRow do
		local emId = self:GetEmIndexFromEmListIndex(i)
		local button = GetControl("TE_EmoteButton"..tostring(i-1))
		if (button ~= nil) then
			local bFound = false
			local idFound = 0
			local color
			for j=1, table.getn(TE.color) do
				if (TE.color[j][1] == emId) then
					bFound = true
					idFound = TE.color[j][2]
					break
				end
			end
			
			if bFound then
				color = self:GetColor(idFound)
			else
				color = self:GetColor(0)
			end
			button:SetNormalFontColor(color[1], color[2], color[3], color[4])
			button:SetMouseOverFontColor(color[1], color[2], color[3], color[4])
			button:SetPressedFontColor(color[1], color[2], color[3], color[4])
		end
	end
end

function TE:InitConfigPanel()
	
	local cPanelId="TiEmoteConfigPanel"
	local panelId = _G[cPanelId]
	
	if not panelId then
		ZO_OptionsWindow_AddUserPanel(cPanelId, "TiEmote")
		panelId = _G[cPanelId]
	end
	
	-- checkbox movable
	local checkbox = CreateControlFromVirtual("TiEmoteMovableCheckbox", ZO_OptionsWindowSettingsScrollChild, "ZO_Options_Checkbox")
	checkbox:SetAnchor(TOPLEFT, checkbox.parent, TOPLEFT, 0, 20)
	checkbox.controlType = OPTIONS_CHECKBOX
	checkbox.panel = panelId
	checkbox.system = SETTING_TYPE_UI
	checkbox.settingId = _G["SETTING_TiEmoteMovableCheckbox"]
	checkbox.text = "Movable"
	
	local checkboxButton = checkbox:GetNamedChild("Checkbox")
	
	
	ZO_PreHookHandler(checkbox, "OnShow", function()
			checkboxButton:SetState(TE.movable and 1 or 0)
			checkboxButton:toggleFunction(TE.movable)
		end)
		
	ZO_PreHookHandler(checkboxButton, "OnClicked", function()  
					self:ToggleMovable()
				end)
	
	ZO_OptionsWindow_InitializeControl(checkbox)
	
	-- slider opacity
	local slider = CreateControlFromVirtual("TiEmoteOpacitySlider", ZO_OptionsWindowSettingsScrollChild, "ZO_Options_Slider")
	slider:SetAnchor(TOPLEFT, checkbox.parent, TOPLEFT, 0, 60)
	slider.controlType = OPTIONS_SLIDER
	slider.panel = panelId
	slider.system = SETTING_TYPE_UI
	slider.text = "Opacity"
	slider.showValue = true
	slider.showValueMin = 0
	slider.showValueMax = 1
	local sliderControl = slider:GetNamedChild("Slider")
	sliderControl:SetValueStep(0.1)
	local sliderLabel = slider:GetNamedChild("ValueLabel")
	slider:SetHandler("OnShow", function() 
			sliderControl:SetValue(TE.opacity) 
			sliderLabel:SetText(string.format("%.1f",TE.opacity))
			end)
	sliderControl:SetHandler("OnValueChanged", function(_self, _val)
			_self:SetValue(_val)
			sliderLabel:SetText(string.format("%.1f",_val))
			end)
	sliderControl:SetHandler("OnSliderReleased", function(_self, _val)
			TE:SetOpacity(_val)
			end)
			
	ZO_OptionsWindow_InitializeControl(slider)
	
end