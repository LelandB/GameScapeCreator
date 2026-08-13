//
//  AttachmentsProvider.swift
//  GameScapeCreator
//
//  Created by Leland Bernstein on 8/10/26.
//

import SwiftUI
import Observation

@Observable
final class AttachmentsProvider {
    
    var attachments: [ObjectIdentifier: AnyView] = [:]
    
    var sortedTagViewPairs: [(tag: ObjectIdentifier, view: AnyView)] {
        attachments.map { key, value in
            (tag: key, view: value)
        }.sorted { $0.tag < $1.tag }
    }
}
