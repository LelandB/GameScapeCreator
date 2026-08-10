//
//  ImmersiveView.swift
//  GameScapeCreator
//
//  Created by Leland Bernstein on 8/5/26.
//

import SwiftUI
import RealityKit
import RealityKitContent

struct ImmersiveView: View {
    @Environment(AppModel.self) var appModel
    
    // Task for plane recognition via raycasting from headset
    @State private var updateFacingPlaneTask: Task<Void, Never>? = nil
    
    var body: some View {
        RealityView { content in
            do {
                content.add(appModel.setupContentEntity())
                
                // Updates and renders the vertical plane in front of the viewer at 1 Hz
                updateFacingPlaneTask = run(appModel.updateFacingPlane, withFrequency: 1)
            } catch {
                print("Error in creating RealityView")
            }
        } update: { content in
        }
        .onDisappear {
            updateFacingPlaneTask?.cancel()
        }
        .task {
            await appModel.runARKitSession()
        }
        .task {
            await appModel.processPlaneDetectionUpdates()
        }
    }
}

extension ImmersiveView {
    /// Runs a given function at an approximate frequency.
    func run(_ function: @escaping () -> Void, withFrequency freqHz: UInt64) -> Task<Void, Never> {
        return Task {
            while true {
                if Task.isCancelled {
                    return
                }
                
                // Sleeps for 1 s / Hz before calling the function.
                let nanoSecondsToSleep: UInt64 = NSEC_PER_SEC / freqHz
                do {
                    try await Task.sleep(nanoseconds: nanoSecondsToSleep)
                } catch {
                    // Sleep fails when the Task is in a canceled state. Exit the loop.
                    return
                }
                
                function()
            }
        }
    }
}
