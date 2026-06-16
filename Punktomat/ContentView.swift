//
//  ContentView.swift
//  Punktomat
//
//  Created by David Orban on 20.01.26.
//

import SwiftUI

struct ContentView: View {
    @State private var tables: [Table] = UserDefaultsStore.load("tables") ?? []
    @State private var showAddTable = false
    @State private var showSettings = false
    @State private var tableToDelete: Table? = nil
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(tables) { table in
                    NavigationLink {
                        TableDetailView(table: table) {
                            duplicate(table: table)
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(table.name)
                            Text("Spalten: \(table.columns)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            tableToDelete = table
                            showDeleteConfirmation = true
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }

                        Button {
                            duplicate(table: table)
                        } label: {
                            Label("Duplizieren", systemImage: "doc.on.doc")
                        }
                        .tint(.blue)

                        Button {
                            editTitle(for: table)
                        } label: {
                            Label("Bearbeiten", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
                }
                .onDelete { tables.remove(atOffsets: $0) }
            }
            .alert("Tabellen löschen?", isPresented: $showDeleteConfirmation, presenting: tableToDelete) { table in
                Button("Abbrechen", role: .cancel) {}
                Button("Löschen", role: .destructive) {
                    if let index = tables.firstIndex(where: { $0.id == table.id }) {
                        tables.remove(at: index)
                    }
                }
            } message: { table in
                Text("Willst du die Tabelle „\(table.name)“ wirklich löschen?")
            }
            .navigationTitle("Tabellen")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddTable = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddTable) {
                AddTableView { table in
                    tables.append(table)
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
        .onChange(of: tables) {
            UserDefaultsStore.save(tables, key: "tables")
        }
    }
}

private extension ContentView {
    private func duplicate(table: Table) {
        let newTable = Table(
            id: UUID(),
            name: table.name + " Kopie",
            columns: table.columns, type: table.type,
            startValue: table.startValue
        )
        tables.append(newTable)
    }
    
    private func editTitle(for table: Table) {
        guard let index = tables.firstIndex(where: { $0.id == table.id }) else { return }

        let alert = UIAlertController(title: "Tabellenname bearbeiten", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = tables[index].name
        }
        alert.addAction(UIAlertAction(title: "Abbrechen", style: .cancel))
        alert.addAction(UIAlertAction(title: "Speichern", style: .default) { _ in
            if let newName = alert.textFields?.first?.text, !newName.isEmpty {
                tables[index].name = newName
            }
        })

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = scene.windows.first(where: \.isKeyWindow)?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
}



#Preview {
    ContentView()
}
