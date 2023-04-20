//
//  TableSection.swift
//  Sapo
//
//  Created by Kien Nguyen on 01/06/2022.
//

import Foundation
import UIKit

public protocol TableSection: AnyObject {
    var id: AnyHashable { get }
    
    // DataSources
    var numberOfItems: Int { get }
    var reusableViewRegisters: [TableReusableViewRegister] { get }
    func cellForRow(at indexPath: IndexPath, table: UITableView) -> UITableViewCell
    
    func heightForRow(at index: Int) -> TableSpacing
    
    // Editing
    func actionsForRow(at indexPath: IndexPath) -> [UIContextualAction]
    
    // Header & Footer
    func header(for table: UITableView) -> UIView?
    var headerSpacing: TableSpacing { get }
    func footer(for table: UITableView) -> UIView?
    var footerSpacing: TableSpacing { get }
    
    // Actions
    func didSelectRow(at indexPath: IndexPath)
    
    // Miscs
    var isAttached: Bool { get }
    func updateAttached(_ isAttached: Bool, notify: Bool)
    
    var adapter: SectionedTableAdapter? { get set }
}

open class BaseTableSection<T>: TableSection {
    private var internalAttached: Bool = true
    
    public var data: T?
    
    /// Convenience closure called on `didSelectRow(at:)`
    public var itemSelectedAction: ((Int) -> Void)?
    
    public init() {
        
    }
    
    // MARK: - Update data
    
    /// Update new data and reload whole section
    /// - Parameters:
    ///   - data: new data
    ///   - animated: animated
    open func update(data: T, animated: Bool = true) {
        self.data = data
        guard isAttached else { return }
        self.adapter?.reloadSection(id: id, animated: animated)
    }
    
    /// Update new data of section, and only notify a set of indexes
    /// - Parameters:
    ///   - data: new data
    ///   - updatedIndexes: indexes to notify reloaded
    ///   - animated: animated
    open func update(data: T, updatedIndexes: Set<Int>, animated: Bool) {
        self.data = data
        guard isAttached else { return }
        self.adapter?.reloadRows(updatedIndexes,
                                 sectionId: id,
                                 animated: animated)
    }
    
    /// Update new data using `updation` and reload only updated indexes
    /// - Parameters:
    ///   - updation: closure to modify current data
    ///   - updatedIndexes: updated indexes to reload
    ///   - animated: animated
    open func update(using updation: (T) -> T, updatedIndexes: Set<Int>, animated: Bool = true) {
        guard let data = data else {
            return
        }
        
        let newData = updation(data)
        self.data = newData
        
        guard isAttached else { return }
        
        self.adapter?.reloadRows(updatedIndexes,
                                 sectionId: id,
                                 animated: animated)
    }
    
    open func update<E>(item: E, index: Int, animated: Bool = true) where T == [E] {
        update(using: {
            var data = $0
            data[index] = item
            return data
        }, updatedIndexes: [index], animated: animated)
    }
    
    /// Insert new items to section, using `insertion` to modify current data
    /// - Parameters:
    ///   - insertion: closure to modify current data
    ///   - animated: animated
    open func insert(using insertion: (T) -> T, animated: Bool = true) {
        guard let data = data else {
            return
        }
        
        let numberOfItemsBefore = self.numberOfItems
        
        let newData = insertion(data)
        self.data = newData
        
        guard isAttached else { return }
        
        self.adapter?.insertRows(Set(numberOfItemsBefore..<numberOfItems),
                                 sectionId: id,
                                 animated: animated)
    }
    
    open func insert<E>(items: [E], animated: Bool = true) where T == [E] {
        insert(using: {
            var data = $0
            data.append(contentsOf: items)
            return data
        }, animated: animated)
    }
    
    // MARK: - `TableSection` conformances
    
    /// Must be overriden
    open var id: AnyHashable {
        fatalError("Must be overriden")
    }
    
    /// Must be overriden
    open var numberOfItems: Int {
        fatalError("Must be overriden")
    }
    
    open var reusableViewRegisters: [TableReusableViewRegister] {
        var regs = registrations
        regs.append(.headerFooterClass(BorderSpacingHeaderFooterView.self))
        return regs
    }
    
    /// Must be overriden
    open func cellForRow(at indexPath: IndexPath, table: UITableView) -> UITableViewCell {
        fatalError("Must be overriden")
    }
    
    open func heightForRow(at index: Int) -> TableSpacing {
        .auto
    }
    
    open func actionsForRow(at indexPath: IndexPath) -> [UIContextualAction] {
        []
    }
    
    open func header(for table: UITableView) -> UIView? {
        switch headerStyle {
        case .spacing:
            return defaultHeaderFooter(for: table)
        case .none:
            return nil
        }
    }
    
    open var headerSpacing: TableSpacing {
        switch headerStyle {
        case .spacing:
            return .header
        case .none:
            return .invisible
        }
    }
    
    open func footer(for table: UITableView) -> UIView? {
        switch footerStyle {
        case .spacing:
            return defaultHeaderFooter(for: table)
        case .none:
            return nil
        }
    }
    
    open var footerSpacing: TableSpacing {
        switch footerStyle {
        case .spacing:
            return .header
        case .none:
            return .invisible
        }
    }
    
    open func didSelectRow(at indexPath: IndexPath) {
        itemSelectedAction?(indexPath.row)
    }
    
    public var isAttached: Bool {
        get { internalAttached }
        set { updateAttached(newValue, notify: true) }
    }
    
    public func updateAttached(_ isAttached: Bool, notify: Bool) {
        if isAttached == internalAttached {
            return
        }
        
        internalAttached = isAttached
        
        if notify {
            notifyAttachChanged()
        }
    }
    
    weak open var adapter: SectionedTableAdapter?
    
    // MARK: - Convenience overriden methods
    
    /// Must be overriden to register cells or custom header
    open var registrations: [TableReusableRegistration] {
        fatalError("Must be overriden")
    }
    
    /// Override to quickly enable `.spacing` header
    /// If using custom header, directly override `header(for table: UITableView)` instead.
    open var headerStyle: TableHeaderFooterStyle {
        .none
    }
    
    /// Override to quickly enable `.spacing` footer
    /// If using custom header, directly override `footer(for table: UITableView)` instead.
    open var footerStyle: TableHeaderFooterStyle {
        .none
    }
    
    // MARK: - Privates
    
    private func notifyAttachChanged() {
        if isAttached {
            adapter?.notifyAttach(id: id)
        } else {
            adapter?.notifyDetach(id: id)
        }
    }
}

public enum TableHeaderFooterStyle {
    case spacing
    case none
}

extension BaseTableSection {
    public func defaultHeaderFooter(for table: UITableView, top: Bool = true, bottom: Bool = true) -> UIView {
        let view = table.dequeueReusableHeaderFooterView(withIdentifier: BorderSpacingHeaderFooterView.reuseId) as! BorderSpacingHeaderFooterView
        view.borderView.isTopBorderEnabled = top
        view.borderView.isBottomBorderEnabled = bottom
        return view
    }
    
    public func notifyHeightChanged() {
        adapter?.notifyHeightChanged(id: id)
    }
}
