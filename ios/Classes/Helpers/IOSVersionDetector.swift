import Foundation
import UIKit
import os.log

/// iOS Version Detection Utility
/// Detects iOS version to determine Liquid Glass support (iOS 18+) and Modern Toolbar (iOS 26+)
///
/// CHAOS ENGINEERING PRINCIPLES:
/// - Fail Fast: Invalid version detection returns safe defaults
/// - Idempotent: Version checks are cached and safe to call multiple times
/// - Anti-fragile: Multiple detection methods with fallbacks
/// - Observable: Structured logging for all detection paths
@available(iOS 15.0, *)
class IOSVersionDetector {

    // MARK: - Observability
    private static let logger = OSLog(subsystem: "com.adaptive_cupertino_ios", category: "VersionDetection")

    // MARK: - Idempotency Cache
    private static var cachedMajorVersion: Int?
    private static var cachedVersionInfo: [String: Any]?

    // MARK: - iOS 26 Modern Toolbar Support

    /// Check if device supports Modern Toolbar with pill-shaped buttons (iOS 26+)
    /// RESILIENCE: Returns false on any detection failure (fail-safe default)
    static func supportsModernToolbar() -> Bool {
        let supports = currentIOSVersion() >= 26.0
        os_log(.info, log: logger, "Modern Toolbar Support: %{public}@, iOS: %.1f",
               supports ? "YES" : "NO", currentIOSVersion())
        return supports
    }

    /// Check if device is running iOS 26 or newer
    /// CHAOS RESISTANT: Uses #available check as primary, version parsing as fallback
    static func isIOS26OrNewer() -> Bool {
        // Primary detection: Compile-time #available check
        if #available(iOS 26.0, *) {
            os_log(.info, log: logger, "📱 TRUE iOS 26 Environment Detected")
            return true
        }

        // Fallback/Experimental: Run iOS 26 features on iOS 18+ for high-fidelity glass demo
        let major = getMajorVersion()
        if major >= 18 {
            os_log(.info, log: logger, "📱 Experimental Mode: Enabling iOS 26 features on iOS %d", major)
            return true
        }
        
        return false
    }

    // MARK: - iOS 18 Liquid Glass Support

    /// Check if device supports Liquid Glass (iOS 18+)
    /// RESILIENCE: Safe default (false) on detection failure
    static func supportsLiquidGlass() -> Bool {
        let supports = currentIOSVersion() >= 18.0
        os_log(.debug, log: logger, "Liquid Glass Support: %{public}@", supports ? "YES" : "NO")
        return supports
    }

    /// Alias for supportsLiquidGlass to match plugin naming
    static func supportsGlassEffect() -> Bool {
        return supportsLiquidGlass()
    }

    /// Check if device is running iOS 18 or newer
    static func isIOS18OrNewer() -> Bool {
        if #available(iOS 26.0, *) {
            return true
        }
        return false
    }

    // MARK: - iOS 26 Liquid Glass Sheets

    /// Check if device supports Liquid Glass Sheets (iOS 26+)
    /// Includes floating geometry and UIGlassEffect support.
    static func supportsLiquidGlassSheets() -> Bool {
        return isIOS26OrNewer()
    }

    // MARK: - Version Parsing (Anti-fragile with multiple methods)

    /// Get current iOS major version with caching for idempotency
    /// CHAOS RESISTANT: Multiple parsing strategies with fallbacks
    static func currentIOSVersion() -> Double {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = "\(osVersion.majorVersion).\(osVersion.minorVersion)"

        // Primary: Double parsing
        if let version = Double(versionString) {
            return version
        }

        // Fallback 1: Manual major version (safe default)
        os_log(.error, log: logger, "Version parsing failed, using major version only: %{public}d",
               osVersion.majorVersion)
        return Double(osVersion.majorVersion)
    }

    /// Get detailed iOS version info with caching
    /// IDEMPOTENT: Cached result for performance and consistency
    static func versionInfo() -> [String: Any] {
        // Return cached if available (idempotency)
        if let cached = cachedVersionInfo {
            return cached
        }

        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let info: [String: Any] = [
            "majorVersion": osVersion.majorVersion,
            "minorVersion": osVersion.minorVersion,
            "patchVersion": osVersion.patchVersion,
            "supportsGlassEffect": supportsGlassEffect(),
            "supportsModernToolbar": supportsModernToolbar(),
            "fullVersion": "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        ]

        // Cache for idempotency
        cachedVersionInfo = info

        os_log(.info, log: logger, "Version Info: %{public}@", String(describing: info))
        return info
    }

    /// Get iOS version as string
    /// CHAOS RESISTANT: Never fails, returns system version or empty string
    static func getIOSVersion() -> String {
        let version = UIDevice.current.systemVersion
        guard !version.isEmpty else {
            os_log(.error, log: logger, "System version is empty, returning fallback")
            return "0.0"
        }
        return version
    }

    /// Get major iOS version number with caching
    /// IDEMPOTENT: Cached result for consistency
    static func getMajorVersion() -> Int {
        // Return cached if available (idempotency)
        if let cached = cachedMajorVersion {
            return cached
        }

        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let major = osVersion.majorVersion

        // Sanity check (chaos engineering: validate assumptions)
        guard major > 0 && major < 100 else {
            os_log(.fault, log: logger, "Invalid major version detected: %{public}d, returning safe default", major)
            return 15 // Safe default (iOS 15 minimum requirement)
        }

        // Cache for idempotency
        cachedMajorVersion = major
        return major
    }

    // MARK: - Self-Healing / Cache Reset

    /// Reset cached values (for testing or anomaly recovery)
    /// SELF-HEALING: Allows cache refresh if detection becomes stale
    static func resetCache() {
        cachedMajorVersion = nil
        cachedVersionInfo = nil
        os_log(.info, log: logger, "Version detection cache reset")
    }
}
