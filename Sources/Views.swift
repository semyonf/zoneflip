import SwiftUI
import ServiceManagement

let menuBarFont = NSFont.monospacedDigitSystemFont(ofSize: NSFont.menuBarFont(ofSize: 0).pointSize, weight: .regular)

/// Menu bar label. The time updates in place; switching zones flips the label over the X axis.
struct FlipLabel: View {
	@ObservedObject var rotator: Rotator

	var body: some View {
		Text(rotator.label(at: rotator.index))
			.font(Font(menuBarFont))
			.fixedSize()
			.rotation3DEffect(.degrees(rotator.angle), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
	}
}

struct SettingsView: View {
	@ObservedObject var store: Store
	private let ids = TimeZone.knownTimeZoneIdentifiers.sorted()

	// Plain stack instead of List: List is an NSTableView, which delays focusing a text field
	// on single click while it waits for a possible double click.
	var body: some View {
		VStack(alignment: .leading, spacing: 14) {
			Text("Таймзоны").font(.headline)
			ScrollView {
				VStack(alignment: .leading, spacing: 8) {
					ForEach(Array(store.zones.enumerated()), id: \.element.id) { i, zone in
						row(i, zone)
					}
				}
				.frame(maxWidth: .infinity, alignment: .leading)
			}
			.frame(minHeight: 160)
			Button("Добавить таймзону") {
				store.zones.append(Zone(identifier: TimeZone.current.identifier, prefix: ""))
			}
			Divider()
			Stepper(value: $store.interval, in: 1...120, step: 1) {
				Text("Менять каждые \(Int(store.interval)) с")
			}
			Toggle("Запускать при входе в систему", isOn: Binding(
				get: { SMAppService.mainApp.status == .enabled },
				set: { on in
					try? on ? SMAppService.mainApp.register() : SMAppService.mainApp.unregister()
					store.objectWillChange.send()
				}
			))
		}
		.padding(20)
		.frame(width: 560, height: 420)
	}

	/// Binding by zone id, so a removed row never reads a stale index.
	private func field(_ id: UUID, _ key: WritableKeyPath<Zone, String>) -> Binding<String> {
		Binding(
			get: { store.zones.first { $0.id == id }?[keyPath: key] ?? "" },
			set: { v in
				if let i = store.zones.firstIndex(where: { $0.id == id }) { store.zones[i][keyPath: key] = v }
			}
		)
	}

	private func row(_ i: Int, _ zone: Zone) -> some View {
		HStack {
			TextField("Подпись", text: field(zone.id, \.prefix))
				.frame(width: 90)
			Picker("", selection: field(zone.id, \.identifier)) {
				ForEach(ids, id: \.self) { Text($0).tag($0) }
			}
			.labelsHidden()
			.frame(width: 220, alignment: .leading)
			Text(Rotator.label(zone, Date()))
				.monospacedDigit()
				.foregroundStyle(.secondary)
				.frame(width: 100, alignment: .trailing)
			Button { store.zones.swapAt(i, i - 1) } label: { Image(systemName: "chevron.up") }
				.disabled(i == 0)
			Button { store.zones.swapAt(i, i + 1) } label: { Image(systemName: "chevron.down") }
				.disabled(i == store.zones.count - 1)
			Button { store.zones.remove(at: i) } label: { Image(systemName: "minus.circle") }
		}
		.buttonStyle(.borderless)
	}
}
