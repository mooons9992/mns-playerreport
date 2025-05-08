local QBCore = exports['qb-core']:GetCoreObject()

-- Local configuration reference
local config = Config

-- Client-side variables
local isNuiOpen = false
local clientReports = {}
local cooldownTimer = 0
local isNuiFocused = false  -- Track if NUI is currently in focus

-- Debug helper function
local function DebugLog(message)
    if config.Debug then
        print("^5[MNS REPORT]^7 " .. tostring(message))
    end
end

-- Register NUI callback events
RegisterNUICallback('submitReport', function(data, cb)
    DebugLog("Submitting report: " .. tostring(data.message))
    TriggerServerEvent('report:submit', data.message)
    cb('ok')
end)

RegisterNUICallback('teleportToPlayer', function(data, cb)
    DebugLog("Teleporting to player with report ID: " .. tostring(data.reportId))
    TriggerServerEvent('report:teleportToPlayer', tonumber(data.reportId))
    cb('ok')
end)

RegisterNUICallback('closeReport', function(data, cb)
    DebugLog("Closing report ID: " .. tostring(data.reportId))
    TriggerServerEvent('report:closeReport', tonumber(data.reportId))
    cb('ok')
end)

RegisterNUICallback('getAllReports', function(data, cb)
    DebugLog("Getting all reports")
    TriggerServerEvent('report:getAllReports')
    cb('ok')
end)

RegisterNUICallback('getPlayerInfo', function(data, cb)
    DebugLog("Getting player info for report ID: " .. tostring(data.reportId))
    TriggerServerEvent('report:getPlayerInfo', tonumber(data.reportId))
    cb('ok')
end)

RegisterNUICallback('escapePressed', function(data, cb)
    DebugLog("NUI escape pressed")
    isNuiFocused = false
    SetNuiFocus(false, false)
    isNuiOpen = false
    cb('ok')
end)

-- Emergency escape handler
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isNuiFocused and (IsControlJustPressed(0, 200) or IsControlJustPressed(0, 194)) then -- ESC key (200) or BACKSPACE (194)
            DebugLog("Emergency escape triggered")
            isNuiFocused = false
            SetNuiFocus(false, false)
            isNuiOpen = false
            SendNUIMessage({
                action = 'closeAll'
            })
        end
    end
end)

-- Register commands
RegisterCommand(config.Commands.player, function()
    DebugLog("Player command triggered: " .. config.Commands.player)
    ShowReportMenu()
end, false)

RegisterCommand(config.Commands.admin, function()
    DebugLog("Admin command triggered: " .. config.Commands.admin)
    TriggerServerEvent('report:checkAdminPermission')
end, false)

RegisterCommand(config.Commands.reportMenu, function()
    DebugLog("Report menu command triggered: " .. config.Commands.reportMenu)
    ShowReportMenu()
end, false)

-- Debug command to check if client-side is working
RegisterCommand("report_debug", function()
    DebugLog("Debug command triggered")
    TriggerEvent('chat:addMessage', {
        color = {100, 255, 100},
        multiline = true,
        args = {"MNS REPORT", "Client-side is responding."}
    })
end, false)

-- Add chat suggestions
Citizen.CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/' .. config.Commands.player, 'Submit a report to admins')
    TriggerEvent('chat:addSuggestion', '/' .. config.Commands.admin, 'View all active reports')
    TriggerEvent('chat:addSuggestion', '/' .. config.Commands.reportMenu, 'Open the report menu')
    TriggerEvent('chat:addSuggestion', '/report_debug', 'Check if the report system is responsive')
    DebugLog("Chat suggestions registered")
end)

-- Show the report creation menu
function ShowReportMenu()
    DebugLog("Showing report menu, webUI: " .. tostring(config.UI.webUI))
    
    -- Use the web UI
    if config.UI.webUI then
        SendNUIMessage({
            action = 'openReportMenu'
        })
        SetNuiFocus(true, true)
        isNuiFocused = true
        isNuiOpen = true
        return
    end
    
    -- Fallback for non-webUI
    QBCore.Functions.Notify("Please use the /report command with your message", "info", 5000)
end

-- Show admin reports panel
function ShowActiveReports()
    DebugLog("Showing active reports, webUI: " .. tostring(config.UI.webUI))
    
    if config.UI.webUI then
        -- Convert reports table to a format that NUI can use
        local reportsToSend = {}
        for id, report in pairs(clientReports) do
            if report.status ~= "resolved" then
                reportsToSend[id] = report
            end
        end
        
        DebugLog("Sending " .. table.count(reportsToSend) .. " reports to NUI")
        
        SendNUIMessage({
            action = 'openAdminMenu',
            reports = reportsToSend
        })
        SetNuiFocus(true, true)
        isNuiFocused = true
        isNuiOpen = true
        return
    end
    
    -- Fallback for non-webUI
    QBCore.Functions.Notify("Web UI is required for admin reports panel", "error", 5000)
end

-- Helper function to count table elements (for reports)
table.count = function(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Register event handlers
RegisterNetEvent('report:showReports')
AddEventHandler('report:showReports', function()
    DebugLog("Received showReports event")
    ShowActiveReports()
end)

-- Open report menu event handler
RegisterNetEvent('report:openReportMenu')
AddEventHandler('report:openReportMenu', function()
    DebugLog("Received openReportMenu event")
    ShowReportMenu()
end)

-- Teleport to player coordinates
RegisterNetEvent('report:teleport')
AddEventHandler('report:teleport', function(coords)
    DebugLog("Teleporting to coordinates: " .. tostring(coords.x) .. ", " .. tostring(coords.y) .. ", " .. tostring(coords.z))
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z)
end)

-- Handle notifications
RegisterNetEvent('report:notification')
AddEventHandler('report:notification', function(message, color)
    DebugLog("Notification: " .. message)
    
    if config.UI.notifications.useQBCore then
        QBCore.Functions.Notify(message, "info", config.UI.notifications.duration)
    else
        -- Legacy notification
        BeginTextCommandThefeedPost("STRING")
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, true)
    end
end)

-- Update report status
RegisterNetEvent('report:updateStatus')
AddEventHandler('report:updateStatus', function(reportId, status)
    DebugLog("Updating report " .. tostring(reportId) .. " status to: " .. status)
    if clientReports[reportId] then
        clientReports[reportId].status = status
    end
end)

-- Admin notification for new reports
RegisterNetEvent('report:adminNotify')
AddEventHandler('report:adminNotify', function(reportId, playerName, message)
    DebugLog("Admin notification for report #" .. tostring(reportId) .. " from " .. playerName)
    
    -- Add to client-side report tracking
    clientReports[reportId] = {
        id = reportId,
        playerName = playerName,
        message = message,
        status = "pending"
    }
    
    -- Play notification sound if enabled
    if config.UI.notifications.enableSound then
        PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", 1)
    end
    
    -- Use NUI notification if web UI is enabled
    if config.UI.webUI then
        SendNUIMessage({
            action = 'showNotification',
            reportId = reportId,
            playerName = playerName,
            message = message
        })
    else
        -- Show legacy notification
        QBCore.Functions.Notify("New report from " .. playerName, "info", 5000)
    end
end)

-- Display player information
RegisterNetEvent('report:showPlayerInfo')
AddEventHandler('report:showPlayerInfo', function(playerInfo)
    if not playerInfo then return end
    
    DebugLog("Received player info for: " .. playerInfo.name)
    
    if config.UI.webUI then
        SendNUIMessage({
            action = 'showPlayerInfo',
            playerInfo = playerInfo
        })
    else
        -- Legacy notification with basic player info
        QBCore.Functions.Notify("Player ID: " .. playerInfo.source .. " | Name: " .. playerInfo.name, "info", 5000)
    end
end)

-- Update cooldown timer to sync with NUI
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if cooldownTimer > 0 then
            cooldownTimer = cooldownTimer - 1
            
            if config.UI.webUI then
                SendNUIMessage({
                    action = 'updateCooldown',
                    time = cooldownTimer
                })
            end
        end
    end
end)

-- Update reports in the NUI
RegisterNetEvent('report:updateReportsList')
AddEventHandler('report:updateReportsList', function(reports)
    DebugLog("Received updated reports list with " .. table.count(reports) .. " reports")
    
    -- Update local reports cache
    clientReports = reports
    
    if config.UI.webUI then
        SendNUIMessage({
            action = 'updateReports',
            reports = reports
        })
    end
end)

-- Resource cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        if isNuiFocused then
            SetNuiFocus(false, false)
        end
    end
end)

-- Initialize client-side
Citizen.CreateThread(function()
    DebugLog("Client-side initialized")
    
    -- Request initial reports if player has permissions (will be checked server-side)
    Citizen.Wait(2000) -- Wait a bit for everything to load
    TriggerServerEvent('report:getAllReports')
end)

-- Print initialization message to confirm script is loaded
print("^2[MNS REPORT SYSTEM]^7 Client-side loaded successfully!")