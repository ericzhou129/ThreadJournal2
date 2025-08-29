//
//  WaveformVisualizerTests.swift
//  ThreadJournal2Tests
//
//  Unit tests for WaveformVisualizer component
//

import XCTest
import SwiftUI
@testable import ThreadJournal2

final class WaveformVisualizerTests: XCTestCase {
    
    func testWaveformVisualizerActionsTriggered() {
        // Given
        var stopAndEditTriggered = false
        var stopAndSaveTriggered = false
        
        let waveform = WaveformVisualizer(
            onStopAndEdit: {
                stopAndEditTriggered = true
            },
            onStopAndSave: {
                stopAndSaveTriggered = true
            }
        )
        
        // When
        waveform.onStopAndEdit()
        waveform.onStopAndSave()
        
        // Then
        XCTAssertTrue(stopAndEditTriggered, "Stop and Edit action should be triggered")
        XCTAssertTrue(stopAndSaveTriggered, "Stop and Save action should be triggered")
    }
    
    func testWaveformVisualizerInitialization() {
        // Given/When
        let waveform = WaveformVisualizer(
            onStopAndEdit: { },
            onStopAndSave: { }
        )
        
        // Then
        XCTAssertNotNil(waveform)
        
        // Verify constants are properly set
        XCTAssertEqual(waveform.barCount, 10, "Waveform should have 10 bars")
        XCTAssertEqual(waveform.baseBars.count, 10, "Base bars array should have 10 elements")
    }
    
    func testWaveformVisualizerActionsSeparatelyCallable() {
        // Given
        var editCallCount = 0
        var saveCallCount = 0
        
        let waveform = WaveformVisualizer(
            onStopAndEdit: {
                editCallCount += 1
            },
            onStopAndSave: {
                saveCallCount += 1
            }
        )
        
        // When
        waveform.onStopAndEdit()
        waveform.onStopAndEdit()
        waveform.onStopAndSave()
        
        // Then
        XCTAssertEqual(editCallCount, 2, "Stop and Edit should be callable multiple times")
        XCTAssertEqual(saveCallCount, 1, "Stop and Save should be callable independently")
    }
    
    func testWaveformVisualizerActionsModifyState() {
        // Given
        var currentMode = "recording"
        
        let waveform = WaveformVisualizer(
            onStopAndEdit: {
                currentMode = "editing"
            },
            onStopAndSave: {
                currentMode = "saved"
            }
        )
        
        // When/Then
        waveform.onStopAndEdit()
        XCTAssertEqual(currentMode, "editing", "Stop and Edit should change mode to editing")
        
        waveform.onStopAndSave()
        XCTAssertEqual(currentMode, "saved", "Stop and Save should change mode to saved")
    }
    
    func testWaveformVisualizerBaseBarConfiguration() {
        // Given
        let waveform = WaveformVisualizer(onStopAndEdit: { }, onStopAndSave: { })
        
        // Then
        let expectedBaseBars = [12, 20, 16, 24, 18, 22, 14, 20, 16, 18]
        XCTAssertEqual(waveform.baseBars, expectedBaseBars, "Base bars should match expected configuration")
        
        // Verify all bar heights are reasonable
        for height in waveform.baseBars {
            XCTAssertGreaterThan(height, 0, "All bar heights should be positive")
            XCTAssertLessThan(height, 30, "All bar heights should be reasonable")
        }
    }
}