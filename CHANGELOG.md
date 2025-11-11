# Changelog

All notable changes to this project will be documented in this file.

## [0.14.0] - 2025-11-11

### 🚀 Features

- Add support for UWSM session in app launch handling
- Implement app stack navigation and improve app visibility logic
- *(PowerMenu)* Add visibility toggle to confirm method
- *(NavBar)* Implement WorkspaceItem class for workspace button interactions
- *(RiverTags)* Refactor tag button implementation to use WorkspaceItem
- *(Rolltop)* Implement initialize_items method and call it in constructors
- *(ScreenRecord)* Add ScreenRecord functionality and UI integration
- *(ScreenRecord)* Enhance screenshot functionality and add recording controls
- *(ScreenRecord)* Update layout styles and adjust margin for better UI presentation
- *(ScreenRecord)* Remove unused on_close method and update callback signatures to async
- *(ScreenRecord)* Update start_record method to include is_region parameter
- *(ScreenRecord)* Refactor recording logic and enhance UI feedback for recording status
- *(ScreenRecord)* Add recording duration display and enhance UI feedback for recording status
- *(ScreenRecord)* Add screen_rec_box styles for enhanced UI effects
- *(ScreenRecord)* Refactor screenshot notification handling and add clipboard functionality
- *(ScreenRecord)* Enhance button focus handling and improve transition effects
- *(PowerMenu)* Enhance keyboard navigation and focus handling
- *(OnScreenDisplay)* Add MorghulProgressBar with animation support
- *(OnScreenDisplay)* Add keyboard layout handling for Hyprland
- *(OnScreenDisplay)* Add battery status handling and UI integration
- Add drag and drop functionality to WorkspaceItem, to switch workspaces or tags
- Integrate Hyprland detection and enhance window animations
- *(OnScreenDisplay)* Optimize visibility checks before showing OSD
- *(Notifications)* Add configurable default notification timeout
- *(OnScreenDisplay)* Add OSD timeout configuration and sound notification support
- *(CssManager)* Add new app.css for enhanced theming and update CSS loading logic
- *(AppSettings)* Add AppSettings UI and functionality for application configuration
- Migrate to Adw API and add color scheme toggle
- Add cute 100% necessary floating animation to an arrow that is barely visible
- Show scroll-down indicator for network list
- Show scroll indicator and refine QBluetooth UI
- Add scroll indicator to QNotifications
- Add hashtable to qnotifications, for better performance

### 🐛 Bug Fixes

- I don't know when this happened wtf
- Adjust brightness filter for occupied state in NavBar
- Add margin adjustments for QuickMenu based on NavBar position
- Pass command line to handle_request for improved feedback
- Enhance error reporting in handle_request and toggle_window methods
- Refactor SVG icons for improved symbolic props
- Remove unnecessary path element from SVG icons for cleaner markup
- Format SVG files for consistent indentation and cleaner markup
- Update user image path to use .face.icon for consistency
- Prevent unnecessary dispatch of workspace command on button click
- Improve app launch handler logic and formatting in AppsCmdButton
- Correct binary name extraction logic in app launch handler
- Add appstream to runtime-utils and remove GTK_THEME variable
- Update no-results page label and improve layout styles
- Ensure consistent layout properties in apps stack configuration
- Improve client title binding management in Hyprland setup
- Correct app executable field reference in AppsCmdButton
- Update clear_notifications method to be async and avoid modification during iteration
- Enhance error handling for network and access point management
- *(PowerMenu)* Use a local variable for current option in confirm method
- *(SysInfo)* Remove unnecessary comments in timeout and calculations
- *(PowerMenu)* Improve left button navigation logic in key_released method
- *(OnScreenDisplay)* Add easing to MorghulProgressBar animations
- *(NotificationPopupsCenter)* Add namespace to notification list box
- *(MorghulProgressBar)* Correct syntax by removing unnecessary line break in animation function
- Treat default as light when toggling color-scheme
- Wrong square styling in $Settings
- Round styles not applying to qnetwork

### 🚜 Refactor

- Optimize command-line handling in Morghulis application
- Move CircularProgress and Gizmo to App, and remove ScrollingLabel and its references
- Remove gschema.xml installation and validation from meson.build
- Simplify NavBar constructor by moving navbar anchor logic to NavBar class
- Remove unused GtkLayerShell import from NavBar class
- Store command line in a class variable for improved readability
- Workspace and tag management to use Rolltop base class
- *(Rolltop)* Simplify underline drawing and improve position update logic
- *(PowerMenu)* Simplify button handling and remove hibernate option
- *(PowerMenu)* Remove focus restrictions from action and confirmation buttons
- Use AstalNetwork API, and drop two-ways libnm shit
- Rotieren spinner instead of Adw.Spinner

### 🎨 Styling

- [**breaking**] Spaces instead of tabs, tabs with uncrustify on Vala is completely broken
- Replace ellipses with proper character in debug messages

### ⚙️ Miscellaneous Tasks

- Optimise svgs
- *(nix)* Update flake.lock and remove nixd from flake.nix

### No-need-for-this

- Clarify unreachable code comment in confirm method

<!-- generated by git-cliff -->
