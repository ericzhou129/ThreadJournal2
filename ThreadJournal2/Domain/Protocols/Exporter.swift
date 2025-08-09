//
//  Exporter.swift
//  ThreadJournal2
//
//  Protocol for export functionality
//

import Foundation

/// Protocol for exporting thread data to various formats
protocol Exporter {
    func export(thread: Thread, entries: [Entry], customFields: [CustomField], fieldGroups: [CustomFieldGroup]) -> ExportData
}