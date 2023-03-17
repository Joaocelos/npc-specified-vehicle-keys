local npc = nil
local closestVehicle = nil

function SpawnNPC()
  local pedModel = "s_m_y_construct_01" -- Change this to the ped model you want for the NPC
  RequestModel(pedModel)
  while not HasModelLoaded(pedModel) do
    Wait(1)
  end
  npc = CreatePed(4, pedModel, Config.NPCSpawnLocation, 0.0, false, true)
  SetPedCanBeTargetted(npc, false)
  SetPedCanBeKnockedOffVehicle(npc, false)
  SetEntityAsMissionEntity(npc, true, true)
  SetBlockingOfNonTemporaryEvents(npc, true)
end

function GetClosestVehicle()
  local playerPed = PlayerPedId()
  local playerPos = GetEntityCoords(playerPed)
  local vehicles = {}
  local handle, currentVehicle = FindFirstVehicle()
  repeat
    local vehiclePos = GetEntityCoords(currentVehicle)
    local distance = GetDistanceBetweenCoords(playerPos, vehiclePos, true)
    if distance <= 5.0 and GetEntityModel(currentVehicle) == GetHashKey(Config.VehicleHash) then
      table.insert(vehicles, {handle = handle, distance = distance})
    end
    success, currentVehicle = FindNextVehicle(handle)
  until not success
  EndFindVehicle(handle)
  if #vehicles > 0 then
    table.sort(vehicles, function(a, b)
      return a.distance < b.distance
    end)
    return vehicles[1].handle
  else
    return nil
  end
end

Citizen.CreateThread(function()
  SpawnNPC()
  while true do
    Citizen.Wait(0)
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)
    local npcPos = GetEntityCoords(npc)
    local distance = GetDistanceBetweenCoords(playerPos, npcPos, true)
    if distance <= 2.0 then
      ShowHelpNotification("Press ~INPUT_CONTEXT~ to talk to the NPC")
      if IsControlJustPressed(0, 38) then -- Change this to the input control you want for the interaction
        closestVehicle = GetClosestVehicle()
        if closestVehicle ~= nil then
          local plate = GetVehicleNumberPlateText(closestVehicle)
          TriggerEvent("QBCore:Notify", "You received the keys for a " .. Config.VehicleHash .. " with plate number " .. plate)
          SetVehicleEngineOn(closestVehicle, true, false, true)
          SetVehicleUndriveable(closestVehicle, false)
          SetVehicleDoorsLocked(closestVehicle, 0)
          TaskTurnPedToFaceEntity(npc, playerPed, 1000)
          TaskPlayAnim(npc, "random@hitch_lift", "idle_f", 1.0, -1, -1, 0, 0, false, false, false)
          Citizen.Wait(2000)
          TaskPlayAnim(npc, "random@hitch_lift", "exit", 1.0, -1, -1, 0,
