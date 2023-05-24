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
    var body: some View {
        VStack {
            Image("capo_0_shape_G_frame_00022")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding()
            Button(action: {
                guard let model = self.trainedModel,
                      let image = UIImage(named: "capo_0_shape_G_frame_00022"),
                      let cgImage = image.cgImage else {
                    print("Failed to load the image or the model.")
                    return
                }
                
                predict(cgImage: cgImage, model: model)
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

/*
 python pytorch_model/predict.py image_data/capo_0_shape_G_frame_00022.jpg
 Predicted tablature: [3, 2, 0, 0, 3, 3]
 Predicted inTransition: False
 Predicted capoPosition: 0
 */
