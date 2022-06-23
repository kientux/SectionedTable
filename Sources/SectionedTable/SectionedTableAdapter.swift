//
//  SectionedTableAdapter.swift
//  Sapo
//
//  Created by Kien Nguyen on 21/05/2022.
//

import Foundation
import UIKit

public class SectionedTableAdapter: NSObject, UITableViewDataSource, UITableViewDelegate {
    
    private var data: ContiguousArray<TableSection> = []
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
        section.adapter = self
        registerCells(for: section)
        data.append(section)
        
        if data.count == 1 {
            tableView.reloadData()
        } else {
            tableView.insertSections(IndexSet(integer: data.count - 1), with: .none)
        }
    }
    
    public func reloadSection(id: Int, animated: Bool = true) {
        if let index = data.firstIndex(where: { $0.id == id }) {
            tableView.reloadSections(IndexSet(integer: index), with: animated ? .automatic : .none)
        }
    }
    
    public func reloadRows(_ rows: Set<Int>, sectionId: Int, animated: Bool = true) {
        if let index = data.firstIndex(where: { $0.id == sectionId }) {
            tableView.reloadRows(at: rows.map({ IndexPath(row: $0, section: index) }),
                                 with: animated ? .automatic : .none)
        }
    }
    
    private func registerCells(for section: TableSection) {
        for reg in section.reusableViewRegisters {
            reg.register(for: tableView)
        }
    }
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        data.count
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data[section].numberOfItems
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        data[indexPath.section].cellForRow(at: indexPath, table: tableView)
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        data[indexPath.section].heightForRow(at: indexPath.row).value
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        cachedRowHeights[indexPath] ?? tableView.estimatedRowHeight
    }
    
    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        data[section].headerSpacing.value
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        data[section].header(for: tableView)
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        data[section].footer(for: tableView)
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        data[section].footerSpacing.value
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        data[indexPath.section].didSelectRow(at: indexPath.row)
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cachedRowHeights[indexPath] = cell.frame.height
    }
}
