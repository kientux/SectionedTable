//
//  TableReusableViewRegister.swift
//  Sapo
//
//  Created by Kien Nguyen on 01/06/2022.
//

import Foundation
import UIKit

public protocol TableReusableViewRegister {
    func register(for table: UITableView)
}

public enum TableReusableRegistration {
    case cell(UITableViewCell.Type)
    case cellClass(UITableViewCell.Type)
    
    case headerFooter(UITableViewHeaderFooterView.Type)
    case headerFooterClass(UITableViewHeaderFooterView.Type)
}

extension TableReusableRegistration: TableReusableViewRegister {
    public func register(for table: UITableView) {
        switch self {
        case .cell(let cell):
            table.registerNib(for: cell)
        case .cellClass(let cell):
            table.registerClass(for: cell)
        case .headerFooter(let view):
            table.registerNib(forHeaderFooter: view)
        case .headerFooterClass(let view):
            table.registerClass(forHeaderFooter: view)
        }
    }
}

extension UIView {
    static var reuseId: String {
        return String(describing: self)
    }
    
    static var nib: UINib {
        return UINib(nibName: String(describing: self),
                     bundle: .main)
    }
}

extension UITableView {
    func registerNib(for cellClass: UITableViewCell.Type) {
        registerNib(for: cellClass, reuseId: cellClass.reuseId)
    }

    func registerNib(for cellClass: UITableViewCell.Type, reuseId: String) {
        register(cellClass.nib, forCellReuseIdentifier: reuseId)
    }

    func registerClass(for cellClass: UITableViewCell.Type) {
        registerClass(for: cellClass, reuseId: cellClass.reuseId)
    }

    func registerClass(for cellClass: UITableViewCell.Type, reuseId: String) {
        register(cellClass, forCellReuseIdentifier: reuseId)
    }
    
    func registerClass(forHeaderFooter aClass: UITableViewHeaderFooterView.Type) {
        registerClass(forHeaderFooter: aClass, reuseId: aClass.reuseId)
    }

    func registerClass(forHeaderFooter aClass: UITableViewHeaderFooterView.Type, reuseId: String) {
        register(aClass, forHeaderFooterViewReuseIdentifier: reuseId)
    }
    
    func registerNib(forHeaderFooter aClass: UITableViewHeaderFooterView.Type) {
        registerNib(forHeaderFooter: aClass, reuseId: aClass.reuseId)
    }

    func registerNib(forHeaderFooter aClass: UITableViewHeaderFooterView.Type, reuseId: String) {
        register(UINib(nibName: String(describing: aClass), bundle: nil),
                 forHeaderFooterViewReuseIdentifier: reuseId)
    }

    func registerNibs<T: UITableViewCell>(for cellClasses: [T.Type]) {
        for cellClass in cellClasses {
            registerNib(for: cellClass)
        }
    }
}
