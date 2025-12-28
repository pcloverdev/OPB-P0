//
//  CameraManager.swift
//  OPB P0
//
//  Created by Patrick Clover on 12/28/25.
//

import AVFoundation
import UIKit
import Combine

/// Manages the camera capture session for real-time video processing
class CameraManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var isSessionRunning = false
    @Published var error: CameraError?
    
    // MARK: - Camera Session Properties
    let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.onepercent.camera.session")
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let videoDataOutput = AVCaptureVideoDataOutput()
    
    // MARK: - Video Output Delegate
    var videoOutputDelegate: AVCaptureVideoDataOutputSampleBufferDelegate? {
        didSet {
            if let delegate = videoOutputDelegate {
                videoDataOutput.setSampleBufferDelegate(delegate, queue: videoDataOutputQueue)
            }
        }
    }
    
    private let videoDataOutputQueue = DispatchQueue(label: "com.onepercent.camera.videooutput", qos: .userInitiated)
    
    // MARK: - Initialization
    override init() {
        super.init()
    }
    
    // MARK: - Authorization
    
    /// Check and request camera authorization
    func checkAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isAuthorized = true
            return true
            
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                isAuthorized = granted
            }
            return granted
            
        case .denied, .restricted:
            await MainActor.run {
                isAuthorized = false
                error = .notAuthorized
            }
            return false
            
        @unknown default:
            return false
        }
    }
    
    // MARK: - Session Configuration
    
    /// Configure the capture session for pose detection
    func configureCaptureSession() async throws {
        guard isAuthorized else {
            throw CameraError.notAuthorized
        }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: CameraError.configurationFailed)
                    return
                }
                
                do {
                    // Begin configuration
                    self.session.beginConfiguration()
                    
                    // Set session preset for high-quality video
                    if self.session.canSetSessionPreset(.high) {
                        self.session.sessionPreset = .high
                    }
                    
                    // Configure video input
                    try self.configureVideoInput()
                    
                    // Configure video output
                    try self.configureVideoOutput()
                    
                    // Commit configuration
                    self.session.commitConfiguration()
                    
                    continuation.resume()
                } catch {
                    self.session.commitConfiguration()
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func configureVideoInput() throws {
        // Remove existing input if any
        if let existingInput = videoDeviceInput {
            session.removeInput(existingInput)
        }
        
        // Get the back camera
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw CameraError.noCameraAvailable
        }
        
        // Configure camera for optimal performance
        do {
            try videoDevice.lockForConfiguration()
            
            // Set frame rate to 30 FPS for balance between performance and quality
            if let format = selectOptimalFormat(for: videoDevice) {
                videoDevice.activeFormat = format
                videoDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 30)
                videoDevice.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 30)
            }
            
            // Enable video stabilization if available
            if videoDevice.activeFormat.isVideoStabilizationModeSupported(.auto) {
                // Note: Stabilization is configured on the connection, not the device
            }
            
            videoDevice.unlockForConfiguration()
        } catch {
            throw CameraError.configurationFailed
        }
        
        // Create and add input
        let videoInput = try AVCaptureDeviceInput(device: videoDevice)
        
        guard session.canAddInput(videoInput) else {
            throw CameraError.configurationFailed
        }
        
        session.addInput(videoInput)
        videoDeviceInput = videoInput
    }
    
    private func configureVideoOutput() throws {
        // Remove existing output if any
        if session.outputs.contains(videoDataOutput) {
            session.removeOutput(videoDataOutput)
        }
        
        // Configure video data output
        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        
        // Discard frames if processing is too slow (important for real-time)
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        guard session.canAddOutput(videoDataOutput) else {
            throw CameraError.configurationFailed
        }
        
        session.addOutput(videoDataOutput)
        
        // Configure video connection for landscape orientation
        if let connection = videoDataOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .landscapeRight
            }
            
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }
        }
    }
    
    private func selectOptimalFormat(for device: AVCaptureDevice) -> AVCaptureDevice.Format? {
        // Find a format that supports 1280x720 at 30fps for good balance
        let formats = device.formats
        
        return formats.first { format in
            let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let ranges = format.videoSupportedFrameRateRanges
            
            return dimensions.width == 1280 &&
                   dimensions.height == 720 &&
                   ranges.contains { $0.maxFrameRate >= 30 }
        } ?? device.activeFormat
    }
    
    // MARK: - Session Control
    
    /// Start the capture session
    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, !self.session.isRunning else { return }
            
            self.session.startRunning()
            
            DispatchQueue.main.async {
                self.isSessionRunning = self.session.isRunning
            }
        }
    }
    
    /// Stop the capture session
    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self = self, self.session.isRunning else { return }
            
            self.session.stopRunning()
            
            DispatchQueue.main.async {
                self.isSessionRunning = false
            }
        }
    }
    
    // MARK: - Utility
    
    /// Get the video preview layer for displaying camera feed
    func previewLayer() -> AVCaptureVideoPreviewLayer {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        return layer
    }
}

// MARK: - Camera Errors

enum CameraError: LocalizedError {
    case notAuthorized
    case configurationFailed
    case noCameraAvailable
    case captureSessionFailure
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Camera access is not authorized. Please enable camera access in Settings."
        case .configurationFailed:
            return "Failed to configure camera session."
        case .noCameraAvailable:
            return "No camera available on this device."
        case .captureSessionFailure:
            return "Camera capture session failed."
        }
    }
}
