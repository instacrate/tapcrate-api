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

final class FluentCacheProvider: Vapor.Provider {

    static let repositoryName = "tapcrate-fluent-cache"
    
    public init(config: Config) throws { }
    
    func boot(_ config: Config) throws { }
    func boot(_ droplet: Droplet) throws { }
    
    public func beforeRun(_ drop: Droplet) {
        if let database = drop.database {
            drop.config.addConfigurable(cache: { _ in MySQLCache(database) }, name: "mysql-cache")
            drop.config.addConfigurable(middleware: { _ in SessionsMiddleware(CacheSessions(drop.cache)) }, name: "fluent-sessions")
        }
    }
}

extension Droplet {
    
    internal static func create() -> Droplet {
        
        do {
            let drop = try Droplet()
            
            try drop.config.addProvider(AuthProvider.Provider.self)
            try drop.config.addProvider(MySQLProvider.Provider.self)
            try drop.config.addProvider(FluentCacheProvider.self)
            
            drop.database?.log = { query in
                print("query : \(query)")
            }
            
            drop.config.preparations = [Product.self,
                                        Maker.self,
                                        CustomerAddress.self,
                                        Customer.self,
                                        StripeMakerCustomer.self,
                                        MakerAddress.self,
                                        Pivot<Tag, Product>.self,
                                        MakerPicture.self,
                                        CustomerPicture.self,
                                        ProductPicture.self,
                                        Tag.self,
                                        Offer.self]
            
            return drop
        } catch {
            fatalError("Failed to start with error \(error)")
        }
    }
}
