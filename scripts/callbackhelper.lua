local CallbackHelper = {}
CallbackHelper.Version = 1

--[[

CALLBACK HELPER v1
by piber

Make sure this is located in MOD/scripts/callbackhelper.lua otherwise it wont load properly!

Do not edit this script file as it could conflict with the release version of this file used by other mods. If you find a bug or need to something changed, let me know.

-------

REQUIREMENTS:
- CacheHelper

-------

Callback Helper's goals:
- Make it easier to combine all callbacks of the same type to a single one, for use in bugged callbacks where only one will work.
- Make creation of custom callbacks easier.
- Contain some general-usage custom callbacks to make it easier for modders to run code when they want.

Callback Helper has a custom add callback function which, if you use it with a vanilla callback id, it combines it into a single callback for your mod. Callback Helper also has some functionality to assist in the process of creating new custom callbacks.

]]

--create the mod
local CallbackHelperMod = RegisterMod("Callback Helper", 1)

--require some lua libraries
local CacheHelper = require("scripts.cachehelper")

--cached values
local game = CacheHelper.Game


------------------------
--custom callback enum--
------------------------
CallbackHelper.Callbacks = {

	--use these callbacks with CallbackHelper.AddCallback(modRef, callbackID, callbackFunction, extraVar)
	--using a vanilla callback id will register the callback to modRef normally but consolidated into a single callback if you use this multiple times

	--PRE/POST ADD CUSTOM CALLBACK
	--custom callback functions that run when a callback gets added through callback helper's custom callback function (crazy huh?)
	--specify a callback id to make your code trigger for only that specific callback
	--in PRE you can return false to prevent the callback from being added
	--function(modRef, callbackID, callbackFunction, extraVar)
	CH_PRE_ADD_CUSTOM_CALLBACK = 100,
	CH_POST_ADD_CUSTOM_CALLBACK = 101,
	
	--GAME START
	--meant to be used in favor of MC_POST_GAME_STARTED, because that callback isnt the first callback to be triggered
	--triggers on the first instance of MC_POST_PLAYER_INIT, the first callback to be called when a game starts
	--makes sure to not trigger on further instances of MC_POST_PLAYER_INIT
	--checks the run counter for if the game a continued game, if it is a continued game then isSaveGame will be true
	--function(player, isSaveGame)
	CH_GAME_START = 102

	--new callback ids should be able to be safely added to this enum

}


---------------------------
--call callbacks function--
---------------------------
--functionToHandleCallbacks is a function that takes what the mod's callback function has returned
--return true within the functionToHandleCallbacks callback to cancel all future functions
--this function returns true if the callbacks were cancelled, otherwise it returns nothing
function CallbackHelper.CallCallbacks(callbackID, functionToHandleCallbacks, args, extraVar)

	if CallbackHelper.AddedCallbacks[callbackID] then
	
		for _, callbackData in ipairs(CallbackHelper.AddedCallbacks[callbackID]) do
		
			if not callbackData.extraVariable or callbackData.extraVariable == extraVar then
			
				local returned = callbackData.functionToCall(callbackData.modReference, table.unpack(args))
				
				local handlerReturned = nil
				if type(functionToHandleCallbacks) == "function" then
					handlerReturned = functionToHandleCallbacks(returned)
				end
				
				if handlerReturned then
					return true
				end
				
			end
			
		end
		
	end
	
end


-------------------------
--add callback function--
-------------------------
CallbackHelper.AddedCallbacks = {}
function CallbackHelper.AddCallback(modRef, callbackID, callbackFunction, extraVar)

	if type(modRef) ~= "table" then
		error("CallbackHelper.AddCallback Error: No valid mod reference provided")
		return
	end
	if type(callbackID) ~= "number" then
		error("CallbackHelper.AddCallback Error: No valid callback ID provided")
		return
	end
	if type(callbackFunction) ~= "function" then
		error("CallbackHelper.AddCallback Error: No valid callback function provided")
		return
	end
	
	--CH_PRE_ADD_CUSTOM_CALLBACK
	local cancelCallback = nil
	
	CallbackHelper.CallCallbacks
	(
		CallbackHelper.Callbacks.CH_PRE_ADD_CUSTOM_CALLBACK, --callback id
		function(returned) --function to handle it
		
			if returned == false then
				cancelCallback = true
				return true
			end
		
		end,
		{modRef, callbackID, callbackFunction, extraVar}, --args to send
		callbackID --extra variable
	)
	
	if cancelCallback then
		return
	end
	
	CallbackHelper.AddedCallbacks[callbackID] = CallbackHelper.AddedCallbacks[callbackID] or {}
	CallbackHelper.AddedCallbacks[callbackID][#CallbackHelper.AddedCallbacks[callbackID]+1] = {modReference = modRef, functionToCall = callbackFunction, extraVariable = extraVar}
	
	--CH_POST_ADD_CUSTOM_CALLBACK
	CallbackHelper.CallCallbacks
	(
		CallbackHelper.Callbacks.CH_POST_ADD_CUSTOM_CALLBACK, --callback id
		nil, --function to handle it
		{modRef, callbackID, callbackFunction, extraVar}, --args to send
		callbackID --extra variable
	)
	
end


-----------------------------
--vanilla callback handling--
-----------------------------
--add special handling for vanilla callbacks - merges all the functions into a singular callback

--if a callback is added with these ids, compares the extra variable with the second arg directly (in the case of returning item ids)
local callbacksCompareExtraVar = {
	[ModCallbacks.MC_USE_ITEM] = true,
	[ModCallbacks.MC_USE_CARD] = true,
	[ModCallbacks.MC_USE_PILL] = true,
	[ModCallbacks.MC_PRE_USE_ITEM] = true
}

--if a callback is added with these ids, compares the extra variable with the Type attribute of the second arg (in the case of entities and needing callbacks specific to their entity type)
local callbacksCompareTypeExtraVar = {
	[ModCallbacks.MC_NPC_UPDATE] = true,
	[ModCallbacks.MC_ENTITY_TAKE_DMG] = true,
	[ModCallbacks.MC_POST_NPC_INIT] = true,
	[ModCallbacks.MC_POST_NPC_RENDER] = true,
	[ModCallbacks.MC_POST_NPC_DEATH] = true,
	[ModCallbacks.MC_PRE_NPC_COLLISION] = true,
	[ModCallbacks.MC_POST_ENTITY_REMOVE] = true,
	[ModCallbacks.MC_POST_ENTITY_KILL] = true,
	[ModCallbacks.MC_PRE_NPC_UPDATE] = true
}

--if a callback is added with these ids, compares the extra variable with the Variant attribute of the second arg (in the case of callbacks specific to an entity type and needing callbacks specific to their entity variant)
local callbacksCompareVariantExtraVar = {
	[ModCallbacks.MC_FAMILIAR_UPDATE] = true,
	[ModCallbacks.MC_FAMILIAR_INIT] = true,
	[ModCallbacks.MC_POST_FAMILIAR_RENDER] = true,
	[ModCallbacks.MC_PRE_FAMILIAR_COLLISION] = true,
	[ModCallbacks.MC_POST_PICKUP_INIT] = true,
	[ModCallbacks.MC_POST_PICKUP_UPDATE] = true,
	[ModCallbacks.MC_POST_PICKUP_RENDER] = true,
	[ModCallbacks.MC_PRE_PICKUP_COLLISION] = true,
	[ModCallbacks.MC_POST_TEAR_INIT] = true,
	[ModCallbacks.MC_POST_TEAR_UPDATE] = true,
	[ModCallbacks.MC_POST_TEAR_RENDER] = true,
	[ModCallbacks.MC_PRE_TEAR_COLLISION] = true,
	[ModCallbacks.MC_POST_PROJECTILE_INIT] = true,
	[ModCallbacks.MC_POST_PROJECTILE_UPDATE] = true,
	[ModCallbacks.MC_POST_PROJECTILE_RENDER] = true,
	[ModCallbacks.MC_PRE_PROJECTILE_COLLISION] = true,
	[ModCallbacks.MC_POST_LASER_INIT] = true,
	[ModCallbacks.MC_POST_LASER_UPDATE] = true,
	[ModCallbacks.MC_POST_LASER_RENDER] = true,
	[ModCallbacks.MC_POST_KNIFE_INIT] = true,
	[ModCallbacks.MC_POST_KNIFE_UPDATE] = true,
	[ModCallbacks.MC_POST_KNIFE_RENDER] = true,
	[ModCallbacks.MC_PRE_KNIFE_COLLISION] = true,
	[ModCallbacks.MC_POST_EFFECT_INIT] = true,
	[ModCallbacks.MC_POST_EFFECT_UPDATE] = true,
	[ModCallbacks.MC_POST_EFFECT_RENDER] = true,
	[ModCallbacks.MC_POST_BOMB_INIT] = true,
	[ModCallbacks.MC_POST_BOMB_UPDATE] = true,
	[ModCallbacks.MC_POST_BOMB_RENDER] = true,
	[ModCallbacks.MC_PRE_BOMB_COLLISION] = true
}

CallbackHelper.ModsAdded = {}
CallbackHelper.AddCallback(CallbackHelperMod, CallbackHelper.Callbacks.CH_POST_ADD_CUSTOM_CALLBACK, function(_, modRef, callbackID, callbackFunction, extraVar)

	if not modRef.CallbackHelper_ModID then
	
		local modID = #CallbackHelper.ModsAdded+1
		
		modRef.CallbackHelper_ModID = modID
		CallbackHelper.ModsAdded[modID] = modRef
		
	end
	
	modRef.CallbackHelper_MergedCallbacksAdded = modRef.CallbackHelper_MergedCallbacksAdded or {}
	if callbackID <= ModCallbacks.MC_PRE_ROOM_ENTITY_SPAWN and not modRef.CallbackHelper_MergedCallbacksAdded[callbackID] then --MC_PRE_ROOM_ENTITY_SPAWN is the last vanilla callback at the time of writing this
	
		modRef:AddCallback(callbackID, function(...)
		
			local args = {...}
			
			--args[1] is the mod reference
			--args[2] would be the first arg returned by the callback (entity/npc or item's id)
			
			if CallbackHelper.AddedCallbacks and CallbackHelper.AddedCallbacks[callbackID] then
			
				for _, callbackData in ipairs(CallbackHelper.AddedCallbacks[callbackID]) do
				
					if args[1].CallbackHelper_ModID == callbackData.modReference.CallbackHelper_ModID then
					
						if not callbackData.extraVariable
						or (callbackData.extraVariable
							and ((callbacksCompareExtraVar[callbackID] and args[2] == callbackData.extraVariable) --compare directly (raw numbers for item ids)
							or (callbacksCompareTypeExtraVar[callbackID] and args[2].Type == callbackData.extraVariable) --compare to entity.Type
							or (callbacksCompareVariantExtraVar[callbackID] and args[2].Variant == callbackData.extraVariable)) --compare to entity.Variant
						) then
						
							local toReturn = callbackData.functionToCall(...)
							if toReturn ~= nil then
								return toReturn
							end
							
						end
						
					end
					
				end
				
			end
			
		end)
		
		modRef.CallbackHelper_MergedCallbacksAdded[callbackID] = true
		
	end
	
end)


--------------
--game start--
--------------
local firstPlayerInited = false
CallbackHelperMod:AddCallback(ModCallbacks.MC_POST_PLAYER_INIT, function(_, player) --player init is the first callback to trigger, before game started, new level, new room, etc

	if not firstPlayerInited then
	
		firstPlayerInited = true
		
		local isSaveGame = false
		if game.TimeCounter > 0 then
			isSaveGame = true
		end
		
		--CH_GAME_START
		CallbackHelper.CallCallbacks
		(
			CallbackHelper.Callbacks.CH_GAME_START, --callback id
			nil, --function to handle it
			{player, isSaveGame} --args to send
		)
		
	end
	
end)
CallbackHelperMod:AddCallback(ModCallbacks.MC_POST_GAME_END, function(_, gameOver)
	firstPlayerInited = false
end)
CallbackHelperMod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function(_, shouldSave)
	firstPlayerInited = false
end)


return CallbackHelper