
local rematch = Rematch
local flyout = RematchAbilityFlyout

function rematch:InitializeCurrent()
	rematch.current.header.text:SetText("Current Battle Pets")
	rematch.panel:SetPoint("TOPLEFT",rematch.current,"BOTTOMLEFT")
	for i=1,3 do
		local button = rematch.current.pet[i]
		button:RegisterForDrag("LeftButton")
		button:RegisterForClicks("LeftButtonUp","RightButtonUp")
		button.set = 1
		button:SetID(i)
	end
end

function rematch:UpdateCurrentPets()

	if select(2,C_PetJournal.GetNumPets())==0 then
		-- if pets not loaded, come back in half a second to try again
		rematch:StartTimer("PetsRanAway",0.5,rematch.UpdateCurrentPets)
		return
	end

	local petID
	rematch:WipePetFrames(rematch.current.pet)
	wipe(rematch.info)
	local ability = rematch.info
	for i=1,3 do
		local button = rematch.current.pet[i]
		petID,ability[1],ability[2],ability[3] = C_PetJournal.GetPetLoadOutInfo(i)
		if petID then
			button.petID = petID
			local speciesID,_,level,xp,xpmax,_,_,_,icon = C_PetJournal.GetPetInfoByPetID(petID)
			-- update this pet's icon
		  button.icon:SetTexture(icon)
			button.icon:Show()
			-- update this pet's abilities
			for j=1,3 do
				button.ability[j].abilityID = ability[j]
				button.ability[j].icon:SetTexture((select(2,C_PetJournal.GetPetAbilityInfo(ability[j]))))
				button.ability[j].icon:Show()
				-- confirm pet is high enough to have this ability
				local canUseAbility,abilityLevel
				wipe(rematch.abilityList)
				C_PetJournal.GetPetAbilityList(speciesID,rematch.abilityList,rematch.levelList)
				for k=1,#rematch.abilityList do
					if ability[j]==rematch.abilityList[k] then
						abilityLevel = rematch.levelList[k]
						if level>=abilityLevel then
							-- they have this ability and they're high enough to use it
							canUseAbility = true
						end
						break
					end
				end
				if canUseAbility then
					button.ability[j].icon:SetVertexColor(1,1,1)
					button.ability[j].icon:SetDesaturated(false)
					button.ability[j].level:Hide()
				else
					button.ability[j].icon:SetVertexColor(.3,.3,.3)
					button.ability[j].icon:SetDesaturated(true)
					button.ability[j].level:SetText(abilityLevel)
					button.ability[j].level:Show()
				end
				button.ability[j].canUse = canUseAbility
			end
			-- xp bar: update+show xp bar if pet is less than 25, hide if pet is 25
			local notMax = level<25
			if notMax then
				button.healthBG:SetPoint("TOPLEFT",button,"BOTTOMLEFT",2,1)
				button.xp:SetWidth(xp>0 and 38*(xp/xpmax) or 1)
				button.level.text:SetText(level)
			else
				button.healthBG:SetPoint("TOPLEFT",button,"BOTTOMLEFT",2,-4)
			end
			button.xpBG:SetShown(notMax)
			button.xp:SetShown(notMax)
			button.level:SetShown(notMax)
			-- update hp and whether pet is dead
			local hp,hpmax = C_PetJournal.GetPetStats(petID)
			if hp>0 then
				button.health:SetWidth(hp>0 and 38*(hp/hpmax) or 1)
			end
			button.dead:SetShown(hp==0)
			button.healthBG:Show()
			button.health:SetShown(hp>0)
		else
			button.petID = rematch.emptyPetID
			button.xpBG:Hide()
			button.xp:Hide()
			button.level:Hide()
			button.healthBG:Hide()
			button.health:Hide()
		end

	end
	rematch:UpdateLevelingBorders()

	if rematch:IsLastTeamLoaded() then
		local teamName = RematchSettings.LastTeamNameLoaded
		rematch.current.header.text:SetText(RematchSettings.LastTeamNameLoaded)
		if RematchSaved[teamName][4] then
			rematch.current.header.text:SetTextColor(1,1,1)
		else
			rematch.current.header.text:SetTextColor(1,.82,0)
		end
	else
		rematch.current.header.text:SetText("Current Battle Pets")
		rematch.current.header.text:SetTextColor(1,.82,0)
	end

end

-- there's no event for when loadout pets change (really!) so we hooksecurefunc both
-- SetAbility and SetPetLoadOutInfo to do an update 0.1 seconds after they happen.
-- the wait is to allow multiple simultaneous changes to happen before doing an update
function rematch:WatchForChangingPets()
	if not rematch.loadoutsHooked then
		rematch.loadoutsHooked = 1
		hooksecurefunc(C_PetJournal,"SetAbility",rematch.StartPetsChanging)
		hooksecurefunc(C_PetJournal,"SetPetLoadOutInfo",rematch.StartPetsChanging)
	end
end

function rematch:StartPetsChanging()
	if rematch:IsVisible() then
		rematch:StartTimer("PetsChanging",0.1,rematch.UpdateWindow) -- UpdateCurrentPets)
	end
end

--[[ Ability flyout ]]--

function rematch:CurrentAbilityOnClick()
	local flyout = RematchAbilityFlyout
	local petSlot = self:GetParent():GetID()
	local abilitySlot = self:GetID()
	if flyout.petSlot==petSlot and flyout.abilitySlot==abilitySlot then
		rematch:HideAbilityFlyout()
		self.arrow:Show()
	elseif IsModifiedClick("CHATLINK") then
		local petID = self:GetParent().petID
		local maxHealth,power,speed,_ = 100,0,0
		if type(petID)=="string" then
			_,maxHealth,power,speed = C_PetJournal.GetPetStats(petID)
		end
		ChatEdit_InsertLink(GetBattlePetAbilityHyperlink(self.abilityID,maxHealth,power,speed))
	else
		local petID = self:GetParent().petID
		if petID and petID~=rematch.emptyPetID then
			self.arrow:Hide()
			flyout.petSlot = petSlot
			flyout.abilitySlot = abilitySlot
			flyout:SetParent(self)
			flyout:SetPoint("RIGHT",self,"LEFT")
			flyout.petID = petID
			rematch:FillFlyout(petSlot,abilitySlot)
			flyout.timer = 0
			flyout:Show()
		end
	end
end

function rematch:HideAbilityFlyout()
	flyout.petSlot = nil
	flyout.abilitySlot = nil
	flyout:Hide()
end

function rematch:FlyoutOnUpdate(elapsed)
	self.timer = self.timer + elapsed
	if self.timer > .75 then
		rematch:HideAbilityFlyout()
	elseif MouseIsOver(flyout) or MouseIsOver(flyout:GetParent()) then
		self.timer = 0 -- restart timer if mouse is over flyout/parent ability
	end
end

function rematch:FillFlyout(petSlot,abilitySlot)
	local petID = C_PetJournal.GetPetLoadOutInfo(petSlot)
	local speciesID,_,level = C_PetJournal.GetPetInfoByPetID(petID)
	C_PetJournal.GetPetAbilityList(speciesID,rematch.abilityList,rematch.levelList)

	for i=1,2 do
		local button = flyout.ability[i]
		local listIndex = (i-1)*3+abilitySlot
		local abilityID = rematch.abilityList[listIndex]

		local _,icon = C_PetJournal.GetPetAbilityInfo(abilityID)
		button.abilityID = rematch.abilityList[listIndex]
		button.icon:SetTexture(icon)
		if level>=rematch.levelList[listIndex] then
			button.level:Hide()
			button.icon:SetVertexColor(1,1,1)
			button.icon:SetDesaturated(false)
			button.canUse = true
		else
			button.level:SetText(rematch.levelList[listIndex])
			button.level:Show()
			button.icon:SetVertexColor(.3,.3,.3)
			button.icon:SetDesaturated(true)
			button.canUse = nil
		end
	end
end

function rematch:FlyoutButtonOnClick()
	if self.canUse then
		local parent = self:GetParent()
		C_PetJournal.SetAbility(parent.petSlot,parent.abilitySlot,self.abilityID)
		rematch:HideAbilityFlyout()
		if PetJournal then
			PetJournal_UpdatePetLoadOut() -- update petjournal if it's open
		end
	end
end
