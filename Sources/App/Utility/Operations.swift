//
//  Operations.swift
//  App
//
//  Created by Hakon Hanesand on 6/10/17.
//

import Foundation

extension Sequence where Iterator.Element: Hashable {
    func unique() -> [Iterator.Element] {
        var seen: [Iterator.Element: Bool] = [:]
        return self.filter { seen.updateValue(true, forKey: $0) == nil }
    }
}

public extension Sequence {
    func group<U>(by key: (Iterator.Element) -> U) -> [U : [Iterator.Element]] {
        var categories: [U: [Iterator.Element]] = [:]
        for element in self {
            let key = key(element)
            if case nil = categories[key]?.append(element) {
                categories[key] = [element]
            }
        }
        return categories
    }
}

func merge<K, V>(keys: [K], with values: [V]) -> [K: V] {
    var dictionary: [K: V] = [:]

    zip(keys, values).forEach { (arg) in
        let (key, value) = arg
        dictionary[key] = value
    }

    return dictionary
}
