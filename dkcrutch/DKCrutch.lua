-------------------------------------------------------------------------------
-- DKCrutch 0.9.6
--
-- Death Knight rune tracker and ability advisor
-------------------------------------------------------------------------------

DKCrutch = {Locals = {}}

local L = DKCrutch.Locals

DKCrutch.versionNumber = '0.9.6'
DKCrutch.talent = ""
DKCrutch.talentUnsure = true
DKCrutch.DebugMode = false
DKCrutch.DebugChat = DEFAULT_CHAT_FRAME
DKCrutch.playerName = UnitName("player")
DKCrutch.playerGUID = UnitGUID("player")
DKCrutch.runeTracker = {}
DKCrutch.runesUp = {}
DKCrutch.depletedCount = 0
DKCrutch.events = {}
DKCrutch.lastUpdate = GetTime();
DKCrutch.hasT15_4pcs = false;
DKCrutch.dualWield = false;
DKCrutch.SpellList = {
	["Outbreak"] = GetSpellInfo(77575),
	["Icy Touch"] = GetSpellInfo(45477),
	["Plague Strike"] = GetSpellInfo(45462),
	["Dark Transformation"] = GetSpellInfo(63560),
	["Raise Dead"] = GetSpellInfo(46584),
	["Death and Decay"] = GetSpellInfo(43265),
	["Scourge Strike"] = GetSpellInfo(55090),
	["Festering Strike"] = GetSpellInfo(85948),
	["Death Coil"] = GetSpellInfo(47541),
	["Empower Rune Weapon"] = GetSpellInfo(47568),
	["Horn of Winter"] = GetSpellInfo(57330),
	["Howling Blast"] = GetSpellInfo(49184),
	["Obliterate"] = GetSpellInfo(49020),
	["Pillar of Frost"] = GetSpellInfo(51271),
	["Frost Strike"] = GetSpellInfo(49143),
	["Death Strike"] = GetSpellInfo(49998),
	["Rune Strike"] = GetSpellInfo(56815),
	["Heart Strike"] = GetSpellInfo(55050),
	["Blood Boil"] = GetSpellInfo(48721),
	["Soul Reaper"] = GetSpellInfo(130736),

-- talent specifig
	["Plague Leech"] = GetSpellInfo(123693),
	["Blood Tap"] = GetSpellInfo(45529),
	["Blood Charge"] = GetSpellInfo(114851),
	["Unholy Blight"] = GetSpellInfo(115989),

-- presences
	["Unholy Presence"] = GetSpellInfo(48265),
	["Frost Presence"] = GetSpellInfo(48266),
	["Blood Presence"] = GetSpellInfo(48263),

-- buff, procs
	["Sudden Doom"] = GetSpellInfo(81340),
	["Unholy Strength"] = GetSpellInfo(53365),
	["Killing Machine"] = GetSpellInfo(51124),
	["Freezing Fog"] = GetSpellInfo(59052),
	["Blood Shield"] = GetSpellInfo(77535),
	["Shadow Infusion"] = GetSpellInfo(91342),	-- buff pet
	["Blood Charge"] = GetSpellInfo(114851),

-- debuffs
	["Frost Fever"] = GetSpellInfo(59921),
	["Blood Plague"] = GetSpellInfo(59879)
}
DKCrutch.lastSpell = ""
DKCrutch.lastProc = ""
DKCrutch.lastGlow = false
DKCrutch.lastBloodCharge = -1;
DKCrutch.lastD1 = ""
DKCrutch.lastD2 = ""
-- FoF detection
DKCrutch.person = {
	["lastPurged"]	= 0.0,
	["foeCount"]	= 0,
	["friendCount"]	= 0,
	["foe"]		= {},
	["friend"]  = {}
}
-- Event filter
DKCrutch.HostileFilter = {
  ["_DAMAGE"] = true, 
  ["_LEECH"] = true,
  ["_DRAIN"] = true,
  ["_STOLEN"] = true,
  ["_INSTAKILL"] = true,
  ["_INTERRUPT"] = true,
  ["_MISSED"] = true
}
-- Set items
DKCrutch.ArmorSets = {
	[138347]	= {	-- Death Knight T15 DPS 4P Bonus
		[95825] = true, [95826] = true, [95827] = true, [95828] = true, [95829] = true, [96569] = true, [96570] = true, [96571] = true, [96572] = true, [96573] = true, [95225] = true, [95226] = true, [95227] = true, [95228] = true, [95229] = true 
	}
}


-- Our sneaky frame to watch for events ... checks DKCrutch.events[] for the function.  Passes all args.
DKCrutch.eventFrame = CreateFrame("Frame")
DKCrutch.eventFrame:RegisterEvent("PLAYER_LOGIN")
DKCrutch.eventFrame:RegisterEvent("PLAYER_ALIVE")
DKCrutch.eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
DKCrutch.eventFrame:SetScript("OnEvent", function(this, event, ...)
	DKCrutch.events[event](...)
end)

-- Define our Event Handlers here

function DKCrutch.events.PLAYER_ALIVE()
	-- check anything
	DKCrutch.playerGUID = UnitGUID("player")
	DKCrutch:detectTalent()
	DKCrutch:ApplySettings()
	
	-- DKCrutch.eventFrame:UnregisterEvent("PLAYER_ALIVE")
end

function DKCrutch.events.PLAYER_EQUIPMENT_CHANGED()
	local _, itemType, itemSlot;

	DKCrutch.hasT15_4pcs = DKCrutch:HasSetBonus( 138347, 4 );
	_, itemSlot = GetInventorySlotInfo("MainHandSlot");
	if (itemSlot) and (GetInventoryItemID("player", itemSlot)) then
		_, _, _, _, _, _, _, _, itemType = GetItemInfo( GetInventoryItemID("player", itemSlot));
		DKCrutch.dualWield = (itemType == "INVTYPE_WEAPON");
	end
end

function DKCrutch.events.PLAYER_ENTERING_WORLD()
	DKCrutch.playerGUID = UnitGUID("player");
	DKCrutch:detectTalent();

	DKCrutch.events.PLAYER_EQUIPMENT_CHANGED();
end

function DKCrutch.events.ACTIVE_TALENT_GROUP_CHANGED()
	DKCrutch:detectTalent()
end

function DKCrutch.events.PLAYER_TALENT_UPDATE()
	DKCrutch:detectTalent()
end

function DKCrutch.events.RUNE_POWER_UPDATE()
	if(DKCrutchDB.enabled) then
		DKCrutch:Update()
	end
end

function DKCrutch.events.RUNE_TYPE_UPDATE()
	if(DKCrutchDB.enabled) then
		DKCrutch:Update()
	end
end

function DKCrutch.events.PLAYER_LOGIN()
	DKCrutch:OnLoad()
	
	DKCrutch.eventFrame:UnregisterEvent("PLAYER_LOGIN")
end

function DKCrutch:SetSwingBarWidth(element, time, speed, maxwidth)
	DKCrutch:Debug("SetSwingBarWidth" .. " t: " .. time .." s:" .. speed , maxwidth)
	local width = ( time / speed * maxwidth );
	if ( width < 1 ) then
		width = 1;
	elseif ( width > maxwidth ) then
		width = maxwidth;
	end
	element:SetValue(width);
end

function DKCrutch:GetSwingSpeed(element)
	local mainhand,offhand = UnitAttackSpeed("player");
	if ( DKCrutch.dualWield ) and ( element.SLOT == GetInventorySlotInfo("SecondaryHandSlot") ) then
		return(offhand);
	else
		return(mainhand);
	end
end

function DKCrutch:SetSwingSpeed(element, speed)
	if ( speed == nil ) then
		element.speed = DKCrutch:GetSwingSpeed(element);
		if ( element.speed == nil ) then
			element:Hide();
			return(nil);
		end
	else
		element.speed = speed;
	end
	_,_,element.latency = GetNetStats();
	element.latency = element.latency / 1000;
	DKCrutch:Debug("SwingFrame l: " .. element.latency .." s:" .. element.speed , element.maxwidth)
	DKCrutch:SetSwingBarWidth(element, element.latency, element.speed, element.maxwidth);
end

function DKCrutch:ResetSwingFrame(element)
	element:SetScript("OnUpdate", nil);
	element.lastupdate = 0;
	element.maxwidth = 128;
	element.elapsed = 0;
	DKCrutch:SetSwingSpeed(element);
	element:SetMinMaxValues(0, element.maxwidth);
	element:SetValue(0);
	element.active = nil;
	element:Show();
	element.vanish = 0;
end

function DKCrutch.VanishFrame(element,elapsed)
	DKCrutch:Debug("VanishFrame", elapsed)
	if ( element.vanish > 0 ) then
		element.vanish = element.vanish - elapsed;
		if ( element.vanish <= 0 ) then
			element:SetScript("OnUpdate", nil);
			element:Hide();
		end
	end  
end

function DKCrutch.UpdateSwingFrame(element,elapsed)
	-- performance throttle
	element.lastupdate = element.lastupdate + elapsed;
	if ( element.lastupdate < 0.03 ) then
		return(nil);
	end
	element.elapsed = element.elapsed + element.lastupdate;
	element.lastupdate = 0;

	-- flag the swing timer as inactive early to help account for lag
	if ( element.elapsed > (element.speed - element.latency ) ) then
		element.active = nil;
	end

	if ( element.elapsed > element.speed ) then
		DKCrutch:ResetSwingFrame(element);
		element.vanish = 2.5;
		element:SetScript("OnUpdate", DKCrutch.VanishFrame);
	end

	DKCrutch:SetSwingBarWidth(element, element.elapsed, element.speed, element.maxwidth);
end

function DKCrutch.events.COMBAT_LOG_EVENT_UNFILTERED(timestamp, event, hideCaster, srcGUID, srcName, srcFlags, srcRaidFlags, dstGUID, dstName, dstFlags, dstRaidFlags, spellId, spellName, spellSchool, damage, ...)
	if(DKCrutchDB.enabled) and (srcName == DKCrutch.playerName) then
		DKCrutch:Update()
		if (UnitAffectingCombat("player")) then
			-- enemy count for AoE advise and multiple player in combat (for aggro warning)
			DKCrutch:CountPerson(timestamp, event, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags)
		end
		if (not DKCrutchDB.swingDisable) then
			if ( string.sub(event,1,5) == "SWING" ) and ( srcGUID == UnitGUID("player") ) then
				-- reset the swing frame to 0
				DKCrutch:ResetSwingFrame(DKCrutch.swingFrame);
				DKCrutch.swingFrame:SetScript("OnUpdate", DKCrutch.UpdateSwingFrame);
			  end
		end
	end
end

function DKCrutch.events.PLAYER_TARGET_CHANGED(...)
	if(DKCrutchDB.enabled) then
		DKCrutch:Update()
	end
end

function DKCrutch.events.PLAYER_REGEN_ENABLED(...)
	-- left combat
	DKCrutch.person["friend"] = {}
	DKCrutch.person["friendCount"] = 0
	DKCrutch.person["foe"] = {}
	DKCrutch.person["foeCount"] = 0
	DKCrutch:PurgePersonTable()
end

function DKCrutch.events.PET_BATTLE_OPENING_START(...)
	DKCrutch:ShowHideFrames( false );
end

function DKCrutch.events.PET_BATTLE_OVER(...)
	DKCrutch:ShowHideFrames( true );
end

function DKCrutch:OnLoad()
	local _,playerClass = UnitClass("player")
	if playerClass ~= "DEATHKNIGHT" then
		DKCrutch.eventFrame:UnregisterEvent("PLAYER_ALIVE")
		DKCrutch.eventFrame:UnregisterEvent("ADDON_LOADED")
		return
	end

	DKCrutch.playerGUID = UnitGUID("player")
	DKCrutch.playerName = UnitName("player");

	-- load defaults, if first start
	DKCrutch:InitSettings()
	
	-- create config panel
	DKCrutch:CreateConfig()

	-- add slash command
	SlashCmdList["DKCrutch"] =	function(msg)
		if (msg=='debug') then
			if (DKCrutch.DebugMode) then
				DKCrutch:Debug("Debug ended", GetTime())
			end
			DKCrutch.DebugMode = not ( DKCrutch.DebugMode )
			local debugStatus = "disabled"
			if (DKCrutch.DebugMode) then
				debugStatus = "enabled. Using frame: " .. DKCrutch.DebugChat:GetID()
				DKCrutch:Debug("Debug started", GetTime())
			end
			DEFAULT_CHAT_FRAME:AddMessage("DKCrutch Debug " .. debugStatus)
		else
			DKCrutch:Debug("Config panel ", DKCrutch.configPanel.name)
			InterfaceOptionsFrame_OpenToCategory(DKCrutch.configPanel)
			InterfaceOptionsFrame_OpenToCategory(DKCrutch.configPanel)
		end
	end
	SLASH_DKCrutch1 = "/dkc"
	
	-- check if talent is elemental
	DKCrutch:detectTalent()

	-- register events
	DKCrutch.eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	DKCrutch.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	DKCrutch.eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
	DKCrutch.eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	DKCrutch.eventFrame:RegisterEvent("RUNE_POWER_UPDATE")
	DKCrutch.eventFrame:RegisterEvent("RUNE_TYPE_UPDATE")
	DKCrutch.eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	DKCrutch.eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	DKCrutch.eventFrame:RegisterEvent("PET_BATTLE_OPENING_START")
	DKCrutch.eventFrame:RegisterEvent("PET_BATTLE_OVER")

	DKCrutch:CreateGUI()
	DKCrutch:ApplySettings()

	DEFAULT_CHAT_FRAME:AddMessage("DKCrutch " .. DKCrutch.versionNumber .. " loaded")
end

function DKCrutch:GetDebugFrame()
	for i=1,NUM_CHAT_WINDOWS do
		local windowName = GetChatWindowInfo(i);
		if windowName == "DkcDBG" then
			return getglobal("ChatFrame" .. i)
		end
	end
	return DEFAULT_CHAT_FRAME
end

function DKCrutch:Debug(statictxt,msg)
	if (DKCrutch.DebugMode) and (DKCrutch.DebugChat) then
		if (msg) then
			DKCrutch.DebugChat:AddMessage( statictxt  .. " : " .. msg)
		else
			DKCrutch.DebugChat:AddMessage( statictxt  .. " : " .. "<nil>")
		end
	end
end

function DKCrutch:detectTalent()
	local spec = GetSpecialization()

	if (spec == 1) then
		DKCrutch.talent = "blood"
	end
	if (spec == 2) then
		DKCrutch.talent = "frost"
	end
	if (spec == 3) then
		DKCrutch.talent = "unholy"
	end

	if (spec == nil) then
		DKCrutch.talentUnsure = true
	else
		DKCrutch:adjustDeathTracker()
		DKCrutch.talentUnsure = false
	end
end

function DKCrutch:RemoveFromTables(guid)
	if (DKCrutch.person["friend"][guid]) and (DKCrutch.person["friend"][guid] ~= 0) then
		DKCrutch.person["friend"][guid] = 0
		DKCrutch.person["friendCount"] = DKCrutch.person["friendCount"] - 1
	end
	if (DKCrutch.person["foe"][guid]) and (DKCrutch.person["foe"][guid] ~= 0) then
		DKCrutch.person["foe"][guid] = 0
		DKCrutch.person["foeCount"] = DKCrutch.person["foeCount"] - 1
	end
end

function DKCrutch:PurgePersonTable()
	for i,v in pairs(DKCrutch.person["foe"]) do
		if ( ( GetTime() - DKCrutch.person["foe"][i] ) > 3) then
			-- no activity from that unit in last 2 seconds, remove it
			if ( DKCrutch.person["foe"][i] ~= 0) then
				DKCrutch.person["foe"][i] = 0	-- mark as inactive
				DKCrutch.person["foeCount"] = DKCrutch.person["foeCount"] - 1
			end
		end
	end
	for i,v in pairs(DKCrutch.person["friend"]) do
		if ( ( GetTime() - DKCrutch.person["friend"][i] ) > 3) then
			-- no activity from that unit in last 2 seconds, remove it
			if ( DKCrutch.person["friend"][i] ~= 0 ) then
				DKCrutch.person["friend"][i] = 0	-- mark as inactive
				DKCrutch.person["friendCount"] = DKCrutch.person["friendCount"] - 1
			end
		end
	end
	DKCrutch.person["lastPurged"] = GetTime()
end

function DKCrutch:CountPerson(time, event, sguid, sname, sflags, dguid, dname, dflags)
	local suffix = event:match(".+(_.-)$")
	if DKCrutch.HostileFilter[suffix] then
		local stype = 0;
		local dtype = 0;
		
		if (sguid) and (sguid:sub(5,5)) and (tonumber(sguid:sub(5,5), 16)) then
			stype = (tonumber(sguid:sub(5,5), 16)) % 8;
		end
		if (dguid) and (dguid:sub(5,5)) and (tonumber(dguid:sub(5,5), 16)) then
			dtype = (tonumber(dguid:sub(5,5), 16)) % 8;
		end
		if (bit.band(dflags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE) and (bit.band(dflags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) and ((dtype==0) or (dtype==3)) then
			if ((not DKCrutch.person["foe"][dguid]) or (DKCrutch.person["foe"][dguid]==0)) then
				DKCrutch.person["foeCount"] = DKCrutch.person["foeCount"] + 1
				DKCrutch:Debug('Foe Added:', dguid)
			end
			DKCrutch.person["foe"][dguid] = GetTime()
    	elseif (bit.band(sflags, COMBATLOG_OBJECT_REACTION_HOSTILE) == COMBATLOG_OBJECT_REACTION_HOSTILE) and (bit.band(sflags, COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) == COMBATLOG_OBJECT_AFFILIATION_OUTSIDER) and ((stype==0) or (stype==3)) then
			if ((not DKCrutch.person["foe"][sguid]) or (DKCrutch.person["foe"][sguid]==0)) then
				DKCrutch.person["foeCount"] = DKCrutch.person["foeCount"] + 1
				DKCrutch:Debug('Foe Added:', sguid)
			end
			DKCrutch.person["foe"][sguid] = GetTime()
		end
		if (bit.band(dflags, COMBATLOG_OBJECT_REACTION_FRIENDLY) == COMBATLOG_OBJECT_REACTION_FRIENDLY) and ((dtype==0) or (dtype==3)) then
			if ((not DKCrutch.person["friend"][dguid]) or (DKCrutch.person["friend"][dguid]==0)) then
				DKCrutch.person["friendCount"] = DKCrutch.person["friendCount"] + 1
			end
			DKCrutch.person["friend"][dguid] = GetTime()
    	elseif (bit.band(sflags, COMBATLOG_OBJECT_REACTION_FRIENDLY) == COMBATLOG_OBJECT_REACTION_FRIENDLY) and ((stype==0) or (stype==3)) then
			if ((not DKCrutch.person["friend"][sguid]) or (DKCrutch.person["friend"][sguid]==0)) then
				DKCrutch.person["friendCount"] = DKCrutch.person["friendCount"] + 1
			end
			DKCrutch.person["friend"][sguid] = GetTime()
		end
	end
	if (DKCrutch.person["lastPurged"] < (GetTime() - 3)) and (DKCrutch.person["foeCount"]>0) then
		DKCrutch:PurgePersonTable()
	end
end

function DKCrutch:InitSettings()
	if not DKCrutchDB then 
		DKCrutchDB = {} -- fresh start
		DKCrutch:ResetDB(true)
	end
	DKCrutch:ResetDB(false)
end

function DKCrutch:hasDeBuff(unit, spellName, casterUnit)
	local i = 1
	while true do
		local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable = UnitDebuff(unit, i)
		if not name then
			break
		end
		if (name) and (spellName) then
			if string.match(name, spellName) and ((unitCaster == casterUnit) or (casterUnit == nil)) then
				return name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable
			end
		end
		i = i + 1
	end
end

function DKCrutch:hasBuff(unit, spellName, stealableOnly, getByID)
	local _
	local i = 1
	while true do
		local name, rank, icon, count, buffType, duration, expirationTime, source, isStealable, _, spellId, _, _, v1, v2 = UnitBuff(unit, i)
		if not name then
			break
		end
		if (not getByID) and (name) and (spellName) then
			if string.match(name, spellName) then
				if (not stealableOnly) or (isStealable) then
					return name, rank, icon, count, buffType, duration, expirationTime, unitCaster, isStealable, v1, v2
				end
			end
		else
			if (getByID == spellId) then
				return name, rank, icon, count, buffType, duration, expirationTime, unitCaster, isStealable, v1, v2
			end
		end
		i = i + 1
	end
end

function DKCrutch:GetSpellCooldownRemaining(spell)
	local s, d, _ = GetSpellCooldown(spell)
	local duration = 0
	if (d) and (d>0) then
		duration = s - GetTime() + d
	end

	return duration, s, d
end

function DKCrutch:HasSetBonus(spellID,minCount)
	local slotId, _, itemId, i, setCount

	setCount = 0;
	
	if (DKCrutch.ArmorSets[spellID]) then
	
		local CheckInventoryID = {
			(GetInventorySlotInfo("HeadSlot")),
			(GetInventorySlotInfo("ShoulderSlot")),
			(GetInventorySlotInfo("ChestSlot")),
			(GetInventorySlotInfo("HandsSlot")),
			(GetInventorySlotInfo("LegsSlot")),
		}
		for i=1,5,1 do
			itemId = GetInventoryItemID("player", CheckInventoryID[i]);
			if (DKCrutch.ArmorSets[spellID][itemId]) then
				setCount = setCount + 1;
			end
		end
	end
	
	return (setCount >= minCount);
end

function DKCrutch:ProcIcon(name,icon,d,e,value)
	if (name) then
		if (DKCrutch.lastProc ~= icon) then
			DKCrutch.lastProc = icon
			DKCrutch.procFrame.texture:SetTexture( icon )
			DKCrutch.procFrame:SetAlpha(DKCrutchDB.proc.alpha)
			if (DKCrutch.locked) then
				DKCrutch.procFrame:SetBackdropColor(0, 0, 0, 0)
			else
				DKCrutch.procFrame:SetBackdropColor(0, 0, 0, .3)
			end
		end
		DKCrutch.procFrame:SetCooldown( e-d, d)
		if (value == "") then
			DKCrutch.procText:SetText( "" )
		else
			if (value<1000) then
				DKCrutch.procText:SetText( value )
			else
				if (value<100000) then
					DKCrutch.procText:SetText( format('%.1f',value/1000) .. "K" )
				else
					DKCrutch.procText:SetText( format('%.0f',value/1000) .. "K" )
				end
			end
			DKCrutch.procFrame:SetAlpha(DKCrutchDB.proc.alpha)
		end
	end
	if (not name) and (DKCrutch.lastProc ~= "") then
		DKCrutch.procFrame.texture:SetTexture( "" )
		DKCrutch.procFrame:SetAlpha(DKCrutchDB.proc.alpha)
		if (DKCrutch.locked) then
			DKCrutch.procFrame:SetBackdropColor(0, 0, 0, 0)
		else
			DKCrutch.procFrame:SetBackdropColor(0, 0, 0, .3)
		end
		DKCrutch.procFrame:SetCooldown( 0,0 )
		DKCrutch.procText:SetText( "" )
		DKCrutch.lastProc=""
	end
end

function DKCrutch:AdviseAbility( hasTarget )
	local _,name,icon,count,d,e
	
	if (DKCrutch.talentUnsure) then
		DKCrutch:detectTalent()
	end
	if (DKCrutch.talent == "unholy") then
		if (InCombatLockdown() and hasTarget) then
			-- show shadow infusion count or Dark Transformation CD
			if (not DKCrutchDB.procDisabled) then
				name,_,icon,count,_,d,e = DKCrutch:hasBuff("pet", DKCrutch.SpellList["Dark Transformation"])
				if (name) then
					DKCrutch:ProcIcon(name,icon,d,e,"")
				else
					name,_,icon,count,_,d,e = DKCrutch:hasBuff("pet", DKCrutch.SpellList["Shadow Infusion"])
					DKCrutch:ProcIcon(name,icon,d,e,count)
				end
				if (not name) and (DKCrutch.lastProc ~= "") then
					DKCrutch:ProcIcon(false)
				end
			end
			return DKCrutch:AdviseUnholyAbility()
		else
			-- check presence
			if (not DKCrutch:hasBuff("player", DKCrutch.SpellList["Unholy Presence"])) then
				return "Unholy Presence"
			end
			-- check pet status
			local cd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Raise Dead"])
			if (cd<=0) and (PetHasActionBar() ~= 1) and (not IsMounted()) then
				return "Raise Dead"
			end
		end
	end
	if (DKCrutch.talent == "frost") then
		-- killing machine proc
		if (not DKCrutchDB.procDisabled) then
			name,_,icon,_,_,d,e = DKCrutch:hasBuff("player", DKCrutch.SpellList["Killing Machine"])
			if (name) then
				DKCrutch:ProcIcon(name,icon,d,e,"")
			end
			if (not name) and (DKCrutch.lastProc ~= "") then
				DKCrutch:ProcIcon(false)
			end
		end
		if (InCombatLockdown() and hasTarget) then
			if (DKCrutch.dualWield) then
				return DKCrutch:AdviseFrostAbilityDW()
			else
				return DKCrutch:AdviseFrostAbility()
			end
		else
			-- check presence
			if (not DKCrutch:hasBuff("player", DKCrutch.SpellList["Frost Presence"])) then
				return "Frost Presence"
			end
		end
	end
	if (DKCrutch.talent == "blood") then
		-- killing machine proc
		if (not DKCrutchDB.procDisabled) then
			name,_,icon,_,_,d,e,_,_,_,value = DKCrutch:hasBuff("player", DKCrutch.SpellList["Blood Shield"])
			if (name) then
				DKCrutch:ProcIcon(name,icon,d,e,value)
			end
			if (not name) and (DKCrutch.lastProc ~= "") then
				DKCrutch:ProcIcon(false)
			end
		end
		if (InCombatLockdown() and hasTarget) then
			return DKCrutch:AdviseBloodAbility()
		else
			-- check presence
			if (not DKCrutch:hasBuff("player", DKCrutch.SpellList["Blood Presence"])) then
				return "Blood Presence"
			end
		end
	end

	return ""
end

function DKCrutch:AdviseBloodAbility()
	-- spell advisor
	local spell = ""
	local obcd, cd

	-- check disease cooldowns
	local ffName, _, _, _, _, _, ffExpiration, ffUnitCaster = DKCrutch:hasDeBuff("target", DKCrutch.SpellList["Frost Fever"], "player")
	local bpName, _, _, _, _, _, bpExpiration, bpUnitCaster = DKCrutch:hasDeBuff("target", DKCrutch.SpellList["Blood Plague"], "player")
	if (not ffExpiration) then
		ffExpiration = 0
	end
	if (not bpExpiration) then
		bpExpiration = 0
	end
	
	-- Refresh diseases with Blood Boil if available
	cd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Blood Boil"])
	if (cd) and (cd<=0) and (IsUsableSpell(DKCrutch.SpellList["Outbreak"], "target") == 1) then
		if ( ( (ffExpiration - GetTime()) <5) or ( (bpExpiration - GetTime()) < 5) ) and ( ( (ffExpiration - GetTime()) > 1) and ( (bpExpiration - GetTime()) > 1) ) then
			return "Blood Boil"
		end
	end	

	-- 	outbreak if frost fever or blood plague less than 2 sec remaining
	obcd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Outbreak"])
	if (obcd) and (obcd<=0) and (IsSpellInRange(DKCrutch.SpellList["Outbreak"], "target") == 1) then
		if ( (ffExpiration - GetTime()) <2) or ( (bpExpiration - GetTime()) < 2) then
			return "Outbreak"
		end
	end
	
	-- icy touch
	cd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Icy Touch"])
	if (cd<=0) and ( IsSpellInRange(DKCrutch.SpellList["Icy Touch"],"target") == 1) then
		if ( (ffExpiration - GetTime()) <3) then
			return "Icy Touch"
		end
	end
	
	-- plague strike
	cd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Plague Strike"])
	if (cd) and (cd<=0) and ( IsSpellInRange(DKCrutch.SpellList["Plague Strike"],"target") == 1) then
		if ( (bpExpiration - GetTime()) <3) then
			return "Plague Strike"
		end
	end

	-- Blood Tap if have at least 5 charges, and at least on fully depleted rune
	if (DKCrutch.SpellList["Blood Tap"]) then
		local name,_,_,count = DKCrutch:hasBuff("player", DKCrutch.SpellList["Blood Charge"])
		if (count) and (count>=5) and (DKCrutch.depletedCount>0) then
			return "Blood Tap"
		end
	end

	-- Plague Leech if Outbreak available, and have on fully depleted rune
	if (DKCrutch.SpellList["Plague Leech"]) then
		if (obcd) and (obcd<=0) and (IsSpellInRange(DKCrutch.SpellList["Outbreak"], "target") == 1) and (DKCrutch.depletedCount>0) then
			if (DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Plague Leech"]) <= 1) then
				return "Plague Leech"
			end
		end
	end

	-- Death Strike if available
	cd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Death Strike"])
	if (cd) and (cd<=1) then
		return "Death Strike"
	end

	-- Heart Strike if available, and at least 1 blood runes is up
	cd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Heart Strike"])
	if (cd) and (cd<=1) and (IsUsableSpell(DKCrutch.SpellList["Heart Strike"])) and (DKCrutch.runesUp[1]>=1) then
		return "Heart Strike"
	end

	-- Rune Strike if available
	cd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Rune Strike"])
	if (cd) and (cd<=1) and (IsUsableSpell(DKCrutch.SpellList["Rune Strike"])) then
		local _, _, _, cost = GetSpellInfo(DKCrutch.SpellList["Rune Strike"])
		if (UnitPower("player", 6) >= cost) then
			return "Rune Strike"
		end
	end

	return ""
end

function DKCrutch:AdviseFrostAbilityDW() -- Frost DK DualWield priority
	-- spell advisor
	local spell = ""
	local obcd,cd,enabled,_

	-- Pillar of Frost if not on CD
	cd, _, enabled = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Pillar of Frost"])
	if (enabled ~= nil) and (cd) and (cd<=1) then
		return "Pillar of Frost"
	end

	-- raise dead if not on cd and has Rune of the Fallen Crusader buff
	cd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Raise Dead"])
	if (cd) and (cd<=0) and (DKCrutch:hasBuff("player", DKCrutch.SpellList["Unholy Strength"])) then
		return "Raise Dead"
	end
	
	-- Priority 1: Diseases
	-- outbreak if frost fever or blood plague less than 2 sec remaining
	local ffName, _, _, _, _, _, ffExpiration, ffUnitCaster = DKCrutch:hasDeBuff("target", DKCrutch.SpellList["Frost Fever"], "player")
	local bpName, _, _, _, _, _, bpExpiration, bpUnitCaster = DKCrutch:hasDeBuff("target", DKCrutch.SpellList["Blood Plague"], "player")
	if (not ffExpiration) then
		ffExpiration = 0
	end
	if (not bpExpiration) then
		bpExpiration = 0
	end
	obcd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Outbreak"])
	if (obcd) and (obcd<=0) and (IsSpellInRange(DKCrutch.SpellList["Outbreak"], "target") == 1) then
		if ( (ffExpiration - GetTime()) <2) or ( (bpExpiration - GetTime()) < 2) then
			return "Outbreak"
		end
	end

	-- howling blast
	local hbcd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Howling Blast"])
	if (hbcd) and (hbcd<=0) and ( IsSpellInRange(DKCrutch.SpellList["Howling Blast"],"target") == 1) then
		if ( (ffExpiration - GetTime()) <3) then
			return "Howling Blast"
		end
	end
	
	-- plague strike
	cd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Plague Strike"])
	if (cd) and (cd<=0) and ( IsSpellInRange(DKCrutch.SpellList["Plague Strike"],"target") == 1) then
		if ( (bpExpiration - GetTime()) <3) then
			return "Plague Strike"
		end
	end

	-- Priority 2: Soul Reaper
	-- Soul Reaper, if target health < 35%, or 45% if has t15 4pcs
	if (DKCrutch.SpellList["Soul Reaper"]) then
		cd, _, enabled = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Soul Reaper"])
		if (enabled ~= nil) and (cd) and (cd<=0) and (UnitHealthMax("target")>0) and ((UnitHealth("target")/UnitHealthMax("target")<0.35) or ((UnitHealth("target")/UnitHealthMax("target")<0.45) and (DKCrutch.hasT15_4pcs))) then
			return "Soul Reaper"
		end
	end

	-- Blood Tap if have at least 5 charges, and at least on fully depleted rune
	if (DKCrutch.SpellList["Blood Tap"]) then
		local name,_,_,count = DKCrutch:hasBuff("player", DKCrutch.SpellList["Blood Charge"])
		if (count) and (count>=5) and (DKCrutch.depletedCount>0) then
			return "Blood Tap"
		end
	end

	-- Plague Leech if Outbreak available, and have on fully depleted rune
	if (DKCrutch.SpellList["Plague Leech"]) then
		if (obcd) and (obcd<=0) and (IsSpellInRange(DKCrutch.SpellList["Outbreak"], "target") == 1) and (DKCrutch.depletedCount>0) then
			if (DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Plague Leech"]) <= 1 ) then
				return "Plague Leech"
			end
		end
	end

	-- Priority 3: Frost Strike
	-- Frost Strike if Killing Machine Procs OR Runic Power >= 90
	local fscd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Frost Strike"])
	if (fscd) and (fscd <= 1) and (DKCrutch:hasBuff("player", DKCrutch.SpellList["Killing Machine"]) or (UnitPower("player", 6) >= 90)) then
		local _, _, _, cost = GetSpellInfo(DKCrutch.SpellList["Frost Strike"])
		if (UnitPower("player", 6) >= cost) then
			return "Frost Strike"
		end
	end

	-- Priority 4: Howling Blast if Rime proc
	-- Howling Blast if Freezing Fog proc (Rime)
	if (hbcd) and (hbcd <= 1) and (
		(DKCrutch:hasBuff("player", DKCrutch.SpellList["Freezing Fog"])) or
		((DKCrutch.runesUp[4] == 0) and (DKCrutch.runesUp[2] == 0))
	) then
		return "Howling Blast"
	end

	-- Priority 5: Obliterate
	-- Obliterate: if 2 death/unholy runes are up OR
	-- 1 unholy UP and frost and death<2 OR
	-- Killing Machine Procs  AND runic power>=35
	local obcd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Obliterate"])
	if ((DKCrutch.runesUp[4] == 2) or (DKCrutch.runesUp[2] == 2)) or
		((DKCrutch.runesUp[2] == 1) and (DKCrutch.runesUp[4] < 2) and (DKCrutch.runesUp[3] < 2)) or
	 	(DKCrutch:hasBuff("player", DKCrutch.SpellList["Killing Machine"]) and (UnitPower("player", 6) >= 35))  then
		if (obcd) and (obcd <= 1) then
			return "Obliterate"
		end
	end

	-- Howling Blast
	if (hbcd) and (hbcd <= 1) then
		return "Howling Blast"
	end

	-- Frost Strike
	if (fscd) and (fscd <= 1) and (IsUsableSpell(DKCrutch.SpellList["Frost Strike"])) then
		local _, _, _, cost = GetSpellInfo(DKCrutch.SpellList["Frost Strike"])
		if (UnitPower("player", 6) >= cost) then
			return "Frost Strike"
		end
	end

	-- Horn of Winter
	cd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Horn of Winter"])
	if (cd) and (cd <= 1) then
		return "Horn of Winter"
	end

	return ""
end

function DKCrutch:AdviseFrostAbility()
	-- spell advisor
	local spell = ""
	local obcd,cd,enabled,_

	-- Pillar of Frost if not on CD
	cd, _, enabled = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Pillar of Frost"])
	if (enabled ~= nil) and (cd) and (cd<=1) then
		return "Pillar of Frost"
	end

	-- raise dead if not on cd and has Rune of the Fallen Crusader buff
	cd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Raise Dead"])
	if (cd) and (cd<=0) and (DKCrutch:hasBuff("player", DKCrutch.SpellList["Unholy Strength"])) then
		return "Raise Dead"
	end
	
	-- outbreak if frost fever or blood plague less than 2 sec remaining
	local ffName, _, _, _, _, _, ffExpiration, ffUnitCaster = DKCrutch:hasDeBuff("target", DKCrutch.SpellList["Frost Fever"], "player")
	local bpName, _, _, _, _, _, bpExpiration, bpUnitCaster = DKCrutch:hasDeBuff("target", DKCrutch.SpellList["Blood Plague"], "player")
	if (not ffExpiration) then
		ffExpiration = 0
	end
	if (not bpExpiration) then
		bpExpiration = 0
	end
	obcd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Outbreak"])
	if (obcd) and (obcd<=0) and (IsSpellInRange(DKCrutch.SpellList["Outbreak"], "target") == 1) then
		if ( (ffExpiration - GetTime()) <2) or ( (bpExpiration - GetTime()) < 2) then
			return "Outbreak"
		end
	end

	-- howling blast
	local hbcd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Howling Blast"])
	if (hbcd) and (hbcd<=0) and ( IsSpellInRange(DKCrutch.SpellList["Howling Blast"],"target") == 1) then
		if ( (ffExpiration - GetTime()) <3) then
			return "Howling Blast"
		end
	end
	
	-- plague strike
	cd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Plague Strike"])
	if (cd) and (cd<=0) and ( IsSpellInRange(DKCrutch.SpellList["Plague Strike"],"target") == 1) then
		if ( (bpExpiration - GetTime()) <3) then
			return "Plague Strike"
		end
	end

	-- Soul Reaper, if target health < 35%, or 45% if has t15 4pcs
	if (DKCrutch.SpellList["Soul Reaper"]) then
		cd, _, enabled = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Soul Reaper"])
		if (enabled ~= nil) and (cd) and (cd<=0) and (UnitHealthMax("target")>0) and ((UnitHealth("target")/UnitHealthMax("target")<0.35) or ((UnitHealth("target")/UnitHealthMax("target")<0.45) and (DKCrutch.hasT15_4pcs))) then
			return "Soul Reaper"
		end
	end

	-- Blood Tap if have at least 5 charges, and at least on fully depleted rune
	if (DKCrutch.SpellList["Blood Tap"]) then
		local name,_,_,count = DKCrutch:hasBuff("player", DKCrutch.SpellList["Blood Charge"])
		if (count) and (count>=5) and (DKCrutch.depletedCount>0) then
			return "Blood Tap"
		end
	end

	-- Plague Leech if Outbreak available, and have on fully depleted rune
	if (DKCrutch.SpellList["Plague Leech"]) then
		if (obcd) and (obcd<=0) and (IsSpellInRange(DKCrutch.SpellList["Outbreak"], "target") == 1) and (DKCrutch.depletedCount>0) then
			if (DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Plague Leech"]) <= 1 ) then
				return "Plague Leech"
			end
		end
	end

	-- Howling Blast if Freezing Fog proc (Rime)
	if (hbcd) and (hbcd <= 1) and (
		(DKCrutch:hasBuff("player", DKCrutch.SpellList["Freezing Fog"])) or
		((DKCrutch.runesUp[4] == 0) and (DKCrutch.runesUp[2] == 0))
	) then
		return "Howling Blast"
	end

	-- Obliterate if runic power<90 OR Killing Machine Proc
	local obcd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Obliterate"])
	if (UnitPower("player", 6) >= 90) or (DKCrutch:hasBuff("player", DKCrutch.SpellList["Killing Machine"]))  then
		if (obcd) and (obcd <= 1) then
			return "Obliterate"
		end
	end

	-- Frost Strike
	local fscd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Frost Strike"])
	if (fscd) and (fscd <= 1) then
		local _, _, _, cost = GetSpellInfo(DKCrutch.SpellList["Frost Strike"])
		if (UnitPower("player", 6) >= cost) then
			return "Frost Strike"
		end
	end

	-- Howling Blast
	if (hbcd) and (hbcd <= 1) then
		return "Howling Blast"
	end

	-- Obliterate
	if (obcd) and (obcd <= 1) then
		return "Obliterate"
	end
	
	-- Horn of Winter
	cd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Horn of Winter"])
	if (cd) and (cd <= 1) then
		return "Horn of Winter"
	end

	return ""
end

function DKCrutch:AdviseUnholyAbility()
	-- spell advisor
	local spell = ""
	local obcd,cd

	-- raise dead if has no pet and raise dead is not on cd
	cd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Raise Dead"])
	if (cd<=0) and (PetHasActionBar() ~= 1) then
		return "Raise Dead"
	end
	
	-- outbreak if frost fever or blood plague less than 2 sec remaining
	local ffName, _, _, _, _, _, ffExpiration, ffUnitCaster = DKCrutch:hasDeBuff("target", DKCrutch.SpellList["Frost Fever"], "player")
	local bpName, _, _, _, _, _, bpExpiration, bpUnitCaster = DKCrutch:hasDeBuff("target", DKCrutch.SpellList["Blood Plague"], "player")
	if (not ffExpiration) then
		ffExpiration = 0
	end
	if (not bpExpiration) then
		bpExpiration = 0
	end
	obcd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Outbreak"])
	if (obcd) and (obcd<=0) and (IsSpellInRange(DKCrutch.SpellList["Outbreak"], "target") == 1) then
		if ( (ffExpiration - GetTime()) <2) or ( (bpExpiration - GetTime()) < 2) then
			return "Outbreak"
		end
	end

	-- plague strike
	cd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Plague Strike"])
	if (cd) and (cd<=0) and ( IsSpellInRange(DKCrutch.SpellList["Plague Strike"],"target") == 1) then
		if ( (bpExpiration - GetTime()) <3) or ( (ffExpiration - GetTime()) <3 ) then
			return "Plague Strike"
		end
	end
	
	-- icy touch
	--[[
	cd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Icy Touch"])
	if (cd<=0) and ( IsSpellInRange(DKCrutch.SpellList["Icy Touch"],"target") == 1) then
		if ( (ffExpiration - GetTime()) <3) then
			return "Icy Touch"
		end
	end
	]]--

	-- Blood Tap if have at least 10 charges, and have >=32 runic power
	if (DKCrutch.SpellList["Blood Tap"]) then
		local name,_,_,count = DKCrutch:hasBuff("player", DKCrutch.SpellList["Blood Charge"])
		if (count) and (count>10) and (DKCrutch.depletedCount>0) and (UnitPower("player", 6) >= 32) then
			return "Blood Tap"
		end
	end

	-- Unholy blight and debuffs are expiring
	if (DKCrutch.SpellList["Unholy Blight"]) then
		cd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Unholy Blight"])
		if (cd) and (cd<=0) and (ffExpiration<3) or (bpExpiration<3) then
			return "Unholy Blight"
		end
	end
	
	-- Soul Reaper, if target health < 35%
	if (DKCrutch.SpellList["Soul Reaper"]) then
		cd, _, enabled = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Soul Reaper"])
		if (enabled ~= nil) and (cd) and (cd<=0) and (UnitHealthMax("target")>0) and ((UnitHealth("target")/UnitHealthMax("target")<0.35) or ((UnitHealth("target")/UnitHealthMax("target")<0.45) and (DKCrutch.hasT15_4pcs))) then
			return "Soul Reaper"
		end
	end

	-- Dark Transform, if has pet and available
	cd, _, enabled = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Dark Transformation"])
	if (enabled ~= nil) and (cd) and (cd<=0) and (IsUsableSpell(DKCrutch.SpellList["Dark Transformation"])) and ( PetHasActionBar() ) then
		return "Dark Transformation"
	end
	
	-- Death Coik if runic power>90
	local dccd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Death Coil"])
	local _, _, _, cost = GetSpellInfo(DKCrutch.SpellList["Death Coil"])
	if (dccd) and (dccd <= 1) and (UnitPower("player", 6) > 90)	then
		return "Death Coil"
	end
	
	-- Scourge strike (or Death and Decay), if 4 death runes are up, or 2 unholy runes are up
	local ddcd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Death and Decay"])
	local sscd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Scourge Strike"])
	if (DKCrutch.runesUp[4] == 4) or (DKCrutch.runesUp[2] == 2) then
		if (ddcd) and (ddcd <= 1) then
			return "Death and Decay"
		else
			if (sscd) and (sscd <= 1) then
				return "Scourge Strike"
			end
		end
	end
	
	-- Blood boil, if AoE
	if (DKCrutch.person["foeCount"]>1) then
		local fscd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Blood Boil"])
		if (fscd) and (fscd <= 1) then
			return "Blood Boil"
		end
	else
	-- Festering Strike if (blood=2 or frost=2)
		local fscd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Festering Strike"])
		if (fscd) and (fscd <= 1) and ( (DKCrutch.runesUp[1] == 2) or (DKCrutch.runesUp[3] == 2) ) then
			return "Festering Strike"
		end
	end

	-- Death coil if Sudden Doom proc, or runic power > 90
	local dccd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Death Coil"])
	local _, _, _, cost = GetSpellInfo(DKCrutch.SpellList["Death Coil"])
	if (dccd) and (dccd <= 1) and (
			(
				(DKCrutch:hasBuff("player", DKCrutch.SpellList["Sudden Doom"])) and
				(UnitPower("player", 6) >= cost)
			)
			or (UnitPower("player", 6) > 90)	
	) then
		return "Death Coil"
	end
	
	-- Scourge Strike
	if (sscd) and (sscd <= 1) then
		return "Scourge Strike"
	end
	
	-- Plague Leech if Outbreak available, and have on fully depleted rune
	if (DKCrutch.SpellList["Plague Leech"]) then
		if (obcd) and (obcd<=0) and (IsSpellInRange(DKCrutch.SpellList["Outbreak"], "target") == 1) and (DKCrutch.depletedCount>0) then
			if (DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Plague Leech"]) <= 1) then
				return "Plague Leech"
			end
		end
	end
	
	-- Festering strike
	if (fscd) and (fscd <= 1) then
		return "Festering Strike"
	end
	
	-- Death Coil
	if (dscd) and (dccd <= 1) and (IsUsableSpell(DKCrutch.SpellList["Death Coil"])) then
		local _, _, _, cost = GetSpellInfo(DKCrutch.SpellList["Death Coil"])
		if (UnitPower("player", 6) >= cost) then
			return "Death Coil"
		end
	end
	
	-- Horn of Winter
	cd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Horn of Winter"])
	if (cd) and (cd <= 1) then
		return "Horn of Winter"
	end
	
	-- Empower Rune Weapon
	cd = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList["Empower Rune Weapon"])
	if (cd) and (cd <= 1) and (DKCrutch.runesUp[2] == 0) then
		return "Empower Rune Weapon"
	end

	return ""
end

function DKCrutch:Update()
	local runeCount = {}
	local _, start, duration, runeReady, runeType, i
	for i=1,4,1 do
		runeCount[i] = 0
		DKCrutch.runesUp[i] = 0
	end
	DKCrutch.depletedCount = 0
	
	DKCrutch:Debug("UPDATE", "")
	for i=1,6,1 do
		start, duration, runeReady = GetRuneCooldown(i)
		runeType = GetRuneType(i)
		if (runeReady) then
			runeCount[runeType] = runeCount[runeType] + 10
			DKCrutch.runesUp[runeType] = DKCrutch.runesUp[runeType] + 1
		else
			if (start) and (start ~= 0) and (GetTime()-start > 0) then
				runeCount[runeType] = runeCount[runeType] + ( ( (GetTime() - start) / duration ) * 10 )
			else
				DKCrutch.depletedCount = DKCrutch.depletedCount + 1
			end
		end
	end
	DKCrutch.deathTracker:SetValue(runeCount[4])
	DKCrutch.runeTracker[1]:SetValue(runeCount[2])
	DKCrutch.runeTracker[2]:SetValue(runeCount[3])
	DKCrutch.runeTracker[3]:SetValue(runeCount[1])

	local guid = UnitGUID("target")
	if  UnitName("target") == nil or UnitIsFriend("player","target") ~= nil or UnitHealth("target") == 0 then
		guid = nil
	end
	
	if ( UnitInVehicle("player") ) then
		-- player is in a "vehicle", or has no target don't suggest abilities
		DKCrutch.advisorFrame.texture:SetTexture("")
		if (DKCrutch.lastD2 ~= "") then
			DKCrutch.debuff2Frame.texture:SetTexture( "" )
			DKCrutch.debuff2Frame:SetCooldown( 0, 0)
			DKCrutch.lastD2 = ""
		end
		if (DKCrutch.lastD1 ~= "") then
			DKCrutch.debuff1Frame.texture:SetTexture( "" )
			DKCrutch.debuff1Frame:SetCooldown( 0, 0)
			DKCrutch.lastD1 = ""
		end
		return
	end
	
	if (not DKCrutchDB.advisorDisabled) then
		local spell = DKCrutch:AdviseAbility( not ((UnitHealth("target") == 0) or (guid == nil)) )
		DKCrutch:Debug("Advised: " .. spell, DKCrutch.SpellList[spell])
		if (spell) and (spell ~= "") then
			local inRange = IsSpellInRange(DKCrutch.SpellList[spell],"target")
			if (inRange) then
				DKCrutch.advisorFrame.texture:SetVertexColor( 0.75 + (inRange * 0.25),1 * inRange,1 * inRange,1)
			end
			if (spell ~= DKCrutch.lastSpell) then
				DKCrutch.advisorFrame.texture:SetTexture( GetSpellTexture(DKCrutch.SpellList[spell]) )
				DKCrutch.lastSpell = spell
			end
			local _, s, d = DKCrutch:GetSpellCooldownRemaining(DKCrutch.SpellList[spell])
			if (d) and (d>0) then
				DKCrutch.cooldownFrame:SetCooldown(s, d)
			end
		else
			if (DKCrutch.lastSpell ~= "") then
				DKCrutch.advisorFrame.texture:SetTexture( "" )
				DKCrutch.cooldownFrame:SetCooldown(-1, 0)
				DKCrutch.lastSpell = spell
			end
		end
	end
	if (not DKCrutchDB.runicDisabled) then
		local size = 1
		local max = UnitPowerMax("player", 6)
		local current = UnitPower("player", 6)
		if (current == 0) then
			if (DKCrutch.lastGlow) then
				DKCrutch.lastGlow = false
				DKCrutch.runicFrame.texture:SetTexture("Interface\\AddOns\\DKCrutch\\media\\runic_power.tga", false)
			end
			DKCrutch.runicFrame.texture:SetTexCoord( 0, 0, 0, 0 );
		else
			if (not DKCrutch.lastGlow) then
				if (current == max) then
					DKCrutch.lastGlow = true
					DKCrutch.runicFrame.texture:SetTexture("Interface\\AddOns\\DKCrutch\\media\\runic_power_glow.tga", false)
				end
			else
				if (current < max) then
					DKCrutch.lastGlow = false
					DKCrutch.runicFrame.texture:SetTexture("Interface\\AddOns\\DKCrutch\\media\\runic_power.tga", false)
				end
			end
			size = (max / current)
			DKCrutch.runicFrame.texture:SetTexCoord( 1-size, 1-size, 1-size, size, size, 1-size, size, size);
		end
		
		local name ,_ , _, count = DKCrutch:hasBuff("player", DKCrutch.SpellList["Blood Charge"]);
		if (name) then
			if (count ~= DKCrutch.lastBloodCharge) then
				local x,y
			
				DKCrutch.lastBloodCharge = count;
			
				y = math.floor(count / 4);
				x = count - (y * 4);
		
				DKCrutch:Debug("X,Y: " .. x, y);
				DKCrutch.bloodFrame.texture:SetTexCoord(x / 4, (x / 4) + 0.25, y / 4, (y / 4) + 0.25);
			end
		else
			if (DKCrutch.lastBloodCharge ~= 0) then
				DKCrutch.lastBloodCharge = 0;
				DKCrutch.bloodFrame.texture:SetTexCoord(0, 0.25, 0, 0.25);
			end
		end
	end
	if (not DKCrutchDB.debuffDisabled) then
		local name, _, icon, _, _, d, e = DKCrutch:hasDeBuff("target", DKCrutch.SpellList["Frost Fever"], "player")
		if (name) and (icon) then
			if (DKCrutch.lastD1 ~= icon) then
				DKCrutch.debuff1Frame.texture:SetTexture( icon )
				DKCrutch.lastD1 = icon
			end
			DKCrutch.debuff1Frame:SetCooldown( e-d, d)
		else
			if (DKCrutch.lastD1 ~= "") then
				DKCrutch.debuff1Frame.texture:SetTexture( "" )
				DKCrutch.debuff1Frame:SetCooldown( 0, 0)
				DKCrutch.lastD1 = ""
			end
		end
		name, _, icon, _, _, d, e = DKCrutch:hasDeBuff("target", DKCrutch.SpellList["Blood Plague"], "player")
		if (name) and (icon) then
			if (DKCrutch.lastD2 ~= icon) then
				DKCrutch.debuff2Frame.texture:SetTexture( icon )
				DKCrutch.lastD2 = icon
			end
			DKCrutch.debuff2Frame:SetCooldown( e-d, d)
		else
			if (DKCrutch.lastD2 ~= "") then
				DKCrutch.debuff2Frame.texture:SetTexture( "" )
				DKCrutch.debuff2Frame:SetCooldown( 0, 0)
				DKCrutch.lastD2 = ""
			end
		end
	end
	if (not DKCrutchDB.weaponDisabled) then
		name, _, icon, _, _, d, e = DKCrutch:hasBuff("player", DKCrutch.SpellList["Unholy Strength"])
		if (name) and (e - GetTime()>0) then
			if (DKCrutch.weaponText:GetText() == "") then
				DKCrutch.weaponFrame:SetMinMaxValues(0, d)
			end
			DKCrutch.weaponText:SetText("F. C.: (" .. format('%.f',e-GetTime()) .. ")")
			DKCrutch.weaponFrame:SetValue( e - GetTime() )
		else
			if (DKCrutch.weaponFrame:GetValue() ~= 0) then
				DKCrutch.weaponFrame:SetValue(0)
				DKCrutch.weaponText:SetText("")
			end
		end
	end
end

function DKCrutch:OnUpdate(elapsed)
	if (DKCrutchDB.enabled) then
		if (GetTime() - DKCrutch.lastUpdate > 0.5) then
			DKCrutch.lastUpdate = GetTime();
			DKCrutch:Update();
		end
	end
end
