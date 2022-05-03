import AppKit
import SwiftUI
import HotKey
import Yaml
import Carbon
import FileWatcher

//typealias CGSConnectionID = UInt32
//typealias CGSSpaceID = UInt64
//
//@_silgen_name("CGSCopyWindowsWithOptionsAndTags")
//func CGSCopyWindowsWithOptionsAndTags(_ cid: CGSConnectionID, _ owner: UInt32, _ spaces: CFArray, _ options: UInt32, _ setTags: inout UInt64, _ clearTags: inout UInt64) -> CFArray
//@_silgen_name("CGSMainConnectionID")
//func CGSMainConnectionID() -> CGSConnectionID
//let cgsMainConnectionId = CGSMainConnectionID()


func alertFatal(_ msg: String) {
    if !Thread.isMainThread {
        DispatchQueue.main.sync {
            alertFatal(msg)
        }
        return
    }
    
    let alert = NSAlert()
    alert.messageText = "Grid Fatal Error"
    alert.informativeText = msg
    alert.addButton(withTitle: "Quit")
    alert.alertStyle = .critical    
    alert.runModal()
    NSApplication.shared.terminate(nil)
}


func alertInfo(_ title: String, _ msg: String) {
    if !Thread.isMainThread {
        DispatchQueue.main.sync {
            alertInfo(title, msg)
        }
        return
    }
    let alert = NSAlert()
    alert.messageText = title
    alert.informativeText = msg
    alert.addButton(withTitle: "OK")
    alert.alertStyle = .informational
    alert.runModal()
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

extension AXUIElement {
    
    func getPosition() -> CGPoint {
        var rawValue: AnyObject?
        AXUIElementCopyAttributeValue(self, NSAccessibility.Attribute.position.rawValue as CFString, &rawValue)
        return (rawValue as! AXValue).toValue()!
    }

    func getSize() -> CGSize {
        var rawValue: AnyObject?
        AXUIElementCopyAttributeValue(self, NSAccessibility.Attribute.size.rawValue as CFString, &rawValue)
        return (rawValue as! AXValue).toValue()!
    }
    
    func setPosition(_ value: CGPoint) {
        let value = AXValue.from(value: value, type: .cgPoint)
        AXUIElementSetAttributeValue(self, kAXPositionAttribute as CFString, value)
    }
    
    func setSize(_ value: CGSize) {
        let value = AXValue.from(value: value, type: .cgSize)
        AXUIElementSetAttributeValue(self, kAXSizeAttribute as CFString, value)
    }
    
    func getRect() -> CGRect {
        let pos = getPosition()
        let size = getSize()
        return CGRect(origin: pos, size: size)
    }

    func setRect(_ value: CGRect) {
        setPosition(value.origin)
        setSize(value.size)
    }
    
    func move(_ position: RectOnScreen) {
        //let currentRect = self.getRect()
        //print("Current rect: \(currentRect)")
        
        
        //let targetRectPixels = Helper.floatRectToPixels(position)
        //print("Target rect:  \(targetRectPixels)")
        //self.setRect(targetRectPixels)
        self.setRect(position.asPixels())
        
        //let finalRect = self.getRect()
        //print("Final rect:  \(finalRect)")
    }
    
    func getTitle() -> String? {
        var rawValue: AnyObject?
        AXUIElementCopyAttributeValue(self, NSAccessibility.Attribute.title.rawValue as CFString, &rawValue)
        return rawValue as! String?
    }
}

class Helper {
//    static func windowsInSpaces(_ spaceIds: [CGSSpaceID]) -> [CGWindowID] {
//        var set_tags = UInt64(0)
//        var clear_tags = UInt64(0)
//        let currentSpaceId = CGSSpaceID(1)
//        return CGSCopyWindowsWithOptionsAndTags(cgsMainConnectionId, 0, [currentSpaceId] as CFArray, 2, &set_tags, &clear_tags) as! [CGWindowID]
//    }

    static func windowListFromApp(_ app: NSRunningApplication) -> [AXUIElement]? {
        let element = AXUIElementCreateApplication(app.processIdentifier)
        var value: AnyObject?
        AXUIElementCopyAttributeValue(element, NSAccessibility.Attribute.windows as CFString, &value)
        return value as? [AXUIElement]
    }
    
    static func getFrontmostApp() -> NSRunningApplication? {
        return NSWorkspace.shared.frontmostApplication
    }
    
    static func getFrontmostWindow() -> AXUIElement? {
        guard let frontmostApplication: NSRunningApplication = NSWorkspace.shared.frontmostApplication else {
            print("Cannot get frontmostApplication")
            return nil
        }
        
        let element = AXUIElementCreateApplication(frontmostApplication.processIdentifier)
        
        var _focusedWindow: AnyObject?
        let result: AXError = AXUIElementCopyAttributeValue(element, NSAccessibility.Attribute.focusedWindow as CFString, &_focusedWindow)
        if result != .success {
          print("Cannot get focused window")
          return nil
        }
        return _focusedWindow as! AXUIElement?
    }
}

extension NSScreen {
    func getRectPixel() -> CGRect {
        let heightOfFirstScreen = NSScreen.screens.first!.frame.height
        var a = self.visibleFrame
        a.origin.y = -a.origin.y + heightOfFirstScreen - a.size.height
        return a
    }
}

class Action {
    var name: String
    init(_ name: String) {
        self.name = name
    }
    @objc func execute() {
        print("\nAction: \(name)")
    }
}

class ActionScenarioEntry {
    var identifier: String
    var positions = Array<RectOnScreen>()
  
    init(yaml node: Yaml) throws {
        
        guard let app = node["app"].string else { throw GridError.message("no 'app'") }
        identifier = app
        guard let pos = node["position"].array else { throw GridError.message("no position or not array") }
        if pos[0].array == nil {
            try addPosition(node["position"])
        } else {
            for p in pos {
                try addPosition(p)
            }
        }
    }
    
    func addPosition(_ pos: Yaml) throws {
        positions.append(try RectOnScreen(yaml: pos))
    }
}

class ActionScenario : Action {
    var entries = Array<ActionScenarioEntry>()
    
    init(name: String) {
        super.init(name)
    }
    
    @objc override func execute() {
        super.execute()
        for entry in entries {
            Task.init {
                await self.move(entry)
            }
        }
    }
    
    func move(_ entry:ActionScenarioEntry) async {
        print(entry.identifier, entry.positions)
        
        do {
            //let apps = NSRunningApplication.runningApplications(withBundleIdentifier: entry.identifier)
            
            guard let url: URL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: entry.identifier) else {
                print("Cannot get URL for app \(entry.identifier)")
                return
            }
            let config = NSWorkspace.OpenConfiguration()
            //config.createsNewApplicationInstance = true
            config.activates = false
            let app: NSRunningApplication = try await NSWorkspace.shared.openApplication(at: url, configuration: config)

            var windowList: [AXUIElement]?
            
            for _ in 0...50 {
                windowList = Helper.windowListFromApp(app)
                if windowList != nil {
                    break
                }
                try await Task.sleep(nanoseconds: 100_000_000)
            }
            if windowList == nil {
                print("no windowList after 5 seconds")
                return
            }
            
            for (index, window) in windowList!.enumerated() {
                window.move(entry.positions[min(index, entry.positions.count-1)])
            }
        } catch {
            print("Unexpected error: \(error)")
        }
    }
}

extension CGRect {
    func hasOriginInside(rect p: CGRect) -> Bool {
        if origin.x >= p.origin.x && origin.x <= (p.origin.x+p.size.width)
            && origin.y >= p.origin.y && origin.y <= (p.origin.y+p.size.height) {
            return true
        }
        return false
    }
}

class RectOnScreen {
    var rect = CGRect()
    var screenIndex = Int(0)
    
    init(yaml pos: Yaml) throws {
        if pos.dictionary != nil {
            let position = pos.dictionary!
            guard let x = position["x"]?.double else { throw GridError.message("no x in position dict") }
            guard let y = position["y"]?.double else { throw GridError.message("no y in position dict") }
            guard let w = position["w"]?.double else { throw GridError.message("no w in position dict") }
            guard let h = position["h"]?.double else { throw GridError.message("no h in position dict") }
            rect = CGRect(x: x, y: y, width: w, height: h)
        } else if pos.array != nil {
            let position = pos.array!
            if position.count < 4 { throw GridError.message("position size < 4") }
            guard let x = position[0].double else { throw GridError.message("x is not float") }
            guard let y = position[1].double else { throw GridError.message("y is not float") }
            guard let w = position[2].double else { throw GridError.message("w is not float") }
            guard let h = position[3].double else { throw GridError.message("h is not float") }
            if position.count >= 5 {
                guard let s = position[4].int else { throw GridError.message("s is not int") }
                screenIndex = s
            }
            rect = CGRect(x: x, y: y, width: w, height: h)
        } else {
            
        }
        print("  \(rect)")
    }
    
    init(fromPixel p: CGRect) {
        
        print("p", p)
        
        for (index, screen) in NSScreen.screens.enumerated() {
            if !p.hasOriginInside(rect:screen.getRectPixel()) {
                continue
            }
            let frame = screen.getRectPixel()
            
            let x = (p.origin.x - frame.origin.x) / frame.width
            let y = (p.origin.y - frame.origin.y) / frame.height
            let w = p.width / frame.width
            let h = p.height / frame.height
            
            rect = CGRect(x: x, y: y, width: w, height: h)
            screenIndex = index
        }
        
    }
    
    func asPixels() -> CGRect {
        var s: NSScreen
        if screenIndex == 0 {
            s = NSScreen.main!
        } else {
            s = NSScreen.screens[min(screenIndex-1, NSScreen.screens.count-1)]
        }
        let frame = s.getRectPixel()
            
        let x = rect.origin.x * frame.width + frame.origin.x
        let y = rect.origin.y * frame.height + frame.origin.y
        let w = rect.size.width * frame.width
        let h = rect.size.height * frame.height
        return CGRect(x: Int(x), y: Int(y), width: Int(w), height: Int(h))
    }
    
}

class ActionForemost : Action {
    var targetRects = Array<RectOnScreen>()
    var lastTs = TimeInterval(0)
    var nRepeat = Int(0)
    var appDelegate: AppDelegate
    var previousPid = Int32(0)
    
    init(appDelegate: AppDelegate, name: String) {
        self.appDelegate = appDelegate
        super.init(name)
    }
    
    @objc override func execute() {
        super.execute()
        
        guard let app: NSRunningApplication = NSWorkspace.shared.frontmostApplication else {
            print("Cannot get app")
            return
        }
        
        guard let identifier = app.bundleIdentifier else {
            print("Cannot get app.bundleIdentifier")
            return
        }

        if (appDelegate.previousAction === self && previousPid == app.processIdentifier) {
            nRepeat += 1
        } else {
            nRepeat = 0
            previousPid = app.processIdentifier
            appDelegate.previousAction = self
        }

        let element = AXUIElementCreateApplication(app.processIdentifier)
        var _focusedWindow: AnyObject?
        let result: AXError = AXUIElementCopyAttributeValue(element, NSAccessibility.Attribute.focusedWindow as CFString, &_focusedWindow)
        if result != .success {
            print("Cannot get focused window")
            return
        }
        let focusedWindow: AXUIElement = _focusedWindow as! AXUIElement
        let target = targetRects[nRepeat % targetRects.count]
        print("Move \(identifier) to \(target)")
        focusedWindow.move(target)
    }
}

let reloadConfigQueue = DispatchQueue(label: "grid.reload.queue")

public enum GridError: Error {
  case message(String)
}

class AppDelegate: NSObject, NSApplicationDelegate {

	var statusBarItem: NSStatusItem!
	var statusBarMenu: NSMenu!
    var hotKeys = Array<HotKey>()
    var filewatcher: FileWatcher!
    var configPath: String!
    weak var previousAction: Action?

	func applicationDidFinishLaunching(_ notification: Notification) {

		statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
		statusBarItem.button?.image = NSImage(systemSymbolName: "square.grid.3x3.fill", accessibilityDescription: "Status bar icon")
		statusBarMenu = NSMenu()
		statusBarItem.menu = statusBarMenu
        configPath = NSString(string: "~/.grid.yaml").expandingTildeInPath
        
        
        
        if !AXIsProcessTrusted() {
            let options : NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
            let accessibilityEnabled = AXIsProcessTrustedWithOptions(options)
        
            if !accessibilityEnabled {
                print("\nACCESSIBILITY IS NOT YET GRANTED!\n")
                alertFatal("Please give Accessibility permission and relaunch Grid.app")
            }
        }
        
        loadYaml()
	}
    
    func loadYaml() {
        do {
            let bundleConfigPath = Bundle.main.url(forResource: "grid", withExtension: "yaml")!
            
            if !FileManager.default.fileExists(atPath: configPath) {
                print("Copy default config to:", configPath!)
                try FileManager.default.copyItem(at: bundleConfigPath, to: URL(fileURLWithPath: configPath))
            }
            
            filewatcher = FileWatcher([configPath])
            filewatcher.callback = { event in
                print("Something happened here: " + event.path)
                reloadConfigQueue.async {
                    self.reloadYaml()
                }
            }
            filewatcher.start()
            
            reloadConfigQueue.async {
                self.reloadYaml()
            }
            
        } catch {
            print("Unexpected error: \(error).")
            handler_quit()
        }
    }
    
    func reloadYaml() {
        self.hotKeys.removeAll()
        self.statusBarMenu.removeAllItems()
        
        do {
            print("Loading config from:", configPath!)
            let configData = try String(contentsOfFile: configPath, encoding: String.Encoding.utf8)
            let config = try Yaml.load(configData)
            for item in config["actions"].array! {
                
                var keys = Array<KeyCombo>()
                let keyString = item["key"].string
                if item["key"].string != nil {
                    keys.append(KeyCombo(string: keyString!))
                } else if item["key"].array != nil {
                    for key in item["key"].array! {
                        guard let s = key.string else { throw GridError.message("key must be a string") }
                        keys.append(KeyCombo(string: s))
                    }
                } else {
                    throw GridError.message("key must be either a string or an array of string")
                }

                var action: Action?
                let name = item["name"].string ?? ""
                
                if item["positions"].array != nil {
                    let a = ActionForemost(appDelegate: self, name: name)
                    for pos in item["positions"].array! {
                        
                        let rect = try RectOnScreen(yaml: pos)
                        a.targetRects.append(rect)
                    }
                    action = a
                } else if item["scenario"].array != nil {
                    let list = item["scenario"].array!
                    let a = ActionScenario(name: name)
                    
                    for scenarioAction in list {
                        try a.entries.append(ActionScenarioEntry(yaml: scenarioAction))
                    }
                    action = a
                } else {
                    throw GridError.message("Action has neither 'positions' nor 'apps'")
                }
                
                for (index, key) in keys.enumerated() {
                    let hk = HotKey(keyCombo: key, keyDownHandler: action!.execute)
                    self.hotKeys.append(hk)
                    
                    if index == 0 {
                        let menuItem = NSMenuItem(title: name, action: nil, keyEquivalent: key.key!.description)
                        menuItem.keyEquivalentModifierMask = hk.keyCombo.modifiers
                        self.statusBarMenu.addItem(menuItem)
                    }
                }
            }
            print("Loading config done")
        } catch GridError.message(let msg) {
            alertInfo("YAML config load error:", msg)
        } catch Yaml.ResultError.message(let msg) {
            alertInfo("YAML config load error:", msg ?? "...")
        } catch {
            alertInfo("YAML config load error:", "other error")
        }
        self.statusBarMenu.addItem(NSMenuItem.separator())
        self.statusBarMenu.addItem(withTitle: "Copy current window info", action: #selector(self.handler_info), keyEquivalent: "c")
        self.statusBarMenu.addItem(withTitle: "Quit", action: #selector(self.handler_quit), keyEquivalent: "q")
        
    }
    
    @objc func handler_quit() {
        NSApplication.shared.terminate(self)
    }
    
    @objc func handler_info() {
        guard let w = Helper.getFrontmostWindow() else {
            print("Cannot get window")
            return
        }
        
        guard let app: NSRunningApplication = NSWorkspace.shared.frontmostApplication else {
            print("Cannot get frontmostApplication")
            return
        }
        
        guard let identifier = app.bundleIdentifier else {
            print("Cannot get app.bundleIdentifier")
            return
        }
        
        print(w.getRect())
        
        let r = RectOnScreen(fromPixel: w.getRect())
        let rect = r.rect
        
        let s = String(format: "- app: '%@'\n  position: [%.4f, %.4f, %.4f, %.4f, %d]", identifier, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height, r.screenIndex+1)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(s, forType: .string)
        print(s)
    }
}

extension KeyCombo {
    init(string: String) {
        var key = string.components(separatedBy: "_")
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
        
        self.init(key: k, modifiers: modifiers)
    }
}
