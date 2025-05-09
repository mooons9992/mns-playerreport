Config = {}

-- Version information
Config.Version = {
    number = "1.1.0", 
    name = "Initial Release",
    check = true -- Enable version checking
}

-- Framework integration (QBCore only)
Config.Framework = 'qb'

-- General settings
Config.ReportCooldown = 60 -- Seconds between reports
Config.AdminPermission = "admin" -- QBCore permission level needed to receive reports

-- Permission settings
Config.UseAcePermissions = true -- Use ACE permissions system alongside QBCore permissions
Config.AdminAcePermission = "command.adminreport" -- ACE permission needed for admin access

-- Report functionality
Config.Reports = {
    maxToShow = 6,          -- Maximum number of reports to show in the admin menu
    maxMessageLength = 128, -- Maximum length of report messages
    allowTeleport = true,   -- Allow admins to teleport to the reporting player
    autoClean = true,       -- Automatically clean up old resolved reports
    retentionTime = 21600   -- Time in seconds to keep resolved reports (6 hours)
}

-- Report status options
Config.StatusOptions = {
    pending = {
        label = "Pending",
        color = "warning"
    },
    inProgress = {
        label = "In Progress",
        color = "info"
    },
    resolved = {
        label = "Resolved",
        color = "success"
    }
}

-- Command configuration
Config.Commands = {
    admin = "reports",     -- Command to open the admin reports panel
    player = "report",     -- Command for players to submit a report
    reportMenu = "reportmenu"  -- Command to open the report menu UI
}

-- UI settings
Config.UI = {
    title = "Admin Report System",
    webUI = true,           -- Set to true to use the HTML-based UI instead of native UI
    width = 500,            -- Width of the UI panels in pixels
    theme = "dark",         -- UI theme (dark or light)
    roundedCorners = true,  -- Use rounded corners for UI elements
    animations = true,      -- Enable UI animations
    
    -- Notification settings
    notifications = {
        useQBCore = true,    -- Use QBCore notifications system
        duration = 3000,     -- Duration in ms to show notifications
        position = "top-right", -- Position of UI notifications
        useNative = false,   -- Use native GTA notifications instead of UI notifications
        enableSound = true   -- Play sound when receiving a report
    }
}

-- UI color scheme
Config.Colors = {
    primary = {0, 123, 255, 200},
    secondary = {52, 58, 64, 200},
    success = {40, 167, 69, 200},
    danger = {220, 53, 69, 200},
    warning = {255, 193, 7, 200},
    info = {23, 162, 184, 200},
    light = {240, 240, 240, 200},
    dark = {33, 37, 41, 200},
    text = {255, 255, 255, 255},
    textDark = {33, 37, 41, 255}
}

-- Discord Webhook integration
Config.Discord = {
    enabled = true, -- Set to true to enable Discord webhooks
    
    -- Make sure this URL is correct and complete
    webhookURL = "https://discord.com/api/webhooks/1368645351178764450/vl6YdXzoWJBlwFszXANQnJsIsEQXnIsRsjJTTV-R0zCQbA8qlAfigXLpLGQX3M8oyR9A",
    webhookName = "Report System", -- Name that will appear as the webhook author
    webhookAvatar = "", -- URL to the avatar image for the webhook
    
    -- Embed colors (decimal color values)
    colors = {
        newReport = 16747520,  -- Orange
        inProgress = 1752220,  -- Light blue
        closed = 5763719,      -- Green
        test = 7506394         -- Purple
    },
    
    -- What information to include in webhooks
    includePlayerIds = true,   -- Include player server IDs
    includeTimestamps = true,  -- Include timestamps
    mentionRole = "",          -- Discord role ID to mention (leave empty for none)
    -- For example, to mention @everyone use: mentionRole = "@everyone"
    -- To mention a specific role use its ID: mentionRole = "<@&ROLE_ID>"
}

-- QBCore specific settings
Config.QBCore = {
    useBuiltInPermissions = true, -- Use QBCore's built-in permission system
    adminGroups = {"admin", "god"}, -- QBCore groups that can access admin reports
    modGroups = {"mod"}, -- QBCore groups that can access admin reports (but with fewer permissions)
    
    -- Integration with other QBCore resources
    playerInfoIntegration = true, -- Show player info from QBCore when handling reports
    inventoryCheck = false, -- Allow admins to check player inventory during report resolution
    vehicleCheck = false -- Allow admins to check player owned vehicles during report resolution
}

-- Debug settings
Config.Debug = false -- Enable debug mode with additional console output