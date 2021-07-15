--[[ Roster

	This module handles the list of pets that will be displayed in the browser.

	The actual displaying is handled in browser.lua/xml.  This just populates a list of pets
	based on filters and flags.

	The UI's live collected/type/source filters are allowed to apply normally and "first".
	If strong vs or tough vs filter is enabled, pet type filter is cleared to let all types through.
	The UI's search filter is not allowed to be applied (search is cleared when pets gathered).
	Our own search filter looks for text from what's left above (abilities too).
	Then a post-search filter discards types for strong vs and tough vs if we're in the mode.
	Some breed caching is also done here if addon Battle Pet Breed ID enabled.

	These functions are exposed to the main module:

		GetNumPets() -- returns total number of pets
		GetPetByIndex(index) -- returns petID of owned pet or speciesID of missing pet
		Update() -- updates roster with internal PET_JOURNAL_LIST_UPDATE force flag

		SetSearch(text) -- filters list with pets that contain text in name, source or abilities
		SetTypeMode(mode) -- set type mode to 1-pet type 2-strong vs 3-tough vs
		GetTypeMode() -- returns current type mode
		SetTypeFilter(index,value,mode) -- sets type index to value within mode
		GetTypeFilter(index) -- returns the current value of type index
		ClearTypeFilters()
		IsTypeFiltersClear() -- whether typeFilters is empty (all types should be visible)

]]

local rematch = Rematch
rematch.roster = {}
local roster = rematch.roster

roster.toughTable = {8,4,2,9,1,10,5,3,6,7} -- types that indexed types are tough vs
roster.strongTable = {4,1,6,5,8,2,9,10,3,7} -- types that indexed types are strong vs

roster.pets = {} -- table of pet indexes, created in GenerateIndexes, owned or missing, regardless of filters
roster.breeds = {} -- BattlePetBreedID creates insane garbage churn, cache a table of pet breeds
roster.abilityList = rematch.abilityList -- reusable table for C_PetJournal.GetAbilityList
roster.levelList = rematch.levelList -- passed to C_PetJournal.GetAbilityList (prevents a ton of garbage creation)
roster.typeMode = 1 -- initial type filter set to pet type
roster.typeFilters = {} -- shared filter for pet type/strong vs/tough vs; indexed numerically like default
roster.rarityFilters = {} -- 1-4 poor-rare filter
roster.currentZoneFilter = nil -- whether to filter to pets in the current zone
roster.favoriteFilter = nil -- whether to filter favorites (not going to use default)

-- returns number of pets in roster
function roster:GetNumPets()
	return #roster.pets
end

-- returns a petID/speciesID by roster index
function roster:GetPetByIndex(index)
	return roster.pets[index]
end

function roster:GetPetNameByIndex(index)
	local customName,realName,_
	local petID = roster.pets[index]
	if type(petID)=="string" then
		_,customName,_,_,_,_,_,realName = C_PetJournal.GetPetInfoByPetID(roster.pets[index])
	elseif type(petID)=="number" then
		realName = C_PetJournal.GetPetInfoBySpeciesID(petID)
	end
	return customName or realName
end

-- this populates roster.pets with petIDs or speciesIDs depending on current filters
-- note it does not (and should never) do anything to trigger a PET_JOURNAL_LIST_UPDATE
function roster:Update()
	wipe(roster.pets)
	for i=1,C_PetJournal.GetNumPets() do
		local candidate = roster:FilterPetByIndex(i,not roster:IsTypeFiltersClear(),not roster:IsRarityFiltersClear(),roster:GetCurrentZoneFilter() and GetRealZoneText())
		if candidate then
			tinsert(roster.pets,candidate)
		end
	end
end

--[[ Search box ]]

function roster:SetSearch(text)
	if roster.searchText==text then
		return
	end

	roster.searchText = nil
	roster.searchMinLevel = nil
	roster.searchMaxLevel = nil

	if not text or text=="" or text==SEARCH then
		-- keep everything nil
	else
		local minLevel,maxLevel = roster:TestSearchForLevelRange(text)
		if minLevel then
			roster.searchMinLevel = minLevel
			roster.searchMaxLevel = maxLevel
		else
			roster.searchText = text
			-- searchMask is a literal/case-insensitive pattern ("Xu-Fu" becomes "[xX][uU]%-[fF][uU]")
			roster.searchMask = roster.searchText:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]",function(c) return "%"..c end):gsub("%a",function(c) return format("[%s%s]",c:lower(),c:upper()) end)
		end
	end
end

-- returns min,max levels if one can be determined from passed text
-- <level <=level >level >=level =level level-level are valid returns
function roster:TestSearchForLevelRange(text)
	local minLevel,maxLevel
	maxLevel = text:match("^<(%d+)")
	if maxLevel then return 0,tonumber(maxLevel)-1 end
	minLevel = text:match("^>(%d+)")
	if minLevel then return tonumber(minLevel)+1,25 end
	minLevel = text:match("^=(%d+)")
	if minLevel then return tonumber(minLevel),tonumber(minLevel) end
	minLevel,maxLevel = text:match("^(%d+)%-(%d+)")
	if minLevel then return tonumber(minLevel),tonumber(maxLevel) end -- "level-level"
	maxLevel = text:match("^<=(%d+)")
	if maxLevel then return 0,tonumber(maxLevel) end
	minLevel = text:match("^>=(%d+)")
	if minLevel then return tonumber(minLevel),25 end
end


--[[ TypeMode 1=standard type filter, 2=strong vs filter, 3=tough vs filter ]]

function roster:GetTypeMode()
	return roster.typeMode
end

function roster:SetTypeMode(mode)
	if mode~=roster.typeMode then
		roster:ClearTypeFilters(true)
		roster.typeMode = mode
		return true
	end
end

--[[ Type Filter ]]

function roster:SetTypeFilter(index,value)
	roster.typeFilters[index] = value or nil
	roster:AssertTypeFilters()
end

function roster:GetTypeFilter(index)
	return roster.typeFilters[index]
end

function roster:IsTypeFiltersClear()
	return not next(roster.typeFilters)
end

-- to prevent triggering an unnecessary PET_JOURNAL_LIST_UPDATE, add all pet types only if needed
function roster:ClearTypeFilters(force)
	if force then
		wipe(roster.typeFilters)
	end
	for i=1,C_PetJournal.GetNumPetTypes() do
	  if C_PetJournal.IsPetTypeFiltered(i) then -- IsPetTypeFiltered returns true if it's unchecked
			C_PetJournal.AddAllPetTypesFilter() -- if anything unchecked, check them all
			break
	  end
	end
end

-- this function makes the live type filters match roster.typeFilters
function roster:AssertTypeFilters()
	if roster.typeMode>1 or not next(roster.typeFilters) then
		roster:ClearTypeFilters()
	else
		for i=1,C_PetJournal.GetNumPetTypes() do
			C_PetJournal.SetPetTypeFilter(i,roster.typeFilters[i])
		end
	end
end

--[[ Rarity Filter ]]

function roster:SetRarityFilter(rarity,value)
	if not value then value = nil end
	roster.rarityFilters[rarity] = value
end

function roster:GetRarityFilter(rarity)
	return roster.rarityFilters[rarity]
end

function roster:IsRarityFiltersClear()
	return not next(roster.rarityFilters)
end

function roster:ClearRarityFilters()
	wipe(roster.rarityFilters)
end

--[[ Current Zone Filter ]]

function roster:SetCurrentZoneFilter(value)
	roster.currentZoneFilter = value
end

function roster:GetCurrentZoneFilter()
	return roster.currentZoneFilter
end

--[[ Favorite Filter ]]

function roster:SetFavoriteFilter(value)
	roster.favoriteFilter = value
end

function roster:GetFavoriteFilter()
	return roster.favoriteFilter
end

--[[ Filtering ]]

-- returns true if the speciesID has a petType we want to show
-- note that roster.abilityList should be populated before calling this
function roster:FilterPetType(speciesID,petType)

	if roster.typeMode==3 then -- tough vs
		for typeIndex in pairs(roster.typeFilters) do
			if roster.toughTable[typeIndex] == petType then
				return true
			end
		end
	elseif roster.typeMode==2 then -- strong vs
		for i=1,#roster.abilityList do
			local abilityType, noHints = select(7,C_PetBattles.GetAbilityInfoByID(roster.abilityList[i]))
			if not noHints then
				for typeIndex in pairs(roster.typeFilters) do
					if roster.strongTable[typeIndex] == abilityType then
						return true
					end
				end
			end
		end
	elseif roster.typeMode==1 then -- normal type
		return true -- we use all filtered pets for normal
	end

	return false
end

-- returns true if one of the passed parameters has a hit with the searchMask
-- it will also search abilities populated in roster.abilityList
function roster:FilterSearchText(...)

	for i=1,select("#",...) do
		local text = select(i,...)
		if text and text:match(roster.searchMask) then
			return true
		end
	end

	for i=1,#roster.abilityList do
		local _,name,_,_,description = C_PetBattles.GetAbilityInfoByID(roster.abilityList[i])
		if name:match(roster.searchMask) or description:match(roster.searchMask) then
			return true
		end
	end

end

-- returns the petID or speciesID if pet journal index should be listed in browser
-- if checkType is true, a test for type is also applied
-- if searchText is true, a test for searchMask is also applied
function roster:FilterPetByIndex(index,checkType,checkRarity,currentZone)

	local	petID, speciesID, owned, customName, level, favorite, _, speciesName, _, petType, _, source, description, isWild, canBattle, isTradeable, _, obtainable = C_PetJournal.GetPetInfoByIndex(index)
	C_PetJournal.GetPetAbilityList(speciesID, roster.abilityList, roster.levelList)

	if roster:GetFavoriteFilter() and not favorite then
		return false
	end

	if currentZone then
		if not source or not source:match(currentZone) then
			return false
		end
	end

	-- check rarity if flag set
	if checkRarity then
		if petID then
			local _, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)
			if not roster:GetRarityFilter(rarity) then
				return false
			end
		else
			return false
		end
	end

	-- check type if flag set
	if checkType then
		if not roster:FilterPetType(speciesID,petType) then
			return false
		end
	end

	-- if there's a min,max level (search string is <25 or =25 or 11-17 or >5 etc)
	if roster.searchMinLevel then
		if level<roster.searchMinLevel or level>roster.searchMaxLevel then
			return false
		end
	end

	-- if there's a legitimate text search string
	if roster.searchText then
		if not roster:FilterSearchText(customName,speciesName,source) then
			return false
		end
	end

	return petID or speciesID
end


--[[ filterResults ]]

function roster:GetFilterResults()
	local filters = "Filters: \124cffffffff"

	if roster.searchText then
		filters = filters.."Search, "
	end
	if roster.searchMinLevel then
		filters = filters.."Level, "
	end
	if not roster:IsTypeFiltersClear() then
		filters = filters..(roster.typeMode==1 and "Pet Type, " or roster.typeMode==2 and "Strong, " or "Tough, ")
	end
	for i=1,C_PetJournal.GetNumPetSources() do
		if C_PetJournal.IsPetSourceFiltered(i) then
			filters = filters.."Sources, "
			break
		end
	end
	if not roster:IsRarityFiltersClear() then
		filters = filters.."Rarity, "
	end
	if C_PetJournal.IsFlagFiltered(LE_PET_JOURNAL_FLAG_COLLECTED) or C_PetJournal.IsFlagFiltered(LE_PET_JOURNAL_FLAG_NOT_COLLECTED) then
		filters = filters.."Collected, "
	end
	if roster:GetFavoriteFilter() then
		filters = filters.."Favorites, "
	end
	if roster:GetCurrentZoneFilter() then
		filters = filters.."Zone, "
	end

	filters = filters:gsub(", $","")

	return (filters~="Filters: \124cffffffff") and filters
end

function roster:ClearAllFilters()
	roster:SetTypeMode(1)
	roster:ClearTypeFilters(true)
	roster:ClearRarityFilters()
	roster:SetSearch("")
	roster:SetCurrentZoneFilter(nil)
	roster:SetFavoriteFilter(nil)
	C_PetJournal.AddAllPetSourcesFilter()
	C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_COLLECTED,true)
	C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_NOT_COLLECTED,true)
	C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_FAVORITES,false)
end