
local rematch = Rematch
local confirm = RematchConfirm
local settings, savedTeams

function rematch:InitializeConfirm()
	savedTeams = RematchSaved
	settings = RematchSettings
end

function rematch:RematchConfirmNoButton()
	confirm:Hide()
end

function rematch:RematchConfirmYesButton()
	confirm:Hide()
	if confirm.func then
		confirm.func()
	end
end

function rematch:ConfirmOnShow()
	rematch.confirmBlackout:Show()
end

function rematch:ConfirmOnHide()
	rematch.confirmBlackout:Hide()
	rematch.saveAs:Hide()
	rematch.drawer.share:Hide()
	RematchIncoming:Hide()
end

-- sets header to teamNpc and creates slots if they haven't already been defined
function rematch:PrepareConfirm(teamName,npcID,delete)
	-- confirm frame should be 258 height with secondTeam shown; 154 with secondTeam hidden
	confirm.header.text:SetText(teamName)
	confirm.header.text:SetTextColor(1,npcID and 1 or .82,npcID and 1 or 0)
	rematch:WipePetFrames(confirm.firstTeam.pet)
	if delete then
		confirm.question:SetText("Do you want to delete:")
		confirm.secondTeam:Hide()
		confirm:SetHeight(154)
	else
		rematch:WipePetFrames(confirm.secondTeam.pet)
		confirm.question:SetText("Do you want to replace:")
		confirm.secondTeam:Show()
		confirm:SetHeight(258)
	end
end

function rematch:ConfirmSave(teamName,oldTeam,newTeam)
	rematch:PrepareConfirm(teamName,newTeam[4])
	rematch:FillPetFramesFromTeam(confirm.firstTeam.pet,oldTeam)
	rematch:FillPetFramesFromTeam(confirm.secondTeam.pet,newTeam)
	confirm.teamName = teamName
	confirm.teamTable = newTeam
	confirm.func = rematch.SaveConfirmed
	confirm:Show()
end

--[[ Delete ]]

function rematch:DeleteSelectedTeam()
	local teamName = rematch.selectedTeam
	if teamName then
		if not settings.AutoConfirm and savedTeams[teamName] then
			rematch:ConfirmDelete(teamName,savedTeams[teamName])
		else
			rematch:DeleteConfirmed()
		end
	end
end

function rematch:ConfirmDelete(teamName,teamTable)
	rematch:PrepareConfirm(teamName,teamTable[4],true)
	rematch:FillPetFramesFromTeam(confirm.firstTeam.pet,teamTable)
	confirm.teamName = teamName
	confirm.teamTable = teamTable
	confirm.func = rematch.DeleteConfirmed
	confirm:Show()
end

function rematch:DeleteConfirmed()
	RematchSaved[rematch.selectedTeam] = nil
	rematch:SetSelectedTeam(nil)
	if rematch.drawer:IsVisible() then
		rematch:OrderTeamList()
		rematch:UpdateTeamList()
	end
end
