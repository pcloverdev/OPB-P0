//
//  MainMenuView.swift
//  OPB P0
//
//  Created by Patrick Clover on 12/28/25.
//

import SwiftUI

/// Main menu for selecting between real-time camera and video analysis
struct MainMenuView: View {
    @State private var showCamera = false
    @State private var showVideoAnalysis = false
    @State private var showWorkouts = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.orange, .red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    // App branding
                    VStack(spacing: 16) {
                        Image(systemName: "basketball")
                            .font(.system(size: 80))
                            .foregroundStyle(.white)
                        
                        Text("1% Better")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)

                    }
                    .padding(.top, 60)
                    
                    Spacer()
                    
                    // Menu buttons
                    VStack(spacing: 24) {
                        MenuButton(
                            title: "Start a Workout",
                            icon: "figure.basketball",
                            description: "Work on your skills with curated workuts"
                        ) {
                            showWorkouts = true
                        }
                        
                        MenuButton(
                            title: "Real-Time Camera",
                            icon: "video.fill",
                            description: "Live pose detection"
                        ) {
                            showCamera = true
                        }
                        
                        MenuButton(
                            title: "Analyze Video",
                            icon: "film.fill",
                            description: "Import & analyze recordings"
                        ) {
                            showVideoAnalysis = true
                        }
                    }
                    .padding(.horizontal, 32)
    
                    Spacer()
                }
            }
            .navigationDestination(isPresented:
                $showWorkouts) {
                WorkoutsView()
            }
            .navigationDestination(isPresented: $showCamera) {
                CameraView()
            }
            .navigationDestination(isPresented: $showVideoAnalysis) {
                VideoAnalysisView()
            }
        }
    }
}

// MARK: - Menu Button Component

struct MenuButton: View {
    let title: String
    let icon: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .frame(width: 60, height: 60)
                    .background(.white.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.bold())
                    
                    Text(description)
                        .font(.subheadline)
                        .opacity(0.8)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
            .foregroundStyle(.white)
            .padding(20)
            .background(.white.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainMenuView()
}
