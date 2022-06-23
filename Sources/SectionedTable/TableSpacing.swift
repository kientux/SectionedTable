//
//  TableSpacing.swift
//  Sapo
//
//  Created by Kien Nguyen on 01/06/2022.
//

import Foundation
import UIKit

public struct TableSpacing {
    let value: CGFloat
}

public extension TableSpacing {
    // default value for header/footer
    static let header = TableSpacing(value: 16.0)
    static let footer = TableSpacing(value: 16.0)
    
    // use to hide header/footer
    static let invisible = TableSpacing(value: .leastNormalMagnitude)
    
    // use for automatic cell height
    static let auto = TableSpacing(value: UITableView.automaticDimension)
    
    // custom value
    static func custom(_ value: CGFloat) -> TableSpacing {
        TableSpacing(value: value)
    }
}
