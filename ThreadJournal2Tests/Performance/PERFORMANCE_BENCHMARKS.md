# ThreadJournal Performance Benchmarks

## Overview
This document outlines the performance targets and testing methodology for ThreadJournal to ensure the app remains responsive with large datasets.

## Performance Targets

### Thread List Loading
- **Target**: < 200ms for 100 threads
- **Test**: `ThreadListPerformanceTests.testLoadThreadList_With100Threads_CompletesUnder200ms()`
- **Covers**: Initial app launch and thread list refresh

### Thread Detail Loading  
- **Target**: < 300ms for 1000 entries
- **Test**: `ThreadDetailPerformanceTests.testLoadThreadDetail_With1000Entries_CompletesUnder300ms()`
- **Covers**: Opening a thread with extensive history

### Entry Creation
- **Target**: < 50ms per entry
- **Test**: `EntryCreationPerformanceTests.testCreateSingleEntry_CompletesUnder50ms()`
- **Covers**: Adding new journal entries

### CSV Export
- **Target**: < 3 seconds for 1000 entries
- **Test**: `CSVExportPerformanceTests.testExport1000Entries_CompletesUnder3Seconds()`
- **Covers**: Exporting thread data for backup/sharing

### Memory Usage
- **Target**: < 150MB total with 100 threads and varying entry counts
- **Test**: `MemoryPerformanceTests.testOverallMemoryUsage_100ThreadsWith1000EntriesEach_StaysUnder150MB()`
- **Covers**: Overall app memory footprint

## Test Data Distribution

For realistic testing, we use the following data distribution:
- 10 threads with 1000 entries each (heavy users)
- 20 threads with 100 entries each (regular users)  
- 30 threads with 50 entries each (moderate users)
- 40 threads with 10 entries each (light users)

Total: 100 threads, ~15,000 entries

## Running Performance Tests

### Run All Performance Tests
```bash
xcodebuild test \
  -scheme ThreadJournal2 \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ThreadJournal2Tests/Performance
```

### Run Specific Test Class
```bash
xcodebuild test \
  -scheme ThreadJournal2 \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:ThreadJournal2Tests/ThreadListPerformanceTests
```

### Using Xcode
1. Open Test Navigator (⌘6)
2. Navigate to ThreadJournal2Tests > Performance
3. Click the play button next to individual tests or test classes

## Interpreting Results

### Baseline Metrics
Performance tests use XCTest's `measure` blocks which run the test 10 times and report:
- Average execution time
- Standard deviation
- Relative standard deviation

### Acceptable Variance
- < 10% variance: Excellent consistency
- 10-20% variance: Acceptable for most operations
- > 20% variance: May indicate performance issues

### Device Considerations
- Tests are calibrated for iPhone 15 simulator
- Older devices (iPhone SE) may need 20-30% more time
- Debug builds are ~2x slower than release builds

## Monitoring Performance

### Key Metrics to Track
1. **Launch Time**: Time to display thread list
2. **Scroll Performance**: 60 FPS in thread list and detail views
3. **Memory Growth**: Should plateau, not continuously increase
4. **Battery Impact**: Minimal background activity

### Performance Regression Prevention
1. Run performance tests before each merge
2. Set baseline metrics in Xcode
3. Fail CI if performance degrades > 20%
4. Profile with Instruments for detailed analysis

## Optimization Guidelines

### When to Optimize
- Performance test failures
- User reports of sluggishness
- Memory warnings in production

### Common Optimizations
1. **Lazy Loading**: Load entries in batches
2. **Caching**: Cache computed properties
3. **Background Processing**: Move heavy operations off main thread
4. **Data Structures**: Use efficient collections

### What NOT to Optimize
- Don't optimize prematurely
- Keep code readable over micro-optimizations
- Profile before optimizing
- Test after optimizing

## Future Considerations

### Phase 2 Performance
- iCloud sync: May add 100-500ms latency
- Search: Index for < 100ms full-text search
- Rich text: May increase memory 20-30%

### Phase 3 Performance  
- Encryption: ~10% CPU overhead
- Voice notes: Streaming to avoid memory spikes
- Tags: Indexed for instant filtering

## Appendix: Test Infrastructure

### TestDataBuilder
Factory pattern for generating consistent test data:
- `createThreads(count:)` - Generate test threads
- `createEntries(count:for:)` - Generate test entries
- `createCompleteScenario(threadCount:entriesPerThread:)` - Full test setup

### Memory Measurement
Uses `mach_task_basic_info` for accurate memory tracking:
```swift
func getCurrentMemoryUsage() -> Int64
```

### Performance Test Template
```swift
func testFeature_WithConditions_MeetsTarget() {
    measure {
        // Test implementation
    }
}
```