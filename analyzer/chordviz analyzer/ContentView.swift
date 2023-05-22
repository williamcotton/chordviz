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
    @State private var displayImage: Image = Image(systemName: "photo")
    
    var body: some View {
        ZStack {
            CameraView(displayImage: $displayImage)
            VStack {
                displayImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: UIScreen.main.bounds.width * 0.5)
                    .padding(.top, 50)
                Spacer()
            }
        }
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
    @Binding var displayImage: Image

    init(displayImage: Binding<Image>) {
        _displayImage = displayImage
        
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
        Coordinator(self, displayImage: $displayImage)
    }

    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: CameraView
        var displayImage: Binding<Image>

        init(_ parent: CameraView, displayImage: Binding<Image>) {
            self.parent = parent
            self.displayImage = displayImage
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
                let model = parent.trainedModel else {
                return
            }

            let ciImage = CIImage(cvImageBuffer: imageBuffer)
            let context = CIContext()
            let cropRect = CIVector(x: 310, y: 70, z: 330, w: 290) // Define crop rectangle
            var cgImage: CGImage? = nil

            // Apply cropping filter
            if let filter = CIFilter(name: "CICrop") {
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                filter.setValue(cropRect, forKey: "inputRectangle")
                if let outputImage = filter.outputImage {
                    cgImage = context.createCGImage(outputImage, from: outputImage.extent)
                }
            }

            guard let croppedCGImage = cgImage,
                // Resize and convert to grayscale
                let resizedImage = UIImage(cgImage: croppedCGImage).resized(to: CGSize(width: 128, height: 128)),
                let grayscaleImage = resizedImage.grayscale(),
                let grayscaleCgImage = grayscaleImage.cgImage else { return }
            
            // Convert CGImage to UIImage
            let croppedUIImage = UIImage(cgImage: croppedCGImage)

            // Convert UIImage to Image
            let croppedImage = Image(uiImage: croppedUIImage)
            
            // Update the displayImage on the main thread
            DispatchQueue.main.async {
                self.displayImage.wrappedValue = croppedImage
            }

            // Convert to CVPixelBuffer
            let pixelBuffer = self.pixelBuffer(from: grayscaleCgImage)

            let request = VNCoreMLRequest(model: model) { request, error in
                if let error = error {
                    print("Failed to perform request: \(error)")
                    return
                }

                if let results = request.results as? [VNClassificationObservation] {
                    for classification in results {
                        print("\(classification.identifier): \(classification.confidence)")
                    }
                } else {
                    print("No results")
                }
            }

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform image request: \(error)")
            }
        }


        // Convert CGImage to CVPixelBuffer
        private func pixelBuffer(from image: CGImage) -> CVPixelBuffer {
            let attributes: [CFString: Any] = [
                kCVPixelBufferCGImageCompatibilityKey: true as CFBoolean,
                kCVPixelBufferCGBitmapContextCompatibilityKey: true as CFBoolean,
                kCVPixelBufferWidthKey: Int(image.width) as CFNumber,
                kCVPixelBufferHeightKey: Int(image.height) as CFNumber,
                kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32ARGB as CFNumber
            ]

            var pxbuffer: CVPixelBuffer?
            CVPixelBufferCreate(kCFAllocatorDefault, image.width, image.height, kCVPixelFormatType_32ARGB, attributes as CFDictionary, &pxbuffer)
            guard let pixelBuffer = pxbuffer else {
                fatalError("Error creating pixel buffer")
            }

            CVPixelBufferLockBaseAddress(pixelBuffer, [])
            let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
            let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            guard let context = CGContext(data: pixelData,
                                          width: image.width,
                                          height: image.height,
                                          bitsPerComponent: 8,
                                          bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                          space: rgbColorSpace,
                                          bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
            else {
                fatalError("Error creating CGContext")
            }

            context.translateBy(x: 0, y: CGFloat(image.height))
            context.scaleBy(x: 1.0, y: -1.0)
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

            CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

            // Normalize pixel values to [0,1]
            var normalizedPixelBuffer: CVPixelBuffer?
            let pixelFormat = NSNumber(value: kCVPixelFormatType_OneComponent8)
            let options: [NSString: Any] = [
                kCVPixelBufferPixelFormatTypeKey: pixelFormat,
                kCVPixelBufferWidthKey: NSNumber(value: image.width),
                kCVPixelBufferHeightKey: NSNumber(value: image.height),
                kCVPixelBufferCGImageCompatibilityKey: NSNumber(value: true),
                kCVPixelBufferCGBitmapContextCompatibilityKey: NSNumber(value: true)
            ]
            let status = CVPixelBufferCreate(nil, image.width, image.height, kCVPixelFormatType_OneComponent8, options as CFDictionary, &normalizedPixelBuffer)
            guard status == kCVReturnSuccess else {
                fatalError("Unable to create pixel buffer")
            }

            CVPixelBufferLockBaseAddress(normalizedPixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
            let normalizedData = CVPixelBufferGetBaseAddress(normalizedPixelBuffer!)!.assumingMemoryBound(to: UInt8.self)

            let rowCount = CVPixelBufferGetHeight(pixelBuffer)
            let columnCount = CVPixelBufferGetWidth(pixelBuffer)

            for row in 0 ..< rowCount {
                for col in 0 ..< columnCount {
                    let pixelIndex = row * columnCount + col
                    let pixel = normalizedData[pixelIndex]
                    normalizedData[pixelIndex] = UInt8(max(0, min(255, pixel / 255)))
                }
            }

            CVPixelBufferUnlockBaseAddress(normalizedPixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

            return normalizedPixelBuffer ?? pixelBuffer
        }
    }
}
