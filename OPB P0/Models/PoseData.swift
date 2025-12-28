//
//  PoseData.swift
//  OPB P0
//
//  Created by Patrick Clover on 12/28/25.
//

import Foundation
import Vision
import CoreGraphics

/// Represents a single body joint with its position and confidence
struct BodyJoint: Identifiable {
    let id: VNHumanBodyPoseObservation.JointName
    let position: CGPoint
    let confidence: Float
    
    var isReliable: Bool {
        confidence > 0.5
    }
}

/// Represents a connection between two joints for skeleton visualization
struct JointConnection: Identifiable {
    let id = UUID()
    let from: VNHumanBodyPoseObservation.JointName
    let to: VNHumanBodyPoseObservation.JointName
    
    /// Standard skeleton connections for visualization
    static let standardConnections: [JointConnection] = [
        // Torso
        JointConnection(from: .neck, to: .root),
        
        // Left arm
        JointConnection(from: .neck, to: .leftShoulder),
        JointConnection(from: .leftShoulder, to: .leftElbow),
        JointConnection(from: .leftElbow, to: .leftWrist),
        
        // Right arm
        JointConnection(from: .neck, to: .rightShoulder),
        JointConnection(from: .rightShoulder, to: .rightElbow),
        JointConnection(from: .rightElbow, to: .rightWrist),
        
        // Left leg
        JointConnection(from: .root, to: .leftHip),
        JointConnection(from: .leftHip, to: .leftKnee),
        JointConnection(from: .leftKnee, to: .leftAnkle),
        
        // Right leg
        JointConnection(from: .root, to: .rightHip),
        JointConnection(from: .rightHip, to: .rightKnee),
        JointConnection(from: .rightKnee, to: .rightAnkle)
    ]
}

/// Complete pose data for a single frame
struct PoseData: Identifiable {
    let id = UUID()
    let timestamp: TimeInterval
    let joints: [VNHumanBodyPoseObservation.JointName: BodyJoint]
    let boundingBox: CGRect
    
    /// Key joints for basketball shooting analysis
    var shootingJoints: [VNHumanBodyPoseObservation.JointName] {
        [
            .leftWrist, .rightWrist,
            .leftElbow, .rightElbow,
            .leftShoulder, .rightShoulder,
            .leftHip, .rightHip,
            .leftKnee, .rightKnee,
            .leftAnkle, .rightAnkle
        ]
    }
    
    /// Returns a specific joint if available and reliable
    func joint(_ name: VNHumanBodyPoseObservation.JointName) -> BodyJoint? {
        joints[name]
    }
    
    /// Check if all critical shooting joints are detected
    var hasValidShootingPose: Bool {
        let criticalJoints: [VNHumanBodyPoseObservation.JointName] = [
            .leftWrist, .rightWrist,
            .leftElbow, .rightElbow,
            .leftShoulder, .rightShoulder
        ]
        
        return criticalJoints.allSatisfy { jointName in
            guard let joint = joints[jointName] else { return false }
            return joint.isReliable
        }
    }
}

/// Enumeration of basketball-specific pose states (for future use)
enum ShootingPhase {
    case idle
    case preparation
    case loading
    case release
    case followThrough
    case recovery
}
