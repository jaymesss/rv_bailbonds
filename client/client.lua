local QBCore = exports[Config.CoreName]:GetCoreObject()
local PlayerJob = {}
local waiting = false;

Citizen.CreateThread(function()
    while true do 
        if waiting then
            if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), Config.MeetingLocation) > Config.CantLeaveRadius then
                SetEntityCoords(PlayerPedId(), Config.MeetingLocation)
                QBCore.Functions.Notify(Locale.Success.on_the_way, 'success', 5000)
            end
        end
        Citizen.Wait(1000)
    end
end)

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
        AddTextComponentSubstringPlayerName(Config.Blip.name)
        EndTextCommandSetBlipName(blip)
    end
    if Config.Armory.enabled then
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
                    label = Config.Armory.target.label,
                    job = Config.JobName
                }
            }
        })
    end
    -- BAIL PAYMENTS
    RequestModel(GetHashKey(Config.BailPayments.ped.model))
    while not HasModelLoaded(GetHashKey(Config.BailPayments.ped.model)) do
        Wait(1)
    end
    local ped = CreatePed(1, GetHashKey(Config.BailPayments.ped.model), Config.BailPayments.ped.coords, false, false)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    exports['qb-target']:AddBoxZone('bondsman-payments', Config.BailPayments.target.coords, 2.5, 2.6, {
        name = "bondsman-payments",
        heading = Config.BailPayments.target.heading,
        debugPoly = false
    }, {
        options = {
            {
                type = "client",
                event = "rv_bailbonds:client:OpenBondPayments",
                icon = "fas fa-gun",
                label = Config.BailPayments.target.label
            }
        }
    })
    -- LAPTOP
    exports['qb-target']:AddBoxZone('bondsman-laptop', Config.Laptop.target.coords, 2.5, 2.6, {
        name = "bondsman-laptop",
        heading = Config.Laptop.target.heading,
        debugPoly = false
    }, {
        options = {
            {
                type = "client",
                event = "rv_bailbonds:client:OpenLaptop",
                icon = "fas fa-gun",
                label = Config.Laptop.target.label,
                job = Config.JobName
            }
        }
    })   
    -- JOB
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

RegisterCommand('bail', function(source, args, rawCommand)
    if not IsBondsman() then
        QBCore.Functions.Notify(Locale.Errors.not_bondsman, 'error', 5000)
        return
    end
    local src = args[1]
    local ped = GetPlayerPed(GetPlayerFromServerId(tonumber(src)))
    if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(ped)) > 10 then 
        QBCore.Functions.Notify(Locale.Errors.too_far_away, 'error', 5000)
        return
    end
    TriggerServerEvent('rv_bailbonds:server:BailPlayer', src)
end, false)

RegisterCommand('bond', function(source, args, rawCommand)
    if PlayerJob.name ~= Config.PoliceJobName then
        QBCore.Functions.Notify(Locale.Errors.not_police, 'error', 5000)
        return
    end
    local src = args[1]
    local ped = GetPlayerPed(GetPlayerFromServerId(tonumber(src)))
    if GetDistanceBetweenCoords(GetEntityCoords(PlayerPedId()), GetEntityCoords(ped)) > 10 then 
        QBCore.Functions.Notify(Locale.Errors.too_far_away, 'error', 5000)
        return
    end
    local amount = tonumber(args[2])
    TriggerServerEvent('rv_bailbonds:server:SetPlayerBail', src, amount)
end, false)

-- RegisterCommand('devbailbonds', function(source, args, rawCommand)
--     TriggerEvent('rv_bailbonds:client:OpenTablet')
-- end, false)

RegisterNetEvent('rv_bailbonds:client:OpenArmory', function()
    if not IsBondsman() then
        QBCore.Functions.Notify(Locale.Errors.not_bondsman, 'error', 5000)
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
    TriggerServerEvent('inventory:server:OpenInventory', 'shop', Config.JobName, authorizedItems)
end)

RegisterNetEvent('rv_bailbonds:client:OpenBondPayments', function()
    local p = promise.new()
    local owed
    QBCore.Functions.TriggerCallback('rv_bailbonds:server:GetOwedAmount', function(result)
        p:resolve(result)
    end)
    owed = Citizen.Await(p)
    if owed <= 0 then
        QBCore.Functions.Notify(Locale.Errors.dont_owe, 'error', 5000)
        return
    end
    lib.registerContext({
        id = 'bailbonds_pay',
        title = Locale.Info.payment_management,
        options = {
            {     
                title = string.gsub(Locale.Info.you_owe, "amount", owed)
            },
            {
                title = Locale.Info.make_payment,
                description = Locale.Info.make_payment_desc,
                icon = 'dollar',
                onSelect = function()   
                    TriggerEvent('rv_bailbonds:client:OpenDialog')
                end
            }
        }
    })
    lib.showContext('bailbonds_pay')
end)

RegisterNetEvent('rv_bailbonds:client:OpenDialog', function()
    local input = lib.inputDialog(Locale.Info.dialog_title, {{type = 'number', label = Locale.Info.dialog_amount, icon = 'hashtag'}})
    if input ~= nil  and input[1] ~= nil then
        local amount = input[1]
        TriggerServerEvent('rv_bailbonds:server:MakePayment', amount)
    end
end)

RegisterNetEvent('rv_bailbonds:client:OpenLaptop', function()
    QBCore.Functions.Progressbar("open_laptop", Locale.Info.opening_laptop, 1500, false, true, {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true
        }, {
        }, {}, {}, function() -- Done
            local p = promise.new()
            local bonds
            QBCore.Functions.TriggerCallback('rv_bailbonds:server:GetPayers', function(result)
                p:resolve(result)
            end)
            bonds = Citizen.Await(p)
            local options = {}
            for k,v in pairs(bonds) do
                print(json.encode(v))
                options[#options+1] = {
                    title = json.decode(v.charinfo).firstname .. ' ' .. json.decode(v.charinfo).lastname .. ' $' .. v.bailowed,
                    description = string.gsub(Locale.Info.owes, "amount", v.bailowed),
                    icon = 'dollar',
                    onSelect = function()
                        TriggerServerEvent('rv_bailbonds:server:BondInfo', v.citizenid, v.amount)
                    end
                }
            end
            lib.registerContext({
                id = 'bailbonds_laptop',
                title = Locale.Info.laptop_title,
                options = options
            })
            lib.showContext('bailbonds_laptop')
        end, function() -- Cancel
    end)
end)


RegisterNetEvent('rv_bailbonds:client:OpenTablet', function()
    TriggerEvent('animations:client:EmoteCommandStart', {"tablet2"})
    QBCore.Functions.Progressbar("open_tablet", Locale.Info.opening_tablet, 3000, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true
    }, {
    }, {}, {}, function() -- Done
        local p = promise.new()
        local bonds
        QBCore.Functions.TriggerCallback('rv_bailbonds:server:GetActiveBonds', function(result)
            p:resolve(result)
        end)
        bonds = Citizen.Await(p)
        local options = {}
        for k,v in pairs(bonds) do
            options[#options+1] = {
                title = v.name .. ' $' .. v.amount,
                description = string.gsub(Locale.Info.set_for, "amount", v.amount),
                icon = 'dollar',
                onSelect = function()
                    TriggerServerEvent('rv_bailbonds:server:BondInfo', v.citizenid, v.amount)
                end
            }
        end
        lib.registerContext({
            id = 'bailbonds_tablet',
            title = Locale.Info.tablet_title,
            options = options,
            onExit = function()
                TriggerEvent('animations:client:EmoteCommandStart', {"c"})
            end
        })
        lib.showContext('bailbonds_tablet')
        Wait(100)
        TriggerEvent('animations:client:EmoteCommandStart', {"tablet2"})
    end, function() -- Cancel
    end)
    
end)

RegisterNetEvent('rv_bailbonds:client:OpenInfo', function(citizenid, time, amount)
    lib.registerContext({
        id = 'bailbonds_info',
        title = Locale.Info.tablet_title,
        options = {
            {     
                title = string.gsub(Locale.Info.months_left, "amount", time)
            },
            {
                title = Locale.Info.accept_job,
                description = string.gsub(Locale.Info.accept_job_desc, "amount", amount),
                icon = 'dollar',
                onSelect = function()   
                    TriggerServerEvent('rv_bailbonds:server:AcceptJob', citizenid, amount)
                end
            },
            {
                title = Locale.Info.go_back,
                onSelect = function()
                    TriggerEvent('rv_bailbonds:client:OpenTablet')
                end
            }
        }
    })
    lib.showContext('bailbonds_info')
end)

RegisterNetEvent('rv_bailbonds:client:MeetingRoom', function()
    SetEntityCoords(PlayerPedId(), Config.MeetingLocation)
    waiting = true
end)

RegisterNetEvent('rv_bailbonds:client:Bailed', function()
    waiting = false
    SettEntityCoords(PlayerPedId(), Config.ExitJailLocation)
end)