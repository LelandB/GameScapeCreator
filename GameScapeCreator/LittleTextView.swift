//
//  LittleTextView.swift
//  GameScapeCreator
//
//  Created by Leland Bernstein on 8/10/26.
//

import SwiftUI
import RealityKit

struct LittleTextView: View {
    private var titleFont: Font {
        .system(size: 48, weight: .semibold)
    }
    
    public var body: some View {
        VStack {
            Spacer()
            VStack(alignment: .center) {
                Text("Lock Plane?")
                    .font(titleFont)
                    .padding(24)
                TogglePlaneLockButton()
                FillLockedPlaneWithCubesButton()
            }
            .frame(width: 600, height: 400)
            .padding(24)
        }
    }
}
