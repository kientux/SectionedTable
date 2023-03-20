//
//  SectionedTableAdapter.swift
//  Sapo
//
//  Created by Kien Nguyen on 21/05/2022.
//

import Foundation
import UIKit

public class SectionedTableAdapter: NSObject {
    
    private var sections: ContiguousArray<TableSection> = [] {
        didSet {
            attachedSections = sections.filter({ $0.isAttached })
        }
    }
    private var attachedSections: ContiguousArray<TableSection> = []
    private var cachedRowHeights: [IndexPath: CGFloat] = [:]
    
    public let tableView: UITableView
    public weak var forwaredDelegate: UITableViewDelegate?
    
    public init(tableView: UITableView) {
        self.tableView = tableView
        
        super.init()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        // some common setups
        self.tableView.estimatedRowHeight = 100
    }
    
    public func addSection(_ section: TableSection) {
        if let existed = sections.first(where: { $0.id == section.id }) {
            fatalError("Id \(section.id) already exists for section \(String(describing: type(of: existed)))")
        }
        
        section.adapter = self
        registerCells(for: section)
        sections.append(section)
        
        if !section.isAttached {
            return
        }
        
        /// Check to fix `UITableViewAlertForLayoutOutsideViewHierarchy` warning
        /// This warning is shown when addSection get called in viewDidLoad,
        /// right after tableView is added into view hierachy and not yet visible.
        /// Later when tableView is added to window and visible, it will automatically reload itself.
        if tableView.window == nil {
            return
        }
        
        if attachedSections.count <= 1 {
            tableView.reloadData()
        } else {
            tableView.insertSections(IndexSet(integer: attachedSections.count - 1),
                                     with: .none)
        }
    }
    
    public func addSectionIfNotExist(_ section: TableSection) -> Bool {
        if sections.contains(where: { $0.id == section.id }) {
            return false
        }
        
        addSection(section)
        return true
    }
    
    public func reloadSection(id: AnyHashable, animated: Bool = true) {
        if let index = attachedSections.firstIndex(where: { $0.id == id }) {
            tableView.reloadSections(IndexSet(integer: index),
                                     with: animated ? .automatic : .none)
        }
    }
    
    public func reloadRows(_ rows: Set<Int>, sectionId: AnyHashable, animated: Bool = true) {
        if let index = attachedSections.firstIndex(where: { $0.id == sectionId }) {
            tableView.reloadRows(at: rows.map({ IndexPath(row: $0, section: index) }),
                                 with: animated ? .automatic : .none)
        }
    }
    
    public func insertRows(_ rows: Set<Int>, sectionId: AnyHashable, animated: Bool = true) {
        if let index = attachedSections.firstIndex(where: { $0.id == sectionId }) {
            tableView.insertRows(at: rows.map({ IndexPath(row: $0, section: index) }),
                                 with: animated ? .automatic : .none)
        }
    }
    
    public func index(of section: TableSection) -> Int? {
        attachedSections.firstIndex(where: { $0.id == section.id })
    }
    
    /// If a single section is attached/detached, it's not really a batch update,
    /// but when multiple sections are attached/detached simultaneously
    /// then it can causes `tableView.numberOfSections` to be different from
    /// dataSource's `numberOfSections(in:)` and cause index-out-of-bound
    /// (as stated in Apple docs, `tableView.numberOfSections` is internally cached, that's maybe the reason).
    /// So we always perform a batch update here to avoid the crash.
    public func notifyAttach(id: AnyHashable) {
        attachedSections = sections.filter({ $0.isAttached })
        
        if let index = attachedSections.firstIndex(where: { $0.id == id }) {
            if #available(iOS 11.0, *) {
                tableView.performBatchUpdates {
                    tableView.insertSections(IndexSet(integer: index),
                                             with: .fade)
                }
            } else {
                tableView.beginUpdates()
                tableView.insertSections(IndexSet(integer: index),
                                         with: .fade)
                tableView.endUpdates()
            }
        }
    }
    
    public func notifyDetach(id: AnyHashable) {
        if let index = attachedSections.firstIndex(where: { $0.id == id }) {
            if #available(iOS 11.0, *) {
                tableView.performBatchUpdates {
                    attachedSections.remove(at: index)
                    tableView.deleteSections(IndexSet(integer: index),
                                             with: .fade)
                }
            } else {
                tableView.beginUpdates()
                attachedSections.remove(at: index)
                tableView.deleteSections(IndexSet(integer: index),
                                         with: .fade)
                tableView.endUpdates()
            }
        }
    }
    
    public func notifyHeightChanged(id: AnyHashable) {
        guard attachedSections.contains(where: { $0.id == id }) else {
            return
        }
        
        if #available(iOS 11.0, *) {
            UIView.setAnimationsEnabled(false)
            tableView.performBatchUpdates({}) { _ in
                UIView.setAnimationsEnabled(true)
            }
        } else {
            UIView.setAnimationsEnabled(false)
            tableView.beginUpdates()
            tableView.endUpdates()
            UIView.setAnimationsEnabled(true)
        }
    }
    
    private func registerCells(for section: TableSection) {
        for reg in section.reusableViewRegisters {
            reg.register(for: tableView)
        }
    }
}

// MARK: - UITableViewDataSource
extension SectionedTableAdapter: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        attachedSections.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        attachedSections[section].numberOfItems
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        attachedSections[indexPath.section].cellForRow(at: indexPath, table: tableView)
    }
}

// MARK: - UITableViewDelegate
extension SectionedTableAdapter: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        forwaredDelegate?.tableView?(tableView, heightForRowAt: indexPath)
        ?? attachedSections[indexPath.section].heightForRow(at: indexPath.row).value
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        forwaredDelegate?.tableView?(tableView, estimatedHeightForRowAt: indexPath)
        ?? cachedRowHeights[indexPath]
        ?? tableView.estimatedRowHeight
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        forwaredDelegate?.tableView?(tableView, heightForHeaderInSection: section)
        ?? attachedSections[section].headerSpacing.value
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        forwaredDelegate?.tableView?(tableView, viewForHeaderInSection: section)
        ?? attachedSections[section].header(for: tableView)
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        forwaredDelegate?.tableView?(tableView, viewForFooterInSection: section)
        ?? attachedSections[section].footer(for: tableView)
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        forwaredDelegate?.tableView?(tableView, heightForFooterInSection: section)
        ?? attachedSections[section].footerSpacing.value
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        forwaredDelegate?.tableView?(tableView, didSelectRowAt: indexPath)
        ?? {
            tableView.deselectRow(at: indexPath, animated: true)
            attachedSections[indexPath.section].didSelectRow(at: indexPath)
        }()
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        forwaredDelegate?.tableView?(tableView, willDisplay: cell, forRowAt: indexPath)
        ?? {
            cachedRowHeights[indexPath] = cell.frame.height
        }()
    }
    
    // MARK: - UIScrollViewDelegate
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        forwaredDelegate?.scrollViewDidScroll?(scrollView)
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        forwaredDelegate?.scrollViewWillBeginDragging?(scrollView)
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        forwaredDelegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        forwaredDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
    
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        forwaredDelegate?.scrollViewWillBeginDecelerating?(scrollView)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        forwaredDelegate?.scrollViewDidEndDecelerating?(scrollView)
    }
}
