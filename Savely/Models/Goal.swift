//
//  Goal.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/10/24.
//

import Foundation
import SwiftUI

struct Goal: Identifiable {
    let id: Int
    let name: String
    let current: Double
    let target: Double
    let color: Color
    
    var progress: Double {
        return current / target
    }
}
