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
    
    func export(thread: Thread, entries: [Entry], customFields: [CustomField], fieldGroups: [CustomFieldGroup]) -> ExportData {
        let csvData = generateCSV(thread: thread, entries: entries, customFields: customFields, fieldGroups: fieldGroups)
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
    
    private func generateCSV(thread: Thread, entries: [Entry], customFields: [CustomField], fieldGroups: [CustomFieldGroup]) -> Data {
        var csvContent = ""
        
        // Build column headers
        let fieldColumns = buildFieldColumns(customFields: customFields, fieldGroups: fieldGroups)
        let headers = ["Date & Time", "Entry Content"] + fieldColumns
        csvContent += headers.map { "\"\(escapeCSVField($0))\"" }.joined(separator: ",") + "\n"
        
        // Add each entry
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        for entry in entries {
            let timestamp = dateFormatter.string(from: entry.timestamp)
            let content = escapeCSVField(entry.content)
            
            var row = [timestamp, content]
            
            // Add field values for each column
            let fieldValues = buildFieldValues(for: entry, fieldColumns: fieldColumns, customFields: customFields, fieldGroups: fieldGroups)
            row.append(contentsOf: fieldValues)
            
            csvContent += row.map { "\"\(escapeCSVField($0))\"" }.joined(separator: ",") + "\n"
        }
        
        // Convert to UTF-8 data
        return csvContent.data(using: .utf8) ?? Data()
    }
    
    private func escapeCSVField(_ field: String) -> String {
        // Replace quotes with double quotes
        let escapedQuotes = field.replacingOccurrences(of: "\"", with: "\"\"")
        return escapedQuotes
    }
    
    /// Builds ordered column headers for custom fields
    /// Group fields are formatted as "GroupName.FieldName"
    /// Standalone fields use their name directly
    /// Columns are ordered by field order
    private func buildFieldColumns(customFields: [CustomField], fieldGroups: [CustomFieldGroup]) -> [String] {
        var columns: [String] = []
        
        // Create a map of field ID to field for easy lookup
        let fieldMap = Dictionary(uniqueKeysWithValues: customFields.map { ($0.id, $0) })
        
        // Create a map of child field ID to parent field for group formatting
        var childToParentMap: [UUID: CustomField] = [:]
        for group in fieldGroups {
            for childField in group.childFields {
                childToParentMap[childField.id] = group.parentField
            }
        }
        
        // Sort all non-group fields by order
        let nonGroupFields = customFields.filter { !$0.isGroup }.sorted { $0.order < $1.order }
        
        // Build column names
        for field in nonGroupFields {
            if let parentField = childToParentMap[field.id] {
                // This is a child field in a group - format as "GroupName.FieldName"
                columns.append("\(parentField.name).\(field.name)")
            } else {
                // This is a standalone field
                columns.append(field.name)
            }
        }
        
        return columns
    }
    
    /// Builds field values for a specific entry matching the field columns order
    /// Returns empty string for fields not present in the entry
    private func buildFieldValues(for entry: Entry, fieldColumns: [String], customFields: [CustomField], fieldGroups: [CustomFieldGroup]) -> [String] {
        // Create a map of field ID to field for easy lookup
        let fieldMap = Dictionary(uniqueKeysWithValues: customFields.map { ($0.id, $0) })
        
        // Create a map of field ID to column name for lookup
        var fieldIdToColumnMap: [UUID: String] = [:]
        
        // Create a map of child field ID to parent field for group formatting
        var childToParentMap: [UUID: CustomField] = [:]
        for group in fieldGroups {
            for childField in group.childFields {
                childToParentMap[childField.id] = group.parentField
            }
        }
        
        // Build the field ID to column name mapping
        for field in customFields.filter({ !$0.isGroup }) {
            if let parentField = childToParentMap[field.id] {
                fieldIdToColumnMap[field.id] = "\(parentField.name).\(field.name)"
            } else {
                fieldIdToColumnMap[field.id] = field.name
            }
        }
        
        // Create a map of field values for this entry
        let entryFieldValues = Dictionary(uniqueKeysWithValues: entry.customFieldValues.map { ($0.fieldId, $0.value) })
        
        // Build values array matching the column order
        var values: [String] = []
        for columnName in fieldColumns {
            // Find the field ID that matches this column name
            if let fieldId = fieldIdToColumnMap.first(where: { $0.value == columnName })?.key {
                values.append(entryFieldValues[fieldId] ?? "")
            } else {
                values.append("")
            }
        }
        
        return values
    }
}