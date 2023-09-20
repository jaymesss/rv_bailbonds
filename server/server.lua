local QBCore = exports[Config.CoreName]:GetCoreObject()
QBCore.Functions.CreateUseableItem(Config.TabletItem, function(source, item)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player.Functions.GetItemByName(Config.TabletItem) then return end
    if Player.PlayerData.job.name ~= Config.JobName then
        TriggerClientEvent('QBCore:Notify', src, Locale.Errors.not_bondsman, 'error')
        return
    end
    TriggerClientEvent('rv_bailbonds:client:OpenTablet', src)
end)

QBCore.Functions.CreateCallback('rv_bailbonds:server:GetActiveBonds', function(source, cb)
    local src = source
    local response = MySQL.query.await('SELECT * FROM bailbonds')
    cb(response)
end)

QBCore.Functions.CreateCallback('rv_bailbonds:server:GetPayers', function(source, cb)
    local src = source
    local response = MySQL.query.await('SELECT * FROM players WHERE bailowed > 0')
    cb(response)
end)

QBCore.Functions.CreateCallback('rv_bailbonds:server:GetOwedAmount', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local response = MySQL.query.await('SELECT * FROM players WHERE citizenid = @citizenid', {
        ["@citizenid"] = Player.PlayerData.citizenid
    })
    cb(response[1].bailowed)
end)

RegisterNetEvent('rv_bailbonds:server:BailPlayer', function(other)
    local src = source
    local srcOther = tonumber(other)
    local Player = QBCore.Functions.GetPlayer(src)
    local OtherPlayer = QBCore.Functions.GetPlayer(srcOther)
    local response = MySQL.query.await('SELECT * FROM bailbonds WHERE citizenid = ?', { OtherPlayer.PlayerData.citizenid })
    local amount = tonumber(response[1].amount)
    if Player.Functions.GetMoney('bank') < amount then
        TriggerClientEvent('QBCore:Notify', src, Locale.Error.not_enough_money, 'error')
        return
    end
    Player.Functions.RemoveMoney('bank', amount)
    OtherPlayer.Functions.SetMetaData("injail", 0)
    Wait(300)
    TriggerClientEvent('rv_bailbonds:client:Bailed', srcOther)
    TriggerClientEvent('prison:client:SetTime', srcOther, 0)
    TriggerClientEvent(Config.LeaveJailEvent, srcOther)
    TriggerClientEvent('QBCore:Notify', srcOther, Locale.Success.bailed_out, 'success')
    TriggerClientEvent('QBCore:Notify', src, string.gsub(Locale.Success.bailed_out_bondsman, "fullname", OtherPlayer.PlayerData.charinfo.firstname .. ' ' .. OtherPlayer.PlayerData.charinfo.lastname), 'success')
    MySQL.Async.execute('DELETE FROM bailbonds WHERE citizenid=?', { OtherPlayer.PlayerData.citizenid })  
    local response = MySQL.query.await('SELECT * FROM players WHERE citizenid = @citizenid', {
        ["@citizenid"] = OtherPlayer.PlayerData.citizenid
    })
    local current = response[1].bailowed
    MySQL.Async.execute('UPDATE players SET bailowed = ? WHERE citizenid = ?', {
        current + amount, OtherPlayer.PlayerData.citizenid
    })
end)

RegisterNetEvent('rv_bailbonds:server:AcceptJob', function(citizenid, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.Functions.GetMoney('bank') < amount then
        TriggerClientEvent('QBCore:Notify', src, Locale.Error.not_enough_money, 'error')
        return
    end
    local OtherPlayer = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    local other = OtherPlayer.PlayerData.source
    TriggerClientEvent('QBCore:Notify', src, Locale.Success.accepted, 'success')
    TriggerClientEvent('QBCore:Notify', other, Locale.Success.on_the_way, 'success')
    TriggerClientEvent('rv_bailbonds:client:MeetingRoom', other)
end)

RegisterNetEvent('rv_bailbonds:server:BondInfo', function(citizenid, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayerByCitizenId(citizenid)
    if Player == nil then
        TriggerClientEvent('QBCore:Notify', src, Locale.Errors.not_in_city, 'error')
        return
    end
    local OtherPlayer = QBCore.Functions.GetPlayer(Player.PlayerData.source)
    if OtherPlayer.PlayerData.metadata['injail'] <= 0 then
        TriggerClientEvent('QBCore:Notify', src, Locale.Errors.no_longer_needs, 'error')
        MySQL.Async.execute('DELETE FROM bailbonds WHERE citizenid=?', { OtherPlayer.PlayerData.citizenid })  
        TriggerClientEvent('rv_bailbonds:client:OpenTablet', src)
        return
    end
    TriggerClientEvent('rv_bailbonds:client:OpenInfo', src, citizenid, OtherPlayer.PlayerData.metadata['injail'], amount)
end)

RegisterNetEvent('rv_bailbonds:server:SetPlayerBail', function(id, amount)
    local src = source
    local srcOther = tonumber(id)
    local Player = QBCore.Functions.GetPlayer(srcOther)
    str = Locale.Success.set_bail_for
    str = string.gsub(str, "fullname", Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname)
    str = string.gsub(str, "amount", amount)
    TriggerClientEvent('QBCore:Notify', src, str, 'success')
    TriggerClientEvent('QBCore:Notify', srcOther, string.gsub(Locale.Info.your_bail_is, "amount", amount), 'success')
    MySQL.insert.await('INSERT INTO `bailbonds` (citizenid, name, amount) VALUES (?, ?, ?)', {
        Player.PlayerData.citizenid, Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname, amount
    })
    for k,v in pairs(QBCore.Functions.GetQBPlayers()) do
        if v.Functions.GetItemByName(Config.TabletItem) then 
            TriggerClientEvent('QBCore:Notify', v.PlayerData.source, string.gsub(Locale.Info.new_bail, "fullname", Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname), 'success')
        end
    end
end)

RegisterNetEvent('rv_bailbonds:server:MakePayment', function(amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.Functions.GetMoney('bank') < amount then
        TriggerClientEvent('QBCore:Notify', src, Locale.Error.not_enough_money, 'error')
        return
    end
    local response = MySQL.query.await('SELECT * FROM players WHERE citizenid = @citizenid', {
        ["@citizenid"] = Player.PlayerData.citizenid
    })
    local current = response[1].bailowed
    if current - amount < 0 then
        TriggerClientEvent('QBCore:Notify', src, Locale.Error.too_much, 'error')
        return
    end
    Player.Functions.RemoveMoney('bank', amount)
    if current - amount == 0 then
        TriggerClientEvent('QBCore:Notify', src, Locale.Success.debt_paid, 'success')
        MySQL.Async.execute('UPDATE players SET bailowed = ? WHERE citizenid = ?', {
            0, Player.PlayerData.citizenid
        })
        return
    end
    TriggerClientEvent('QBCore:Notify', src, string.gsub(Locale.Success.debt_amount, 'amount', amount), 'success')
    MySQL.Async.execute('UPDATE players SET bailowed = ? WHERE citizenid = ?', {
        current - amount, Player.PlayerData.citizenid
    })
end)