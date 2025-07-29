//
//  CustomFieldGroupTests.swift
//  ThreadJournal2Tests
//
//  Tests for CustomFieldGroup domain entity
//

import XCTest
@testable import ThreadJournal2

final class CustomFieldGroupTests: XCTestCase {
    
    private let threadId = UUID()
    
    func testCreateValidGroup() throws {
        let parentField = try CustomField(
            threadId: threadId,
            name: "ADHD Check-in",
            order: 1,
            isGroup: true
        )
        
        let childFields = [
            try CustomField(threadId: threadId, name: "Mood", order: 2),
            try CustomField(threadId: threadId, name: "Energy", order: 3),
            try CustomField(threadId: threadId, name: "Focus", order: 4)
        ]
        
        let group = try CustomFieldGroup(
            parentField: parentField,
            childFields: childFields
        )
        
        XCTAssertEqual(group.parentField, parentField)
        XCTAssertEqual(group.childFields, childFields)
        XCTAssertEqual(group.childFields.count, 3)
    }
    
    func testParentNotGroupThrows() throws {
        let nonGroupField = try CustomField(
            threadId: threadId,
            name: "Regular Field",
            order: 1,
            isGroup: false
        )
        
        let childField = try CustomField(
            threadId: threadId,
            name: "Child",
            order: 2
        )
        
        XCTAssertThrowsError(
            try CustomFieldGroup(
                parentField: nonGroupField,
                childFields: [childField]
            )
        ) { error in
            XCTAssertEqual(error as? ValidationError, .parentNotGroup)
        }
    }
    
    func testNestedGroupsNotAllowed() throws {
        let parentField = try CustomField(
            threadId: threadId,
            name: "Parent Group",
            order: 1,
            isGroup: true
        )
        
        let nestedGroup = try CustomField(
            threadId: threadId,
            name: "Nested Group",
            order: 2,
            isGroup: true
        )
        
        XCTAssertThrowsError(
            try CustomFieldGroup(
                parentField: parentField,
                childFields: [nestedGroup]
            )
        ) { error in
            XCTAssertEqual(error as? ValidationError, .nestedGroupsNotAllowed)
        }
    }
    
    func testFieldsFromDifferentThreadsThrows() throws {
        let thread1 = UUID()
        let thread2 = UUID()
        
        let parentField = try CustomField(
            threadId: thread1,
            name: "Parent",
            order: 1,
            isGroup: true
        )
        
        let childFromDifferentThread = try CustomField(
            threadId: thread2,
            name: "Child",
            order: 2
        )
        
        XCTAssertThrowsError(
            try CustomFieldGroup(
                parentField: parentField,
                childFields: [childFromDifferentThread]
            )
        ) { error in
            XCTAssertEqual(error as? ValidationError, .fieldsFromDifferentThreads)
        }
    }
    
    func testEmptyChildrenAllowed() throws {
        let parentField = try CustomField(
            threadId: threadId,
            name: "Empty Group",
            order: 1,
            isGroup: true
        )
        
        let group = try CustomFieldGroup(
            parentField: parentField,
            childFields: []
        )
        
        XCTAssertEqual(group.childFields.count, 0)
    }
    
    func testEquality() throws {
        let parentField = try CustomField(
            threadId: threadId,
            name: "Group",
            order: 1,
            isGroup: true
        )
        
        let childFields = [
            try CustomField(threadId: threadId, name: "Field1", order: 2),
            try CustomField(threadId: threadId, name: "Field2", order: 3)
        ]
        
        let group1 = try CustomFieldGroup(
            parentField: parentField,
            childFields: childFields
        )
        
        let group2 = try CustomFieldGroup(
            parentField: parentField,
            childFields: childFields
        )
        
        XCTAssertEqual(group1, group2)
    }
}