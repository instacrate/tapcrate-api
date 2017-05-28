//
//  StripeCollection+DataManipulation.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 5/28/17.
//
//

import Node

extension Sequence where Iterator.Element == (String, String) {
    
    func reduceDictionary() -> [String : String] {
        return flatMap { $0 }.reduce([:]) { (_dict, tuple) in
            var dict = _dict
            dict.updateValue(tuple.1, forKey: tuple.0)
            return dict
        }
    }
}

fileprivate func stripeKeyPathFor(base: String, appending: String) -> String {
    if base.characters.count == 0 {
        return appending
    }
    
    return "\(base)[\(appending)]"
}

extension StructuredData {
    
    func collected() throws -> [String : String] {
        let leaves = collectLeaves(prefix: "")
        return leaves.reduceDictionary()
    }
    
    private func collectLeaves(prefix: String) -> [(String, String)] {
        switch self {
        case let .array(nodes):
            return nodes.map { $0.collectLeaves(prefix: prefix) }.joined().array
            
        case let .object(object):
            return object.map { (key: String, value: StructuredData) -> [(String, String)] in
                let prefix = stripeKeyPathFor(base: prefix, appending: key)
                return value.collectLeaves(prefix: prefix)
                }.joined().array
            
        case .bool(_), .bytes(_), .string(_), .number(_), .date(_):
            return [(prefix, string ?? "")]
            
        case .null:
            return []
        }
    }
}
