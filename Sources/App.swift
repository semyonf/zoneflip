import AppKit
import SwiftUI
import Combine

/// Hosting view that lets clicks fall through to the status bar button.
final class PassthroughHostingView<V: View>: NSHostingView<V> {
	override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
	let store = Store()
	lazy var rotator = Rotator(store: store)
	var statusItem: NSStatusItem!
	var settingsWindow: NSWindow?
	var bag = Set<AnyCancellable>()

	func applicationDidFinishLaunching(_ note: Notification) {
		NSApp.mainMenu = Self.mainMenu()
		statusItem = NSStatusBar.system.statusItem(withLength: 60)
		let button = statusItem.button!
		let host = PassthroughHostingView(rootView: FlipLabel(rotator: rotator))
		host.translatesAutoresizingMaskIntoConstraints = false
		button.addSubview(host)
		NSLayoutConstraint.activate([
			host.leadingAnchor.constraint(equalTo: button.leadingAnchor),
			host.trailingAnchor.constraint(equalTo: button.trailingAnchor),
			host.topAnchor.constraint(equalTo: button.topAnchor),
			host.bottomAnchor.constraint(equalTo: button.bottomAnchor),
		])

		let menu = NSMenu()
		menu.delegate = self
		statusItem.menu = menu

		// Fixed width = widest label, so the item does not jump between zones.
		rotator.$now.combineLatest(store.$zones)
			.sink { [weak self] now, zones in self?.updateWidth(now, zones) }
			.store(in: &bag)
	}

	/// A menu-bar-only app has no main menu, so text fields get no ⌘C/⌘V/⌘X/⌘A/⌘Z.
	/// The menu is never shown, but its key equivalents still reach the settings window.
	static func mainMenu() -> NSMenu {
		let edit = NSMenu(title: "Edit")
		edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
		edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
		edit.addItem(.separator())
		edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
		edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
		edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
		edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
		edit.addItem(.separator())
		let emoji = edit.addItem(withTitle: "Emoji & Symbols", action: #selector(NSApplication.orderFrontCharacterPalette(_:)), keyEquivalent: " ")
		emoji.keyEquivalentModifierMask = [.control, .command]

		let window = NSMenu(title: "Window")
		window.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")

		let main = NSMenu()
		for sub in [NSMenu(title: "ZoneFlip"), edit, window] { // the first submenu is the app menu
			let item = NSMenuItem()
			item.submenu = sub
			main.addItem(item)
		}
		return main
	}

	func updateWidth(_ now: Date, _ zones: [Zone]) {
		let labels = zones.isEmpty ? ["Нет зон"] : zones.map { Rotator.label($0, now) }
		let w = labels.map { ($0 as NSString).size(withAttributes: [.font: menuBarFont]).width }.max() ?? 40
		let len = ceil(w) + 12
		if statusItem.length != len { statusItem.length = len }
	}

	func menuNeedsUpdate(_ menu: NSMenu) {
		menu.removeAllItems()
		let now = Date()
		for zone in store.zones {
			let name = TimeZone(identifier: zone.identifier)?.localizedName(for: .generic, locale: .current) ?? zone.identifier
			let item = NSMenuItem(title: "\(Rotator.label(zone, now))   \(name)", action: nil, keyEquivalent: "")
			item.isEnabled = false
			menu.addItem(item)
		}
		menu.addItem(.separator())
		menu.addItem(withTitle: "Настройки…", action: #selector(openSettings), keyEquivalent: ",").target = self
		menu.addItem(withTitle: "Выйти", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
	}

	@objc func openSettings() {
		if settingsWindow == nil {
			let w = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(store: store)))
			w.title = "ZoneFlip"
			w.styleMask = [.titled, .closable]
			w.isReleasedWhenClosed = false
			w.center()
			settingsWindow = w
		}
		NSApp.activate()
		settingsWindow?.makeKeyAndOrderFront(nil)
	}
}

@main
enum Main {
	static let delegate = AppDelegate()
	static func main() {
		let app = NSApplication.shared
		app.setActivationPolicy(.accessory)
		app.delegate = delegate
		app.run()
	}
}
