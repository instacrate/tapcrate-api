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
import Vapor
import FluentProvider

extension SessionPersistable where Self: Entity {
    
    private static func key<T>(for: T.Type) -> String {
        return "session-entity-id-\(T.self)"
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

public final class OverridingPasswordAuthenticationMiddleware<U: PasswordAuthenticatable>: Middleware where U : SessionPersistable {
    public let passwordVerifier: PasswordVerifier?
    
    public init(_ userType: U.Type = U.self, _ passwordVerifier: PasswordVerifier? = nil) {
        self.passwordVerifier = passwordVerifier
    }
    
    public func respond(to req: Request, chainingTo next: Responder) throws -> Response {
        
        guard let password = req.multipleUserAuth.header?.basic else {
            throw AuthenticationError.invalidCredentials
        }
        
        let u = try U.authenticate(password)
        req.multipleUserAuth.authenticate(u)
        return try next.respond(to: req)
    }
}

public final class MultipleUserAuthenticationHelper {
    
    private static func key<T>(for: T.Type) -> String {
        return "auth-entity-\(T.self)"
    }
    
    weak var request: Request?
    public init(request: Request) {
        self.request = request
    }
    
    /// Returns the `Authorization: ...` header
    // from the request.
    public var header: AuthorizationHeader? {
        guard let authorization = request?.headers["Authorization"] else {
            guard let query = request?.query else {
                return nil
            }
            
            if let bearer = query["_authorizationBearer"]?.string {
                return AuthorizationHeader(string: "Bearer \(bearer)")
            } else if let basic = query["_authorizationBasic"]?.string {
                return AuthorizationHeader(string: "Basic \(basic)")
            } else {
                return nil
            }
        }
        
        return AuthorizationHeader(string: authorization)
    }
    
    /// Authenticates an `Authenticatable` type.
    ///
    /// `isAuthenticated` will return `true` for this type
    public func authenticate<A: Authenticatable>(_ a: A) {
        let key = MultipleUserAuthenticationHelper.key(for: A.self)
        request?.storage[key] = a
    }
    
    /// Authenticates an `Authenticatable` and `Peristable` type
    /// giving the additional option to persist.
    ///
    /// Calls `.persist(for: req)` on the model.
    public func authenticate<AP: Authenticatable & Persistable>(_ ap: AP, persist: Bool) throws {
        let key = MultipleUserAuthenticationHelper.key(for: AP.self)
        request?.storage[key] = ap
        if persist {
            guard let request = request else {
                throw AuthError.noRequest
            }
            try ap.persist(for: request)
        }
    }
    
    /// Removes the authenticated user from internal storage.
    public func unauthenticate<A: Authenticatable>(_ a: A) throws {
        let key = MultipleUserAuthenticationHelper.key(for: A.self)
        
        if
            let user = request?.storage[key] as? Persistable,
            let req = request
        {
            try user.unpersist(for: req)
        }
        
        request?.storage[key] = nil
    }
    
    /// Returns the Authenticated user if it exists.
    public func authenticated<A: Authenticatable>(_ userType: A.Type = A.self) -> A? {
        let key = MultipleUserAuthenticationHelper.key(for: A.self)
        return request?.storage[key] as? A
    }
    
    /// Returns the Authenticated user or throws if it does not exist.
    public func assertAuthenticated<A: Authenticatable>(_ userType: A.Type = A.self) throws -> A {
        guard let a = authenticated(A.self) else {
            throw AuthenticationError.notAuthenticated
        }
        
        return a
    }
    
    /// Returns true if the User type has been authenticated.
    public func isAuthenticated<A: Authenticatable>(_ userType: A.Type = A.self) -> Bool {
        return authenticated(A.self) != nil
    }
}

public final class MultipleUserPersistMiddleware<U: Authenticatable & Persistable>: Middleware {
    public init(_ userType: U.Type = U.self) {}
    
    public func respond(to req: Request, chainingTo next: Responder) throws -> Response {
        if let user = try U.fetchPersisted(for: req) {
            req.multipleUserAuth.authenticate(user)
        }
        
        let res = try next.respond(to: req)
        
        if let user = req.multipleUserAuth.authenticated(U.self) {
            try user.persist(for: req)
        }
        
        return res
    }
}

extension Request {
    /// Access the authorization helper with
    /// `authenticate` and `isAuthenticated` calls
    public var multipleUserAuth: MultipleUserAuthenticationHelper {
        if let existing = storage["multiple-user-auth"] as? MultipleUserAuthenticationHelper {
            return existing
        }
        
        let helper = MultipleUserAuthenticationHelper(request: self)
        storage["multiple-user-auth"] = helper
        
        return helper
    }
}

extension Request {
    
    func customer() throws -> Customer {
        return try multipleUserAuth.assertAuthenticated(Customer.self)
    }
    
    func maker() throws -> Maker {
        return try multipleUserAuth.assertAuthenticated(Maker.self)
    }

    func check(has sessionType: SessionType) throws -> Model {
        switch sessionType {
        case .customer:
            return try multipleUserAuth.assertAuthenticated(Customer.self)

        case .maker:
            return try multipleUserAuth.assertAuthenticated(Maker.self)
        }
    }
}
