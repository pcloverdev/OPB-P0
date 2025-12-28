# Architecture & Data Flow

This document explains how data flows through the One Percent app and how the components interact.

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         SwiftUI Views                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │ MainMenuView │  │ CameraView   │  │VideoAnalysis │         │
│  │              │  │              │  │    View      │         │
│  └──────────────┘  └──────┬───────┘  └──────┬───────┘         │
└────────────────────────────┼──────────────────┼─────────────────┘
                             │                  │
                             ▼                  ▼
┌─────────────────────────────────────────────────────────────────┐
│                         ViewModels                              │
│  ┌────────────────────────┐  ┌────────────────────────┐        │
│  │   CameraViewModel      │  │ VideoAnalysisViewModel │        │
│  │   - Orchestrates       │  │   - Manages playback   │        │
│  │   - Error handling     │  │   - Frame processing   │        │
│  └────────┬───────────────┘  └────────┬───────────────┘        │
└───────────┼──────────────────────────┼─────────────────────────┘
            │                          │
            ▼                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Managers                                │
│  ┌────────────────────┐        ┌──────────────────────┐        │
│  │  CameraManager     │        │ PoseDetectionManager │        │
│  │  - AVCaptureSession│◄───────┤ - Vision requests    │        │
│  │  - Device config   │ frames │ - Pose processing    │        │
│  │  - Permissions     │        │ - Metrics tracking   │        │
│  └────────────────────┘        └──────────────────────┘        │
└─────────────────────────────────────────────────────────────────┘
            │                          │
            ▼                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                          Models                                 │
│  ┌──────────────┐  ┌──────────────────┐  ┌──────────────┐     │
│  │  PoseData    │  │PerformanceMetrics│  │  BodyJoint   │     │
│  │  - Joints    │  │  - FPS tracking  │  │  - Position  │     │
│  │  - Timestamp │  │  - Latency       │  │  - Confidence│     │
│  └──────────────┘  └──────────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────────┘
```

## Real-Time Camera Data Flow

```
1. User Opens Camera
        │
        ▼
2. CameraViewModel.setup()
        │
        ├──► Check authorization
        │
        ├──► Configure AVCaptureSession
        │         │
        │         └──► Set preset, format, frame rate
        │
        └──► Connect PoseDetectionManager as delegate
                │
                ▼
3. Session Starts
        │
        ▼
4. Frame Capture Loop
        │
        ├──► AVCaptureSession captures frame (30 FPS)
        │         │
        │         └──► CMSampleBuffer created
        │                   │
        │                   ▼
        ├──► PoseDetectionManager.captureOutput()
        │         │
        │         ├──► Skip if already processing (drop frame)
        │         │
        │         ├──► Create VNImageRequestHandler
        │         │
        │         ├──► Perform VNDetectHumanBodyPoseRequest
        │         │         │
        │         │         └──► Vision framework processes frame
        │         │                   │
        │         │                   └──► Returns VNHumanBodyPoseObservation
        │         │
        │         ├──► Convert to PoseData model
        │         │         │
        │         │         └──► Extract 19 joint positions
        │         │                   │
        │         │                   └──► Filter by confidence (>0.1)
        │         │
        │         └──► Publish to @Published currentPose
        │                   │
        │                   ▼
        ├──► SwiftUI View Updates
        │         │
        │         └──► PoseOverlayView redraws
        │                   │
        │                   ├──► Draw connections (skeleton lines)
        │                   │
        │                   ├──► Draw joints (circles)
        │                   │
        │                   └──► Color by confidence
        │
        └──► Performance metrics updated
                  │
                  └──► FPS, latency, dropped frames calculated
```

## Video Analysis Data Flow

```
1. User Selects Video
        │
        ▼
2. PhotosPicker → Movie.Transferable
        │
        ▼
3. VideoAnalysisViewModel.loadVideo()
        │
        ├──► Create AVAsset from URL
        │
        ├──► Create AVPlayer
        │
        ├──► Create AVAssetImageGenerator
        │
        └──► Setup time observer
                │
                ▼
4. Playback Loop
        │
        ├──► Time observer fires every 0.1s
        │         │
        │         ├──► Update currentTime
        │         │
        │         └──► Check if should process frame
        │                   │
        │                   └──► (at most 15 FPS)
        │                         │
        │                         ▼
        ├──► Process Frame
        │         │
        │         ├──► Generate CGImage at currentTime
        │         │
        │         ├──► Convert to CIImage
        │         │
        │         ├──► PoseDetectionManager.detectPose()
        │         │         │
        │         │         └──► Same Vision processing as real-time
        │         │
        │         └──► Update currentPose
        │                   │
        │                   ▼
        └──► UI Updates
                  │
                  ├──► Video plays
                  │
                  ├──► Skeleton overlay draws
                  │
                  └──► Metrics update
```

## Component Responsibilities

### 📱 Views (SwiftUI)
**Responsibility:** UI presentation only

- Observe ViewModel state
- Render UI components
- Handle user interactions
- No business logic

**Key Views:**
- `MainMenuView` - Navigation hub
- `CameraView` - Camera preview + overlay container
- `VideoAnalysisView` - Video player + controls + overlay
- `PoseOverlayView` - Canvas-based skeleton rendering
- `PerformanceMetricsView` - HUD display

### 🎮 ViewModels
**Responsibility:** State management and coordination

- Coordinate between managers
- Handle user actions
- Manage UI state (@Published properties)
- Error handling and presentation

**Key ViewModels:**
- `CameraViewModel` - Orchestrates camera + pose detection
- `VideoAnalysisViewModel` - Manages video playback + analysis

### ⚙️ Managers
**Responsibility:** Business logic and system integration

- Encapsulate complex operations
- Interact with system frameworks
- No UI knowledge
- Reusable and testable

**Key Managers:**
- `CameraManager` - AVFoundation abstraction
- `PoseDetectionManager` - Vision framework abstraction

### 📦 Models
**Responsibility:** Data structures

- Pure Swift structs/classes
- No dependencies on UI or business logic
- Represent domain concepts

**Key Models:**
- `PoseData` - Complete pose snapshot
- `BodyJoint` - Single joint with position + confidence
- `PerformanceMetrics` - Performance tracking

## Threading Model

```
┌─────────────────────────────────────────────────────────────┐
│                    Main Thread (@MainActor)                 │
│  - SwiftUI views                                            │
│  - ViewModels                                               │
│  - @Published property updates                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│          Camera Session Queue (serial)                      │
│  - AVCaptureSession configuration                           │
│  - Start/stop session                                       │
│  - Add/remove inputs/outputs                                │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│          Video Data Output Queue (concurrent)               │
│  - Receive video frames                                     │
│  - High priority (QoS: .userInitiated)                      │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│          Pose Processing Queue (concurrent)                 │
│  - Vision framework requests                                │
│  - Frame processing                                         │
│  - High priority (QoS: .userInitiated)                      │
└─────────────────────────────────────────────────────────────┘
```

### Thread Safety

**Main Thread Updates:**
```swift
DispatchQueue.main.async {
    self.currentPose = poseData
    self.performanceMetrics.recordFrame()
}
```

**Background Processing:**
```swift
processingQueue.async {
    // Heavy Vision processing
    let result = try handler.perform([request])
    
    // Return to main for UI update
    DispatchQueue.main.async {
        self.currentPose = result
    }
}
```

## State Management with Combine

```
┌─────────────────────────────────────────────────────────────┐
│                    Published Properties                     │
│                                                             │
│  @Published var currentPose: PoseData?                      │
│  @Published var isSessionRunning: Bool                      │
│  @Published var error: Error?                               │
│                                                             │
│  When updated, automatically trigger view refresh           │
└─────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                    SwiftUI View Body                        │
│                                                             │
│  var body: some View {                                      │
│      if let pose = viewModel.currentPose {                  │
│          PoseOverlayView(poseData: pose)                    │
│      }                                                      │
│  }                                                          │
│                                                             │
│  Automatically re-evaluates when currentPose changes        │
└─────────────────────────────────────────────────────────────┘
```

## Error Handling Flow

```
Error Occurs (any layer)
        │
        ▼
Manager catches error
        │
        ├──► Update @Published error property
        │
        └──► Log to console
                │
                ▼
ViewModel observes error
        │
        ├──► Transform to user-friendly message
        │
        └──► Update @Published showError = true
                │
                ▼
View displays alert
        │
        └──► User dismisses or takes action
```

## Performance Optimization Strategy

### Frame Drop Prevention
```
1. Check if processing
     │
     ├──► YES: Drop frame immediately
     │         └──► Increment dropped frame counter
     │
     └──► NO: Process frame
                │
                └──► Set processing flag
```

### Efficient Coordinate Conversion
```
Vision Coordinates         SwiftUI Coordinates
(0,0) at bottom-left  →   (0,0) at top-left
Normalized (0-1)      →   Actual pixels

x' = x * width
y' = (1 - y) * height
```

### Memory Management
```
- Use [weak self] in closures
- Cleanup resources in onDisappear/deinit
- Cancel Combine subscriptions
- Stop capture session when not needed
- Remove time observers
- Release video assets
```

## Adding New Features

### To Add Ball Tracking (Phase 2)

1. **Create Manager:**
```swift
// BallTrackingManager.swift
class BallTrackingManager {
    @Published var detectedBalls: [BallData] = []
    
    func detectBall(in sampleBuffer: CMSampleBuffer) {
        // Ball detection logic
    }
}
```

2. **Update ViewModel:**
```swift
class CameraViewModel {
    let ballTrackingManager = BallTrackingManager()
    
    func setup() async {
        // Connect to camera output
        // Coordinate with pose detection
    }
}
```

3. **Create Overlay View:**
```swift
struct BallOverlayView: View {
    let ballData: BallData
    
    var body: some View {
        // Render ball circle/trajectory
    }
}
```

4. **Integrate in CameraView:**
```swift
ZStack {
    CameraPreviewView()
    PoseOverlayView()    // Existing
    BallOverlayView()    // New
}
```

## Testing Strategy

### Unit Testing (Managers)
```swift
func testPoseDetection() async throws {
    let manager = PoseDetectionManager()
    let testImage = CIImage(/* test image */)
    
    let result = try await manager.detectPose(in: testImage)
    
    XCTAssertNotNil(result)
    XCTAssertTrue(result.joints.count > 0)
}
```

### Integration Testing (ViewModels)
```swift
func testCameraSetup() async {
    let viewModel = CameraViewModel()
    
    await viewModel.setup()
    
    XCTAssertTrue(viewModel.isSetupComplete)
    XCTAssertNil(viewModel.setupError)
}
```

### UI Testing (SwiftUI Previews)
```swift
#Preview {
    let samplePose = PoseData(/* test data */)
    PoseOverlayView(poseData: samplePose)
}
```

## Debugging Tips

### View Hierarchy
```
Use Xcode's Debug View Hierarchy:
1. Run app
2. Debug → View Debugging → Capture View Hierarchy
3. Inspect layer ordering
4. Check frame sizes
```

### Performance Profiling
```
Use Instruments:
1. Product → Profile (⌘I)
2. Choose "Time Profiler" for CPU
3. Choose "Leaks" for memory
4. Choose "System Trace" for threading
```

### Console Logging
```swift
// Add strategic logging
print("📸 Frame captured at \(timestamp)")
print("🤖 Pose detected: \(joints.count) joints")
print("⚡️ FPS: \(metrics.currentFPS)")
```

---

This architecture provides:
- ✅ Clear separation of concerns
- ✅ Testability
- ✅ Maintainability
- ✅ Extensibility for future features
- ✅ Performance optimization
- ✅ Thread safety
