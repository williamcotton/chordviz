//
//  PredictView.swift
//  chordviz analyzer
//
//  Created by William Cotton on 5/24/23.
//

import Foundation
import SwiftUI
import CoreML
import Vision

struct PredictView: View {
    @Binding var trainedModel: VNCoreMLModel?
    
    // State variables for the prediction results
    @State private var predictedTablature: [Int] = []
    @State private var predictedInTransition: Bool = false
    @State private var predictedCapoPosition: Int = 0

    var body: some View {
        VStack {
            Image("capo_0_shape_G_frame_00022")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
            
            Text("Predicted tablature: \(predictedTablature.map { String($0) }.joined(separator: ", "))")
            Text("Predicted inTransition: \(predictedInTransition ? "True" : "False")")
            Text("Predicted capoPosition: \(predictedCapoPosition)")
            
            Button(action: {
                guard let model = self.trainedModel,
                      let image = UIImage(named: "capo_0_shape_G_frame_00022"),
                      let cgImage = image.cgImage else {
                    print("Failed to load the image or the model.")
                    return
                }
                
                let (predictedTablature, predictedInTransition, predictedCapoPosition) = predict(cgImage: cgImage, model: model)
                
                // Update the prediction result state variables
                self.predictedTablature = predictedTablature
                self.predictedInTransition = predictedInTransition
                self.predictedCapoPosition = predictedCapoPosition
            }) {
                Text("Predict")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
}
