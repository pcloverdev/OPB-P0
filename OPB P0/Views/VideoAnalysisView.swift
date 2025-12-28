//
//  VideoAnalysisView.swift
//  OPB P0
//
//  Created by Patrick Clover on 12/28/25.
//

import SwiftUI
import AVKit
import PhotosUI

/// View for analyzing pre-recorded videos from the photo library
struct VideoAnalysisView: View {
    @StateObject private var viewModel = VideoAnalysisViewModel()
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var showMetrics = true
    
    var body: some View {
        ZStack {
            if let player = viewModel.getPlayer() {
                // Video player with pose overlay
                videoPlayerView(player: player)
            } else {
                // Video picker
                videoPickerView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Done") {
                    dismiss()
                }
            }
            
            if viewModel.getPlayer() != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showMetrics.toggle() }) {
                        Image(systemName: showMetrics ? "gauge.high" : "gauge.low")
                    }
                }
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                await loadVideo(from: newItem)
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
    
    // MARK: - Video Picker View
    
    private var videoPickerView: some View {
        VStack(spacing: 24) {
            Image(systemName: "video.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("Select a Video to Analyze")
                .font(.title2.bold())
            
            Text("Import a video from your photo library to analyze basketball shooting form with pose detection.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            PhotosPicker(
                selection: $selectedItem,
                matching: .videos
            ) {
                Label("Choose Video", systemImage: "photo.on.rectangle")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding()
                    .background(.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
    
    // MARK: - Video Player View
    
    private func videoPlayerView(player: AVPlayer) -> some View {
        ZStack {
            // Video player
            VideoPlayer(player: player)
                .ignoresSafeArea()
            
            // Pose overlay
            if let pose = viewModel.currentPose {
                PoseOverlayView(poseData: pose)
                    .ignoresSafeArea()
            }
            
            // Controls overlay
            VStack {
                Spacer()
                
                // Performance metrics
                if showMetrics {
                    HStack {
                        PerformanceMetricsView(metrics: viewModel.performanceMetrics)
                        Spacer()
                    }
                    .padding()
                }
                
                // Playback controls
                playbackControls
                    .padding()
                    .background(.ultraThinMaterial)
            }
        }
    }
    
    // MARK: - Playback Controls
    
    private var playbackControls: some View {
        VStack(spacing: 12) {
            // Time slider
            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { viewModel.currentTime },
                        set: { viewModel.seek(to: $0) }
                    ),
                    in: 0...max(viewModel.duration, 0.1)
                )
                
                HStack {
                    Text(viewModel.formattedCurrentTime)
                        .font(.caption.monospacedDigit())
                    
                    Spacer()
                    
                    Text(viewModel.formattedDuration)
                        .font(.caption.monospacedDigit())
                }
                .foregroundStyle(.secondary)
            }
            
            // Play/Pause button
            HStack(spacing: 32) {
                Button(action: {
                    viewModel.seek(to: max(0, viewModel.currentTime - 1))
                }) {
                    Image(systemName: "gobackward")
                        .font(.title2)
                }
                
                Button(action: {
                    viewModel.togglePlayback()
                }) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                }
                
                Button(action: {
                    viewModel.seek(to: min(viewModel.duration, viewModel.currentTime + 1))
                }) {
                    Image(systemName: "goforward")
                        .font(.title2)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Video Loading
    
    private func loadVideo(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            // Load the video file
            guard let movie = try await item.loadTransferable(type: Movie.self) else {
                return
            }
            
            // Load video into view model
            await viewModel.loadVideo(from: movie.url)
            
        } catch {
            print("Failed to load video: \(error)")
        }
    }
}

// MARK: - Movie Transferable

struct Movie: Transferable {
    let url: URL
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = URL.documentsDirectory.appending(path: "video-\(UUID().uuidString).mov")
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self(url: copy)
        }
    }
}

#Preview {
    NavigationStack {
        VideoAnalysisView()
    }
}
