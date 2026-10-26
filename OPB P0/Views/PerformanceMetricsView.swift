//
//  PerformanceMetricsView.swift
//  OPB P0
//
//  Created by Patrick Clover on 12/28/25.
//

import SwiftUI

/// HUD displaying real-time performance metrics
struct PerformanceMetricsView: View {
    @ObservedObject var metrics: PerformanceMetrics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            MetricRow(
                label: "FPS",
                value: String(format: "%.1f", metrics.currentFPS),
                status: fpsStatus(metrics.currentFPS)
            )
            
            MetricRow(
                label: "Avg FPS",
                value: String(format: "%.1f", metrics.averageFPS),
                status: fpsStatus(metrics.averageFPS)
            )
            
            MetricRow(
                label: "Latency",
                value: String(format: "%.1f ms", metrics.processingLatency),
                status: latencyStatus(metrics.processingLatency)
            )
            
            MetricRow(
                label: "Frames",
                value: "\(metrics.totalFramesProcessed)",
                status: .neutral
            )
            
            if metrics.droppedFrames > 0 {
                MetricRow(
                    label: "Dropped",
                    value: "\(metrics.droppedFrames)",
                    status: .warning
                )
            }
        }
        .padding()
        .background(.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func fpsStatus(_ fps: Double) -> MetricStatus {
        switch fps {
        case 25...:
            return .good
        case 15..<25:
            return .warning
        default:
            return .poor
        }
    }
    
    private func latencyStatus(_ latency: Double) -> MetricStatus {
        switch latency {
        case 0..<35:
            return .good
        case 35..<50:
            return .warning
        default:
            return .poor
        }
    }
}

// MARK: - Metric Row Component

struct MetricRow: View {
    let label: String
    let value: String
    let status: MetricStatus
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption.monospacedDigit())
                .foregroundStyle(status.color)
            
            Circle()
                .fill(status.color)
                .frame(width: 6, height: 6)
        }
    }
}

// MARK: - Metric Status

enum MetricStatus {
    case good
    case warning
    case poor
    case neutral
    
    var color: Color {
        switch self {
        case .good:
            return .green
        case .warning:
            return .yellow
        case .poor:
            return .red
        case .neutral:
            return .primary
        }
    }
}

#Preview {
    let metrics = PerformanceMetrics()
    metrics.currentFPS = 29.5
    metrics.averageFPS = 28.3
    metrics.processingLatency = 32.5
    metrics.totalFramesProcessed = 1234
    metrics.droppedFrames = 5
    
    return ZStack {
        Color.black
        VStack {
            Spacer()
            PerformanceMetricsView(metrics: metrics)
                .padding()
        }
    }
}
