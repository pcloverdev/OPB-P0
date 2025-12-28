//
//  PoseOverlayView.swift
//  OPB P0
//
//  Created by Patrick Clover on 12/28/25.
//

import SwiftUI
import Vision

/// Renders the pose skeleton overlay on top of the camera/video feed
struct PoseOverlayView: View {
    let poseData: PoseData
    
    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                // Vision framework uses normalized coordinates (0-1)
                // with origin at bottom-left, we need to convert to SwiftUI coordinates
                
                // Draw connections (skeleton lines)
                for connection in JointConnection.standardConnections {
                    if let fromJoint = poseData.joint(connection.from),
                       let toJoint = poseData.joint(connection.to),
                       fromJoint.isReliable && toJoint.isReliable {
                        
                        let fromPoint = convertPoint(fromJoint.position, in: size)
                        let toPoint = convertPoint(toJoint.position, in: size)
                        
                        // Draw line
                        var path = Path()
                        path.move(to: fromPoint)
                        path.addLine(to: toPoint)
                        
                        // Color based on confidence
                        let avgConfidence = (fromJoint.confidence + toJoint.confidence) / 2
                        let lineColor = colorForConfidence(avgConfidence)
                        
                        context.stroke(
                            path,
                            with: .color(lineColor),
                            lineWidth: 3
                        )
                    }
                }
                
                // Draw joints (circles)
                for (_, joint) in poseData.joints where joint.isReliable {
                    let point = convertPoint(joint.position, in: size)
                    let jointColor = colorForConfidence(joint.confidence)
                    
                    // Draw outer circle (glow effect)
                    context.fill(
                        Circle().path(in: CGRect(
                            x: point.x - 8,
                            y: point.y - 8,
                            width: 16,
                            height: 16
                        )),
                        with: .color(jointColor.opacity(0.3))
                    )
                    
                    // Draw inner circle
                    context.fill(
                        Circle().path(in: CGRect(
                            x: point.x - 5,
                            y: point.y - 5,
                            width: 10,
                            height: 10
                        )),
                        with: .color(jointColor)
                    )
                }
                
                // Highlight critical shooting joints
                drawShootingJointHighlights(context: context, size: size)
            }
        }
    }
    
    /// Convert Vision framework coordinates to SwiftUI coordinates
    private func convertPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        // Vision uses normalized coordinates with origin at bottom-left
        // SwiftUI uses actual coordinates with origin at top-left
        return CGPoint(
            x: point.x * size.width,
            y: (1 - point.y) * size.height
        )
    }
    
    /// Get color based on detection confidence
    private func colorForConfidence(_ confidence: Float) -> Color {
        switch confidence {
        case 0.8...1.0:
            return .green
        case 0.5..<0.8:
            return .yellow
        default:
            return .red
        }
    }
    
    /// Draw special highlights for key shooting joints
    private func drawShootingJointHighlights(context: GraphicsContext, size: CGSize) {
        let keyJoints: [VNHumanBodyPoseObservation.JointName] = [
            .leftWrist, .rightWrist,
            .leftElbow, .rightElbow,
            .leftShoulder, .rightShoulder
        ]
        
        for jointName in keyJoints {
            if let joint = poseData.joint(jointName), joint.isReliable {
                let point = convertPoint(joint.position, in: size)
                
                // Draw subtle ring around key joints
                let ringPath = Circle().path(in: CGRect(
                    x: point.x - 12,
                    y: point.y - 12,
                    width: 24,
                    height: 24
                ))
                
                context.stroke(
                    ringPath,
                    with: .color(.cyan.opacity(0.4)),
                    lineWidth: 2
                )
            }
        }
    }
}

#Preview {
    // Create sample pose data for preview
    let sampleJoints: [VNHumanBodyPoseObservation.JointName: BodyJoint] = [
        .neck: BodyJoint(id: .neck, position: CGPoint(x: 0.5, y: 0.7), confidence: 0.9),
        .leftShoulder: BodyJoint(id: .leftShoulder, position: CGPoint(x: 0.4, y: 0.65), confidence: 0.9),
        .rightShoulder: BodyJoint(id: .rightShoulder, position: CGPoint(x: 0.6, y: 0.65), confidence: 0.9),
        .leftElbow: BodyJoint(id: .leftElbow, position: CGPoint(x: 0.35, y: 0.5), confidence: 0.85),
        .rightElbow: BodyJoint(id: .rightElbow, position: CGPoint(x: 0.65, y: 0.5), confidence: 0.85),
        .leftWrist: BodyJoint(id: .leftWrist, position: CGPoint(x: 0.3, y: 0.4), confidence: 0.8),
        .rightWrist: BodyJoint(id: .rightWrist, position: CGPoint(x: 0.7, y: 0.4), confidence: 0.8),
    ]
    
    let samplePose = PoseData(
        timestamp: 0,
        joints: sampleJoints,
        boundingBox: CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
    )
    
    ZStack {
        Color.black
        PoseOverlayView(poseData: samplePose)
    }
}
