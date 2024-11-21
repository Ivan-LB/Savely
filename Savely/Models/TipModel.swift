//
//  Tip.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/10/24.
//

import Foundation
import SwiftData

@Model
class TipModel: Identifiable {
    @Attribute(.unique) var id: UUID
    var date: Date
    var content: String
    
    init(id: UUID = UUID(), date: Date, content: String) {
        self.id = id
        self.date = date
        self.content = content
    }
}
