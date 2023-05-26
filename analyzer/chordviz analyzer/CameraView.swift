//
//  CameraView.swift
//  chordviz analyzer
//
//  Created by William Cotton on 5/24/23.
//

import SwiftUI
import CoreML
import Vision
import AVFoundation
import Foundation

struct CameraView: UIViewControllerRepresentable {
    @Binding var trainedModel: VNCoreMLModel?
    @Binding var displayImage: Image
    @Binding var predictedTablature: [Int]
    @Binding var predictedInTransition: Bool
    @Binding var predictedCapoPosition: Int

    init(trainedModel: Binding<VNCoreMLModel?>,
         displayImage: Binding<Image>,
         predictedTablature: Binding<[Int]>,
         predictedInTransition: Binding<Bool>,
         predictedCapoPosition: Binding<Int>) {
        
        _trainedModel = trainedModel
        _displayImage = displayImage
        _predictedTablature = predictedTablature
        _predictedInTransition = predictedInTransition
        _predictedCapoPosition = predictedCapoPosition
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

        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
        }

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
        Coordinator(self,
                    displayImage: $displayImage,
                    predictedTablature: $predictedTablature,
                    predictedInTransition: $predictedInTransition,
                    predictedCapoPosition: $predictedCapoPosition)
    }

    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: CameraView
        var displayImage: Binding<Image>
        var predictedTablature: Binding<[Int]>
        var predictedInTransition: Binding<Bool>
        var predictedCapoPosition: Binding<Int>

        init(_ parent: CameraView,
             displayImage: Binding<Image>,
             predictedTablature: Binding<[Int]>,
             predictedInTransition: Binding<Bool>,
             predictedCapoPosition: Binding<Int>) {
            self.parent = parent
            self.displayImage = displayImage
            self.predictedTablature = predictedTablature
            self.predictedInTransition = predictedInTransition
            self.predictedCapoPosition = predictedCapoPosition
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
                let model = parent.trainedModel else {
                return
            }

            var ciImage = CIImage(cvImageBuffer: imageBuffer)
            let context = CIContext()
            
            // Resize image
            let targetWidth: CGFloat = 640
            let targetHeight: CGFloat = 360

            // Compute the scale factor
            let scale = min(targetWidth / ciImage.extent.width, targetHeight / ciImage.extent.height)
            
            let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)
            ciImage = ciImage.transformed(by: scaleTransform)
            
            /*
             In Python's OpenCV, the origin (0,0) is at the top-left corner of the image. The x-coordinates increase as you go right and the y-coordinates increase as you go down.

             However, in Swift's Core Image, the origin (0,0) is at the bottom-left corner of the image. The x-coordinates increase as you go right and the y-coordinates increase as you go up.
             */

            // Assuming the original height is available as `originalHeight
            let originalHeight = ciImage.extent.height
            let y_adjusted = originalHeight - 70 - 290

            let cropRect = CGRect(x: 310, y: y_adjusted, width: 330, height: 290)
            ciImage = ciImage.cropped(to: cropRect)

            // Rotate the image after cropping
//            let rotateTransform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
//            ciImage = ciImage.transformed(by: rotateTransform)
            
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
                else { return }
            
            // Convert CGImage to UIImage
            let croppedUIImage = UIImage(cgImage: cgImage)

            // Convert UIImage to Image
            let croppedImage = Image(uiImage: croppedUIImage)
            
            // Update the displayImage on the main thread
            DispatchQueue.main.async {
                self.displayImage.wrappedValue = croppedImage
            }
            
            let (predictedTablature, predictedInTransition, predictedCapoPosition) = predict(cgImage: cgImage, model: model)

            // Update the prediction result state variables on the main thread
            DispatchQueue.main.async {
                self.predictedTablature.wrappedValue = predictedTablature
                self.predictedInTransition.wrappedValue = predictedInTransition
                self.predictedCapoPosition.wrappedValue = predictedCapoPosition
            }
        }
    }
}
