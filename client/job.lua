local RSGCore = exports['rsg-core']:GetCoreObject()
local isHealingPerson = false

-- Functions
local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(5)
    end
end

-----------------------------------------------------------------------------------

-- toggle and set medic job
RegisterNetEvent('rsg-medic:clent:ToggleDuty', function()
    RSGCore.Functions.GetPlayerData(function(PlayerData)
        PlayerJob = PlayerData.job
        onDuty = PlayerData.job.onduty
        if PlayerJob.name == Config.JobRequired then
            onDuty = not onDuty
            TriggerServerEvent("RSGCore:ToggleDuty")
        else
            RSGCore.Functions.Notify(Lang:t('error.not_medic'), 'error')
        end
    end)
end)

RegisterNetEvent('RSGCore:Client:OnJobUpdate', function(JobInfo)
    print(JobInfo)
    PlayerJob = JobInfo
    TriggerServerEvent("rsg-medic:server:SetMedic")
end)

-----------------------------------------------------------------------------------

-- get closest player
local function GetClosestPlayer()
    local closestPlayers = RSGCore.Functions.GetPlayersFromCoords()
    local closestDistance = -1
    local closestPlayer = -1
    local coords = GetEntityCoords(PlayerPedId())
    for i=1, #closestPlayers, 1 do
        if closestPlayers[i] ~= PlayerId() then
            local pos = GetEntityCoords(GetPlayerPed(closestPlayers[i]))
            local distance = #(pos - coords)
            if closestDistance == -1 or closestDistance > distance then
                closestPlayer = closestPlayers[i]
                closestDistance = distance
            end
        end
    end
    return closestPlayer, closestDistance
end

-----------------------------------------------------------------------------------

-- medic revive player
RegisterNetEvent('rsg-medic:client:RevivePlayer', function()
    local hasItem = RSGCore.Functions.HasItem('firstaid', 1)
    if hasItem then
        local player, distance = GetClosestPlayer()
        if player ~= -1 and distance < 5.0 then
            local playerId = GetPlayerServerId(player)
            isHealingPerson = true
            local dict = loadAnimDict('script_re@gold_panner@gold_success')
            TaskPlayAnim(PlayerPedId(), dict, 'SEARCH01', 8.0, 8.0, -1, 1, false, false, false)
            FreezeEntityPosition(PlayerPedId(), true)
            RSGCore.Functions.Progressbar("reviving", "Reviving...", Config.MedicReviveTime, false, true, {
                disableMovement = true,
                disableCarMovement = true,
                disableMouse = false,
                disableCombat = true,
            }, {}, {}, {}, function()
                ClearPedTasks(PlayerPedId())
                TriggerServerEvent('rsg-medic:server:RevivePlayer', playerId)
                FreezeEntityPosition(PlayerPedId(), false)
                isHealingPerson = false
            end)
        else
            RSGCore.Functions.Notify(Lang:t('error.no_player'), 'error')
        end
    else
        RSGCore.Functions.Notify(Lang:t('error.no_firstaid'), 'error')
    end
end)

-----------------------------------------------------------------------------------

-- medic alert
RegisterNetEvent('rsg-medic:client:medicAlert', function(coords, text)
    RSGCore.Functions.Notify(text, Config.JobRequired)
    local transG = 250
    local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, coords.x, coords.y, coords.z)
    local blip2 = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, coords.x, coords.y, coords.z)
    local blipText = Lang:t('info.blip_text', {value = text})
    SetBlipSprite(blip, 1109348405, 1)
    SetBlipSprite(blip2, -184692826, 1)
    Citizen.InvokeNative(0x662D364ABF16DE2F, blip, GetHashKey('BLIP_MODIFIER_AREA_PULSE'))
    Citizen.InvokeNative(0x662D364ABF16DE2F, blip2, GetHashKey('BLIP_MODIFIER_AREA_PULSE'))
    SetBlipScale(blip, 0.8)
    SetBlipScale(blip2, 2.0)
    Citizen.InvokeNative(0x9CB1A1623062F402, blip, blipText)
    while transG ~= 0 do
        Wait(180 * 4)
        transG = transG - 1
        if transG == 0 then
            RemoveBlip(blip)
            return
        end
    end
end)

-----------------------------------------------------------------------------------
