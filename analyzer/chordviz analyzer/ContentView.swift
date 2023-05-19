//
//  ContentView.swift
//  chordviz analyzer
//
//  Created by William Cotton on 7/22/22.
//

import SwiftUI
import AVFoundation
import CoreML
import Vision

struct ContentView: View {
    var body: some View {
        Text("Chordviz Analyzer")
            .padding()
        CameraView()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
    
    func grayscale() -> UIImage? {
        let context = CIContext()
        guard let filter = CIFilter(name: "CIPhotoEffectMono"),
              let input = CIImage(image: self) else { return nil }
        filter.setValue(input, forKey: kCIInputImageKey)
        guard let output = filter.outputImage,
              let outputCGImage = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: outputCGImage)
    }
}


struct CameraView: UIViewControllerRepresentable {
    private var trainedModel: VNCoreMLModel?

    init() {
        do {
            let configuration = MLModelConfiguration()
            let model = try VNCoreMLModel(for: trained_guitar_tab_net(configuration: configuration).model)
            self.trainedModel = model
        } catch {
            print("Failed to load Vision ML model: \(error)")
        }
    }

    func makeUIViewController(context: Context) -> some UIViewController {
        let viewController = UIViewController()
        let captureSession = AVCaptureSession()

        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            return viewController
        }
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = viewController.view.frame
        viewController.view.layer.addSublayer(previewLayer)

        captureSession.startRunning()

        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): NSNumber(value: kCVPixelFormatType_32BGRA)]
        dataOutput.alwaysDiscardsLateVideoFrames = true

        if captureSession.canAddOutput(dataOutput) {
            captureSession.addOutput(dataOutput)
        }

        let queue = DispatchQueue(label: "com.capturesession.output.queue")
        dataOutput.setSampleBufferDelegate(context.coordinator, queue: queue)

        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
        } catch {
            print("Failed to create input device: \(error)")
        }

        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // Nothing to do here
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
                  let model = parent.trainedModel else {
                return
            }

            let ciImage = CIImage(cvImageBuffer: imageBuffer)
            let context = CIContext()
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }

            // Resize and convert to grayscale
            guard let resizedImage = UIImage(cgImage: cgImage).resized(to: CGSize(width: 128, height: 128)),
                  let grayscaleImage = resizedImage.grayscale(),
                  let grayscaleCgImage = grayscaleImage.cgImage else { return }

            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    print("Failed to process image: \(error)")
                    return
                }
                if let results = request.results as? [VNCoreMLFeatureValueObservation],
                   let multiArrayResult = results.first?.featureValue.multiArrayValue {
                    
                    var resultsArray = [Float]()
                    let count = multiArrayResult.count
                    for i in 0..<count {
                        resultsArray.append(multiArrayResult[i].floatValue)
                    }

                    let tablature = Array(resultsArray[0...5].map { Int($0) })
                    let inTransition = resultsArray[6] == 1.0 ? true : false
                    let capoPosition = Int(resultsArray[7])

                    DispatchQueue.main.async {
                        print("Predicted tablature: \(tablature)")
                        print("Predicted inTransition: \(inTransition)")
                        print("Predicted capoPosition: \(capoPosition)")
                    }
                }
            }


            let handler = VNImageRequestHandler(cgImage: grayscaleCgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform image request: \(error)")
            }
        }
    }
}
