//
//  VideoAnalysisViewModel.swift
//  OPB P0
//
//  Created by Patrick Clover on 12/28/25.
//

import Foundation
import SwiftUI
import AVFoundation
import Combine
import CoreImage

/// ViewModel managing video file analysis
@MainActor
class VideoAnalysisViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var currentPose: PoseData?
    @Published var isProcessing = false
    @Published var error: Error?
    
    // MARK: - Managers
    let poseDetectionManager = PoseDetectionManager()
    
    // MARK: - Video Properties
    private var player: AVPlayer?
    private var playerItemObserver: NSKeyValueObservation?
    private var timeObserver: Any?
    private var asset: AVAsset?
    
    // MARK: - Frame Processing
    private var imageGenerator: AVAssetImageGenerator?
    private var lastProcessedTime: CMTime = .zero
    private let minimumFrameInterval: TimeInterval = 1.0 / 15.0 // Process at most 15 FPS
    
    // MARK: - Computed Properties
    var performanceMetrics: PerformanceMetrics {
        poseDetectionManager.performanceMetrics
    }
    
    var formattedCurrentTime: String {
        formatTime(currentTime)
    }
    
    var formattedDuration: String {
        formatTime(duration)
    }
    
    // MARK: - Video Loading
    
    /// Load a video from a URL
    func loadVideo(from url: URL) async {
        isProcessing = true
        defer { isProcessing = false }
        
        // Create asset
        let asset = AVAsset(url: url)
        self.asset = asset
        
        // Load duration
        do {
            let loadedDuration = try await asset.load(.duration)
            duration = loadedDuration.seconds
        } catch {
            self.error = error
            return
        }
        
        // Create player
        let playerItem = AVPlayerItem(asset: asset)
        let player = AVPlayer(playerItem: playerItem)
        self.player = player
        
        // Setup image generator for frame extraction
        let generator = AVAssetImageGenerator(asset: asset)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        generator.appliesPreferredTrackTransform = true
        self.imageGenerator = generator
        
        // Setup time observer
        setupTimeObserver()
        
        // Reset pose detection
        poseDetectionManager.reset()
    }
    
    private func setupTimeObserver() {
        guard let player = player else { return }
        
        // Update current time every 0.1 seconds
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            
            self.currentTime = time.seconds
            
            // Process frame for pose detection if enough time has passed
            let timeSinceLastProcess = time.seconds - self.lastProcessedTime.seconds
            if timeSinceLastProcess >= self.minimumFrameInterval {
                Task {
                    await self.processCurrentFrame()
                }
            }
        }
    }
    
    // MARK: - Playback Control
    
    /// Toggle play/pause
    func togglePlayback() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        
        isPlaying.toggle()
    }
    
    /// Seek to a specific time
    func seek(to time: Double) {
        guard let player = player else { return }
        
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        
        // Process frame at the new position
        Task {
            await processCurrentFrame()
        }
    }
    
    // MARK: - Frame Processing
    
    private func processCurrentFrame() async {
        guard let imageGenerator = imageGenerator else { return }
        
        let time = CMTime(seconds: currentTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        lastProcessedTime = time
        
        do {
            // Generate image at current time
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let ciImage = CIImage(cgImage: cgImage)
            
            // Detect pose
            let poseData = try await poseDetectionManager.detectPose(in: ciImage, orientation: .up)
            
            currentPose = poseData
            
        } catch {
            // Silently fail for frame processing errors (video might be corrupted at this frame)
            print("Frame processing error: \(error)")
        }
    }
    
    // MARK: - Utility
    
    /// Get the AVPlayer for video rendering
    func getPlayer() -> AVPlayer? {
        return player
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        let milliseconds = Int((seconds.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, remainingSeconds, milliseconds)
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        player?.pause()
        
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        
        playerItemObserver?.invalidate()
        player = nil
        asset = nil
        imageGenerator = nil
        currentPose = nil
        poseDetectionManager.reset()
    }
}
