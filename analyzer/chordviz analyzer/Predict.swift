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
    guard let resizedImage = UIImage(cgImage: cgImage).resized(to: CGSize(width: 128, height: 128)),
          let grayscaleImage = resizedImage.grayscale(),
          let grayscaleCgImage = grayscaleImage.cgImage else { return }
    
    let pixelBuffer = pixelBuffer(from: grayscaleCgImage)

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
func pixelBuffer(from image: CGImage) -> CVPixelBuffer {
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
