//
//  JointAngleOverlayView.swift
//  OPB P0
//
//  Created by Patrick Clover on 12/28/25.
//

import SwiftUI
import Vision

/// Overlay displaying key joint angles for basketball shooting analysis
struct JointAngleOverlayView: View {
    let poseData: PoseData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Joint Angles")
                .font(.headline)
                .foregroundStyle(.white)
            
            // Shooting arm angles (typically right arm for right-handed shooters)
            if let elbowAngle = calculateElbowAngle(side: .right) {
                AngleRow(
                    label: "R Elbow",
                    angle: elbowAngle,
                    idealRange: 85...95,
                    icon: "arm.right"
                )
            }
            
            if let elbowAngle = calculateElbowAngle(side: .left) {
                AngleRow(
                    label: "L Elbow",
                    angle: elbowAngle,
                    idealRange: 85...95,
                    icon: "arm.left"
                )
            }
            
            // Shoulder angles
            if let shoulderAngle = calculateShoulderAngle(side: .right) {
                AngleRow(
                    label: "R Shoulder",
                    angle: shoulderAngle,
                    idealRange: 75...100,
                    icon: "figure.arms.open"
                )
            }
            
            if let shoulderAngle = calculateShoulderAngle(side: .left) {
                AngleRow(
                    label: "L Shoulder",
                    angle: shoulderAngle,
                    idealRange: 75...100,
                    icon: "figure.arms.open"
                )
            }
            
            // Knee angles
            if let kneeAngle = calculateKneeAngle(side: .right) {
                AngleRow(
                    label: "R Knee",
                    angle: kneeAngle,
                    idealRange: 90...135,
                    icon: "figure.stand"
                )
            }
            
            if let kneeAngle = calculateKneeAngle(side: .left) {
                AngleRow(
                    label: "L Knee",
                    angle: kneeAngle,
                    idealRange: 90...135,
                    icon: "figure.stand"
                )
            }
            
            // Hip angles
            if let hipAngle = calculateHipAngle(side: .right) {
                AngleRow(
                    label: "R Hip",
                    angle: hipAngle,
                    idealRange: 160...180,
                    icon: "figure.walk"
                )
            }
            
            if let hipAngle = calculateHipAngle(side: .left) {
                AngleRow(
                    label: "L Hip",
                    angle: hipAngle,
                    idealRange: 160...180,
                    icon: "figure.walk"
                )
            }
            
            // Wrist release angle
            if let wristAngle = calculateWristReleaseAngle(side: .right) {
                AngleRow(
                    label: "R Wrist",
                    angle: wristAngle,
                    idealRange: 0...45,
                    icon: "hand.raised"
                )
            }
        }
        .padding()
        .background(.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Angle Calculations
    
    /// Calculate elbow angle (shoulder-elbow-wrist)
    private func calculateElbowAngle(side: Side) -> Double? {
        let shoulder: VNHumanBodyPoseObservation.JointName
        let elbow: VNHumanBodyPoseObservation.JointName
        let wrist: VNHumanBodyPoseObservation.JointName
        
        switch side {
        case .left:
            shoulder = .leftShoulder
            elbow = .leftElbow
            wrist = .leftWrist
        case .right:
            shoulder = .rightShoulder
            elbow = .rightElbow
            wrist = .rightWrist
        }
        
        guard let shoulderJoint = poseData.joint(shoulder),
              let elbowJoint = poseData.joint(elbow),
              let wristJoint = poseData.joint(wrist),
              shoulderJoint.isReliable && elbowJoint.isReliable && wristJoint.isReliable else {
            return nil
        }
        
        return calculateAngle(
            point1: shoulderJoint.position,
            vertex: elbowJoint.position,
            point2: wristJoint.position
        )
    }
    
    /// Calculate shoulder angle (neck-shoulder-elbow)
    private func calculateShoulderAngle(side: Side) -> Double? {
        let shoulder: VNHumanBodyPoseObservation.JointName
        let elbow: VNHumanBodyPoseObservation.JointName
        
        switch side {
        case .left:
            shoulder = .leftShoulder
            elbow = .leftElbow
        case .right:
            shoulder = .rightShoulder
            elbow = .rightElbow
        }
        
        guard let neckJoint = poseData.joint(.neck),
              let shoulderJoint = poseData.joint(shoulder),
              let elbowJoint = poseData.joint(elbow),
              neckJoint.isReliable && shoulderJoint.isReliable && elbowJoint.isReliable else {
            return nil
        }
        
        return calculateAngle(
            point1: neckJoint.position,
            vertex: shoulderJoint.position,
            point2: elbowJoint.position
        )
    }
    
    /// Calculate knee angle (hip-knee-ankle)
    private func calculateKneeAngle(side: Side) -> Double? {
        let hip: VNHumanBodyPoseObservation.JointName
        let knee: VNHumanBodyPoseObservation.JointName
        let ankle: VNHumanBodyPoseObservation.JointName
        
        switch side {
        case .left:
            hip = .leftHip
            knee = .leftKnee
            ankle = .leftAnkle
        case .right:
            hip = .rightHip
            knee = .rightKnee
            ankle = .rightAnkle
        }
        
        guard let hipJoint = poseData.joint(hip),
              let kneeJoint = poseData.joint(knee),
              let ankleJoint = poseData.joint(ankle),
              hipJoint.isReliable && kneeJoint.isReliable && ankleJoint.isReliable else {
            return nil
        }
        
        return calculateAngle(
            point1: hipJoint.position,
            vertex: kneeJoint.position,
            point2: ankleJoint.position
        )
    }
    
    /// Calculate hip angle (shoulder-hip-knee) to measure body posture
    private func calculateHipAngle(side: Side) -> Double? {
        let shoulder: VNHumanBodyPoseObservation.JointName
        let hip: VNHumanBodyPoseObservation.JointName
        let knee: VNHumanBodyPoseObservation.JointName
        
        switch side {
        case .left:
            shoulder = .leftShoulder
            hip = .leftHip
            knee = .leftKnee
        case .right:
            shoulder = .rightShoulder
            hip = .rightHip
            knee = .rightKnee
        }
        
        guard let shoulderJoint = poseData.joint(shoulder),
              let hipJoint = poseData.joint(hip),
              let kneeJoint = poseData.joint(knee),
              shoulderJoint.isReliable && hipJoint.isReliable && kneeJoint.isReliable else {
            return nil
        }
        
        return calculateAngle(
            point1: shoulderJoint.position,
            vertex: hipJoint.position,
            point2: kneeJoint.position
        )
    }
    
    /// Calculate wrist release angle relative to vertical (elbow-wrist vector)
    private func calculateWristReleaseAngle(side: Side) -> Double? {
        let elbow: VNHumanBodyPoseObservation.JointName
        let wrist: VNHumanBodyPoseObservation.JointName
        
        switch side {
        case .left:
            elbow = .leftElbow
            wrist = .leftWrist
        case .right:
            elbow = .rightElbow
            wrist = .rightWrist
        }
        
        guard let elbowJoint = poseData.joint(elbow),
              let wristJoint = poseData.joint(wrist),
              elbowJoint.isReliable && wristJoint.isReliable else {
            return nil
        }
        
        // Calculate angle from vertical
        let dx = wristJoint.position.x - elbowJoint.position.x
        let dy = wristJoint.position.y - elbowJoint.position.y
        
        let angleRadians = atan2(abs(dx), abs(dy))
        return angleRadians * 180 / Double.pi
    }
    
    /// Calculate angle between three points (vertex is the middle point)
    private func calculateAngle(point1: CGPoint, vertex: CGPoint, point2: CGPoint) -> Double {
        // Vector from vertex to point1
        let v1 = CGVector(dx: point1.x - vertex.x, dy: point1.y - vertex.y)
        
        // Vector from vertex to point2
        let v2 = CGVector(dx: point2.x - vertex.x, dy: point2.y - vertex.y)
        
        // Calculate angle using dot product and magnitudes
        let dotProduct = v1.dx * v2.dx + v1.dy * v2.dy
        let magnitude1 = sqrt(v1.dx * v1.dx + v1.dy * v1.dy)
        let magnitude2 = sqrt(v2.dx * v2.dx + v2.dy * v2.dy)
        
        let cosineAngle = dotProduct / (magnitude1 * magnitude2)
        let angleRadians = acos(max(-1, min(1, cosineAngle))) // Clamp to avoid floating point errors
        
        return angleRadians * 180 / .pi
    }
    
    // MARK: - Supporting Types
    
    enum Side {
        case left
        case right
    }
}

// MARK: - Angle Row Component

struct AngleRow: View {
    let label: String
    let angle: Double
    let idealRange: ClosedRange<Double>
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(minWidth: 70, alignment: .leading)
            
            Spacer()
            
            Text("\(Int(angle))°")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.white)
                .frame(minWidth: 40, alignment: .trailing)
            
            Circle()
                .fill(angleStatus.color)
                .frame(width: 6, height: 6)
        }
    }
    
    private var angleStatus: AngleStatus {
        if idealRange.contains(angle) {
            return .ideal
        } else if (idealRange.lowerBound - 10...idealRange.upperBound + 10).contains(angle) {
            return .acceptable
        } else {
            return .needsWork
        }
    }
}

// MARK: - Angle Status

enum AngleStatus {
    case ideal
    case acceptable
    case needsWork
    
    var color: Color {
        switch self {
        case .ideal:
            return .green
        case .acceptable:
            return .yellow
        case .needsWork:
            return .orange
        }
    }
}

#Preview {
    ZStack {
        Color.black
        
        VStack {
            Spacer()
            HStack {
                // Create sample pose data for preview
                let samplePose = PoseData(
                    timestamp: 0,
                    joints: [
                        .rightShoulder: BodyJoint(id: .rightShoulder, position: CGPoint(x: 0.5, y: 0.3), confidence: 0.9),
                        .rightElbow: BodyJoint(id: .rightElbow, position: CGPoint(x: 0.6, y: 0.5), confidence: 0.9),
                        .rightWrist: BodyJoint(id: .rightWrist, position: CGPoint(x: 0.55, y: 0.7), confidence: 0.9),
                        .rightHip: BodyJoint(id: .rightHip, position: CGPoint(x: 0.5, y: 0.6), confidence: 0.9),
                        .rightKnee: BodyJoint(id: .rightKnee, position: CGPoint(x: 0.5, y: 0.8), confidence: 0.9),
                        .rightAnkle: BodyJoint(id: .rightAnkle, position: CGPoint(x: 0.5, y: 1.0), confidence: 0.9),
                        .neck: BodyJoint(id: .neck, position: CGPoint(x: 0.5, y: 0.2), confidence: 0.9)
                    ],
                    boundingBox: .zero
                )
                
                JointAngleOverlayView(poseData: samplePose)
                
                Spacer()
            }
            .padding()
        }
    }
}
