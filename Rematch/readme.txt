Rematch is an addon to help create, store, recall and share battle pet teams.

Its primary purpose is to store and recall battle pets for targets. For instance:
- When you target Aki the Chosen, bring up the Rematch window and hit Save, it will record under her name the pets you have out.
- When you return to Aki another day, you can target her, bring up the window and hit Load to bring those pets back.

New in 2.3.2

- Fix for 'Start Leveling' in default pet journal.
- Double-clicking a pet in the browser will summon/dismiss it.
- Dead pets are marked in the browser.
- Possible fix for browser scrolling bug.

New Pet Browser

The 2.3 update finally has a pet browser you can open alongside the main window for help creating your teams.  You can open it with the 'Pets' button on the main window, or by setting up a key binding in the default key binding interface.

Some advantages it has over the default pet journal:
- Search will also search for abilities: 'call lightning' will list all pets that have the Call Lightning ability.
- Search will also search abilities' text: 'blinded' will list all pets with abilities that mention Blinded pets.
- In addition to filtering pets by type, you can filter by 'Strong vs': if you filter Strong vs Dragonkin, it will list all pets with magic attacks.
- You can also filter to pets that are Tough vs a type of attack: filtering Tough vs Elemental will list all critters.
- A 'Type Bar' to filter by the various types without going through the dropdown menus.
- You can choose what levels to list from the search box: <25 will list pets below 25, =25 will list pets that are 25, 11-15 will list pets between levels 11 and 15, etc.
- A counter at the bottom of the browser tells you how many pets are listed: search =25 and you'll see how many level 25 pets you own.
- If Jump to Key is enabled, you can hit a letter and it will jump to the next pet that begins with that letter.

To clear filters, you can click the little X button in the search box or the type bar, or you can click the X along the bottom when filters are applied.  You can also click 'Reset All' within the filters menu.  Closing the browser itself will also clear most filters.

How to Use

You can summon the Rematch window a few ways:
- Set a key binding in the default key binding interface.
- Use the /rematch command.
- Click the Rematch button in the pet journal.
- Have 'Auto Show' checked in options and target something for which you have a saved team that's not already loaded.

As mentioned at the top, this addon's primary purpose is to save for targets. Target an NPC, click Save, and a team is saved for that target.
- If you don't have an NPC targeted, 'Save' will turn to 'Save As' and if clicked it will ask for a name for the team.
- If you name a team the same as a player, it will react to that player just like an NPC.
- You can bring up a list of teams you've saved by clicking the pullout button at the bottom.

Leveling Pets

Thanks to suggestions from Behub, Aloek and others, Rematch has a robust system to make leveling pets easy.

In the pullout drawer there is a leveling slot with a shiny gold border. Within this slot you can build a queue of pets you want to level. Drag a pet to the slot or right-click a pet elsewhere (like the pet journal) and choose 'Start Leveling' to make a leveling pet.

- Any teams saved with a leveling pet will reserve that pet's slot for future leveling pets.
- When you see a shiny gold border around a pet in Rematch, it means that is a leveling pet.
- As pets reach 25 (gratz!) the next pet in the leveling queue automatically becomes your new leveling pet.

Sharing Teams

There are two ways to share battle pet teams when you right-click it in the pullout drawer:
- The Send option to send a team to someone online on your faction.
- The Export option to create a WeakAuras-like text string that you can copy/paste.

When a user receives a team that you Send, they'll receive a popup displaying the team with the option to save it.

To use an Export string, click the Import button in the pullout drawer and paste the string. You can review the team before saving it.

If you receive or import a team that includes pets you don't have, that's fine. They'll be greyed out and only the pets you have will attempt to load. You can keep the team as is for the day when you get the pet, or you can choose to save over it if you find a suitable substitute for the missing pet.

Note: Battle.net and RealID are not supported yet, sorry. It will happen in a future update. But you can send to Name-Realm if they're on the same faction.

Miscellaneous
- The "tooltip" for pets is a card with stats. Hold Alt to flip the card over for more about your pet. Click the pet to lock the card in place so you can mouseover abilities.
- When a card is locked and has a wooden frame around it, you can unlock it several ways: clicking one of the little screws on the corner, clicking the pet again from where you locked it, hitting ESCape or any other action that dismisses the card.
- You can Rename, Delete, Send or Export a team by right-clicking it in the pullout drawer.
- When a team is selected, the little window to the right of your saved pets lists the types your team is strong against, sorted by the number of strong attacks loaded on your team. Abilities that don't attack are excluded.
- Teams with white names have an NPC ID stored in them to focus its target awareness to that NPC ID. If they have a gold name then any target of that name is considered its target.
- This addon will peacefully co-exist with all other battle pet addons. If the addon is installed it will pull breed information from Battle Pet Breed ID.
- You can shift-click pets and abilities to chat like you can from the pet journal.
- You can manually edit the names at the start of an import string to save it under a different name.
- The Escape key will pull back most panels opened within the addon. For instance, if you pull up the Rematch window, open the drawer and go into options: hitting escape will close options and return to the drawer, hitting escape again will collapse the drawer, and hitting escape again will close the window.
- Clicking a pet or one of its abilities will jump to that pet in the Pet Journal.
- You can view or rearrange pets in the leveling queue by moving the mouse over the leveling slot in the pullout drawer.
- If you have the addon Pet Battle Teams enabled, "/rematch import" will import your PBT teams into Rematch.

If you have any comments, suggestions or bugs to report feel free to post them here in the comments. Thanks!

03/09/2014 2.3.2 fix for 'start leveling' in pet journal, double-click in browser to summon/dismiss pets, browser pets marked if dead, possible fix for a scrollframe bug (when scrollbar disabled move offset to 0 if not already there)
03/08/2014 2.3.1 removed portrait mask for ability icons on default ability tooltip, jump to key only if no modifier down, added link to chat for browser pets, browser opens back up after journal closes (if it was up before), favorite filter turned into a soft filter
03/07/2014 2.3.0 new pet browser, pet card lock/mouseover mechanism, SmartAnchor system references the main window instead of relativeTo, Jump to Team changed to Jump to Key, species aren't filled when when caging a species that has multiples in a saved team, fix for abilities not linking from current pets
02/22/2014 2.2.9 new option StayForBattle, added "weak vs" row to hints window, SmartAnchor system for pet card and tooltips, reworked dropdown menu build to make options more consistent, added Swap with Next in Queue to dropdown, added pullout side panel for leveling pet/queue auto load, added option ShowSidePanel to enable side panel
02/19/2014 2.2.8 window hides when a battle starts/returns after, fix for 5.4.7 patch and revoked pets
02/11/2014 2.2.7 fix for pet names on leveling slot/queue right-click menu, pets in the journal show an icon if they're a leveling pet, leveling icon changed, when queue is empty 'Put Leveling Pet Here' still given as an option but disabled, removed highlight texture from saved pets
02/01/2014 2.2.6 when pets are loaded, there is no longer an effort to have loaded teams move into first slots, but instead to the slots they were saved, fix for dead X icon persisting on empty slots, auto load only fires once per encounter with a saved target, added AutoLoad->AutoLoadAlways option, added AutoLoad->EmptyMissing option, fixed minor xml errors, fix for current header not being draggable, pet loading more rigorous (checks if pet/ability needs loading, verifies it loaded, sets up a reload in 0.3 seconds or after battle if failed), /rematch import converts empty slots to leveling pets and turns on 'Empty Missing', /rematch import over to overwrite existing teams, /rematch help
01/29/2014 2.2.5 fix for right-click menu on leveling slot
01/29/2014 2.2.4 species ID is saved with teams and used when the pet ID is no longer valid, 'Send to End of Queue' option added for current leveling pets, full support for empty slots, petload process changed from OnUpdate one swap per frame to all swaps at once
01/25/2014 2.2.3 rename/send/export/delete moved to right-click of a team; fix for current team title not updating if pets don't change, fix for ESC sometimes failing with unexpected UISpecialFrame entry, possible fix for pet loading issue
01/18/2014 2.2.2 ESC system switched from UISpecialFrames to propagated keys, "Current Battle Pets" header will show last loaded team (if current pets are still last loaded team), teams can be renamed, hitting a letter over teams will jump to a team that begins with that letter, new toggle auto load binding
01/10/2014 2.2.1 changed 'frame' to 'rematch' in RematchSharedDropDown CreateFrame
01/10/2014 2.2.0 code restructured, UI/ESCable system reworked, saved pet section collapses, Lock Drawer option, esc clears selected team, auto-show/load will not dismiss the window if it was up already, 'Use Leveling Pet' added to right-click menu of current pets that can't level, save button is 'Save As' when it will ask for a name, help button and help plates
12/14/2013 2.1.5a fix for ability icons made too big from today's update oops
12/14/2013 2.1.5 'Add to Leveling Queue' option added for journal pet menus to send to end of queue, removed 5.4.1 taint bug fix, queue only processes when out of combat/pet battle
12/06/2013 2.1.4 auto upgrade (aka best of species) option added
11/29/2013 2.1.3 leveling queue system, right-click menus added to journal current pets and leveling pets, level displayed on current pets under 25
11/07/2013 2.1.2 confirmation on save/import/receive over existing teams, confirmation on delete, option to disable confirmations, changed icon of the pullout button, new option: Auto Load->On Mouseover to auto load teams on mouseover instead of target
11/04/2013 2.1.1 caged pets replaced by their species in saved teams, fix for auto load preventing opening window, petsNeedLoading will take leveling pets into account
11/03/2013 2.1.0 removed lock system, replaced with leveling slot system; pet journal onshow HookScript instead of SetScript; removed requirement for selected team to be scrolled in to save/delete; saveAs will allow saving over a team with same name
10/29/2013 2.0.10 fix for taint issue with microbuttons: setfenv onshow to empty UpdateMicroButtons()
10/28/2013 2.0.9 removed visibility requirement to update pet journal loadouts
10/27/2013 2.0.8 fix for disconnect bug when dragging pets to a saved slot; PetBattleTeam migration moved to /rematch migrate
10/27/2013 2.0.7 rematch button on pet journal will move based on the existence of other buttons along the bottom
10/24/2013 2.0.6 if 'Auto Show' and 'Lock Window' are both checked, window will remain after pets load; all three slots can be locked; auto show/load trigger more intelligently with locked pets; added Rematch button to pet journal; ability tooltip mouse disabled; holding Shift will let you move the window while it's locked; 'Keep Companion' system reworked around UNIT_PET with a timeout
10/18/2013 2.0.5 fix for saving low level pets caused by fix from last update
10/18/2013 2.0.4 low level pets with abilities higher than they can use will load the lower tier ability instead, low level current pets only show abilities they can use, team loads taking too long will stop trying, BAG_UPDATE throttled
10/18/2013 2.0.3 rewrite: new UI, new options, custom teams, send/import/export teams
09/11/2013 1.0.5 toc update for 5.4
08/06/2013 1.0.4 fix for saved pets caged or missing
05/21/2013 1.0.3 toc update for 5.3
03/16/2013 1.0.2 added 'Auto Show' option, changed UI a bit
03/13/2013 1.0.1 initial release