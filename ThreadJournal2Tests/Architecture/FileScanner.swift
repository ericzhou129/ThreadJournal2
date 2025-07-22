//
//  FileScanner.swift
//  ThreadJournal2Tests
//
//  Utility for scanning Swift files and analyzing their imports
//

import Foundation

/// Utility class for scanning Swift files in the project
final class FileScanner {
    
    /// Represents a scanned Swift file
    struct SwiftFile {
        let path: String
        let content: String
        let imports: Set<String>
        
        /// Checks if the file contains a specific import
        func contains(_ importStatement: String) -> Bool {
            imports.contains(importStatement)
        }
        
        /// Checks if the file imports any of the specified modules
        func importsAny(of modules: [String]) -> Bool {
            for module in modules {
                if imports.contains(module) {
                    return true
                }
            }
            return false
        }
    }
    
    /// Scans all Swift files in the specified directory
    /// - Parameter directory: The directory path relative to the project root
    /// - Returns: Array of SwiftFile objects
    static func scan(_ directory: String) -> [SwiftFile] {
        let fileManager = FileManager.default
        let projectRoot = getProjectRoot()
        let fullPath = projectRoot.appendingPathComponent(directory)
        
        var swiftFiles: [SwiftFile] = []
        
        if let enumerator = fileManager.enumerator(at: fullPath, includingPropertiesForKeys: nil) {
            for case let file as URL in enumerator {
                if file.pathExtension == "swift" {
                    if let swiftFile = scanFile(at: file, projectRoot: projectRoot) {
                        swiftFiles.append(swiftFile)
                    }
                }
            }
        }
        
        return swiftFiles
    }
    
    /// Scans a single Swift file
    /// - Parameters:
    ///   - url: The file URL
    ///   - projectRoot: The project root URL for relative path calculation
    /// - Returns: SwiftFile object if successful
    private static func scanFile(at url: URL, projectRoot: URL) -> SwiftFile? {
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        
        let imports = extractImports(from: content)
        let relativePath = url.path.replacingOccurrences(of: projectRoot.path + "/", with: "")
        
        return SwiftFile(
            path: relativePath,
            content: content,
            imports: imports
        )
    }
    
    /// Extracts all import statements from Swift file content
    /// - Parameter content: The file content
    /// - Returns: Set of imported module names
    private static func extractImports(from content: String) -> Set<String> {
        var imports = Set<String>()
        
        // Regular expression to match import statements
        let importPattern = #"^\s*import\s+(\w+)"#
        
        content.enumerateLines { line, _ in
            if let regex = try? NSRegularExpression(pattern: importPattern, options: .anchorsMatchLines) {
                let matches = regex.matches(in: line, options: [], range: NSRange(line.startIndex..., in: line))
                for match in matches {
                    if let range = Range(match.range(at: 1), in: line) {
                        let moduleName = String(line[range])
                        imports.insert(moduleName)
                    }
                }
            }
        }
        
        return imports
    }
    
    /// Gets the project root directory
    /// - Returns: URL of the project root
    private static func getProjectRoot() -> URL {
        // In test context, we need to navigate up from the test bundle
        let currentPath = URL(fileURLWithPath: #file)
        
        // Navigate up to find ThreadJournal2 directory
        var url = currentPath
        while url.pathComponents.count > 1 {
            if url.lastPathComponent == "ThreadJournal2" {
                return url
            }
            url = url.deletingLastPathComponent()
        }
        
        // Fallback to current directory
        return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
            .appendingPathComponent("ThreadJournal2")
    }
}

// MARK: - Layer Detection Extension

extension FileScanner.SwiftFile {
    
    /// Determines which layer this file belongs to based on its path
    var layer: ArchitectureLayer? {
        if path.contains("/Domain/") {
            return .domain
        } else if path.contains("/Application/") {
            return .application
        } else if path.contains("/Interface/") {
            return .interface
        } else if path.contains("/Infrastructure/") {
            return .infrastructure
        }
        return nil
    }
}

/// Represents the architectural layers in Clean Architecture
enum ArchitectureLayer {
    case domain
    case application
    case interface
    case infrastructure
    
    /// Returns the allowed imports for this layer
    var allowedImports: Set<String> {
        switch self {
        case .domain:
            // Domain can only import Foundation
            return ["Foundation"]
        case .application:
            // Application can import Domain and Foundation
            return ["Foundation"]
        case .interface:
            // Interface can import Application, Domain, and UI frameworks
            return ["Foundation", "SwiftUI", "UIKit", "Combine"]
        case .infrastructure:
            // Infrastructure can import Domain and persistence frameworks
            return ["Foundation", "CoreData", "Combine"]
        }
    }
    
    /// Returns the forbidden imports for this layer
    var forbiddenImports: Set<String> {
        switch self {
        case .domain:
            // Domain must not import UI or persistence frameworks
            return ["UIKit", "SwiftUI", "CoreData", "Combine"]
        case .application:
            // Application must not import UI or persistence frameworks
            return ["UIKit", "SwiftUI", "CoreData"]
        case .interface:
            // Interface must not import persistence frameworks
            return ["CoreData"]
        case .infrastructure:
            // Infrastructure must not import UI frameworks
            return ["UIKit", "SwiftUI"]
        }
    }
}