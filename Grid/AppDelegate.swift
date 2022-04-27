import AppKit
import SwiftUI
import HotKey
import Yaml
import Carbon

class Action {
    var targetRects = Array<CGRect>()
    var lastTs = TimeInterval(0)
    var nRepeat = Int(0)
    var appDelegate: AppDelegate
    var previousPid = Int32(0)
    
    init(appDelegate: AppDelegate) {
        self.appDelegate = appDelegate
    }
    
    @objc func execute() {
        print("\nPressed at \(Date())")
        
        guard let frontmostApplication: NSRunningApplication = NSWorkspace.shared.frontmostApplication else {
            print("Cannot get frontmostApplication")
            return
        }
        
        if (appDelegate.previousAction === self && previousPid == frontmostApplication.processIdentifier) {
            nRepeat += 1
        } else {
            nRepeat = 0
            previousPid = frontmostApplication.processIdentifier
            appDelegate.previousAction = self
        }
        print("Repeat \(nRepeat)")
        
        let underlyingElement = AXUIElementCreateApplication(frontmostApplication.processIdentifier)
        var _focusedWindow: AnyObject?
        let result: AXError = AXUIElementCopyAttributeValue(underlyingElement, NSAccessibility.Attribute.focusedWindow as CFString, &_focusedWindow)
        if result != .success {
            print("Cannot get focused window")
            return
        }
        let focusedWindow: AXUIElement = _focusedWindow as! AXUIElement
        
        let currentRect = self.getRect(window: focusedWindow)
        print("Current rect: \(currentRect)")
        
        let targetRectPixels = self.floatRectToPixels(rect: self.targetRects[nRepeat % targetRects.count])
        print("Target rect:  \(targetRectPixels)")
        
        self.setRect(window: focusedWindow, value: targetRectPixels)
        
        let finalRect = self.getRect(window: focusedWindow)
        print("Final rect:  \(finalRect)")
    }
    
    func floatRectToPixels(rect: CGRect) -> CGRect {
        let screens = NSScreen.screens
        let heightOfFirstScreen = screens.first!.frame.height
        
        let screen = NSScreen.main
        
        let screenFrame = NSRectToCGRect(screen!.frame)
        let screenVisibleFrame = NSRectToCGRect(screen!.visibleFrame)
        
        let menuBarHeight = screenFrame.height - screenVisibleFrame.height
        
        var x = rect.origin.x * screenVisibleFrame.width
        var y = rect.origin.y * screenVisibleFrame.height + menuBarHeight
        if (screenFrame.origin.x != 0 || screenFrame.origin.y != 0) {
            x += screenFrame.origin.x
            y += screenFrame.origin.y - heightOfFirstScreen - screenFrame.height
        }
        
        
        let w = rect.size.width * screenVisibleFrame.width
        let h = rect.size.height * screenVisibleFrame.height
        return CGRect(x: x, y: y, width: w, height: h)
    }
    
    func getPosition(window: AXUIElement) -> CGPoint {
        var rawValue: AnyObject?
        AXUIElementCopyAttributeValue(window, NSAccessibility.Attribute.position.rawValue as CFString, &rawValue)
        return (rawValue as! AXValue).toValue()!
    }

    func getSize(window: AXUIElement) -> CGSize {
        var rawValue: AnyObject?
        AXUIElementCopyAttributeValue(window, NSAccessibility.Attribute.size.rawValue as CFString, &rawValue)
        return (rawValue as! AXValue).toValue()!
    }
    
    func setPosition(window: AXUIElement, value: CGPoint) {
        let value = AXValue.from(value: value, type: .cgPoint)
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value)
    }
    
    func setSize(window: AXUIElement, value: CGSize) {
        let value = AXValue.from(value: value, type: .cgSize)
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value)
    }
    
    func getRect(window: AXUIElement) -> CGRect {
        let pos = getPosition(window: window)
        let size = getSize(window: window)
        return CGRect(origin: pos, size: size)
    }

    func setRect(window: AXUIElement, value: CGRect) {
        setPosition(window: window, value: value.origin)
        setSize(window: window, value: value.size)
    }
}

extension AXValue {
    func toValue<T>() -> T? {
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        let success = AXValueGetValue(self, AXValueGetType(self), pointer)
        return success ? pointer.pointee : nil
    }

    static func from<T>(value: T, type: AXValueType) -> AXValue {
        let pointer = UnsafeMutablePointer<T>.allocate(capacity: 1)
        pointer.pointee = value
        return AXValueCreate(type, pointer)!
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {

	var statusBarItem: NSStatusItem!
	var statusBarMenu: NSMenu!
    var hotKeys = Array<HotKey>()
    var hotKey: HotKey!
    weak var previousAction: Action?
    
    func getPosition(window: AXUIElement) -> CGPoint {
        var rawValue: AnyObject?
        AXUIElementCopyAttributeValue(window, NSAccessibility.Attribute.position.rawValue as CFString, &rawValue)
        return (rawValue as! AXValue).toValue()!
    }

    func getSize(window: AXUIElement) -> CGSize {
        var rawValue: AnyObject?
        AXUIElementCopyAttributeValue(window, NSAccessibility.Attribute.size.rawValue as CFString, &rawValue)
        return (rawValue as! AXValue).toValue()!
    }
    
    func setPosition(window: AXUIElement, value: CGPoint) {
        let value = AXValue.from(value: value, type: .cgPoint)
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value)
    }
    
    func setSize(window: AXUIElement, value: CGSize) {
        let value = AXValue.from(value: value, type: .cgSize)
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value)
    }
    
    func getRect(window: AXUIElement) -> CGRect {
        let pos = getPosition(window: window)
        let size = getSize(window: window)
        return CGRect(origin: pos, size: size)
    }
	func applicationDidFinishLaunching(_ notification: Notification) {

		self.statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
		self.statusBarItem.button?.image = NSImage(systemSymbolName: "square.grid.3x3.fill", accessibilityDescription: "Status bar icon")
		self.statusBarMenu = NSMenu()
		self.statusBarItem.menu = self.statusBarMenu
    
        loadYaml()
        
        if !AXIsProcessTrusted() {
            let options : NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
            let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        
            if !accessibilityEnabled {
                print("\nACCESSIBILITY IS NOT YET GRANTED!\n")
            }
        }
        
        self.statusBarMenu.addItem(withTitle: "Quit", action: #selector(handler_quit), keyEquivalent: "q")
	}

    func loadYaml() {
        do {
            let bundleConfigPath = Bundle.main.url(forResource: "grid", withExtension: "yaml")!
            let configPath = NSString(string: "~/.grid.yaml").expandingTildeInPath
            let configUrl = URL(fileURLWithPath: configPath)
            
            if !FileManager.default.fileExists(atPath: configPath) {
                print("Copy default config to:", configPath)
                try FileManager.default.copyItem(at: bundleConfigPath, to: configUrl)
            }
            
            print("Loading config from:", configPath)
            let configData = try String(contentsOfFile: configPath, encoding: String.Encoding.utf8)
            let config = try Yaml.load(configData)
            for item in config.array! {
                let keyString = item["key"].string!
                var key = keyString.components(separatedBy: "_")
                let k = Key(string: key.popLast()!)!
                
                var modifiers: NSEvent.ModifierFlags = []
                for i in key {
                    if i == "CMD" {
                        modifiers.insert(NSEvent.ModifierFlags.command)
                    } else if i == "OPT" || i == "ALT" {
                        modifiers.insert(NSEvent.ModifierFlags.option)
                    } else if i == "CTRL" {
                        modifiers.insert(NSEvent.ModifierFlags.control)
                    }
                }
                
                let keyCombo = KeyCombo(key: k, modifiers: modifiers)
                print(keyCombo)
                
                let action = Action(appDelegate: self)
                for pos in item["positions"].array! {
                    let position = pos.dictionary!
                    let x = position["x"]!.double!
                    let y = position["y"]!.double!
                    let w = position["w"]!.double!
                    let h = position["h"]!.double!
                    let rect = CGRect(x: x, y: y, width: w, height: h)
                    action.targetRects.append(rect)
                    print("  \(rect)")
                }
                
                let hk = HotKey(keyCombo: keyCombo, keyDownHandler: action.execute)
                self.hotKeys.append(hk)
                let menuItem = NSMenuItem(title: item["name"].string ?? "", action: nil, keyEquivalent: k.description)
                menuItem.keyEquivalentModifierMask = hk.keyCombo.modifiers
                self.statusBarMenu.addItem(menuItem)
            }
            print("Loading config done")
        } catch {
            print("Unexpected error: \(error).")
            handler_quit()
        }
    }
    
    @objc func handler_quit() {
        NSApplication.shared.terminate(self)
    }
}
