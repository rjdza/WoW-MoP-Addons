if not TMW then return end

TMW.CHANGELOG = {

[==[===v7.0.0===]==],
[==[* You can now create groups that exist for all characters on your account. These groups can be enabled and disabled on a per-profile basis. Changes made to these groups will be reflected for any character that they are enabled for.]==],
[==[* Text Layouts are now defined on an account-wide basis instead of being defined for individual profiles.]==],
[==[]==],
[==[* All references from one icon or group to another in TellMeWhen are now tracked by a unique ID. This ID will persist no matter where it is moved or exported to.]==],
[==[** This includes:]==],
[==[*** DogTags]==],
[==[*** Meta icons]==],
[==[*** Icon Shown conditions (and the other conditions that track icons)]==],
[==[*** On Icon Show/On Icon Hide icon events]==],
[==[*** Group anchoring to other groups]==],
[==[** The consequence of this is that you can now, for example, import/export a meta icon separately from the icons it is checking and they will automatically find eachother once they are all imported (as long as these export strings were created with TMW v7.0.0+)]==],
[==[** IMPORTANT: Existing DogTags that reference other icons/groups by ID cannot be updated automatically - you will need to change these yourself.]==],
[==[]==],
[==[* TellMeWhen_Options now maintains a backup of TellMeWhen's SavedVariables that will be restored if TellMeWhen's SVs become corrupted.]==],
[==[]==],
[==[* Global Cooldowns are now only filtered for icon types that can track things on the global cooldown.]==],
[==[* The Combat Event icon unit exclusion "Miscellaneous: Unknown Unit" will now also cause events that were fired without a unit to be excluded.]==],
[==[* The meta icon setting "Inherit failed condition opacity" has been removed. Meta icons will now always inherit the exact opacity of the icons they are showing, though this can be overridden by the meta icon's opacity settings.]==],
[==[* Complex chains of meta icon inheritance should now be handled much better, especially when some of the icons have animations on them.]==],
[==[]==],
[==[* The duration of Diminishing Returns is now customizable in TMW's main options.]==],
[==[* You can now right-click-and-drag the group resize handle to easily change the number of rows and columns of a group.]==],
[==[* Added group settings that allow you to specify when a group should be shown based on the role that your current specialization fulfills.]==],
[==[* You can now enter "none" or "blank" as a custom texture for an icon to force it to display no texture.]==],
[==[* New Condition: Specialization Role]==],
[==[* The Buff/Debuff - "Number of" conditions now accept semicolon-delimited lists of multiple auras that should be counted.]==],
[==[]==],
[==[* Exporting a meta icon will also export the string(s) of its component icons.]==],
[==[* Exporting groups and icons will also export the string(s) of their text layouts.]==],
[==[]==],
[==[* Various updates to many buff/debuff equivalencies.]==],
[==[* New buff equivalency: SpeedBoosts]==],
[==[]==],
[==[* In the wake of the recent distribution of malicious scripts to WeakAuras users, TellMeWhen now warns you about importing executable Lua code.]==],
[==[* Code snippets can now be disabled from autorunning at login.]==],
[==[* Dramatically decreased memory usage, especially for icons that have no icon type assigned.]==],
[==[* You can now use "thisobj" in Lua conditions as a reference to the icon or group that is checking the conditions.]==],
[==[]==],
[==[* Bug Fixes:]==],
[==[** Units tracked by name with spaces in them (E.g. Kor'kron Warbringer as a CLEU unit filter) will now be interpreted properly as input.]==],
[==[*** IMPORTANT: A consequence of this fix is that if you are enter a unit like "boss 1", this will no longer work. You need to enter "boss1", which has always been the proper unitID.]==],
[==[** Importing/Exporting icons from/to strings with hyperlinks in some part of the icon's data will now preserve the hyperlink.]==],
[==[** Icons should now always have the correct size after their view changes or the size or ID of a group changes.]==],
[==[** Fixed an issue where strings imported from older version of TellMeWhen (roughly pre-v6.0.0) could have their StackMin/Max and DurationMin/Max settings as strings instead of numbers.]==],
[==[** The "Equipment set equipped" condition should properly update when saving the equipment set that is currently equipped.]==],
[==[** Fixed an issue when upgrading text layouts that could also cause them to not be upgraded at all: /Components/IconModules/IconModule_Texts/Texts.lua line 205: attempt to index field 'Anchors' (a nil value)]==],
[==[** Currency conditions should once again be listed in the condition type selection menu.]==],
[==[** The NPC ID condition should now work correctly with npcIDs that are greater than 65535 (0xFFFF).]==],
[==[]==],
[==[===v6.2.6===]==],
[==[* Bug Fixes:]==],
[==[** Added a hack to ElvUI's timer texts so that they will once again obey the setting in TellMeWhen. Previously, they would be enabled for all icons because of a change made by ElvUI's developers.]==],
[==[** Spell Cooldown icons that are tracking by spellID instead of by name should once again reflect spell charges properly (this functionality was disrupted by a bug introduced by Blizzard in patch 5.4).]==],
[==[]==],
[==[===v6.2.5===]==],
[==[* ElvUI's timer texts are once again supported by TellMeWhen.]==],
[==[]==],
[==[===v6.2.4===]==],
[==[* Added DogTags for string.gsub and string.find.]==],
[==[* Added Yu'lon's Barrier to the DamageShield equivalency.]==],
[==[]==],
[==[* Bug Fixes:]==],
[==[** IconModule_Alpha/Alpha.lua:84: attempt to index local "IconModule_Alpha" (a nil value)]==],
[==[** Rune icons will now behave properly when no runes are found that match the types configured for the icon.]==],
[==[** The Banish loss of control type was accidentally linked to the Fear loss of control type - this has been fixed.]==],
[==[** Unit cooldown icons should now attempt to show the first usable spell even if no units being checked have casted any spells yet.]==],
[==[]==],
[==[===v6.2.3===]==],
[==[* IMPORTANT: The color settings for all timer bars (including bar group and timer overlay bars) have changed a bit:]==],
[==[** The labels for these settings now correctly correspond to the state that they will be used for.]==],
[==[** The colors will automatically switch when you enable the "Fill bar up" setting for a bar.]==],
[==[** These changes will probably require you to reconfigure some of your settings.]==],
[==[]==],
[==[* Icons in groups that use the Bar display method can now have their colors configured on a per-icon basis.]==],
[==[** You can copy colors between icons by right-click dragging one icon to another.]==],
[==[]==],
[==[* TellMeWhen now uses a coroutine-based update engine to help prevent the occasional "script ran too long" error.]==],
[==[** This version also includes an updated LibDogTag-3.0 and LibDogTag-Unit-3.0 that should no longer throw "script ran too long" errors.]==],
[==[]==],
[==[* Bug Fixes:]==],
[==[** Removed the "Snared" Loss of Control category from the configuration since it is most certainly not used by Blizzard.]==],
[==[** Item-tracking icons and condition should now always get the correct data once it becomes available.]==],
[==[]==],
[==[===v6.2.2===]==],
[==[* Buff/Debuff icons can now sort by stacks.]==],
[==[* The group sorting option to sort by duration now treats spells that are on the GCD as having no cooldown.]==],
[==[]==],
[==[* Added a few more popup notifications when invalid settings/actions are entered/performed.]==],
[==[* Icons will now be automatically enabled when you select an icon type.]==],
[==[* Incorporated LibDogTag-Stats-3.0 into TellMeWhen's various implementations of LibDogTag-3.0.]==],
[==[* The Mastery condition now uses GetMasteryEffect() instead of GetMastery(). The condition will now be comparable to the total percentage increase granted by mastery instead of the value that has to be multiplied by your spec's mastery coefficient (which is no longer shown in Blizzard's character sheet.)]==],
[==[* TMWOptDB now uses AceDB-3.0. One benefit of this is that the suggestion list will now always be locale-appropriate.]==],
[==[* The suggestion list for units is now much more useful.]==],
[==[* The suggestion list now has a warning in the tooltip when inserting spells that interfere with the names of equivalencies.]==],
[==[* The suggestion list now pops up a help message the first time it is shown.]==],
[==[* You can now copy an icon's events and conditions by right-click-dragging the icon to another icon.]==],
[==[** You can also copy group conditions between groups this way.]==],
[==[* When right-click-dragging an icon to an icon that has multiple icons in the same place, you can now choose which one you would like the destination to be.]==],
[==[]==],
[==[* Bug Fixes:]==],
[==[** Buff/Debuff icons that are set to sort by low duration should now properly display unlimited duration auras when there is nothing else to display.]==],
[==[** The Ranged Attack Power condition should now always use the proper RAP value.]==],
[==[** Fixed some "You are not in a raid group" errors.]==],
[==[** All features in TellMeWhen that track items (including Item Cooldown icons and any item conditions) are universally able to accept slotIDs as input, and all features will now correctly distinguished equipped items from items in your bag when tracking by slotID. This is the result of a new, robust system for managing items.]==],
[==[]==],
[==[===v6.2.0===]==],
[==[* New Icon Type: Buff/Debuff Check (for checking missing raid buffs).]==],
[==[* New advanced feature: Lua Snippets]==],
[==[* New advanced icon event handler: Lua Execution]==],
[==[]==],
[==[* Mass refactoring has taken place. You will need to restart WoW when upgrading to this version of TellMeWhen.]==],
[==[* Multi-state Cooldown icons can now keep track of spell charges.]==],
[==[* Added a new setting to the Runes condition that allows you to force the condition to check for non-death runes.]==],
[==[* Rune icons can now distinguish between checking normal runes and death runes.]==],
[==[* Rune icons have an option to show extra unusable runes as charges.]==],
[==[* Added a buff equivalency to track absorbtion shields ("DamageShield").]==],
[==[]==],
[==[* New Conditions:]==],
[==[** NPC ID]==],
[==[** Weekday]==],
[==[** Time of Day]==],
[==[** Quest Complete]==],
[==[** Spell Cast Count]==],
[==[** Absorbtion shield amount]==],
[==[** Unit Incoming heals]==],
[==[]==],
[==[* Bug Fixes:]==],
[==[** The IncreasedStats equivalency should now always properly check for the Legacy of the Emperor buff]==],
[==[** Groups being moved (dragged around) should now much  more reliably detatch from your cursor when they are supposed to.]==],
[==[** Fixed an accidental inversion of the 1st param to TMW_LOCK_TOGGLED]==],
[==[** Replaced Blood Pact with Dark Intent for the IncreasedStamina equivalency.]==],
[==[** The "All Types" setting for Loss of Control icons should now work as intended.]==],
[==[** Attempted to fix the issue where the "You are not in a raid" message would be caused by TellMeWhen.]==],
[==[** Fixed: Components/IconModules/IconModule_Alpha/Alpha.lua:145 attempt to perform arithmetic on field "actualAlphaAtLastChange" (a nil value)]==],
[==[** Fixed: IconType_unitcooldown/unitcooldown.lua:270 attempt to index local "NameHash" (a boolean value)]==],
[==[** Conditions that use the c.GCDReplacedNameFirst condition substitution will no longer fail to compile when the spell being subbed in contains a double quote.]==],
[==[]==],
[==[===v6.1.5===]==],
[==[* Bug Fixes:]==],
[==[** Fixed an offset error with the Instance Type condition. ]==],
[==[]==],
[==[===v6.1.4===]==],
[==[* Bug Fixes:]==],
[==[** Forgot to remove a call to a method that was retired in 5.2 when I upgraded the code to work with 5.2 (GetInstanceDifficulty).]==],
[==[]==],
[==[===v6.1.3===]==],
[==[* New icon type: Swing Timer.]==],
[==[* New conditions: Swing Timer - Main Hand; Swing Timer - Off Hand.]==],
[==[* Added textures to the icon type select menu.]==],
[==[* All pre-MoP compatibility code has been removed.]==],
[==[* You can now use item slot IDs as dynamic Custom Texture values. Syntax is {{{$item.1}}}, where 1 is the item slot ID (1-19) that you want to use.]==],
[==[* Added a setting to customize the shadow on text displays.]==],
[==[]==],
[==[* Bug Fixes:]==],
[==[** Text from the Text Displays module should now always appear above all other icon elements.]==],
[==[** Fixed: {{{Core/Conditions/Categories/PlayerAttributes.lua:60: attempt to call upvalue "GetInstanceDifficulty" (a nil value) }}}]==],
[==[** The ALPHA_STACKREQ and ALPHA_DURATIONREQ data processor hooks should now properly trigger the TMW_ICON_UPDATED event when their state changes, which will allow meta icons (that check icons that implement these hooks) to properly update as needed.]==],
[==[** The "Talent learned", "Glyph active", and "Tracking active" conditions should now always update properly when checked in a condition set where there are OnUpdate driven conditions in a higher position than these conditions.]==],
[==[** Editboxes will no longer have their text reset if they are focused and have unsaved changes when a non-editbox setting is changed.]==],
[==[]==],
[==[===v6.1.2===]==],
[==[* Added a new tag [LocType] to display the category of loss of control icon types.]==],
[==[* New slash command for changing profiles: /tmw profile "Profile Name"]==],
[==[* Animations can now be anchored to different components of an icon (when appropriate).]==],
[==[]==],
[==[* Bug Fixes:]==],
[==[** Designed a new protocol for sharing class spells to prevent the old version of it that was dramatically flawed from leaking into a new version of it.]==],
[==[** Icon Color Flash animations should now work correctly.]==],
[==[** Rewrote (but mostly just refactored) the database initialization process so that it runs in a much more logical fashion, and also so it allows for upgrades in the "global" DB namespace to run when they are supposed to.]==],
[==[** Rewrote (but mostly just refactored) event configuration code.]==],
[==[** The [Opacity] tag should now properly return a number instead of a boolean.]==],
[==[** Added Mind Quickening to the IncreasedSpellHaste equivalency]==],
[==[** Fixed {{{[string "ConditionEvents_SPELLCHARGETIME"] line 3: attempt to call global 'GetSpellCharges' (a nil value)}}}]==],
[==[** The group "Only show in combat" setting is now handled by the group's event handlers (instead of conditions) to prevent Script ran too long errors (hopefully).]==],
[==[** Invented a new method for moving the Icon Editor so that it won't jump around all over the place anymore.]==],
[==[** Fixed an issue with DetectFrame for GroupModule_GroupPosition (Thanks to ChairmanKaga, ticket #740).]==],
[==[** Event handlers that are changed from an event that has short condition checking enabled to an event that does not have condition checking should now function correctly.]==],
[==[** It should no longer be possible for the bottom of the icon editor to extend off your screen and preventing you from resizing it.]==],
[==[]==],
[==[===v6.1.1===]==],
[==[* Added a new text output handler for the Instance channel, and updated existing chat output methods for this channel.]==],
[==[]==],
[==[* Bug Fixes:]==],
[==[** Fixed error Interface/AddOns/TellMeWhen/TellMeWhen.lua:155: table index is nil]==],
[==[]==],
[==[===v6.1.0===]==],
[==[* New icon display method: Bars.]==],
[==[* New icon type: Loss of Control (WoW 5.1+ only)]==],
[==[* You may notice some slight changes to the way your text layouts appear, especially if you used the Constrain Width setting. You will have to re-adjust your old layouts to achieve old functionality, which will probably require adding a second anchor to any affected text displays.]==],
[==[* New group option: Group Opacity.]==],
[==[* New conditions: Buff/Debuff Duration Percentage.]==],
[==[* The "Class Colored Names" setting was removed due to internal conflicts with DogTag and the implementation of this setting.]==],
[==[]==],
[==[* Bug Fixes:]==],
[==[** Conditions with minimum values less than zero should now allow for these values to be selected.]==],
[==[** The Show Timer Text option should now work properly with Tukui.]==],
[==[** You should no longer see an error randomly telling you that TMW can't do an action in combat when no action has been triggered.]==],
[==[** Logging in while in combat with Masque installed without the Allow Config in Combat option enabled should no longer leave icons in a mangled state.]==],
[==[** Logging in while in combat with the Allow Config in Combat option enabled should now have a much lower chance of triggering a 'script ran too long' error.]==],
[==[** Items whose cooldown durations are reported as being 0.001 seconds should no longer be treated as being usable.]==],
[==[** Added missing spells to the SpellDamageTaken equivalency]==],
[==[** Attempted a fix for error <string>:"Condition_SPELLDMG":3: Usage: GetSpellBonusDamage(school)]==],
[==[** All slashes in custom texture paths will be converted to backslashes upon processing.]==],
[==[** The [Name] DogTag should now always update properly.]==],
[==[** Fixed the error stemming from Components/Core/Spells/ClassSpellCache.lua:215 ()? running while in combat.]==],
[==[]==],
[==[===v6.0.4===]==],
[==[* New icon event: On Condition Set Passing. Allows you to create an event handler that reacts to the state of a condition set.]==],
[==[* New icon event: On Icon Setup. Essentially allows you to have a "default state" for icon animations.]==],
[==[* Added a dropdown menu to select an icon when right clicking a spot on your screen that contains multiple icons.]==],
[==[* Conditions with no maximum value (e.g. Health/Mana; any condition that checks a time) now allow manual input of a value.]==],
[==[* There is now an option to allow configuration while in combat (as opposed to allowing at all the time with potential bugs, the options module now loads at login when this option is enabled to prevent many errors and bugs).]==],
[==[]==],
[==[* New conditions:]==],
[==[** Spell charge time]==],
[==[** In pet battle]==],
[==[** Equipment set equipped]==],
[==[** Icon Shown Time]==],
[==[** Icon Hidden Time]==],
[==[]==],
[==[* New setting for Buff/Debuff icons: Hide if no units.]==],
[==[* Added Challenge Mode and 40 Player raid to the Instance Type condition.]==],
[==[* The Totem icon type has been re-focused towards the Rune of Power talent for mages.]==],
[==[* The Buff Efficiency Threshold setting is back.]==],
[==[* Changed all file encodings to UTF-8 in hopes of fixing the loading problems that many users are having.]==],
[==[* The {{{[Duration]}}} tag now has a parameter that allows for the GCD to be ignored ({{{[Duration(gcd=false)]}}})]==],
[==[* Added a separate toggle for the Show Timer Text option that only affects the timer text that ElvUI provides.]==],
[==[]==],
[==[* Bug fixes:]==],
[==[** Minimum group frame level is now 5 instead of 1 to prevent issues caused at low frame levels.]==],
[==[** Increased the delay on LoadFirstValidIcon from 0.1 seconds to 0.5 seconds in hopes of preventing the AceCD:804 error more often.]==],
[==[** Soul shard condition maximum has been increased to 4 (from 3).]==],
[==[** The lightwell icon type should now work properly with the Lightspring glyph.]==],
[==[** Tried again to fix the AceCD:804 error. Probably didn't succeed.]==],
[==[** Fixed an incorrect spellID for Spirit Beast Blessing in the IncreasedMastery equivalency.]==],
[==[** Groups should now properly show/hide as needed when you change between primary/secondary talents specializations when both specializations are the same.]==],
[==[** Condition Object Constructors are now much more reliable (at the cost of some garbage churn when running TMW:Update())]==],
[==[** Fix attempted for GroupModule_GroupPosition/Config.lua line 47: attempt to index local 'Module' (a nil value)]==],
[==[** IncreasedStats should now properly include Legacy of the Emperor]==],
[==[** Fixed Components/IconTypes/IconType_unitcooldown/unitcooldown.lua:317 attempt to index local 'NameHash' (a boolean value)]==],
[==[** Fixed Components/IconModules/IconModule_PowerBar/PowerBar.lua:128 attempt to index local 'colorinfo' (a nil value)]==],
[==[** Fixed Components/IconModules/IconModule_Alpha/Alpha.lua:96 attempt to compare nil with number]==],
[==[** The "Show Timer Text" option now works with ElvUI]==],
[==[** Fixed TellMeWhen: Condition MELEEAP tried to write values to Env different than those that were already in it.]==],
[==[** Attempted some fixes at some obscure bugs that can happen with replacement spells (e.g. tracking Immolate in a debuff icon was getting force-changed to Corruption in Affliction spec.)]==],
[==[** Removed the blank normaltexture that every icon had because of issues it causes in WoW 5.1]==],
[==[** The Instance Type condition should now work properly.]==],
[==[** Hacked in a fix for {{{<string>:"local _G = _G -- 1...":6: attempt to index field "__functions" (a nil value)}}}]==],
[==[** Item conditions show now correctly work if the item that they are tracking was entered by name and wasn't in your bags at login.]==],
[==[** When a profile in the import menus has more than 10 groups, its groups will be split into submenus so that they don't run off the screen.]==],
[==[** Attempted a fix at the issue with text corruption when typing Chinese characters into DogTag formatted editboxes.]==],
[==[** The glyph condition should now work correctly when its logic is set to false.]==],
[==[** You should no longer be spammed with messages telling you that you are not in a guild.]==],
[==[** The Show icon texture setting for MikSBT text output should now function as intended.]==],
[==[** Attempted a fix for TellMeWhen.lua line 2333: attempt to get length of field 'CSN' (a nil value)]==],
[==[]==],
[==[* A Special note: r450 concludes a series of 9 bogus commits that were made in order to restore the revision number of the repo back to where it was before the data loss that struck CurseForge's SVN repos on 11/7]==],
[==[]==],
[==[===v6.0.3===]==],
[==[* Re-implemented the stance condition for paladin seals.]==],
[==[* Minor updates for some buff/debuff equivalancies. Still need help getting these completely up to date, though! If you notice something missing, please let me know!]==],
[==[* You can now change the event of an event handler once it has been created.]==],
[==[* New setting for Combat Event icons - Don't Refresh.]==],
[==[* Added Raid Finder to the Instance Type condition.]==],
[==[* You can now output text to the UI Errors Frame.]==],
[==[* Moved the Timers ignore GCD & Bars ignore GCD settings from per-profile to per-icon.]==],
[==[* Updated Unit Cooldown icons for all cooldown resets in MoP.]==],
[==[* DR categories should now be complete for MoP. Please report any missing spells.]==],
[==[* You can once again toggle config mode in combat. You may still get script ran too long errors if TellMeWhen_Options has not been loaded yet and you unlock in combat,  but it won't break anything.]==],
[==[* You can now reorder groups.]==],
[==[* Added a setting to make colors ignore the GCD. It is enabled by default.]==],
[==[* Added center text as a default text layout.]==],
[==[* New condition: Unit is Player.]==],
[==[* Unit conditions now allow Lua conditions.]==],
[==[* Unit conditions now allow you to track the target of the icon's units.]==],
[==[]==],
[==[* Bug fixes:]==],
[==[** Fixed static formats again (ICONMENU_MULTISTATECD_DESC)]==],
[==[** (Condition ROLE): attempt to index global "roles" (a nil value)]==],
[==[** Buff/debuff duration sorting actually works now!]==],
[==[** TellMeWhen_Options.lua:3351: attempt to index local "settingsUsedByEvent" (a nil value)]==],
[==[** Announcements.lua:531: attempt to concatenate local "Text" (a nil value)]==],
[==[** Leader of the Pack should now be properly checked by the IncreasedCrit equivalency]==],
[==[** Fixed a major flaw with importing profiles from backup or from other profiles in the db]==],
[==[** (Condition THREATRAW): attempt to call global 'UnitDetailedThreatSituation' (a nil value)]==],
[==[** Fixed cooldown resetting with unitcooldown icons. Spells still not really updated for MoP]==],
[==[** Fixed a bug where colors weren't being updated when the duration of an icon changes. Colors still suck, but at least they should work (better) now.]==],
[==[** Fixed a bag bug that will completely break most configuration after cloning a text layout]==],
[==[** Fixed a bug where profiles of version 60032 or earlier could not be imported by version 60033 or later.]==],
[==[** Fixed an error caused by dragging certain talents/specialization spells onto icons.]==],
[==[** Wrote a library (LibSpellRange-1.0) to solve the range checking problem in MoP.]==],
[==[** Texts.lua line 438: attempt to compare nil with number - Fixed for real this time!]==],
[==[** The talent specialization condition will now properly allow all four choices for druids.]==],
[==[** The pet talent tree conditions should no longer be listed for non-hunters.]==],
[==[** As a workaround to a strange bug in DogTag, the {{{[Stacks]}}} tag now returns a number value instead of a string. All default and otherwise reasonable variations of {{{[Stacks:Hide('0')}}} should automatically be upgraded.]==],
[==[** Unit conditions now actually work with icon types other than Buff/Debuff.]==],
[==[** Fixed an error with the GCD condition on login.]==],
[==[** The behavior of the link parameter for Item Cooldown icons' {{{[Spell]}}} DogTag should no longer be backwards.]==],
[==[** Shift-clicking links into the text announcement input box should now format them correctly for DogTag. Existing links cannot/will not be updated.]==],
[==[** Fixed errors with mismatched frames and channels in the text output event configuration.]==],
[==[** Attempted a fix for an error involving data from the last used suggestion module to leak into the DogTag suggestion module.]==],
[==[]==],
[==[===v6.0.2===]==],
[==[* Cooldown icons should now provide much better functionality when checking multiple spells. Single-spell functionality should (hopefully) remain unchanged.]==],
[==[* Updated the name and description of the "Spell Cast Succeeded" Combat Event to reflect that it now only tracks instant cast spells.]==],
[==[]==],
[==[* Bug fixes:]==],
[==[** Bumped TellMeWhen_Options interface number]==],
[==[** Fixed warlock stance suggestions]==],
[==[** Removed paladin auras]==],
[==[** Fixed name coloring issue]==],
[==[** Fixed an error with range checking invalid spells]==],
[==[** Holy power limit increased to 5]==],
[==[** The "Show Variable text" setting should no longer cause errors]==],
[==[** Fixed the GCD spell for warriors (again)]==],
[==[** Fixed an issue with static formats and ptBR, zhCN, and zhTW.]==],
[==[** /Core/Conditions/Categories/BuffsDebuffs.lua:56 attempt to index global 'strlowerCache' (a nil value)]==],
[==[]==],
[==[===v6.0.1===]==],
[==[* Bug fix: Fixed positioning issues when using Masque.]==],
[==[]==],
[==[===v6.0.0===]==],
[==[* This is by far the biggest update that TMW has ever seen. There were so many changes that I lost track of them. Here are a few:]==],
[==[]==],
[==[* Full support for Mists of Pandaria. If anything is missing, please open a ticket.]==],
[==[]==],
[==[* Almost everything in TMW is now modular. The most immediate effect of this is that the main tab in the icon editor is now divided into panels for each component that is contributing to an icon.]==],
[==[* Implemented LibDogTag as the text manager for TMW instead of TMW's old (and very limited) system. You can now create text layouts that can be applied to an icon to dictate how the texts for that icon will be displayed.]==],
[==[* You can now specify a new set of conditions that are attached to the units that an icon checks. This is the replacement for the now-removed ability to track "%u" as a unit in icon conditions.]==],
[==[* You can now select any of the 4 sound channels to play sounds to (instead of just Master and SFX).]==],
[==[* You can now list specific totems to be checked by totem icons.]==],
[==[* Added On Left Click and On Right Click event handlers to icons.]==],
[==[* You can now change the direction that icons layout in within a group.]==],
[==[* Spell Crit is now an event that can be tracked by Combat Event icons.]==],
[==[]==],
[==[* New Conditions:]==],
[==[** Added a condition to check if you have your mouse over a frame (group or icon).]==],
[==[** Added conditions to check if you have a certain glyph active.]==],
[==[** Added a condition to check the creature type (Undead, Humanoid, Demon, etc.) of a unit.]==],
[==[]==],
[==[* There are many, many more changes not listed here. I recommend that you just start configuring TellMeWhen to see what all has changed.]==],
[==[]==],
}
