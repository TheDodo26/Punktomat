//
//  ColumnData.swift
//  Punktomat
//
//  Created by David Orban on 21.01.26.
//

import Foundation

struct ColumnData: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var values: [Double]

    init(
        id: UUID = UUID(),
        name: String,
        values: [Double] = []
    ) {
        self.id = id
        self.name = name
        self.values = values
    }
}
