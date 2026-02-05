import Flutter
import UIKit

/// Shared utility for dynamically loading and registering Flutter icon fonts in native code.
class FlutterFontLoader {
    private let registrar: FlutterPluginRegistrar
    private static var registeredFonts = Set<String>()
    
    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
    }
    
    /// Loads a Flutter font by name, resolving its asset path via the registrar.
    func loadFont(name: String, size: CGFloat, package: String? = nil) -> UIFont? {
        // 1. Check if already available to the system
        if let font = UIFont(name: name, size: size) {
            return font
        }
        
        // 2. Resolve Asset Path
        var assetName: String?
        if name == "CupertinoIcons" {
            assetName = "packages/cupertino_icons/assets/CupertinoIcons.ttf"
        } else if name == "MaterialIcons" {
            assetName = "fonts/MaterialIcons-Regular.otf"
        } else if let pkg = package {
            assetName = "packages/\(pkg)/\(name).ttf"
        } else {
            assetName = "assets/fonts/\(name).ttf"
        }
        
        guard let asset = assetName else { return nil }
        
        // 3. Register if not already done
        let key = registrar.lookupKey(forAsset: asset)
        if !Self.registeredFonts.contains(key) {
            if registerFont(key: key) {
                Self.registeredFonts.insert(key)
            }
        }
        
        return UIFont(name: name, size: size)
    }
    
    private func registerFont(key: String) -> Bool {
        guard let path = Bundle.main.path(forResource: key, ofType: nil) else {
            NSLog("⚠️ [FlutterFontLoader] Asset not found for key: %@", key)
            return false
        }
        
        guard let fontDataProvider = CGDataProvider(filename: path.cString(using: .utf8)!) else { return false }
        guard let font = CGFont(fontDataProvider) else { return false }
        
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(font, &error) {
            let errorDescription = error.map { "\($0.takeRetainedValue())" } ?? "Unknown"
            NSLog("ℹ️ [FlutterFontLoader] Registration info for %@: %@", key, errorDescription)
            // If it's already registered (check error code if needed), we return true
            return true 
        }
        
        NSLog("✅ [FlutterFontLoader] Font registered: %@", key)
        return true
    }
}
