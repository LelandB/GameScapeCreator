//
//  TogglePlaneLockButton.swift
//  GameScapeCreator
//
//  Created by Leland Bernstein on 8/10/26.
//


import SwiftUI

struct TogglePlaneLockButton: View {

    @Environment(AppModel.self) private var appModel

    var body: some View {
        Button {
            Task { @MainActor in
                switch appModel.isPlaneLocked {
                    case true:
                        appModel.isPlaneLocked = false

                    case false:
                        appModel.isPlaneLocked = true
                }
            }
        } label: {
            Text(appModel.isPlaneLocked == true ? "Unlock the plane" : "Lock current plane")
        }
        .disabled(appModel.immersiveSpaceState == .inTransition || appModel.immersiveSpaceState == .closed)
        .animation(.none, value: 0)
        .fontWeight(.semibold)
    }
}
