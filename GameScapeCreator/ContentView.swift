//
//  ContentView.swift
//  GameScapeCreator
//
//  Created by Leland Bernstein on 8/5/26.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    
    var body: some View {
        VStack {
                Text("Click to open Immersive Space and specify game area.")
                
                ToggleImmersiveSpaceButton()
//                TogglePlaneLockButton()
//                FillLockedPlaneWithCubesButton()
        }
        .padding()
    }
}

//#Preview(windowStyle: .automatic) {
//    ContentView()
//}
