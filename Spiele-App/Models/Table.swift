//
//  Table.swift
//  Spiele-App
//
//  Created by David Orban on 21.01.26.
//

import Foundation

struct Table: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    let columns: Int
    let type: TableType
    let startValue: Double

    init(
        id: UUID = UUID(),
        name: String,
        columns: Int,
        type: TableType,
        startValue: Double
    ) {
        self.id = id
        self.name = name
        self.columns = columns
        self.type = type
        self.startValue = startValue
    }
}
