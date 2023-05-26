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

func predict(cgImage: CGImage, model: VNCoreMLModel) -> [Int] {
    guard let grayscaleCgImage = resizeAndGrayscale(cgImage: cgImage, to: CGSize(width: 128, height: 128)) else {
        print("Failed to resize and grayscale image.")
        return []
    }
    
    let pixelBuffer = pixelBuffer(from: grayscaleCgImage)
    
    var outputValues: [Int] = []
    
    let request = VNCoreMLRequest(model: model) { request, error in
        if let error = error {
            print("Failed to perform request: \(error)")
            return
        }

        guard let results = request.results as? [VNCoreMLFeatureValueObservation],
              let firstResult = results.first,
              let multiArray = firstResult.featureValue.multiArrayValue else {
            print("No results found.")
            return
        }

        // Convert the float values to integers and append them to the outputValues array
        for i in 0..<multiArray.count {
            let value = multiArray[i].floatValue
            outputValues.append(Int(round(value)))
        }
    }

    let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
    do {
        try handler.perform([request])
    } catch {
        print("Failed to perform image request: \(error)")
        return []
    }
    
    return outputValues
}


// Convert CGImage to CVPixelBuffer
func pixelBuffer(from image: CGImage) -> CVPixelBuffer {
    let imageWidth = 128
    let imageHeight = 128

    var pixelBuffer : CVPixelBuffer? = nil
    let rgbColorSpace = CGColorSpaceCreateDeviceGray()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
    let context = CGContext(data: nil, width: Int(imageWidth), height: Int(imageHeight), bitsPerComponent: 8, bytesPerRow: imageWidth, space: rgbColorSpace, bitmapInfo: bitmapInfo.rawValue)

    guard let context = context else {
        fatalError("Error: could not create CGBitmapContext")
    }

    context.draw(image, in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))

    guard let newCgImage = context.makeImage() else {
        fatalError("Error: could not create CGImage from CGBitmapContext")
    }

    let status = CVPixelBufferCreate(kCFAllocatorDefault, imageWidth, imageHeight, kCVPixelFormatType_OneComponent8, nil, &pixelBuffer)

    guard status == kCVReturnSuccess else {
        fatalError("Error: could not create new pixel buffer")
    }

    CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
    let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

    let grayColorSpace = CGColorSpaceCreateDeviceGray()
    let newContext = CGContext(data: pixelData, width: Int(imageWidth), height: Int(imageHeight), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: grayColorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue)

    guard let unwrappedContext = newContext else {
        fatalError("Error: could not create CGBitmapContext")
    }

    unwrappedContext.draw(newCgImage, in: CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight))
    
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
