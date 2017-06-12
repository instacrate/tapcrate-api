//
//  Droplet+Init.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/28/16.
//
//

import Vapor
import Sessions
import MySQLProvider
import Fluent
import FluentProvider
import HTTP
import Console
import MySQLProvider
import AuthProvider
import Sessions
import Cookies
import Foundation

final class FluentCacheProvider: Vapor.Provider {
    
    static let repositoryName = "tapcrate-fluent-cache"
    
    public init(config: Config) throws { }
    
    func boot(_ config: Config) throws {
        let cache = try config.resolveCache()
        
        config.addConfigurable(middleware: { _ in
            return SessionsMiddleware(CacheSessions(cache), cookieFactory: { (request) -> Cookie in
                return Cookie(name: "vapor-session", value: "", httpOnly: true)
            })
        }, name: "fluent-sessions")
    }
    
    func boot(_ droplet: Droplet) throws { }
    
    public func beforeRun(_ drop: Droplet) {
        
    }
}

extension Droplet {
    
    internal static func create() -> Droplet {
        
        do {
            let config = try Config()

            try config.addProvider(AuthProvider.Provider.self)
            try config.addProvider(MySQLProvider.Provider.self)

            config.addConfigurable(cache: MySQLCache.init, name: "mysql-cache")
            config.addConfigurable(middleware: CustomErrorMiddleware.init, name: "allError")

            try config.addProvider(FluentCacheProvider.self)
        
            config.preparations += [
                Maker.self,
                MakerAddress.self,
                MakerPicture.self,

                Customer.self,
                CustomerAddress.self,
                CustomerPicture.self,
                StripeMakerCustomer.self,

                Product.self,
                ProductPlan.self,
                ProductPicture.self,
                Variant.self,

                Tag.self,
                Pivot<Tag, Product>.self,

                Order.self,
                Offer.self,
                Subscription.self,
                MySQLCache.MySQLCacheEntity.self,

                Pivot<Offer, Customer>.self,

                PageView.self,
                Review.self,

                AddTimestampableToAllEntities.self
            ] as [Preparation.Type]

            let drop = try Droplet(config)
            
            drop.database?.log = { query in
                print("query : \(query)")
            }
            
            return drop
        } catch let error as NSError {
            fatalError("Failed to start with error \(error.localizedDescription) \(error.userInfo)")
        } catch {
            fatalError("Failed to start with error : \(error)")
        }
    }
}
