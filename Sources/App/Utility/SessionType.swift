//
//  SessionType.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 5/28/17.
//
//

import Authentication

enum SessionType: String, TypesafeOptionsParameter {
    case customer
    case maker
    case anonymous
    
    static let key = "type"
    static let values = [SessionType.customer.rawValue, SessionType.maker.rawValue]
    
    static var defaultValue: SessionType? = .none
    
    var type: Authenticatable.Type {
        switch self {
        case .customer:
            return Customer.self
        case .maker:
            return Maker.self
        case .anonymous:
            // TODO : figure this out
            return Customer.self
        }
    }
}
