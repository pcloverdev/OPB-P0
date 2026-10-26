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
    @State private var showMetrics = false
    @State private var showJointAngles = false
    @State private var showControls = true
    @State private var hideControlsTask: Task<Void, Never>?
    
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
                        Image(systemName: showMetrics ? "gauge.with.needle.fill" : "gauge.with.needle")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showJointAngles.toggle() }) {
                        Image(systemName: showJointAngles ? "ruler.fill" : "ruler")
                    }
                }
            }
        }
        .toolbarBackground(showControls ? .visible : .hidden, for: .navigationBar)
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
            
            // Tap to toggle controls
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    toggleControls()
                }
            
            // Controls overlay
            VStack {
                Spacer()
                
                HStack(alignment: .bottom, spacing: 12) {
                    // Performance metrics
                    if showMetrics {
                        PerformanceMetricsView(metrics: viewModel.performanceMetrics)
                    }
                    
                    Spacer()
                    
                    // Joint angles
                    if showJointAngles, let pose = viewModel.currentPose {
                        JointAngleOverlayView(poseData: pose)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                // Playback controls
                if showControls {
                    playbackControls
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.3), value: showControls)
        }
        .onAppear {
            // Auto-hide controls after 3 seconds when video starts playing
            if viewModel.isPlaying {
                scheduleControlsHide()
            }
        }
        .onChange(of: viewModel.isPlaying) { _, isPlaying in
            if isPlaying {
                scheduleControlsHide()
            } else {
                showControls = true
                cancelControlsHide()
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
            
            // Frame-by-frame and playback controls
            HStack(spacing: 20) {
                // Step backward one frame
                Button(action: {
                    viewModel.stepBackward()
                }) {
                    Image(systemName: "backward.frame.fill")
                        .font(.title3)
                }
                .help("Previous frame")
                
                // Skip backward 1 second
                Button(action: {
                    viewModel.seek(to: max(0, viewModel.currentTime - 1))
                }) {
                    Image(systemName: "gobackward")
                        .font(.title2)
                }
                .help("Back 1 second")
                
                // Play/Pause
                Button(action: {
                    viewModel.togglePlayback()
                }) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title)
                        .frame(width: 44, height: 44)
                }
                .help(viewModel.isPlaying ? "Pause" : "Play")
                
                // Skip forward 1 second
                Button(action: {
                    viewModel.seek(to: min(viewModel.duration, viewModel.currentTime + 1))
                }) {
                    Image(systemName: "goforward")
                        .font(.title2)
                }
                .help("Forward 1 second")
                
                // Step forward one frame
                Button(action: {
                    viewModel.stepForward()
                }) {
                    Image(systemName: "forward.frame.fill")
                        .font(.title3)
                }
                .help("Next frame")
            }
            
            // Playback speed control
            HStack(spacing: 12) {
                Image(systemName: "gauge.with.dots.needle.bottom.50percent")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Button(action: { viewModel.setPlaybackSpeed(0.25) }) {
                    speedButton(speed: 0.25)
                }
                
                Button(action: { viewModel.setPlaybackSpeed(0.5) }) {
                    speedButton(speed: 0.5)
                }
                
                Button(action: { viewModel.setPlaybackSpeed(1.0) }) {
                    speedButton(speed: 1.0)
                }
                
                Button(action: { viewModel.setPlaybackSpeed(1.5) }) {
                    speedButton(speed: 1.5)
                }
                
                Button(action: { viewModel.setPlaybackSpeed(2.0) }) {
                    speedButton(speed: 2.0)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Control Visibility
    
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls.toggle()
        }
        
        if showControls && viewModel.isPlaying {
            scheduleControlsHide()
        } else {
            cancelControlsHide()
        }
    }
    
    private func scheduleControlsHide() {
        cancelControlsHide()
        
        hideControlsTask = Task {
            try? await Task.sleep(for: .seconds(3))
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showControls = false
                }
            }
        }
    }
    
    private func cancelControlsHide() {
        hideControlsTask?.cancel()
        hideControlsTask = nil
    }
    
    // MARK: - Speed Button Helper
    
    private func speedButton(speed: Float) -> some View {
        Text(speed == 1.0 ? "1×" : "\(speed, specifier: "%.2g")×")
            .font(.caption.bold())
            .foregroundStyle(viewModel.playbackSpeed == speed ? .white : .primary)
            .frame(width: 40, height: 28)
            .background(viewModel.playbackSpeed == speed ? Color.blue : Color.secondary.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 6))
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
