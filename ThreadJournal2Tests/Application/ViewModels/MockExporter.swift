//
//  MockExporter.swift
//  ThreadJournal2Tests
//
//  Mock implementation of Exporter for testing
//

import Foundation
@testable import ThreadJournal2


/// Mock exporter for testing
final class MockExporter: Exporter {
    var exportCallCount = 0
    var exportResult: ExportData?
    var shouldFail = false
    
    func export(thread: ThreadJournal2.Thread, entries: [Entry]) -> ExportData {
        exportCallCount += 1
        
        if shouldFail {
            // In a real implementation, this would throw
            // For now, return empty data
            return MockExportData(
                fileName: "error.csv",
                mimeType: "text/csv",
                data: Data()
            )
        }
        
        return exportResult ?? MockExportData(
            fileName: "\(thread.title).csv",
            mimeType: "text/csv",
            data: "Date & Time,Entry Content\n".data(using: .utf8) ?? Data()
        )
    }
}

/// Mock export data implementation
struct MockExportData: ExportData {
    let fileName: String
    let mimeType: String
    let data: Data
}