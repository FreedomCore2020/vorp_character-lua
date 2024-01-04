---@diagnostic disable: undefined-global

local VORPInv = exports.vorp_inventory:vorp_inventoryApi()
local random = math.random(1, #Config.SpawnPosition)
local Core = exports.vorp_core:GetCore()
local MaxCharacters = Core.maxCharacters

Core.Callback.Register("vorp_characters:getMaxCharacters", function(source, cb)
	cb(#MaxCharacters)
end)

RegisterServerEvent("vorp_CreateNewCharacter", function(source)
	TriggerClientEvent("vorpcharacter:startCharacterCreator", source)
end)


RegisterServerEvent("vorpcharacter:saveCharacter", function(skin, clothes, firstname, lastname)
	local _source = source
	local playerCoords = Config.SpawnCoords.position
	local playerHeading = Config.SpawnCoords.heading
	Core.getUser(_source).addCharacter(firstname, lastname, json.encode(skin), json.encode(clothes))
	Wait(600)
	TriggerClientEvent("vorp:initCharacter", _source, playerCoords, playerHeading, false)
	-- wait for char to be made
	SetTimeout(3000, function()
		TriggerEvent("vorp_NewCharacter", _source)
	end)
end)

RegisterServerEvent("vorpcharacter:deleteCharacter", function(charid)
	local _source = source
	local User = Core.getUser(_source)
	User.removeCharacter(charid)
end)

RegisterServerEvent("vorp_CharSelectedCharacter")
AddEventHandler("vorp_CharSelectedCharacter", function(charid)
	local _source = source
	Core.getUser(_source).setUsedCharacter(charid)
end)

RegisterServerEvent("vorpcharacter:getPlayerSkin")
AddEventHandler("vorpcharacter:getPlayerSkin", function()
	local _source = source
	local Character = Core.getUser(_source).getUsedCharacter
	TriggerClientEvent("vorpcharacter:updateCache", _source, json.decode(Character.skin), json.decode(Character.comps))
end)


RegisterNetEvent("vorpcharacter:setPlayerCompChange", function(skinValues, compsValues)
	local _source = source
	local UserCharacter = Core.getUser(_source)
	if UserCharacter then
		local User = UserCharacter.getUsedCharacter
		if compsValues then
			User.updateComps(json.encode(compsValues))
		end

		if skinValues then
			User.updateSkin(json.encode(skinValues))
		end
	end
end)


function Checkmissingkeys(data, key, gender)
	local switch = false
	if key == "skin" then
		for k, v in pairs(PlayerSkin) do
			if data[k] == nil then
				switch = true
				data[k] = v
			end
			if data["Eyes"] == 0 then
				switch = true
				if data["sex"] == "mp_male" then
					data["Eyes"] = 612262189
				else
					data["Eyes"] = 928002221
				end
			end
		end
		return data, switch
	end
	if key == "comps" then
		for k, v in pairs(PlayerClothing) do
			if data[k] == nil then
				data[k] = v
			end
		end
		return data, switch
	end
end

local function UpdateDatabase(character)
	local json_skin = json.decode(character.skin)
	local json_comps = json.decode(character.comps)
	local skin, updateSkin = Checkmissingkeys(json_skin, "skin")
	local comps, updateComp = Checkmissingkeys(json_comps, "comps", skin.sex)

	if updateSkin then
		character.updateSkin((json.encode(skin)))
	end
	if updateComp then
		character.updateComps(json.encode(comps))
	end
	return skin, comps
end

function GetPlayerData(source)
	local User = Core.getUser(source)

	if not User then
		return false
	end
	local Characters = User.getUserCharacters

	local userCharacters = {}
	for _, characters in pairs(Characters) do
		local skin, comps = UpdateDatabase(characters)
		local userChars = {
			charIdentifier = characters.charIdentifier,
			money = characters.money,
			gold = characters.gold,
			firstname = characters.firstname,
			lastname = characters.lastname,
			skin = skin,
			components = comps,
			coords = json.decode(characters.coords),
			isDead = characters.isdead,
			job = characters.jobLabel,
			grade = characters.jobGrade,
			group = characters.group
		}
		userCharacters[#userCharacters + 1] = userChars
	end
	return userCharacters
end

AddEventHandler("vorp_SpawnUniqueCharacter", function(source)
	local userCharacters = GetPlayerData(source)
	if not userCharacters then
		return
	end
	TriggerClientEvent("vorpcharacter:spawnUniqueCharacter", source, userCharacters)
end)


RegisterServerEvent("vorp_GoToSelectionMenu")
AddEventHandler("vorp_GoToSelectionMenu", function(source)
	local _source = source
	if _source == nil then
		print("Source is nil")
		return
	end
	local UserCharacters = GetPlayerData(_source)

	if not UserCharacters then
		return
	end

	TriggerClientEvent("vorpcharacter:selectCharacter", _source, UserCharacters, MaxCharacters, random)
end)

CreateThread(function()
	Wait(1000)
	VORPInv.RegisterUsableItem(Config.secondChanceItem, function(data)
		local _source = data.source
		local User = Core.getUser(_source)

		if not User then
			return false
		end

		VORPInv.CloseInv(_source)
		local Characters = User.getUsedCharacter
		local CharacterSkin = json.decode(Characters.skin)
		local CharacterComps = json.decode(Characters.comps)
		VORPInv.subItem(_source, Config.secondChanceItem, 1)
		TriggerClientEvent("vorp_character:Server:SecondChance", _source, CharacterSkin, CharacterComps)
	end)
end)


RegisterNetEvent("vorp_character:Client:SecondChanceSave", function(skin, comps)
	local _source = source
	local User = Core.getUser(_source)
	local character = User.getUsedCharacter
	character.updateSkin((json.encode(skin)))
	character.updateComps(json.encode(comps))
	local playerCoords = Config.SpawnCoords.position
	local playerHeading = Config.SpawnCoords.heading
	TriggerClientEvent("vorp:initCharacter", _source, playerCoords, playerHeading, false)
end)
