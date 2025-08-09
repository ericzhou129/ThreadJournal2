//
//  MemoryManagementService.swift
//  ThreadJournal2
//
//  Service for managing memory usage and cache optimization
//

import Foundation
import UIKit

/// Service responsible for memory management and cache optimization
final class MemoryManagementService {
    
    static let shared = MemoryManagementService()
    
    // MARK: - Cache Size Limits
    
    /// Maximum number of cached threads with custom fields
    private let maxCachedThreads = 10
    
    /// Maximum cache age in seconds
    private let maxCacheAge: TimeInterval = 300 // 5 minutes
    
    /// Timer for periodic cache cleanup
    private var cleanupTimer: Timer?
    
    /// Memory pressure observer
    private var memoryPressureSource: DispatchSourceMemoryPressure?
    
    // MARK: - Initialization
    
    private init() {
        setupMemoryPressureMonitoring()
        startPeriodicCleanup()
        setupAppStateNotifications()
    }
    
    deinit {
        cleanupTimer?.invalidate()
        memoryPressureSource?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Memory Pressure Monitoring
    
    private func setupMemoryPressureMonitoring() {
        memoryPressureSource = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .critical],
            queue: DispatchQueue.global(qos: .utility)
        )
        
        memoryPressureSource?.setEventHandler { [weak self] in
            Task { @MainActor in
                await self?.handleMemoryPressure()
            }
        }
        
        memoryPressureSource?.resume()
    }
    
    @MainActor
    private func handleMemoryPressure() async {
        print("Memory pressure detected - clearing caches")
        await clearAllCaches()
    }
    
    // MARK: - App State Monitoring
    
    private func setupAppStateNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func appDidEnterBackground() {
        Task { @MainActor in
            await clearNonEssentialCaches()
        }
    }
    
    @objc private func appDidReceiveMemoryWarning() {
        Task { @MainActor in
            await handleMemoryPressure()
        }
    }
    
    // MARK: - Periodic Cleanup
    
    private func startPeriodicCleanup() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performPeriodicCleanup()
            }
        }
    }
    
    @MainActor
    private func performPeriodicCleanup() async {
        // Clean up expired caches
        CustomFieldsViewModel.cleanupExpiredCaches()
        ThreadDetailViewModel.cleanupExpiredCaches()
        
        // Trim caches if they exceed size limits
        await trimCachesToLimits()
    }
    
    // MARK: - Cache Management
    
    @MainActor
    func clearAllCaches() async {
        CustomFieldsViewModel.clearAllCaches()
        ThreadDetailViewModel.clearAllCaches()
        print("All caches cleared due to memory pressure")
    }
    
    @MainActor
    func clearNonEssentialCaches() async {
        // Clear expired caches but keep recent ones
        CustomFieldsViewModel.cleanupExpiredCaches()
        ThreadDetailViewModel.cleanupExpiredCaches()
        print("Non-essential caches cleared")
    }
    
    @MainActor
    private func trimCachesToLimits() async {
        // Implementation would trim caches to size limits
        // For now, just cleanup expired entries
        CustomFieldsViewModel.cleanupExpiredCaches()
        ThreadDetailViewModel.cleanupExpiredCaches()
    }
    
    // MARK: - Memory Usage Monitoring
    
    /// Gets current memory usage in MB
    func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return 0.0 }
        
        return Double(info.resident_size) / 1024.0 / 1024.0 // Convert to MB
    }
    
    /// Gets system memory pressure level
    func getMemoryPressureLevel() -> String {
        let memoryUsage = getCurrentMemoryUsage()
        
        if memoryUsage > 500 { // > 500MB
            return "Critical"
        } else if memoryUsage > 250 { // > 250MB
            return "Warning"
        } else {
            return "Normal"
        }
    }
    
    // MARK: - Cache Statistics
    
    /// Gets cache statistics for debugging
    func getCacheStatistics() -> [String: Any] {
        return [
            "memory_usage_mb": getCurrentMemoryUsage(),
            "memory_pressure": getMemoryPressureLevel(),
            "cleanup_timer_valid": cleanupTimer?.isValid ?? false,
            "max_cached_threads": maxCachedThreads,
            "max_cache_age": maxCacheAge
        ]
    }
}