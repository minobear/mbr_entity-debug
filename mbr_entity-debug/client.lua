local playerPed = nil
local plyCoords = nil
local targetCoords = nil
local lastEntity = nil
local vertical, parallel = 0, 0

local debugMode = false

RegisterCommand("edebug",function(source, args)
	debugMode = not debugMode
	if debugMode then
		startDebug()
	else
		stopDebug()
	end
end)

function stopDebug()
	FreezeEntityPosition(lastEntity, false)
	DrawSub("~r~Debug mode off", 5000)
end

function startDebug()
	updateTargetCoords()
	getClosestEntity()
	DisplayHelpText("Press ~INPUT_CELLPHONE_UP~ or ~INPUT_CELLPHONE_DOWN~ to control the pointer vertical possion")
	DrawSub("~g~Debug mode on", 5000)
end

function updateTargetCoords()
	Citizen.CreateThread(function()
		while debugMode do
			Citizen.Wait(5)
			playerPed = PlayerPedId()
			plyCoords = GetEntityCoords(playerPed)	
			local forward = GetEntityForwardVector(playerPed) * 1.0
			
			if IsControlPressed(1, 172) then  -- up
				vertical = vertical + vector3(0,0,0.05)
			elseif IsControlPressed(1, 173) then  -- down
				vertical = vertical - vector3(0,0,0.05)
			end
			
			targetCoords = plyCoords + forward + vertical + parallel
		end		
	end)
end

function getClosestEntity()
	Citizen.CreateThread(function()
		Wait(100)
		while debugMode do
			Citizen.Wait(5)
			local entityType = ""
			
			local object, objDist = GetClosestObject({}, targetCoords)
			local objCoords = GetEntityCoords(object)
			
			local vehicle, vehDist = GetClosestVehicle(targetCoords)
			local vehCoords = GetEntityCoords(vehicle)
			
			local ped, pedDist = GetClosestPed(targetCoords)
			local pedCoords = GetEntityCoords(ped)
			
			local entity, entityCoords = nil, nil
			local closestDist = math.min(objDist, vehDist, pedDist)
			
			if objDist == closestDist then
				entityType = "Object"
				entity, entityCoords = object, objCoords
			elseif vehDist == closestDist then
				entityType = "Vehicle"
				entity, entityCoords = vehicle, vehCoords
			elseif pedDist == closestDist then
				entityType = "Ped"
				entity, entityCoords = ped, pedCoords
			end
			
			-- Display "?" Pointer
			DrawMarker(32, targetCoords, 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.1, 0.1, 0.1, 255, 0, 0, 255, false, true, 2, false, false, false, false)	
			
			if entity ~= playerPed then	
				local entityModel = GetEntityModel(entity)
				local entityPos = string.sub(entityCoords, 9, -2)
				local entityHeading = string.format("%.3f", GetEntityHeading(playerPed))
				local attatchEntity = GetEntityAttachedTo(entity)
				DrawText3D(entityCoords, "~y~"..entityType..": "..entity.."\nModel: "..entityModel.."\nCoords: "..entityPos..", H: "..entityHeading, 0.8)
				DrawMarker(0, entityCoords + vector3(0,0,1.0), 0.0, 0.0, 0.0, 0, 0.0, 0.0, 0.2, 0.2, 0.2, 255, 255, 0, 255, true, false, 2, false, false, false, false)
			end
			
			-- Freeze the entity
			if debugMode then
				if lastEntity ~= entity then
					FreezeEntityPosition(lastEntity, false)
				elseif entity ~= playerPed then
					FreezeEntityPosition(entity, true)
				end
			end
			
			lastEntity = entity
		end
	end)
end

function DrawText3D(coords, text, size)
	local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
	local camCoords      = GetGameplayCamCoords()
	local dist           = GetDistanceBetweenCoords(camCoords, coords.x, coords.y, coords.z, true)
	local size           = size

	if size == nil then
		size = 1
	end

	local scale = (size / dist) * 2
	local fov   = (1 / GetGameplayCamFov()) * 100
	local scale = scale * fov

	if onScreen then
		SetTextScale(0.0 * scale, 0.55 * scale)
		SetTextFont(0)
		SetTextColour(255, 255, 255, 255)
		SetTextDropshadow(0, 0, 0, 0, 255)
		SetTextDropShadow()
		SetTextOutline()
		SetTextEntry('STRING')
		SetTextCentre(1)

		AddTextComponentString(text)
		DrawText(x, y)
	end
end

function DrawSub(msg, time)
	ClearPrints()
	SetTextEntry_2("STRING")
	AddTextComponentString(msg)
	DrawSubtitleTimed(time, 1)
end

function DisplayHelpText(str)
	SetTextComponentFormat("STRING")
	AddTextComponentString(str)
	DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end