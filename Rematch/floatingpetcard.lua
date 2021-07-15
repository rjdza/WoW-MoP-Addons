
-- todo: convert ability buttons to a parentArray

local rematch = Rematch
local card = RematchFloatingPetCard

-- desturates floating pet cards that are not owned
local function SetCardDesaturate(desat)
	card.leftAbilitiesBG:SetDesaturated(desat)
	card.rightAbilitiesBG:SetDesaturated(desat)
	card.leftTitleBG:SetDesaturated(desat)
	card.rightTitleBG:SetDesaturated(desat)
	card.lineAbilitiesBG:SetDesaturated(desat)
	card.lineTitleBG:SetDesaturated(desat)
	if desat then
		card.back:SetBackdropBorderColor(.75,.75,.75)
		card:SetBackdropBorderColor(.75,.75,.75)
	else
		card.back:SetBackdropBorderColor(1,.82,0)
		card:SetBackdropBorderColor(1,.82,0)
	end
end

rematch.vulnerabilities = {{4,5},{1,3},{6,8},{5,2},{8,7},{2,9},{9,10},{10,1},{3,4},{7,6}}

function rematch:ShowFloatingPetCard(petID,anchorPoint,relativeTo,relativePoint,xoff,yoff)

	if (card.petID and card.petID==petID) or not petID or petID==rematch.emptyPetID or card.locked then
		return -- already displaying this card or it's a nil/empty petID
	end

	-- only petID,parent were passed as parameters, decide our own anchor depending which half of screen
	if type(anchorPoint)=="table" and not relativeTo then
		rematch:SmartAnchor(card,anchorPoint) -- anchorPoint is actually relativeTo
	else
		card:ClearAllPoints()
		card:SetPoint(anchorPoint,relativeTo,relativePoint,xoff,yoff)
	end

	card.back:SetShown(IsAltKeyDown())

	local speciesID,icon,customName,realName,level,xp,maxXp,displayID,isFavorite,icon,petType,sourceText,description,canBattle,creatureID

	if type(petID)=="string" then
		speciesID,customName,level,xp,maxXp,displayID,isFavorite,realName,icon,petType,creatureID,sourceText,description,_,canBattle = C_PetJournal.GetPetInfoByPetID(petID)
	elseif type(petID)=="number" and petID~=0 then
		speciesID = petID
		petID = nil
		realName,icon,petType,creatureID,sourceText,description,_,canBattle = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
	else
		return
	end

	card.petID = petID or speciesID

	card.back.source:SetText(sourceText)
	card.back.description:SetText(description)

	local model = card.model
	if displayID and displayID~=0 then
		if ( displayID ~= model.displayID ) then
			model.creatureID = nil
			model.displayID = displayID
			model:SetDisplayInfo(displayID)
			model:SetDoBlend(false)
		end
	elseif creatureID and creatureID~=0 then
		if ( creatureID ~= model.creatureID ) then
			model.creatureID = creatureID;
			model.displayID = nil;
			model:SetCreature(creatureID);
			model:SetDoBlend(false);
		end
	end
	model:SetAnimation(0)

	SetPortraitToTexture(card.icon.icon,icon)
	card.petType.icon:SetTexture("Interface\\PetBattles\\PetIcon-"..PET_TYPE_SUFFIX[petType])
	card.name:SetText(customName or realName)

	if customName then
		card.realName:SetText(realName)
		card.realName:Show()
	else
		card.realName:Hide()
	end

	if speciesID and canBattle then
		C_PetJournal.GetPetAbilityList(speciesID,rematch.abilityList,rematch.levelList)
		for i=1,#rematch.abilityList do
			local _,name, icon, _, _, _, petType, noHints = C_PetBattles.GetAbilityInfoByID(rematch.abilityList[i])
			local index = tostring(i)
			card.abilities[index].type:SetTexture("Interface\\PetBattles\\PetIcon-"..PET_TYPE_SUFFIX[petType])
			card.abilities[index].name:SetText(name)
			card.abilities[index].abilityID = rematch.abilityList[i]
		end
		card.cantbattle:Hide()
		card.abilities:Show()
		if petID then -- this is a pet we own with actual stats

			SetCardDesaturate(false)
			card.stats.level:SetText(level)

			local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)
			if health==0 then
				card.stats.hpBar:Hide()
				card.stats.health:SetText("Dead")
				model:SetAnimation(1) -- death animation
			else
				card.stats.hpBar:SetWidth(48*(health/maxHealth))
				card.stats.hpBar:Show()
				card.stats.health:SetText(maxHealth)
			end
			card.stats.power:SetText(power)
			card.stats.speed:SetText(speed)

			local color = ITEM_QUALITY_COLORS[rarity-1]
			card.stats.quality:SetText(_G["BATTLE_PET_BREED_QUALITY"..rarity])
			card.stats.quality:SetVertexColor(color.r,color.g,color.b)

			if rematch.breedable then
				local breed = GetBreedID_Journal(petID) or ""
				card.stats.breed:SetText(GetBreedID_Journal(petID) or "")
				card.stats.breed:Show()
				card.stats.breedIcon:Show()
			end

			if level<25 then
				card.stats.xpBar:SetMinMaxValues(0,maxXp)
				card.stats.xpBar:SetValue(xp)
				card.stats.xpBar.rankText:SetFormattedText(PET_BATTLE_CURRENT_XP_FORMAT_BOTH, xp, maxXp, xp/maxXp*100);
				card.stats.xpBar:Show()
				card.stats.pennant:SetVertexColor(1,1,1)
			else
				card.stats.xpBar:Hide()
				card.stats.pennant:SetVertexColor(1,.82,0)
			end

			card.stats:Show()
		else -- this is not a pet we own, hide stats
			SetCardDesaturate(true)
			card.stats:Hide()
		end
		-- set vulnerabilities
		card.back.strongType:SetTexture("Interface\\PetBattles\\PetIcon-"..PET_TYPE_SUFFIX[rematch.vulnerabilities[petType][1]])
		card.back.weakType:SetTexture("Interface\\PetBattles\\PetIcon-"..PET_TYPE_SUFFIX[rematch.vulnerabilities[petType][2]])

	else -- this pet can't battle
		if petID then
			SetCardDesaturate(false)
		else
			SetCardDesaturate(true)
		end
		card.abilities:Hide()
		card.stats:Hide()
		card.cantbattle:Show()
	end
	card:Show()
end

function rematch:HideFloatingPetCard(force)
	if not card.locked or force then
		card:Hide()
	end
end

function rematch:FloatingPetCardOnShow()
	self:RegisterEvent("MODIFIER_STATE_CHANGED")
end

function rematch:FloatingPetCardOnHide()
	card.petID = nil
	card.locked = nil
	self.lockFrame:Hide()
	self:UnregisterEvent("MODIFIER_STATE_CHANGED")
end

function rematch:LockFloatingPetCard()
	card.locked = not card.locked
	card.lockFrame:SetShown(card.locked)
end

function rematch:FloatingPetCardAbilityOnEnter()
	self.name:SetTextColor(1,1,1)
	rematch.AbilityOnEnter(self,card.petID)
end

function rematch:FloatingPetCardAbilityOnLeave()
	self.name:SetTextColor(1,.82,.5)
	rematch:AbilityOnLeave()
end

--[[ breed support

	Breed support is provided by Battle Pet Breed ID by Simca:
	http://www.curse.com/addons/wow/battle_pet_breedid

]]

rematch.breedNames = {nil,nil,"B/B","P/P","S/S","H/H","H/P","P/S","H/S","P/B","S/B","H/B"}

function rematch:GetBreedName(breed)
	if BPBID_Options.format==1 then
		return breed
	elseif BPBID_Options.format==2 then
		return format("%d/%d",breed,breed+10)
	elseif rematch.breedNames[breed] then
		return rematch.breedNames[breed]
	else
		return "ERR"
	end
end

-- populates card.main.breedTable with all possible breeds and stats for the card's species
function rematch:ShowBreedTable()

	local speciesID = type(card.petID)=="string" and C_PetJournal.GetPetInfoByPetID(card.petID) or card.petID
	local currentBreed = card.stats.breed:IsVisible() and card.stats.breed:GetText()

	if not rematch.breedable or not speciesID or not select(8,C_PetJournal.GetPetInfoBySpeciesID(speciesID)) then
		return -- leave if BPBID not loaded, invalid species or pet can't battle
	end
	if not BPBID_Arrays.BreedsPerSpecies then
		BPBID_Arrays.InitializeArrays()
	end

	card.main.blackout:SetAlpha(1) -- darken main area so table stands out

	local data = BPBID_Arrays
	local row = card.main.breedTable.row

	for i=1,10 do
		row[i]:Hide()
	end
	card.main.breedTable.highlight:Hide()

	local numBreeds
	if data.BreedsPerSpecies[speciesID] then
		numBreeds = #data.BreedsPerSpecies[speciesID]
		for i=1,numBreeds do
			local breed = data.BreedsPerSpecies[speciesID][i]
			row[i]:Show()
			local breedText = rematch:GetBreedName(breed)
			row[i].breed:SetText(breedText)
			if breedText==currentBreed then
				card.main.breedTable.highlight:SetPoint("BOTTOMLEFT",row[i],"BOTTOMLEFT")
				card.main.breedTable.highlight:Show()
			end
			row[i].health:SetText(ceil((data.BasePetStats[speciesID][1] + data.BreedStats[breed][1]) * 25 * ((data.RealRarityValues[4] - 0.5) * 2 + 1) * 5 + 100 - 0.5))
			row[i].power:SetText(ceil((data.BasePetStats[speciesID][2] + data.BreedStats[breed][2]) * 25 * ((data.RealRarityValues[4] - 0.5) * 2 + 1) - 0.5))
			row[i].speed:SetText(ceil((data.BasePetStats[speciesID][3] + data.BreedStats[breed][3]) * 25 * ((data.RealRarityValues[4] - 0.5) * 2 + 1) - 0.5))
		end
	end
	if not numBreeds or numBreeds==0 then
		card.main.breedTable.title:SetText("No breeds known :(")
		card.main.breedTable:SetHeight(44)
	else
		card.main.breedTable.title:SetText("\124cffddddddPossible level 25 \124cff0070ddRares")
		card.main.breedTable:SetHeight(44+numBreeds*14)
	end
	card.main.breedTable:Show()
end

function rematch:HideBreedTable()
	card.main.blackout:SetAlpha(0)
	card.main.breedTable:Hide()
end