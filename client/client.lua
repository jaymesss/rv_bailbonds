local QBCore = exports[Config.CoreName]:GetCoreObject()
local PlayerJob = {}

Citizen.CreateThread(function()
    -- ARMORY
    if Config.Blip.enabled then
        local blip = AddBlipForCoord(Config.Blip.coords)
        SetBlipSprite(blip, Config.Blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, Config.Blip.scale)
        SetBlipColour(blip, Config.Blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(v.name)
        EndTextCommandSetBlipName(blip)
    end
    if Config.Armory.enabled then
        RequestModel(GetHashKey(Config.Armory.ped.model))
        while not HasModelLoaded(GetHashKey(Config.Armory.ped.model)) do
            Wait(1)
        end
        local ped = CreatePed(1, GetHashKey(Config.Armory.ped.model), Config.Armory.ped.coords, false, false)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        if Config.Target == "qb" then
            exports['qb-target']:AddBoxZone('bondsman-armory', Config.Armory.target.coords, 2.5, 2.6, {
                name = "bondsman-armory",
                heading = Config.Armory.target.heading,
                debugPoly = false
            }, {
                options = {
                    {
                        type = "client",
                        event = "rv_bailbonds:client:OpenArmory",
                        icon = "fas fa-gun",
                        label = Config.Armory.target.label
                    }
                }
            })
        end
    end
    local Player = QBCore.Functions.GetPlayerData()
    if Player ~= nil then
        PlayerJob = Player.job
    end
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    local Player = QBCore.Functions.GetPlayerData()
    PlayerJob = Player.job
end)

RegisterNetEvent("QBCore:Client:SetDuty", function(newDuty)
    PlayerJob.onduty = newDuty
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

function IsBondsman()
    return PlayerJob.name == Config.JobName
end

RegisterNetEvent('rv_bailbonds:client:OpenArmory', function()
    if not IsBondsman() then
        QBCore.Functions.Notify(Locale.not_bondsman, 'error', 5000)
        return
    end
    local authorizedItems = {
        label = Config.Armory.label,
        slots = Config.Armory.slots,
        items = {}
    }
    index = 1
    for _, armoryItem in pairs(Config.Armory.items) do
        for i=1, #armoryItem.authorizedGrades do
            if armoryItem.authorizedGrades[i] == PlayerJob.grade.level then
                authorizedItems.items[index] = armoryItem
                authorizedItems.items[index].slot = index
                index = index + 1
            end
        end
    end
    TriggerServerEvent('inventory:server:OpenInventory', 'shop', Config.JobName, Config.Armory.items)
end)
