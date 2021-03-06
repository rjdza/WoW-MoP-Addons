--[[
Copyright 2012-2014 João Cardoso
PetTracker is distributed under the terms of the GNU General Public License (Version 3).
As a special exception, the copyright holders of this addon do not give permission to
redistribute and/or modify it.

This addon is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with the addon. If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.

This file is part of PetTracker.
--]]

local _, Addon = ...
local Loader = Addon:NewModule('ConfigLoader')

function Loader:Startup()
	if not PetTracker_Tutorial or PetTracker_Tutorial < 8 then
		LoadAddOn('PetTracker_Config')
	else
		local original = InterfaceOptionsFrame:GetScript('OnShow')
		InterfaceOptionsFrame:SetScript('OnShow', function(...)
			LoadAddOn('PetTracker_Config')
			original(...)
		end)
	end
end