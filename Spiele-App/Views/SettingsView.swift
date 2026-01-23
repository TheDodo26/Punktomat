//
//  SettingsView.swift
//  Spiele-App
//

import SwiftUI





struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: - Appearance Settings

    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("accentColorName") private var accentColorName: String = AccentColor.blue.rawValue
    @AppStorage("useNumberPad") var useNumberPad: Bool = true

    // MARK: - Developer Debug Settings

    @AppStorage("debugMode") private var debugMode = false
    @AppStorage("disableAnimations") private var disableAnimations = false
    @AppStorage("showLayoutBounds") private var showLayoutBounds = false
    @AppStorage("debugExportPreview") private var debugExportPreview = false

    // MARK: - Reset Alert

    @State private var showResetAlert = false

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
#if DEBUG
                developerSection
#else
                developerSection
#endif
                appInfoSection
            }
            .navigationTitle("Einstellungen")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(appearanceMode.colorScheme)
        .tint(AccentColor(rawValue: accentColorName)?.color ?? .blue)
        .alert("Alle Tabellen löschen?", isPresented: $showResetAlert) {
            Button("Abbrechen", role: .cancel) {}
            Button("Löschen", role: .destructive) {
                resetAllTables()
            }
        } message: {
            Text("Diese Aktion kann nicht rückgängig gemacht werden.")
        }
    }

    // MARK: - Sections

    private var appearanceSection: some View {
        Section("Darstellung") {
            Picker("Modus", selection: $appearanceMode) {
                ForEach(AppearanceMode.allCases) {
                    Text($0.title).tag($0)
                }
            }
            .pickerStyle(.segmented)

            Picker("Akzentfarbe", selection: $accentColorName) {
                ForEach(AccentColor.allCases) {
                    Label($0.title, systemImage: "circle.fill")
                        .foregroundStyle($0.color)
                        .tag($0.rawValue)
                }
            }
            Toggle("Nur Zahlen (NumberPad)", isOn: $useNumberPad)
        }
    }

    private var appInfoSection: some View {
        Section("App") {
            Text("Version 0.2.1")
        }
    }

    private var developerSection: some View {
        Section("Developer") {
            

            Toggle("Debug-Modus", isOn: $debugMode)

            if debugMode {
                Toggle("Animationen deaktivieren", isOn: $disableAnimations)
                Toggle("Layout-Grenzen anzeigen", isOn: $showLayoutBounds)
                Toggle("Export-Preview aktivieren", isOn: $debugExportPreview)

                Button("Demo-Daten erzeugen") {
                    createDemoData()
                }

                Button("UserDefaults loggen") {
                    logUserDefaults()
                }

                Button("App-Zustand komplett resetten", role: .destructive) {
                    resetAppCompletely()
                }

                Button("Test-Crash auslösen", role: .destructive) {
                    fatalError("Debug Crash ausgelöst")
                }
            }
            
            Button(role: .destructive) {
                showResetAlert = true
            } label: {
                Text("Alle Tabellen zurücksetzen")
            }
        }
    }

    // MARK: - Actions

    private func resetAllTables() {
        UserDefaults.standard.removeObject(forKey: "tables")

        let defaults = UserDefaults.standard.dictionaryRepresentation().keys
        for key in defaults where key.hasPrefix("columns_") {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }

// MARK: - Debug Helpers

private func logUserDefaults() {
    print("=== UserDefaults ===")
    for (key, value) in UserDefaults.standard.dictionaryRepresentation() {
        print("\(key): \(value)")
    }
}

private func resetAppCompletely() {
    guard let bundleID = Bundle.main.bundleIdentifier else { return }
    UserDefaults.standard.removePersistentDomain(forName: bundleID)
}

private func createDemoData() {
    let tables: [Table] = [
        Table(name: "Spielabend", columns: 3, type: .standard, startValue: 0),
        Table(name: "Countdown-Test", columns: 2, type: .countdown, startValue: 100)
    ]

    UserDefaultsStore.save(tables, key: "tables")

    for table in tables {
        let columns = (1...table.columns).map { index in
            ColumnData(
                name: "Spalte \(index)",
                values: (1...5).map { _ in Double.random(in: 1...20) }
            )
        }
        UserDefaultsStore.save(columns, key: "columns_\(table.id.uuidString)")
    }
}
}

// MARK: - Appearance Mode

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Hell"
        case .dark: return "Dunkel"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Accent Color

enum AccentColor: String, CaseIterable, Identifiable {
    case blue
    case red
    case green
    case orange
    case purple

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .blue: return .blue
        case .red: return .red
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        }
    }
}

#Preview {
    SettingsView()
}
