import Foundation
import Combine
import SwiftUI

struct Zone: Codable, Identifiable, Hashable {
	var id = UUID()
	var identifier: String
	var prefix: String
}

/// Settings persisted in UserDefaults.
final class Store: ObservableObject {
	@Published var zones: [Zone] { didSet { save() } }
	@Published var interval: Double { didSet { defaults.set(interval, forKey: "interval") } }

	private let defaults = UserDefaults.standard

	init() {
		if let data = defaults.data(forKey: "zones"),
		   let saved = try? JSONDecoder().decode([Zone].self, from: data) {
			zones = saved
		} else {
			zones = [
				Zone(identifier: "UTC", prefix: "UTC"),
				Zone(identifier: "America/New_York", prefix: "NY"),
				Zone(identifier: "Asia/Tokyo", prefix: "TYO"),
			]
		}
		let i = defaults.double(forKey: "interval")
		interval = i > 0 ? i : 5
	}

	private func save() {
		if let data = try? JSONEncoder().encode(zones) {
			defaults.set(data, forKey: "zones")
		}
	}
}

/// Current time and which zone is on screen.
final class Rotator: ObservableObject {
	@Published private(set) var index = 0 // zone currently on screen
	@Published private(set) var angle = 0.0 // flip rotation of the label
	@Published private(set) var now = Date()

	let store: Store
	private var rotateTimer: Timer?
	private var clockTimer: Timer?
	private var bag = Set<AnyCancellable>()

	init(store: Store) {
		self.store = store
		clockTimer = Self.schedule(every: 1) { [weak self] in self?.now = Date() }
		store.$interval.removeDuplicates().sink { [weak self] in self?.restart(interval: $0) }.store(in: &bag)
		store.$zones.sink { [weak self] zones in
			guard let self else { return }
			if index >= zones.count { index = 0 }
		}.store(in: &bag)
	}

	func label(at i: Int) -> String {
		let zones = store.zones
		guard !zones.isEmpty else { return "Нет зон" }
		return Self.label(zones[i % zones.count], now)
	}

	static func label(_ zone: Zone, _ date: Date) -> String {
		let f = DateFormatter()
		f.timeZone = TimeZone(identifier: zone.identifier)
		f.setLocalizedDateFormatFromTemplate("jmm") // follows the system 12/24h setting
		let time = f.string(from: date)
		return zone.prefix.isEmpty ? time : "\(zone.prefix) \(time)"
	}

	private func restart(interval: Double) {
		rotateTimer?.invalidate()
		rotateTimer = Self.schedule(every: interval) { [weak self] in
			guard let self, store.zones.count > 1 else { return }
			flip()
		}
	}

	/// Rotate the label away, swap the zone while it is edge-on, rotate it back.
	private func flip() {
		withAnimation(.easeIn(duration: 0.16)) { angle = 90 } completion: { [self] in
			index = (index + 1) % max(store.zones.count, 1)
			angle = -90
			withAnimation(.easeOut(duration: 0.16)) { angle = 0 }
		}
	}

	private static func schedule(every s: Double, _ block: @escaping () -> Void) -> Timer {
		let t = Timer(timeInterval: s, repeats: true) { _ in block() }
		RunLoop.main.add(t, forMode: .common) // keep ticking while the menu is open
		return t
	}
}
