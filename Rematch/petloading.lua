
local rematch = Rematch
local settings, savedTeams

rematch.petsToLoad = {{},{},{}} -- used in loading process, the actual pets/abilities expected at the end of a load
rematch.currentLoadOut = {{},{},{}} -- used in loading process, the current loadout pets/abilities
rematch.loadCandidates = {} -- list of petID candidates that may form the final load

function rematch:InitializePetLoading()
	settings = RematchSettings
	savedTeams = RematchSaved
end

function rematch:RematchLoadButton()
	local team = rematch.selectedTeam
	if team and savedTeams[team] then
		rematch:LoadPets(team)
	end
end

-- two elements (petID or ability) are the same if they both exist, are the same or one of them is 0(ignore)
local function same(e1,e2)
	if not e1 or not e2 then
		return false
	elseif e1==e2 or e1==0 or e2==0 then
		return true
	end
end

-- returns true if the currently loaded pets are what was last loaded
function rematch:IsLastTeamLoaded()
	if savedTeams[settings.LastTeamNameLoaded] then
		local team = settings.LastTeamTableLoaded
		for i=1,3 do
			local petID,ability1,ability2,ability3 = C_PetJournal.GetPetLoadOutInfo(i)
			if not same(petID,team[i][1]) or not same(ability1,team[i][2]) or not same(ability2,team[i][3]) or not same(ability3,team[i][4]) then
				return false
			end
		end
		return true
	end
end

function rematch:PetsNeedLoading(teamName)
	local team = savedTeams[teamName]
	if not team then
		return
	end
	local levelingPetID = rematch:GetLevelingPetID()
	local curAbility = rematch.info
	local curPetID, validPetID, teamPetID, teamAbilityID
	for i=1,3 do
		curPetID,curAbility[1],curAbility[2],curAbility[3] = C_PetJournal.GetPetLoadOutInfo(i)
		teamPetID = team[i][1]
		if teamPetID==rematch.emptyPetID then -- if we want an empty slot
			if curPetID then
				return true -- loaded needed if slot is occupied
			end
		elseif teamPetID==0 then -- if we want a leveling pet
			if levelingPetID and curPetID~=levelingPetID then
				return true -- there's a leveling pet, and one is not in this slot, load needed
			end
		elseif type(teamPetID)=="string" and C_PetJournal.GetPetInfoByPetID(teamPetID) then -- if we want a valid petID
			if curPetID~=teamPetID then
				return true -- the loaded pet is different than incoming pet, load needed
			end
			for j=1,3 do
				teamAbilityID = team[i][j+1]
				if teamAbilityID and teamAbilityID~=0 and teamAbilityID~=curAbility[j] then
					return true -- an ability is different, load needed
				end
			end
		end
	end
	return false -- if we made it this far, team doesn't need loaded
end

-- new LoadPets routine: go through the team and apply pets and abilities directly, letting
-- the game rearrange duplicates and such. after each SetLoadOutInfo or SetAbility, verify
-- the change happened and if not set up a reload attempt and abort.
function rematch:LoadPets(teamName)
	local team = savedTeams[teamName]
	if not team then
		return
	end
	rematch:SummonedPetMayChange()

	local levelingPetID = rematch:GetLevelingPetID()
	local teamPetID
	local loadout = rematch.info

	for i=1,3 do
		teamPetID = team[i][1]

		if settings.KeepLeveling and levelingPetID and C_PetJournal.GetPetLoadOutInfo(i)==levelingPetID then
			-- do nothing when KeepLeveling enabled and the pet is a leveling pet

		elseif teamPetID==rematch.emptyPetID then
			-- load empty slot
			if C_PetJournal.GetPetLoadOutInfo(i) then
				C_PetJournal.SetPetLoadOutInfo(i,rematch.emptyPetID)
				if C_PetJournal.GetPetLoadOutInfo(i) then
					rematch:SetupReload(teamName,i)
					return
				end
			end

		elseif teamPetID==0 and levelingPetID then
			-- load leveling pet
			if C_PetJournal.GetPetLoadOutInfo(i)~=levelingPetID then
				C_PetJournal.SetPetLoadOutInfo(i,levelingPetID)
				if C_PetJournal.GetPetLoadOutInfo(i)~=levelingPetID then
					rematch:SetupReload(teamName,i)
					return
				end
			end

		elseif type(teamPetID)=="string" and C_PetJournal.GetPetInfoByPetID(teamPetID) and not C_PetJournal.PetIsRevoked(teamPetID) then -- valid petID
			-- load valid petID and its abilities
			loadout[1],loadout[2],loadout[3],loadout[4] = C_PetJournal.GetPetLoadOutInfo(i)
			if loadout[1]~=teamPetID then
				C_PetJournal.SetPetLoadOutInfo(i,teamPetID)
			end
			for j=2,4 do -- abilities (note we only load abilities for pets with a valid petID)
				if loadout[j]~=team[i][j] then
					C_PetJournal.SetAbility(i,j-1,team[i][j])
				end
			end
			-- verify pet+abilities together
			loadout[1],loadout[2],loadout[3],loadout[4] = C_PetJournal.GetPetLoadOutInfo(i)
			for j=1,4 do
				if (j==1 and loadout[j]~=teamPetID) or loadout[j]~=team[i][j] then
					rematch:SetupReload(teamName,i)
					return
				end
			end

		elseif settings.EmptyMissing then
			C_PetJournal.SetPetLoadOutInfo(i,rematch.emptyPetID)
		end
	end

	-- if we made it this far, all pets are loaded!

	-- note team we loaded for LastTeam
	rematch:WipeTeamTable(settings.LastTeamTableLoaded)
	for i=1,3 do
		local s = settings.LastTeamTableLoaded[i]
		s[1],s[2],s[3],s[4] = C_PetJournal.GetPetLoadOutInfo(i)
	end
	settings.LastTeamNameLoaded = teamName

	if rematch:IsVisible() then -- update window if it's shown
		rematch:UpdateCurrentPets()
		for i=1,3 do
			rematch.current.pet[i].icon:SetDesaturated(nil)
			rematch.current.pet[i].icon:SetVertexColor(1,1,1)
			rematch.current.pet[i].shine:SetCooldown(0,1) -- shine the current pets
		end
	end
	if PetJournal then
		PetJournal_UpdatePetLoadOut() -- update petjournal if it's open
	end

	-- if window wasn't already shown, and this AutoShow or AutoLoad going, and window not locked, hide window
	if not rematch.alreadyShown and settings.AutoShow and rematch.selectedTeam and rematch.targetedName==rematch.selectedTeam and not settings.LockWindow then
		rematch:Hide()
	end

	rematch.reloadTeamName = nil

end

-- while not as bad as it used to be, there is still a limit to how many pet swaps can happen over
-- a short period of time. when a team loads it verifies the pets/abilities loaded, and if anything
-- didn't load, a reload is setup to attempt later (0.3 seconds now, can adjust).
function rematch:SetupReload(teamName,slot)
	if slot then
		-- if a slot is the cause of a reload, darken its icon
		rematch.current.pet[slot].icon:SetVertexColor(.5,.5,.5)
		rematch.current.pet[slot].icon:SetDesaturated(1)
	end
	rematch.reloadTeamName = teamName
	rematch:StartTimer("Reload",0.3,rematch.ReloadTeam)
end

function rematch:ReloadTeam()
	if not rematch.reloadTeamName then
		return
	end
	if C_PetBattles.IsInBattle() then -- if a reload attempt is during battle, try after battle is done
		rematch:RegisterEvent("PET_BATTLE_OVER")
		return
	end
	rematch:LoadPets(rematch.reloadTeamName)
end
