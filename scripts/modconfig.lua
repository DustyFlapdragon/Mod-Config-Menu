local MCM = {}
MCM.Version = 18

--[[

MOD CONFIG MENU v18
by piber

Make sure this is located in MOD/scripts/modconfig.lua otherwise it wont load properly!

Do not edit this script file as it could conflict with the release version of this file used by other mods. If you find a bug or need to something changed, let me know.

Make sure you also have Mod Config Menu's assets as well, these should be contained in MOD/resources/gfx/ui/modconfig.

-------

REQUIREMENTS:
- ScreenHelper
- CallbackHelper
- TableHelper
- InputHelper
- CacheHelper

-------

Mod Config Menu's goals:
- Provide a common use platform for mod makers to let players configure their mod at will
- Contain a selection of common settings that most mods would use, and have them affect all of them

Mod Config Menu has a general section containing settings for Hud Offset, Overlays, Big Books, and Charge Bars, meant for use in all mods, each with their own custom callback. There is also functionality to enable mods to create new custom sections in the config menu, complete with calling a custom function the modder would create when adding the setting, effectively allowing it to change anything the modder wishes.

]]

Isaac.DebugString("Loading Mod Config Menu v" .. MCM.Version)

--create the mod
local MCMMod = RegisterMod("Mod Config Menu", 1)

--require some lua libraries
local json = require("json")
local ScreenHelper = require("scripts.screenhelper")
local CallbackHelper = require("scripts.callbackhelper")
local TableHelper = require("scripts.tablehelper")
local InputHelper = require("scripts.inputhelper")
local CacheHelper = require("scripts.cachehelper")

--cached values
local game = CacheHelper.Game
local level = CacheHelper.Level
local room = CacheHelper.Room

local seeds = CacheHelper.Seeds
local sfx = CacheHelper.SFX

local vecZero = CacheHelper.VecZero

local colorDefault = CacheHelper.Color
local colorHalf = CacheHelper.ColorHalf


--------------------
--custom callbacks--
--------------------

--POST MODIFY HUD OFFSET
--gets called when the hud offset setting is changed in the general mod config menu section
--use this if you need to change anything in your mod when hud offset is changed
--function(hudOffset)
CallbackHelper.Callbacks.MCM_POST_MODIFY_HUD_OFFSET = 4300

--this will make ScreenHelper's offset match MCM's offset when it is changed
CallbackHelper.AddCallback(MCMMod, CallbackHelper.Callbacks.MCM_POST_MODIFY_HUD_OFFSET, function(_, hudOffset)
	ScreenHelper.SetOffset(hudOffset)
end)

--POST MODIFY OVERLAYS
--gets called when the overlays setting is changed in the general mod config menu section
--use this if you need to change anything in your mod when overlays are enabled or disabled
--function(overlaysEnabled)
CallbackHelper.Callbacks.MCM_POST_MODIFY_OVERLAYS = 4301

--POST MODIFY CHARGE BARS
--gets called when the charge bars setting is changed in the general mod config menu section
--use this if you need to change anything in your mod when charge bars are enabled or disabled
--function(chargeBarsEnabled)
CallbackHelper.Callbacks.MCM_POST_MODIFY_CHARGE_BARS = 4302

--POST MODIFY BIG BOOKS
--gets called when the big books setting is changed in the general mod config menu section
--use this if you need to change anything in your mod when big books are enabled or disabled
--function(chargeBarsEnabled)
CallbackHelper.Callbacks.MCM_POST_MODIFY_BIG_BOOKS = 4303


----------
--saving--
----------

MCM.ConfigDefault = {

	--general
	HudOffset = 0,
	Overlays = true,
	ChargeBars = false,
	BigBooks = true,
	
	--mcm settings
	OpenMenuKeyboard = Keyboard.KEY_L,
	OpenMenuController = InputHelper.Controller.STICK_RIGHT,
	
	HideHudInMenu = true,
	ResetToDefault = Keyboard.KEY_R,
	ShowControls = true,
	
	--last button pressed tracker
	LastBackPressed = Keyboard.KEY_BACKSPACE,
	LastSelectPressed = Keyboard.KEY_ENTER
	
}
MCM.Config = TableHelper.CopyTable(MCM.ConfigDefault)

function MCM.GetSave()
	
	local saveData = TableHelper.CopyTable(MCM.ConfigDefault)
	saveData = TableHelper.FillTable(saveData, MCM.Config)
	
	saveData = json.encode(saveData)
	
	return saveData
	
end

function MCM.LoadSave(fromData)

	if fromData and ((type(fromData) == "string" and json.decode(fromData)) or type(fromData) == "table") then
	
		local saveData = TableHelper.CopyTable(MCM.ConfigDefault)
		
		if type(fromData) == "string" then
			fromData = json.decode(fromData)
		end
		saveData = TableHelper.FillTable(saveData, fromData)
		
		local currentData = TableHelper.CopyTable(MCM.Config)
		saveData = TableHelper.FillTable(currentData, saveData)
		
		MCM.Config = TableHelper.CopyTable(saveData)
		
		--make sure ScreenHelper's offset matches MCM's offset
		ScreenHelper.SetOffset(MCM.Config.HudOffset)
		
		return saveData
		
	else
		error("MCM.LoadSave - arg 1 (fromData) couldnt be decoded or used directly as mcm data")
	end
	
end


---------------------------
--startup version display--
---------------------------

local versionPrintFont = Font()
versionPrintFont:Load("font/pftempestasevencondensed.fnt")

local versionPrintTimer = 0

CallbackHelper.AddCallback(MCMMod, CallbackHelper.Callbacks.CH_GAME_START, function(_, player, isSaveGame)

	if MCM.Config.ShowControls then
	
		versionPrintTimer = 120
		
	else
	
		versionPrintTimer = 60
		
	end
	
end)

MCMMod:AddCallback(ModCallbacks.MC_POST_UPDATE, function()

	if versionPrintTimer > 0 then
	
		versionPrintTimer = versionPrintTimer - 1
		
	end
	
end)

MCMMod:AddCallback(ModCallbacks.MC_POST_RENDER, function()

	if versionPrintTimer > 0 then
	
		local bottomRight = ScreenHelper.GetScreenBottomRight(0)

		local openMenuButton = Keyboard.KEY_F10
		if type(MCM.Config.OpenMenuKeyboard) == "number" and MCM.Config.OpenMenuKeyboard > -1 then
			openMenuButton = MCM.Config.OpenMenuKeyboard
		end

		local openMenuButtonString = "Unknown Key"
		if InputHelper.KeyboardToString[openMenuButton] then
			openMenuButtonString = InputHelper.KeyboardToString[openMenuButton]
		end
		
		local text = "Press " .. openMenuButtonString .. " to open Mod Config Menu"
		local versionPrintColor = KColor(1, 1, 0, (math.min(versionPrintTimer, 60)/60) * 0.5)
		versionPrintFont:DrawString(text, 0, bottomRight.Y - 28, versionPrintColor, bottomRight.X, true)
		
	end
	
end)

------------------------------------
--set up the menu sprites and font--
------------------------------------
MCM.IsVisible = false

function MCM.GetMenuAnm2Sprite(animation, frame, color)

	local sprite = Sprite()
	
	sprite:Load("gfx/ui/modconfig/menu.anm2", true)
	sprite:SetFrame(animation or "Idle", frame or 0)
	
	if color then
		sprite.Color = color
	end
	
	return sprite
	
end

--main menu sprites
local MenuSprite = MCM.GetMenuAnm2Sprite("Idle", 0)
local PopupSprite = MCM.GetMenuAnm2Sprite("Popup", 0)

--main cursors
local CursorSpriteRight = MCM.GetMenuAnm2Sprite("Cursor", 0)
local CursorSpriteUp = MCM.GetMenuAnm2Sprite("Cursor", 1)
local CursorSpriteDown = MCM.GetMenuAnm2Sprite("Cursor", 2)

--subcategory pane cursors
local SubcategoryCursorSpriteLeft = MCM.GetMenuAnm2Sprite("Cursor", 3, colorHalf)
local SubcategoryCursorSpriteRight = MCM.GetMenuAnm2Sprite("Cursor", 0, colorHalf)

--options pane cursors
local OptionsCursorSpriteUp = MCM.GetMenuAnm2Sprite("Cursor", 1, colorHalf)
local OptionsCursorSpriteDown = MCM.GetMenuAnm2Sprite("Cursor", 2, colorHalf)

--other options pane objects
local SubcategoryDividerSprite = MCM.GetMenuAnm2Sprite("Divider", 0, colorHalf)
local SliderSprite = MCM.GetMenuAnm2Sprite("Slider1", 0)

--strikeout
local StrikeOutSprite = MCM.GetMenuAnm2Sprite("Strikeout", 0)

--back/select corner papers
local CornerSelect = MCM.GetMenuAnm2Sprite("BackSelect", 0)
local CornerBack = MCM.GetMenuAnm2Sprite("BackSelect", 1)
local CornerOpen = MCM.GetMenuAnm2Sprite("BackSelect", 2)
local CornerExit = MCM.GetMenuAnm2Sprite("BackSelect", 3)

--fonts
local Font10 = Font()
Font10:Load("font/teammeatfont10.fnt")

local Font12 = Font()
Font12:Load("font/teammeatfont12.fnt")

local Font16Bold = Font()
Font16Bold:Load("font/teammeatfont16bold.fnt")

--popups
MCM.PopupGfx = {
	THIN_SMALL = "gfx/ui/modconfig/popup_thin_small.png",
	THIN_MEDIUM = "gfx/ui/modconfig/popup_thin_medium.png",
	THIN_LARGE = "gfx/ui/modconfig/popup_thin_large.png",
	WIDE_SMALL = "gfx/ui/modconfig/popup_wide_small.png",
	WIDE_MEDIUM = "gfx/ui/modconfig/popup_wide_medium.png",
	WIDE_LARGE = "gfx/ui/modconfig/popup_wide_large.png"
}


-------------------------
--add setting functions--
-------------------------
MCM.OptionType = {
	TEXT = 1,
	SPACE = 2,
	SCROLL = 3,
	BOOLEAN = 4,
	NUMBER = 5,
	KEYBIND_KEYBOARD = 6,
	KEYBIND_CONTROLLER = 7,
	TITLE = 8
}

MCM.MenuData = {}

function MCM.GetCategoryIDByName(name)

	local categoryID = nil
	
	for i=1, #MCM.MenuData do
		if name == MCM.MenuData[i].Name then
			categoryID = i
			break
		end
	end
	
	return categoryID
	
end

function MCM.GetSubcategoryIDByName(categoryID, name)

	local subcategoryID = nil
	
	for i=1, #MCM.MenuData[categoryID].Subcategories do
		if name == MCM.MenuData[categoryID].Subcategories[i].Name then
			subcategoryID = i
			break
		end
	end
	
	return subcategoryID
	
end

function MCM.UpdateCategory(name, dataTable)

	if type(name) ~= "string" then
		return
	end

	local categoryToChange = MCM.GetCategoryIDByName(name)
	if categoryToChange == nil then
		categoryToChange = #MCM.MenuData+1
		MCM.MenuData[categoryToChange] = {}
		MCM.MenuData[categoryToChange].Subcategories = {}
	end
	
	MCM.MenuData[categoryToChange].Name = tostring(name)
	
	if dataTable.Info then
		MCM.MenuData[categoryToChange].Info = dataTable.Info
	end
	
	if dataTable.IsOld then
		MCM.MenuData[categoryToChange].IsOld = dataTable.IsOld
	end
	
end

function MCM.UpdateSubcategory(category, name, dataTable)

	if type(category) ~= "string" then
		return
	end

	if type(name) ~= "string" then
		return
	end
	
	local categoryToChange = MCM.GetCategoryIDByName(name)
	if categoryToChange == nil then
		categoryToChange = #MCM.MenuData+1
		MCM.MenuData[categoryToChange] = {}
		MCM.MenuData[categoryToChange].Name = tostring(category)
		MCM.MenuData[categoryToChange].Subcategories = {}
	end
	
	local subcategoryToChange = MCM.GetSubcategoryIDByName(categoryToChange, name)
	if subcategoryToChange == nil then
		subcategoryToChange = #MCM.MenuData[categoryToChange].Subcategories+1
		MCM.MenuData[categoryToChange].Subcategories[subcategoryToChange] = {}
		MCM.MenuData[categoryToChange].Subcategories[subcategoryToChange].Options = {}
	end
	
	MCM.MenuData[categoryToChange].Subcategories[subcategoryToChange].Name = tostring(name)
	
	if dataTable.Info then
		MCM.MenuData[categoryToChange].Subcategories[subcategoryToChange].Info = dataTable.Info
	end
	
end

function MCM.AddSetting(category, subcategory, settingTable)
	if settingTable == nil then
		settingTable = subcategory
		subcategory = nil
	end
	
	if subcategory == nil then
		subcategory = "Uncategorized"
	end
	
	local categoryToChange = MCM.GetCategoryIDByName(category)
	if categoryToChange == nil then
		categoryToChange = #MCM.MenuData+1
		MCM.MenuData[categoryToChange] = {}
		MCM.MenuData[categoryToChange].Name = tostring(category)
		MCM.MenuData[categoryToChange].Subcategories = {}
	end
	
	local subcategoryToChange = MCM.GetSubcategoryIDByName(categoryToChange, subcategory)
	if subcategoryToChange == nil then
		subcategoryToChange = #MCM.MenuData[categoryToChange].Subcategories+1
		MCM.MenuData[categoryToChange].Subcategories[subcategoryToChange] = {}
		MCM.MenuData[categoryToChange].Subcategories[subcategoryToChange].Name = tostring(subcategory)
		MCM.MenuData[categoryToChange].Subcategories[subcategoryToChange].Options = {}
	end
	
	MCM.MenuData[categoryToChange].Subcategories[subcategoryToChange].Options[#MCM.MenuData[categoryToChange].Subcategories[subcategoryToChange].Options+1] = settingTable
	
	return settingTable
end
function MCM.AddText(category, subcategory, text, color)
	if color == nil and type(text) ~= "string" and type(text) ~= "function" then
		color = text
		text = subcategory
		subcategory = nil
	end
	
	local settingTable = {
		Type = MCM.OptionType.TEXT,
		Display = text,
		Color = color,
		NoCursorHere = true
	}
	
	return MCM.AddSetting(category, subcategory, settingTable)
end
function MCM.AddTitle(category, subcategory, text, color)
	if color == nil and type(text) ~= "string" and type(text) ~= "function" then
		color = text
		text = subcategory
		subcategory = nil
	end
	
	local settingTable = {
		Type = MCM.OptionType.TITLE,
		Display = text,
		Color = color,
		NoCursorHere = true
	}
	
	return MCM.AddSetting(category, subcategory, settingTable)
end
function MCM.AddSpace(category, subcategory)
	local settingTable = {
		Type = MCM.OptionType.SPACE
	}
	
	return MCM.AddSetting(category, subcategory, settingTable)
end

--------------------
--GENERAL SETTINGS--
--------------------

MCM.UpdateCategory("General", {
	Info = "Settings that affect the majority of mods"
})

MCM.AddSpace("General") --SPACE

MCM.AddSpace("General") --SPACE

--hud offset visual
local HudOffsetVisualTopLeft = MCM.GetMenuAnm2Sprite("Offset", 0)
local HudOffsetVisualTopRight = MCM.GetMenuAnm2Sprite("Offset", 1)
local HudOffsetVisualBottomRight = MCM.GetMenuAnm2Sprite("Offset", 2)
local HudOffsetVisualBottomLeft = MCM.GetMenuAnm2Sprite("Offset", 3)

MCM.AddSetting("General", { --HUD OFFSET
	Type = MCM.OptionType.SCROLL,
	CurrentSetting = function()
		return MCM.Config.HudOffset
	end,
	Default = MCM.ConfigDefault.HudOffset,
	Display = function(cursorIsHere)
	
		if cursorIsHere then
		
			--render the visual
			HudOffsetVisualBottomRight:Render(ScreenHelper.GetScreenBottomRight(), vecZero, vecZero)
			HudOffsetVisualBottomLeft:Render(ScreenHelper.GetScreenBottomLeft(), vecZero, vecZero)
			HudOffsetVisualTopRight:Render(ScreenHelper.GetScreenTopRight(), vecZero, vecZero)
			HudOffsetVisualTopLeft:Render(ScreenHelper.GetScreenTopLeft(), vecZero, vecZero)
			
		end
		
		return "Hud Offset: $scroll" .. tostring(math.floor(MCM.Config.HudOffset))
		
	end,
	OnChange = function(currentNum)
	
		MCM.Config.HudOffset = currentNum
		
		--MCM_POST_MODIFY_HUD_OFFSET
		CallbackHelper.CallCallbacks
		(
			CallbackHelper.Callbacks.MCM_POST_MODIFY_HUD_OFFSET, --callback id
			nil, --function to handle it
			{currentNum} --args to send
		)
		
	end,
	Info = {
		"How far from the corners of the screen",
		"custom hud elements will be.",
		"Try to make this match your base-game setting."
	},
	HideControls = true
})
MCM.AddSetting("General", { --OVERLAYS
	Type = MCM.OptionType.BOOLEAN,
	CurrentSetting = function()
		return MCM.Config.Overlays
	end,
	Default = MCM.ConfigDefault.Overlays,
	Display = function()
	
		local onOff = "Off"
		if MCM.Config.Overlays then
			onOff = "On"
		end
		
		return "Overlays: " .. onOff
		
	end,
	OnChange = function(currentBool)
	
		MCM.Config.Overlays = currentBool
		
		--MCM_POST_MODIFY_OVERLAYS
		CallbackHelper.CallCallbacks
		(
			CallbackHelper.Callbacks.MCM_POST_MODIFY_OVERLAYS, --callback id
			nil, --function to handle it
			{currentBool} --args to send
		)
		
	end,
	Info = {
		"Enable or disable custom visual overlays,",
		"like screen-wide fog."
	}
})
MCM.AddSetting("General", { --CHARGE BARS
	Type = MCM.OptionType.BOOLEAN,
	CurrentSetting = function()
		return MCM.Config.ChargeBars
	end,
	Default = MCM.ConfigDefault.ChargeBars,
	Display = function()
	
		local onOff = "Off"
		if MCM.Config.ChargeBars then
			onOff = "On"
		end
		
		return "Charge Bars: " .. onOff
		
	end,
	OnChange = function(currentBool)
	
		MCM.Config.ChargeBars = currentBool
		
		--MCM_POST_MODIFY_CHARGE_BARS
		CallbackHelper.CallCallbacks
		(
			CallbackHelper.Callbacks.MCM_POST_MODIFY_CHARGE_BARS, --callback id
			nil, --function to handle it
			{currentBool} --args to send
		)
		
	end,
	Info = {
		"Enable or disable custom charge bar visuals",
		"for mod effects, like those from chargable items."
	}
})
MCM.AddSetting("General", { --BIGBOOKS
	Type = MCM.OptionType.BOOLEAN,
	CurrentSetting = function()
		return MCM.Config.BigBooks
	end,
	Default = MCM.ConfigDefault.BigBooks,
	Display = function()
	
		local onOff = "Off"
		if MCM.Config.BigBooks then
			onOff = "On"
		end
		
		return "Bigbooks: " .. onOff
		
	end,
	OnChange = function(currentBool)
	
		MCM.Config.BigBooks = currentBool
		
		--MCM_POST_MODIFY_BIG_BOOKS
		CallbackHelper.CallCallbacks
		(
			CallbackHelper.Callbacks.MCM_POST_MODIFY_BIG_BOOKS, --callback id
			nil, --function to handle it
			{currentBool} --args to send
		)
		
	end,
	Info = {
		"Enable or disable custom bigbook overlays,",
		"like those which appear when an active item is used."
	}
})

MCM.AddSpace("General") --SPACE

MCM.AddText("General", "These settings apply to")
MCM.AddText("General", "all mods which support them")


----------------------------
--MOD CONFIG MENU SETTINGS--
----------------------------

MCM.UpdateCategory("Mod Config Menu", {
	Info = {
		"Settings specific to Mod Config Menu",
		"Change keybindings for the menu here"
	}
})

MCM.AddSpace("Mod Config Menu") --SPACE

MCM.AddTitle("Mod Config Menu", "Version " .. tostring(MCM.Version) .. " !") --VERSION INDICATOR

MCM.AddSpace("Mod Config Menu") --SPACE

MCM.AddSetting("Mod Config Menu", { --KEYBOARD KEYBIND
	Type = MCM.OptionType.KEYBIND_KEYBOARD,
	IsOpenMenuKeybind = true,
	CurrentSetting = function()
		return MCM.Config.OpenMenuKeyboard
	end,
	Default = MCM.ConfigDefault.OpenMenuKeyboard,
	Display = function()
		local key = "None"
		if MCM.Config.OpenMenuKeyboard > -1 then
			key = "Unknown Key"
			if InputHelper.KeyboardToString[MCM.Config.OpenMenuKeyboard] then
				key = InputHelper.KeyboardToString[MCM.Config.OpenMenuKeyboard]
			end
		end
		return "Open Menu: " .. key .. " (keyboard)"
	end,
	OnChange = function(currentNum)
		if not currentNum then
			currentNum = -1
		end
		MCM.Config.OpenMenuKeyboard = currentNum
	end,
	Info = "Keyboard button that opens this menu.",
	PopupGfx = MCM.PopupGfx.WIDE_SMALL,
	Popup = function()
		local goBackString = "back"
		if MCM.Config.LastBackPressed then
			if InputHelper.KeyboardToString[MCM.Config.LastBackPressed] then
				goBackString = InputHelper.KeyboardToString[MCM.Config.LastBackPressed]
			elseif InputHelper.ControllerToString[MCM.Config.LastBackPressed] then
				goBackString = InputHelper.ControllerToString[MCM.Config.LastBackPressed]
			end
		end
		
		local keepSettingString1 = ""
		local keepSettingString2 = ""
		if MCM.Config.OpenMenuKeyboard > -1 and InputHelper.KeyboardToString[MCM.Config.OpenMenuKeyboard] then
			keepSettingString1 = "This setting is currently set to \"" .. InputHelper.KeyboardToString[MCM.Config.OpenMenuKeyboard] .. "\"."
			keepSettingString2 = "Press this button to keep it unchanged."
		end
		
		return {
			"Press a keyboard button to change this setting.",
			"",
			keepSettingString1,
			keepSettingString2,
			"",
			"Press \"" .. goBackString .. "\" to go back and clear this setting."
		}
	end
})
MCM.AddSetting("Mod Config Menu", { --CONTROLLER KEYBIND
	Type = MCM.OptionType.KEYBIND_CONTROLLER,
	IsOpenMenuKeybind = true,
	CurrentSetting = function()
		return MCM.Config.OpenMenuController
	end,
	Default = MCM.ConfigDefault.OpenMenuController,
	Display = function()
		local key = "None"
		if MCM.Config.OpenMenuController > -1 then
			key = "Unknown Button"
			if InputHelper.ControllerToString[MCM.Config.OpenMenuController] then
				key = InputHelper.ControllerToString[MCM.Config.OpenMenuController]
			end
		end
		return "Open Menu: " .. key .. " (controller)"
	end,
	OnChange = function(currentNum)
		if not currentNum then
			currentNum = -1
		end
		MCM.Config.OpenMenuController = currentNum
	end,
	Info = "Controller button that opens this menu.",
	PopupGfx = MCM.PopupGfx.WIDE_SMALL,
	Popup = function()
		local goBackString = "back"
		if MCM.Config.LastBackPressed then
			if InputHelper.KeyboardToString[MCM.Config.LastBackPressed] then
				goBackString = InputHelper.KeyboardToString[MCM.Config.LastBackPressed]
			elseif InputHelper.ControllerToString[MCM.Config.LastBackPressed] then
				goBackString = InputHelper.ControllerToString[MCM.Config.LastBackPressed]
			end
		end
		
		local keepSettingString1 = ""
		local keepSettingString2 = ""
		if MCM.Config.OpenMenuController > -1 and InputHelper.ControllerToString[MCM.Config.OpenMenuController] then
			keepSettingString1 = "This setting is currently set to \"" .. InputHelper.ControllerToString[MCM.Config.OpenMenuController] .. "\"."
			keepSettingString2 = "Press this button to keep it unchanged."
		end
		
		return {
			"Press a controller button to change this setting.",
			"",
			keepSettingString1,
			keepSettingString2,
			"",
			"Press \"" .. goBackString .. "\" to go back and clear this setting."
		}
	end
})
MCM.AddText("Mod Config Menu", "F10 will always open this menu.")

MCM.AddSpace("Mod Config Menu") --SPACE

MCM.AddSetting("Mod Config Menu", { --HIDE HUD
	Type = MCM.OptionType.BOOLEAN,
	CurrentSetting = function()
		return MCM.Config.HideHudInMenu
	end,
	Default = MCM.ConfigDefault.HideHudInMenu,
	Display = function()
		local onOff = "No"
		if MCM.Config.HideHudInMenu then
			onOff = "Yes"
		end
		return "Hide HUD: " .. onOff
	end,
	OnChange = function(currentBool)
		MCM.Config.HideHudInMenu = currentBool
		
		if currentBool then
			if not seeds:HasSeedEffect(SeedEffect.SEED_NO_HUD) then
				seeds:AddSeedEffect(SeedEffect.SEED_NO_HUD)
			end
		else
			if seeds:HasSeedEffect(SeedEffect.SEED_NO_HUD) then
				seeds:RemoveSeedEffect(SeedEffect.SEED_NO_HUD)
			end
		end
	end,
	Info = "Enable or disable the hud when this menu is open."
})
MCM.AddSetting("Mod Config Menu", { --RESET TO DEFAULT BUTTON
	Type = MCM.OptionType.KEYBIND_KEYBOARD,
	IsResetKeybind = true,
	CurrentSetting = function()
		return MCM.Config.ResetToDefault
	end,
	Default = MCM.ConfigDefault.ResetToDefault,
	Display = function()
		local key = "None"
		if MCM.Config.ResetToDefault > -1 then
			key = "Unknown Key"
			if InputHelper.KeyboardToString[MCM.Config.ResetToDefault] then
				key = InputHelper.KeyboardToString[MCM.Config.ResetToDefault]
			end
		end
		return "Reset To Default Keybind: " .. key
	end,
	OnChange = function(currentNum)
		if not currentNum then
			currentNum = -1
		end
		MCM.Config.ResetToDefault = currentNum
	end,
	Info = {
		"Press this keyboard button to reset a setting",
		"to its default value if supported."
	},
	PopupGfx = MCM.PopupGfx.WIDE_SMALL,
	Popup = function()
		local goBackString = "back"
		if MCM.Config.LastBackPressed then
			if InputHelper.KeyboardToString[MCM.Config.LastBackPressed] then
				goBackString = InputHelper.KeyboardToString[MCM.Config.LastBackPressed]
			elseif InputHelper.ControllerToString[MCM.Config.LastBackPressed] then
				goBackString = InputHelper.ControllerToString[MCM.Config.LastBackPressed]
			end
		end
		
		local keepSettingString1 = ""
		local keepSettingString2 = ""
		if MCM.Config.ResetToDefault > -1 and InputHelper.KeyboardToString[MCM.Config.ResetToDefault] then
			keepSettingString1 = "This setting is currently set to \"" .. InputHelper.KeyboardToString[MCM.Config.ResetToDefault] .. "\"."
			keepSettingString2 = "Press this button to keep it unchanged."
		end
		
		return {
			"Press a keyboard button to change this setting.",
			"",
			keepSettingString1,
			keepSettingString2,
			"",
			"Press \"" .. goBackString .. "\" to go back and clear this setting."
		}
	end
})
MCM.AddSetting("Mod Config Menu", { --SHOW CONTROLS
	Type = MCM.OptionType.BOOLEAN,
	CurrentSetting = function()
		return MCM.Config.ShowControls
	end,
	Default = MCM.ConfigDefault.ShowControls,
	Display = function()
		local onOff = "No"
		if MCM.Config.ShowControls then
			onOff = "Yes"
		end
		return "Show Controls: " .. onOff
	end,
	OnChange = function(currentBool)
		MCM.Config.ShowControls = currentBool
	end,
	Info = {
		"Disable this to make the start-up message go",
		"away faster and to remove the back and select",
		"widgets at the lower corners of the screen."
	}
})

local configMenuCategoryCanShow = 11
local configMenuSubcategoriesCanShow = 3
local configMenuOptionsCanShow = 11

local configMenuInSubcategory = false
local configMenuInOptions = false
local configMenuInPopup = false

local holdingCounterDown = 0
local holdingCounterUp = 0
local holdingCounterRight = 0
local holdingCounterLeft = 0

local configMenuPositionCursorCategory = 1
local configMenuPositionCursorSubcategory = 1
local configMenuPositionCursorOption = 1
local configMenuPositionFirstCategory = 1
local configMenuPositionFirstSubcategory = 1
local configMenuPositionFirstOption = 1

--valid action presses
local actionsDown = {ButtonAction.ACTION_DOWN, ButtonAction.ACTION_SHOOTDOWN, ButtonAction.ACTION_MENUDOWN}
local actionsUp = {ButtonAction.ACTION_UP, ButtonAction.ACTION_SHOOTUP, ButtonAction.ACTION_MENUUP}
local actionsRight = {ButtonAction.ACTION_RIGHT, ButtonAction.ACTION_SHOOTRIGHT, ButtonAction.ACTION_MENURIGHT}
local actionsLeft = {ButtonAction.ACTION_LEFT, ButtonAction.ACTION_SHOOTLEFT, ButtonAction.ACTION_MENULEFT}
local actionsBack = {ButtonAction.ACTION_PILLCARD, ButtonAction.ACTION_MAP, ButtonAction.ACTION_MENUBACK}
local actionsSelect = {ButtonAction.ACTION_ITEM, ButtonAction.ACTION_PAUSE, ButtonAction.ACTION_MENUCONFIRM, ButtonAction.ACTION_BOMB}

--ignore these buttons for the above actions
local ignoreActionButtons = {InputHelper.Controller.BUTTON_A, InputHelper.Controller.BUTTON_B, InputHelper.Controller.BUTTON_X, InputHelper.Controller.BUTTON_Y}

local currentMenuCategory = nil
local currentMenuSubcategory = nil
local currentMenuOption = nil
local function updateCurrentMenuVars()
	if MCM.MenuData[configMenuPositionCursorCategory] then
		currentMenuCategory = MCM.MenuData[configMenuPositionCursorCategory]
		if currentMenuCategory.Subcategories and currentMenuCategory.Subcategories[configMenuPositionCursorSubcategory] then
			currentMenuSubcategory = currentMenuCategory.Subcategories[configMenuPositionCursorSubcategory]
			if currentMenuSubcategory.Options and currentMenuSubcategory.Options[configMenuPositionCursorOption] then
				currentMenuOption = currentMenuSubcategory.Options[configMenuPositionCursorOption]
			end
		end
	end
end

--leaving/entering menu sections
function MCM.EnterPopup()
	if configMenuInSubcategory and configMenuInOptions and not configMenuInPopup then
		local foundValidPopup = false
		if currentMenuOption
		and currentMenuOption.Type
		and currentMenuOption.Type ~= MCM.OptionType.SPACE
		and currentMenuOption.Popup then
			foundValidPopup = true
		end
		if foundValidPopup then
			local popupSpritesheet = MCM.PopupGfx.THIN_SMALL
			if currentMenuOption.PopupGfx and type(currentMenuOption.PopupGfx) == "string" then
				popupSpritesheet = currentMenuOption.PopupGfx
			end
			PopupSprite:ReplaceSpritesheet(8, popupSpritesheet)
			PopupSprite:LoadGraphics()
			configMenuInPopup = true
		end
	end
end

function MCM.EnterOptions()
	if configMenuInSubcategory and not configMenuInOptions then
		if currentMenuSubcategory
		and currentMenuSubcategory.Options
		and #currentMenuSubcategory.Options > 0 then
		
			for optionIndex=1, #currentMenuSubcategory.Options do
				
				local thisOption = currentMenuSubcategory.Options[optionIndex]
				
				if thisOption.Type
				and thisOption.Type ~= MCM.OptionType.SPACE
				and (not thisOption.NoCursorHere or (type(thisOption.NoCursorHere) == "function" and not thisOption.NoCursorHere()))
				and thisOption.Display then
				
					configMenuPositionCursorOption = optionIndex
					configMenuInOptions = true
					OptionsCursorSpriteUp.Color = colorDefault
					OptionsCursorSpriteDown.Color = colorDefault
					
					break
				end
			end
		end
	end
end

function MCM.EnterSubcategory()
	if not configMenuInSubcategory then
		configMenuInSubcategory = true
		SubcategoryCursorSpriteLeft.Color = colorDefault
		SubcategoryCursorSpriteRight.Color = colorDefault
		SubcategoryDividerSprite.Color = colorDefault
		
		local hasUsableCategories = false
		if currentMenuCategory.Subcategories then
			for j=1, #currentMenuCategory.Subcategories do
				if currentMenuCategory.Subcategories[j].Name ~= "Uncategorized" then
					hasUsableCategories = true
				end
			end
		end
		
		if not hasUsableCategories then
			MCM.EnterOptions()
		end
	end
end

function MCM.LeavePopup()
	if configMenuInSubcategory and configMenuInOptions and configMenuInPopup then
		configMenuInPopup = false
	end
end

function MCM.LeaveOptions()
	if configMenuInSubcategory and configMenuInOptions then
		configMenuInOptions = false
		OptionsCursorSpriteUp.Color = colorHalf
		OptionsCursorSpriteDown.Color = colorHalf
		
		local hasUsableCategories = false
		if currentMenuCategory.Subcategories then
			for j=1, #currentMenuCategory.Subcategories do
				if currentMenuCategory.Subcategories[j].Name ~= "Uncategorized" then
					hasUsableCategories = true
				end
			end
		end
		
		if not hasUsableCategories then
			MCM.LeaveSubcategory()
		end
	end
end

function MCM.LeaveSubcategory()
	if configMenuInSubcategory then
		configMenuInSubcategory = false
		SubcategoryCursorSpriteLeft.Color = colorHalf
		SubcategoryCursorSpriteRight.Color = colorHalf
		SubcategoryDividerSprite.Color = colorHalf
	end
end

local mainSpriteColor = colorDefault
local optionsSpriteColor = colorDefault
local optionsSpriteColorAlpha = colorHalf
local mainFontColor = KColor(34/255,32/255,30/255,1)
local leftFontColor = KColor(35/255,31/255,30/255,1)
local leftFontColorSelected = KColor(35/255,50/255,70/255,1)

local optionsFontColor = KColor(34/255,32/255,30/255,1)
local optionsFontColorAlpha = KColor(34/255,32/255,30/255,0.5)
local optionsFontColorNoCursor = KColor(34/255,32/255,30/255,0.8)
local optionsFontColorNoCursorAlpha = KColor(34/255,32/255,30/255,0.4)
local optionsFontColorTitle = KColor(50/255,0,0,1)
local optionsFontColorTitleAlpha = KColor(50/255,0,0,0.5)

local subcategoryFontColor = KColor(34/255,32/255,30/255,1)
local subcategoryFontColorSelected = KColor(34/255,50/255,70/255,1)
local subcategoryFontColorAlpha = KColor(34/255,32/255,30/255,0.5)
local subcategoryFontColorSelectedAlpha = KColor(34/255,50/255,70/255,0.5)

--render the menu
MCM.ControlsEnabled = true
MCMMod:AddCallback(ModCallbacks.MC_POST_RENDER, function()
	local isPaused = game:IsPaused()

	local pressingButton = ""

	local pressingNonRebindableKey = false
	local pressedToggleMenu = false

	local openMenuGlobal = Keyboard.KEY_F10
	local openMenuKeyboard = MCM.Config.OpenMenuKeyboard
	local openMenuController = MCM.Config.OpenMenuController

	if MCM.ControlsEnabled and not isPaused then
		for i=0, 4 do
			if InputHelper.KeyboardTriggered(openMenuGlobal, i)
			or (openMenuKeyboard > -1 and InputHelper.KeyboardTriggered(openMenuKeyboard, i))
			or (openMenuController > -1 and Input.IsButtonTriggered(openMenuController, i)) then
				pressingNonRebindableKey = true
				pressedToggleMenu = true
				if not configMenuInPopup then
					MCM.ToggleConfigMenu()
				end
			end
		end
	end
	
	--force close the menu in some situations
	if MCM.IsVisible then
	
		if isPaused then
			MCM.CloseConfigMenu()
		end
		
		if not MCM.RoomIsSafe() then
			MCM.CloseConfigMenu()
			sfx:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ, 0.75, 0, false, 1)
		end
		
	end

	if revel and revel.data and revel.data.controllerToggle then
		if openMenuController == InputHelper.Controller.STICK_RIGHT and (revel.data.controllerToggle == 1 or revel.data.controllerToggle == 3 or revel.data.controllerToggle == 4) then
			revel.data.controllerToggle = 2 --force revelations' menu to only use the left stick
		elseif openMenuController == InputHelper.Controller.STICK_LEFT and (revel.data.controllerToggle == 1 or revel.data.controllerToggle == 2 or revel.data.controllerToggle == 4) then
			revel.data.controllerToggle = 3 --force revelations' menu to only use the right stick
		end
	end
	
	if MCM.IsVisible then
		if MCM.ControlsEnabled and not isPaused then
			for i=1, #CacheHelper.Players do
				local player = CacheHelper.Players[i]
				local data = player:GetData()
				
				--freeze players and disable their controls
				player.Velocity = vecZero
				
				if not data.ConfigMenuPlayerPosition then
					data.ConfigMenuPlayerPosition = player.Position
				end
				player.Position = data.ConfigMenuPlayerPosition
				if not data.ConfigMenuPlayerControlsDisabled then
					player.ControlsEnabled = false
					data.ConfigMenuPlayerControlsDisabled = true
				end
				
				--disable toggling revelations menu
				if data.input and data.input.menu and data.input.menu.toggle then
					data.input.menu.toggle = false
				end
			end
			
			if not InputHelper.MultipleButtonTriggered(ignoreActionButtons) then
				--pressing buttons
				local downButtonPressed = InputHelper.MultipleActionTriggered(actionsDown)
				if downButtonPressed then
					pressingButton = "DOWN"
				end
				local upButtonPressed = InputHelper.MultipleActionTriggered(actionsUp)
				if upButtonPressed then
					pressingButton = "UP"
				end
				local rightButtonPressed = InputHelper.MultipleActionTriggered(actionsRight)
				if rightButtonPressed then
					pressingButton = "RIGHT"
				end
				local leftButtonPressed = InputHelper.MultipleActionTriggered(actionsLeft)
				if leftButtonPressed then
					pressingButton = "LEFT"
				end
				local backButtonPressed = InputHelper.MultipleActionTriggered(actionsBack) or InputHelper.MultipleKeyboardTriggered({Keyboard.KEY_BACKSPACE})
				if backButtonPressed then
					pressingButton = "BACK"
					local possiblyPressedButton = InputHelper.MultipleKeyboardTriggered(Keyboard)
					if possiblyPressedButton then
						MCM.Config.LastBackPressed = possiblyPressedButton
					end
				end
				local selectButtonPressed = InputHelper.MultipleActionTriggered(actionsSelect)
				if selectButtonPressed then
					pressingButton = "SELECT"
					local possiblyPressedButton = InputHelper.MultipleKeyboardTriggered(Keyboard)
					if possiblyPressedButton then
						MCM.Config.LastSelectPressed = possiblyPressedButton
					end
				end
				if MCM.Config.ResetToDefault > -1 and InputHelper.MultipleKeyboardTriggered({MCM.Config.ResetToDefault}) then
					pressingButton = "RESET"
				end
				
				--holding buttons
				if InputHelper.MultipleActionPressed(actionsDown) then
					holdingCounterDown = holdingCounterDown + 1
				else
					holdingCounterDown = 0
				end
				if holdingCounterDown > 20 and holdingCounterDown%5 == 0 then
					pressingButton = "DOWN"
				end
				if InputHelper.MultipleActionPressed(actionsUp) then
					holdingCounterUp = holdingCounterUp + 1
				else
					holdingCounterUp = 0
				end
				if holdingCounterUp > 20 and holdingCounterUp%5 == 0 then
					pressingButton = "UP"
				end
				if InputHelper.MultipleActionPressed(actionsRight) then
					holdingCounterRight = holdingCounterRight + 1
				else
					holdingCounterRight = 0
				end
				if holdingCounterRight > 20 and holdingCounterRight%5 == 0 then
					pressingButton = "RIGHT"
				end
				if InputHelper.MultipleActionPressed(actionsLeft) then
					holdingCounterLeft = holdingCounterLeft + 1
				else
					holdingCounterLeft = 0
				end
				if holdingCounterLeft > 20 and holdingCounterLeft%5 == 0 then
					pressingButton = "LEFT"
				end
			else
				if InputHelper.MultipleButtonTriggered({InputHelper.Controller.BUTTON_B}) then
					pressingButton = "BACK"
				end
				if InputHelper.MultipleButtonTriggered({InputHelper.Controller.BUTTON_A}) then
					pressingButton = "SELECT"
				end
				pressingNonRebindableKey = true
			end
			
			if pressingButton ~= "" then
				pressingNonRebindableKey = true
			end
		end
		
		updateCurrentMenuVars()
		
		local lastCursorCategoryPosition = configMenuPositionCursorCategory
		local lastCursorSubcategoryPosition = configMenuPositionCursorSubcategory
		local lastCursorOptionsPosition = configMenuPositionCursorOption
		
		local enterPopup = false
		local leavePopup = false
		
		local enterOptions = false
		local leaveOptions = false
		
		local enterSubcategory = false
		local leaveSubcategory = false
		
		if configMenuInPopup then
			if currentMenuOption then
				local optionType = currentMenuOption.Type
				local optionCurrent = currentMenuOption.CurrentSetting
				local optionOnChange = currentMenuOption.OnChange

				if optionType == MCM.OptionType.KEYBIND_KEYBOARD or optionType == MCM.OptionType.KEYBIND_CONTROLLER or currentMenuOption.OnSelect then

					if not isPaused then

						if pressingNonRebindableKey
						and not (pressingButton == "BACK"
						or pressingButton == "LEFT"
						or (currentMenuOption.OnSelect and (pressingButton == "SELECT" or pressingButton == "RIGHT"))
						or (currentMenuOption.IsResetKeybind and pressingButton == "RESET")
						or (currentMenuOption.IsOpenMenuKeybind and pressedToggleMenu)) then
							sfx:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ, 0.75, 0, false, 1)
						else
							local numberToChange = nil
							local recievedInput = false
							if optionType == MCM.OptionType.KEYBIND_KEYBOARD or optionType == MCM.OptionType.KEYBIND_CONTROLLER then
								numberToChange = optionCurrent
								
								if type(optionCurrent) == "function" then
									numberToChange = optionCurrent()
								end
								
								if pressingButton == "BACK" or pressingButton == "LEFT" then
									numberToChange = nil
									recievedInput = true
								else
									for i=0, 4 do
										if optionType == MCM.OptionType.KEYBIND_KEYBOARD then
											for j=32, 400 do
												if InputHelper.KeyboardTriggered(j, i) then
													numberToChange = j
													recievedInput = true
													break
												end
											end
										else
											for j=0, 31 do
												if Input.IsButtonTriggered(j, i) then
													numberToChange = j
													recievedInput = true
													break
												end
											end
										end
									end
								end
							elseif currentMenuOption.OnSelect then
								if pressingButton == "BACK" or pressingButton == "LEFT" then
									recievedInput = true
								end
								if pressingButton == "SELECT" or pressingButton == "RIGHT" then
									numberToChange = true
									recievedInput = true
								end
							end
							
							if recievedInput then
								if optionType == MCM.OptionType.KEYBIND_KEYBOARD or optionType == MCM.OptionType.KEYBIND_CONTROLLER then
									if type(optionCurrent) == "function" then
										if optionOnChange then
											optionOnChange(numberToChange)
										end
									elseif type(optionCurrent) == "number" then
										currentMenuOption.CurrentSetting = numberToChange
									end
								elseif currentMenuOption.OnSelect and numberToChange then
									currentMenuOption.OnSelect()
								end
								
								leavePopup = true
								
								local sound = currentMenuOption.Sound
								if not sound then
									sound = SoundEffect.SOUND_PLOP
								end
								if sound >= 0 then
									sfx:Play(sound, 1, 0, false, 1)
								end
							end
						end
					end
				end
			end
			
			--confirmed left press
			if pressingButton == "LEFT" then
				leavePopup = true
			end
			
			--confirmed back press
			if pressingButton == "BACK" then
				leavePopup = true
			end
		elseif configMenuInOptions then
			--confirmed down press
			if pressingButton == "DOWN" then
				configMenuPositionCursorOption = configMenuPositionCursorOption + 1 --move options cursor down
			end
			
			--confirmed up press
			if pressingButton == "UP" then
				configMenuPositionCursorOption = configMenuPositionCursorOption - 1 --move options cursor up
			end
			
			if pressingButton == "SELECT" or pressingButton == "RIGHT" or pressingButton == "LEFT" or (pressingButton == "RESET" and currentMenuOption and currentMenuOption.Default ~= nil) then
				if pressingButton == "LEFT" then
					leaveOptions = true
				end
				
				if currentMenuOption then
					local optionType = currentMenuOption.Type
					local optionCurrent = currentMenuOption.CurrentSetting
					local optionOnChange = currentMenuOption.OnChange
					
					if optionType == MCM.OptionType.SCROLL or optionType == MCM.OptionType.NUMBER then
						leaveOptions = false
						
						local numberToChange = optionCurrent
						
						if type(optionCurrent) == "function" then
							numberToChange = optionCurrent()
						end
						
						local modifyBy = currentMenuOption.ModifyBy or 1
						modifyBy = math.max(modifyBy,0.001)
						if math.floor(modifyBy) == modifyBy then --force modify by into being an integer instead of a float if it should be
							modifyBy = math.floor(modifyBy)
						end
						
						if pressingButton == "RIGHT" or pressingButton == "SELECT" then
							numberToChange = numberToChange + modifyBy
						elseif pressingButton == "LEFT" then
							numberToChange = numberToChange - modifyBy
						elseif pressingButton == "RESET" and currentMenuOption.Default ~= nil then
							numberToChange = currentMenuOption.Default
							if type(currentMenuOption.Default) == "function" then
								numberToChange = currentMenuOption.Default()
							end
						end
						
						if optionType == MCM.OptionType.SCROLL then
							numberToChange = math.max(math.min(math.floor(numberToChange), 10), 0)
						else
							if currentMenuOption.Maximum and numberToChange > currentMenuOption.Maximum then
								if not currentMenuOption.NoLoopFromMaxMin and currentMenuOption.Minimum then
									numberToChange = currentMenuOption.Minimum
								else
									numberToChange = currentMenuOption.Maximum
								end
							end
							if currentMenuOption.Minimum and numberToChange < currentMenuOption.Minimum then
								if not currentMenuOption.NoLoopFromMaxMin and currentMenuOption.Maximum then
									numberToChange = currentMenuOption.Maximum
								else
									numberToChange = currentMenuOption.Minimum
								end
							end
						end
						
						if math.floor(modifyBy) ~= modifyBy then --check if modify by is a float
							numberToChange = math.floor((numberToChange*1000)+0.5)*0.001
						else
							numberToChange = math.floor(numberToChange)
						end
						
						if type(optionCurrent) == "function" then
							if optionOnChange then
								optionOnChange(numberToChange)
							end
						elseif type(optionCurrent) == "number" then
							currentMenuOption.CurrentSetting = numberToChange
						end
						
						local sound = currentMenuOption.Sound
						if not sound then
							sound = SoundEffect.SOUND_PLOP
						end
						if sound >= 0 then
							sfx:Play(sound, 1, 0, false, 1)
						end
					elseif optionType == MCM.OptionType.BOOLEAN then
						leaveOptions = false
						
						local boolToChange = optionCurrent
						
						if type(optionCurrent) == "function" then
							boolToChange = optionCurrent()
						end
						
						if pressingButton == "RESET" and currentMenuOption.Default ~= nil then
							boolToChange = currentMenuOption.Default
							if type(currentMenuOption.Default) == "function" then
								boolToChange = currentMenuOption.Default()
							end
						else
							boolToChange = (not boolToChange)
						end
						
						if type(optionCurrent) == "function" then
							if optionOnChange then
								optionOnChange(boolToChange)
							end
						elseif type(optionCurrent) == "boolean" then
							currentMenuOption.CurrentSetting = boolToChange
						end
						
						local sound = currentMenuOption.Sound
						if not sound then
							sound = SoundEffect.SOUND_PLOP
						end
						if sound >= 0 then
							sfx:Play(sound, 1, 0, false, 1)
						end
					elseif (optionType == MCM.OptionType.KEYBIND_KEYBOARD or optionType == MCM.OptionType.KEYBIND_CONTROLLER) and pressingButton == "RESET" and currentMenuOption.Default ~= nil then
						local numberToChange = optionCurrent
						
						if type(optionCurrent) == "function" then
							numberToChange = optionCurrent()
						end
						
						numberToChange = currentMenuOption.Default
						if type(currentMenuOption.Default) == "function" then
							numberToChange = currentMenuOption.Default()
						end
						
						if type(optionCurrent) == "function" then
							if optionOnChange then
								optionOnChange(numberToChange)
							end
						elseif type(optionCurrent) == "number" then
							currentMenuOption.CurrentSetting = numberToChange
						end
						
						local sound = currentMenuOption.Sound
						if not sound then
							sound = SoundEffect.SOUND_PLOP
						end
						if sound >= 0 then
							sfx:Play(sound, 1, 0, false, 1)
						end
					elseif optionType ~= MCM.OptionType.SPACE and pressingButton == "RIGHT" then
						if currentMenuOption.Popup then
							enterPopup = true
						elseif currentMenuOption.OnSelect then
							currentMenuOption.OnSelect()
						end
					end
				end
			end
			
			--confirmed back press
			if pressingButton == "BACK" then
				leaveOptions = true
			end
			
			--confirmed select press
			if pressingButton == "SELECT" then
				if currentMenuOption then
					if currentMenuOption.Popup then
						enterPopup = true
					elseif currentMenuOption.OnSelect then
						currentMenuOption.OnSelect()
					end
				end
			end
		elseif configMenuInSubcategory then
			local hasUsableCategories = false
			if currentMenuCategory.Subcategories then
				for j=1, #currentMenuCategory.Subcategories do
					if currentMenuCategory.Subcategories[j].Name ~= "Uncategorized" then
						hasUsableCategories = true
					end
				end
			end
			if hasUsableCategories then
				--confirmed down press
				if pressingButton == "DOWN" then
					enterOptions = true
				end
				
				--confirmed up press
				if pressingButton == "UP" then
					leaveSubcategory = true
				end
				
				--confirmed right press
				if pressingButton == "RIGHT" then
					configMenuPositionCursorSubcategory = configMenuPositionCursorSubcategory + 1 --move right down
				end
				
				--confirmed left press
				if pressingButton == "LEFT" then
					configMenuPositionCursorSubcategory = configMenuPositionCursorSubcategory - 1 --move cursor left
				end
				
				--confirmed back press
				if pressingButton == "BACK" then
					leaveSubcategory = true
				end
				
				--confirmed select press
				if pressingButton == "SELECT" then
					enterOptions = true
				end
			end
		else
			--confirmed down press
			if pressingButton == "DOWN" then
				configMenuPositionCursorCategory = configMenuPositionCursorCategory + 1 --move left cursor down
			end
			
			--confirmed up press
			if pressingButton == "UP" then
				configMenuPositionCursorCategory = configMenuPositionCursorCategory - 1 --move left cursor up
			end
			
			--confirmed right press
			if pressingButton == "RIGHT" then
				enterSubcategory = true
			end
			
			--confirmed back press
			if pressingButton == "BACK" then
				MCM.CloseConfigMenu()
			end
			
			--confirmed select press
			if pressingButton == "SELECT" then
				enterSubcategory = true
			end
		end
		
		--entering popup
		if enterPopup then
			MCM.EnterPopup()
		end
		
		--leaving popup
		if leavePopup then
			MCM.LeavePopup()
		end
		
		--entering subcategory
		if enterSubcategory then
			MCM.EnterSubcategory()
		end
		
		--entering options
		if enterOptions then
			MCM.EnterOptions()
		end
		
		--leaving options
		if leaveOptions then
			MCM.LeaveOptions()
		end
		
		--leaving subcategory
		if leaveSubcategory then
			MCM.LeaveSubcategory()
		end
		
		--category cursor position was changed
		if lastCursorCategoryPosition ~= configMenuPositionCursorCategory then
			if not configMenuInSubcategory then
				--cursor position
				if configMenuPositionCursorCategory < 1 then --move from the top of the list to the bottom
					configMenuPositionCursorCategory = #MCM.MenuData
				end
				if configMenuPositionCursorCategory > #MCM.MenuData then --move from the bottom of the list to the top
					configMenuPositionCursorCategory = 1
				end
				
				--first category selection to render
				if configMenuPositionFirstCategory > 1 and configMenuPositionCursorCategory <= configMenuPositionFirstCategory+1 then
					configMenuPositionFirstCategory = configMenuPositionCursorCategory-1
				end
				if configMenuPositionFirstCategory+(configMenuCategoryCanShow-1) < #MCM.MenuData and configMenuPositionCursorCategory >= configMenuPositionFirstCategory+(configMenuCategoryCanShow-2) then
					configMenuPositionFirstCategory = configMenuPositionCursorCategory-(configMenuCategoryCanShow-2)
				end
				configMenuPositionFirstCategory = math.min(math.max(configMenuPositionFirstCategory, 1), #MCM.MenuData-(configMenuCategoryCanShow-1))
				
				--make sure subcategory and option positions are 1
				configMenuPositionCursorSubcategory = 1
				configMenuPositionFirstSubcategory = 1
				configMenuPositionCursorOption = 1
				configMenuPositionFirstOption = 1
			end
		end
		
		--subcategory cursor position was changed
		if lastCursorSubcategoryPosition ~= configMenuPositionCursorSubcategory then
			if not configMenuInOptions then
				--cursor position
				if configMenuPositionCursorSubcategory < 1 then --move from the top of the list to the bottom
					configMenuPositionCursorSubcategory = #currentMenuCategory.Subcategories
				end
				if configMenuPositionCursorSubcategory > #currentMenuCategory.Subcategories then --move from the bottom of the list to the top
					configMenuPositionCursorSubcategory = 1
				end
				
				--first category selection to render
				if configMenuPositionFirstSubcategory > 1 and configMenuPositionCursorSubcategory <= configMenuPositionFirstSubcategory+1 then
					configMenuPositionFirstSubcategory = configMenuPositionCursorSubcategory-1
				end
				if configMenuPositionFirstSubcategory+(configMenuSubcategoriesCanShow-1) < #currentMenuCategory.Subcategories and configMenuPositionCursorSubcategory >= configMenuPositionFirstCategory+(configMenuSubcategoriesCanShow-2) then
					configMenuPositionFirstSubcategory = configMenuPositionCursorSubcategory-(configMenuSubcategoriesCanShow-2)
				end
				configMenuPositionFirstSubcategory = math.min(math.max(configMenuPositionFirstSubcategory, 1), #currentMenuCategory.Subcategories-(configMenuSubcategoriesCanShow-1))
				
				--make sure option positions are 1
				configMenuPositionCursorOption = 1
				configMenuPositionFirstOption = 1
			end
		end
		
		--options cursor position was changed
		if lastCursorOptionsPosition ~= configMenuPositionCursorOption then
			if configMenuInOptions
			and currentMenuSubcategory
			and currentMenuSubcategory.Options
			and #currentMenuSubcategory.Options > 0 then
				
				--find next valid option that isn't a space
				local nextValidOptionSelection = configMenuPositionCursorOption
				local optionIndex = configMenuPositionCursorOption
				for i=1, #currentMenuSubcategory.Options*2 do
				
					local thisOption = currentMenuSubcategory.Options[optionIndex]
					
					if thisOption
					and thisOption.Type
					and thisOption.Type ~= MCM.OptionType.SPACE
					and (not thisOption.NoCursorHere or (type(thisOption.NoCursorHere) == "function" and not thisOption.NoCursorHere()))
					and thisOption.Display then
						
						nextValidOptionSelection = optionIndex
						
						break
					end
					
					if configMenuPositionCursorOption > lastCursorOptionsPosition then
						optionIndex = optionIndex + 1
					elseif configMenuPositionCursorOption < lastCursorOptionsPosition then
						optionIndex = optionIndex - 1
					end
					if optionIndex < 1 then
						optionIndex = #currentMenuSubcategory.Options
					end
					if optionIndex > #currentMenuSubcategory.Options then
						optionIndex = 1
					end
				end
				
				configMenuPositionCursorOption = nextValidOptionSelection
				
				updateCurrentMenuVars()
				
				--first options selection to render
				if configMenuPositionFirstOption > 1 and configMenuPositionCursorOption <= configMenuPositionFirstOption+1 then
					configMenuPositionFirstOption = configMenuPositionCursorOption-1
				end
				local lastOption = configMenuOptionsCanShow
				local hasSubcategories = false
				for j=1, #currentMenuCategory.Subcategories do
					if currentMenuCategory.Subcategories[j].Name ~= "Uncategorized" then
						hasSubcategories = true
					end
				end
				if hasSubcategories then
					lastOption = lastOption - 2
				end
				if configMenuPositionFirstOption+(lastOption-1) < #currentMenuSubcategory.Options and configMenuPositionCursorOption >= configMenuPositionFirstOption+(lastOption-2) then
					configMenuPositionFirstOption = configMenuPositionCursorOption-(lastOption-2)
				end
				configMenuPositionFirstOption = math.min(math.max(configMenuPositionFirstOption, 1), #currentMenuSubcategory.Options-(lastOption-1))
			end
		end
		
		local centerPos = ScreenHelper.GetScreenCenter()
		local leftPos = centerPos + Vector(-142,-102)
		local titlePos = centerPos + Vector(68,-118)
		local infoPos = centerPos + Vector(-4,106)
		local optionPos = centerPos + Vector(68,-88)
		
		MenuSprite:Render(centerPos, vecZero, vecZero)
		
		--category
		local lastLeftPos = leftPos
		local renderedLeft = 0
		for categoryIndex=1, #MCM.MenuData do
			if categoryIndex >= configMenuPositionFirstCategory then
				--text
				local textToDraw = tostring(MCM.MenuData[categoryIndex].Name)
				
				local color = leftFontColor
				--[[
				if configMenuPositionCursorCategory == categoryIndex then
					color = leftFontColorSelected
				end
				]]
				
				local posOffset = Font12:GetStringWidthUTF8(textToDraw)/2
				Font12:DrawString(textToDraw, lastLeftPos.X - posOffset, lastLeftPos.Y - 8, color, 0, true)
				
				--cursor
				if configMenuPositionCursorCategory == categoryIndex then
					CursorSpriteRight:Render(lastLeftPos + Vector((posOffset + 10)*-1,0), vecZero, vecZero)
				end
				
				--increase counter
				renderedLeft = renderedLeft + 1
				if renderedLeft >= configMenuCategoryCanShow then --if this is the last one we should render
					--render scroll arrows
					if configMenuPositionFirstCategory > 1 then --if the first one we rendered wasnt the first in the list
						CursorSpriteUp:Render(leftPos + Vector(45,-4), vecZero, vecZero)
					end
					if categoryIndex < #MCM.MenuData then --if this isnt the last category
						CursorSpriteDown:Render(lastLeftPos + Vector(45,4), vecZero, vecZero)
					end
					break
				end
				
				--pos mod
				lastLeftPos = lastLeftPos + Vector(0,16)
			end
		end
		
		--title
		local titleText = "Mod Config Menu"
		if configMenuInSubcategory then
			titleText = tostring(currentMenuCategory.Name)
		end
		local titleTextOffset = Font16Bold:GetStringWidthUTF8(titleText)/2
		Font16Bold:DrawString(titleText, titlePos.X - titleTextOffset, titlePos.Y - 9, mainFontColor, 0, true)
		
		--subcategory
		
		local lastOptionPos = optionPos
		local renderedOptions = 0
		
		local lastSubcategoryPos = optionPos
		local renderedSubcategories = 0
		
		if currentMenuCategory then
		
			local hasUncategorizedCategory = false
			local hasSubcategories = false
			local numCategories = 0
			for j=1, #currentMenuCategory.Subcategories do
				if currentMenuCategory.Subcategories[j].Name == "Uncategorized" then
					hasUncategorizedCategory = true
				else
					hasSubcategories = true
					numCategories = numCategories + 1
				end
			end
			
			if hasSubcategories then
				
				if hasUncategorizedCategory then
					numCategories = numCategories + 1
				end
				
				if numCategories == 2 then
					lastSubcategoryPos = lastOptionPos + Vector(-38,0)
				elseif numCategories >= 3 then
					lastSubcategoryPos = lastOptionPos + Vector(-76,0)
				end
			
				for subcategoryIndex=1, #currentMenuCategory.Subcategories do
				
					if subcategoryIndex >= configMenuPositionFirstSubcategory then
						
						local thisSubcategory = currentMenuCategory.Subcategories[subcategoryIndex]
						
						local posOffset = 0
						
						if thisSubcategory.Name then
							local textToDraw = thisSubcategory.Name
							
							textToDraw = tostring(textToDraw)
							
							local color = subcategoryFontColor
							if not configMenuInSubcategory then
								color = subcategoryFontColorAlpha
							--[[
							elseif configMenuPositionCursorSubcategory == subcategoryIndex and configMenuInSubcategory then
								color = subcategoryFontColorSelected
							]]
							end
							
							posOffset = Font12:GetStringWidthUTF8(textToDraw)/2
							Font12:DrawString(textToDraw, lastSubcategoryPos.X - posOffset, lastSubcategoryPos.Y - 8, color, 0, true)
						end
						
						--cursor
						if configMenuPositionCursorSubcategory == subcategoryIndex and configMenuInSubcategory then
							CursorSpriteRight:Render(lastSubcategoryPos + Vector((posOffset + 10)*-1,0), vecZero, vecZero)
						end
						
						--increase counter
						renderedSubcategories = renderedSubcategories + 1
						if renderedSubcategories >= configMenuSubcategoriesCanShow then --if this is the last one we should render
							--render scroll arrows
							if configMenuPositionFirstSubcategory > 1 then --if the first one we rendered wasnt the first in the list
								SubcategoryCursorSpriteLeft:Render(lastOptionPos + Vector(-125,0), vecZero, vecZero)
							end
							if subcategoryIndex < #currentMenuCategory.Subcategories then --if this isnt the last thing
								SubcategoryCursorSpriteRight:Render(lastOptionPos + Vector(125,0), vecZero, vecZero)
							end
							break
						end
						
						--pos mod
						lastSubcategoryPos = lastSubcategoryPos + Vector(76,0)
					end
				end
				
				renderedOptions = renderedOptions + 1
				lastOptionPos = lastOptionPos + Vector(0,14)
				
				SubcategoryDividerSprite:Render(lastOptionPos, vecZero, vecZero)
				
				renderedOptions = renderedOptions + 1
				lastOptionPos = lastOptionPos + Vector(0,14)
			end
		end
		
		--options
		
		local firstOptionPos = lastOptionPos
		
		if currentMenuSubcategory
		and currentMenuSubcategory.Options
		and #currentMenuSubcategory.Options > 0 then
		
			local useAltSlider = false
		
			for optionIndex=1, #currentMenuSubcategory.Options do
			
				if optionIndex >= configMenuPositionFirstOption then
					
					local thisOption = currentMenuSubcategory.Options[optionIndex]
					
					local cursorIsAtThisOption = configMenuPositionCursorOption == optionIndex and configMenuInOptions
					local posOffset = 10
					
					if thisOption.Type
					and thisOption.Type ~= MCM.OptionType.SPACE
					and thisOption.Display then
					
						local optionType = thisOption.Type
						local optionDisplay = thisOption.Display
						local optionColor = thisOption.Color
						
						--get what to draw
						if optionType == MCM.OptionType.TEXT
						or optionType == MCM.OptionType.BOOLEAN
						or optionType == MCM.OptionType.NUMBER
						or optionType == MCM.OptionType.KEYBIND_KEYBOARD
						or optionType == MCM.OptionType.KEYBIND_CONTROLLER
						or optionType == MCM.OptionType.TITLE then
							local textToDraw = optionDisplay
							
							if type(optionDisplay) == "function" then
								textToDraw = optionDisplay(cursorIsAtThisOption, configMenuInOptions, lastOptionPos)
							end
							
							textToDraw = tostring(textToDraw)
							
							local heightOffset = 6
							local font = Font10
							local color = optionsFontColor
							if not configMenuInOptions then
								if thisOption.NoCursorHere then
									color = optionsFontColorNoCursorAlpha
								else
									color = optionsFontColorAlpha
								end
							elseif thisOption.NoCursorHere then
								color = optionsFontColorNoCursor
							end
							if optionType == MCM.OptionType.TITLE then
								heightOffset = 8
								font = Font12
								color = optionsFontColorTitle
								if not configMenuInOptions then
									color = optionsFontColorTitleAlpha
								end
							end
							
							if optionColor then
								color = KColor(optionColor[1], optionColor[2], optionColor[3], color.A)
							end
							
							posOffset = font:GetStringWidthUTF8(textToDraw)/2
							font:DrawString(textToDraw, lastOptionPos.X - posOffset, lastOptionPos.Y - heightOffset, color, 0, true)
						elseif optionType == MCM.OptionType.SCROLL then
							local numberToShow = optionDisplay
							
							if type(optionDisplay) == "function" then
								numberToShow = optionDisplay(cursorIsAtThisOption, configMenuInOptions, lastOptionPos)
							end
							
							posOffset = 31
							local scrollOffset = 0
							
							if type(numberToShow) == "number" then
								numberToShow = math.max(math.min(math.floor(numberToShow), 10), 0)
							elseif type(numberToShow) == "string" then
								local numberToShowStart, numberToShowEnd = string.find(numberToShow, "$scroll")
								if numberToShowStart and numberToShowEnd then
									local numberStart = numberToShowEnd+1
									local numberEnd = numberToShowEnd+3
									local numberString = string.sub(numberToShow, numberStart, numberEnd)
									numberString = tonumber(numberString)
									if not numberString or (numberString and not type(numberString) == "number") or (numberString and type(numberString) == "number" and numberString < 10) then
										numberEnd = numberEnd-1
										numberString = string.sub(numberToShow, numberStart, numberEnd)
										numberString = tonumber(numberString)
									end
									if numberString and type(numberString) == "number" then
										local textToDrawPreScroll = string.sub(numberToShow, 0, numberToShowStart-1)
										local textToDrawPostScroll = string.sub(numberToShow, numberEnd, string.len(numberToShow))
										local textToDraw = textToDrawPreScroll .. "               " .. textToDrawPostScroll
										
										local color = optionsFontColor
										if not configMenuInOptions then
											color = optionsFontColorAlpha
										end
										if optionColor then
											color = KColor(optionColor[1], optionColor[2], optionColor[3], color.A)
										end
										
										scrollOffset = posOffset
										posOffset = Font10:GetStringWidthUTF8(textToDraw)/2
										Font10:DrawString(textToDraw, lastOptionPos.X - posOffset, lastOptionPos.Y - 6, color, 0, true)
										
										scrollOffset = posOffset - (Font10:GetStringWidthUTF8(textToDrawPreScroll)+scrollOffset)
										numberToShow = numberString
									end
								end
							end
							
							local scrollColor = optionsSpriteColor
							if not configMenuInOptions then
								scrollColor = optionsSpriteColorAlpha
							end
							if optionColor then
								scrollColor = Color(optionColor[1], optionColor[2], optionColor[3], scrollColor.A, scrollColor.RO, scrollColor.GO, scrollColor.BO)
							end
							
							local sliderString = "Slider1"
							if useAltSlider then
								sliderString = "Slider2"
							end
							
							SliderSprite.Color = scrollColor
							SliderSprite:SetFrame(sliderString, numberToShow)
							SliderSprite:Render(lastOptionPos - Vector(scrollOffset, -2), vecZero, vecZero)
							
							useAltSlider = not useAltSlider
							
						end
						
						local showStrikeout = thisOption.ShowStrikeout
						if posOffset > 0 and (type(showStrikeout) == boolean and showStrikeout == true) or (type(showStrikeout) == "function" and showStrikeout() == true) then
							if configMenuInOptions then
								StrikeOutSprite.Color = colorDefault
							else
								StrikeOutSprite.Color = colorHalf
							end
							StrikeOutSprite:SetFrame("Strikeout", math.floor(posOffset))
							StrikeOutSprite:Render(lastOptionPos, vecZero, vecZero)
						end
					end
					
					--cursor
					if cursorIsAtThisOption then
						CursorSpriteRight:Render(lastOptionPos + Vector((posOffset + 10)*-1,0), vecZero, vecZero)
					end
					
					--increase counter
					renderedOptions = renderedOptions + 1
					if renderedOptions >= configMenuOptionsCanShow then --if this is the last one we should render
						--render scroll arrows
						if configMenuPositionFirstOption > 1 then --if the first one we rendered wasnt the first in the list
							OptionsCursorSpriteUp:Render(firstOptionPos + Vector(125,-4), vecZero, vecZero)
						end
						if optionIndex < #currentMenuSubcategory.Options then --if this isnt the last thing
							OptionsCursorSpriteDown:Render(lastOptionPos + Vector(125,4), vecZero, vecZero)
						end
						break
					end
					
					--pos mod
					lastOptionPos = lastOptionPos + Vector(0,14)
				end
			end
		end
		
		--info
		local infoTable = nil
		local isOldInfo = false
		
		if configMenuInOptions then
		
			if currentMenuOption and currentMenuOption.Info then
				infoTable = currentMenuOption.Info
			end
			
		elseif configMenuInSubcategory then
		
			if currentMenuSubcategory and currentMenuSubcategory.Info then
				infoTable = currentMenuSubcategory.Info
			end
			
		elseif currentMenuCategory and currentMenuCategory.Info then
			
			infoTable = currentMenuCategory.Info
			if currentMenuCategory.IsOld then
				isOldInfo = true
			end
			
		end
		
		if infoTable then
			
			if type(infoTable) == "function" then
				infoTable = infoTable()
			end
			if type(infoTable) ~= "table" then
				infoTable = {infoTable}
			end
			
			local lastInfoPos = infoPos - Vector(0,6*#infoTable)
			for line=1, #infoTable do
			
				--text
				local textToDraw = tostring(infoTable[line])
				local posOffset = Font10:GetStringWidthUTF8(textToDraw)/2
				local color = mainFontColor
				if isOldInfo then
					color = optionsFontColorTitle
				end
				Font10:DrawString(textToDraw, lastInfoPos.X - posOffset, lastInfoPos.Y - 6, color, 0, true)
				
				--pos mod
				lastInfoPos = lastInfoPos + Vector(0,10)
				
			end
			
		end
		
		--popup
		if configMenuInPopup
		and currentMenuOption
		and currentMenuOption.Popup then
			PopupSprite:Render(centerPos, vecZero, vecZero)
			
			local popupTable = currentMenuOption.Popup
			if type(popupTable) == "function" then
				popupTable = popupTable()
			end
			if type(popupTable) ~= "table" then
				popupTable = {popupTable}
			end
			
			local lastPopupPos = (centerPos + Vector(0,2)) - Vector(0,6*#popupTable)
			for line=1, #popupTable do
				--text
				local textToDraw = tostring(popupTable[line])
				local posOffset = Font10:GetStringWidthUTF8(textToDraw)/2
				Font10:DrawString(textToDraw, lastPopupPos.X - posOffset, lastPopupPos.Y - 6, mainFontColor, 0, true)
				
				--pos mod
				lastPopupPos = lastPopupPos + Vector(0,10)
			end
		end
		
		--controls
		local shouldShowControls = true
		if configMenuInOptions and currentMenuOption and currentMenuOption.HideControls then
			shouldShowControls = false
		end
		if not MCM.Config.ShowControls then
			shouldShowControls = false
		end
		if shouldShowControls then

			--back
			local bottomLeft = ScreenHelper.GetScreenBottomLeft(0)
			if not configMenuInSubcategory then
				CornerExit:Render(bottomLeft, vecZero, vecZero)
			else
				CornerBack:Render(bottomLeft, vecZero, vecZero)
			end

			local goBackString = ""
			if MCM.Config.LastBackPressed then
				if InputHelper.KeyboardToString[MCM.Config.LastBackPressed] then
					goBackString = InputHelper.KeyboardToString[MCM.Config.LastBackPressed]
				elseif InputHelper.ControllerToString[MCM.Config.LastBackPressed] then
					goBackString = InputHelper.ControllerToString[MCM.Config.LastBackPressed]
				end
			end
			Font10:DrawString(goBackString, (bottomLeft.X - Font10:GetStringWidthUTF8(goBackString)/2) + 36, bottomLeft.Y - 24, mainFontColor, 0, true)

			--select
			local bottomRight = ScreenHelper.GetScreenBottomRight(0)
			if not configMenuInPopup then
			
				local foundValidPopup = false
				--[[
				if configMenuInSubcategory
				and configMenuInOptions
				and currentMenuOption
				and currentMenuOption.Type
				and currentMenuOption.Type ~= MCM.OptionType.SPACE
				and currentMenuOption.Popup then
					foundValidPopup = true
				end
				]]
				
				if foundValidPopup then
					CornerOpen:Render(bottomRight, vecZero, vecZero)
				else
					CornerSelect:Render(bottomRight, vecZero, vecZero)
				end
				
				local selectString = ""
				if MCM.Config.LastSelectPressed then
					if InputHelper.KeyboardToString[MCM.Config.LastSelectPressed] then
						selectString = InputHelper.KeyboardToString[MCM.Config.LastSelectPressed]
					elseif InputHelper.ControllerToString[MCM.Config.LastSelectPressed] then
						selectString = InputHelper.ControllerToString[MCM.Config.LastSelectPressed]
					end
				end
				Font10:DrawString(selectString, (bottomRight.X - Font10:GetStringWidthUTF8(selectString)/2) - 36, bottomRight.Y - 24, mainFontColor, 0, true)
				
			end
			
		end
	else
		for i=1, #CacheHelper.Players do
			local player = CacheHelper.Players[i]
			local data = player:GetData()
			
			--enable player controls
			if data.ConfigMenuPlayerPosition then
				data.ConfigMenuPlayerPosition = nil
			end
			if data.ConfigMenuPlayerControlsDisabled then
				player.ControlsEnabled = true
				data.ConfigMenuPlayerControlsDisabled = false
			end
		end
		
		configMenuInSubcategory = false
		configMenuInOptions = false
		configMenuInPopup = false
		
		holdingCounterDown = 0
		holdingCounterUp = 0
		holdingCounterLeft = 0
		holdingCounterRight = 0
		
		configMenuPositionCursorCategory = 1
		configMenuPositionCursorSubcategory = 1
		configMenuPositionCursorOption = 1
		configMenuPositionFirstCategory = 1
		configMenuPositionFirstSubcategory = 1
		configMenuPositionFirstOption = 1
	end
end)

CallbackHelper.AddCallback(MCMMod, CallbackHelper.Callbacks.CH_GAME_START, function(_, player, isSaveGame)
	MCM.IsVisible = false
end)

function MCM.OpenConfigMenu()
	if MCM.RoomIsSafe() then
		if MCM.Config.HideHudInMenu then
			seeds:AddSeedEffect(SeedEffect.SEED_NO_HUD)
		end
		MCM.IsVisible = true
	else
		sfx:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ, 0.75, 0, false, 1)
	end
end

function MCM.CloseConfigMenu()
	MCM.LeavePopup()
	MCM.LeaveOptions()
	MCM.LeaveSubcategory()
	seeds:RemoveSeedEffect(SeedEffect.SEED_NO_HUD)
	MCM.IsVisible = false
end

function MCM.ToggleConfigMenu()
	if MCM.IsVisible then
		MCM.CloseConfigMenu()
	else
		MCM.OpenConfigMenu()
	end
end

--prevents the pause menu from opening when in the mod config menu
MCMMod:AddCallback(ModCallbacks.MC_INPUT_ACTION, function(_, entity, inputHook, buttonAction)
	if MCM.IsVisible and buttonAction ~= ButtonAction.ACTION_FULLSCREEN and buttonAction ~= ButtonAction.ACTION_CONSOLE then
		if inputHook == InputHook.IS_ACTION_PRESSED or inputHook == InputHook.IS_ACTION_TRIGGERED then 
			return false
		else
			return 0
		end
	end
end)

--returns true if the room is clear and there are no active enemies and there are no projectiles
MCM.IgnoreActiveEnemies = {}
function MCM.RoomIsSafe()

	local roomHasDanger = false
	
	for _, entity in pairs(Isaac.GetRoomEntities()) do
		if entity:IsActiveEnemy() and not entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
		and (not MCM.IgnoreActiveEnemies[entity.Type] or (MCM.IgnoreActiveEnemies[entity.Type] and not MCM.IgnoreActiveEnemies[entity.Type][-1] and not MCM.IgnoreActiveEnemies[entity.Type][entity.Variant])) then
			roomHasDanger = true
		elseif entity.Type == EntityType.ENTITY_PROJECTILE and entity:ToProjectile().ProjectileFlags & ProjectileFlags.CANT_HIT_PLAYER ~= 1 then
			roomHasDanger = true
		elseif entity.Type == EntityType.ENTITY_BOMBDROP then
			roomHasDanger = true
		end
	end
	
	if room:IsClear() and not roomHasDanger then
		return true
	end
	
	return false
	
end

local checkedForPotato = false
CallbackHelper.AddCallback(MCMMod, CallbackHelper.Callbacks.CH_GAME_START, function(_, player, isSaveGame)
	if not checkedForPotato then
	
		local potatoType = Isaac.GetEntityTypeByName("Potato Dummy")
		local potatoVariant = Isaac.GetEntityVariantByName("Potato Dummy")
		
		if potatoType and potatoType > 0 then
			MCM.IgnoreActiveEnemies[potatoType] = {}
			MCM.IgnoreActiveEnemies[potatoType][potatoVariant] = true
		end
		
		checkedForPotato = true
		
	end
end)

--console commands that toggle the menu
local toggleCommands = {
	["modconfigmenu"] = true,
	["modconfig"] = true,
	["mcm"] = true,
	["mc"] = true
}
MCMMod:AddCallback(ModCallbacks.MC_EXECUTE_CMD, function(_, command, args)
	command = command:lower()
	if toggleCommands[command] then
		MCM.ToggleConfigMenu()
	end
end)


------------
--FINISHED--
------------
Isaac.DebugString("Mod Config Menu v" .. MCM.Version .. " loaded!")
print("Mod Config Menu v" .. MCM.Version .. " loaded!")


return MCM
