# Info.plist Configuration Guide

## Required Privacy Permissions

Your app needs to request camera and photo library access. Add these keys to your `Info.plist` file.

### Method 1: Using Xcode's Info Tab

1. Select your project in the Project Navigator
2. Select the "OPB P0" target
3. Go to the "Info" tab
4. Click the "+" button to add new entries
5. Add the following keys and values:

| Key | Value |
|-----|-------|
| Privacy - Camera Usage Description | Camera access is required to analyze basketball shooting form in real-time. |
| Privacy - Photo Library Usage Description | Photo library access is required to analyze recorded videos of basketball shooting. |

### Method 2: Editing Info.plist Directly

If you're editing the `Info.plist` file directly (as source code), add:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Existing keys... -->
    
    <!-- Camera Permission -->
    <key>NSCameraUsageDescription</key>
    <string>Camera access is required to analyze basketball shooting form in real-time.</string>
    
    <!-- Photo Library Permission -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Photo library access is required to analyze recorded videos of basketball shooting.</string>
    
    <!-- Optional: If you plan to add photos to the library in future -->
    <!-- <key>NSPhotoLibraryAddUsageDescription</key>
    <string>Save analyzed videos to your photo library.</string> -->
</dict>
</plist>
```

## Supported Interface Orientations

For optimal pose detection during basketball shooting, the app should support landscape orientations. Configure in:

**Project Settings → General → Deployment Info → Device Orientation**

Recommended settings:
- ✅ Landscape Left
- ✅ Landscape Right
- ✅ Portrait (for menu navigation)
- ❌ Upside Down Portrait (optional, usually disabled)

## Background Modes (Optional - Future Enhancement)

If you want to continue processing in the background (not needed for Phase 1):

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

## Minimum Deployment Target

Ensure your deployment target is set correctly:

- **iOS Deployment Target**: 16.0 or later

Check: Project Settings → General → Minimum Deployments → iOS

## Device Requirements

Add device capabilities (optional but recommended for documentation):

```xml
<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>armv7</string>
    <string>camera-flash</string>
    <string>video-camera</string>
</array>
```

## Status Bar Appearance

Since the camera view hides the status bar for full-screen experience:

```xml
<key>UIViewControllerBasedStatusBarAppearance</key>
<true/>
```

This is the default in modern iOS apps and allows per-view-controller status bar control.

## Complete Example Info.plist

Here's a complete example of what your Info.plist should contain:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>One Percent</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    
    <!-- Privacy Permissions -->
    <key>NSCameraUsageDescription</key>
    <string>Camera access is required to analyze basketball shooting form in real-time.</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Photo library access is required to analyze recorded videos of basketball shooting.</string>
    
    <!-- UI Configuration -->
    <key>UILaunchScreen</key>
    <dict/>
    <key>UIViewControllerBasedStatusBarAppearance</key>
    <true/>
    
    <!-- Supported Interface Orientations -->
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
        <string>UIInterfaceOrientationLandscapeLeft</string>
        <string>UIInterfaceOrientationLandscapeRight</string>
    </array>
    
    <!-- Device Capabilities -->
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
</dict>
</plist>
```

## Verification

After adding these permissions:

1. Clean build folder (⌘⇧K)
2. Build and run on a physical device
3. When prompted, grant camera and photo library permissions
4. Test both real-time camera and video analysis features

## Important Notes

- **Physical Device Required**: Pose detection and camera features require a physical iOS device
- **Simulator Limitations**: The iOS Simulator does not support camera or pose detection
- **First Run**: Users will be prompted to grant permissions on first use
- **Settings**: Users can manage permissions in Settings → Privacy & Security → Camera/Photos

## Troubleshooting

**Permission Dialog Not Appearing:**
- Delete the app from your device
- Clean build folder in Xcode
- Rebuild and reinstall

**Permission Denied:**
- Go to Settings → Privacy & Security → Camera → One Percent → Enable
- Go to Settings → Privacy & Security → Photos → One Percent → Enable

**Build Error "Missing Required Key":**
- Ensure both NSCameraUsageDescription and NSPhotoLibraryUsageDescription are in Info.plist
- The usage description strings cannot be empty
