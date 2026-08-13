//
//  ImmersiveView.swift
//  GameScapeCreator
//
//  Created by Leland Bernstein on 8/5/26.
//

import SwiftUI
import RealityKit
import RealityKitContent
import UIKit

struct ImmersiveView: View {
    @Environment(AppModel.self) var appModel
    
    // Task for plane recognition via raycasting from headset
    @State private var updateFacingPlaneTask: Task<Void, Never>? = nil
    
    // SwiftUI Views recompute when updating a state variable
    @State private var hWorldAttachment: ViewAttachmentEntity?
    @State private var showHelloWorldAttachment: Bool = false
    
    private let whiteMaterial = SimpleMaterial(color: .white, roughness: 0.5, isMetallic: false)
    private let blueMaterial = SimpleMaterial(color: .blue, roughness: 0.5, isMetallic: false)

    
    private var pinchGesture: some Gesture {
        return DragGesture()
            .targetedToAnyEntity()
            .handActivationBehavior(.pinch)
            .onEnded { event in
                // appModel.hasBeenPinched = !appModel.hasBeenPinched
                // showHelloWorldAttachment = !showHelloWorldAttachment

                let eventEntity = event.entity
                let name = eventEntity.name

                if name.contains("plane") {
                    appModel.toggleRenderPlaneLock(string: name)
                }
            } // Registers at the end of a drag - seems to not be called on just a pinch action!
    }
    
    var body: some View {
        RealityView { content, attachments in
            do {
                content.add(appModel.setupContentEntity())
                
                if let helloWorldAttachment = attachments.entity(for: "HelloWorld") {
                    helloWorldAttachment.position = SIMD3<Float>(0.0, 1.2, 0.0)
                    helloWorldAttachment.name = "Checking"
                    helloWorldAttachment.isEnabled = false
                    content.add(helloWorldAttachment)
                    hWorldAttachment = helloWorldAttachment
                }
                
                // Updates and renders the vertical plane in front of the viewer at 1 Hz
                updateFacingPlaneTask = run(appModel.updateFacingPlane, withFrequency: 1)
            } catch {
                print("Error in creating RealityView")
            }
        } update: { content, attachments in
            // enable and disable helloWorldAttachment
                if showHelloWorldAttachment == true {
                    if let hWorldUnpacked = hWorldAttachment {
                        // sets position and rotation of the attachment to match the headset's
                        if let planePositionHeadsetRotation = appModel.providePlaneCentroidPosition() {
                            var adjustedPosition = planePositionHeadsetRotation.position
                            adjustedPosition.y += 0.6
                            
                            // Extract only the Y-axis rotation
                            let fullRotation = planePositionHeadsetRotation.rotation
                            let yRotation = simd_quatf(angle: fullRotation.angle, axis: SIMD3<Float>(0, 1, 0))
                            
                            // Assign the position and rotation
//                            hWorldUnpacked.position = headSetPositionAndRotation.position
//                            hWorldUnpacked.orientation = headSetPositionAndRotation.rotation
                            hWorldUnpacked.position = adjustedPosition
                            hWorldUnpacked.orientation = yRotation

                            hWorldUnpacked.isEnabled = true
                        } else {
                            print("Failed to get headset position and rotation.")
                        }
                        hWorldUnpacked.isEnabled = true
                    } else {
                        print("No View Attachment Entity found")
                        return
                    }
                } else {
                    if let hWorldUnpacked = hWorldAttachment {
                        hWorldUnpacked.isEnabled = false
                    }
                }
        } attachments: {
            Attachment(id: "HelloWorld") {
                LittleTextView()
                    .frame(width: 600, height: 400)
                    .glassBackgroundEffect()
            }
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
        .gesture(pinchGesture)
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
