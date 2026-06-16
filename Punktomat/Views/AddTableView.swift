//
//  AddTableView.swift
//  Spiele-App
//
//  Created by David Orban on 21.01.26.
//

import SwiftUI

struct AddTableView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var columns = 2
    @State private var type: TableType = .standard
    @State private var startValue = 100.0

    let onAdd: (Table) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("z. B. Spielabend", text: $name)
                }

                Section("Spalten") {
                    Stepper("\(columns)", value: $columns, in: 1...10)
                }

                Section("Typ") {
                    Picker("Typ", selection: $type) {
                        ForEach(TableType.allCases) {
                            Text($0.rawValue).tag($0)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                if type == .countdown {
                    Section("Startwert") {
                        TextField("Startwert", value: $startValue, format: .number)
                            .keyboardType(.numbersAndPunctuation)
                    }
                }
            }
            .navigationTitle("Neue Tabelle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Erstellen") {
                        guard !name.isEmpty else { return }
                        onAdd(
                            Table(
                                name: name,
                                columns: columns,
                                type: type,
                                startValue: startValue
                            )
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}



#Preview {
    ContentView()
}
