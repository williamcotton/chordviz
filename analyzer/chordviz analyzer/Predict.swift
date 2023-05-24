//
//  Predict.swift
//  chordviz analyzer
//
//  Created by William Cotton on 5/24/23.
//

import Foundation
import SwiftUI
import CoreML
import Vision

func predict(cgImage: CGImage, model: VNCoreMLModel) {
//    guard let resizedImage = UIImage(cgImage: cgImage).resized(to: CGSize(width: 128, height: 128)) else {
//        print("Image resizing failed.")
//        return
//    }
//
//    guard let grayscaleImage = resizedImage.grayscale(),
//          let grayscaleCgImage = grayscaleImage.cgImage else {
//        print("Grayscale conversion failed.")
//        return
//    }
    
    guard let grayscaleCgImage = resizeAndGrayscale(cgImage: cgImage, to: CGSize(width: 128, height: 128)) else {
        print("Failed to resize and grayscale image.")
        return
    }
    
    let pixelBuffer = pixelBuffer(from: grayscaleCgImage)
    print("Pixel buffer width: \(CVPixelBufferGetWidth(pixelBuffer)), height: \(CVPixelBufferGetHeight(pixelBuffer))")
    
    // Print the first 10 pixel values
    CVPixelBufferLockBaseAddress(pixelBuffer, [])
    let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
    let buffer = baseAddress!.assumingMemoryBound(to: UInt8.self)
    for i in 0..<10 {
        print(buffer[i])
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

    let request = VNCoreMLRequest(model: model) { request, error in
        if let error = error {
            print("Failed to perform request: \(error)")
            return
        }

        guard let results = request.results else {
            print("No results found.")
            return
        }

        // Print the results
        for result in results {
            print("Result type: \(type(of: result))")
            print("Result: \(result)")
        }

        if let classificationResults = results as? [VNClassificationObservation] {
            for classification in classificationResults {
                print("Classification identifier: \(classification.identifier)")
                print("Classification confidence: \(classification.confidence)")
            }
        }

        if let featureValueResults = results as? [VNCoreMLFeatureValueObservation] {
            for featureValue in featureValueResults {
                print("Feature Value: \(featureValue.featureValue)")
            }
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
func pixelBuffer(from image: CGImage) -> CVPixelBuffer {
    let imageWidth = 128
    let imageHeight = 128

    // Create pixel buffer
    var pixelBuffer: CVPixelBuffer?
    let attributes: [CFString: Any] = [
        kCVPixelBufferCGImageCompatibilityKey: true as CFBoolean,
        kCVPixelBufferCGBitmapContextCompatibilityKey: true as CFBoolean,
        kCVPixelBufferWidthKey: imageWidth as CFNumber,
        kCVPixelBufferHeightKey: imageHeight as CFNumber,
        kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_OneComponent8 as CFNumber
    ]
    let status = CVPixelBufferCreate(kCFAllocatorDefault, imageWidth, imageHeight, kCVPixelFormatType_OneComponent8, attributes as CFDictionary, &pixelBuffer)
    guard status == kCVReturnSuccess else {
        fatalError("Error: could not create pixel buffer")
    }
    
    // Lock the pixel buffer
    CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

    // Prepare for drawing
    let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
    guard let context = CGContext(
        data: pixelData,
        width: imageWidth,
        height: imageHeight,
        bitsPerComponent: 8,
        bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
        space: CGColorSpaceCreateDeviceGray(),
        bitmapInfo: CGImageAlphaInfo.none.rawValue
    ) else {
        fatalError("Error: could not create CGContext")
    }
    
    // Draw the image
    UIGraphicsPushContext(context)
    context.translateBy(x: 0, y: CGFloat(imageHeight))
    context.scaleBy(x: 1, y: -1)
    context.draw(image, in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
    UIGraphicsPopContext()
    
    // Normalize pixel values to [0, 1]
    let pixelBase = CVPixelBufferGetBaseAddress(pixelBuffer!)!.assumingMemoryBound(to: UInt8.self)
    let pixelCount = imageWidth * imageHeight
    for i in 0 ..< pixelCount {
        let pixelValue = Int(pixelBase[i])
        let normalizedPixelValue = Float(pixelValue) / 255.0
        pixelBase[i] = UInt8(normalizedPixelValue * 255.0)
    }
    
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
    
    return pixelBuffer!
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
        guard let output = filter.outputImage else { return nil }
        
        let outputCropped = output.cropped(to: input.extent)
        
        guard let outputCGImage = context.createCGImage(outputCropped, from: outputCropped.extent) else { return nil }
        
        return UIImage(cgImage: outputCGImage)
    }

}

func resizeAndGrayscale(cgImage: CGImage, to size: CGSize) -> CGImage? {
    // Create grayscale color space
    guard let colorSpace = CGColorSpace(name: CGColorSpace.linearGray) else {
        print("Failed to create grayscale color space.")
        return nil
    }

    // Create bitmap graphics context
    guard let context = CGContext(
        data: nil,
        width: Int(size.width),
        height: Int(size.height),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.none.rawValue
    ) else {
        print("Failed to create context.")
        return nil
    }

    // Draw the image into the context
    context.interpolationQuality = .high
    context.draw(cgImage, in: CGRect(origin: .zero, size: size))

    // Extract image from the context
    guard let newImage = context.makeImage() else {
        print("Failed to create image from context.")
        return nil
    }

    return newImage
}
