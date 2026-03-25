import Foundation
import AppKit

final class GlobalHotkeyService: ObservableObject {
    static let shared = GlobalHotkeyService()

    @Published var isEnabled = false

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    struct Hotkey: Identifiable, Hashable {
        let id: String
        let keyCode: UInt16
        let modifiers: UInt32

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        static func == (lhs: Hotkey, rhs: Hotkey) -> Bool {
            lhs.id == rhs.id
        }
    }

    private static var hotkeys: [Hotkey] = []
    private static var hotkeyActions: [String: () -> Void] = [:]

    private init() {}

    func register(hotkey: Hotkey, action: @escaping () -> Void) {
        Self.hotkeys.removeAll { $0.id == hotkey.id }
        Self.hotkeys.append(hotkey)
        Self.hotkeyActions[hotkey.id] = action
    }

    func unregister(id: String) {
        Self.hotkeys.removeAll { $0.id == id }
        Self.hotkeyActions.removeValue(forKey: id)
    }

    func start() {
        guard eventTap == nil else { return }

        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, userInfo) -> Unmanaged<CGEvent>? in
                let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
                let flags = event.flags
                let modifiers = GlobalHotkeyService.convertModifiers(flags)

                let currentHotkeys = GlobalHotkeyService.hotkeys
                for hotkey in currentHotkeys {
                    if hotkey.keyCode == keyCode && hotkey.modifiers == modifiers {
                        if let action = GlobalHotkeyService.hotkeyActions[hotkey.id] {
                            DispatchQueue.main.async {
                                action()
                            }
                        }
                        return nil
                    }
                }

                return Unmanaged.passRetained(event)
            },
            userInfo: nil
        )

        guard let tap = eventTap else { return }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        isEnabled = true
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        isEnabled = false
    }

    private static func convertModifiers(_ flags: CGEventFlags) -> UInt32 {
        var modifiers: UInt32 = 0
        if flags.contains(.maskCommand) { modifiers |= 1 << 0 }
        if flags.contains(.maskShift) { modifiers |= 1 << 1 }
        if flags.contains(.maskControl) { modifiers |= 1 << 2 }
        if flags.contains(.maskAlternate) { modifiers |= 1 << 3 }
        return modifiers
    }

    static let MOD_CMD: UInt32 = 1 << 0
    static let MOD_SHIFT: UInt32 = 1 << 1
    static let MOD_CONTROL: UInt32 = 1 << 2
    static let MOD_OPTION: UInt32 = 1 << 3
}
