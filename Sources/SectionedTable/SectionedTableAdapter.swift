//
//  SectionedTableAdapter.swift
//  Sapo
//
//  Created by Kien Nguyen on 21/05/2022.
//

import Foundation
import UIKit

public class SectionedTableAdapter: NSObject {
    
    public class MoveHandler {
        public var canMoveFrom: (IndexPath) -> Bool = { _ in true }
        public var canMoveTo: (IndexPath, IndexPath) -> Bool = { _, _ in true }
        public var didMove: (IndexPath, IndexPath) -> Void
        
        public init(didMove: @escaping (_ source: IndexPath, _ dest: IndexPath) -> Void,
                    canMoveFrom: @escaping (_ source: IndexPath) -> Bool = { _ in true },
                    canMoveTo: @escaping (_ source: IndexPath, _ dest: IndexPath) -> Bool = { _, _ in true }) {
            self.didMove = didMove
            self.canMoveFrom = canMoveFrom
            self.canMoveTo = canMoveTo
        }
    }
    
    private var sections: ContiguousArray<TableSection> = [] {
        didSet {
            attachedSections = sections.filter({ $0.isAttached })
        }
    }
    private var attachedSections: ContiguousArray<TableSection> = []
    private var cachedRowHeights: [IndexPath: CGFloat] = [:]
    
    public let tableView: UITableView
    public weak var forwaredScrollDelegate: UIScrollViewDelegate?
    
    public var moveHandler: MoveHandler? {
        didSet {
            if moveHandler != nil {
                tableView.dragDelegate = self
                tableView.dragInteractionEnabled = true
            } else {
                tableView.dragDelegate = nil
                tableView.dragInteractionEnabled = false
            }
        }
    }
    
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
    
    /// Update attach status of all sections and notify tableView
    /// - Parameter ids: ids of attached sections
    public func updateAttachedSections(ids: [AnyHashable]) {
        let attachedIds = attachedSections.map({ $0.id })
        let allIds = sections.map({ $0.id })
        
        let attaches = allIds.filter({ ids.contains($0) && !attachedIds.contains($0) })
        let detaches = allIds.filter({ !ids.contains($0) && attachedIds.contains($0) })
        
        sections.forEach({ $0.updateAttached(ids.contains($0.id), notify: false) })
        
        notifyAttachesAndDetaches(attaches: attaches, detaches: detaches)
    }
    
    public func notifyAttachesAndDetaches(attaches: [AnyHashable], detaches: [AnyHashable]) {
        if attaches.isEmpty && detaches.isEmpty {
            return
        }
        
        let calculateRemovedIndexes = {
            var removedIndexes: [Int] = []
            for (index, section) in self.attachedSections.enumerated() {
                if detaches.contains(section.id) {
                    removedIndexes.append(index)
                }
            }
            return removedIndexes
        }
        
        let calculateInsertedIndexes = {
            var insertedIndexes: [Int] = []
            for (index, section) in self.attachedSections.enumerated() {
                if attaches.contains(section.id) {
                    insertedIndexes.append(index)
                }
            }
            return insertedIndexes
        }
        
        let removedIndexes = calculateRemovedIndexes()
        
        if #available(iOS 11.0, *) {
            tableView.performBatchUpdates {
                attachedSections = sections.filter({ $0.isAttached })
                tableView.deleteSections(IndexSet(removedIndexes), with: .fade)
                let insertedIndexes = calculateInsertedIndexes()
                tableView.insertSections(IndexSet(insertedIndexes), with: .fade)
            }
        } else {
            tableView.beginUpdates()
            attachedSections = sections.filter({ $0.isAttached })
            tableView.deleteSections(IndexSet(removedIndexes), with: .fade)
            let insertedIndexes = calculateInsertedIndexes()
            tableView.insertSections(IndexSet(insertedIndexes), with: .fade)
            tableView.endUpdates()
        }
    }
    
    public func notifyHeightChanged(id: AnyHashable) {
        guard attachedSections.contains(where: { $0.id == id }) else {
            return
        }
        
        if #available(iOS 11.0, *) {
            UIView.performWithoutAnimation {
                self.tableView.performBatchUpdates({}) { _ in }
            }
        } else {
            UIView.performWithoutAnimation {
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
            }
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
        attachedSections[indexPath.section].heightForRow(at: indexPath.row).value
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        cachedRowHeights[indexPath] ?? tableView.estimatedRowHeight
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        attachedSections[section].headerSpacing.value
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        attachedSections[section].header(for: tableView)
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        attachedSections[section].footer(for: tableView)
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        attachedSections[section].footerSpacing.value
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        attachedSections[indexPath.section].didSelectRow(at: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cachedRowHeights[indexPath] = cell.frame.height
    }
    
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let actions = attachedSections[indexPath.section].actionsForRow(at: indexPath)
        if actions.isEmpty {
            return nil
        }
        
        let action = UISwipeActionsConfiguration(actions: actions)
        action.performsFirstActionWithFullSwipe = false
        return action
    }
    
    public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        moveHandler?.didMove(sourceIndexPath, destinationIndexPath)
    }
    
    // MARK: - UIScrollViewDelegate
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        forwaredScrollDelegate?.scrollViewDidScroll?(scrollView)
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        forwaredScrollDelegate?.scrollViewWillBeginDragging?(scrollView)
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        forwaredScrollDelegate?.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        forwaredScrollDelegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    }
    
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        forwaredScrollDelegate?.scrollViewWillBeginDecelerating?(scrollView)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        forwaredScrollDelegate?.scrollViewDidEndDecelerating?(scrollView)
    }
}

// MARK: - UITableViewDragDelegate
extension SectionedTableAdapter: UITableViewDragDelegate {
    public func tableView(_ tableView: UITableView,
                          itemsForBeginning session: UIDragSession,
                          at indexPath: IndexPath) -> [UIDragItem] {
        guard let moveHandler, moveHandler.canMoveFrom(indexPath) else {
            return []
        }
        
        let item = UIDragItem(itemProvider: .init())
        item.localObject = indexPath
        return [item]
    }
    
    public func tableView(_ tableView: UITableView,
                          dropSessionDidUpdate session: UIDropSession,
                          withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        guard let moveHandler, tableView.hasActiveDrag else { return .init(operation: .cancel) }
        guard let source = session.localDragSession?.items.first?.localObject as? IndexPath else { return .init(operation: .cancel) }
        guard let dest = destinationIndexPath else { return .init(operation: .cancel) }
        
        if !moveHandler.canMoveTo(source, dest) {
            return .init(operation: .forbidden)
        }
        
        return .init(operation: .move, intent: .insertAtDestinationIndexPath)
    }
}
