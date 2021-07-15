
--[[ this handles the export, import and sending of teams as well as the incoming frame ]]

local rematch = Rematch
local settings, savedTeams

local share = rematch.drawer.share
local shareMultiEdit = share.multiLine.scrollFrame.editBox
local incoming = RematchIncoming

rematch.shareString = "" -- teams are converted to/from a string in this format:
-- Name of team:npcID:S1:A1:A2:A3:S2:A1:A2:A3:S3:A1:A2:A3:
-- S1-3 = species of pet in slot 1 to 3
-- A1-3 = ability loaded in slot 1 of 3
-- A 0 for species means it's a leveling slot
-- A 1 for species means it's an empty slot

-- share mode: 1=export, 2=import, 3=send

function rematch:InitializeShare()
	settings = RematchSettings
	savedTeams = RematchSaved
	RematchShareMultiLineScrollBar:SetAlpha(0)
	RegisterAddonMessagePrefix("Rematch") -- for listening to our own CHAT_MSG_ADDON
	rematch:RegisterEvent("CHAT_MSG_ADDON")
	incoming.header.text:SetText("Incoming Rematch Team")
	incoming.warning:SetText("A team with this name already exists.\nEdit the name or hit Save to overwrite it.")
end

-- export button on drawer panel
function rematch:ExportSelectedTeam()
	rematch:PrepareShare(1)
	rematch:GenerateShareString(rematch.selectedTeam,savedTeams[rematch.selectedTeam])
	rematch:MultiLineOnTextChanged()
	share:Show()
end

-- import button on drawer panel
function rematch:RematchImportButton()
	rematch:ClearSelected()
	rematch:PrepareShare(2)
	shareMultiEdit:SetText("")
	share:Show()
end

function rematch:SendSelectedTeam()
	rematch:PrepareShare(3)
	share.singleLine.editBox:SetText("")
	share:Show()
end

-- ok/cancel button within the share window
function rematch:RematchShareOkButton()
	share:Hide()
end

-- save/send button within the share window
function rematch:RematchShareSaveButton()
	if share.saveButton:IsEnabled() then
		if rematch.shareMode==2 then -- import
			share:Hide()
			if rematch:SaveTeam(rematch.tempTeamName,savedTeams["~temp~"]) then
				rematch:SetSelectedTeam(rematch.tempTeamName)
			end
		elseif rematch.shareMode==3 then -- send
			Rematch:SendOnEnterPressed()
		end
	end
end

function rematch:ShareOnShow()
	rematch.drawer.teams:Hide()
	rematch.drawer.leveling:Hide()
end

function rematch:ShareOnHide()
	rematch.drawer.teams:Show()
	rematch.drawer.leveling:Show()
	rematch.saved.header:Show()
	rematch:SetShareStatus()
	rematch:ClearSelected()
end

-- reconfigures share window for the mode it's going into (1=export, 2=import, 3=send)
function rematch:PrepareShare(mode)
	share.header.text:SetText(mode==1 and "Export" or mode==2 and "Import" or "Send To...")
	share.description:SetHeight(mode==1 and 76 or mode==2 and 70 or 50)
	share.description:SetPoint("TOP",0,mode==3 and -42 or -20)
	share.multiLine:SetShown(mode~=3)
	share.singleLine:SetShown(mode==3)
	share.saveButton:SetShown(mode~=1)
	share.okButton:SetText(mode==1 and OKAY or CANCEL)
	share.saveButton:SetText(mode==2 and SAVE or "Send")
	if mode==1 then
		share.description.text:SetText("The text below describes this team in a format usable by other users. Hit Ctrl+C to copy it to the clipboard. Ctrl+V to paste it into an email, forum or elsewhere.")
	elseif mode==2 then
		share.description.text:SetText("If you have a team copied to the clipboard, paste it here with Ctrl+V. You can review the team above before hitting Enter or clicking Save to save the team.")
	elseif mode==3 then
		share.description.text:SetText("Who would you like to send this team to?")
	end
	rematch.shareMode = mode
	rematch:SetShareStatus()
end

-- displays a message and an icon in the lowerleft corner of share frame and stops waiting for stuff
-- if no message is given, the status/icon is hidden
-- if no icon is given, then the warning icon is used
function rematch:SetShareStatus(message,icon)
	share.statusIcon:SetTexture(icon or "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
	share.statusText:SetText(message or "")
	share.statusIcon:SetShown(message and true or false)
	share.statusText:SetShown(message and true or false)
	rematch:UnregisterEvent("CHAT_MSG_SYSTEM")
	rematch:StopTimer("SendTimeout")
end

-- converts a team into a string and assigns it to rematch.shareString
function rematch:GenerateShareString(teamName,teamTable)
	if teamName:len()>128 then
		teamName = strsub(1,128)
	end
	local info = rematch.info
	wipe(info)
	tinsert(info,teamName)
	tinsert(info,teamTable[4] or 0)
	for i=1,3 do
		local speciesID
		if teamTable[i][1]==rematch.emptyPetID then
			speciesID = 1
		elseif type(teamTable[i][1])=="string" then
			speciesID = C_PetJournal.GetPetInfoByPetID(teamTable[i][1])
		else
			speciesID = teamTable[i][1]
		end
		tinsert(info,speciesID or 0)
		for j=2,4 do
			tinsert(info,teamTable[i][j] or 0)
		end
	end
	rematch.shareString = format("%s:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:",unpack(info))
end

-- parses a shareString (import string or received via CHAT_MSG_ADDON) into teamTable and returns its name
-- if no teamTable given, it only verifies it's formatted correctly and returns its name if valid
function rematch:ParseShareString(shareString,teamTable)
	local name,npcID,theRest = shareString:match("^(.-):(%d+):(%d+:%d+:%d+:%d+:%d+:%d+:%d+:%d+:%d+:%d+:%d+:%d+:)")

	if name and teamTable then -- skipping this if not a good string or only wanted name
		-- wipe existing team table
		rematch:WipeTeamTable(teamTable)

		-- populate it from theRest pulled from string
		local s=teamTable
		s[1][1],s[1][2],s[1][3],s[1][4],s[2][1],s[2][2],s[2][3],s[2][4],s[3][1],s[3][2],s[3][3],s[3][4] = strsplit(":",theRest)
		for i=1,3 do
			for j=1,4 do
				s[i][j] = tonumber(s[i][j])
			end
		end
		for i=1,3 do
			if s[i][1]==1 then
				s[i][1] = rematch.emptyPetID -- convert any speciesIDs of 1 to the emptyPetID
			end
		end
		if npcID~="0" then -- add npc id if it exists
			tinsert(s,tonumber(npcID))
		end
	end

	return name
end

function rematch:MultiLineOnTextChanged()
	if rematch.shareMode==1 then -- export
		shareMultiEdit:SetText(rematch.shareString)
		shareMultiEdit:HighlightText()
		shareMultiEdit:SetCursorPosition(0)
	elseif rematch.shareMode==2 then -- import
		local shareString = shareMultiEdit:GetText()
		if shareString:len()==0 then
			rematch:SetShareStatus()
			return
		else
			local teamName = rematch:ParseShareString(shareString)
			if not teamName then
				rematch:SetShareStatus("This is not a valid team.")
				share.saveButton:Disable()
				rematch:ClearSelected()
				return
			elseif savedTeams[teamName] then
				rematch:SetShareStatus("A team already has this name.")
			else
				rematch:SetShareStatus()
			end
			share.saveButton:Enable()
			rematch.tempTeamName = rematch:ParseShareString(shareString,savedTeams["~temp~"])
			rematch:SetSelectedTeam("~temp~")
			rematch:UpdateSavedPets()
		end
	end
end

function rematch:SendOnTextChanged()
	share.saveButton:SetEnabled(share.singleLine.editBox:GetText():len()>0)
	rematch:SetShareStatus()
end

function rematch:SendOnEnterPressed()
	if share.saveButton:IsEnabled() then
		local name = share.singleLine.editBox:GetText()
		rematch:GenerateShareString(rematch.selectedTeam,savedTeams[rematch.selectedTeam])
		if rematch.shareString then
			rematch:SetShareStatus("Sending...","Interface\\Icons\\SOR-mail")
			rematch.sendee = share.singleLine.editBox:GetText():trim()
			rematch:RegisterEvent("CHAT_MSG_SYSTEM")
			rematch:StartTimer("SendTimeout",5,rematch.SendTimeout)
			SendAddonMessage("Rematch",rematch.shareString,"WHISPER",rematch.sendee)
		end
	end
end

function rematch:SendTimeout()
	rematch:SetShareStatus("No response. Due to lag or no Rematch?")
end

-- this is registered when we send a team, and unregistered on next SetShareStatus (including panel closing)
function rematch:CHAT_MSG_SYSTEM(message)
	if message==format(ERR_CHAT_PLAYER_NOT_FOUND_S,rematch.sendee) then
		rematch:SetShareStatus("They do not appear to be online.")
	end
end

-- SendAddonMessage from other users to us will trigger this event
function rematch:CHAT_MSG_ADDON(prefix,message,_,sender)
--	print(prefix,message,sender)
	if prefix~="Rematch" then
		return
	end
	if message=="ok" then -- sendee received team and sent back an ok
		rematch:SetShareStatus("The team was received!","Interface\\RaidFrame\\ReadyCheck-Ready")
	elseif message=="busy" then -- sendee received team but is already looking at a team
		rematch:SetShareStatus("They have another team waiting. Try again later.")
	elseif message=="combat" then -- sendee received team, but they're in combat
		rematch:SetShareStatus("They're in combat. Try again later.")
	elseif message=="block" then -- sendee received team, but has settings.DisableShare checked
		rematch:SetShareStatus("They have team sharing disabled.")
	else -- it's (probably) an incoming team

		-- if our DisableShare is set, tell the sender and leave
		if settings.DisableShare then
			SendAddonMessage("Rematch","block","WHISPER",sender)
			return
		end
		-- if user is already looking at a team, tell the sender and leave
		if incoming:IsVisible() then
			SendAddonMessage("Rematch","busy","WHISPER",sender)
			return
		end
		-- if user is in combat (not a game limitation, but it'd be very annoying to get incoming pets in a boss fight)
		if InCombatLockdown() then
			SendAddonMessage("Rematch","combat","WHISPER",sender)
			return
		end
		rematch.incomingTeam = rematch.incomingTeam or {{},{},{}}
		rematch.incomingName = rematch:ParseShareString(message,rematch.incomingTeam)

		if not rematch.incomingName then
			return -- we weren't sent a valid team, don't tell sender. they could be using a future version
		end

		-- if we made it this far, team was successfully received. send back "ok"
		SendAddonMessage("Rematch","ok","WHISPER",sender)

		rematch:DisplayIncoming(sender,rematch.incomingName,rematch.incomingTeam)

	end
end

--[[ Incoming ]]--

function rematch:RematchIncomingCancelButton()
	incoming:Hide()
end

function rematch:DisplayIncoming(sender,teamName,teamTable)
	incoming.greeting:SetText("\124cffffd200"..sender.."\124cffffffff has sent you a battle pet team!")
	incoming.incomingAs.editBox:SetText(teamName)
	incoming.incomingAs.editBox:SetCursorPosition(0)
	rematch:WipePetFrames(incoming.pet)
	rematch:FillPetFramesFromTeam(incoming.pet,teamTable)
	RematchIncoming:Show()
end

function rematch:IncomingAsOnTextChanged()
	local teamName = incoming.incomingAs.editBox:GetText()
	incoming.saveButton:SetEnabled(teamName:len()>0)
	local alreadyExists = savedTeams[teamName]
	incoming.warning:SetShown(alreadyExists)
	incoming.allClear:SetShown(not alreadyExists)
end

function rematch:RematchIncomingSaveButton()
	if incoming.saveButton:IsEnabled() then
		local teamName = incoming.incomingAs.editBox:GetText()
		if rematch:SaveTeam(teamName,rematch.incomingTeam) then
			incoming:Hide()
			if rematch:IsVisible() then
				share:Hide()
				rematch:SetSelectedTeam(teamName)
			end
		end
	end
end
