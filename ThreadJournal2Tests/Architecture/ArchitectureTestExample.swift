//
//  ArchitectureTestExample.swift
//  ThreadJournal2Tests
//
//  Example test to verify architecture tests are working
//

import XCTest

final class ArchitectureTestExample: XCTestCase {
    
    /// Example test showing how to run a specific architecture check
    func testExampleArchitectureCheck() {
        // Scan a specific layer
        let domainFiles = FileScanner.scan("ThreadJournal2/Domain")
        
        print("Found \(domainFiles.count) files in Domain layer:")
        for file in domainFiles {
            print("  - \(file.path)")
            print("    Imports: \(file.imports)")
        }
        
        // Verify Domain files exist
        XCTAssertGreaterThan(domainFiles.count, 0, "Domain layer should have at least one file")
        
        // Check a specific rule
        for file in domainFiles {
            for importedModule in file.imports {
                XCTAssertEqual(importedModule, "Foundation", 
                              "Domain file \(file.path) should only import Foundation, but imports \(importedModule)")
            }
        }
    }
    
    /// Test the FileScanner utility itself
    func testFileScannerFunctionality() {
        // Test scanning the test directory
        let testFiles = FileScanner.scan("ThreadJournal2Tests/Architecture")
        
        // We should find at least this test file
        XCTAssertGreaterThan(testFiles.count, 0, "Should find test files in Architecture directory")
        
        // Verify this file is found
        let thisFile = testFiles.first { $0.path.contains("ArchitectureTestExample.swift") }
        XCTAssertNotNil(thisFile, "Should find this test file")
        
        // Verify imports are detected
        if let file = thisFile {
            XCTAssertTrue(file.imports.contains("XCTest"), "Should detect XCTest import")
        }
    }
}