# Troubleshooting Guide

Common issues and solutions for the One Percent basketball training app.

## Build & Compilation Issues

### Missing Privacy Keys Error
**Error:** `This app has crashed because it attempted to access privacy-sensitive data without a usage description.`

**Solution:**
1. Open your `Info.plist` file
2. Add the required privacy keys:
   - `NSCameraUsageDescription`
   - `NSPhotoLibraryUsageDescription`
3. See `INFO_PLIST_SETUP.md` for detailed instructions
4. Clean build folder (⌘⇧K) and rebuild

### Cannot Run on Simulator
**Issue:** Pose detection doesn't work on simulator

**Explanation:** This is expected behavior. The Vision framework's pose detection requires actual device hardware.

**Solution:** Always test on a physical iOS device (iPhone 12 or newer recommended)

### SwiftUI Preview Not Working
**Issue:** Xcode preview crashes or doesn't display

**Solution:**
1. The camera and pose detection views won't work in preview (require hardware)
2. Use the `#Preview` macros for static UI components only
3. Test dynamic features on physical device
4. For pose overlay testing, use sample `PoseData` (see `PoseOverlayView` preview)

## Runtime Issues

### Camera Not Starting

**Symptom:** Black screen in camera view

**Possible Causes & Solutions:**

1. **Permission Denied**
   - Check: Settings → Privacy & Security → Camera → One Percent
   - Enable camera access
   - Restart the app

2. **Camera in Use by Another App**
   - Close other camera apps
   - Force quit all apps and try again
   - Restart device if needed

3. **Setup Failed**
   - Check console logs for specific error
   - Ensure device is not in Low Power Mode
   - Try on a different device

### Pose Detection Not Working

**Symptom:** Camera works but no skeleton overlay appears

**Possible Causes & Solutions:**

1. **Insufficient Lighting**
   - Move to a well-lit area
   - Avoid backlighting (light behind subject)
   - Recommended: 300+ lux lighting

2. **Person Not in Frame**
   - Ensure full body is visible
   - Step back from camera
   - Check camera is not pointed at wrong direction

3. **Person Too Far Away**
   - Move closer to camera
   - Optimal distance: 6-12 feet
   - Ensure person takes up significant portion of frame

4. **Fast Movement**
   - Slow down movements temporarily to test
   - Pose detection has limits with very fast motion
   - This is expected for explosive basketball movements

### Low FPS / Laggy Performance

**Symptom:** FPS below 20, stuttering video, dropped frames

**Possible Causes & Solutions:**

1. **Device Thermal Throttling**
   - Device overheating after extended use
   - Let device cool down
   - Reduce session length
   - Remove phone case for better heat dissipation

2. **Low Power Mode Enabled**
   - Disable Low Power Mode: Settings → Battery
   - Low Power Mode caps CPU/GPU performance

3. **Background Apps**
   - Close all background apps
   - Restart device
   - Ensure at least 2GB free storage

4. **Older Device**
   - iPhone 11 and older may struggle
   - Consider upgrading to iPhone 12+
   - Reduce camera resolution (requires code modification)

5. **Poor Lighting**
   - Camera works harder in low light
   - Increase ambient lighting
   - Avoid using in dark environments

### Video Import Issues

**Symptom:** Cannot select or load videos from photo library

**Possible Causes & Solutions:**

1. **Permission Denied**
   - Check: Settings → Privacy & Security → Photos → One Percent
   - Change access to "Full Access" or "Selected Photos"
   - Restart app

2. **Unsupported Video Format**
   - App supports: MP4, MOV, M4V
   - Convert video using QuickTime or Photos app
   - Export from camera roll if iCloud Photo Library

3. **iCloud Photo Library**
   - Video may not be downloaded locally
   - Tap video in Photos app to download
   - Wait for download to complete
   - Try importing again

4. **Corrupted Video File**
   - Try playing video in Photos app first
   - If it doesn't play there, it won't work in our app
   - Re-record or use different video

### Video Playback Issues

**Symptom:** Video imported but won't play or shows black screen

**Possible Causes & Solutions:**

1. **Large Video File**
   - Very long videos (>5 min) may cause issues
   - Try with shorter video first
   - Consider trimming video in Photos app

2. **High Resolution Video**
   - 4K videos may lag on older devices
   - Export video at 1080p or 720p
   - Use lower resolution for testing

3. **Memory Pressure**
   - Close app completely
   - Restart device
   - Try with smaller video

### Skeleton Overlay Misaligned

**Symptom:** Skeleton drawn in wrong position relative to person

**Possible Causes & Solutions:**

1. **Orientation Issue**
   - Ensure video/camera is in landscape mode
   - Portrait videos may have coordinate translation issues
   - Re-record in landscape if possible

2. **Aspect Ratio Mismatch**
   - Video aspect ratio differs from screen
   - This is a known limitation
   - Use videos with 16:9 aspect ratio for best results

## Performance Issues

### High Battery Drain

**Symptom:** Battery drains quickly during use

**Explanation:** This is expected behavior for real-time computer vision

**Mitigation:**
1. Use device while charging for extended sessions
2. Close background apps
3. Reduce screen brightness
4. Disable unnecessary features (Wi-Fi, Bluetooth)
5. Take breaks to let device cool down

**Monitoring:**
- Settings → Battery → Battery Health
- Check if app is consuming excessive power
- Typical usage: 15-25% battery per hour (varies by device)

### Device Getting Hot

**Symptom:** Device becomes uncomfortably warm

**Explanation:** Normal for intensive CV processing

**Solutions:**
1. Remove phone case
2. Avoid direct sunlight
3. Take breaks every 10-15 minutes
4. Use in air-conditioned environment if possible
5. Do not charge while using (if possible)

**When to Stop:**
- Device displays temperature warning
- FPS drops below 15
- App becomes unresponsive

### App Crashes

**Symptom:** App crashes unexpectedly

**Immediate Actions:**
1. Note what you were doing when crash occurred
2. Restart the app
3. If persists, restart device

**Data Collection:**
1. Check crash logs: Settings → Privacy & Security → Analytics & Improvements → Analytics Data
2. Look for "OPB P0" crash logs
3. Share crash log for debugging (if reporting issue)

**Common Crash Causes:**

1. **Memory Overflow**
   - Large video files
   - Extended runtime
   - Solution: Process shorter videos, restart app periodically

2. **Threading Issues**
   - Very rare, but possible
   - Solution: Report with reproduction steps

3. **Permission Denied Mid-Use**
   - User revoked permission while app running
   - Solution: Restart app after granting permission

## Accuracy Issues

### Poor Pose Detection Accuracy

**Symptom:** Skeleton flickers, missing joints, wrong positions

**Factors Affecting Accuracy:**

1. **Lighting (Most Important)**
   - Bright, even lighting is critical
   - Avoid shadows, backlighting
   - Recommended: 500+ lux for best results

2. **Clothing**
   - Tight-fitting clothing works best
   - Loose/baggy clothing reduces accuracy
   - High contrast clothing vs background helps

3. **Background**
   - Simple, uncluttered background best
   - Avoid busy patterns
   - Avoid other people in frame

4. **Camera Angle**
   - Side view (profile) works best for shooting analysis
   - 45-degree angle acceptable
   - Straight-on view may miss depth information

5. **Distance**
   - Optimal: 8-10 feet from camera
   - Too close: not all joints in frame
   - Too far: insufficient detail

### Confidence Always Low (Yellow/Red Joints)

**Symptom:** Joints never show as green (high confidence)

**Solutions:**
1. Improve lighting dramatically
2. Ensure full body visible
3. Use contrasting clothing
4. Clean camera lens
5. Test with different person (body type affects detection)

## Advanced Issues

### Memory Leaks

**Symptom:** App gets slower over time, eventually crashes

**Diagnosis:**
1. Open Instruments (⌘I in Xcode)
2. Run "Leaks" instrument
3. Use app for 5-10 minutes
4. Check for leaked memory

**Solution:**
- If found, please report with reproduction steps
- Temporary workaround: Restart app every 15-20 minutes

### Thread Deadlock

**Symptom:** App freezes completely, must force quit

**Diagnosis:**
- Very rare with current architecture
- Check console for thread warnings

**Solution:**
- Force quit app (swipe up from app switcher)
- Restart device if persists
- Report issue with reproduction steps

## Getting Help

### Before Reporting an Issue

Collect this information:
1. Device model and iOS version
2. Steps to reproduce
3. What you expected vs what happened
4. Console logs (if possible)
5. Screenshot/video of issue
6. Performance metrics at time of issue

### Debug Console Logs

To view logs while running from Xcode:
1. Run app from Xcode (⌘R)
2. Keep Xcode connected
3. View console output at bottom of Xcode
4. Look for error messages or warnings

### Performance Debugging

Check performance metrics in the app:
1. Enable metrics display (gauge icon)
2. Monitor:
   - **FPS**: Should be 25-30
   - **Latency**: Should be <35ms
   - **Dropped Frames**: Should be <5% of total

### Reset App State

If all else fails:
1. Force quit app
2. Delete app from device
3. Restart device
4. Reinstall app from Xcode
5. Test with simple scenario first

## Known Limitations

These are expected behaviors, not bugs:

1. **Single Person Detection**: Only detects one person
2. **No Depth Information**: 2D pose only, no 3D coordinates
3. **Occlusion Issues**: Joints behind body not detected
4. **Fast Motion Blur**: Very fast movements may be missed
5. **Device Requirements**: Requires iPhone 12+ for optimal performance
6. **Lighting Requirements**: Indoor court lighting may be insufficient
7. **Battery Consumption**: Heavy battery use is normal for CV apps

## Future Improvements

These limitations may be addressed in future phases:

- Better low-light performance
- Multiple person tracking
- 3D pose estimation
- Improved fast motion tracking
- Reduced battery consumption
- Offline processing optimization

---

**Can't find your issue?** 

Check the README.md for general information or create a detailed issue report with:
- Device info
- iOS version
- Steps to reproduce
- Expected vs actual behavior
- Screenshots/logs if possible
