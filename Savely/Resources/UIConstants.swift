//
//  UIConstants.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/10/24.
//

import Foundation
import SwiftUI

struct UIConstants {
    enum UICornerRadius {
        static let cornerRadius = 5.0
        static let cornerRadiusMedium = 10.0
    }
    
    enum UILineWidth {
        static let lineWidth = 1.0
    }
    
    enum UIFont {
        static let extraLargeTitle = Font.custom("Roboto", size: 36)
        static let largeTitle = Font.custom("Roboto", size: 24)
        static let regularTitle = Font.custom("Roboto", size: 20)
        static let smallTitle = Font.custom("Roboto", size: 18)
        
        static let largeBody = Font.custom("Roboto", size: 16)
        static let mediumBody = Font.custom("Roboto", size: 15)
        static let regularBody = Font.custom("Roboto", size: 14)
        static let smallBody = Font.custom("Roboto", size: 12)
    }
    
    enum UIPadding {
        
    }
}
