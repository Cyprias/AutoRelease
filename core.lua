--[[******************************************************************************
	Addon:      AutoRelease
	Author:     Cyprias
	License:    MIT License	(http://opensource.org/licenses/MIT)
**********************************************************************************]]

local folder, ns = ...

-- Constants --
local debugging             = false;             -- Various debugging messages.
local releaseDelay          = 0.250;             -- Wait 250 ms before releasing. Releasing too soon after death in wintergrasp seems to glitch game preventing the spirit from rezzing us.

-- Core
local core      = CreateFrame("Frame");
core.title		= GetAddOnMetadata(folder, "Title")
core.version	= GetAddOnMetadata(folder, "Version")
core.titleFull  = core.title.." v"..core.version
core.addonDir   = "Interface\\AddOns\\"..folder.."\\"

ns.core         = core;
_G._AR = core

do
	local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME;
	function core:Echo(msg, r, g, b)
		if (not r) then r = 0.7; end
		if (not g) then g = 0.7; end
		if (not b) then b = 0.7; end
		DEFAULT_CHAT_FRAME:AddMessage("|cff003300[|r|cff00FF00AR|r|cff003300]|r "..msg, r, g, b);
	end
end

function core:Debug(msg, r, g, b)
	if (debugging == true) then
		self:Echo("Debug: " .. msg, r, g, b);
	end
end

do 	
	-- Core event frame.
	local function OnEvent(self, event, ...)
		if (core[event]) then
			core[event](core, event, ...);
			return;
		end
		core:Debug("<OnEvent> Missing handler: " .. tostring(event));
	end
	core:SetScript("OnEvent", OnEvent)
	core:RegisterEvent("VARIABLES_LOADED");
end

do
	-- Initialize our addon.
	function core:VARIABLES_LOADED()	
		self:Debug("<VARIABLES_LOADED>");
		self:RegisterEvent("PLAYER_DEAD");
	end
end
	
do
	local GetRealZoneText = GetRealZoneText;
	function core:PLAYER_DEAD(event, ...)
		core:Debug("We died.");
		if ( self:InBattleground() or GetRealZoneText() == "Wintergrasp" ) then
			core:Debug("We're in a battleground.");
			if (core:ShouldRelease() )then
				core:Echo("Auto releasing...");
				core:Release()
			end
		end
	end
end

do
	local IsInInstance = IsInInstance;
	function core:InBattleground()
		local active, iType = IsInInstance()
		if (active and iType == "pvp") then
			return true;
		end
		return false;
	end
end

do
	local HasSoulstone = HasSoulstone;
	local CanUseSoulstone = CanUseSoulstone;
	function core:ShouldRelease()
		if( HasSoulstone() and CanUseSoulstone() ) then
			return false;
		end
		return true;
	end	
end

do
	local CreateFrame = CreateFrame;
	function core:Wait(miliseconds, callback)
		local f = CreateFrame("Frame");
		function onUpdate(self, elapsed)
			self.totalElapsed = (self.totalElapsed or 0) + elapsed;
			--core:Debug("totalElapsed: " .. self.totalElapsed);
			if (self.totalElapsed < miliseconds) then 
				return; 
			end
		
			f:SetScript("OnUpdate", nil);
			f = nil;

			-- Call our callback.
			callback();
		end
		f:SetScript("OnUpdate", onUpdate)
	end
end

do
	local RepopMe = RepopMe;
	function core:Release()--	/script _AR:Release();
		core:Debug("Waiting...");
		self:Wait(releaseDelay, function()
			core:Debug("Release!");
			RepopMe();
		end)
	end
end