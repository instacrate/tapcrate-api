//
//  AddTimestampableToAllEntities.swift
//  App
//
//  Created by Hakon Hanesand on 6/12/17.
//

import Fluent

struct AddTimestampableToAllEntities: Preparation {

    static func revert(_ database: Database) throws {
        try database.modify(Review.self, closure: { (review) in
            review.string("author")
        })
    }

    static func prepare(_ database: Database) throws {

    }
}
