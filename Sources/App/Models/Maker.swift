//
//  Maker.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent
import FluentProvider
import BCrypt
import Foundation
import Node
import AuthProvider
import HTTP

enum ApplicationState: String, NodeConvertible {
    
    case none = "none"
    case recieved = "recieved"
    case rejected = "rejected"
    case accepted = "accepted"
    
    init(node: Node) throws {
        
        guard let state = node.string.flatMap ({ ApplicationState(rawValue: $0) }) else {
            throw Abort.custom(status: .badRequest, message: "Invalid value for application state.")
        }
        
        self = state
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return .string(rawValue)
    }
}

final class Maker: Model, Preparation, NodeConvertible, Sanitizable, JWTInitializable, SessionPersistable {
    
    static func createMaker(from request: Request) throws -> Maker {
        guard let node = request.json?.node else {
            throw Abort.custom(status: .badRequest, message: "Missing JSON body.")
        }
        
        let maker: Maker = try request.extractModel()
        try maker.save()
        
        if var addressNode: Node = try node.extract("address") {
            addressNode.context = try ParentContext(id: maker.id)
            let makerAddress = try MakerAddress(node: addressNode)
            try makerAddress.save()
        }
        
        return maker
    }
    
    let storage = Storage()
    
    static var permitted: [String] = ["email", "businessName", "publicWebsite", "contactName", "contactPhone", "contactEmail", "location", "createdOn", "cut", "username", "stripe_id", "keys", "missingFields", "needsIdentityUpload", "maker_address_id", "password"]
    
    let email: String
    let businessName: String
    let publicWebsite: String
    
    let contactName: String
    let contactPhone: String
    let contactEmail: String
    
    let location: String
    let createdOn: Date
    let cut: Double
    
    var username: String
    var password: String?
    var hash: String
    
    var stripe_id: String?
    var keys: Keys?
    
    var missingFields: Bool
    var needsIdentityUpload: Bool
    
    var sub_id: String?
    
    init(subject: String, request: Request) throws {
        fatalError("Not supported")
    }
    
    init(node: Node) throws {
        
        username = try node.extract("username")
        password = try? node.extract("password")
        
        if let password = try? node.extract("password") as String {
            self.hash = try drop.hash.make(password).makeString()
        } else {
            self.hash = try node.extract("hash") as String
        }
        
        email = try node.extract("email")
        businessName = try node.extract("businessName")
        publicWebsite = try node.extract("publicWebsite")
        
        contactName = try node.extract("contactName")
        contactPhone = try node.extract("contactPhone")
        contactEmail = try node.extract("contactEmail")
        
        location = try node.extract("location")
        createdOn = (try? node.extract("createdOn")) ?? Date()
        cut = try node.extract("cut") ?? 0.08
        sub_id = try? node.extract("sub_id")
        
        stripe_id = try? node.extract("stripe_id")
        
        missingFields = (try? node.extract("missingFields")) ?? false
        needsIdentityUpload = (try? node.extract("needsIdentityUpload")) ?? false
        
        if stripe_id != nil {
            let publishable: String = try node.extract("publishableKey")
            let secret: String = try node.extract("secretKey")
            
            keys = try Keys(node: Node(node: ["secret" : secret, "publishable" : publishable]))
        }
        
        id = try? node.extract("id")
    }
    
    func makeNode(in context: Context?) throws -> Node {
        return try Node(node: [
            "email" : .string(email),
            "businessName" : .string(businessName),
            "publicWebsite" : .string(publicWebsite),
            
            "contactName" : .string(contactName),
            "contactPhone" : .string(contactPhone),
            "contactEmail" : .string(contactEmail),
            
            "location" : .string(location),
            "cut" : .number(.double(cut)),
            
            "username" : .string(username),
            "hash" : .string(hash),
            
            "missingFields" : .bool(missingFields),
            "needsIdentityUpload" : .bool(needsIdentityUpload)
        ]).add(objects: [
            "id" : id,
            "stripe_id" : stripe_id,
            "publishableKey" : keys?.publishable,
            "secretKey" : keys?.secret,
            "sub_id" : sub_id,
            "createdOn" : Node.date(createdOn).string,
            "password" : (context?.isRow ?? false) ? password : nil
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(Maker.self) { maker in
            maker.id()
            maker.string("email")
            maker.string("businessName")
            maker.string("publicWebsite")
            
            maker.string("contactName")
            maker.string("contactPhone")
            maker.string("contactEmail")
            
            maker.string("location")
            maker.string("createdOn")
            maker.double("cut")
            
            maker.string("username")
            maker.string("password")
            maker.string("hash")
            
            maker.string("publishableKey", optional: true)
            maker.string("secretKey", optional: true)
            maker.string("sub_id", optional: true)
            
            maker.string("stripe_id", optional: true)
            maker.bool("missingFields")
            maker.bool("needsIdentityUpload")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(Maker.self)
    }
}

extension Maker {
    
    func products() -> Children<Maker, Product> {
        return children()
    }
    
    func connectCustomers() throws -> Children<Maker, StripeMakerCustomer> {
        return children()
    }
    
    func addresses() -> Children<Maker, MakerAddress> {
        return children()
    }

    func subscriptions() -> Children<Maker, Subscription> {
        return children()
    }
    
    func pictures() -> Children<Maker, MakerPicture> {
        return children()
    }
}

extension Maker {
    
    func connectAccount(for customer: Customer, with card: String) throws -> String {
        let customer_id = try customer.throwableId()
        
        guard let stripeCustomerId = customer.stripe_id else {
            throw Abort.custom(status: .internalServerError, message: "Can not duplicate account onto vendor connect account if it has not been created on the platform first.")
        }
        
        guard let secretKey = keys?.secret else {
            throw Abort.custom(status: .internalServerError, message: "Missing secret key for vendor with id \(id?.int ?? 0)")
        }
        
        if let connectAccount = try self.connectCustomers().filter("customer_id", customer_id).first() {
            
            let hasPaymentMethod = try Stripe.shared.paymentInformation(for: connectAccount.stripeCustomerId, under: secretKey).filter { $0.id == card }.count > 0
            
            if !hasPaymentMethod {
                // TODO : right now we hit this every time....
                let token = try Stripe.shared.createToken(for: stripeCustomerId, representing: card, on: secretKey)
                let _ = try Stripe.shared.associate(source: token.id, withStripe: connectAccount.stripeCustomerId, under: secretKey)
            }
            
            return connectAccount.stripeCustomerId
        } else {
            let token = try Stripe.shared.createToken(for: stripeCustomerId, representing: card, on: secretKey)
            let stripeCustomer = try Stripe.shared.createStandaloneAccount(for: customer, from: token, on: secretKey)
            
            let connectAccount = try StripeMakerCustomer(maker: self, customer: customer, account: stripeCustomer.id)
            try connectAccount.save()
            
            return connectAccount.stripeCustomerId
        }
    }
}

extension Maker: PasswordAuthenticatable {
    
    public static var usernameKey: String {
        return "username"
    }
    
    var hashedPassword: String? {
        return self.hash
    }
    
    public static var passwordVerifier: PasswordVerifier? {
        return BCryptHasher()
    }
    
    public static func authenticate(_ creds: Password) throws -> Maker {
        guard let match = try self.makeQuery().filter(usernameKey, creds.username).first() else {
            if drop.config.environment == .development {
                throw Abort.custom(status: .badRequest, message: "Could not find user with username \(creds.username).")
            } else {
                throw AuthenticationError.invalidCredentials
            }
        }
        
        guard let hash = match.hashedPassword else {
            if drop.config.environment == .development {
                throw Abort.custom(status: .badRequest, message: "No hashed password for user with username \(creds.username).")
            } else {
                throw AuthenticationError.invalidCredentials
            }
        }
        
        guard let passwordVerifier = passwordVerifier else {
            if drop.config.environment == .development {
                throw Abort.custom(status: .badRequest, message: "No password hasher for \(self).")
            } else {
                throw AuthenticationError.invalidCredentials
            }
        }
        
        do {
            guard try passwordVerifier.verify(password: creds.password, matches: hash) else {
                if drop.config.environment == .development {
                    throw Abort.custom(status: .badRequest, message: "Password \(creds.password) does not match hash : \(hash)")
                } else {
                    throw AuthenticationError.invalidCredentials
                }
            }
        } catch {
            if drop.config.environment == .development {
                throw Abort.custom(status: .badRequest, message: "Error checking hash : \(error).")
            } else {
                throw AuthenticationError.invalidCredentials
            }
        }
        
        return match
    }
}
