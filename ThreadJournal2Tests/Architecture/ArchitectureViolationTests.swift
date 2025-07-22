//
//  ArchitectureViolationTests.swift
//  ThreadJournal2Tests
//
//  Additional tests for detecting architecture violations
//

import XCTest
@testable import ThreadJournal2

final class ArchitectureViolationTests: XCTestCase {
    
    // MARK: - Naming Convention Tests
    
    /// Verifies that all use cases follow naming convention
    func testUseCaseNamingConvention() {
        let useCaseFiles = FileScanner.scan("ThreadJournal2/Application")
            .filter { $0.path.contains("UseCase") }
        
        for file in useCaseFiles {
            let fileName = URL(fileURLWithPath: file.path).deletingPathExtension().lastPathComponent
            
            XCTAssertTrue(
                fileName.hasSuffix("UseCase"),
                "Use case file \(fileName) must end with 'UseCase'"
            )
            
            // Check that the class/struct name matches the file name
            let typePattern = #"(class|struct)\s+(\w+)"#
            if let regex = try? NSRegularExpression(pattern: typePattern, options: []) {
                let matches = regex.matches(in: file.content, options: [], range: NSRange(file.content.startIndex..., in: file.content))
                
                for match in matches {
                    if let range = Range(match.range(at: 2), in: file.content) {
                        let typeName = String(file.content[range])
                        XCTAssertEqual(
                            typeName,
                            fileName,
                            "Type name \(typeName) must match file name \(fileName)"
                        )
                    }
                }
            }
        }
    }
    
    /// Verifies that repository implementations follow naming convention
    func testRepositoryImplementationNaming() {
        let repoImplFiles = FileScanner.scan("ThreadJournal2/Infrastructure/Persistence")
            .filter { $0.path.contains("Repository") && !$0.path.contains("Protocol") }
        
        for file in repoImplFiles {
            let fileName = URL(fileURLWithPath: file.path).deletingPathExtension().lastPathComponent
            
            // Implementation files should have specific suffixes
            let validSuffixes = ["CoreDataRepository", "InMemoryRepository", "UserDefaultsRepository"]
            let hasValidSuffix = validSuffixes.contains { fileName.hasSuffix($0) }
            
            XCTAssertTrue(
                hasValidSuffix,
                "Repository implementation \(fileName) must end with a valid suffix: \(validSuffixes.joined(separator: ", "))"
            )
        }
    }
    
    // MARK: - Dependency Injection Tests
    
    /// Verifies that use cases use dependency injection
    func testUseCasesUseDependencyInjection() {
        let useCaseFiles = FileScanner.scan("ThreadJournal2/Application")
            .filter { $0.path.contains("UseCase") }
        
        for file in useCaseFiles {
            let content = file.content
            
            // Check for initializer with dependencies
            let initPattern = #"init\s*\([^)]*\w+:[^)]+\)"#
            let hasInitWithParams = countMatches(of: initPattern, in: content) > 0
            
            if !hasInitWithParams {
                // Check if it's a simple use case without dependencies
                let propertyPattern = #"(let|var)\s+\w+:\s*\w+Repository"#
                let hasRepositoryProperty = countMatches(of: propertyPattern, in: content) > 0
                
                if hasRepositoryProperty {
                    XCTFail(
                        "Use case \(file.path) has repository properties but no dependency injection initializer"
                    )
                }
            }
        }
    }
    
    // MARK: - Circular Dependency Tests
    
    /// Checks for potential circular dependencies between layers
    func testNoCircularDependencies() {
        // Map to track which files reference which layers
        var layerReferences: [String: Set<String>] = [:]
        
        let allFiles = [
            FileScanner.scan("ThreadJournal2/Domain"),
            FileScanner.scan("ThreadJournal2/Application"),
            FileScanner.scan("ThreadJournal2/Interface"),
            FileScanner.scan("ThreadJournal2/Infrastructure")
        ].flatMap { $0 }
        
        for file in allFiles {
            guard let sourceLayer = file.layer else { continue }
            
            var referencedLayers = Set<String>()
            
            // Check for references to other layers in the content
            if file.content.contains("Domain.") || file.content.contains("import Domain") {
                referencedLayers.insert("Domain")
            }
            if file.content.contains("Application.") || file.content.contains("import Application") {
                referencedLayers.insert("Application")
            }
            if file.content.contains("Interface.") || file.content.contains("import Interface") {
                referencedLayers.insert("Interface")
            }
            if file.content.contains("Infrastructure.") || file.content.contains("import Infrastructure") {
                referencedLayers.insert("Infrastructure")
            }
            
            layerReferences[String(describing: sourceLayer)] = referencedLayers
        }
        
        // Verify dependency rules
        if let domainRefs = layerReferences["domain"] {
            XCTAssertTrue(
                domainRefs.subtracting(["Domain"]).isEmpty,
                "Domain layer must not reference other layers, but references: \(domainRefs)"
            )
        }
        
        if let appRefs = layerReferences["application"] {
            XCTAssertTrue(
                appRefs.subtracting(["Domain", "Application"]).isEmpty,
                "Application layer can only reference Domain, but references: \(appRefs)"
            )
        }
    }
    
    // MARK: - Code Organization Tests
    
    /// Verifies that files are in the correct directories
    func testFilesInCorrectDirectories() {
        let allFiles = FileScanner.scan("ThreadJournal2")
        
        for file in allFiles {
            let path = file.path
            let fileName = URL(fileURLWithPath: path).lastPathComponent
            
            // Check entity files are in Entities folder
            if fileName.contains("Entity") || ["Thread.swift", "Entry.swift"].contains(fileName) {
                XCTAssertTrue(
                    path.contains("/Entities/"),
                    "Entity file \(fileName) must be in an Entities directory"
                )
            }
            
            // Check repository files are in Repositories folder
            if fileName.contains("Repository") {
                XCTAssertTrue(
                    path.contains("/Repositories/"),
                    "Repository file \(fileName) must be in a Repositories directory"
                )
            }
            
            // Check use case files are in appropriate folders
            if fileName.contains("UseCase") {
                XCTAssertTrue(
                    path.contains("/Application/"),
                    "Use case file \(fileName) must be in the Application layer"
                )
            }
        }
    }
    
    // MARK: - Protocol Conformance Tests
    
    /// Verifies that repository implementations conform to their protocols
    func testRepositoryImplementationsConformToProtocols() {
        let repoProtocols = FileScanner.scan("ThreadJournal2/Domain/Repositories")
        let repoImplementations = FileScanner.scan("ThreadJournal2/Infrastructure/Persistence")
            .filter { $0.path.contains("Repository") }
        
        // Extract protocol names
        var protocolNames: Set<String> = []
        for file in repoProtocols {
            let protocolPattern = #"protocol\s+(\w+)"#
            if let regex = try? NSRegularExpression(pattern: protocolPattern, options: []) {
                let matches = regex.matches(in: file.content, options: [], range: NSRange(file.content.startIndex..., in: file.content))
                for match in matches {
                    if let range = Range(match.range(at: 1), in: file.content) {
                        protocolNames.insert(String(file.content[range]))
                    }
                }
            }
        }
        
        // Check implementations
        for impl in repoImplementations {
            let content = impl.content
            var implementsProtocol = false
            
            for protocolName in protocolNames {
                if content.contains(": \(protocolName)") || content.contains(", \(protocolName)") {
                    implementsProtocol = true
                    break
                }
            }
            
            XCTAssertTrue(
                implementsProtocol,
                "Repository implementation \(impl.path) must conform to a repository protocol"
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func countMatches(of pattern: String, in text: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return 0
        }
        return regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text)).count
    }
}