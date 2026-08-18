//
//  LittleTextView.swift
//  GameScapeCreator
//
//  Created by Leland Bernstein on 8/10/26.
//

import SwiftUI
import RealityKit

struct LittleTextView: View {
@Environment(AppModel.self) private var appModel

    private var titleFont: Font {
        .system(size: 48, weight: .semibold)
    }
    
    public var body: some View {
        var planeName = appModel.lastSelectedPlane != nil ? appModel.lastSelectedPlane!.name : "None"
        
        VStack {
            Spacer()
            VStack(alignment: .center) {
                Text("Plane Locked: \(planeName)")
                    .font(titleFont)
                    .padding(24)

                Button {
                    Task { @MainActor in
                        appModel.unlockPlane(planeName: planeName)
                    }
                } label: {
                    Text("Unlock the plane")
                }
                .fontWeight(.semibold)
                .padding(24)

                Button {
                    Task { @MainActor in 
                        appModel.placeVertexCubesOnLockedPlane(planeName: planeName)
                    }
                } label: {
                    Text("Place Vertex Cubes")
                }
                .fontWeight(.semibold)
                .padding(24)
                // TogglePlaneLockButton()
                // FillLockedPlaneWithCubesButton()
            }
            .frame(width: 700, height: 500)
            .padding(24)
        }
    }
}
