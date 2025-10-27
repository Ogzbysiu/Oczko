local isEyeActive = false
local currentTarget = nil
local carryTarget = nil
local isCarrying = false

-- Sprawdzenie, czy gracz jest zakuty
local function IsPlayerCuffed(player)
    return GetPedConfigFlag(GetPlayerPed(player), 32) -- CPED_CONFIG_FLAG_IsHandcuffed
end

-- Sprawdzenie, czy gracz jest w carry
local function IsPlayerCarried(player)
    return IsEntityPlayingAnim(GetPlayerPed(player), "missminuteman_1ig_2", "handsup_base", 3)
        or IsEntityPlayingAnim(GetPlayerPed(player), "mp_arresting", "idle", 3)
end

-- Raycast do wykrycia gracza
local function GetTargetPlayer()
    local playerPed = PlayerPedId()
    local camCoord = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local direction = RotationToDirection(camRot)
    local ray = StartShapeTestRay(camCoord, camCoord + direction * 5.0, 12, playerPed, 0)
    local _, hit, _, _, entity = GetShapeTestResult(ray)

    if hit == 1 and IsEntityAPed(entity) and IsPedAPlayer(entity) and entity ~= playerPed then
        return NetworkGetPlayerIndexFromPed(entity), entity
    end
    return nil, nil
end

function RotationToDirection(rotation)
    local z = math.rad(rotation.z)
    local x = math.rad(rotation.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

-- Opcje menu
local function GetOptions(targetPlayer, targetPed)
    local options = {}

    if IsPlayerCuffed(targetPlayer) then
        table.insert(options, {
            label = "Przeszukaj",
            icon = "fas fa-search",
            action = "search"
        })
    end

    if not IsPlayerCarried(targetPlayer) then
        table.insert(options, {
            label = "Podnieś",
            icon = "fas fa-people-carry",
            action = "carry"
        })
    end

    return options
end

-- Główna pętla
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isEyeActive then
            local player, ped = GetTargetPlayer()
            if player and player ~= currentTarget then
                currentTarget = player
                local options = GetOptions(player, ped)
                SendNUIMessage({
                    type = "show",
                    options = options
                })
            elseif not player and currentTarget then
                currentTarget = nil
                SendNUIMessage({ type = "hide" })
            end
        else
            Citizen.Wait(300)
        end
    end
end)

-- Aktywacja oka
RegisterKeyMapping('toggleEye', 'Otwórz Oczko', 'keyboard', 'LMENU')
RegisterCommand('toggleEye', function()
    isEyeActive = not isEyeActive
    SetNuiFocus(isEyeActive, isEyeActive)
    SendNUIMessage({ type = "toggle", active = isEyeActive })
    if not isEyeActive then
        SendNUIMessage({ type = "hide" })
        currentTarget = nil
    end
end)

-- Kliknięcie opcji
RegisterNUICallback('select', function(data, cb)
    if currentTarget and data.action then
        if data.action == "search" then
            TriggerServerEvent('ogz-eye:searchPlayer', GetPlayerServerId(currentTarget))
        elseif data.action == "carry" then
            TriggerServerEvent('ogz-eye:requestCarry', GetPlayerServerId(currentTarget))
        end
    end
    cb('ok')
end)

-- Odbiór akceptacji podniesienia
RegisterNetEvent('ogz-eye:showCarryPrompt')
AddEventHandler('ogz-eye:showCarryPrompt', function(requesterId)
    local requesterName = GetPlayerName(GetPlayerFromServerId(requesterId))
    SendNUIMessage({
        type = "carryPrompt",
        requesterId = requesterId,
        requesterName = requesterName
    })
    SetNuiFocus(true, true)
end)

RegisterNUICallback('carryResponse', function(data, cb)
    SetNuiFocus(false, false)
    TriggerServerEvent('ogz-eye:carryResponse', data.requesterId, data.accept)
    SendNUIMessage({ type = "hidePrompt" })
    cb('ok')
end)

-- Podniesienie (animacja carry)
RegisterNetEvent('ogz-eye:startCarry')
AddEventHandler('ogz-eye:startCarry', function(targetServerId)
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetServerId))
    local playerPed = PlayerPedId()

    -- Animacja carry
    RequestAnimDict("missfinale_c2mcs_1")
    while not HasAnimDictLoaded("missfinale_c2mcs_1") do Citizen.Wait(10) end

    AttachEntityToEntity(playerPed, targetPed, 0, 0.0, 0.4, 0.0, 0.0, 0.0, 180.0, false, false, false, false, 2, true)
    TaskPlayAnim(playerPed, "missfinale_c2mcs_1", "fin_c2_mcs_1_camman", 8.0, -8.0, -1, 49, 0, false, false, false)

    isCarrying = true
    carryTarget = targetServerId

    Citizen.CreateThread(function()
        while isCarrying do
            Citizen.Wait(0)
            if IsControlJustPressed(0, 38) then -- E
                TriggerServerEvent('ogz-eye:dropPlayer', carryTarget)
                break
            end
        end
    end)
end)

RegisterNetEvent('ogz-eye:stopCarry')
AddEventHandler('ogz-eye:stopCarry', function()
    isCarrying = false
    carryTarget = nil
    ClearPedTasks(PlayerPedId())
    DetachEntity(PlayerPedId(), true, false)
end)

-- Upuszczenie
RegisterNetEvent('ogz-eye:dropPlayer')
AddEventHandler('ogz-eye:dropPlayer', function()
    TriggerEvent('ogz-eye:stopCarry')
end)