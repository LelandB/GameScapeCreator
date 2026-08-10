//
//  GameScapeCreatorApp.swift
//  GameScapeCreator
//
//  Created by Leland Bernstein on 8/5/26.
//

import OSLog
import SwiftUI

@main
struct GameScapeCreatorApp: App {
    
    @State private var appModel = AppModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appModel)
        }
        
        ImmersiveSpace(id: appModel.immersiveSpaceID) {
            ImmersiveView()
                .environment(appModel)
                .onAppear {
                    appModel.immersiveSpaceState = .open
                }
                .onDisappear {
                    appModel.immersiveSpaceState = .closed
                }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}

@MainActor
let logger = Logger(subsystem: "name.lelandbern.GameScapeCreator", category: "general")
