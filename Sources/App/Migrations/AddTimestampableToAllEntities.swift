//
//  AddTimestampableToAllEntities.swift
//  App
//
//  Created by Hakon Hanesand on 6/12/17.
//

import Fluent

struct AddTimestampableToAllEntities: Preparation {

    static func revert(_ database: Database) throws {

    }

    static func prepare(_ database: Database) throws {

        try? database.modify(Customer.self) { builder in
            builder.date(Customer.createdAtKey)
            builder.date(Customer.updatedAtKey)
        }
        try? database.modify(CustomerAddress.self) { builder in
            builder.date(CustomerAddress.createdAtKey)
            builder.date(CustomerAddress.updatedAtKey)
        }
        try? database.modify(Maker.self) { builder in
            builder.delete("createdOn")
            builder.date(Maker.createdAtKey)
            builder.date(Maker.updatedAtKey)
        }
        try? database.modify(Offer.self) { builder in
            builder.date(Offer.createdAtKey)
            builder.date(Offer.updatedAtKey)
        }
        try? database.modify(PageView.self) { builder in
            builder.date(PageView.createdAtKey)
            builder.date(PageView.updatedAtKey)
        }
        try? database.modify(CustomerPicture.self) { builder in
            builder.date(CustomerPicture.createdAtKey)
            builder.date(CustomerPicture.updatedAtKey)
        }
        try? database.modify(MakerPicture.self) { builder in
            builder.date(MakerPicture.createdAtKey)
            builder.date(MakerPicture.updatedAtKey)
        }
        try? database.modify(ProductPicture.self) { builder in
            builder.date(ProductPicture.createdAtKey)
            builder.date(ProductPicture.updatedAtKey)
        }
        try? database.modify(Product.self) { builder in
            builder.delete("created")
            builder.date(Product.createdAtKey)
            builder.date(Product.updatedAtKey)
        }
        try? database.modify(Review.self) { builder in
            builder.delete("date")
            builder.date(Review.createdAtKey)
            builder.date(Review.updatedAtKey)
        }
        try? database.modify(Subscription.self) { builder in
            builder.date(Subscription.createdAtKey)
            builder.date(Subscription.updatedAtKey)
        }
        try? database.modify(Tag.self) { builder in
            builder.date(Tag.createdAtKey)
            builder.date(Tag.updatedAtKey)
        }
        try? database.modify(Variant.self) { builder in
            builder.date(Variant.createdAtKey)
            builder.date(Variant.updatedAtKey)
        }
    }
}
