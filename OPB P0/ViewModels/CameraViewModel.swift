//
//  CameraViewModel.swift
//  OPB P0
//
//  Created by Patrick Clover on 12/28/25.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation

/// ViewModel managing the camera view and pose detection pipeline
@MainActor
class CameraViewModel: ObservableObject {
    
    // MARK: - Managers
    let cameraManager = CameraManager()
    let poseDetectionManager = PoseDetectionManager()
    
    // MARK: - Published Properties
    @Published var isSetupComplete = false
    @Published var setupError: Error?
    @Published var showError = false
    @Published var errorMessage = ""
    
    // MARK: - Computed Properties
    var currentPose: PoseData? {
        poseDetectionManager.currentPose
    }
    
    var performanceMetrics: PerformanceMetrics {
        poseDetectionManager.performanceMetrics
    }
    
    // MARK: - Cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupSubscriptions()
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        // Monitor camera errors
        cameraManager.$error
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.handleError(error)
            }
            .store(in: &cancellables)
        
        // Monitor pose detection errors
        poseDetectionManager.$detectionError
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.handleError(error)
            }
            .store(in: &cancellables)
    }
    
    /// Initialize camera and pose detection
    func setup() async {
        do {
            // Check camera authorization
            let authorized = await cameraManager.checkAuthorization()
            guard authorized else {
                throw CameraError.notAuthorized
            }
            
            // Configure capture session
            try await cameraManager.configureCaptureSession()
            
            // Connect pose detection to camera output
            cameraManager.videoOutputDelegate = poseDetectionManager
            
            // Start the session
            cameraManager.startSession()
            
            isSetupComplete = true
            
        } catch {
            setupError = error
            handleError(error)
        }
    }
    
    // MARK: - Control
    
    /// Start camera and pose detection
    func start() {
        guard isSetupComplete else { return }
        cameraManager.startSession()
        poseDetectionManager.reset()
    }
    
    /// Stop camera and pose detection
    func stop() {
        cameraManager.stopSession()
    }
    
    /// Clean up resources
    func cleanup() {
        stop()
        cancellables.removeAll()
    }
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        if let cameraError = error as? CameraError {
            errorMessage = cameraError.localizedDescription
        } else {
            errorMessage = error.localizedDescription
        }
        showError = true
    }
}
