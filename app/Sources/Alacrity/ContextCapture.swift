import Foundation
import AppKit
import Vision

class ContextCapture {
    static let shared = ContextCapture()
    private var captureTimer: Timer?
    private var captureInterval: TimeInterval = 1.0
    private var lastCaptureTime = Date()
    
    // Keep only the last 5 captures in memory, don't save to disk permanently
    private var recentCaptures: [CaptureData] = []
    private let maxRecentCaptures = 5
    
    private init() {}
    
    struct CaptureData {
        let timestamp: Date
        let image: NSImage
        let extractedText: String
    }
    
    func startCapture(interval: TimeInterval = 1.0) {
        guard captureTimer == nil else { return }
        
        captureInterval = interval
        lastCaptureTime = Date()
        
        captureTimer = Timer.scheduledTimer(withTimeInterval: captureInterval, repeats: true) { [weak self] _ in
            self?.captureScreen()
        }
    }
    
    func stopCapture() {
        captureTimer?.invalidate()
        captureTimer = nil
        clearAllCaptures()
    }
    
    private func captureScreen() {
        let settings = AlacritySettings()
        
        guard settings.captureEnabled else {
            return
        }
        
        let now = Date()
        if now.timeIntervalSince(lastCaptureTime) < captureInterval * 0.8 {
            return
        }
        
        lastCaptureTime = now
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            // Capture based on selected windows or whole screen
            var screenImage: NSImage?
            
            if settings.useWholeScreen {
                if let mainDisplay = NSScreen.main {
                    if let image = CGWindowListCreateImage(
                        mainDisplay.frame,
                        .optionOnScreenOnly,
                        kCGNullWindowID,
                        .bestResolution
                    ) {
                        screenImage = NSImage(cgImage: image, size: mainDisplay.frame.size)
                    }
                }
            } else if !settings.selectedWindowIds.isEmpty {
                // Get images for selected windows
                let windowIds = settings.selectedWindowIds
                var combinedImage: NSImage?
                
                for windowId in windowIds {
                    if let image = CGWindowListCreateImage(
                        .null,
                        .optionIncludingWindow,
                        CGWindowID(windowId),
                        .bestResolution
                    ) {
                        let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
                        
                        if combinedImage == nil {
                            combinedImage = nsImage
                        } else {
                            // For simplicity, we'll just use the most recent window
                            // Advanced implementation could combine images
                            combinedImage = nsImage
                        }
                    }
                }
                
                screenImage = combinedImage
            }
            
            guard let capturedImage = screenImage else { return }
            
            // Process the image (resize, extract text)
            let processedImage = self.resizeImage(capturedImage, maxDimension: 1200)
            self.extractTextFromImage(processedImage) { extractedText in
                // Store in memory only
                let captureData = CaptureData(
                    timestamp: now,
                    image: processedImage,
                    extractedText: extractedText
                )
                self.storeCapture(captureData)
            }
        }
    }
    
    private func storeCapture(_ captureData: CaptureData) {
        // Add to recent captures and maintain limit
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.recentCaptures.append(captureData)
            
            // Keep only the most recent captures
            if self.recentCaptures.count > self.maxRecentCaptures {
                self.recentCaptures.removeFirst(self.recentCaptures.count - self.maxRecentCaptures)
            }
        }
    }
    
    func clearAllCaptures() {
        DispatchQueue.main.async { [weak self] in
            self?.recentCaptures.removeAll()
        }
    }
    
    // Get context for API request
    func getContext() -> String {
        var contextText = ""
        
        // Add text from recent captures
        for capture in recentCaptures {
            let timestamp = formatTimestamp(capture.timestamp)
            contextText += "--- Screen Context at \(timestamp) ---\n"
            contextText += capture.extractedText
            contextText += "\n\n"
        }
        
        // Add text from selected files
        let settings = AlacritySettings()
        for filePath in settings.selectedFilePaths {
            if let fileContents = try? String(contentsOfFile: filePath) {
                contextText += "--- File: \(URL(fileURLWithPath: filePath).lastPathComponent) ---\n"
                contextText += fileContents
                contextText += "\n\n"
            }
        }
        
        return contextText
    }
    
    // MARK: - Helper Functions
    
    private func resizeImage(_ image: NSImage, maxDimension: CGFloat) -> NSImage {
        let originalSize = image.size
        var newSize = originalSize
        
        if originalSize.width > maxDimension || originalSize.height > maxDimension {
            if originalSize.width > originalSize.height {
                newSize.height = originalSize.height * (maxDimension / originalSize.width)
                newSize.width = maxDimension
            } else {
                newSize.width = originalSize.width * (maxDimension / originalSize.height)
                newSize.height = maxDimension
            }
        }
        
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize))
        resizedImage.unlockFocus()
        
        return resizedImage
    }
    
    private func extractTextFromImage(_ image: NSImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            completion("")
            return
        }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest { (request, error) in
            guard error == nil else {
                completion("")
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion("")
                return
            }
            
            let recognizedTexts = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            completion(recognizedTexts.joined(separator: " "))
        }
        
        // Configure for accurate text detection
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        do {
            try requestHandler.perform([request])
        } catch {
            print("Error performing text recognition: \(error)")
            completion("")
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
} 