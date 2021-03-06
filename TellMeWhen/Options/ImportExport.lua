-- --------------------
-- TellMeWhen
-- Originally by Nephthys of Hyjal <lieandswell@yahoo.com>

-- Other contributions by:
--		Sweetmms of Blackrock, Oozebull of Twisting Nether, Oodyboo of Mug'thol,
--		Banjankri of Blackrock, Predeter of Proudmoore, Xenyr of Aszune

-- Currently maintained by
-- Cybeloras of Aerie Peak/Detheroc/Mal'Ganis
-- --------------------


if not TMW then return end

local TMW = TMW
local L = TMW.L
local print = TMW.print

-- GLOBALS: TELLMEWHEN_VERSIONNUMBER
-- GLOBALS: UIDROPDOWNMENU_MENU_LEVEL, UIDROPDOWNMENU_MENU_VALUE
-- GLOBALS: UIDropDownMenu_AddButton, UIDropDownMenu_CreateInfo, CloseDropDownMenus

local get = TMW.get

local tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, wipe, next, rawget =
	  tonumber, tostring, type, pairs, ipairs, tinsert, tremove, sort, wipe, next, rawget
local strfind, strmatch, format, gsub, strsub, strtrim, max, min, strlower, floor, log10 =
	  strfind, strmatch, format, gsub, strsub, strtrim, max, min, strlower, floor, log10



local function showGUIDConflictHelp(editbox, ...)
	if not TMW.HELP:IsCodeRegistered("IMPORT_NEWGUIDS") then
		TMW.HELP:NewCode("IMPORT_NEWGUIDS", 1, false)
	end
	TMW.HELP:Show("IMPORT_NEWGUIDS", nil, editbox, 0, 0, ...)
end

TMW:RegisterCallback("TMW_OPTIONS_LOADED", function()
	TMW.HELP:NewCode("ICON_EXPORT_MULTIPLE", 10, false)
	TMW.HELP:NewCode("ICON_EXPORT_DOCOPY", 11, true)
end)





local SharableDataType

local EDITBOX




local Item = TMW:NewClass("SettingsItem")
Item:MakeInstancesWeak()

function Item:OnNewInstance(type, parent)
	assert(type)

	self.Type = type
	self.extra = {}
	
	if parent then
		self:SetParent(parent)
	end
end

function Item:GetEditbox()
	return EDITBOX
end

function Item:SetExtra(k, v)
	self.extra[k] = v
end
function Item:GetExtra(k)
	return self.extra[k]
end

function Item:SetParent(parent)
	self.parent = parent
	self.Version = self.Version or parent.Version
	self.ImportSource = self.ImportSource or parent.ImportSource
end


function Item:CreateMenuEntry()
	local info = UIDropDownMenu_CreateInfo()
	info.value = self
	info.hasArrow = true
	info.notCheckable = true

	SharableDataType.types[self.Type]:Import_CreateMenuEntry(info, self)

	if self:GetExtra("SourcePlayer") then
		local fromLine = FROM .. " " .. self:GetExtra("SourcePlayer")

		if info.tooltipText then
			info.tooltipText = info.tooltipText .. "\r\n\r\n" .. fromLine
		else
			if not info.tooltipTitle then
				info.tooltipTitle = fromLine
			else
				info.tooltipText = fromLine
			end
		end

		info.tooltipOnButton = true
	end

	self.Header = info.text

	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
end

function Item:BuildChildMenu()
	if self.Header then
		local info = UIDropDownMenu_CreateInfo()
		info.text = self.Header
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		TMW.AddDropdownSpacer()
	end

	SharableDataType.types[self.Type]:RunMenuBuilders(self)
end

function Item:Import(...)
	self:AssertSelfIsInstance()
	
	local results = TMW:DetectImportedLua(self.Settings)
	local source = self.ImportSource.type

	if source == "Profile" or source == "Backup" or not results then
		TMW:Import(self, ...)
	else
		TMW:ImportPendingConfirmation(self, results, {TMW.Import, TMW, self, ...})
	end
end







local Bundle = TMW:NewClass("SettingsBundle")
Bundle:MakeInstancesWeak()
function Bundle:OnNewInstance(type)
	assert(type)

	self.Type = type
	self.Items = {}
end

function Bundle:Add(Item)
	assert(Item.class == TMW.Classes.SettingsItem)
	assert(Item.Type == self.Type)

	tinsert(self.Items, Item)
end
function Bundle:InItems()
	return pairs(self.Items)
end
function Bundle:GetLength()
	return #self.Items
end

function Bundle:First()
	return self.Items[1]
end
function Bundle:Last()
	return self.Items[#self.Items]
end

function Bundle:Evaluate()
	local numPerGroup = SharableDataType.types[self.Type].numPerGroup

	if #self.Items > numPerGroup then
		local Bundle = Bundle:New(self.Type)

		for n, Item in self:InItems() do
			if Bundle:GetLength() >= numPerGroup then
				Bundle:CreateGroupedMenuEntry()
				Bundle = Bundle:New(self.Type)
			end

			Bundle:Add(Item)
		end
		Bundle:CreateGroupedMenuEntry()
	else
		if self.Header then
			local info = UIDropDownMenu_CreateInfo()
			info.text = self.Header
			info.isTitle = true
			info.notCheckable = true
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

			TMW.AddDropdownSpacer()
		end

		for n, Item in self:InItems() do
			Item:CreateMenuEntry()
		end
	end
end

function Bundle:CreateGroupedMenuEntry()
	local info = UIDropDownMenu_CreateInfo()
	info.notCheckable = true
	info.hasArrow = true
	info.value = self

	info.text = SharableDataType.types[self.Type]:Import_GetGroupedBundleEntryText(self)
	self.Header = info.text

	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
end

function Bundle:CreateParentedMenuEntry(text)
	if self:GetLength() > 0 then
		local info = UIDropDownMenu_CreateInfo()
		info.text = text
		self.Header = text
		info.notCheckable = true
		info.hasArrow = true
		info.value = self
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		return true
	end
end




-- -----------------------
-- DATA TYPES
-- -----------------------

SharableDataType = TMW:NewClass("SharableDataType")
SharableDataType.types = {}
SharableDataType.numPerGroup = 15
SharableDataType.extrasMap = {}

function SharableDataType:OnNewInstance(type, order)
	TMW:ValidateType("2 (type)", "SharableDataType:New(type, order)", type, "string")
	TMW:ValidateType("3 (order)", "SharableDataType:New(type, order)", order, "number")
	
	self.type = type
	self.order = order
	SharableDataType.types[type] = self
	self.MenuBuilders = {}
end
function SharableDataType:RegisterMenuBuilder(order, func)
	tinsert(self.MenuBuilders, {
		order = order,
		func = func,
	})
	
	TMW:SortOrderedTables(self.MenuBuilders)
end
function SharableDataType:RunMenuBuilders(Item)
	for i, data in ipairs(self.MenuBuilders) do
		TMW.safecall(data.func, Item)
	end
end
function SharableDataType:AddExtras(Item, ...)
	for i, v in pairs(self.extrasMap) do
		Item:SetExtra(v, select(i, ...))
	end
end








---------- Database ----------
local database = SharableDataType:New("database", 0)








---------- Profile ----------
local profile = SharableDataType:New("profile", 10)
profile.extrasMap = {"Name"}

function profile:Import_ImportData(Item, profileName)
	if profileName then

		-- generate a new name if the profile already exists
		while TMW.db.profiles[profileName] do
			profileName = TMW.oneUpString(profileName)
		end

		-- put the data in the profile (no reason to CTIPWM when we can just do this) and set the profile
		TMW.db.profiles[profileName] = CopyTable(Item.Settings)
		TMW.db:SetProfile(profileName)
	else
		TMW.db:ResetProfile()
		TMW:CopyTableInPlaceWithMeta(Item.Settings, TMW.db.profile, true)
	end

	if Item.Version then
		if Item.Version > TELLMEWHEN_VERSIONNUMBER then
			TMW:Print(L["FROMNEWERVERSION"])
		else
			TMW:UpgradeProfile()
		end
	end
end

function profile:Import_CreateMenuEntry(info, Item)
	info.text = Item:GetExtra("Name")
end

function profile:Import_GetGroupedBundleEntryText(Bundle)
	local First = Bundle:First():GetExtra("Name")
	local Last = Bundle:Last():GetExtra("Name")

	return L["UIPANEL_PROFILES"] .. ": " ..
	(First:match("(.-)%-") or First:gsub(1, 20)):trim(" -") .. " - " ..
	(Last:match("(.-)%-") or Last:gsub(1, 20)):trim(" -")
end


-- Current Profile
database:RegisterMenuBuilder(10, function(Item_database)
	local db = Item_database.Settings
	local currentProfile = TMW.db:GetCurrentProfile()
	
	-- This might not evaluate to true if the import source is the backup database
	-- and this profile didn't exist when backup was created
	if db.profiles[currentProfile] then
		local Item = Item:New("profile")

		Item:SetParent(Item_database)
		Item.Settings = db.profiles[currentProfile]
		Item:SetExtra("Name", currentProfile)

		Item:CreateMenuEntry()

		TMW.AddDropdownSpacer()
	end
end)

-- All other profiles
database:RegisterMenuBuilder(20, function(Item_database)
	local db = Item_database.Settings
	local currentProfile = TMW.db:GetCurrentProfile()

	local Bundle = Bundle:New("profile")

	--other profiles
	for profilename, profiletable in TMW:OrderedPairs(db.profiles) do
		-- current profile and default are handled separately
		if profilename ~= currentProfile --[[and profilename ~= "Default"]] then
			local Item = Item:New("profile")

			Item:SetParent(Item_database)
			Item.Settings = profiletable
			Item.Version = profiletable.Version
			Item:SetExtra("Name", profilename)

			Bundle:Add(Item)
		end
	end

	Bundle:Evaluate()
end)

-- Default Profile
--[[database:RegisterMenuBuilder(30, function(Item_database)
	local db = Item_database.Settings
	local currentProfile = TMW.db:GetCurrentProfile()
	
	--default profile
	if db.profiles["Default"] and currentProfile ~= "Default" then
		local Item = Item:New("profile")

		Item:SetParent(Item_database)
		Item.Settings = db.profiles.Default
		Item.Version = db.profiles.Default.Version
		Item:SetExtra("Name", "Default")

		Item:CreateMenuEntry()
	end
end)]]


-- Copy Profile
profile:RegisterMenuBuilder(10, function(Item_profile)
	-- copy entire profile - overwrite current
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["IMPORT_PROFILE"] .. " - " .. L["IMPORT_PROFILE_OVERWRITE"]:format(TMW.db:GetCurrentProfile())
	info.func = function()
		Item_profile:Import()
	end
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	-- copy entire profile - create new profile
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["IMPORT_PROFILE"] .. " - " .. L["IMPORT_PROFILE_NEW"]
	info.func = function()
		Item_profile:Import(Item_profile:GetExtra("Name"))
	end
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	TMW.AddDropdownSpacer()
end)



profile.Export_DescriptionAppend = L["EXPORT_SPECIALDESC2"]:format("6.0.3+")
function profile:Export_SetButtonAttributes(editbox, info)
	local text = L["fPROFILE"]:format(TMW.db:GetCurrentProfile())
	info.text = text
	info.tooltipTitle = text
end
function profile:Export_GetArgs(editbox)
	-- settings, defaults, ...
	return TMW.db.profile, TMW.Defaults.profile, TMW.db:GetCurrentProfile()
end








---------- Group ----------
local group = SharableDataType:New("group", 20)
group.numPerGroup = 10
group.extrasMap = {"groupID"}

local function remapGUIDs(data, GUIDmap)
	for k, v in pairs(data) do
		local type = type(v)
		if type == "table" then
			remapGUIDs(v, GUIDmap)
		elseif type == "string" then
			if GUIDmap[v] then
				data[k] = GUIDmap[v]
			else
				for oldGUID, newGUID in pairs(GUIDmap) do
					oldGUID = oldGUID:gsub("([%-%+])", "%%%1")
					if v:find(oldGUID) then
						data[k] = v:gsub(oldGUID, newGUID)
					end
				end
			end
		end
	end
end

function group:Import_ImportData(Item_group, domain, createNewGroup, oldgroupID, destgroup)
	print(domain, createNewGroup, oldgroupID, destgroup)
	local group
	if createNewGroup then
		group = TMW:Group_Add(domain, nil)
	else
		group = destgroup
	end

	local version = Item_group.Version

	TMW.db[domain].Groups[group.ID] = nil -- restore defaults, table recreated when passed in to CTIPWM
	local gs = group:GetSettings()
	TMW:CopyTableInPlaceWithMeta(Item_group.Settings, gs, true)

	if version < 70000 then
		gs.__UPGRADEHELPER_OLDGROUPID = oldgroupID
	elseif version >= 70000	then
		local existingGUIDs = {}

		local GUIDmap = {}

		for gs2 in TMW:InGroupSettings() do
			if gs ~= gs2 then
				existingGUIDs[gs2.GUID] = true
			end
		end
		for ics, gs2 in TMW:InIconSettings() do
			if ics.GUID and ics.GUID ~= "" then
				if gs ~= gs2 then
					existingGUIDs[ics.GUID] = true
				else
					GUIDmap[ics.GUID] = TMW:GenerateGUID("icon", TMW.CONST.GUID_SIZE)
				end
			end
		end

		GUIDmap[gs.GUID] = TMW:GenerateGUID("group", TMW.CONST.GUID_SIZE)

		for k, v in pairs(GUIDmap) do
			if not existingGUIDs[k] then
				GUIDmap[k] = nil
			end
		end

		if next(GUIDmap) then
			local groupCount, iconCount = 0, 0
			for k, v in pairs(GUIDmap) do
				local dataType = TMW:ParseGUID(k)
				if dataType == "group" then
					groupCount = groupCount + 1
				elseif dataType == "icon" then
					iconCount = iconCount + 1
				end
			end

			TMW:Printf(L["IMPORT_NEWGUIDS"], groupCount, iconCount)
			showGUIDConflictHelp(EDITBOX, L["IMPORT_NEWGUIDS"], groupCount, iconCount)

			remapGUIDs(gs, GUIDmap)
		end
	end

	if version then
		if version > TELLMEWHEN_VERSIONNUMBER then
			TMW:Print(L["FROMNEWERVERSION"])
		else
			TMW:DoUpgrade("group", version, gs, domain, group.ID)
		end
	end
end

function group:Import_CreateMenuEntry(info, Item)
	local gs = Item.Settings
	local groupID = Item:GetExtra("groupID")

	info.text = TMW:GetGroupName(gs.Name, groupID)
	info.tooltipTitle = format(L["fGROUP"], groupID)
	info.tooltipText = 	(L["UIPANEL_ROWS"] .. ": " .. (gs.Rows or 1) .. "\r\n") ..
					L["UIPANEL_COLUMNS"] .. ": " .. (gs.Columns or 4) ..
					((gs.Enabled and "") or "\r\n(" .. L["DISABLED"] .. ")")
	info.tooltipOnButton = true
end

function group:Import_GetGroupedBundleEntryText(Bundle)
	return L["UIPANEL_GROUPS"] .. ": " ..
	Bundle:First():GetExtra("groupID") .. " - " ..
	Bundle:Last():GetExtra("groupID")
end


-- Global Group Listing
database:RegisterMenuBuilder(15, function(Item_database)
	
	local global = Item_database.Settings.global
	local Bundle = Bundle:New("group")

	local numGroups = global.NumGroups

	if numGroups and numGroups > 1 then
		for groupID, gs in TMW:OrderedPairs(global.Groups) do
			if groupID >= 1 and groupID <= numGroups then
				local Item = Item:New("group")

				Item:SetParent(Item_database)
				Item.Settings = gs
				Item:SetExtra("groupID", groupID)

				Bundle:Add(Item)
				
			end
		end

		Bundle:CreateParentedMenuEntry(L["UIPANEL_GROUPS_GLOBAL"])

		TMW.AddDropdownSpacer()
	end
end)

-- Profile Group Listing
profile:RegisterMenuBuilder(40, function(Item_profile)
	-- group header
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["UIPANEL_GROUPS"]
	info.isTitle = true
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)


	local profile = Item_profile.Settings
	local Bundle = Bundle:New("group")

	local numGroups = tonumber(profile.NumGroups) or 1

	if profile.Groups then
		for groupID, gs in TMW:OrderedPairs(profile.Groups) do
			if groupID >= 1 and groupID <= numGroups then
				local Item = Item:New("group")

				Item:SetParent(Item_profile)
				Item.Settings = gs
				Item:SetExtra("groupID", groupID)

				Bundle:Add(Item)
			end
		end
	end

	Bundle:Evaluate()
end)


-- Copy Group
group:RegisterMenuBuilder(20, function(Item_group)
	local groupID = Item_group:GetExtra("groupID")
	local gs = Item_group.Settings

	local IMPORTS, EXPORTS = EDITBOX:GetAvailableImportExportTypes()

	local group = IMPORTS.group_overwrite

	-- copy entire group - overwrite current
	local info = UIDropDownMenu_CreateInfo()
	-- IMPORT_PROFILE_OVERWRITE is used here even though we aren't importing a profile
	info.text = L["COPYGROUP"] .. " - " .. L["IMPORT_PROFILE_OVERWRITE"]:format(group and group:GetGroupName() or "?")
	info.func = function()
		Item_group:Import(group.Domain, false, groupID, group)
	end
	info.notCheckable = true
	info.disabled = not IMPORTS.group_overwrite
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	-- copy entire group - create new group in profile
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["COPYGROUP"] .. " - " .. L["MAKENEWGROUP_PROFILE"]
	info.func = function()
		Item_group:Import("profile", true, groupID)
	end
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

	-- copy entire group - create new group in global
	local info = UIDropDownMenu_CreateInfo()
	info.text = L["COPYGROUP"] .. " - " .. L["MAKENEWGROUP_GLOBAL"]
	info.func = function()
		Item_group:Import("global", true, groupID)
	end
	info.notCheckable = true
	UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
end)



group.Export_DescriptionAppend = L["EXPORT_SPECIALDESC2"]:format("4.6.0+")

function group:Export_SetButtonAttributes(editbox, info)
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	local group = EXPORTS[self.type]
	
	local text = L["fGROUP"]:format(group:GetGroupName(1):gsub("|r", "|cff00ffff"))
	info.text = text
	info.tooltipTitle = text
end

function group:Export_GetArgs(editbox)
	-- settings, defaults, ...
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	local group = EXPORTS[self.type]
	
	return group:GetSettings(), TMW.Group_Defaults, group.ID
end








---------- Icon ----------
local icon = SharableDataType:New("icon", 30)
icon.extrasMap = {}

function icon:Import_ImportData(Item)
	local IMPORTS, EXPORTS = EDITBOX:GetAvailableImportExportTypes()
	
	local icon = IMPORTS.icon
	local group = IMPORTS.group_overwrite
	local gs = group:GetSettings()

	gs.Icons[icon.ID] = nil -- restore defaults
	local ics = icon:GetSettings()
	TMW:CopyTableInPlaceWithMeta(Item.Settings, ics, true)


	local version = Item.Version
	if version >= 70000 and ics.GUID ~= "" then
		local existed = false

		for ics2 in TMW:InIconSettings() do
			if ics2 ~= ics and ics2.GUID == ics.GUID then
				existed = true
				break
			end
		end

		if existed then
			TMW:Printf(L["IMPORT_NEWGUIDS"], 0, 1)
			showGUIDConflictHelp(EDITBOX, L["IMPORT_NEWGUIDS"], 0, 1)

			local GUIDmap = {
				[ics.GUID] = TMW:GenerateGUID("icon", TMW.CONST.GUID_SIZE)
			}
			remapGUIDs(ics, GUIDmap)
		end
	end


	if version then
		if version > TELLMEWHEN_VERSIONNUMBER then
			TMW:Print(L["FROMNEWERVERSION"])
		else
			TMW:DoUpgrade("icon", version, ics, gs, icon.ID)
		end
	end
end

function icon:Import_CreateMenuEntry(info, Item)
	local ics = Item.Settings
	local iconID = Item:GetExtra("iconID")

	local Item_group = Item.parent
	local groupID = Item_group and Item_group:GetExtra("groupID")
	local gs = Item_group and Item_group.Settings
	local version = Item.Version


	local IMPORTS, EXPORTS = EDITBOX:GetAvailableImportExportTypes()
	
	local text, textshort, tooltipText = TMW:GetIconMenuText(ics)
	if text:sub(-2) == "))" and iconID then
		textshort = textshort .. " " .. L["fICON"]:format(iconID)
	end
	info.text = textshort
	info.tooltipTitle = (groupID and format(L["GROUPICON"], TMW:GetGroupName(gs and gs.Name, groupID, 1), iconID)) or (iconID and L["fICON"]:format(iconID)) or L["ICON"]
	info.tooltipOnButton = true
		
	info.disabled = not IMPORTS.icon
	if info.disabled then
		info.tooltipText = L["IMPORT_ICON_DISABLED_DESC"]
		info.tooltipWhileDisabled = true
	else
		info.tooltipText = tooltipText
	end

	info.hasArrow = false

	info.icon = TMW:GuessIconTexture(ics)
	info.tCoordLeft = 0.07
	info.tCoordRight = 0.93
	info.tCoordTop = 0.07
	info.tCoordBottom = 0.93

	info.func = function()
		if ic and ic:IsVisible() then
			TMW.HELP:Show("ICON_IMPORT_CURRENTPROFILE", nil, EDITBOX, 0, 0, L["HELP_IMPORT_CURRENTPROFILE"])
			IMPORTS.icon:SetInfo("texture", tex)
		else
			IMPORTS.icon:SetInfo("texture", nil)
		end
		
		if gs then
			TMW:PrepareIconSettingsForCopying(ics, gs)
		end
		
		Item:Import()
	end
end

function icon:Import_GetGroupedBundleEntryText(Bundle)
	return L["UIPANEL_ICONS"] .. ": " ..
	Bundle:First():GetExtra("iconID") .. " - " ..
	Bundle:Last():GetExtra("iconID")
end


-- Group's Icons
group:RegisterMenuBuilder(30, function(Item_group)
	
	if Item_group.Settings.Icons then
		TMW.AddDropdownSpacer()

		-- Header
		local info = UIDropDownMenu_CreateInfo()
		info.text = L["UIPANEL_ICONS"]
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)


		local Bundle = Bundle:New("icon")

		for iconID, ics in TMW:OrderedPairs(Item_group.Settings.Icons) do
			if not TMW:DeepCompare(TMW.DEFAULT_ICON_SETTINGS, ics) then
				local Item = Item:New("icon")

				Item:SetParent(Item_group)
				Item.Settings = ics
				Item:SetExtra("iconID", iconID)

				Bundle:Add(Item)
			end
		end

		Bundle:Evaluate()
	end
end)


icon:RegisterMenuBuilder(10, function(Item_icon)
	Item_icon:CreateMenuEntry()
end)



function icon:Export_SetButtonAttributes(editbox, info)
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	local icon = EXPORTS.icon
	
	local text = L["fICON"]:format(icon.ID)
	info.text = text
	info.tooltipTitle = text

	info.icon = icon.attributes.texture
	info.tCoordLeft = 0.07
	info.tCoordRight = 0.93
	info.tCoordTop = 0.07
	info.tCoordBottom = 0.93
end

function icon:Export_GetArgs(editbox)
	-- settings, defaults, ...
	local IMPORTS, EXPORTS = editbox:GetAvailableImportExportTypes()
	local icon = EXPORTS.icon
	
	local gs = icon.group:GetSettings()
	local ics = icon:GetSettings()
	TMW:PrepareIconSettingsForCopying(ics, gs)
	
	return ics, TMW.Icon_Defaults
end







-- -----------------------
-- IMPORT SOURCES
-- -----------------------

local ImportSource = TMW:NewClass("ImportSource")
ImportSource.types = {}

function ImportSource:OnNewInstance(type)
	self.type = type
	ImportSource.types[type] = self
end




---------- Profile ----------
local Profile = ImportSource:New("Profile")
Profile.displayText = L["IMPORT_FROMLOCAL"]

function Profile:HandleTopLevelMenu()
	local Item = Item:New("database")
	Item.ImportSource = self

	Item.Settings = TMW.db
	Item.Version = TellMeWhenDB.Version

	Item:BuildChildMenu()
end




---------- Backup ----------
local Backup = ImportSource:New("Backup")
Backup.displayText = L["IMPORT_FROMBACKUP"]
Backup.displayDescription = L["IMPORT_FROMBACKUP_DESC"]:format(TMW.BackupDate)

function Backup:HandleTopLevelMenu()
	local Item = Item:New("database")
	Item.ImportSource = self

	Item.Settings = TMW.Backupdb
	Item.Version = TMW.Backupdb.Version

	Item:BuildChildMenu()
end

function Backup:TMW_CONFIG_IMPORTEXPORT_DROPDOWNDRAW(event, destination)
	if destination == self then
		local info = UIDropDownMenu_CreateInfo()
		info.text = "|cffff0000" .. L["IMPORT_FROMBACKUP_WARNING"]:format(TMW.BackupDate)
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		TMW.AddDropdownSpacer()
	end
end

TMW:RegisterCallback("TMW_CONFIG_IMPORTEXPORT_DROPDOWNDRAW", Backup)




---------- String ----------
local String = ImportSource:New("String")
String.displayText = function()
	return (EDITBOX.DoPulseValidString and "|cff00ff00" or "") .. L["IMPORT_FROMSTRING"]
end
String.displayDisabled = function()
	local t = strtrim(EDITBOX:GetText())
	return not (t ~= "" and TMW:DeserializeData(t))
end
String.displayDescription = L["IMPORT_FROMSTRING_DESC"]

function String:HandleTopLevelMenu()
	local t = strtrim(EDITBOX:GetText())

	-- There is an escaped link. Unescape it.
	if t:find("||H") then
		t = t:gsub("||", "|")
	end

	local editboxResults = t ~= "" and TMW:DeserializeData(t)

	if editboxResults then
		for _, result in pairs(editboxResults) do 
			local type = SharableDataType.types[result.type]

			local Item = Item:New(result.type)
			Item.ImportSource = self

			Item.Settings = result.data
			Item.Version = result.version
			type:AddExtras(Item, unpack(result))

			Item:CreateMenuEntry()
		end
	end
end




---------- Comm ----------
local Comm = ImportSource:New("Comm")
local DeserializedData = {}
Comm.displayText = L["IMPORT_FROMCOMM"]
Comm.displayDescription = L["IMPORT_FROMCOMM_DESC"]
Comm.displayDisabled = function()
	Comm:DeserializeReceivedData()
	return not (DeserializedData and next(DeserializedData))
end

function Comm:DeserializeReceivedData()
	if TMW.Received then
		 -- deserialize received comm
		for k, who in pairs(TMW.Received) do
			-- deserialize received data now because we dont do it as they are received; AceSerializer is only embedded in _Options
			if type(k) == "string" and who then
				local results = TMW:DeserializeData(k)
				if results then
					for _, result in pairs(results) do
						tinsert(DeserializedData, result)
						result.who = who
						TMW.Received[k] = nil
					end
				end
			end
		end
		if not next(TMW.Received) then
			TMW.Received = nil
		end
	end
end

function Comm:HandleTopLevelMenu(editbox)
	Comm:DeserializeReceivedData()
	
	for k, result in ipairs(DeserializedData) do
		local type = SharableDataType.types[result.type]

		local Item = Item:New(result.type)
		Item.ImportSource = self

		Item.Settings = result.data
		Item.Version = result.version
		Item:SetExtra("SourcePlayer", result.who)
		type:AddExtras(Item, unpack(result))

		Item:CreateMenuEntry()
	end
end








-- -----------------------
-- EXPORT DESTINATIONS
-- -----------------------

local function DestinationsOrderedSort(a, b)
	return SharableDataType.instances[a].order < SharableDataType.instances[b].order
end

local ExportDestination = TMW:NewClass("ExportDestination")
ExportDestination.types = {}

function ExportDestination:OnNewInstance(type)
	self.type = type
	ExportDestination.types[type] = self
end

function ExportDestination:HandleTopLevelMenu()
	local IMPORTS, EXPORTS = EDITBOX:GetAvailableImportExportTypes()
	
	for k, dataType in TMW:OrderedPairs(SharableDataType.instances, DestinationsOrderedSort) do
		if EXPORTS[dataType.type] then
			local info = UIDropDownMenu_CreateInfo()

			info.tooltipText = self.Export_DescriptionPrepend
			if dataType.Export_DescriptionAppend then
				info.tooltipText = info.tooltipText .. "\r\n\r\n" .. dataType.Export_DescriptionAppend
			end
			info.tooltipOnButton = true
			info.tooltipWhileDisabled = true
			info.notCheckable = true
			
			dataType:Export_SetButtonAttributes(EDITBOX, info)
			
			-- Color everything before the first colon a light blue (highlights the type of data being exported, for clarity)
			info.text = info.text:gsub("^(.-):", "|cff00ffff%1|r:")
			
			info.func = function()
				-- type, settings, defaults, ...
				self:Export(dataType.type, dataType:Export_GetArgs(EDITBOX))
			end
			
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
	end
end




---------- String ----------
local String = ExportDestination:New("String")
String.Export_DescriptionPrepend = L["EXPORT_TOSTRING_DESC"]

function String:Export(type, settings, defaults, ...)
	local strings = TMW:GetSettingsStrings(nil, type, settings, defaults, ...)

	local str = table.concat(strings, "\r\n\r\n"):gsub("|", "||")

	str = TMW:MakeSerializedDataPretty(str)
	TMW.LastExportedString = str

	EDITBOX:SetText(str)
	EDITBOX:HighlightText()
	EDITBOX:SetFocus()

	CloseDropDownMenus()

	TMW.HELP:Hide("ICON_EXPORT_MULTIPLE")
	if #strings > 1 then
		TMW.HELP:Show("ICON_EXPORT_MULTIPLE", nil, EDITBOX, 0, 0, L["HELP_EXPORT_MULTIPLE_STRING"])
	end

	TMW.HELP:Show("ICON_EXPORT_DOCOPY", nil, EDITBOX, 0, 0, L["HELP_EXPORT_DOCOPY_" .. (IsMacClient() and "MAC" or "WIN")])
end

function String:SetButtonAttributes(editbox, info)
	info.text = L["EXPORT_TOSTRING"]
	info.tooltipTitle = L["EXPORT_TOSTRING"]
	info.tooltipText = L["EXPORT_TOSTRING_DESC"]
	info.hasArrow = true
end




---------- Comm ----------
local Comm = ExportDestination:New("Comm")
Comm.Export_DescriptionPrepend = L["EXPORT_TOCOMM_DESC"]

function Comm:Export(type, settings, defaults, ...)
	local player = strtrim(EDITBOX:GetText())
	if player and #player > 1 then
		local strings = TMW:GetSettingsStrings(nil, type, settings, defaults, ...)

		TMW.HELP:Hide("ICON_EXPORT_MULTIPLE")
		if #strings > 1 then
			TMW.HELP:Show("ICON_EXPORT_MULTIPLE", nil, EDITBOX, 0, 0, L["HELP_EXPORT_MULTIPLE_COMM"])
		end

		for n, str in pairs(strings) do
			if player == "RAID" or player == "GUILD" then -- note the upper case
				TMW:SendCommMessage("TMW", str, player, nil, "BULK", EDITBOX.callback, {n, #strings})
			else
				TMW:SendCommMessage("TMW", str, "WHISPER", player, "BULK", EDITBOX.callback, {n, #strings})
			end
		end
	end
	
	CloseDropDownMenus()
end

function Comm:SetButtonAttributes(editbox, info)
	local player = strtrim(editbox:GetText())
	local playerLength = strlenutf8(player)
	info.disabled = (strfind(player, "[`~^%d!@#%$%%&%*%(%)%+=_]") or playerLength <= 1 or playerLength > 35) and true

	local text
	if player == "RAID" or player == "GUILD" then
		text = L["EXPORT_TO" .. player]
	else
		text = L["EXPORT_TOCOMM"]
		if not info.disabled then
			text = text .. ": " .. player
		end
	end

	info.text = text
	info.tooltipTitle = text
	info.tooltipText = L["EXPORT_TOCOMM_DESC"]

	info.value = "EXPORT_TOCOMM"
	info.hasArrow = not info.disabled
end








-- -----------------------
-- DROPDOWN
-- -----------------------

local CurrentHandler
function TMW.IE:ImportExport_DropDown(...)
	local DROPDOWN = self
	EDITBOX = DROPDOWN:GetParent()
	TMW.IE.ImportExport_Editbox = EDITBOX

	local VALUE = UIDROPDOWNMENU_MENU_VALUE

	if UIDROPDOWNMENU_MENU_LEVEL == 1 then
		CurrentHandler = nil
	elseif UIDROPDOWNMENU_MENU_LEVEL == 2 then
		assert(type(VALUE) == "table")
		CurrentHandler = VALUE
	end
	
	TMW:Fire("TMW_CONFIG_IMPORTEXPORT_DROPDOWNDRAW", CurrentHandler)
	
	if UIDROPDOWNMENU_MENU_LEVEL == 2 then
		VALUE:HandleTopLevelMenu()

	elseif UIDROPDOWNMENU_MENU_LEVEL == 1 then

		----------IMPORT----------
		
		-- heading
		local info = UIDropDownMenu_CreateInfo()
		info.text = L["IMPORT_HEADING"]
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)

		-- List of Import Sources
		for k, importSource in pairs(ImportSource.instances) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = get(importSource.displayText, EDITBOX)
			
			if importSource.displayDescription then
				info.tooltipTitle = get(importSource.displayText, EDITBOX)
				info.tooltipText = importSource.displayDescription
				info.tooltipOnButton = true
				info.tooltipWhileDisabled = true
			end
			
			info.value = importSource
			info.notCheckable = true
			info.disabled = get(importSource.displayDisabled, EDITBOX)
			info.hasArrow = not info.disabled
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end


		TMW.AddDropdownSpacer()



		----------EXPORT----------

		-- heading
		info = UIDropDownMenu_CreateInfo()
		info.text = L["EXPORT_HEADING"]
		info.isTitle = true
		info.notCheckable = true
		UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		
		-- List of export destinations
		for k, exportDestination in pairs(ExportDestination.instances) do
			local info = UIDropDownMenu_CreateInfo()
			info.tooltipOnButton = true
			info.tooltipWhileDisabled = true
			info.notCheckable = true
			
			exportDestination:SetButtonAttributes(EDITBOX, info)
			
			info.value = exportDestination
			
			UIDropDownMenu_AddButton(info, UIDROPDOWNMENU_MENU_LEVEL)
		end
		
	elseif type(VALUE) == "table" then
		if VALUE.class == Item then
			VALUE:BuildChildMenu()
		elseif VALUE.class == Bundle then
			VALUE:Evaluate()
		else
			error("Bad value at " .. UIDROPDOWNMENU_MENU_LEVEL)
		end
	end
end








