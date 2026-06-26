//
//  Item.swift
//  WorkShift
//
//  Created by Papaya on 26.06.2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
