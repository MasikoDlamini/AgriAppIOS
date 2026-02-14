# Agribusiness News App

A native iOS app built with SwiftUI that wraps the [Agribusiness Media](https://agribusinessmedia.com) website in a clean, native iOS interface.

## Features

- **Native WebView Integration**: Seamless integration with WKWebView for optimal performance
- **SwiftUI Architecture**: Modern SwiftUI-based app structure for iOS 16+
- **Navigation Controls**: Back button, reload, and Safari view options
- **Loading Indicators**: Visual feedback during page loads
- **Secure Connection**: Properly configured App Transport Security for HTTPS connections
- **Gesture Support**: Swipe navigation gestures enabled
- **iPad Support**: Responsive design for both iPhone and iPad

## Requirements

- macOS with Xcode 15 or later
- iOS 16.0+ deployment target
- Apple Developer account (for device deployment)

## Project Structure

```
AgribusinessNewsApp/
├── AgribusinessNewsApp/
│   ├── AgribusinessNewsAppApp.swift      # Main app entry point
│   ├── Views/
│   │   ├── ContentView.swift             # Main content view with navigation
│   │   ├── WebView.swift                 # WKWebView wrapper
│   │   └── SafariView.swift              # Safari view controller wrapper
│   ├── Models/
│   │   └── WebViewModel.swift            # View model for web state management
│   ├── Assets.xcassets/                  # App icons and colors
│   └── Info.plist                        # App configuration
└── AgribusinessNewsApp.xcodeproj/        # Xcode project file
```

## Getting Started

### Opening the Project

1. Navigate to the project folder:
   ```bash
   cd "/Users/masikodlamini/Documents/Agribusiness app"
   ```

2. Open the project in Xcode:
   ```bash
   open AgribusinessNewsApp.xcodeproj
   ```

### Building and Running

#### Using Xcode GUI:

1. Open `AgribusinessNewsApp.xcodeproj` in Xcode
2. Select a target device (iPhone simulator or physical device)
3. Click the "Play" button (⌘+R) to build and run

#### Using Command Line:

Build the project:
```bash
xcodebuild -project AgribusinessNewsApp.xcodeproj -scheme AgribusinessNewsApp -configuration Debug
```

Run on simulator:
```bash
xcodebuild -project AgribusinessNewsApp.xcodeproj -scheme AgribusinessNewsApp -destination 'platform=iOS Simulator,name=iPhone 15' build
```

### Code Signing

Before deploying to a physical device:

1. Open the project in Xcode
2. Select the project in the navigator
3. Select the "AgribusinessNewsApp" target
4. Go to "Signing & Capabilities"
5. Select your development team
6. Xcode will automatically manage provisioning profiles

## Configuration

### Changing the Website URL

To point to a different website, modify the URL in `WebViewModel.swift`:

```swift
@Published var urlString = "https://your-website.com"
```

### App Display Name

The app display name is set in `Info.plist`:
```xml
<key>CFBundleDisplayName</key>
<string>Agribusiness News</string>
```

### Bundle Identifier

Update the bundle identifier in the Xcode project settings:
1. Select the project in the navigator
2. Select the target
3. Update "Bundle Identifier" under "General"

Current identifier: `com.agribusiness.newsapp`

## Key Components

### WebView
A UIViewRepresentable wrapper around WKWebView that provides:
- JavaScript support
- Navigation delegation
- Loading state management
- Back/forward navigation gestures

### WebViewModel
An ObservableObject that manages:
- Current URL
- Loading states
- Navigation capabilities (back/forward)
- Navigation commands

### ContentView
The main view that provides:
- Navigation bar with controls
- Loading indicator overlay
- Safari view modal presentation

## Customization

### Adding App Icons

1. Open `Assets.xcassets/AppIcon.appiconset` in Xcode
2. Drag and drop icon images for different sizes
3. Required sizes: 1024x1024 (App Store), plus various sizes for devices

### Changing Accent Color

1. Open `Assets.xcassets/AccentColor.colorset`
2. Select the color set
3. Choose your preferred accent color in the Attributes Inspector

### Adding Features

Consider adding:
- Pull-to-refresh functionality
- Share button for sharing articles
- Bookmark/favorites system
- Push notifications
- Offline mode with caching
- Custom error pages

## Troubleshooting

### Build Errors

**"No signing certificate found"**
- Add your Apple Developer account in Xcode Preferences
- Select your team in Signing & Capabilities

**"WebView not loading"**
- Check App Transport Security settings in Info.plist
- Verify network connectivity
- Check website accessibility

### Runtime Issues

**Blank white screen**
- Check the console for error messages
- Verify the URL is correct and accessible
- Ensure JavaScript is enabled if required

## App Store Submission

Before submitting to the App Store:

1. Update version and build numbers
2. Add proper app icons (all required sizes)
3. Create app screenshots
4. Add privacy policy if collecting data
5. Ensure compliance with Apple's App Store Review Guidelines
6. Consider whether your app adds sufficient value beyond the mobile website

## License

This project is created for personal/business use. Make sure you have rights to wrap the website content in an app.

## Support

For issues related to:
- **App Development**: Check Xcode console for errors
- **Website Content**: Contact Agribusiness Media
- **iOS Development**: Visit [Apple Developer Documentation](https://developer.apple.com/documentation/)

## Version History

- **1.0** (Current) - Initial release with basic WebView functionality

---

Built with SwiftUI for iOS 16+
