import UIKit
import AVFoundation
import Vision

class LivelinessDetectionViewController: UIViewController {
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var faceDetectionRequest: VNDetectFaceLandmarksRequest!
    private var cameraOutput = AVCapturePhotoOutput()
    private var isBlinkDetected = false
    private var isLeftTurnDetected = false
    private var isRightTurnDetected = false
    private var countdownLabel = UILabel()
    private var loadingIndicator = UIActivityIndicatorView(style: .large)
    private let translucentBox = UIView()
    private let statusLabel = UILabel()
    private var lastEyeState: Bool = false
    private let earThreshold: Float = 0.019
    private var countdownTimer: Timer?
    private var countdownSeconds = 3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
        setupFaceDetection()
    }

    enum LivelinessState {
    case waitingForBlink
    case waitingForLeftTurn
    case waitingForRightTurn
    case countingDown
    case capturingSelfie
    case loading
}
private var currentState: LivelinessState = .waitingForBlink
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("No front camera available")
            return
        }
        do {
            let input = try AVCaptureDeviceInput(device: frontCamera)
            captureSession.addInput(input)
            captureSession.addOutput(cameraOutput)
        } catch {
            print("Error accessing front camera: \(error)")
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer)
        captureSession.startRunning()
    }
    
    private func setupUI() {
        translucentBox.frame = CGRect(x: 20, y: 100, width: view.frame.width - 40, height: 50)
        translucentBox.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        translucentBox.layer.cornerRadius = 10
        view.addSubview(translucentBox)
        
        statusLabel.frame = translucentBox.bounds
        statusLabel.text = "Please place your face in the camera view"
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        translucentBox.addSubview(statusLabel)
        
        countdownLabel.frame = CGRect(x: (view.frame.width - 100) / 2, y: view.center.y - 50, width: 100, height: 100)
        countdownLabel.font = UIFont.boldSystemFont(ofSize: 40)
        countdownLabel.textColor = .white
        countdownLabel.textAlignment = .center
        countdownLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        countdownLabel.layer.cornerRadius = 10
        countdownLabel.isHidden = true
        view.addSubview(countdownLabel)
        
        loadingIndicator.center = view.center
        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)
    }
    
    private func setupFaceDetection() {
        faceDetectionRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let results = request.results as? [VNFaceObservation], let self = self else { return }
            DispatchQueue.main.async {
                self.processFaceObservations(results)
            }
        }
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInteractive))
        captureSession.addOutput(videoOutput)
    }


private func processFaceObservations(_ observations: [VNFaceObservation]) {
    guard let face = observations.first else {
            DispatchQueue.main.async {
                self.statusLabel.text = "Please place your face in the camera view"
                // Reset countdown state if no face is detected
                self.countdownTimer?.invalidate()
                self.countdownTimer = nil
                self.countdownLabel.isHidden = true
            }
            return
        }

    switch currentState {
    case .waitingForBlink:
        DispatchQueue.main.async {
            self.statusLabel.text = "Please Blink Your Eyes"
        }
        detectBlink(face)
    case .waitingForLeftTurn:
        DispatchQueue.main.async {
            self.statusLabel.text = "Please turn your head to the right"
        }
        detectHeadTurn(face, direction: "left")
    case .waitingForRightTurn:
        DispatchQueue.main.async {
            self.statusLabel.text = "Please turn your head to the left"
        }
        detectHeadTurn(face, direction: "right")
    case .countingDown:
     statusLabel.text = "Get ready for the Selfie"
        // Start countdown only if not already started
        if countdownTimer == nil {
            startCountdown()
        }
    case .capturingSelfie, .loading:
        statusLabel.text = "Perfect! Processing..."
        // Do nothing, waiting for the process to complete
        break
    }
}
private func detectBlink(_ face: VNFaceObservation) {
    guard let landmarks = face.landmarks,
          let leftEye = landmarks.leftEye,
          let rightEye = landmarks.rightEye
    else {
        return
    }

    let leftEAR = calculateEyeAspectRatio(eye: leftEye)
    let rightEAR = calculateEyeAspectRatio(eye: rightEye)
    let averageEAR = (leftEAR + rightEAR) / 2.0

    let blinkThreshold: Float = 0.025
    let eyesClosed = averageEAR < blinkThreshold

    if eyesClosed && !lastEyeState {
        currentState = .waitingForLeftTurn
        print("Blink detected! Waiting for left turn.")
    }

    lastEyeState = eyesClosed
}

private func detectHeadTurn(_ face: VNFaceObservation, direction: String) {
    let yaw = face.yaw?.doubleValue ?? 0.0

    if direction == "left" && yaw < -0.3 {
        currentState = .waitingForRightTurn
        print("Left turn detected! Waiting for right turn.")
    } else if direction == "right" && yaw > 0.3 {
        currentState = .countingDown
        print("Right turn detected! Starting countdown.")
    }
}

private func calculateEyeAspectRatio(eye: VNFaceLandmarkRegion2D) -> Float {
    let eyePoints = eye.normalizedPoints

    // Ensure we have enough points to calculate EAR
    guard eyePoints.count >= 6 else { return 0.0 }

    // Extract the required points
    let p1 = eyePoints[0]  // Left corner of the eye
    let p2 = eyePoints[1]  // Top of the eye
    let p3 = eyePoints[2]  // Inner top of the eye
    let p4 = eyePoints[3]  // Right corner of the eye
    let p5 = eyePoints[4]  // Bottom of the eye
    let p6 = eyePoints[5]  // Inner bottom of the eye

    // Calculate distances
    let vertical1 = distanceBetweenPoints(p2, p6)
    let vertical2 = distanceBetweenPoints(p3, p5)
    let horizontal = distanceBetweenPoints(p1, p4)

    // Calculate EAR
    let ear = (vertical1 + vertical2) / (2 * horizontal)
    return Float(ear)
}

private func distanceBetweenPoints(_ p1: CGPoint, _ p2: CGPoint) -> CGFloat {
    return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))
}

private func startCountdown() {
    // Reset countdown state
    countdownSeconds = 3
    countdownLabel.isHidden = false
    countdownLabel.text = "\(countdownSeconds)"
    
    // Invalidate any existing timer
    countdownTimer?.invalidate()
    countdownTimer = nil
    
    // Start new timer
    countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
        guard let self = self else {
            timer.invalidate()
            return
        }
        
        self.countdownSeconds -= 1
        DispatchQueue.main.async {
            self.countdownLabel.text = "\(self.countdownSeconds)"
        }
        
        if self.countdownSeconds <= 0 {
            timer.invalidate()
            self.countdownTimer = nil
            self.countdownLabel.isHidden = true
            self.captureSelfie()
        }
    }
}

private func updateCountdownLabel() {
    DispatchQueue.main.async {
        self.countdownLabel.text = "\(self.countdownSeconds)"
    }
}

private func captureSelfie() {
    currentState = .loading // Add this line
    DispatchQueue.main.async {
        self.loadingIndicator.startAnimating()
    }
    
    let settings = AVCapturePhotoSettings()
    cameraOutput.capturePhoto(with: settings, delegate: self)
    DispatchQueue.main.async {
        self.captureSession.stopRunning()
    }
}
}

extension LivelinessDetectionViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        do {
            try requestHandler.perform([faceDetectionRequest])
        } catch {
            print("Face detection error: \(error)")
        }
    }

func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    if let error = error {
        print("Photo capture error: \(error)")
        return
    }
    guard let imageData = photo.fileDataRepresentation() else { return }
        SharedViewModel.shared.selfieImage = imageData
        loadingIndicator.startAnimating()

        guard let selfieImageData = photo.fileDataRepresentation() else {
        print("Error: Could not get selfie image data")
        return
    }
        
    print("✅ Selfie Image stored successfully!")

    // ✅ Get Cropped Face Image URL
    guard let croppedFaceUrlString = SharedViewModel.shared.ocrResponse?.imageUrl,
          let croppedFaceUrl = URL(string: croppedFaceUrlString) else {
        print("❌ Error: Cropped Face Image URL is missing or invalid")
        return
    }

    // ✅ Download Cropped Face Image
    print("🔄 Downloading Cropped Face Image...")
    let downloadTask = URLSession.shared.dataTask(with: croppedFaceUrl) { (data, response, error) in
        if let error = error {
            print("❌ Error downloading cropped face: \(error)")
            return
        }

        guard let croppedFaceData = data else {
            print("❌ Error: No data received for cropped face")
            return
        }

        print("✅ Cropped Face Image downloaded successfully!")
        SharedViewModel.shared.croppedFaceImageData = croppedFaceData

        // ✅ Call API after downloading image
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.callVerificationAPI()
        }
    }
    downloadTask.resume()

    }

    private func callVerificationAPI() {
    print("🔄 Starting Verification API Call...")

    guard let croppedFaceData = SharedViewModel.shared.croppedFaceImageData,
          let selfieImageData = SharedViewModel.shared.selfieImage,
          let referenceID = SharedViewModel.shared.referenceNumber else {
        print("❌ Missing required data for verification API")
        return
    }
    print(croppedFaceData,"---------------------------")
    print(selfieImageData,"---------------------------")
    print(referenceID,"---------------------------")

    let formData = MultipartFormData()
    formData.addFileData(croppedFaceData, fieldName: "reference_image", fileName: "reference.jpg", mimeType: "image/jpeg")
    formData.addFileData(selfieImageData, fieldName: "candidate_image", fileName: "candidate.jpg", mimeType: "image/jpeg")
    formData.addTextField(referenceID, fieldName: "reference_id")

    // var request = URLRequest(url: URL(string: "https://api-innovitegra.online/innomatcher/verify-images")!)
    var request = URLRequest(url: URL(string: "https://api.innovitegrasuite.online/neuro/verify")!)
    request.httpMethod = "POST"
    request.setValue(formData.contentType, forHTTPHeaderField: "Content-Type")
    request.setValue("testapikey", forHTTPHeaderField: "api-key")
    request.httpBody = formData.build()
    print("api called--------------------------------")
    print(request,"---------------------------")



    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
    DispatchQueue.main.async {
        if let error = error {
            print("❌ Error calling verify-images API: \(error)")
            return
        }

        guard let data = data, let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("❌ Invalid response from verify-images API")
            return
        }
        print(data, "---------------------------")

        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            print("✅ Verification API Response:", jsonObject ?? "No Data")

            // Stop Loading Indicator
            self.loadingIndicator.stopAnimating()
            print(jsonObject, "---------------------------")
            
            // Save Verification Result
            SharedViewModel.shared.verificationResult = jsonObject

            // Dismiss current view before presenting the final screen
                // ✅ Navigate to FinalVerificationViewController
              if let topVC = self.getTopViewController() {
                    let finalVC = FinalVerificationViewController()
                    finalVC.modalPresentationStyle = .fullScreen
                    topVC.present(finalVC, animated: true, completion: {
                        print("✅ Successfully presented FinalVerificationViewController")
                    })
                } else {
                    print("❌ Unable to find the visible view controller to present")
                }
            
        } catch {
            print("❌ Error parsing verify-images response: \(error)")
        }
    }
}
//     let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
//     DispatchQueue.main.async {
//         if let error = error {
//             print("❌ Error calling verify-images API: \(error)")
//             self.loadingIndicator.stopAnimating()
//             return
//         }

//         guard let data = data, 
//               let httpResponse = response as? HTTPURLResponse, 
//               httpResponse.statusCode == 200 else {
//             print("❌ Invalid response from verify-images API")
//             self.loadingIndicator.stopAnimating()
//             return
//         }

//         do {
//             let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
//             SharedViewModel.shared.verificationResult = jsonObject
            
//             // Stop loading indicator first
//             self.loadingIndicator.stopAnimating()
            
//             // Dismiss current controller first
//             self.dismiss(animated: true) {
//                 // Present new controller after dismissal completes
//                 let finalVC = FinalVerificationViewController()
//                 finalVC.modalPresentationStyle = .fullScreen
                
//                 // Get the root view controller
//                 if let rootVC = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController {
//                     rootVC.present(finalVC, animated: true)
//                 } else {
//                     print("❌ Could not find root view controller")
//                 }
//             }
            
//         } catch {
//             print("❌ Error parsing verify-images response: \(error)")
//             self.loadingIndicator.stopAnimating()
//         }
//     }
// }
    task.resume()
}


   
    //  DispatchQueue.main.async {
    //     // self.loadingIndicator.stopAnimating()
    //     // self.currentState = .waitingForBlink
    //     // self.isBlinkDetected = false // Reset these too
    //     // self.isLeftTurnDetected = false
    //     // self.isRightTurnDetected = false
    //     // self.dismiss(animated: true)

    // }

    
    func getTopViewController(_ rootViewController: UIViewController? = UIApplication.shared.connectedScenes
    .compactMap { ($0 as? UIWindowScene)?.keyWindow }
    .first?.rootViewController) -> UIViewController? {

    if let presentedViewController = rootViewController?.presentedViewController {
        return getTopViewController(presentedViewController)
    }
    if let navigationController = rootViewController as? UINavigationController {
        return getTopViewController(navigationController.visibleViewController)
    }
    if let tabBarController = rootViewController as? UITabBarController {
        return getTopViewController(tabBarController.selectedViewController)
    }
    return rootViewController
}



override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    captureSession.stopRunning() // Add this line
}
}
