//
//  CSVExporter.swift
//  ThreadJournal2
//
//  Handles CSV export formatting for threads and entries
//

import Foundation

/// CSV implementation of ExportData
struct CSVExportData: ExportData {
    let fileName: String
    let mimeType: String = "text/csv"
    let data: Data
}

/// Handles CSV export functionality
final class CSVExporter: Exporter {
    
    func export(thread: Thread, entries: [Entry]) -> ExportData {
        let csvData = generateCSV(thread: thread, entries: entries)
        let fileName = generateFileName(for: thread)
        
        return CSVExportData(
            fileName: fileName,
            data: csvData
        )
    }
    
    private func generateFileName(for thread: Thread) -> String {
        // Sanitize thread title for filename
        let sanitizedTitle = thread.title
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: "\\", with: "-")
            .replacingOccurrences(of: "?", with: "")
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "*", with: "")
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "|", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmm"
        let dateString = formatter.string(from: Date())
        
        return "\(sanitizedTitle)_\(dateString).csv"
    }
    
    private func generateCSV(thread: Thread, entries: [Entry]) -> Data {
        var csvContent = ""
        
        // Add headers
        csvContent += "\"Date & Time\",\"Entry Content\"\n"
        
        // Add each entry
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        for entry in entries {
            let timestamp = dateFormatter.string(from: entry.timestamp)
            let content = escapeCSVField(entry.content)
            csvContent += "\"\(timestamp)\",\"\(content)\"\n"
        }
        
        // Convert to UTF-8 data
        return csvContent.data(using: .utf8) ?? Data()
    }
    
    private func escapeCSVField(_ field: String) -> String {
        // Replace quotes with double quotes
        let escapedQuotes = field.replacingOccurrences(of: "\"", with: "\"\"")
        return escapedQuotes
    }
}