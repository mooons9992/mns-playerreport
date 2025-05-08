# MNS Player Report System

A comprehensive player report system for FiveM servers running QBCore framework with a clean GUI interface and Discord webhook integration.

## Features

- **Player Report Submission**: Allow players to submit detailed reports with a custom message
- **Admin Notification System**: Real-time notifications for staff when new reports come in
- **Report Management Interface**: Clean UI for admins to track and manage reports
- **Discord Integration**: Automatically post reports and status updates to Discord
- **Teleportation System**: Easily teleport admins to reporting players' location
- **Permission Management**: QBCore permission system with ACE permission fallback
- **Cooldown System**: Prevents spam reports with configurable cooldowns
- **Report Status Tracking**: Track pending, in-progress, and resolved reports
- **Player Disconnect Handling**: Keeps track of reports even if players disconnect

## Dependencies

- QBCore framework
- qb-core

## Installation

1. Download the latest release
2. Extract to your resources folder as `mns-playerreport`
3. Add `ensure mns-playerreport` to your server.cfg
4. Configure the settings in `config.lua`
5. Update the Discord webhook URL in the config

## Usage

### For Players
- Use `/report <message>` to submit a report directly
- Use `/reportmenu` to open the report UI interface

### For Admins
- Receive notifications when players submit reports
- Use `/reports` to open the admin reports panel
- Click "Teleport" to teleport to the player's location
- Click "Close" to mark a report as resolved
- Use `/testreport` to create a test report (Admin only)

## Configuration

The script includes extensive configuration options:

- UI theme and appearance settings
- Notification templates and messaging
- Discord webhook integration with custom embeds
- Permission levels and admin groups
- Report cooldowns and limits
- Auto-cleanup of old resolved reports

### Permission System

MNS Player Report uses QBCore's permission system with fallback to ACE:

```lua
Config.QBCore = {
   useBuiltInPermissions = true, -- Use QBCore's built-in permission system
   adminGroups = {"admin", "god"}, -- QBCore groups that can access admin reports
   modGroups = {"mod"} -- QBCore groups that can access reports with fewer permissions
}
```

If you're using ACE permissions, make sure to give your admins the proper permission:

```
add_ace group.admin command.adminreport allow
```

## Admin Commands

- `/reports` - Open the admin reports panel
- `/testreport` - Create a test report (Admin only)
- `/test_webhook` - Test the Discord webhook integration (Admin only)

## Version History

### 1.0.0
- Initial release
- QBCore integration
- Discord webhook support
- Report management system
- Permission-based access

## Support

For support or questions about this script or other scripts, join our Discord server or submit an issue on GitHub:
[https://github.com/mooons9992/mns-playerreport](https://github.com/mooons9992/mns-playerreport)