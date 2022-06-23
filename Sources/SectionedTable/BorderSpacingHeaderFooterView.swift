//
//  BorderSpacingHeaderFooterView.swift
//  Sapo
//
//  Created by Kien Nguyen on 01/06/2022.
//

import Foundation
import UIKit

public class BorderSpacingHeaderFooterView: UITableViewHeaderFooterView {
    
    static let defaultHeight: CGFloat = 16.0
    
    let borderView = BorderView()
    
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        contentView.addSubview(borderView)
        
        borderView.translatesAutoresizingMaskIntoConstraints = false
        borderView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        borderView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        borderView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        borderView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
}

class BorderView: UIView {
    private let topLayer = CALayer()
    private let bottomLayer = CALayer()
    
    var isTopBorderEnabled: Bool = true {
        didSet {
            setNeedsLayout()
        }
    }
    
    var isBottomBorderEnabled: Bool = true {
        didSet {
            setNeedsLayout()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        let color = UIColor(red: 228.0 / 255.0,
                            green: 230.0 / 255.0,
                            blue: 239.0 / 255.0,
                            alpha: 1.0)
            .cgColor
        
        topLayer.backgroundColor = color
        bottomLayer.backgroundColor = color
        
        layer.addSublayer(topLayer)
        layer.addSublayer(bottomLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        topLayer.isHidden = !isTopBorderEnabled
        bottomLayer.isHidden = !isBottomBorderEnabled
        
        topLayer.frame = CGRect(x: 0.0,
                                y: 0.0,
                                width: frame.size.width,
                                height: 1.0)
        bottomLayer.frame = CGRect(x: 0.0,
                                   y: frame.size.height - 1.0,
                                   width: frame.size.width,
                                   height: 1.0)
    }
}
