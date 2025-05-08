local QBCore = exports['qb-core']:GetCoreObject()

-- Direct inclusion of Utils from the file
local Utils = {}
local utilsFile = LoadResourceFile(GetCurrentResourceName(), "utils/utils.lua")
if utilsFile then
    Utils = load(utilsFile)() or {}
    print("^2[MNS REPORT SYSTEM]^7 Utils module loaded successfully")
else
    print("^1[MNS REPORT SYSTEM]^7 Failed to load Utils module")
end

-- Local configuration reference
local config = Config

-- Server-side reporting system
local reports = {}
local playerCooldowns = {}

-- Clean old reports periodically
Citizen.CreateThread(function()
    while config.Reports.autoClean do
        Citizen.Wait(300000) -- Check every 5 minutes
        
        local currentTime = os.time()
        local cleanedCount = 0
        
        for id, report in pairs(reports) do
            if report.status == "resolved" and report.closedTime and 
               (currentTime - report.closedTime) > config.Reports.retentionTime then
                reports[id] = nil
                cleanedCount = cleanedCount + 1
            end
        end
        
        if cleanedCount > 0 and config.Debug then
            Utils.DebugLog("Auto-cleaned " .. cleanedCount .. " old resolved reports", "info")
        end
    end
end)

-- Report submission handler
RegisterNetEvent('report:submit')
AddEventHandler('report:submit', function(message)
    local source = source
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return end
    
    local playerName = GetPlayerName(source)
    local currentTime = os.time()
    
    -- Debug message to ensure event is received
    if config.Debug then
        Utils.DebugLog("Received report from " .. playerName .. ": " .. message, "info")
    end
    
    -- Check cooldown
    if playerCooldowns[source] and (currentTime - playerCooldowns[source]) < config.ReportCooldown then
        local remainingTime = config.ReportCooldown - (currentTime - playerCooldowns[source])
        Utils.NotifyPlayer(source, "You must wait " .. Utils.FormatTime(remainingTime) .. " before submitting another report.", "warning")
        return
    end
    
    -- Sanitize input message
    message = Utils.SanitizeText(message)
    
    -- Trim message to max length
    if #message > config.Reports.maxMessageLength then
        message = string.sub(message, 1, config.Reports.maxMessageLength) .. "..."
    end
    
    -- Create report
    local reportId = #reports + 1
    reports[reportId] = {
        id = reportId,
        player = source,
        playerName = playerName,
        message = message,
        timestamp = currentTime,
        status = "pending",
        citizenid = Player.PlayerData.citizenid,
        charinfo = Player.PlayerData.charinfo
    }
    
    -- Set cooldown
    playerCooldowns[source] = currentTime
    
    -- Notify player
    Utils.NotifyPlayer(source, "Your report has been submitted. An admin will assist you soon.", "success")
    
    -- Notify admins
    for _, playerId in ipairs(GetPlayers()) do
        if Utils.HasPermission(playerId, "admin.reports") then
            TriggerClientEvent('report:adminNotify', playerId, reportId, playerName, message)
        end
    end
    
    -- Send Discord webhook notification
    Utils.SendDiscordWebhook({
        title = "📢 New Player Report #" .. reportId,
        description = "A new player report has been submitted.",
        color = config.Discord.colors.newReport,
        fields = {
            {
                name = "Player",
                value = playerName,
                inline = true
            },
            {
                name = "Player ID",
                value = source,
                inline = true
            },
            {
                name = "Character Name",
                value = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
                inline = true
            },
            {
                name = "Report Message",
                value = message,
                inline = false
            },
            {
                name = "Status",
                value = config.StatusOptions.pending.label,
                inline = true
            },
            {
                name = "Time",
                value = Utils.FormatDate(currentTime),
                inline = true
            }
        }
    })
    
    -- Send to NUI if enabled
    if config.UI.webUI then
        TriggerClientEvent('report:updateReportsList', -1, reports)
    end
end)

-- Admin permission check handler
RegisterNetEvent('report:checkAdminPermission')
AddEventHandler('report:checkAdminPermission', function()
    local source = source
    
    -- Debug message
    if config.Debug then
        Utils.DebugLog("Permission check for player " .. GetPlayerName(source), "info")
    end
    
    -- Use the server-side permission check
    if Utils.HasPermission(source, "admin.reports") then
        -- Player has permission, tell client to show reports
        if config.Debug then
            Utils.DebugLog("Permission granted for " .. GetPlayerName(source), "success")
        end
        
        TriggerClientEvent('report:showReports', source)
        
        -- Also send current reports
        if config.UI.webUI then
            TriggerClientEvent('report:updateReportsList', source, reports)
        end
    else
        -- Player doesn't have permission
        if config.Debug then
            Utils.DebugLog("Permission denied for " .. GetPlayerName(source), "error")
        end
        
        Utils.NotifyPlayer(source, "You don't have permission to view reports.", "error")
    end
end)

-- Admin teleport to player handler
RegisterNetEvent('report:teleportToPlayer')
AddEventHandler('report:teleportToPlayer', function(reportId)
    local source = source
    
    -- Check if admin
    if not Utils.HasPermission(source, "admin.reports") then
        Utils.NotifyPlayer(source, "You don't have permission to teleport to reports.", "error")
        return
    end
    
    -- Get report
    local report = reports[reportId]
    if not report then
        Utils.NotifyPlayer(source, "Report not found.", "error")
        return
    end
    
    -- Check if player is online
    local targetPlayer = report.player
    if not GetPlayerName(targetPlayer) then
        Utils.NotifyPlayer(source, "Player has disconnected.", "warning")
        return
    end
    
    -- Get target coordinates
    local targetCoords = Utils.GetPlayerCoords(targetPlayer)
    
    -- Teleport admin to player
    TriggerClientEvent('report:teleport', source, targetCoords)
    
    -- Update report status
    report.status = "inProgress"
    report.assignedAdmin = source
    report.assignedAdminName = GetPlayerName(source)
    
    -- Notify both parties
    Utils.NotifyPlayer(source, "Teleported to " .. report.playerName .. "'s report.", "info")
    Utils.NotifyPlayer(targetPlayer, "An admin is now attending to your report.", "success")
    
    -- Update admin report list
    TriggerClientEvent('report:updateStatus', -1, reportId, "inProgress")
    
    -- Send Discord webhook notification
    Utils.SendDiscordWebhook({
        title = "👀 Report Status Update #" .. reportId,
        description = "An admin is now responding to a report.",
        color = config.Discord.colors.inProgress,
        fields = {
            {
                name = "Player",
                value = report.playerName,
                inline = true
            },
            {
                name = "Admin",
                value = GetPlayerName(source),
                inline = true
            },
            {
                name = "Report Message",
                value = report.message,
                inline = false
            },
            {
                name = "Status",
                value = config.StatusOptions.inProgress.label,
                inline = true
            },
            {
                name = "Action",
                value = "Admin teleported to player",
                inline = true
            }
        }
    })
    
    -- Update reports list for all admins if using Web UI
    if config.UI.webUI then
        TriggerClientEvent('report:updateReportsList', -1, reports)
    end
end)

-- Admin close report handler
RegisterNetEvent('report:closeReport')
AddEventHandler('report:closeReport', function(reportId)
    local source = source
    
    -- Check if admin
    if not Utils.HasPermission(source, "admin.reports") then
        Utils.NotifyPlayer(source, "You don't have permission to close reports.", "error")
        return
    end
    
    -- Get report
    local report = reports[reportId]
    if not report then
        Utils.NotifyPlayer(source, "Report not found.", "error")
        return
    end
    
    -- Close report
    report.status = "resolved"
    report.closedBy = source
    report.closedByName = GetPlayerName(source)
    report.closedTime = os.time()
    
    -- Notify admin
    Utils.NotifyPlayer(source, "Report #" .. reportId .. " closed.", "success")
    
    -- Notify player if still online
    if GetPlayerName(report.player) then
        Utils.NotifyPlayer(report.player, "Your report has been resolved.", "success")
    end
    
    -- Update admin report list
    TriggerClientEvent('report:updateStatus', -1, reportId, "resolved")
    
    -- Send Discord webhook notification
    Utils.SendDiscordWebhook({
        title = "✅ Report Closed #" .. reportId,
        description = "A player report has been resolved.",
        color = config.Discord.colors.closed,
        fields = {
            {
                name = "Player",
                value = report.playerName,
                inline = true
            },
            {
                name = "Admin",
                value = GetPlayerName(source),
                inline = true
            },
            {
                name = "Report Message",
                value = report.message,
                inline = false
            },
            {
                name = "Status",
                value = config.StatusOptions.resolved.label,
                inline = true
            },
            {
                name = "Time",
                value = Utils.FormatDate(os.time()),
                inline = true
            }
        }
    })
    
    -- Update reports list for all admins if using Web UI
    if config.UI.webUI then
        TriggerClientEvent('report:updateReportsList', -1, reports)
    end
end)

-- Get all reports handler
RegisterNetEvent('report:getAllReports')
AddEventHandler('report:getAllReports', function()
    local source = source
    
    -- Check if admin
    if Utils.HasPermission(source, "admin.reports") then
        TriggerClientEvent('report:updateReportsList', source, reports)
    end
end)

-- Get detailed player information for an admin
RegisterNetEvent('report:getPlayerInfo')
AddEventHandler('report:getPlayerInfo', function(reportId)
    local source = source
    
    -- Check if admin
    if not Utils.HasPermission(source, "admin.reports") then
        Utils.NotifyPlayer(source, "You don't have permission to view player info.", "error")
        return
    end
    
    -- Get report
    local report = reports[reportId]
    if not report then
        Utils.NotifyPlayer(source, "Report not found.", "error")
        return
    end
    
    -- Check if player is still online
    local targetPlayer = report.player
    if not GetPlayerName(targetPlayer) then
        Utils.NotifyPlayer(source, "Player has disconnected.", "warning")
        return
    end
    
    -- Get player information
    local playerInfo = Utils.GetPlayerInfo(targetPlayer)
    
    -- Send info back to admin
    TriggerClientEvent('report:showPlayerInfo', source, playerInfo)
end)

-- Admin commands
QBCore.Commands.Add(config.Commands.admin, "View admin reports panel", {}, false, function(source)
    if Utils.HasPermission(source, "admin.reports") then
        TriggerClientEvent('report:showReports', source)
    else
        Utils.NotifyPlayer(source, "You don't have permission to view reports.", "error")
    end
end)

QBCore.Commands.Add(config.Commands.player, "Submit a report to admins", {{name = "message", help = "Your report message"}}, true, function(source, args)
    TriggerEvent('report:submit', table.concat(args, " "))
end)

QBCore.Commands.Add(config.Commands.reportMenu, "Open the report menu", {}, false, function(source)
    TriggerClientEvent('report:openReportMenu', source)
end)

QBCore.Commands.Add("testreport", "Test the report system (Admin Only)", {}, true, function(source)
    if Utils.HasPermission(source, "admin.reports") then
        -- Create a test report
        local reportId = #reports + 1
        reports[reportId] = {
            id = reportId,
            player = source,
            playerName = GetPlayerName(source),
            message = "This is a test report created by an admin.",
            timestamp = os.time(),
            status = "pending"
        }
        
        -- Notify admin
        Utils.NotifyPlayer(source, "Test report created with ID #" .. reportId, "success")
        
        -- Update reports list for all admins
        if config.UI.webUI then
            TriggerClientEvent('report:updateReportsList', -1, reports)
        end
    else
        Utils.NotifyPlayer(source, "You don't have permission to create test reports.", "error")
    end
end, "admin")

-- Debug command
if config.Debug then
    RegisterCommand("report_debug", function(source, args, rawCommand)
        local player = source
        TriggerClientEvent('chat:addMessage', player, {
            color = {255, 100, 100},
            multiline = true,
            args = {"REPORT SYSTEM", "Server-side script is loaded and functioning."}
        })
        
        -- Print permissions info
        Utils.DebugLog("Permission check for " .. GetPlayerName(player) .. ": " .. 
            tostring(Utils.HasPermission(player, "admin.reports")), "info")
    end, false)
end

-- Test webhook command
RegisterCommand("test_webhook", function(source, args, rawCommand)
    local player = source
    
    -- Check if admin
    if not Utils.HasPermission(player, "admin.reports") then
        Utils.NotifyPlayer(player, "You don't have permission to test webhooks.", "error")
        return
    end
    
    -- Test Discord webhook
    Utils.SendDiscordWebhook({
        title = "🔧 Webhook Test",
        description = "This is a test of the Discord webhook integration.",
        color = config.Discord.colors.test,
        fields = {
            {
                name = "Requested By",
                value = GetPlayerName(player),
                inline = true
            },
            {
                name = "Server",
                value = GetConvar("sv_hostname", "Unknown"),
                inline = true
            },
            {
                name = "Time",
                value = Utils.FormatDate(os.time()),
                inline = false
            }
        }
    })
    
    -- Notify player
    Utils.NotifyPlayer(player, "Discord webhook test sent.", "success")
end, false)

-- Player disconnection handler
AddEventHandler('playerDropped', function(reason)
    local source = source
    
    -- Update any report this player may have submitted
    for id, report in pairs(reports) do
        if report.player == source and report.status == "pending" then
            report.playerDisconnected = true
            report.disconnectReason = reason
            report.disconnectTime = os.time()
            
            -- Notify admins of player disconnect
            for _, playerId in ipairs(GetPlayers()) do
                if Utils.HasPermission(playerId, "admin.reports") then
                    Utils.NotifyPlayer(playerId, "Player " .. report.playerName .. " with Report #" .. id .. " disconnected.", "warning")
                end
            end
            
            -- Update reports list for all admins
            if config.UI.webUI then
                TriggerClientEvent('report:updateReportsList', -1, reports)
            end
        end
    end
end)

-- Print initialization message
print("^2[MNS REPORT SYSTEM]^7 Server-side initialized successfully!")