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
    // cell with nib
    case cell(UITableViewCell.Type)
    
    // cell with nib in custom bundle
    case cellInBundle(UITableViewCell.Type, Bundle)
    
    // cell class
    case cellClass(UITableViewCell.Type)
    
    // header/footer with nib
    case headerFooter(UITableViewHeaderFooterView.Type)
    
    // header/footer with nib in custom bundle
    case headerFooterInBundle(UITableViewHeaderFooterView.Type, Bundle)
    
    // header/footer class
    case headerFooterClass(UITableViewHeaderFooterView.Type)
}

extension TableReusableRegistration {
    // global resources bundle for cell/header/footer registration
    public static var resourcesBundle: Bundle = .main
}

extension TableReusableRegistration: TableReusableViewRegister {
    public func register(for table: UITableView) {
        switch self {
        case .cell(let cell):
            table.registerNib(for: cell)
        case .cellInBundle(let cell, let bundle):
            table.registerNib(for: cell, bundle: bundle, reuseId: cell.reuseId)
        case .cellClass(let cell):
            table.registerClass(for: cell)
        case .headerFooter(let view):
            table.registerNib(forHeaderFooter: view)
        case .headerFooterInBundle(let view, let bundle):
            table.registerNib(forHeaderFooter: view, bundle: bundle, reuseId: view.reuseId)
        case .headerFooterClass(let view):
            table.registerClass(forHeaderFooter: view)
        }
    }
}

extension UIView {
    static var reuseId: String {
        return String(describing: self)
    }
    
    static func nib(from bundle: Bundle) -> UINib {
        return UINib(nibName: String(describing: self),
                     bundle: bundle)
    }
}

extension UITableView {
    func registerNib(for cellClass: UITableViewCell.Type) {
        registerNib(for: cellClass,
                    bundle: TableReusableRegistration.resourcesBundle,
                    reuseId: cellClass.reuseId)
    }

    func registerNib(for cellClass: UITableViewCell.Type, bundle: Bundle, reuseId: String) {
        register(cellClass.nib(from: bundle), forCellReuseIdentifier: reuseId)
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
        registerNib(forHeaderFooter: aClass,
                    bundle: TableReusableRegistration.resourcesBundle,
                    reuseId: aClass.reuseId)
    }

    func registerNib(forHeaderFooter aClass: UITableViewHeaderFooterView.Type, bundle: Bundle, reuseId: String) {
        register(aClass.nib(from: bundle), forHeaderFooterViewReuseIdentifier: reuseId)
    }

    func registerNibs<T: UITableViewCell>(for cellClasses: [T.Type]) {
        for cellClass in cellClasses {
            registerNib(for: cellClass)
        }
    }
}
