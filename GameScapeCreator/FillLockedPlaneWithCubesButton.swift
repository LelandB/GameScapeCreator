//
//  FillLockedPlaneWithCubesButton.swift
//  GameScapeCreator
//
//  Created by Leland Bernstein on 8/10/26.
//


import SwiftUI

struct FillLockedPlaneWithCubesButton: View {

    @Environment(AppModel.self) private var appModel

    var body: some View {
        Button {
            Task { @MainActor in
                appModel.fillCurrentPlaneWithCubes()
            }
        } label: {
            Text(appModel.isPlaneLocked == true ? "Put Cubes on Plane" : "No Plane Locked")
        }
        .disabled(appModel.immersiveSpaceState == .inTransition || appModel.immersiveSpaceState == .closed)
        .animation(.none, value: 0)
        .fontWeight(.semibold)
    }
}
