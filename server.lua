RegisterNetEvent('ogz-eye:searchPlayer')
AddEventHandler('ogz-eye:searchPlayer', function(targetId)
    local src = source
    TriggerClientEvent('ogz-eye:searchResult', src, "Przeszukałeś gracza!")
    TriggerClientEvent('ogz-eye:searchResult', targetId, "Zostałeś przeszukany!")
end)

RegisterNetEvent('ogz-eye:requestCarry')
AddEventHandler('ogz-eye:requestCarry', function(targetId)
    local src = source
    TriggerClientEvent('ogz-eye:showCarryPrompt', targetId, src)
end)

RegisterNetEvent('ogz-eye:carryResponse')
AddEventHandler('ogz-eye:carryResponse', function(requesterId, accept)
    local src = source
    if accept then
        TriggerClientEvent('ogz-eye:startCarry', requesterId, src)
        TriggerClientEvent('ogz-eye:startCarry', src, requesterId)
    else
        TriggerClientEvent('chat:addMessage', requesterId, { args = { "Odmowa", "Gracz odmówił podniesienia." } })
    end
end)

RegisterNetEvent('ogz-eye:dropPlayer')
AddEventHandler('ogz-eye:dropPlayer', function(targetId)
    TriggerClientEvent('ogz-eye:dropPlayer', targetId)
    TriggerClientEvent('ogz-eye:dropPlayer', source)
end)