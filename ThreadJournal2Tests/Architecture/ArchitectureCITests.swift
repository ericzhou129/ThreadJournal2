//
//  ArchitectureCITests.swift
//  ThreadJournal2Tests
//
//  CI-focused architecture tests that will fail the build on violations
//

import XCTest
@testable import ThreadJournal2

/// Main test suite for CI builds - any failure here should block the build
final class ArchitectureCITests: XCTestCase {
    
    override class func setUp() {
        super.setUp()
        print("🏗️ Running Architecture Compliance Tests...")
    }
    
    override class func tearDown() {
        super.tearDown()
        print("✅ Architecture Tests Completed")
    }
    
    // MARK: - Critical Architecture Rules
    
    /// Master test that runs all architecture checks
    func testArchitectureCompliance() {
        var violations: [String] = []
        
        // Run all architecture checks
        violations.append(contentsOf: checkDomainLayerCompliance())
        violations.append(contentsOf: checkApplicationLayerCompliance())
        violations.append(contentsOf: checkInterfaceLayerCompliance())
        violations.append(contentsOf: checkInfrastructureLayerCompliance())
        violations.append(contentsOf: checkUseCaseCompliance())
        violations.append(contentsOf: checkDependencyRules())
        
        // Report all violations
        if !violations.isEmpty {
            let report = generateViolationReport(violations)
            XCTFail(report)
        }
    }
    
    // MARK: - Layer Compliance Checks
    
    private func checkDomainLayerCompliance() -> [String] {
        var violations: [String] = []
        let domainFiles = FileScanner.scan("ThreadJournal2/Domain")
        
        for file in domainFiles {
            // Check forbidden imports
            let forbiddenImports = ["UIKit", "SwiftUI", "CoreData", "Combine"]
            for forbidden in forbiddenImports {
                if file.contains(forbidden) {
                    violations.append("❌ Domain Violation: \(file.path) imports \(forbidden)")
                }
            }
            
            // Check that only Foundation is imported
            for importedModule in file.imports {
                if importedModule != "Foundation" {
                    violations.append("❌ Domain Violation: \(file.path) imports non-Foundation module: \(importedModule)")
                }
            }
        }
        
        return violations
    }
    
    private func checkApplicationLayerCompliance() -> [String] {
        var violations: [String] = []
        let applicationFiles = FileScanner.scan("ThreadJournal2/Application")
        
        for file in applicationFiles {
            // Check forbidden imports
            let forbiddenImports = ["UIKit", "SwiftUI", "CoreData"]
            for forbidden in forbiddenImports {
                if file.contains(forbidden) {
                    violations.append("❌ Application Violation: \(file.path) imports \(forbidden)")
                }
            }
        }
        
        return violations
    }
    
    private func checkInterfaceLayerCompliance() -> [String] {
        var violations: [String] = []
        let interfaceFiles = FileScanner.scan("ThreadJournal2/Interface")
        
        for file in interfaceFiles {
            // Check forbidden imports
            if file.contains("CoreData") {
                violations.append("❌ Interface Violation: \(file.path) imports CoreData")
            }
        }
        
        return violations
    }
    
    private func checkInfrastructureLayerCompliance() -> [String] {
        var violations: [String] = []
        let infrastructureFiles = FileScanner.scan("ThreadJournal2/Infrastructure")
        
        for file in infrastructureFiles {
            // Check forbidden imports
            let forbiddenImports = ["UIKit", "SwiftUI"]
            for forbidden in forbiddenImports {
                if file.contains(forbidden) {
                    violations.append("❌ Infrastructure Violation: \(file.path) imports \(forbidden)")
                }
            }
        }
        
        return violations
    }
    
    private func checkUseCaseCompliance() -> [String] {
        var violations: [String] = []
        let useCaseFiles = FileScanner.scan("ThreadJournal2/Application")
            .filter { $0.path.contains("UseCase") }
        
        for file in useCaseFiles {
            // Check for single public execute method
            let publicMethodPattern = #"public\s+func\s+(\w+)"#
            var publicMethods: [String] = []
            
            if let regex = try? NSRegularExpression(pattern: publicMethodPattern, options: []) {
                let matches = regex.matches(in: file.content, options: [], range: NSRange(file.content.startIndex..., in: file.content))
                for match in matches {
                    if let range = Range(match.range(at: 1), in: file.content) {
                        publicMethods.append(String(file.content[range]))
                    }
                }
            }
            
            // Should have exactly one public method named "execute"
            if publicMethods.count != 1 || (publicMethods.count == 1 && publicMethods[0] != "execute") {
                violations.append("❌ Use Case Violation: \(file.path) must have exactly one public method named 'execute', found: \(publicMethods)")
            }
        }
        
        return violations
    }
    
    private func checkDependencyRules() -> [String] {
        var violations: [String] = []
        
        // Check that repository implementations exist only in Infrastructure
        let allRepoFiles = FileScanner.scan("ThreadJournal2")
            .filter { $0.path.contains("Repository") }
        
        for file in allRepoFiles {
            let isDomainProtocol = file.path.contains("/Domain/") && file.content.contains("protocol")
            let isInfrastructureImpl = file.path.contains("/Infrastructure/")
            
            if !isDomainProtocol && !isInfrastructureImpl && file.content.contains("Repository") {
                // Check if it's an implementation (not just a protocol)
                if file.content.contains("class") || (file.content.contains("struct") && file.content.contains(": ") && file.content.contains("Repository")) {
                    violations.append("❌ Dependency Violation: Repository implementation \(file.path) must be in Infrastructure layer")
                }
            }
        }
        
        return violations
    }
    
    // MARK: - Report Generation
    
    private func generateViolationReport(_ violations: [String]) -> String {
        let header = """
        🚨 ARCHITECTURE VIOLATIONS DETECTED 🚨
        
        The following Clean Architecture rules have been violated:
        
        """
        
        let violationList = violations.map { "  • \($0)" }.joined(separator: "\n")
        
        let footer = """
        
        
        📋 Architecture Rules:
        1. Domain layer: Only import Foundation
        2. Application layer: No UI or persistence imports
        3. Interface layer: No persistence imports
        4. Infrastructure layer: No UI imports
        5. Use Cases: Single public execute() method
        6. Repository implementations: Infrastructure layer only
        
        Please fix these violations before merging.
        """
        
        return header + violationList + footer
    }
    
    // MARK: - Summary Test
    
    /// Provides a summary of the architecture scan
    func testArchitectureSummary() {
        print("\n📊 Architecture Scan Summary:")
        
        let layers = [
            ("Domain", "ThreadJournal2/Domain"),
            ("Application", "ThreadJournal2/Application"),
            ("Interface", "ThreadJournal2/Interface"),
            ("Infrastructure", "ThreadJournal2/Infrastructure")
        ]
        
        for (name, path) in layers {
            let files = FileScanner.scan(path)
            print("  • \(name) Layer: \(files.count) files")
        }
        
        // This test always passes, it's just for reporting
        XCTAssertTrue(true)
    }
}