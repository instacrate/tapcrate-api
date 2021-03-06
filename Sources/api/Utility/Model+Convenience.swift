//
//  Model+Convenience.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 4/10/17.
//
//

import HTTP
import Vapor
import Fluent
import FluentProvider

extension Entity {
    
    func throwableId() throws -> Int {
        guard let id = id else {
            throw Abort.custom(status: .internalServerError, message: "Bad internal state. \(type(of: self).entity) does not have database id when it was requested.")
        }
        
        guard let customerIdInt = id.int else {
            throw Abort.custom(status: .internalServerError, message: "Bad internal state. \(type(of: self).entity) has database id but it was of type \(id.wrapped.type) while we expected number.int")
        }
        
        return customerIdInt
    }
    
    func id() throws -> Identifier {
        guard let id = id else {
            throw Abort.custom(status: .internalServerError, message: "Bad internal state. \(type(of: self).entity) does not have database id when it was requested.")
        }
        
        return id
    }
}
