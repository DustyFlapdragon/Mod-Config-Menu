--the version of this script
local currentVersion = 13

--remove any previous versions that may exist
if ModConfigMenu then
	local thisVersion = 1
	if ModConfigMenu.Version then
		thisVersion = ModConfigMenu.Version
	end
	if thisVersion < currentVersion then
		ModConfigMenu = nil
		Isaac.DebugString("Removed older mod config menu (version " .. thisVersion .. ")")
	end
end

if not ModConfigMenu then
	ModConfigMenu = RegisterMod("Mod Config Menu", 1)
	ModConfigMenu.Version = currentVersion
	Isaac.DebugString("Loading Mod Config Menu v" .. ModConfigMenu.Version)
	
	if ModConfigMenu.StandaloneMod == nil then
		ModConfigMenu.StandaloneMod = false
	end
	
	ModConfigMenu.VECTOR_ZERO = Vector(0,0)
	ModConfigMenu.VECTOR_ONE = Vector(1,1)
	
	ModConfigMenu.VECTOR_LEFT = Vector(-1,0)
	ModConfigMenu.VECTOR_UP = Vector(0,-1)
	ModConfigMenu.VECTOR_RIGHT = Vector(1,0)
	ModConfigMenu.VECTOR_DOWN = Vector(0,1)
	ModConfigMenu.VECTOR_UP_LEFT = Vector(-1,-1)
	ModConfigMenu.VECTOR_UP_RIGHT = Vector(1,-1)
	ModConfigMenu.VECTOR_DOWN_LEFT = Vector(-1,1)
	ModConfigMenu.VECTOR_DOWN_RIGHT = ModConfigMenu.VECTOR_ONE
	
	ModConfigMenu.COLOR_DEFAULT = Color(1,1,1,1,0,0,0)
	ModConfigMenu.COLOR_HALF = Color(1,1,1,0.5,0,0,0)
	ModConfigMenu.COLOR_INVISIBLE = Color(1,1,1,0,0,0,0)
	ModConfigMenu.KCOLOR_DEFAULT = KColor(1,1,1,1)
	ModConfigMenu.KCOLOR_HALF = KColor(1,1,1,0.5)
	ModConfigMenu.KCOLOR_INVISIBLE = KColor(1,1,1,0)
	
	ModConfigMenu.Game = Game()
	ModConfigMenu.Seeds = ModConfigMenu.Game:GetSeeds()
	ModConfigMenu.Level = ModConfigMenu.Game:GetLevel()
	ModConfigMenu.Room = ModConfigMenu.Game:GetRoom()
	ModConfigMenu.SFX = SFXManager()
	
	ModConfigMenu:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
		ModConfigMenu.Game = Game()
		ModConfigMenu.Seeds = ModConfigMenu.Game:GetSeeds()
		ModConfigMenu.Level = ModConfigMenu.Game:GetLevel()
		ModConfigMenu.Room = ModConfigMenu.Game:GetRoom()
		ModConfigMenu.SFX = SFXManager()
	end)
	
	ModConfigMenu.ControlsEnabled = true
	
	--table handlers
	function ModConfigMenu.CopyTable(tableToCopy)
		local table2 = {}
		for i, value in pairs(tableToCopy) do
			if type(value) == "table" then
				table2[i] = ModConfigMenu.CopyTable(value)
			else
				table2[i] = value
			end
		end
		return table2
	end
	
	function ModConfigMenu.FillTable(tableToFill, tableToFillFrom)
		for i, value in pairs(tableToFillFrom) do
			if tableToFill[i] ~= nil then
				if type(value) == "table" then
					tableToFill[i] = ModConfigMenu.FillTable(tableToFill[i], value)
				else
					tableToFill[i] = value
				end
			else
				if type(value) == "table" then
					tableToFill[i] = ModConfigMenu.FillTable({}, value)
				else
					tableToFill[i] = value
				end
			end
		end
		return tableToFill
	end
	
	--custom callbacks
	ModConfigMenu.HudOffsetCallbacks = {}
	function ModConfigMenu.AddHudOffsetChangeCallback(callbackFunction)
		if not callbackFunction then
			error("AddHudOffsetChangeCallback Error: No valid callback function provided")
			return
		end
		ModConfigMenu.HudOffsetCallbacks = ModConfigMenu.HudOffsetCallbacks or {}
		ModConfigMenu.HudOffsetCallbacks[#ModConfigMenu.HudOffsetCallbacks+1] = callbackFunction
	end
	
	ModConfigMenu.OverlayCallbacks = {}
	function ModConfigMenu.AddOverlayChangeCallback(callbackFunction)
		if not callbackFunction then
			error("AddOverlayChangeCallback Error: No valid callback function provided")
			return
		end
		ModConfigMenu.OverlayCallbacks = ModConfigMenu.OverlayCallbacks or {}
		ModConfigMenu.OverlayCallbacks[#ModConfigMenu.OverlayCallbacks+1] = callbackFunction
	end
	
	ModConfigMenu.ChargeBarCallbacks = {}
	function ModConfigMenu.AddChargeBarChangeCallback(callbackFunction)
		if not callbackFunction then
			error("AddChargeBarChangeCallback Error: No valid callback function provided")
			return
		end
		ModConfigMenu.ChargeBarCallbacks = ModConfigMenu.ChargeBarCallbacks or {}
		ModConfigMenu.ChargeBarCallbacks[#ModConfigMenu.ChargeBarCallbacks+1] = callbackFunction
	end
	
	ModConfigMenu.BigBookCallbacks = {}
	function ModConfigMenu.AddBigBookChangeCallback(callbackFunction)
		if not callbackFunction then
			error("AddBigBookChangeCallback Error: No valid callback function provided")
			return
		end
		ModConfigMenu.BigBookCallbacks = ModConfigMenu.BigBookCallbacks or {}
		ModConfigMenu.BigBookCallbacks[#ModConfigMenu.BigBookCallbacks+1] = callbackFunction
	end
	
	--enums
	ModConfigMenuController = {
		DPAD_LEFT = 0,
		DPAD_RIGHT = 1,
		DPAD_UP = 2,
		DPAD_DOWN = 3,
		BUTTON_A = 4,
		BUTTON_B = 5,
		BUTTON_X = 6,
		BUTTON_Y = 7,
		BUMPER_LEFT = 8,
		TRIGGER_LEFT = 9,
		STICK_LEFT = 10,
		BUMPER_RIGHT = 11,
		TRIGGER_RIGHT = 12,
		STICK_RIGHT = 13,
		BUTTON_BACK = 14,
		BUTTON_START = 15
	}
	
	ModConfigMenuKeyboardToString = {}
	do
		for key,num in pairs(Keyboard) do
			local keyString = key
			
			local keyStart, keyEnd = string.find(keyString, "KEY_")
			keyString = string.sub(keyString, keyEnd+1, string.len(keyString))
			
			keyString = string.gsub(keyString, "_", " ")
			
			ModConfigMenuKeyboardToString[num] = keyString
		end
	end
	
	ModConfigMenuControllerToString = {}
	do
		for button,num in pairs(ModConfigMenuController) do
			local buttonString = button
			
			if string.match(buttonString, "BUTTON_") then
				local buttonStart, buttonEnd = string.find(buttonString, "BUTTON_")
				buttonString = string.sub(buttonString, buttonEnd+1, string.len(buttonString))
			end
			
			if string.match(buttonString, "BUMPER_") then
				local bumperStart, bumperEnd = string.find(buttonString, "BUMPER_")
				buttonString = string.sub(buttonString, bumperEnd+1, string.len(buttonString)) .. "_BUMPER"
			end
			
			if string.match(buttonString, "TRIGGER_") then
				local triggerStart, triggerEnd = string.find(buttonString, "TRIGGER_")
				buttonString = string.sub(buttonString, triggerEnd+1, string.len(buttonString)) .. "_TRIGGER"
			end
			
			if string.match(buttonString, "STICK_") then
				local stickStart, stickEnd = string.find(buttonString, "STICK_")
				buttonString = string.sub(buttonString, stickEnd+1, string.len(buttonString)) .. "_STICK"
			end
			
			buttonString = string.gsub(buttonString, "_", " ")
			
			ModConfigMenuControllerToString[num] = buttonString
		end
	end
	
	ModConfigMenuOptionType = {
		TEXT = 1,
		SPACE = 2,
		SCROLL = 3,
		BOOLEAN = 4,
		NUMBER = 5,
		KEYBIND_KEYBOARD = 6,
		KEYBIND_CONTROLLER = 7,
		TITLE = 8
	}
	
	--saving
	ModConfigMenu.ConfigDefault = {
		HudOffset = 0,
		Overlays = true,
		ChargeBars = false,
		BigBooks = true,
		
		OpenMenuKeyboard = Keyboard.KEY_L,
		OpenMenuController = ModConfigMenuController.STICK_RIGHT,
		
		HideHudInMenu = true,
		ResetToDefault = Keyboard.KEY_R,
		ShowControls = true,
		
		LastBackPressed = Keyboard.KEY_BACKSPACE,
		LastSelectPressed = Keyboard.KEY_ENTER
	}
	ModConfigMenu.Config = ModConfigMenu.CopyTable(ModConfigMenu.ConfigDefault)
	
	local json = require("json")
	
	function ModConfigMenu.ClearSave(bypassGameStart)
		if ModConfigMenu.GameStarted or bypassGameStart then
			ModConfigMenu.Config = ModConfigMenu.CopyTable(ModConfigMenu.ConfigDefault)
		end
	end
	
	function ModConfigMenu.Save(bypassGameStart)
		if ModConfigMenu.GameStarted or bypassGameStart then
			local saveData = ModConfigMenu.CopyTable(ModConfigMenu.ConfigDefault)
			saveData = ModConfigMenu.FillTable(saveData, ModConfigMenu.Config)
			
			ModConfigMenu:SaveData(json.encode(saveData))
		end
	end
	
	function ModConfigMenu.Load(fromSave)
		local saveData = ModConfigMenu.CopyTable(ModConfigMenu.ConfigDefault)
		
		if ModConfigMenu:HasData() then
			local loadData = json.decode(ModConfigMenu:LoadData())
			saveData = ModConfigMenu.FillTable(saveData, loadData)
		end
		
		ModConfigMenu.Config = ModConfigMenu.CopyTable(saveData)
		ModConfigMenu.Save(true)
	end
	
	ModConfigMenu.GameStarted = false
	ModConfigMenu:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, isSaveGame)
		ModConfigMenu.GameStarted = true
		
		ModConfigMenu.Load(isSaveGame)
	end)
	
	ModConfigMenu:AddCallback(ModCallbacks.MC_POST_GAME_END, function(_, gameOver)
		ModConfigMenu.Save()
		ModConfigMenu.ClearSave(true)
		
		ModConfigMenu.GameStarted = false
	end)
	
	ModConfigMenu:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function(_, shouldSave)
		ModConfigMenu.Save()
		ModConfigMenu.ClearSave(true)
		
		ModConfigMenu.GameStarted = false
	end)
	
	--screen position functions
	function ModConfigMenu.GetScreenCenterPosition()
		local shape = ModConfigMenu.Room:GetRoomShape()
		local centerOffset = (ModConfigMenu.Room:GetCenterPos()) - ModConfigMenu.Room:GetTopLeftPos()
		local pos = ModConfigMenu.Room:GetCenterPos()
		if centerOffset.X > 260 then
			pos.X = pos.X - 260
		end
		if shape == RoomShape.ROOMSHAPE_LBL or shape == RoomShape.ROOMSHAPE_LTL then
			pos.X = pos.X - 260
		end
		if centerOffset.Y > 140 then
			pos.Y = pos.Y - 140
		end
		if shape == RoomShape.ROOMSHAPE_LTR or shape == RoomShape.ROOMSHAPE_LTL then
			pos.Y = pos.Y - 140
		end
		return Isaac.WorldToRenderPosition(pos, false)
	end
	
	function ModConfigMenu.GetScreenBottomRight(offset, doHealthOffset, doCardOffset)
		local pos = ModConfigMenu.GetScreenCenterPosition() * 2
		
		if not offset then
			offset = ModConfigMenu.Config.HudOffset
		end
		
		local hudOffset = Vector(-offset * 2.2, -offset * 1.6)
		if doHealthOffset then
			hudOffset = Vector((-offset * 1.6) - ((offset - 10) * 0.2), -offset * 0.6)
		elseif doCardOffset then
			hudOffset = Vector(-offset * 1.6, -offset * 0.6)
		end
		pos = pos + hudOffset

		return pos
	end

	function ModConfigMenu.GetScreenBottomLeft(offset)
		local pos = Vector(0, ModConfigMenu.GetScreenBottomRight(0).Y)
		
		if not offset then
			offset = ModConfigMenu.Config.HudOffset
		end
		
		local hudOffset = Vector(offset * 2.2, -offset * 1.6)
		pos = pos + hudOffset
		
		return pos
	end

	function ModConfigMenu.GetScreenTopRight(offset, doHealthOffset)
		local pos = Vector(ModConfigMenu.GetScreenBottomRight(0).X, 0)
		
		if not offset then
			offset = ModConfigMenu.Config.HudOffset
		end
		
		local hudOffset = Vector(-offset * 2.2, offset * 1.2)
		if doHealthOffset then
			hudOffset = Vector((-offset * 2.2) - ((offset - 10) * 0.2), offset * 1.2)
		end
		pos = pos + hudOffset

		return pos
	end
	
	function ModConfigMenu.GetScreenTopLeft(offset)
		local pos = ModConfigMenu.VECTOR_ZERO
		
		if not offset then
			offset = ModConfigMenu.Config.HudOffset
		end
		
		local hudOffset = Vector(offset * 2, offset * 1.2)
		pos = pos + hudOffset
		
		return pos
	end

	--display info on new run, based on stageapi code
    local versionPrintTimer = 0
    ModConfigMenu:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function()
		if ModConfigMenu.Config.ShowControls then
			versionPrintTimer = 120
		else
			versionPrintTimer = 60
		end
    end)
    ModConfigMenu:AddCallback(ModCallbacks.MC_POST_UPDATE, function()
        if versionPrintTimer > 0 then
            versionPrintTimer = versionPrintTimer - 1
        end
    end)
    ModConfigMenu:AddCallback(ModCallbacks.MC_POST_RENDER, function()
        if versionPrintTimer > 0 then
            local bottomRight = ModConfigMenu.GetScreenBottomRight(0)
			local center = ModConfigMenu.GetScreenCenterPosition()
            local renderY = bottomRight.Y - 28
            local renderX = center.X

			local openMenuButton = Keyboard.KEY_F10
			if ModConfigMenu.Config.OpenMenuKeyboard and ModConfigMenu.Config.OpenMenuKeyboard > -1 then
				openMenuButton = ModConfigMenu.Config.OpenMenuKeyboard
			end

			local openMenuButtonString = "Unknown Key"
			if ModConfigMenuKeyboardToString[openMenuButton] then
				openMenuButtonString = ModConfigMenuKeyboardToString[openMenuButton]
			end
			
			local text = "Press " .. openMenuButtonString .. " to open Mod Config Menu"
			Isaac.RenderScaledText(text, renderX - Isaac.GetTextWidth(text) * 0.25, renderY, 0.5, 0.5, 1, 1, 0, (math.min(versionPrintTimer, 60)/60) * 0.5)
        end
    end)
	
	--based on some revelations menu code, handles some dumb controller input nonsense
	function ModConfigMenu.SafeKeyboardTriggered(key, controllerIndex)
		return Input.IsButtonTriggered(key, controllerIndex) and not Input.IsButtonTriggered(key % 32, controllerIndex)
	end
	function ModConfigMenu.SafeKeyboardPressed(key, controllerIndex)
		return Input.IsButtonPressed(key, controllerIndex) and not Input.IsButtonPressed(key % 32, controllerIndex)
	end
	
	--multiple button checks
	function ModConfigMenu.MultipleActionTriggered(actions, controllerIndex)
		for i,action in pairs(actions) do
			for index=0, 4 do
				if controllerIndex ~= nil then
					index = controllerIndex
				end
				if Input.IsActionTriggered(action, index) then
					return action
				end
				if controllerIndex ~= nil then
					break
				end
			end
		end
		return nil
	end
	
	function ModConfigMenu.MultipleActionPressed(actions, controllerIndex)
		for i,action in pairs(actions) do
			for index=0, 4 do
				if controllerIndex ~= nil then
					index = controllerIndex
				end
				if Input.IsActionPressed(action, index) then
					return action
				end
				if controllerIndex ~= nil then
					break
				end
			end
		end
		return nil
	end
	
	function ModConfigMenu.MultipleButtonTriggered(buttons, controllerIndex)
		for i,button in pairs(buttons) do
			for index=0, 4 do
				if controllerIndex ~= nil then
					index = controllerIndex
				end
				if Input.IsButtonTriggered(button, index) then
					return button
				end
				if controllerIndex ~= nil then
					break
				end
			end
		end
		return nil
	end
	
	function ModConfigMenu.MultipleButtonPressed(buttons, controllerIndex)
		for i,button in pairs(buttons) do
			for index=0, 4 do
				if controllerIndex ~= nil then
					index = controllerIndex
				end
				if Input.IsButtonPressed(button, index) then
					return button
				end
				if controllerIndex ~= nil then
					break
				end
			end
		end
		return nil
	end
	
	function ModConfigMenu.MultipleKeyboardTriggered(keys, controllerIndex)
		for i,key in pairs(keys) do
			for index=0, 4 do
				if controllerIndex ~= nil then
					index = controllerIndex
				end
				if ModConfigMenu.SafeKeyboardTriggered(key, index) then
					return key
				end
				if controllerIndex ~= nil then
					break
				end
			end
		end
		return nil
	end
	
	function ModConfigMenu.MultipleKeyboardPressed(keys, controllerIndex)
		for i,key in pairs(keys) do
			for index=0, 4 do
				if controllerIndex ~= nil then
					index = controllerIndex
				end
				if ModConfigMenu.SafeKeyboardPressed(key, index) then
					return key
				end
				if controllerIndex ~= nil then
					break
				end
			end
		end
		return nil
	end
	
	--set up the menu sprites and font
	local renderingConfigMenu = false
	
	local configMenuMain = Sprite()
	configMenuMain:Load("gfx/ui/modconfig/menu.anm2", true)
	configMenuMain:SetFrame("Idle", 0)
	
	local configMenuPopup = Sprite()
	configMenuPopup:Load("gfx/ui/modconfig/menu.anm2", true)
	configMenuPopup:SetFrame("Popup", 0)
	
	local configMenuCursor = Sprite()
	configMenuCursor:Load("gfx/ui/modconfig/menu.anm2", true)
	configMenuCursor:SetFrame("Cursor", 0)
	
	local configMenuCursorUp = Sprite()
	configMenuCursorUp:Load("gfx/ui/modconfig/menu.anm2", true)
	configMenuCursorUp:SetFrame("Cursor", 3)
	
	local configMenuCursorDown = Sprite()
	configMenuCursorDown:Load("gfx/ui/modconfig/menu.anm2", true)
	configMenuCursorDown:SetFrame("Cursor", 4)
	
	local configMenuOptionsCursorUp = Sprite()
	configMenuOptionsCursorUp:Load("gfx/ui/modconfig/menu.anm2", true)
	configMenuOptionsCursorUp:SetFrame("Cursor", 3)
	configMenuOptionsCursorUp.Color = ModConfigMenu.COLOR_HALF
	
	local configMenuOptionsCursorDown = Sprite()
	configMenuOptionsCursorDown:Load("gfx/ui/modconfig/menu.anm2", true)
	configMenuOptionsCursorDown:SetFrame("Cursor", 4)
	configMenuOptionsCursorDown.Color = ModConfigMenu.COLOR_HALF
	
	local configMenuSubcategoryCursorLeft = Sprite()
	configMenuSubcategoryCursorLeft:Load("gfx/ui/modconfig/menu.anm2", true)
	configMenuSubcategoryCursorLeft:SetFrame("Cursor", 5)
	configMenuSubcategoryCursorLeft.Color = ModConfigMenu.COLOR_HALF
	
	local configMenuSubcategoryCursorRight = Sprite()
	configMenuSubcategoryCursorRight:Load("gfx/ui/modconfig/menu.anm2", true)
	configMenuSubcategoryCursorRight:SetFrame("Cursor", 0)
	configMenuSubcategoryCursorRight.Color = ModConfigMenu.COLOR_HALF
	
	local configMenuSubcategoryDivider = Sprite()
	configMenuSubcategoryDivider:Load("gfx/ui/modconfig/menu.anm2", true)
	configMenuSubcategoryDivider:SetFrame("Cursor", 6)
	configMenuSubcategoryDivider.Color = ModConfigMenu.COLOR_HALF
	
	local configMenuCrosshairRed = Sprite()
	configMenuCrosshairRed:Load("gfx/ui/modconfig/menu.anm2", true)
	configMenuCrosshairRed:SetFrame("Cursor", 2)
	
	local configMenuSlider1 = Sprite()
	configMenuSlider1:Load("gfx/ui/modconfig/menu.anm2", true)
	configMenuSlider1:SetFrame("Slider1", 0)
	
	local configMenuSlider2 = Sprite()
	configMenuSlider2:Load("gfx/ui/modconfig/menu.anm2", true)
	configMenuSlider2:SetFrame("Slider2", 0)
	
	local configMenuOptionsCorner = Sprite()
	configMenuOptionsCorner:Load("gfx/ui/modconfig/menu.anm2", true)
	configMenuOptionsCorner:SetFrame("Corner", 0)
	
	local strikeOut = Sprite()
	strikeOut:Load("gfx/ui/modconfig/menu.anm2", true)
	strikeOut:SetFrame("Strikeout", 0)
	
	local CornerSelect = Sprite()
	CornerSelect:Load("gfx/ui/modconfig/menu.anm2", true)
	CornerSelect:SetFrame("BackSelect", 0)
	
	local CornerBack = Sprite()
	CornerBack:Load("gfx/ui/modconfig/menu.anm2", true)
	CornerBack:SetFrame("BackSelect", 1)
	
	local CornerOpen = Sprite()
	CornerOpen:Load("gfx/ui/modconfig/menu.anm2", true)
	CornerOpen:SetFrame("BackSelect", 2)
	
	local CornerExit = Sprite()
	CornerExit:Load("gfx/ui/modconfig/menu.anm2", true)
	CornerExit:SetFrame("BackSelect", 3)
	
	local configMenuFont10 = Font()
	configMenuFont10:Load("font/teammeatfont10.fnt")
	local configMenuFont12 = Font()
	configMenuFont12:Load("font/teammeatfont12.fnt")
	local configMenuFont16 = Font()
	configMenuFont16:Load("font/teammeatfont16.fnt")
	local configMenuFont16Bold = Font()
	configMenuFont16Bold:Load("font/teammeatfont16bold.fnt")
	local configMenuFont20Bold = Font()
	configMenuFont20Bold:Load("font/teammeatfont20bold.fnt")
	
	ModConfigMenuPopupGfx = {
		THIN_SMALL = "gfx/ui/modconfig/popup_thin_small.png",
		THIN_MEDIUM = "gfx/ui/modconfig/popup_thin_medium.png",
		THIN_LARGE = "gfx/ui/modconfig/popup_thin_large.png",
		WIDE_SMALL = "gfx/ui/modconfig/popup_wide_small.png",
		WIDE_MEDIUM = "gfx/ui/modconfig/popup_wide_medium.png",
		WIDE_LARGE = "gfx/ui/modconfig/popup_wide_large.png"
	}
	
	--config menu data tables and functions
	ModConfigMenuData = {}
	function ModConfigMenu.AddSetting(category, subcategory, settingTable)
		if settingTable == nil then
			settingTable = subcategory
			subcategory = nil
		end
		
		if subcategory == nil then
			subcategory = "Uncategorized"
		end
		
		local categoryToChange = nil
		local subcategoryToChange = nil
		for i=1, #ModConfigMenuData do
			if category == ModConfigMenuData[i].Name then
				categoryToChange = i
				for j=1, #ModConfigMenuData[i].Subcategories do
					if subcategory == ModConfigMenuData[i].Subcategories[j].Name then
						subcategoryToChange = j
					end
				end
				break
			end
		end
		
		if categoryToChange == nil then
			categoryToChange = #ModConfigMenuData+1
			ModConfigMenuData[categoryToChange] = {}
			ModConfigMenuData[categoryToChange].Name = tostring(category)
			ModConfigMenuData[categoryToChange].Subcategories = {}
		end
		
		if subcategoryToChange == nil then
			subcategoryToChange = #ModConfigMenuData[categoryToChange].Subcategories+1
			ModConfigMenuData[categoryToChange].Subcategories[subcategoryToChange] = {}
			ModConfigMenuData[categoryToChange].Subcategories[subcategoryToChange].Name = tostring(subcategory)
			ModConfigMenuData[categoryToChange].Subcategories[subcategoryToChange].Options = {}
		end
		
		ModConfigMenuData[categoryToChange].Subcategories[subcategoryToChange].Options[#ModConfigMenuData[categoryToChange].Subcategories[subcategoryToChange].Options+1] = settingTable
		
		return settingTable
	end
	function ModConfigMenu.AddText(category, subcategory, text, color)
		if color == nil and type(text) ~= "string" and type(text) ~= "function" then
			color = text
			text = subcategory
			subcategory = nil
		end
		
		local settingTable = {
			Type = ModConfigMenuOptionType.TEXT,
			Display = text,
			Color = color,
			NoCursorHere = true
		}
		
		return ModConfigMenu.AddSetting(category, subcategory, settingTable)
	end
	function ModConfigMenu.AddTitle(category, subcategory, text, color)
		if color == nil and type(text) ~= "string" and type(text) ~= "function" then
			color = text
			text = subcategory
			subcategory = nil
		end
		
		local settingTable = {
			Type = ModConfigMenuOptionType.TITLE,
			Display = text,
			Color = color,
			NoCursorHere = true
		}
		
		return ModConfigMenu.AddSetting(category, subcategory, settingTable)
	end
	function ModConfigMenu.AddSpace(category, subcategory)
		local settingTable = {
			Type = ModConfigMenuOptionType.SPACE
		}
		
		return ModConfigMenu.AddSetting(category, subcategory, settingTable)
	end
	
	--add the default settings
	ModConfigMenu.AddSetting("General", { --HUD OFFSET
		Type = ModConfigMenuOptionType.SCROLL,
		CurrentSetting = function()
			return ModConfigMenu.Config.HudOffset
		end,
		Default = ModConfigMenu.ConfigDefault.HudOffset,
		Display = function(cursorIsHere)
			if cursorIsHere then
				configMenuOptionsCorner:SetFrame("Corner", 2)
				configMenuOptionsCorner:Render(ModConfigMenu.GetScreenBottomRight(), ModConfigMenu.VECTOR_ZERO, ModConfigMenu.VECTOR_ZERO)
				
				configMenuOptionsCorner:SetFrame("Corner", 3)
				configMenuOptionsCorner:Render(ModConfigMenu.GetScreenBottomLeft(), ModConfigMenu.VECTOR_ZERO, ModConfigMenu.VECTOR_ZERO)
				
				configMenuOptionsCorner:SetFrame("Corner", 1)
				configMenuOptionsCorner:Render(ModConfigMenu.GetScreenTopRight(), ModConfigMenu.VECTOR_ZERO, ModConfigMenu.VECTOR_ZERO)
				
				configMenuOptionsCorner:SetFrame("Corner", 0)
				configMenuOptionsCorner:Render(ModConfigMenu.GetScreenTopLeft(), ModConfigMenu.VECTOR_ZERO, ModConfigMenu.VECTOR_ZERO)
			end
			return "Hud Offset: $scroll" .. tostring(math.floor(ModConfigMenu.Config.HudOffset))
		end,
		OnChange = function(currentNum)
			ModConfigMenu.Config.HudOffset = currentNum
			if #ModConfigMenu.HudOffsetCallbacks > 0 then
				for _, callbackFunction in ipairs(ModConfigMenu.HudOffsetCallbacks) do
					callbackFunction(currentNum)
				end
			end
		end,
		Info = {
			"Hud offset to be used by mods",
			"that support this setting."
		},
		HideControls = true
	})
	ModConfigMenu.AddSetting("General", { --OVERLAYS
		Type = ModConfigMenuOptionType.BOOLEAN,
		CurrentSetting = function()
			return ModConfigMenu.Config.Overlays
		end,
		Default = ModConfigMenu.ConfigDefault.Overlays,
		Display = function()
			local onOff = "Off"
			if ModConfigMenu.Config.Overlays then
				onOff = "On"
			end
			return "Overlays: " .. onOff
		end,
		OnChange = function(currentBool)
			ModConfigMenu.Config.Overlays = currentBool
			if #ModConfigMenu.OverlayCallbacks > 0 then
				for _, callbackFunction in ipairs(ModConfigMenu.OverlayCallbacks) do
					callbackFunction(currentBool)
				end
			end
		end,
		Info = {
			"Enable or disable overlays for mods",
			"that support this setting."
		}
	})
	ModConfigMenu.AddSetting("General", { --CHARGE BARS
		Type = ModConfigMenuOptionType.BOOLEAN,
		CurrentSetting = function()
			return ModConfigMenu.Config.ChargeBars
		end,
		Default = ModConfigMenu.ConfigDefault.ChargeBars,
		Display = function()
			local onOff = "Off"
			if ModConfigMenu.Config.ChargeBars then
				onOff = "On"
			end
			return "Charge Bars: " .. onOff
		end,
		OnChange = function(currentBool)
			ModConfigMenu.Config.ChargeBars = currentBool
			if #ModConfigMenu.ChargeBarCallbacks > 0 then
				for _, callbackFunction in ipairs(ModConfigMenu.ChargeBarCallbacks) do
					callbackFunction(currentBool)
				end
			end
		end,
		Info = {
			"Enable or disable charge bars for mods",
			"that support this setting."
		}
	})
	ModConfigMenu.AddSetting("General", { --BIGBOOKS
		Type = ModConfigMenuOptionType.BOOLEAN,
		CurrentSetting = function()
			return ModConfigMenu.Config.BigBooks
		end,
		Default = ModConfigMenu.ConfigDefault.BigBooks,
		Display = function()
			local onOff = "Off"
			if ModConfigMenu.Config.BigBooks then
				onOff = "On"
			end
			return "Bigbooks: " .. onOff
		end,
		OnChange = function(currentBool)
			ModConfigMenu.Config.BigBooks = currentBool
			if #ModConfigMenu.BigBookCallbacks > 0 then
				for _, callbackFunction in ipairs(ModConfigMenu.BigBookCallbacks) do
					callbackFunction(currentBool)
				end
			end
		end,
		Info = {
			"Enable or disable bigbooks for mods",
			"that support this setting."
		}
	})
	ModConfigMenu.AddSpace("General") --SPACE
	ModConfigMenu.AddSetting("General", { --KEYBOARD KEYBIND
		Type = ModConfigMenuOptionType.KEYBIND_KEYBOARD,
		IsOpenMenuKeybind = true,
		CurrentSetting = function()
			return ModConfigMenu.Config.OpenMenuKeyboard
		end,
		Default = ModConfigMenu.ConfigDefault.OpenMenuKeyboard,
		Display = function()
			local key = "None"
			if ModConfigMenu.Config.OpenMenuKeyboard > -1 then
				key = "Unknown Key"
				if ModConfigMenuKeyboardToString[ModConfigMenu.Config.OpenMenuKeyboard] then
					key = ModConfigMenuKeyboardToString[ModConfigMenu.Config.OpenMenuKeyboard]
				end
			end
			return "Open Menu: " .. key .. " (keyboard)"
		end,
		OnChange = function(currentNum)
			if not currentNum then
				currentNum = -1
			end
			ModConfigMenu.Config.OpenMenuKeyboard = currentNum
		end,
		Info = {
			"Keyboard button that opens this menu.",
			"",
			"F10 will always open this menu."
		},
		PopupGfx = ModConfigMenuPopupGfx.WIDE_SMALL,
		Popup = function()
			local goBackString = "back"
			if ModConfigMenu.Config.LastBackPressed then
				if ModConfigMenuKeyboardToString[ModConfigMenu.Config.LastBackPressed] then
					goBackString = ModConfigMenuKeyboardToString[ModConfigMenu.Config.LastBackPressed]
				elseif ModConfigMenuControllerToString[ModConfigMenu.Config.LastBackPressed] then
					goBackString = ModConfigMenuControllerToString[ModConfigMenu.Config.LastBackPressed]
				end
			end
			
			local keepSettingString1 = ""
			local keepSettingString2 = ""
			if ModConfigMenu.Config.OpenMenuKeyboard > -1 and ModConfigMenuKeyboardToString[ModConfigMenu.Config.OpenMenuKeyboard] then
				keepSettingString1 = "This setting is currently set to \"" .. ModConfigMenuKeyboardToString[ModConfigMenu.Config.OpenMenuKeyboard] .. "\"."
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
	ModConfigMenu.AddSetting("General", { --CONTROLLER KEYBIND
		Type = ModConfigMenuOptionType.KEYBIND_CONTROLLER,
		IsOpenMenuKeybind = true,
		CurrentSetting = function()
			return ModConfigMenu.Config.OpenMenuController
		end,
		Default = ModConfigMenu.ConfigDefault.OpenMenuController,
		Display = function()
			local key = "None"
			if ModConfigMenu.Config.OpenMenuController > -1 then
				key = "Unknown Button"
				if ModConfigMenuControllerToString[ModConfigMenu.Config.OpenMenuController] then
					key = ModConfigMenuControllerToString[ModConfigMenu.Config.OpenMenuController]
				end
			end
			return "Open Menu: " .. key .. " (controller)"
		end,
		OnChange = function(currentNum)
			if not currentNum then
				currentNum = -1
			end
			ModConfigMenu.Config.OpenMenuController = currentNum
		end,
		Info = {
			"Controller button that opens this menu.",
			"",
			"F10 will always open this menu."
		},
		PopupGfx = ModConfigMenuPopupGfx.WIDE_SMALL,
		Popup = function()
			local goBackString = "back"
			if ModConfigMenu.Config.LastBackPressed then
				if ModConfigMenuKeyboardToString[ModConfigMenu.Config.LastBackPressed] then
					goBackString = ModConfigMenuKeyboardToString[ModConfigMenu.Config.LastBackPressed]
				elseif ModConfigMenuControllerToString[ModConfigMenu.Config.LastBackPressed] then
					goBackString = ModConfigMenuControllerToString[ModConfigMenu.Config.LastBackPressed]
				end
			end
			
			local keepSettingString1 = ""
			local keepSettingString2 = ""
			if ModConfigMenu.Config.OpenMenuController > -1 and ModConfigMenuControllerToString[ModConfigMenu.Config.OpenMenuController] then
				keepSettingString1 = "This setting is currently set to \"" .. ModConfigMenuControllerToString[ModConfigMenu.Config.OpenMenuController] .. "\"."
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
	-- ModConfigMenu.AddText("General", "F10 will always open this menu.")
	
	ModConfigMenu.AddSpace("General") --SPACE
	
	ModConfigMenu.AddSetting("General", { --HIDE HUD
		Type = ModConfigMenuOptionType.BOOLEAN,
		CurrentSetting = function()
			return ModConfigMenu.Config.HideHudInMenu
		end,
		Default = ModConfigMenu.ConfigDefault.HideHudInMenu,
		Display = function()
			local onOff = "No"
			if ModConfigMenu.Config.HideHudInMenu then
				onOff = "Yes"
			end
			return "Hide HUD: " .. onOff
		end,
		OnChange = function(currentBool)
			ModConfigMenu.Config.HideHudInMenu = currentBool
			
			if currentBool then
				if not ModConfigMenu.Seeds:HasSeedEffect(SeedEffect.SEED_NO_HUD) then
					ModConfigMenu.Seeds:AddSeedEffect(SeedEffect.SEED_NO_HUD)
				end
			else
				if ModConfigMenu.Seeds:HasSeedEffect(SeedEffect.SEED_NO_HUD) then
					ModConfigMenu.Seeds:RemoveSeedEffect(SeedEffect.SEED_NO_HUD)
				end
			end
		end,
		Info = "Enable or disable the hud when this menu is open."
	})
	ModConfigMenu.AddSetting("General", { --RESET TO DEFAULT BUTTON
		Type = ModConfigMenuOptionType.KEYBIND_KEYBOARD,
		IsResetKeybind = true,
		CurrentSetting = function()
			return ModConfigMenu.Config.ResetToDefault
		end,
		Default = ModConfigMenu.ConfigDefault.ResetToDefault,
		Display = function()
			local key = "None"
			if ModConfigMenu.Config.ResetToDefault > -1 then
				key = "Unknown Key"
				if ModConfigMenuKeyboardToString[ModConfigMenu.Config.ResetToDefault] then
					key = ModConfigMenuKeyboardToString[ModConfigMenu.Config.ResetToDefault]
				end
			end
			return "Reset To Default Keybind: " .. key
		end,
		OnChange = function(currentNum)
			if not currentNum then
				currentNum = -1
			end
			ModConfigMenu.Config.ResetToDefault = currentNum
		end,
		Info = {
			"Press this keyboard button to reset a setting",
			"to its default value if supported."
		},
		PopupGfx = ModConfigMenuPopupGfx.WIDE_SMALL,
		Popup = function()
			local goBackString = "back"
			if ModConfigMenu.Config.LastBackPressed then
				if ModConfigMenuKeyboardToString[ModConfigMenu.Config.LastBackPressed] then
					goBackString = ModConfigMenuKeyboardToString[ModConfigMenu.Config.LastBackPressed]
				elseif ModConfigMenuControllerToString[ModConfigMenu.Config.LastBackPressed] then
					goBackString = ModConfigMenuControllerToString[ModConfigMenu.Config.LastBackPressed]
				end
			end
			
			local keepSettingString1 = ""
			local keepSettingString2 = ""
			if ModConfigMenu.Config.ResetToDefault > -1 and ModConfigMenuKeyboardToString[ModConfigMenu.Config.ResetToDefault] then
				keepSettingString1 = "This setting is currently set to \"" .. ModConfigMenuKeyboardToString[ModConfigMenu.Config.ResetToDefault] .. "\"."
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
	ModConfigMenu.AddSetting("General", { --SHOW CONTROLS
		Type = ModConfigMenuOptionType.BOOLEAN,
		CurrentSetting = function()
			return ModConfigMenu.Config.ShowControls
		end,
		Default = ModConfigMenu.ConfigDefault.ShowControls,
		Display = function()
			local onOff = "No"
			if ModConfigMenu.Config.ShowControls then
				onOff = "Yes"
			end
			return "Show Controls: " .. onOff
		end,
		OnChange = function(currentBool)
			ModConfigMenu.Config.ShowControls = currentBool
		end,
		Info = {
			"Disable this to remove the start-up message",
			"and the back and select widgets",
			"at the lower corners of the screen."
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
	local ignoreActionButtons = {ModConfigMenuController.BUTTON_A, ModConfigMenuController.BUTTON_B, ModConfigMenuController.BUTTON_X, ModConfigMenuController.BUTTON_Y}
	
	local currentMenuCategory = nil
	local currentMenuSubcategory = nil
	local currentMenuOption = nil
	local function updateCurrentMenuVars()
		if ModConfigMenuData[configMenuPositionCursorCategory] then
			currentMenuCategory = ModConfigMenuData[configMenuPositionCursorCategory]
			if currentMenuCategory.Subcategories and currentMenuCategory.Subcategories[configMenuPositionCursorSubcategory] then
				currentMenuSubcategory = currentMenuCategory.Subcategories[configMenuPositionCursorSubcategory]
				if currentMenuSubcategory.Options and currentMenuSubcategory.Options[configMenuPositionCursorOption] then
					currentMenuOption = currentMenuSubcategory.Options[configMenuPositionCursorOption]
				end
			end
		end
	end
	
	--leaving/entering menu sections
	function ModConfigMenu.EnterPopup()
		if configMenuInSubcategory and configMenuInOptions and not configMenuInPopup then
			local foundValidPopup = false
			if currentMenuOption
			and currentMenuOption.Type
			and currentMenuOption.Type ~= ModConfigMenuOptionType.SPACE
			and currentMenuOption.Popup then
				foundValidPopup = true
			end
			if foundValidPopup then
				local popupSpritesheet = ModConfigMenuPopupGfx.THIN_SMALL
				if currentMenuOption.PopupGfx and type(currentMenuOption.PopupGfx) == "string" then
					popupSpritesheet = currentMenuOption.PopupGfx
				end
				configMenuPopup:ReplaceSpritesheet(8, popupSpritesheet)
				configMenuPopup:LoadGraphics()
				configMenuInPopup = true
			end
		end
	end
	
	function ModConfigMenu.EnterOptions()
		if configMenuInSubcategory and not configMenuInOptions then
			if currentMenuSubcategory
			and currentMenuSubcategory.Options
			and #currentMenuSubcategory.Options > 0 then
			
				for optionIndex=1, #currentMenuSubcategory.Options do
					
					local thisOption = currentMenuSubcategory.Options[optionIndex]
					
					if thisOption.Type
					and thisOption.Type ~= ModConfigMenuOptionType.SPACE
					and (not thisOption.NoCursorHere or (type(thisOption.NoCursorHere) == "function" and not thisOption.NoCursorHere()))
					and thisOption.Display then
					
						configMenuPositionCursorOption = optionIndex
						configMenuInOptions = true
						configMenuOptionsCursorUp.Color = ModConfigMenu.COLOR_DEFAULT
						configMenuOptionsCursorDown.Color = ModConfigMenu.COLOR_DEFAULT
						
						break
					end
				end
			end
		end
	end
	
	function ModConfigMenu.EnterSubcategory()
		if not configMenuInSubcategory then
			configMenuInSubcategory = true
			configMenuSubcategoryCursorLeft.Color = ModConfigMenu.COLOR_DEFAULT
			configMenuSubcategoryCursorRight.Color = ModConfigMenu.COLOR_DEFAULT
			configMenuSubcategoryDivider.Color = ModConfigMenu.COLOR_DEFAULT
			
			local hasUsableCategories = false
			if currentMenuCategory.Subcategories then
				for j=1, #currentMenuCategory.Subcategories do
					if currentMenuCategory.Subcategories[j].Name ~= "Uncategorized" then
						hasUsableCategories = true
					end
				end
			end
			
			if not hasUsableCategories then
				ModConfigMenu.EnterOptions()
			end
		end
	end
	
	function ModConfigMenu.LeavePopup()
		if configMenuInSubcategory and configMenuInOptions and configMenuInPopup then
			configMenuInPopup = false
		end
	end
	
	function ModConfigMenu.LeaveOptions()
		if configMenuInSubcategory and configMenuInOptions then
			configMenuInOptions = false
			configMenuOptionsCursorUp.Color = ModConfigMenu.COLOR_HALF
			configMenuOptionsCursorDown.Color = ModConfigMenu.COLOR_HALF
			
			local hasUsableCategories = false
			if currentMenuCategory.Subcategories then
				for j=1, #currentMenuCategory.Subcategories do
					if currentMenuCategory.Subcategories[j].Name ~= "Uncategorized" then
						hasUsableCategories = true
					end
				end
			end
			
			if not hasUsableCategories then
				ModConfigMenu.LeaveSubcategory()
			end
		end
	end
	
	function ModConfigMenu.LeaveSubcategory()
		if configMenuInSubcategory then
			configMenuInSubcategory = false
			configMenuSubcategoryCursorLeft.Color = ModConfigMenu.COLOR_HALF
			configMenuSubcategoryCursorRight.Color = ModConfigMenu.COLOR_HALF
			configMenuSubcategoryDivider.Color = ModConfigMenu.COLOR_HALF
		end
	end
	
	local mainSpriteColor = ModConfigMenu.COLOR_DEFAULT
	local optionsSpriteColor = ModConfigMenu.COLOR_DEFAULT
	local optionsSpriteColorAlpha = ModConfigMenu.COLOR_HALF
	local mainFontColor = KColor(34/255,32/255,30/255,1)
	local leftFontColor = KColor(35/255,31/255,30/255,1)
	local leftFontColorSelected = KColor(35/255,50/255,70/255,1)
	local optionsFontColor = KColor(34/255,32/255,30/255,1)
	local optionsFontColorTitle = KColor(50/255,0,0,1)
	local optionsFontColorAlpha = KColor(34/255,32/255,30/255,0.5)
	local optionsFontColorTitleAlpha = KColor(50/255,0,0,0.5)
	local subcategoryFontColor = KColor(34/255,32/255,30/255,1)
	local subcategoryFontColorSelected = KColor(34/255,50/255,70/255,1)
	local subcategoryFontColorAlpha = KColor(34/255,32/255,30/255,0.5)
	local subcategoryFontColorSelectedAlpha = KColor(34/255,50/255,70/255,0.5)
	
	--render the menu
	ModConfigMenu:AddCallback(ModCallbacks.MC_POST_RENDER, function()
		local isPaused = ModConfigMenu.Game:IsPaused()

		local pressingButton = ""

		local pressingNonRebindableKey = false
		local pressedToggleMenu = false

		local openMenuGlobal = Keyboard.KEY_F10
		local openMenuKeyboard = ModConfigMenu.Config.OpenMenuKeyboard
		local openMenuController = ModConfigMenu.Config.OpenMenuController

		if ModConfigMenu.ControlsEnabled and not isPaused then
			for i=0, 4 do
				if ModConfigMenu.SafeKeyboardTriggered(openMenuGlobal, i)
				or (openMenuKeyboard > -1 and ModConfigMenu.SafeKeyboardTriggered(openMenuKeyboard, i))
				or (openMenuController > -1 and Input.IsButtonTriggered(openMenuController, i)) then
					pressingNonRebindableKey = true
					pressedToggleMenu = true
					if not configMenuInPopup then
						ModConfigMenu.ToggleConfigMenu()
					end
				end
			end
		end
		
		--force close the menu in some situations
		if renderingConfigMenu then
		
			if isPaused then
				ModConfigMenu.CloseConfigMenu()
			end
			
			if not ModConfigMenu.RoomIsSafe() then
				ModConfigMenu.CloseConfigMenu()
				ModConfigMenu.SFX:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ, 0.75, 0, false, 1)
			end
			
		end

		if revel and revel.data and revel.data.controllerToggle then
			if openMenuController == ModConfigMenuController.STICK_RIGHT and (revel.data.controllerToggle == 1 or revel.data.controllerToggle == 3 or revel.data.controllerToggle == 4) then
				revel.data.controllerToggle = 2 --force revelations' menu to only use the left stick
			elseif openMenuController == ModConfigMenuController.STICK_LEFT and (revel.data.controllerToggle == 1 or revel.data.controllerToggle == 2 or revel.data.controllerToggle == 4) then
				revel.data.controllerToggle = 3 --force revelations' menu to only use the right stick
			end
		end
		
		if renderingConfigMenu then
			if ModConfigMenu.ControlsEnabled and not isPaused then
				for i=1, ModConfigMenu.Game:GetNumPlayers() do
					local player = Isaac.GetPlayer(i-1)
					local data = player:GetData()
					
					--freeze players and disable their controls
					player.Velocity = ModConfigMenu.VECTOR_ZERO
					
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
				
				if not ModConfigMenu.MultipleButtonTriggered(ignoreActionButtons) then
					--pressing buttons
					local downButtonPressed = ModConfigMenu.MultipleActionTriggered(actionsDown)
					if downButtonPressed then
						pressingButton = "DOWN"
					end
					local upButtonPressed = ModConfigMenu.MultipleActionTriggered(actionsUp)
					if upButtonPressed then
						pressingButton = "UP"
					end
					local rightButtonPressed = ModConfigMenu.MultipleActionTriggered(actionsRight)
					if rightButtonPressed then
						pressingButton = "RIGHT"
					end
					local leftButtonPressed = ModConfigMenu.MultipleActionTriggered(actionsLeft)
					if leftButtonPressed then
						pressingButton = "LEFT"
					end
					local backButtonPressed = ModConfigMenu.MultipleActionTriggered(actionsBack) or ModConfigMenu.MultipleKeyboardTriggered({Keyboard.KEY_BACKSPACE})
					if backButtonPressed then
						pressingButton = "BACK"
						local possiblyPressedButton = ModConfigMenu.MultipleKeyboardTriggered(Keyboard)
						if possiblyPressedButton then
							ModConfigMenu.Config.LastBackPressed = possiblyPressedButton
						end
					end
					local selectButtonPressed = ModConfigMenu.MultipleActionTriggered(actionsSelect)
					if selectButtonPressed then
						pressingButton = "SELECT"
						local possiblyPressedButton = ModConfigMenu.MultipleKeyboardTriggered(Keyboard)
						if possiblyPressedButton then
							ModConfigMenu.Config.LastSelectPressed = possiblyPressedButton
						end
					end
					if ModConfigMenu.Config.ResetToDefault > -1 and ModConfigMenu.MultipleKeyboardTriggered({ModConfigMenu.Config.ResetToDefault}) then
						pressingButton = "RESET"
					end
					
					--holding buttons
					if ModConfigMenu.MultipleActionPressed(actionsDown) then
						holdingCounterDown = holdingCounterDown + 1
					else
						holdingCounterDown = 0
					end
					if holdingCounterDown > 20 and holdingCounterDown%5 == 0 then
						pressingButton = "DOWN"
					end
					if ModConfigMenu.MultipleActionPressed(actionsUp) then
						holdingCounterUp = holdingCounterUp + 1
					else
						holdingCounterUp = 0
					end
					if holdingCounterUp > 20 and holdingCounterUp%5 == 0 then
						pressingButton = "UP"
					end
					if ModConfigMenu.MultipleActionPressed(actionsRight) then
						holdingCounterRight = holdingCounterRight + 1
					else
						holdingCounterRight = 0
					end
					if holdingCounterRight > 20 and holdingCounterRight%5 == 0 then
						pressingButton = "RIGHT"
					end
					if ModConfigMenu.MultipleActionPressed(actionsLeft) then
						holdingCounterLeft = holdingCounterLeft + 1
					else
						holdingCounterLeft = 0
					end
					if holdingCounterLeft > 20 and holdingCounterLeft%5 == 0 then
						pressingButton = "LEFT"
					end
				else
					if ModConfigMenu.MultipleButtonTriggered({ModConfigMenuController.BUTTON_B}) then
						pressingButton = "BACK"
					end
					if ModConfigMenu.MultipleButtonTriggered({ModConfigMenuController.BUTTON_A}) then
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

					if optionType == ModConfigMenuOptionType.KEYBIND_KEYBOARD or optionType == ModConfigMenuOptionType.KEYBIND_CONTROLLER or currentMenuOption.OnSelect then

						if not isPaused then

							if pressingNonRebindableKey
							and not (pressingButton == "BACK"
							or pressingButton == "LEFT"
							or (currentMenuOption.OnSelect and (pressingButton == "SELECT" or pressingButton == "RIGHT"))
							or (currentMenuOption.IsResetKeybind and pressingButton == "RESET")
							or (currentMenuOption.IsOpenMenuKeybind and pressedToggleMenu)) then
								ModConfigMenu.SFX:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ, 0.75, 0, false, 1)
							else
								local numberToChange = nil
								local recievedInput = false
								if optionType == ModConfigMenuOptionType.KEYBIND_KEYBOARD or optionType == ModConfigMenuOptionType.KEYBIND_CONTROLLER then
									numberToChange = optionCurrent
									
									if type(optionCurrent) == "function" then
										numberToChange = optionCurrent()
									end
									
									if pressingButton == "BACK" or pressingButton == "LEFT" then
										numberToChange = nil
										recievedInput = true
									else
										for i=0, 4 do
											if optionType == ModConfigMenuOptionType.KEYBIND_KEYBOARD then
												for j=32, 400 do
													if ModConfigMenu.SafeKeyboardTriggered(j, i) then
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
									if optionType == ModConfigMenuOptionType.KEYBIND_KEYBOARD or optionType == ModConfigMenuOptionType.KEYBIND_CONTROLLER then
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
										ModConfigMenu.SFX:Play(sound, 1, 0, false, 1)
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
						
						if optionType == ModConfigMenuOptionType.SCROLL or optionType == ModConfigMenuOptionType.NUMBER then
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
							
							if optionType == ModConfigMenuOptionType.SCROLL then
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
								ModConfigMenu.SFX:Play(sound, 1, 0, false, 1)
							end
						elseif optionType == ModConfigMenuOptionType.BOOLEAN then
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
								ModConfigMenu.SFX:Play(sound, 1, 0, false, 1)
							end
						elseif (optionType == ModConfigMenuOptionType.KEYBIND_KEYBOARD or optionType == ModConfigMenuOptionType.KEYBIND_CONTROLLER) and pressingButton == "RESET" and currentMenuOption.Default ~= nil then
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
								ModConfigMenu.SFX:Play(sound, 1, 0, false, 1)
							end
						elseif optionType ~= ModConfigMenuOptionType.SPACE and pressingButton == "RIGHT" then
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
					ModConfigMenu.CloseConfigMenu()
				end
				
				--confirmed select press
				if pressingButton == "SELECT" then
					enterSubcategory = true
				end
			end
			
			--entering popup
			if enterPopup then
				ModConfigMenu.EnterPopup()
			end
			
			--leaving popup
			if leavePopup then
				ModConfigMenu.LeavePopup()
			end
			
			--entering subcategory
			if enterSubcategory then
				ModConfigMenu.EnterSubcategory()
			end
			
			--entering options
			if enterOptions then
				ModConfigMenu.EnterOptions()
			end
			
			--leaving options
			if leaveOptions then
				ModConfigMenu.LeaveOptions()
			end
			
			--leaving subcategory
			if leaveSubcategory then
				ModConfigMenu.LeaveSubcategory()
			end
			
			--category cursor position was changed
			if lastCursorCategoryPosition ~= configMenuPositionCursorCategory then
				if not configMenuInSubcategory then
					--cursor position
					if configMenuPositionCursorCategory < 1 then --move from the top of the list to the bottom
						configMenuPositionCursorCategory = #ModConfigMenuData
					end
					if configMenuPositionCursorCategory > #ModConfigMenuData then --move from the bottom of the list to the top
						configMenuPositionCursorCategory = 1
					end
					
					--first category selection to render
					if configMenuPositionFirstCategory > 1 and configMenuPositionCursorCategory <= configMenuPositionFirstCategory+1 then
						configMenuPositionFirstCategory = configMenuPositionCursorCategory-1
					end
					if configMenuPositionFirstCategory+(configMenuCategoryCanShow-1) < #ModConfigMenuData and configMenuPositionCursorCategory >= configMenuPositionFirstCategory+(configMenuCategoryCanShow-2) then
						configMenuPositionFirstCategory = configMenuPositionCursorCategory-(configMenuCategoryCanShow-2)
					end
					configMenuPositionFirstCategory = math.min(math.max(configMenuPositionFirstCategory, 1), #ModConfigMenuData-(configMenuCategoryCanShow-1))
					
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
						and thisOption.Type ~= ModConfigMenuOptionType.SPACE
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
			
			local centerPos = ModConfigMenu.GetScreenCenterPosition()
			local leftPos = centerPos + Vector(-142,-102)
			local titlePos = centerPos + Vector(68,-118)
			local infoPos = centerPos + Vector(-4,106)
			local optionPos = centerPos + Vector(68,-88)
			
			configMenuMain:Render(centerPos, ModConfigMenu.VECTOR_ZERO, ModConfigMenu.VECTOR_ZERO)
			
			--category
			local lastLeftPos = leftPos
			local renderedLeft = 0
			for categoryIndex=1, #ModConfigMenuData do
				if categoryIndex >= configMenuPositionFirstCategory then
					--text
					local textToDraw = tostring(ModConfigMenuData[categoryIndex].Name)
					
					local color = leftFontColor
					--[[
					if configMenuPositionCursorCategory == categoryIndex then
						color = leftFontColorSelected
					end
					]]
					
					local posOffset = configMenuFont12:GetStringWidthUTF8(textToDraw)/2
					configMenuFont12:DrawString(textToDraw, lastLeftPos.X - posOffset, lastLeftPos.Y - 8, color, 0, true)
					
					--cursor
					if configMenuPositionCursorCategory == categoryIndex then
						configMenuCursor:Render(lastLeftPos + Vector((posOffset + 10)*-1,0), ModConfigMenu.VECTOR_ZERO, ModConfigMenu.VECTOR_ZERO)
					end
					
					--increase counter
					renderedLeft = renderedLeft + 1
					if renderedLeft >= configMenuCategoryCanShow then --if this is the last one we should render
						--render scroll arrows
						if configMenuPositionFirstCategory > 1 then --if the first one we rendered wasnt the first in the list
							configMenuCursorUp:Render(leftPos + Vector(45,-4), ModConfigMenu.VECTOR_ZERO, ModConfigMenu.VECTOR_ZERO)
						end
						if categoryIndex < #ModConfigMenuData then --if this isnt the last category
							configMenuCursorDown:Render(lastLeftPos + Vector(45,4), ModConfigMenu.VECTOR_ZERO, ModConfigMenu.VECTOR_ZERO)
						end
						break
					end
					
					--pos mod
					lastLeftPos = lastLeftPos + Vector(0,16)
				end
			end
			
			--title
			local titleText = "Mod Config"
			if configMenuInSubcategory then
				titleText = tostring(currentMenuCategory.Name)
			end
			local titleTextOffset = configMenuFont16Bold:GetStringWidthUTF8(titleText)/2
			configMenuFont16Bold:DrawString(titleText, titlePos.X - titleTextOffset, titlePos.Y - 10, mainFontColor, 0, true)
			
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
								
								posOffset = configMenuFont12:GetStringWidthUTF8(textToDraw)/2
								configMenuFont12:DrawString(textToDraw, lastSubcategoryPos.X - posOffset, lastSubcategoryPos.Y - 8, color, 0, true)
							end
							
							--cursor
							if configMenuPositionCursorSubcategory == subcategoryIndex and configMenuInSubcategory then
								configMenuCursor:Render(lastSubcategoryPos + Vector((posOffset + 10)*-1,0), ModConfigMenu.VECTOR_ZERO, ModConfigMenu.VECTOR_ZERO)
							end
							
							--increase counter
							renderedSubcategories = renderedSubcategories + 1
							if renderedSubcategories >= configMenuSubcategoriesCanShow then --if this is the last one we should render
								--render scroll arrows
								if configMenuPositionFirstSubcategory > 1 then --if the first one we rendered wasnt the first in the list
									configMenuSubcategoryCursorLeft:Render(lastOptionPos + Vector(-125,0), ModConfigMenu.VECTOR_ZERO, ModConfigMenu.VECTOR_ZERO)
								end
								if subcategoryIndex < #currentMenuCategory.Subcategories then --if this isnt the last thing
									configMenuSubcategoryCursorRight:Render(lastOptionPos + Vector(125,0), ModConfigMenu.VECTOR_ZERO, ModConfigMenu.VECTOR_ZERO)
								end
								break
							end
							
							--pos mod
							lastSubcategoryPos = lastSubcategoryPos + Vector(76,0)
						end
					end
					
					renderedOptions = renderedOptions + 1
					lastOptionPos = lastOptionPos + Vector(0,14)
					
					configMenuSubcategoryDivider:Render(lastOptionPos, ModConfigMenu.VECTOR_ZERO, ModConfigMenu.VECTOR_ZERO)
					
					renderedOptions = renderedOptions + 1
					lastOptionPos = lastOptionPos + Vector(0,14)
				end
			end
			
			--options
			
			local firstOptionPos = lastOptionPos
			
			if currentMenuSubcategory
			and currentMenuSubcategory.Options
			and #currentMenuSubcategory.Options > 0 then
			
				for optionIndex=1, #currentMenuSubcategory.Options do
				
					if optionIndex >= configMenuPositionFirstOption then
						
						local thisOption = currentMenuSubcategory.Options[optionIndex]
						
						local cursorIsAtThisOption = configMenuPositionCursorOption == optionIndex and configMenuInOptions
						local posOffset = 10
						
						if thisOption.Type
						and thisOption.Type ~= ModConfigMenuOptionType.SPACE
						and thisOption.Display then
						
							local optionType = thisOption.Type
							local optionDisplay = thisOption.Display
							local optionColor = thisOption.Color
							
							--get what to draw
							if optionType == ModConfigMenuOptionType.TEXT
							or optionType == ModConfigMenuOptionType.BOOLEAN
							or optionType == ModConfigMenuOptionType.NUMBER
							or optionType == ModConfigMenuOptionType.KEYBIND_KEYBOARD
							or optionType == ModConfigMenuOptionType.KEYBIND_CONTROLLER
							or optionType == ModConfigMenuOptionType.TITLE then
								local textToDraw = optionDisplay
								
								if type(optionDisplay) == "function" then
									textToDraw = optionDisplay(cursorIsAtThisOption, configMenuInOptions, lastOptionPos)
								end
								
								textToDraw = tostring(textToDraw)
								
								local heightOffset = 6
								local font = configMenuFont10
								local color = optionsFontColor
								if not configMenuInOptions then
									color = optionsFontColorAlpha
								end
								if optionType == ModConfigMenuOptionType.TITLE then
									heightOffset = 8
									font = configMenuFont12
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
							elseif optionType == ModConfigMenuOptionType.SCROLL then
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
											textToDrawPreScroll = string.sub(numberToShow, 0, numberToShowStart-1)
											textToDrawPostScroll = string.sub(numberToShow, numberEnd, string.len(numberToShow))
											textToDraw = textToDrawPreScroll .. "               " .. textToDrawPostScroll
											
											local color = optionsFontColor
											if not configMenuInOptions then
												color = optionsFontColorAlpha
											end
											if optionColor then
												color = KColor(optionColor[1], optionColor[2], optionColor[3], color.A)
											end
											
											scrollOffset = posOffset
											posOffset = configMenuFont10:GetStringWidthUTF8(textToDraw)/2
											configMenuFont10:DrawString(textToDraw, lastOptionPos.X - posOffset, lastOptionPos.Y - 6, color, 0, true)
											
											scrollOffset = posOffset - (configMenuFont10:GetStringWidthUTF8(textToDrawPreScroll)+scrollOffset)
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
								configMenuSlider1.Color = scrollColor
								configMenuSlider1:SetFrame("Slider1", numberToShow)
								configMenuSlider1:Render(lastOptionPos - Vector(scrollOffset, -2), ModConfigMenu.VECTOR_ZERO, ModConfigMenu.VECTOR_ZERO)
							end
							
							local showStrikeout = thisOption.ShowStrikeout
							if posOffset > 0 and (type(showStrikeout) == boolean and showStrikeout == true) or (type(showStrikeout) == "function" and showStrikeout() == true) then
								if configMenuInOptions then
									strikeOut.Color = ModConfigMenu.COLOR_DEFAULT
								else
									strikeOut.Color = ModConfigMenu.COLOR_HALF
								end
								strikeOut:SetFrame("Strikeout", math.floor(posOffset))
								strikeOut:Render(lastOptionPos, ModConfigMenu.VECTOR_ZERO, ModConfigMenu.VECTOR_ZERO)
							end
						end
						
						--cursor
						if cursorIsAtThisOption then
							configMenuCursor:Render(lastOptionPos + Vector((posOffset + 10)*-1,0), ModConfigMenu.VECTOR_ZERO, ModConfigMenu.VECTOR_ZERO)
						end
						
						--increase counter
						renderedOptions = renderedOptions + 1
						if renderedOptions >= configMenuOptionsCanShow then --if this is the last one we should render
							--render scroll arrows
							if configMenuPositionFirstOption > 1 then --if the first one we rendered wasnt the first in the list
								configMenuOptionsCursorUp:Render(firstOptionPos + Vector(125,-4), ModConfigMenu.VECTOR_ZERO, ModConfigMenu.VECTOR_ZERO)
							end
							if optionIndex < #currentMenuSubcategory.Options then --if this isnt the last thing
								configMenuOptionsCursorDown:Render(lastOptionPos + Vector(125,4), ModConfigMenu.VECTOR_ZERO, ModConfigMenu.VECTOR_ZERO)
							end
							break
						end
						
						--pos mod
						lastOptionPos = lastOptionPos + Vector(0,14)
					end
				end
			end
			
			--info
			if configMenuInOptions
			and currentMenuOption
			and currentMenuOption.Info then
				local infoTable = currentMenuOption.Info
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
					local posOffset = configMenuFont10:GetStringWidthUTF8(textToDraw)/2
					configMenuFont10:DrawString(textToDraw, lastInfoPos.X - posOffset, lastInfoPos.Y - 6, mainFontColor, 0, true)
					
					--pos mod
					lastInfoPos = lastInfoPos + Vector(0,10)
				end
			end
			
			--popup
			if configMenuInPopup
			and currentMenuOption
			and currentMenuOption.Popup then
				configMenuPopup:Render(centerPos, ModConfigMenu.VECTOR_ZERO, ModConfigMenu.VECTOR_ZERO)
				
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
					local posOffset = configMenuFont10:GetStringWidthUTF8(textToDraw)/2
					configMenuFont10:DrawString(textToDraw, lastPopupPos.X - posOffset, lastPopupPos.Y - 6, mainFontColor, 0, true)
					
					--pos mod
					lastPopupPos = lastPopupPos + Vector(0,10)
				end
			end
			
			--controls
			local shouldShowControls = true
			if configMenuInOptions and currentMenuOption and currentMenuOption.HideControls then
				shouldShowControls = false
			end
			if not ModConfigMenu.Config.ShowControls then
				shouldShowControls = false
			end
			if shouldShowControls then

				--back
				local bottomLeft = ModConfigMenu.GetScreenBottomLeft(0)
				if not configMenuInSubcategory then
					CornerExit:Render(bottomLeft, ModConfigMenu.VECTOR_ZERO, ModConfigMenu.VECTOR_ZERO)
				else
					CornerBack:Render(bottomLeft, ModConfigMenu.VECTOR_ZERO, ModConfigMenu.VECTOR_ZERO)
				end

				local goBackString = ""
				if ModConfigMenu.Config.LastBackPressed then
					if ModConfigMenuKeyboardToString[ModConfigMenu.Config.LastBackPressed] then
						goBackString = ModConfigMenuKeyboardToString[ModConfigMenu.Config.LastBackPressed]
					elseif ModConfigMenuControllerToString[ModConfigMenu.Config.LastBackPressed] then
						goBackString = ModConfigMenuControllerToString[ModConfigMenu.Config.LastBackPressed]
					end
				end
				configMenuFont10:DrawString(goBackString, (bottomLeft.X - configMenuFont10:GetStringWidthUTF8(goBackString)/2) + 36, bottomLeft.Y - 24, mainFontColor, 0, true)

				--select
				local bottomRight = ModConfigMenu.GetScreenBottomRight(0)
				if not configMenuInPopup then
				
					local foundValidPopup = false
					--[[
					if configMenuInSubcategory
					and configMenuInOptions
					and currentMenuOption
					and currentMenuOption.Type
					and currentMenuOption.Type ~= ModConfigMenuOptionType.SPACE
					and currentMenuOption.Popup then
						foundValidPopup = true
					end
					]]
					
					if foundValidPopup then
						CornerOpen:Render(bottomRight, ModConfigMenu.VECTOR_ZERO, ModConfigMenu.VECTOR_ZERO)
					else
						CornerSelect:Render(bottomRight, ModConfigMenu.VECTOR_ZERO, ModConfigMenu.VECTOR_ZERO)
					end
					
					local selectString = ""
					if ModConfigMenu.Config.LastSelectPressed then
						if ModConfigMenuKeyboardToString[ModConfigMenu.Config.LastSelectPressed] then
							selectString = ModConfigMenuKeyboardToString[ModConfigMenu.Config.LastSelectPressed]
						elseif ModConfigMenuControllerToString[ModConfigMenu.Config.LastSelectPressed] then
							selectString = ModConfigMenuControllerToString[ModConfigMenu.Config.LastSelectPressed]
						end
					end
					configMenuFont10:DrawString(selectString, (bottomRight.X - configMenuFont10:GetStringWidthUTF8(selectString)/2) - 36, bottomRight.Y - 24, mainFontColor, 0, true)
					
				end
				
			end
		else
			for i=1, ModConfigMenu.Game:GetNumPlayers() do
				local player = Isaac.GetPlayer(i-1)
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
	
	ModConfigMenu:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, isSaveGame)
		renderingConfigMenu = false
	end)
	
	function ModConfigMenu.OpenConfigMenu()
		if ModConfigMenu.RoomIsSafe() then
			if ModConfigMenu.Config.HideHudInMenu then
				ModConfigMenu.Seeds:AddSeedEffect(SeedEffect.SEED_NO_HUD)
			end
			renderingConfigMenu = true
		else
			ModConfigMenu.SFX:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ, 0.75, 0, false, 1)
		end
	end
	
	function ModConfigMenu.CloseConfigMenu()
		ModConfigMenu.LeavePopup()
		ModConfigMenu.LeaveOptions()
		ModConfigMenu.LeaveSubcategory()
		ModConfigMenu.Seeds:RemoveSeedEffect(SeedEffect.SEED_NO_HUD)
		renderingConfigMenu = false
	end
	
	function ModConfigMenu.ToggleConfigMenu()
		if renderingConfigMenu then
			ModConfigMenu.CloseConfigMenu()
		else
			ModConfigMenu.OpenConfigMenu()
		end
	end
	
	--prevents the pause menu from opening when in the mod config menu
	ModConfigMenu:AddCallback(ModCallbacks.MC_INPUT_ACTION, function(_, entity, inputHook, buttonAction)
		if renderingConfigMenu and buttonAction ~= ButtonAction.ACTION_FULLSCREEN and buttonAction ~= ButtonAction.ACTION_CONSOLE then
			if inputHook == InputHook.IS_ACTION_PRESSED or inputHook == InputHook.IS_ACTION_TRIGGERED then 
				return false
			else
				return 0
			end
		end
	end)
	
	--returns true if the room is clear and there are no active enemies and there are no projectiles
	ModConfigMenu.IgnoreActiveEnemies = {}
	function ModConfigMenu.RoomIsSafe()
	
		local roomHasDanger = false
		
		for _, entity in pairs(Isaac.GetRoomEntities()) do
			if entity:IsActiveEnemy() and not entity:HasEntityFlags(EntityFlag.FLAG_FRIENDLY)
			and (not ModConfigMenu.IgnoreActiveEnemies[entity.Type] or (ModConfigMenu.IgnoreActiveEnemies[entity.Type] and not ModConfigMenu.IgnoreActiveEnemies[entity.Type][-1] and not ModConfigMenu.IgnoreActiveEnemies[entity.Type][entity.Variant])) then
				roomHasDanger = true
			elseif entity.Type == EntityType.ENTITY_PROJECTILE and entity:ToProjectile().ProjectileFlags & ProjectileFlags.CANT_HIT_PLAYER ~= 1 then
				roomHasDanger = true
			elseif entity.Type == EntityType.ENTITY_BOMBDROP then
				roomHasDanger = true
			end
		end
		
		if ModConfigMenu.Room:IsClear() and not roomHasDanger then
			return true
		end
		
		return false
		
	end
	
	local checkedForPotato = false
	ModConfigMenu:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, function(_, isSaveGame)
		if not checkedForPotato then
		
			local potatoType = Isaac.GetEntityTypeByName("Potato Dummy")
			local potatoVariant = Isaac.GetEntityVariantByName("Potato Dummy")
			
			if potatoType and potatoType > 0 then
				ModConfigMenu.IgnoreActiveEnemies[potatoType] = {}
				ModConfigMenu.IgnoreActiveEnemies[potatoType][potatoVariant] = true
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
	ModConfigMenu:AddCallback(ModCallbacks.MC_EXECUTE_CMD, function(_, command, args)
		command = command:lower()
		if toggleCommands[command] then
			ModConfigMenu.ToggleConfigMenu()
		end
	end)
	
	------------
	--FINISHED--
	------------
	ModConfigMenu.FinishedLoadingMessage = "Mod Config Menu v" .. ModConfigMenu.Version .. " loaded!"
	if not ModConfigMenuIsStandalone then
		Isaac.DebugString(ModConfigMenu.FinishedLoadingMessage)
		print(ModConfigMenu.FinishedLoadingMessage)
	end
end


ModConfigMenu.ForceError() --this function doesn't exist, we do this to cause an error intentionally