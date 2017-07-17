//
//  Sort.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 7/3/17.
//

import Vapor
import HTTP
import Fluent
import FluentProvider

enum Sort: String, TypesafeOptionsParameter {

    case alpha
    case price
    case new
    case none

    static let key = "sort"
    static let values = [Sort.alpha.rawValue, Sort.new.rawValue, Sort.price.rawValue, Sort.none.rawValue]
    static let defaultValue: Sort? = Sort.none

    var field: String {
        switch self {
        case .alpha:
            return "name"
        case .price:
            return "fullPrice"
        case .new:
            // TODO : hacky
            return "id"
        case .none:
            return ""
        }
    }

    func modify<T>(_ query: Query<T>) throws -> Query<T> {
        if self == .none {
            return query
        }

        return try query.sort(field, .ascending)
    }
}
