# One Percent - Basketball Training App (Phase 1: Proof of Concept)

A basketball training app that analyzes shooting form and performance using computer vision and pose detection.

## Phase 1 Goals

This proof of concept validates the core computer vision technology:

1. ✅ Basic camera capture with real-time pose detection overlay
2. ✅ Pose detection accuracy validation during basketball shooting motions
3. ✅ Performance testing (frame rate, battery usage) on iPhone 12+
4. ✅ Simple video analysis from photo library
5. 🔜 Ball tracking prototype (next iteration)

## Technical Stack

- **Language**: Swift
- **UI Framework**: SwiftUI
- **Architecture**: MVVM
- **Computer Vision**: Apple Vision Framework (VNDetectHumanBodyPoseRequest)
- **Video Capture**: AVFoundation (AVCaptureSession)
- **Reactive Programming**: Combine
- **Minimum iOS Version**: iOS 16+

## Project Architecture

```
OPB P0/
├── Models/
│   ├── PoseData.swift           # Pose joint data structures
│   └── PerformanceMetrics.swift # FPS & latency tracking
│
├── Managers/
│   ├── CameraManager.swift      # AVFoundation camera session
│   └── PoseDetectionManager.swift # Vision framework integration
│
├── ViewModels/
│   ├── CameraViewModel.swift    # Real-time camera state
│   └── VideoAnalysisViewModel.swift # Video analysis state
│
├── Views/
│   ├── MainMenuView.swift       # Main menu
│   ├── CameraView.swift         # Real-time camera + pose
│   ├── VideoAnalysisView.swift  # Video library analysis
│   ├── PoseOverlayView.swift    # Skeleton visualization
│   └── PerformanceMetricsView.swift # HUD metrics display
│
├── ContentView.swift
└── OPB_P0App.swift
```

## Key Features

### Real-Time Pose Detection
- 30 FPS camera capture in landscape mode
- 19-point body pose detection using Vision framework
- Real-time skeleton overlay with confidence indicators
- Performance metrics HUD (FPS, latency, dropped frames)

### Video Analysis
- Import videos from photo library
- Frame-by-frame pose analysis
- Playback controls with scrubbing
- Same pose visualization as real-time mode

### Tracked Body Points
Focus on basketball shooting mechanics:
- **Upper Body**: Wrists, Elbows, Shoulders
- **Lower Body**: Hips, Knees, Ankles

### Performance Monitoring
- Current & Average FPS
- Processing latency (ms)
- Total frames processed
- Dropped frame count

## Setup Instructions

### 1. Camera Permissions

Add these keys to your `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required to analyze basketball shooting form in real-time.</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is required to analyze recorded videos of basketball shooting.</string>
```

### 2. Build Configuration

- **Target**: iOS 16.0+
- **Devices**: iPhone 12 and newer (recommended)
- **Orientation**: Landscape (camera view)

### 3. Running the App

1. Open the project in Xcode 15+
2. Select a physical iOS device (pose detection requires device hardware)
3. Build and run (⌘R)

## Usage

### Real-Time Camera Mode

1. Launch app
2. Tap "Real-Time Camera"
3. Grant camera permission
4. Point camera at a person performing basketball shooting motions
5. View pose skeleton overlay in real-time
6. Tap gauge icon to toggle performance metrics
7. Tap X to exit

### Video Analysis Mode

1. Launch app
2. Tap "Analyze Video"
3. Tap "Choose Video"
4. Select a video from your photo library
5. Use playback controls to play/pause/scrub
6. Pose detection runs automatically as video plays
7. View performance metrics
8. Tap "Done" to exit

## Architecture Details

### MVVM Pattern

**Models**
- `PoseData`: Represents detected pose with joints and confidence
- `PerformanceMetrics`: Tracks real-time performance statistics

**Managers (Business Logic)**
- `CameraManager`: Handles AVCaptureSession configuration and lifecycle
- `PoseDetectionManager`: Processes frames with Vision framework

**ViewModels**
- `CameraViewModel`: Orchestrates camera and pose detection for real-time mode
- `VideoAnalysisViewModel`: Manages video playback and pose detection

**Views**
- SwiftUI views for UI presentation
- Modular, reusable components

### Pose Detection Pipeline

```
Camera/Video → CMSampleBuffer/CIImage
              ↓
     VNDetectHumanBodyPoseRequest
              ↓
     VNHumanBodyPoseObservation
              ↓
          PoseData Model
              ↓
     PoseOverlayView (Canvas)
```

### Performance Optimizations

1. **Frame Dropping**: `alwaysDiscardsLateVideoFrames = true`
2. **720p Resolution**: Balance between quality and performance
3. **30 FPS Target**: Optimal for real-time processing
4. **Background Processing**: Dedicated queues for capture and processing
5. **Confidence Filtering**: Only display joints with >0.1 confidence

## Performance Expectations

### Target Metrics (iPhone 12+)
- **FPS**: 25-30 FPS
- **Latency**: <35ms processing time
- **Dropped Frames**: <5% under normal conditions

### Battery Impact
- Real-time camera mode: Moderate-High battery usage (expected for CV)
- Video analysis mode: Moderate battery usage

## Future Enhancements (Next Phases)

### Phase 2: Ball Tracking
- Implement ball detection algorithm
- Track ball trajectory
- Measure shot arc and release angle

### Phase 3: Advanced Analytics
- Calculate release angle from pose + ball data
- Measure elbow alignment
- Detect shot phases (preparation, release, follow-through)
- Shot outcome detection (make/miss)

### Phase 4: Data Persistence
- Save shooting sessions
- Track progress over time
- Generate performance reports

## Troubleshooting

### Pose Detection Not Working
- Ensure adequate lighting
- Ensure full body is visible in frame
- Check camera permissions

### Low FPS
- Close background apps
- Restart device
- Ensure device meets minimum requirements (iPhone 12+)

### Video Import Issues
- Ensure video is in a supported format (MP4, MOV)
- Check photo library permissions

## Code Style & Best Practices

- **Swift Concurrency**: async/await for asynchronous operations
- **Combine**: Reactive state management
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Documentation**: Inline comments for complex logic
- **Modularity**: Separation of concerns for easy testing and extension

## Development Notes

This is a proof of concept focused on validating core CV capabilities. The code is structured to be easily extensible for future phases.

### Adding Ball Tracking
When ready to implement ball tracking:
1. Create `BallTrackingManager.swift` in Managers/
2. Add ball detection using Vision or custom CoreML model
3. Update `CameraViewModel` to coordinate pose + ball tracking
4. Extend `PoseOverlayView` or create `BallOverlayView`

### Testing
While no tests are included in Phase 1, the architecture supports testing:
- Managers can be unit tested
- ViewModels can be tested with mock managers
- UI components can be previewed with sample data

---

Built with ❤️ for basketball training optimization.
