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
    @State private var selectedTab = 0
    @State var trainedModel: VNCoreMLModel?
    @State private var predictedTablature: [Int] = []
    @State private var predictedInTransition: Bool = false
    @State private var predictedCapoPosition: Int = 0

    init() {
        do {
            let configuration = MLModelConfiguration()
            let model = try VNCoreMLModel(for: trained_guitar_tab_net(configuration: configuration).model)
            self._trainedModel = State(initialValue: model)
        } catch {
            print("Failed to load Vision ML model: \(error)")
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            if selectedTab == 0 {
                ZStack {
                    CameraView(
                        trainedModel: self.$trainedModel,
                        displayImage: $displayImage,
                        predictedTablature: $predictedTablature,
                        predictedInTransition: $predictedInTransition,
                        predictedCapoPosition: $predictedCapoPosition
                    )
                    VStack {
                        displayImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: UIScreen.main.bounds.width * 0.5)
                            .padding(.top, 0)
                        Spacer()
                    }
                    VStack(alignment: .leading) {
                        Text("tablature: \(predictedTablature.map { String($0) }.joined(separator: ", "))")
                            .foregroundColor(.green)
                            .font(.title)
                            .bold()
                        Text("inTransition: \(predictedInTransition ? "True" : "False")")
                            .foregroundColor(.green)
                            .font(.title)
                            .bold()
                        Text("capoPosition: \(predictedCapoPosition)")
                            .foregroundColor(.green)
                            .font(.title)
                            .bold()
                    
                    }
                    .background(Color.black.opacity(0.5))
                    .padding(.top, 10)
                }
            } else if selectedTab == 1 {
                PredictView(trainedModel: self.$trainedModel)
            } else if selectedTab == 2 {
                TempView(number: "3")
            } else if selectedTab == 3 {
                TempView(number: "4")
            } else if selectedTab == 4 {
                TempView(number: "5")
            }
            
            HStack {
                ForEach(0..<5) { index in
                    Button(action: {
                        self.selectedTab = index
                    }) {
                        VStack {
                            Image(systemName: "\(index+1).circle")
                            Text("View \(index+1)")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 50)
            .background(Color.white)
        }
    }
}

struct TempView: View {
    var number: String
    var body: some View {
        Text(number)
            .font(.largeTitle)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background(Color.white)
            .edgesIgnoringSafeArea(.all)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
