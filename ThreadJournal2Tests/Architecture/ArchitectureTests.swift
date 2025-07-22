//
//  ArchitectureTests.swift
//  ThreadJournal2Tests
//
//  Automated tests to enforce Clean Architecture boundaries
//

import XCTest
@testable import ThreadJournal2

final class ArchitectureTests: XCTestCase {
    
    // MARK: - Domain Layer Tests
    
    /// Verifies that Domain layer has no imports from UI or persistence frameworks
    func testDomainHasNoUIOrPersistenceImports() {
        let domainFiles = FileScanner.scan("ThreadJournal2/Domain")
        
        for file in domainFiles {
            // Check for UI framework imports
            XCTAssertFalse(
                file.contains("UIKit"),
                "Domain file \(file.path) must not import UIKit"
            )
            XCTAssertFalse(
                file.contains("SwiftUI"),
                "Domain file \(file.path) must not import SwiftUI"
            )
            
            // Check for persistence framework imports
            XCTAssertFalse(
                file.contains("CoreData"),
                "Domain file \(file.path) must not import CoreData"
            )
            
            // Check for Combine (should be avoided in Domain)
            XCTAssertFalse(
                file.contains("Combine"),
                "Domain file \(file.path) must not import Combine"
            )
        }
    }
    
    /// Verifies that Domain layer only imports Foundation
    func testDomainOnlyImportsFoundation() {
        let domainFiles = FileScanner.scan("ThreadJournal2/Domain")
        let allowedImports: Set<String> = ["Foundation"]
        
        for file in domainFiles {
            for importedModule in file.imports {
                XCTAssertTrue(
                    allowedImports.contains(importedModule),
                    "Domain file \(file.path) imports \(importedModule), which is not allowed. Only Foundation is permitted."
                )
            }
        }
    }
    
    // MARK: - Application Layer Tests
    
    /// Verifies that Application layer doesn't import UI or persistence frameworks
    func testApplicationHasNoUIOrPersistenceImports() {
        let applicationFiles = FileScanner.scan("ThreadJournal2/Application")
        
        for file in applicationFiles {
            // Check for UI framework imports
            XCTAssertFalse(
                file.contains("UIKit"),
                "Application file \(file.path) must not import UIKit"
            )
            XCTAssertFalse(
                file.contains("SwiftUI"),
                "Application file \(file.path) must not import SwiftUI"
            )
            
            // Check for persistence framework imports
            XCTAssertFalse(
                file.contains("CoreData"),
                "Application file \(file.path) must not import CoreData"
            )
        }
    }
    
    /// Verifies that Application layer only imports Domain and Foundation
    func testApplicationOnlyImportsAllowedModules() {
        let applicationFiles = FileScanner.scan("ThreadJournal2/Application")
        let allowedImports: Set<String> = ["Foundation"]
        
        for file in applicationFiles {
            for importedModule in file.imports {
                XCTAssertTrue(
                    allowedImports.contains(importedModule),
                    "Application file \(file.path) imports \(importedModule), which is not allowed. Only Foundation is permitted."
                )
            }
        }
    }
    
    // MARK: - Interface Layer Tests
    
    /// Verifies that Interface layer doesn't import persistence frameworks
    func testInterfaceHasNoPersistenceImports() {
        let interfaceFiles = FileScanner.scan("ThreadJournal2/Interface")
        
        for file in interfaceFiles {
            XCTAssertFalse(
                file.contains("CoreData"),
                "Interface file \(file.path) must not import CoreData"
            )
        }
    }
    
    // MARK: - Infrastructure Layer Tests
    
    /// Verifies that Infrastructure layer doesn't import UI frameworks
    func testInfrastructureHasNoUIImports() {
        let infrastructureFiles = FileScanner.scan("ThreadJournal2/Infrastructure")
        
        for file in infrastructureFiles {
            // Check for UI framework imports
            XCTAssertFalse(
                file.contains("UIKit"),
                "Infrastructure file \(file.path) must not import UIKit"
            )
            XCTAssertFalse(
                file.contains("SwiftUI"),
                "Infrastructure file \(file.path) must not import SwiftUI"
            )
        }
    }
    
    // MARK: - Use Case Tests
    
    /// Verifies that use cases have a single public execute() method
    func testUseCasesHaveSinglePublicExecuteMethod() {
        let useCaseFiles = FileScanner.scan("ThreadJournal2/Application")
            .filter { $0.path.contains("UseCase") }
        
        for file in useCaseFiles {
            let content = file.content
            
            // Check for public execute method
            let publicExecutePattern = #"public\s+func\s+execute"#
            let publicExecuteMatches = countMatches(of: publicExecutePattern, in: content)
            
            XCTAssertEqual(
                publicExecuteMatches,
                1,
                "Use case \(file.path) must have exactly one public execute() method, found \(publicExecuteMatches)"
            )
            
            // Check that no other public methods exist
            let publicMethodPattern = #"public\s+func\s+(?!execute)"#
            let otherPublicMethods = countMatches(of: publicMethodPattern, in: content)
            
            XCTAssertEqual(
                otherPublicMethods,
                0,
                "Use case \(file.path) must not have public methods other than execute(), found \(otherPublicMethods)"
            )
        }
    }
    
    // MARK: - Cross-Layer Dependency Tests
    
    /// Comprehensive test for all layer dependencies
    func testAllLayerDependencies() {
        let allFiles = [
            FileScanner.scan("ThreadJournal2/Domain"),
            FileScanner.scan("ThreadJournal2/Application"),
            FileScanner.scan("ThreadJournal2/Interface"),
            FileScanner.scan("ThreadJournal2/Infrastructure")
        ].flatMap { $0 }
        
        for file in allFiles {
            guard let layer = file.layer else { continue }
            
            for importedModule in file.imports {
                if layer.forbiddenImports.contains(importedModule) {
                    XCTFail(
                        "\(layer) layer file \(file.path) imports forbidden module: \(importedModule)"
                    )
                }
            }
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

// MARK: - File Content Analysis Extension

extension ArchitectureTests {
    
    /// Verifies that repositories in Domain layer are protocols only
    func testDomainRepositoriesAreProtocols() {
        let repositoryFiles = FileScanner.scan("ThreadJournal2/Domain/Repositories")
        
        for file in repositoryFiles {
            let content = file.content
            
            // Check for protocol declaration
            let protocolPattern = #"protocol\s+\w+Repository"#
            let hasProtocol = countMatches(of: protocolPattern, in: content) > 0
            
            XCTAssertTrue(
                hasProtocol,
                "Repository file \(file.path) must define a protocol"
            )
            
            // Check for class or struct (should not exist in Domain repositories)
            let classPattern = #"class\s+\w+Repository"#
            let structPattern = #"struct\s+\w+Repository"#
            
            XCTAssertEqual(
                countMatches(of: classPattern, in: content),
                0,
                "Repository file \(file.path) must not contain class implementations"
            )
            
            XCTAssertEqual(
                countMatches(of: structPattern, in: content),
                0,
                "Repository file \(file.path) must not contain struct implementations"
            )
        }
    }
    
    /// Verifies that entities in Domain layer are pure value types
    func testDomainEntitiesArePureValueTypes() {
        let entityFiles = FileScanner.scan("ThreadJournal2/Domain/Entities")
        
        for file in entityFiles {
            let content = file.content
            
            // Entities should be structs, not classes
            let classPattern = #"class\s+\w+"#
            XCTAssertEqual(
                countMatches(of: classPattern, in: content),
                0,
                "Entity file \(file.path) must not contain classes. Use structs for value types."
            )
            
            // Check for mutable state (var properties that aren't private)
            let mutableStatePattern = #"(?<!private\s)var\s+\w+:"#
            let mutableStateCount = countMatches(of: mutableStatePattern, in: content)
            
            if mutableStateCount > 0 {
                print("Warning: Entity \(file.path) contains \(mutableStateCount) mutable properties. Consider using immutable values.")
            }
        }
    }
}