//
//  PoseDetectionManager.swift
//  OPB P0
//
//  Created by Patrick Clover on 12/28/25.
//

import Foundation
import Vision
import AVFoundation
import CoreImage
import Combine
import QuartzCore

/// Manages Vision framework pose detection processing
class PoseDetectionManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentPose: PoseData?
    @Published var detectionError: Error?
    
    // MARK: - Performance Tracking
    let performanceMetrics = PerformanceMetrics()
    
    // MARK: - Vision Request
    private let poseRequest: VNDetectHumanBodyPoseRequest
    private let sequenceHandler = VNSequenceRequestHandler()
    
    // MARK: - Processing Queue
    private let processingQueue = DispatchQueue(label: "com.onepercent.posedetection", qos: .userInitiated)
    private var isProcessing = false
    
    // MARK: - Initialization
    
    override init() {
        // Initialize pose detection request
        poseRequest = VNDetectHumanBodyPoseRequest()
        
        // Configure request for real-time performance
        poseRequest.revision = VNDetectHumanBodyPoseRequestRevision1
        
        super.init()
    }
    
    // MARK: - Pose Detection
    
    /// Process a video frame for pose detection
    func detectPose(in sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation = .right) {
        // Skip if already processing (drop frame)
        guard !isProcessing else {
            performanceMetrics.recordDroppedFrame()
            return
        }
        
        isProcessing = true
        let startTime = CACurrentMediaTime()
        
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            defer {
                self.isProcessing = false
            }
            
            do {
                // Perform pose detection
                let results = try self.performPoseDetection(on: sampleBuffer, orientation: orientation)
                
                // Update metrics
                DispatchQueue.main.async {
                    self.performanceMetrics.recordFrame(processingStartTime: startTime)
                    
                    if let poseData = results {
                        self.currentPose = poseData
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.detectionError = error
                    self.performanceMetrics.recordDroppedFrame()
                }
            }
        }
    }
    
    /// Process a CIImage for pose detection (used for video file analysis)
    func detectPose(in image: CIImage, orientation: CGImagePropertyOrientation = .up) async throws -> PoseData? {
        return try await withCheckedThrowingContinuation { continuation in
            processingQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: nil)
                    return
                }
                
                do {
                    let request = VNDetectHumanBodyPoseRequest()
                    request.revision = VNDetectHumanBodyPoseRequestRevision1
                    
                    let handler = VNImageRequestHandler(ciImage: image, orientation: orientation)
                    try handler.perform([request])
                    
                    guard let observation = request.results?.first else {
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    let poseData = self.createPoseData(from: observation, timestamp: CACurrentMediaTime())
                    continuation.resume(returning: poseData)
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func performPoseDetection(on sampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation) throws -> PoseData? {
        // Create image request handler
        let requestHandler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: orientation, options: [:])
        
        // Perform the pose detection request
        try requestHandler.perform([poseRequest])
        
        // Get the first result (should only be one person)
        guard let observation = poseRequest.results?.first else {
            return nil
        }
        
        // Convert Vision observation to our PoseData model
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        return createPoseData(from: observation, timestamp: timestamp)
    }
    
    // MARK: - Data Conversion
    
    private func createPoseData(from observation: VNHumanBodyPoseObservation, timestamp: TimeInterval) -> PoseData {
        var joints: [VNHumanBodyPoseObservation.JointName: BodyJoint] = [:]
        
        // Extract all recognized joints
        let allJoints: [VNHumanBodyPoseObservation.JointName] = [
            // Upper body
            .nose, .leftEye, .rightEye, .leftEar, .rightEar,
            .neck, .root,
            .leftShoulder, .rightShoulder,
            .leftElbow, .rightElbow,
            .leftWrist, .rightWrist,
            
            // Lower body
            .leftHip, .rightHip,
            .leftKnee, .rightKnee,
            .leftAnkle, .rightAnkle
        ]
        
        for jointName in allJoints {
            if let recognizedPoint = try? observation.recognizedPoint(jointName) {
                // Only include points with reasonable confidence
                if recognizedPoint.confidence > 0.1 {
                    let joint = BodyJoint(
                        id: jointName,
                        position: CGPoint(x: recognizedPoint.location.x, y: recognizedPoint.location.y),
                        confidence: recognizedPoint.confidence
                    )
                    joints[jointName] = joint
                }
            }
        }
        
        // Calculate bounding box from detected joints
        let boundingBox = calculateBoundingBox(for: joints)
        
        return PoseData(
            timestamp: timestamp,
            joints: joints,
            boundingBox: boundingBox
        )
    }
    
    /// Calculate a bounding box that encompasses all detected joints
    private func calculateBoundingBox(for joints: [VNHumanBodyPoseObservation.JointName: BodyJoint]) -> CGRect {
        guard !joints.isEmpty else {
            return .zero
        }
        
        let positions = joints.values.map { $0.position }
        
        let minX = positions.map { $0.x }.min() ?? 0
        let maxX = positions.map { $0.x }.max() ?? 0
        let minY = positions.map { $0.y }.min() ?? 0
        let maxY = positions.map { $0.y }.max() ?? 0
        
        // Add some padding (10% on each side)
        let width = maxX - minX
        let height = maxY - minY
        let padding = 0.1
        
        return CGRect(
            x: max(0, minX - width * padding),
            y: max(0, minY - height * padding),
            width: min(1, width * (1 + 2 * padding)),
            height: min(1, height * (1 + 2 * padding))
        )
    }
    
    // MARK: - Utility
    
    /// Reset detection state
    func reset() {
        currentPose = nil
        detectionError = nil
        performanceMetrics.reset()
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension PoseDetectionManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Process the frame for pose detection
        detectPose(in: sampleBuffer, orientation: .right)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Record dropped frame
        performanceMetrics.recordDroppedFrame()
    }
}
