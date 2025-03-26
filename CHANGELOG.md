# Changelog

All notable changes to this project will be documented in this file.

## [0.10.0] - 2025-02-28

### 🚀 Features

- [WIP] implement lexer, parser, and evaluator for mathematical expressions
- This works, damn this is crazy
- Add math expression handling in Runner and update UI components
- Add autostart control option to CLI
- Add tray button styles with rotation effect to NavBar
- Add font size property to CircularProgressBar for customizable text size
- Add volume control to NavBar with CircularProgressBar integration
- Add speaker property to NavBar for volume control integration
- Add icon name property to CircularProgressBar for customizable icon display
- Implement icon caching in CircularProgressBar for improved performance?
- Update font in CircularProgressBar and adjust size measurement logic
- Add wyvern SVG asset and integrate into Settings UI, fix mprsi_box shown when no players available
- Add accent background styling for buttons with hover effect
- Enhance QBluetooth UI with tooltips and battery status display
- Implement singleton pattern in QuickMenu class
- Set default dimensions for QuickMenu
- Initialize Adw and improve error logging in Morghulis class
- Add right-click functionality to TagButton and improve CSS class management
- Implement singleton pattern for OnScreenDisplay and add volume change method
- Add volume control handling in request method
- Enhance notification system with sound playback and visibility management
- Add NotifPopItem and update notification handling in the application
- Init CircularProgress variant
- Add fill rule option to CircularProgress and update geometry handling
- Integrate AstalWp.Endpoint for speaker volume control in NavBar
- Enhance CircularProgressBar with default CSS styling for improved visuals
- Add power profile buttons for performance, balanced, and power saver modes
- Add 'numeric' style to MenuButton Clock in NavBar for enhanced display options
- Implement accent hover color and update NavBar styles for improved UI
- Improve volume_bin by better tooltip and ScrollController
- Integrate GSound for notification sounds
- Add Gizmo helper widget for custom widget creation
- Enhance size allocation and measurement for CircularProgressBar
- Add start_at and end_at properties to CircularProgressBar for customizable progress range
- Add angle normalization to CircularProgressBar for consistent progress range
- Add angles_changed signal to CircularProgressBar for angle normalization notifications
- Add inverted, start-at, and end-at properties to NavBar for enhanced customization
- Update PowerBox to include logout functionality and adjust button spacing
- Enable markup usage in NotificationItem for enhanced text formatting
- Implement PowerOption enum for improved action handling in PowerBox
- Add QAudioBox and QAudioItem components for audio management
- Enhance QAudioBox layout with overlay and scrolled window for improved user experience
- Refactor Tray class to use Gtk.FlowBox for improved item layout management
- Add master border radius variable and apply to button styles
- Add ScrollingLabel widget with customizable scrolling behavior

### 🐛 Bug Fixes

- *(Settings.vala)* Correct comparison operator in ppd_present method
- Ppd_present
- Correct logic in looks_like_math function and update visibility handling in Runner
- Round percentage display in CircularProgressBar for improved accuracy
- Bug where tray items will tell the Popover MenuButton that:
- Unused modifier for wicons
- Duplicating `List' instance
- Missing classes
- NotifPopCenter not allocating enough height
- NotifItem current time format
- Max width notifs items at body
- Update icon transform properties in NavBar styles
- Allow line width to be set to zero in CircularProgressBar
- Handle zero or negative line width in CircularProgress RadiusFill rendering
- Change modifier of old internal classes at CPB
- Correct construct method definition in CircularProgressBar
- Update identity for power profiles in Settings to improve clarity
- Power_button goinginvi
- Remove unused spacing
- Numeric labels
- Adjust NotificationItem styles for improved layout
- Move file css before Windows creation
- NotifItem actions
- Update logout command to terminate user session correctly
- Adjust QuickMenu and Settings dimensions
- Replace manual label update with property binding for focused view in NavBar
- Ensure client title is checked for null before accessing properties
- Remove unnecessary update_revealer_visibility method and simplify edge reached logic
- Adjust brightness of occupied navbar color for better visibility
- Add debug logging for unsupported backlight interface

### 🚜 Refactor

- QBluetooth and QBluetoothItem to use ListBox and improve padding
- [**breaking**] Add Math subdirectory with lexer, parser, and evaluator build configuration
- Runner as Top anchored, using Gdk.Display and Monitor to margin it up in height by 4
- Commented volume_bin CircularProgress
- Remove duplicated "master_border" style from NavBar bins
- Remove unused Colors.scss and update references to master-border-radius
- Remove unused mpris_time_label styles and update Mpris layout to use `numeric` classes
- Remove Runner styles and update references in main.scss and UI files
- Remove Mpris styles and update references to hslider in main.scss and UI files
- Remove unused styles from OnScreenDisplay and QuickMenu
- Remove quick_settings_grid_box styles and update references in UI files
- Add title_6 class with font-size adjustment in main.scss
- Replace quick_settings_button styles with qs_grid and update references in QButton and Settings
- Remove nav_bar_label styles and update references to title-4 in NavBar
- Update HyprWorkspaces and RiverTags constructors to accept dependencies
- Simplify art_url method logic for URL validation and consistency
- `has_windows` -> `occupied` and update button CSS classes in NavBar
- Update NavBar accesibilty and improve tooltip text
- Mpris to MprisPlayer, set some tooltips
- Update QPowerProfiles layout and improve component structure
- [**breaking**] [READ BELOW] Remove unused SVG assets and update UI button icons
- Simplify blueprint input declaration in meson.build
- Update NotifWindow class to use property syntax and improve notification sound handling
- Update UI styles in NotifWindow, QBluetooth, and QNetwork for consistency
- Improve property accessors and encapsulate display setup in Morghulis class
- Remove default dimensions from Settings and improve power profiles check
- NavBar code's layout and improve initialization
- Move clock_format to Morghulis class for centralized time formatting
- Use centralized clock_format in NotifPop for time formatting
- Move Mpris and Notifd properties to private and adjust NavigationView declaration
- Remove tag from NavigationPage and connect visibility change to settings navigation
- Update notification resources in meson.build files
- Rename notification classes and update resource files
- Remove unused progress bar and timeout handling from notification classes
- NotifPopItem and NotifPopItemsCenter for improved notification handling and structure
- Remove auto-remove functionality from NotifPopItem and implement timeout handling in NotifPopItemsCenter
- Remove unused timeout_ids from NotifPopItemsCenter
- Simplify notification handling in NotifPopItemsCenter by consolidating sound playback and notification addition logic
- Update NotifPopItem and NotifPopItemsCenter for improved layout and action handling
- Improve accessibility
- Encapsulate properties in PowerBox and improve error handling
- [**breaking**] Remove old CircularProgressBar class and update references to `CircularProgressSnapshot` as `CircularProgressBar`
- CircularProgressBar filename
- Integrate AstalBattery and AstalPowerProfiles for enhanced power profile management, usin new CircularProgress
- Restructure battery display in NavBar for improved visibility and layout
- Simplify CSS loading by creating a color lightening function and consolidating provider addition
- Remove QuickMenu styles and update related components
- [**breaking**] Rename NotifItem to NotificationItem and update related files
- Add NotificationPopupsCenter and QNotifications for enhanced notification management
- Update NavBar styles for consistency and enhance CircularProgressBar functionality
- Improve child handling in CircularProgressBar and enhance focusability
- Streamline CircularProgressBar integration in NavBar for improved volume display
- Enhance documentation and structure of CircularProgressBar widget
- Simplify property definitions and improve geometry calculations in CircularProgressBar
- Replace custom fill classes with Gizmo for CircularProgressBar
- Remove unnecessary notify connections in CircularProgressBar
- Change function pointers to unowned in Gizmo class
- Remove width-request from NavBar template
- Change variable types for improved clarity in CircularProgressBar calculations
- Change class and method visibility in CircularProgressBar for better encapsulation
- Remove SliderBox component and update PowerBox for uptime display
- Using custom qbutton css class for accent handling
- Improve variable naming and streamline workspace handling in NavBar and HyprWorkspaces
- Simplify Gtk.GestureClick initialization and improve child assignment in TagButton
- Improve variable naming and access in NotifPopItemsCenter
- Implement singleton pattern for Runner instance management
- Streamline Gtk.MenuButton initialization in Tray class
- Update README and meson.build to clarify libgtop dependency
- Remove namespace and anchor properties from UI templates to ignore LayerShell Warnings
- Integrate AstalNotifd as public prop for notification dnd

### 📚 Documentation

- Update README to clarify optional dependencies and enhance feature list
- Add "Thanks to" section with acknowledgments in README.md
- Update README to mark Brightness and Backlight as completed

### 🎨 Styling

- Update notification styles and structure for improved clarity
- Format code for consistency in ast.h
- Add missing line break in Runner class for improved readability
- Update uncrustify configuration to break switch cases with their corresponding cases
- Change indent break statements in switch cases
- Add comment for Uncrustify configuration
- Consistency at QuickMenu
- Improve layout and spacing in NotifPopItem
- Add padding CSS class to QNetwork box
- Improve consistency in code
- Standardize style definitions across UI components
- Calculate_measurement
- Using _ prefix for private fields
- Update QAudioBox and QAudioItem for improved UI elements
- Update QAudioItem styles for consistency and improved layout

### ⚙️ Miscellaneous Tasks

- Update header comments in CircularProgressBar for clarity and attribution
- Set width request for NavBar volume bin
- Update README with OSD volume control instructions and modify request method for volume change
- Remove unused style classes
- Flat style for notifs
- Revert calculate_measurement
- Update flake.nix & flake.lock

### Hypr

- Fix active submap

### Mpris

- Using rebular iterator for consistency

### Navbar

- Remove unused props and cmts
- Add toggle volume to volume_bin
- Update NavBar time display
- Occupied color based on accent

### Powerbox

- Better uptime

### River

- Enhance NavBar with urgent state and refactor TagButton for better CSS management

### Runner

- Using get_first_child, not launching app if looks like math(probably)

### Scss

- [**breaking**] Refactor scss style classes to use less individual ones.
- Improve flats button class

### Tray

- FlowBox SelectionMode.None

<!-- generated by git-cliff -->
