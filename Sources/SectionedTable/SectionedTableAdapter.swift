//
//  SectionedTableAdapter.swift
//  Sapo
//
//  Created by Kien Nguyen on 21/05/2022.
//

import Foundation
import UIKit

public class SectionedTableAdapter: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    private var sections: ContiguousArray<TableSection> = [] {
        didSet {
            attachedSections = sections.filter({ $0.isAttached })
        }
    }
    private var attachedSections: ContiguousArray<TableSection> = []
    private let tableView: UITableView
    private var cachedRowHeights: [IndexPath: CGFloat] = [:]
    
    public init(tableView: UITableView) {
        self.tableView = tableView
        
        super.init()
        
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        // some common setups
        self.tableView.estimatedRowHeight = 100
    }
    
    public func addSection(_ section: TableSection) {
        if data.contains(where: { $0.id == section.id }) {
            fatalError("Section ID must be unique. ID \(section.id) already exists.")
        }
        
        section.adapter = self
        registerCells(for: section)
        sections.append(section)
        
        if attachedSections.count <= 1 {
            tableView.reloadData()
        } else {
            tableView.insertSections(IndexSet(integer: attachedSections.count - 1),
                                     with: .none)
        }
    }
    
    public func reloadSection(id: Int, animated: Bool = true) {
        if let index = attachedSections.firstIndex(where: { $0.id == id }) {
            tableView.reloadSections(IndexSet(integer: index),
                                     with: animated ? .automatic : .none)
        }
    }
    
    public func reloadRows(_ rows: Set<Int>, sectionId: Int, animated: Bool = true) {
        if let index = attachedSections.firstIndex(where: { $0.id == sectionId }) {
            tableView.reloadRows(at: rows.map({ IndexPath(row: $0, section: index) }),
                                 with: animated ? .automatic : .none)
        }
    }
    
    public func notifyAttach(id: Int) {
        attachedSections = sections.filter({ $0.isAttached })
        
        if let index = attachedSections.firstIndex(where: { $0.id == id }) {
            tableView.insertSections(IndexSet(integer: index),
                                     with: .fade)
        }
    }
    
    public func notifyDetach(id: Int) {
        if let index = attachedSections.firstIndex(where: { $0.id == id }) {
            attachedSections = sections.filter({ $0.isAttached })
            tableView.deleteSections(IndexSet(integer: index),
                                     with: .fade)
        }
    }
    
    private func registerCells(for section: TableSection) {
        for reg in section.reusableViewRegisters {
            reg.register(for: tableView)
        }
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        attachedSections.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        attachedSections[section].numberOfItems
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        attachedSections[indexPath.section].cellForRow(at: indexPath, table: tableView)
    }
    
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
        attachedSections[indexPath.section].didSelectRow(at: indexPath.row)
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cachedRowHeights[indexPath] = cell.frame.height
    }
}
