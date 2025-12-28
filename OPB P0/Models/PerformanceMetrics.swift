//
//  PerformanceMetrics.swift
//  OPB P0
//
//  Created by Patrick Clover on 12/28/25.
//

import Foundation
import Combine
import QuartzCore

/// Tracks performance metrics for pose detection system
class PerformanceMetrics: ObservableObject {
    @Published var currentFPS: Double = 0
    @Published var averageFPS: Double = 0
    @Published var processingLatency: Double = 0 // milliseconds
    @Published var droppedFrames: Int = 0
    @Published var totalFramesProcessed: Int = 0
    
    private var frameTimes: [TimeInterval] = []
    private var latencyMeasurements: [Double] = []
    private let maxStoredMeasurements = 60 // Store last 60 measurements for averaging
    
    private var lastFrameTime: TimeInterval?
    
    /// Record a new frame completion
    func recordFrame(processingStartTime: TimeInterval) {
        let now = CACurrentMediaTime()
        let processingTime = (now - processingStartTime) * 1000 // Convert to ms
        
        // Update processing latency
        latencyMeasurements.append(processingTime)
        if latencyMeasurements.count > maxStoredMeasurements {
            latencyMeasurements.removeFirst()
        }
        processingLatency = latencyMeasurements.reduce(0, +) / Double(latencyMeasurements.count)
        
        // Update FPS
        if let lastTime = lastFrameTime {
            let frameTime = now - lastTime
            frameTimes.append(frameTime)
            
            if frameTimes.count > maxStoredMeasurements {
                frameTimes.removeFirst()
            }
            
            // Calculate current FPS from last frame time
            currentFPS = 1.0 / frameTime
            
            // Calculate average FPS
            let averageFrameTime = frameTimes.reduce(0, +) / Double(frameTimes.count)
            averageFPS = 1.0 / averageFrameTime
        }
        
        lastFrameTime = now
        totalFramesProcessed += 1
    }
    
    /// Record a dropped frame
    func recordDroppedFrame() {
        droppedFrames += 1
    }
    
    /// Reset all metrics
    func reset() {
        currentFPS = 0
        averageFPS = 0
        processingLatency = 0
        droppedFrames = 0
        totalFramesProcessed = 0
        frameTimes.removeAll()
        latencyMeasurements.removeAll()
        lastFrameTime = nil
    }
    
    /// Get a formatted summary of current metrics
    var summary: String {
        """
        FPS: \(String(format: "%.1f", currentFPS)) (avg: \(String(format: "%.1f", averageFPS)))
        Latency: \(String(format: "%.1f", processingLatency))ms
        Frames: \(totalFramesProcessed) (dropped: \(droppedFrames))
        """
    }
}
