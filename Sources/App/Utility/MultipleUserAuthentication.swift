//
//  Authentication.swift
//  tapcrate-api
//
//  Created by Hakon Hanesand on 5/28/17.
//
//

import AuthProvider
import Fluent
import HTTP

extension SessionPersistable where Self: Entity {
    
    private static func key<T>(for: T.Type) -> String {
        return "session-entitiy-id-\(T.self)"
    }
    
    public func persist(for req: Request) throws {
        let session = try req.assertSession()
        let key = Self.key(for: type(of: self))
        
        if session.data[key]?.wrapped != id?.wrapped {
            try req.assertSession().data.set(key, id)
        }
    }
    
    public func unpersist(for req: Request) throws {
        let key = Self.key(for: type(of: self))
        try req.assertSession().data.removeKey(key)
    }
    
    public static func fetchPersisted(for request: Request) throws -> Self? {
        let key = Self.key(for: self)
        
        guard let id = try request.assertSession().data[key] else {
            return nil
        }
        
        guard let user = try Self.find(id) else {
            return nil
        }
        
        return user
    }
}

public final class OverridingPasswordAuthenticationMiddleware<U: PasswordAuthenticatable>: Middleware {
    public let passwordVerifier: PasswordVerifier?
    
    public init(_ userType: U.Type = U.self, _ passwordVerifier: PasswordVerifier? = nil) {
        self.passwordVerifier = passwordVerifier
    }
    
    public func respond(to req: Request, chainingTo next: Responder) throws -> Response {
        
        guard let password = req.auth.header?.basic else {
            throw AuthenticationError.invalidCredentials
        }
        
        let u = try U.authenticate(password)
        
        req.auth.authenticate(u)
        
        return try next.respond(to: req)
    }
}
