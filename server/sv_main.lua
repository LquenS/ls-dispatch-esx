local QBCore = exports['es_extended']:getSharedObject()
local LS_CORE = exports["ls-core"]:GetCoreObject()
local calls = {}

function _U(entry)
	return Locales[Config.Locale][entry] 
end

local function IsPoliceJob(job)
    for k, v in pairs(Config.PoliceJob) do
        if job == v then
            return true
        end
    end
    return false
end

RegisterNetEvent("dispatch:server:notify", function(data)
	local newId = #calls + 1
	calls[newId] = data
    calls[newId].callId = newId
    calls[newId].units = {}
    calls[newId].time = os.time() * 1000

	TriggerClientEvent('dispatch:clNotify', -1, data, newId)
    if not data.alert then 
        TriggerClientEvent("ls-dispatch:client:AddCallBlip", -1, data.origin, dispatchCodes[data.dispatchcodename], newId)
    else
        TriggerClientEvent("ls-dispatch:client:AddCallBlip", -1, data.origin, data.alert, newId)
    end
end)

RegisterNetEvent("dispatch:respondWithHotkey", function(callid)
    local tPlayer = QBCore.GetPlayerFromId(source)

    local result = LS_CORE.Config.DATABASE( LS_CORE.Config.DATABASE_NAME, 'fetchAll', 'SELECT firstname, lastname FROM users WHERE identifier = @identifier', {
        ['@identifier'] = tPlayer.identifier
    })
    local _player = "NAME NAME"
    if result[1] then
        _player = result[1].firstname .. " " .. result[1].lastname
    end
    
    local player = {
        identifier = tPlayer.identifier,
        fullname = _player,
        job = tPlayer.job,
        callsign = "UNKNOWN"
    }

    if calls[callid] then
        local units_count = #calls[callid].units
        if units_count > 0 then
            for _,v in pairs ( calls[callid].units ) do
                if v.identifier == player.identifier then
                    return
                end
            end
        end

        if IsPoliceJob(player.job.name) then
            calls[callid].units[units_count+1] = { identifier = player.identifier, fullname = player.fullname, job = 'Police', callsign = player.callsign }
        elseif player.job.name == 'ambulance' then
            calls[callid].units[units_count+1] = { identifier = player.identifier, fullname = player.fullname, job = 'EMS', callsign = player.callsign }
        end
		TriggerClientEvent("dispatch:c:respondWaypoint", tPlayer.source, calls[callid])
		TriggerClientEvent("ls-mdt:c:respondToCall", tPlayer.source)
    end
end)

RegisterNetEvent("dispatch:addUnit", function(callid, player, cb)
    if calls[callid] then
        local units_count = #calls[callid].units
        if units_count > 0 then
            for _,v in pairs ( calls[callid].units ) do
                if v.identifier == player.identifier then
                    cb(calls[callid])
                    return
                end
            end
        end

        if IsPoliceJob(player.job.name) then
            calls[callid].units[units_count+1] = { identifier = player.identifier, fullname = player.fullname, job = 'Police', callsign = player.callsign }
        elseif player.job.name == 'ambulance' then
            calls[callid].units[units_count+1] = { identifier = player.identifier, fullname = player.fullname, job = 'EMS', callsign = player.callsign }
        end
		TriggerClientEvent("dispatch:c:respondWaypoint", QBCore.GetPlayerFromIdentifier(player.identifier), calls[callid])
		
        cb(calls[callid])
    end
end)

RegisterNetEvent("dispatch:removeUnit", function(callid, player, cb)
    if calls[callid] then
        if #calls[callid].units > 0 then
            for k,v in pairs ( calls[callid].units ) do
                if v.identifier == player.identifier then
                    calls[callid].units[k] = nil
                end
            end
        end
        cb(calls[callid])
    end    
end)

QBCore.RegisterServerCallback('ls-dispatch:s:getName', function(source, cb)
    local tPlayer = QBCore.GetPlayerFromId(source)

    local result = LS_CORE.Config.DATABASE( LS_CORE.Config.DATABASE_NAME, 'fetchAll', 'SELECT firstname, lastname FROM users WHERE identifier = @identifier', {
        ['@identifier'] = tPlayer.identifier
    })
    local _player = "NAME NAME"
    if result[1] then
        _player = result[1].firstname .. " " .. result[1].lastname
    end
	cb(_player)
end)

function GetDispatchCalls() 
    return calls 
end
exports('GetDispatchCalls', GetDispatchCalls)
