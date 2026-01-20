//
//  ContentView.swift
//  Spiele-App
//
//  Created by David Orban on 20.01.26.
//

import SwiftUI

// MARK: - Model

struct Table: Identifiable, Hashable, Codable {
    let id = UUID()
    let name: String
    let columns: Int
    let type: AddTableView.TableType
    let startValue: Double
}

// MARK: - ContentView

struct ContentView: View {
    @State private var tables: [Table] = UserDefaults.standard.data(forKey: "tables").flatMap {
        try? JSONDecoder().decode([Table].self, from: $0)
    } ?? []
    @State private var showAddTable = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(tables) { table in
                    NavigationLink(destination: TableDetailView(table: table)) {
                        VStack(alignment: .leading) {
                            Text(table.name)
                            Text("Spalten: \(table.columns)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    tables.remove(atOffsets: indexSet)
                }
            }
            .navigationTitle("Tabellen")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddTable = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddTable) {
                AddTableView { name, columns, type, startValue in
                    tables.append(Table(name: name, columns: columns, type: type, startValue: startValue))
                }
            }
        }
        .onChange(of: tables) { newTables in
            if let data = try? JSONEncoder().encode(newTables) {
                UserDefaults.standard.set(data, forKey: "tables")
            }
        }
    }
}

// MARK: - Add Table Sheet

struct AddTableView: View {
    enum TableType: String, CaseIterable, Identifiable, Codable {
        case standard = "Standard"
        case countdown = "Countdown"
        
        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var columns: Int = 2
    @State private var tableType: TableType = .standard
    @State private var startValue: Double = 100

    let onAdd: (String, Int, TableType, Double) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Name der Tabelle") {
                    TextField("z. B. Spielabend", text: $name)
                }

                Section("Anzahl Spalten") {
                    Stepper("\(columns) Spalten", value: $columns, in: 1...10)
                }
                
                Section("Tabellentyp") {
                    Picker("Typ", selection: $tableType) {
                        ForEach(TableType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                if tableType == .countdown {
                    Section("Startwert") {
                        TextField("Startwert", value: $startValue, format: .number)
                            .keyboardType(.numbersAndPunctuation)
                    }
                }
            }
            .navigationTitle("Neue Tabelle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Erstellen") {
                        guard !name.isEmpty else { return }
                        onAdd(name, columns, tableType, startValue)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Table Detail View

struct TableDetailView: View {
    let table: Table

    // One storage key per table
    private var storageKey: String {
        "columns_\(table.id.uuidString)"
    }

    // Each column has a name and its own values
    struct ColumnData: Codable, Identifiable, Equatable {
        var id = UUID()
        var name: String
        var values: [Double]
    }

    @State private var columns: [ColumnData] = []
    @State private var newValue: String = ""
    @State private var selectedColumnIndex: Int = 0
    @State private var remainingValues: [Double] = []
    @State private var keyboardHeight: CGFloat = 0

    init(table: Table) {
        self.table = table
        if table.type == .countdown {
            _remainingValues = State(initialValue: [])
        } else {
            _remainingValues = State(initialValue: [])
        }
    }

    private func sum(for column: ColumnData) -> Double {
        column.values.reduce(0, +)
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 16) {
                    if columns.isEmpty {
                        ProgressView()
                    } else {
                        // Horizontal ScrollView for columns
                        ScrollView(.horizontal, showsIndicators: true) {
                            HStack(alignment: .top, spacing: 16) {
                                ForEach($columns.indices, id: \.self) { index in
                                    if table.type == .countdown {
                                        VStack(alignment: .leading, spacing: 8) {
                                            // Editable column name
                                            TextField("Spaltenname", text: $columns[index].name)
                                                .font(.headline)
                                                .textFieldStyle(.roundedBorder)
                                            
                                            // ScrollView for values with delete button
                                            ScrollView {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    ForEach(columns[index].values.indices, id: \.self) { valueIndex in
                                                        HStack {
                                                            Text("\(columns[index].values[valueIndex], format: .number)")
                                                            Spacer()
                                                            Button(action: {
                                                                columns[index].values.remove(at: valueIndex)
                                                                // Update remaining value after deletion
                                                                let sumValues = columns[index].values.reduce(0, +)
                                                                remainingValues[index] = max(table.startValue - sumValues, 0)
                                                            }) {
                                                                Image(systemName: "trash")
                                                                    .foregroundStyle(.red)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            .frame(height: 200)
                                            
                                            // Remaining value for this column
                                            Text("Verbleibend: \(remainingValues.indices.contains(index) ? remainingValues[index] : table.startValue, format: .number)")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding()
                                        .frame(minWidth: 150)
                                        .background(.thinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                    } else {
                                        ColumnView(column: $columns[index])
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Divider()
                            .padding(.vertical)
                        
                        // Input section for adding new values
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Neuen Wert hinzufügen")
                                .font(.headline)
                            
                            Picker(selection: $selectedColumnIndex, label: Text("Spalte")) {
                                ForEach(columns.indices, id: \.self) { index in
                                    Text(columns[index].name).tag(index)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            HStack {
                                TextField("Wert eingeben", text: $newValue)
                                    .keyboardType(.numbersAndPunctuation)
                                    .textFieldStyle(.roundedBorder)
                                    .autocorrectionDisabled(true)
                                    .textInputAutocapitalization(.never)
                                    .onSubmit {
                                        if let value = Double(newValue.replacingOccurrences(of: ",", with: ".")) {
                                            if table.type == .countdown {
                                                if remainingValues.indices.contains(selectedColumnIndex) {
                                                    let newRemaining = max(remainingValues[selectedColumnIndex] - value, 0)
                                                    if newRemaining >= 0 {
                                                        columns[selectedColumnIndex].values.append(value)
                                                        remainingValues[selectedColumnIndex] = newRemaining
                                                    }
                                                }
                                            } else {
                                                columns[selectedColumnIndex].values.append(value)
                                            }
                                            newValue = ""
                                        }
                                    }
                                
                                Button("Hinzufügen") {
                                    if let value = Double(newValue.replacingOccurrences(of: ",", with: ".")) {
                                        if table.type == .countdown {
                                            if remainingValues.indices.contains(selectedColumnIndex) {
                                                let newRemaining = max(remainingValues[selectedColumnIndex] - value, 0)
                                                if newRemaining >= 0 {
                                                    columns[selectedColumnIndex].values.append(value)
                                                    remainingValues[selectedColumnIndex] = newRemaining
                                                }
                                            }
                                        } else {
                                            columns[selectedColumnIndex].values.append(value)
                                        }
                                        newValue = ""
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .id("inputField")
                    }
                }
                .padding(.top)
            }
            .padding(.bottom, keyboardHeight)
            .onAppear { loadColumns() }
            .onChange(of: columns) { newColumns in saveColumns(newColumns) }
            .navigationTitle(table.name)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                    withAnimation {
                        proxy.scrollTo("inputField", anchor: .bottom)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                keyboardHeight = 0
            }
            // --- Toolbar for keyboard dismiss button ---
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fertig") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil,
                            from: nil,
                            for: nil
                        )
                    }
                }
            }
        }
    }


    // MARK: - Persistence

    private func loadColumns() {
        if
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([ColumnData].self, from: data)
        {
            columns = decoded
            selectedColumnIndex = 0
            if table.type == .countdown {
                remainingValues = columns.map { _ in table.startValue }
                for (index, column) in columns.enumerated() {
                    let sumValues = column.values.reduce(0, +)
                    remainingValues[index] = max(table.startValue - sumValues, 0)
                }
            }
        } else {
            // Initial setup with default column names
            columns = (1...table.columns).map {
                ColumnData(name: "Spalte \($0)", values: [])
            }
            selectedColumnIndex = 0
            if table.type == .countdown {
                remainingValues = Array(repeating: table.startValue, count: table.columns)
            }
        }
    }

    private func saveColumns(_ columns: [ColumnData]) {
        if let data = try? JSONEncoder().encode(columns) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}



struct ColumnView: View {
    @Binding var column: TableDetailView.ColumnData

    var body: some View {
        let sum = column.values.reduce(0, +)

        VStack(alignment: .leading, spacing: 8) {
            TextField("Spaltenname", text: $column.name)
                .font(.headline)
                .textFieldStyle(.roundedBorder)

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(column.values.indices, id: \.self) { index in
                        HStack {
                            Text("\(column.values[index], format: .number)")
                            Spacer()
                            Button(action: {
                                column.values.remove(at: index)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                }
            }
            .frame(height: 200)

            Text("Summe: \(sum, format: .number)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(minWidth: 150)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
// MARK: - Preview

#Preview {
    ContentView()
}
