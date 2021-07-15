
local rematch = Rematch
local savedTeams, settings

function rematch:InitializeSaved()
	rematch.saved.header.text:SetText("Saved for <no target>")
	rematch.saveAs.header.text:SetText("Save Team As...")
	-- remove highlight texture from saved pets to make it look less likely to accept dragged pets
	for i=1,3 do
		rematch.saved.pet[i]:SetHighlightTexture(nil)
		for j=1,3 do
			rematch.saved.pet[i].ability[j]:SetHighlightTexture(nil)
		end
	end
	savedTeams = RematchSaved
	settings = RematchSettings
end

function rematch:RematchSaveButton()
	if rematch.selectedTeam then -- saved team already selected
		local npcID
		if rematch.targetedName==rematch.selectedTeam then -- selected team is named same as our target
			npcID = rematch.targetedNpcID -- use current target's NPC ID
		else
			npcID = savedTeams[rematch.selectedTeam][4] -- otherwise use one already saved with team
		end
		rematch:SaveCurrentTeam(rematch.selectedTeam,npcID)
	else -- saved team not already selected
		if rematch.targetedNpcID then -- an NPC is targeted, use their name for team name
			rematch:SaveCurrentTeam(rematch.targetedName,rematch.targetedNpcID)
		else
			rematch.saveAs:Show() -- otherwise ask for team name
		end
	end
end

function rematch:RematchSaveAsCloseButton()
	rematch.saveAs:Hide()
end

function rematch:RematchSaveAsSaveButton()
	rematch:SaveAsSave()
end

--[[ Saved Pets ]]

-- attack types (index) are {strong vs type,weak vs type}
-- ie flying(3rd) is strong vs aquatic(9), weak vs dragonkin(2)
rematch.attackHints = { {2,8},{6,4},{9,2},{1,9},{4,1},{3,10},{10,5},{5,3},{7,6},{8,7} }
rematch.attackTypes = {} -- reusable table for attack types for hint frame

function rematch:UpdateSavedPets()
	rematch:WipePetFrames(rematch.saved.pet)
	for i=1,6 do
		rematch.saved.hints.icon[i]:Hide() -- clear hints too
	end
	if rematch.selectedTeam and savedTeams[rematch.selectedTeam] then
		self:FillPetFramesFromTeam(rematch.saved.pet,savedTeams[rematch.selectedTeam])
		for i=1,3 do
			local petID = rematch.saved.pet[i].petID
			if type(petID)=="string" and petID~=rematch.emptyPetID then
				if C_PetJournal.GetPetStats(petID)==0 then
					rematch.saved.pet[i].dead:Show()
				end
			end
		end

		local actualName = rematch.selectedTeam=="~temp~" and rematch.tempTeamName or rematch.selectedTeam
		if savedTeams[rematch.selectedTeam][4] then
			rematch.saved.header.text:SetText(format("Saved for \124cffffffff%s",actualName))
		else
			rematch.saved.header.text:SetText(format("Saved as \"%s\"",actualName))
		end
		rematch:UpdateHints()
	else
		rematch.saved.header.text:SetText("Saved Battle Pets")
	end
end

function rematch:UpdateHints()
	local attacks = rematch.attackTypes
	for i=1,10 do
		attacks[i] = 0 -- set all type counters to 0
	end
	local team = savedTeams[rematch.selectedTeam]
	if team then
		for i=1,3 do
			local petID = team[i][1]
			if petID and petID~=0 then -- don't count leveling pets
				for j=1,3 do
					if team[i][j+1] then
						local abilityType, noHints = select(7,C_PetBattles.GetAbilityInfoByID(team[i][j+1]))
						if abilityType and not noHints then -- if ability is an attack, increment its counter
							attacks[abilityType] = attacks[abilityType]+1
						end
					end
				end
			end
		end
		-- go through the attackTypes table gathered above and multiply values by 100,
		-- add their index, then reverse sort.
		-- ie 4x flying is 403, 1x mechanical is 110.
		for i=1,10 do
			attacks[i] = attacks[i]*100+i
		end
		table.sort(attacks,function(e1,e2) return e1>e2 end)
		-- now the most common attacks are at the top. the value%100 will be the attack type
		for i=1,10 do
			attacks[i] = attacks[i]>99 and attacks[i]%100 or nil
		end
		rematch.saved.hints.icon[1]:SetShown(#attacks>0)
		rematch.saved.hints.icon[4]:SetShown(#attacks>0)
		if #attacks > 0 then
			for i=1,2 do -- only care about first 2
				if attacks[i] then
					rematch.saved.hints.icon[i+1]:SetTexture("Interface\\PetBattles\\PetIcon-"..PET_TYPE_SUFFIX[rematch.attackHints[attacks[i]][1]])
					rematch.saved.hints.icon[i+4]:SetTexture("Interface\\PetBattles\\PetIcon-"..PET_TYPE_SUFFIX[rematch.attackHints[attacks[i]][2]])
					rematch.saved.hints.icon[i+1]:Show()
					rematch.saved.hints.icon[i+4]:Show()
				end
			end
		end
	end
end

--[[ SaveAs frame ]]--

function rematch:SaveAsOnShow()
	rematch.saveAs.editBoxFrame.editBox:SetText("")
	rematch:SaveAsEditBoxChanged()
	if rematch.drawer:IsVisible() then
		rematch.saveAs.drawerWasOpen = 1
		rematch.drawer:Hide()
	end
	rematch.saved.header:Hide()
	rematch.saveAs.editBoxFrame.editBox:SetFocus()
	rematch:SetSelectedTeam("~temp~")
end

function rematch:SaveAsOnHide()
	if rematch.saveAs.drawerWasOpen then
		rematch.saveAs.drawerWasOpen = nil
		rematch.drawer:Show()
	end
	rematch.saved.header:Show()
	if rematch.selectedTeam=="~temp~" then
		rematch:ClearSelected()
		rematch:UpdateWindow()
	end
end

function rematch:SaveAsSave()
	if rematch.saveAs.saveButton:IsEnabled() then
		rematch.saveAs:Hide()
		rematch:SaveCurrentTeam(rematch.saveAs.editBoxFrame.editBox:GetText())
	end
end

function rematch:SaveAsEditBoxChanged()
	local txt=rematch.saveAs.editBoxFrame.editBox:GetText()
	local exists = savedTeams[txt]
	rematch.saveAs.warning:SetShown(exists)
	rematch.saveAs.warningIcon:SetShown(exists)
	rematch.saveAs.saveButton:SetEnabled(txt:len()>0 and txt~="~temp~")
end

function rematch:SaveCurrentTeam(teamName,npcID)
	local incoming = savedTeams["~temp~"]
	wipe(incoming)
	for i=1,3 do
		local petID,ability1,ability2,ability3 = C_PetJournal.GetPetLoadOutInfo(i)
		if rematch:IsCurrentLevelingPet(petID) then
			tinsert(incoming,{0,0,0,0}) -- this is a leveling pet, save it as 0s
		else
			tinsert(incoming,{petID,ability1,ability2,ability3})
		end
	end
	if npcID then
		tinsert(incoming,npcID)
	end
	if rematch:SaveTeam(teamName,incoming) then
		rematch.saveAs:Hide()
	end
end

-- returns true if the teams are similar (same species in every slot), to determine whether to confirm a save
function rematch:TeamsAreSimilar(team1,team2)
	for i=1,3 do
		if team1[i][1]~=team2[i][1] then
			if team1[i][1]==0 or team2[i][1]==0 or not team1[i][1] or not team2[i][1] or type(team1[i][1])=="number" or type(team2[i][1])=="number" then
				return false
			end
			local speciesID1 = C_PetJournal.GetPetInfoByPetID(team1[i][1])
			local speciesID2 = C_PetJournal.GetPetInfoByPetID(team2[i][1])
			if speciesID1 ~= speciesID2 then
				return false
			end
		end
	end
	return true
end

-- instead of disparate ways teams are saved (main save, import save, receive save), all team saves go through here
-- returns true if save happened immediately
function rematch:SaveTeam(teamName,teamTable)
	local confirm = RematchConfirm
	confirm.teamName = teamName
	confirm.teamTable = teamTable
	if not settings.AutoConfirm and savedTeams[teamName] and not rematch:TeamsAreSimilar(savedTeams[teamName],teamTable) then
		rematch:ConfirmSave(teamName,savedTeams[teamName],teamTable)
	else
		rematch:SaveConfirmed()
		return true
	end
end

-- the final save: create a team named incomingTeamName with the contents of incomingTeamTable
function rematch:SaveConfirmed()
	local confirm = RematchConfirm
	savedTeams[confirm.teamName] = {}
	local source = confirm.teamTable
	local dest = savedTeams[confirm.teamName]
	-- copy team from source to destination
	for i=1,#source do
		if type(source[i])=="table" then
			dest[i] = {}
			for j=1,#source[i] do
				dest[i][j] = source[i][j]
			end
		else
			dest[i] = source[i]
		end
	end
	rematch:ValidateTeam(dest)
	rematch:SetSelectedTeam(confirm.teamName)
	rematch:UpdateSavedPets()
	for i=1,3 do
		rematch.saved.pet[i].shine:SetCooldown(0,1) -- do shiny cooldown ending bit
	end
	if rematch.drawer:IsVisible() then
		rematch:OrderTeamList()
		rematch:UpdateTeamList()
		rematch:ScrollToSelectedTeam()
	end
end
