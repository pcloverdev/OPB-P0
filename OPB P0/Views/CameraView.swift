//
//  CameraView.swift
//  OPB P0
//
//  Created by Patrick Clover on 12/28/25.
//

import SwiftUI
import AVFoundation

/// Real-time camera view with pose detection overlay
struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showMetrics = true
    
    var body: some View {
        ZStack {
            // Camera preview layer
            CameraPreviewView(session: viewModel.cameraManager.session)
                .ignoresSafeArea()
            
            // Pose overlay
            if let pose = viewModel.currentPose {
                PoseOverlayView(poseData: pose)
                    .ignoresSafeArea()
            }
            
            // UI Overlay
            VStack {
                // Top bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button(action: { showMetrics.toggle() }) {
                        Image(systemName: showMetrics ? "gauge.high" : "gauge.low")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                    }
                    .padding()
                }
                
                Spacer()
                
                // Performance metrics
                if showMetrics {
                    PerformanceMetricsView(metrics: viewModel.performanceMetrics)
                        .padding()
                }
            }
        }
        .navigationBarBackButtonHidden()
        .statusBar(hidden: true)
        .task {
            await viewModel.setup()
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .alert("Camera Error", isPresented: $viewModel.showError) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - Camera Preview View (UIKit Integration)

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        
        view.layer.addSublayer(previewLayer)
        context.coordinator.previewLayer = previewLayer
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update layer frame when view size changes
        DispatchQueue.main.async {
            context.coordinator.previewLayer?.frame = uiView.bounds
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

#Preview {
    CameraView()
}
