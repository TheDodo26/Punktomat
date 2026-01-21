//
//  ContentView.swift
//  Spiele-App
//
//  Created by David Orban on 20.01.26.
//

import SwiftUI

struct ContentView: View {
    @State private var tables: [Table] =
        UserDefaultsStore.load("tables") ?? []

    @State private var showAddTable = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(tables) { table in
                    NavigationLink {
                        TableDetailView(table: table)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(table.name)
                            Text("Spalten: \(table.columns)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { tables.remove(atOffsets: $0) }
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
            UserDefaultsStore.save($0, key: "tables")
        }
    }
}



#Preview {
    ContentView()
}
