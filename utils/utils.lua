local QBCore = exports['qb-core']:GetCoreObject()

-- String trimming extension
function string.trim(s)
    return s:match"^%s*(.*)":match"(.-)%s*$"
 end

local Utils = {}

-- Permission check function with QBCore support
function Utils.HasPermission(player, permission)
    -- Get QBCore player data
    local Player = QBCore.Functions.GetPlayer(player)
    
    -- First try QBCore permission system
    if Player and Config.QBCore.useBuiltInPermissions then
        local playerGroup = Player.PlayerData.group
        
        -- Check if player is in admin groups
        for _, group in pairs(Config.QBCore.adminGroups) do
            if playerGroup == group then
                return true
            end
        end
        
        -- Check if player is in mod groups
        for _, group in pairs(Config.QBCore.modGroups) do
            if playerGroup == group then
                return true
            end
        end
    end
    
    -- Fallback to ACE permissions if enabled
    if Config.UseAcePermissions then
        local hasAce = IsPlayerAceAllowed(player, Config.AdminAcePermission)
        
        if Config.Debug then
            print("[REPORT SYSTEM] Player " .. GetPlayerName(player) .. " ACE permission check: " .. tostring(hasAce))
        end
        
        return hasAce
    end
    
    return false
end

-- Get player coordinates
function Utils.GetPlayerCoords(player)
    return GetEntityCoords(GetPlayerPed(player))
end

-- Send notification to a player
function Utils.NotifyPlayer(player, message, type)
    if not message then return end
    
    -- Use QBCore notification system if enabled
    if Config.UI.notifications.useQBCore then
        TriggerClientEvent('QBCore:Notify', player, message, type, Config.UI.notifications.duration)
        return
    end
    
    -- Otherwise use our custom notification system
    TriggerClientEvent('report:notification', player, message, Config.Colors[type or "info"])
end

-- Format time for display (converts seconds to MM:SS format)
function Utils.FormatTime(seconds)
    return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

-- Format date for display
function Utils.FormatDate(timestamp)
    return os.date("%Y-%m-%d %H:%M:%S", timestamp)
end

-- Discord webhook integration
function Utils.SendDiscordWebhook(webhookData)
    -- Skip if Discord webhook is not enabled in config
    if not Config.Discord.enabled or not Config.Discord.webhookURL then
        return
    end
    
    -- Debug message
    if Config.Debug then
        print("[REPORT SYSTEM] Sending Discord webhook")
    end
    
    -- Prepare the webhook data
    local data = {
        username = Config.Discord.webhookName or "Report System",
        avatar_url = Config.Discord.webhookAvatar or "",
        embeds = {
            {
                title = webhookData.title or "Player Report",
                description = webhookData.description or "",
                color = webhookData.color or Config.Discord.colors.newReport,
                footer = {
                    text = "MNS Player Report System"
                },
                timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z")
            }
        }
    }
    
    -- Add mention if configured
    if Config.Discord.mentionRole and Config.Discord.mentionRole ~= "" then
        data.content = Config.Discord.mentionRole
    end
    
    -- Add fields if provided
    if webhookData.fields then
        data.embeds[1].fields = webhookData.fields
    end
    
    -- Convert the data to JSON
    local jsonData = json.encode(data)
    
    -- Send the webhook
    PerformHttpRequest(Config.Discord.webhookURL, function(err, text, headers)
        if err ~= 201 then
            print("[REPORT SYSTEM] Discord webhook failed with error: " .. tostring(err))
        elseif Config.Debug then
            print("[REPORT SYSTEM] Discord webhook sent successfully")
        end
    end, 'POST', jsonData, { ['Content-Type'] = 'application/json' })
end

-- Get player info (for admin investigation)
function Utils.GetPlayerInfo(playerId)
    local Player = QBCore.Functions.GetPlayer(playerId)
    if not Player then return nil end
    
    return {
        source = playerId,
        name = GetPlayerName(playerId),
        citizenid = Player.PlayerData.citizenid,
        charinfo = Player.PlayerData.charinfo,
        job = Player.PlayerData.job,
        position = Utils.GetPlayerCoords(playerId),
        money = {
            cash = Player.PlayerData.money.cash,
            bank = Player.PlayerData.money.bank
        }
    }
end

-- Clean/sanitize input text
function Utils.SanitizeText(text)
    if not text then return "" end
    
    -- Remove HTML/script tags
    text = text:gsub("<[^>]*>", "")
    
    -- Remove excessive whitespace
    text = text:gsub("%s+", " ")
    
    return text:trim()
end

-- Get player ID from CitizenID
function Utils.GetPlayerByCitizenId(citizenId)
    local players = QBCore.Functions.GetPlayers()
    for _, playerId in ipairs(players) do
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player and Player.PlayerData.citizenid == citizenId then
            return playerId
        end
    end
    return nil
end

-- Debug logging utility
function Utils.DebugLog(message, level)
    if not Config.Debug then return end
    
    level = level or 'info'
    
    local colors = {
        info = "^5",
        warn = "^3",
        error = "^1",
        success = "^2"
    }
    
    print(string.format("%s[MNS REPORT] %s^7", colors[level] or "^7", message))
end

return Utils