//
//  AuthenticationController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/3/17.
//
//

import Vapor
import HTTP
import Fluent
import FluentProvider
import Routing
import Node
import AuthProvider
import JWT

final class AuthenticationCollection {
    
    typealias AuthenticationSubject = Entity & Authenticatable & JWTInitializable & NodeConvertible & Persistable
    
    var keys: [String : String] = [:]
    
    func build(_ builder: RouteBuilder) {
        
        builder.grouped(OverridingPasswordAuthenticationMiddleware(Maker.self)).post("login") { request in
            guard let maker = request.multipleUserAuth.authenticated(Maker.self) else {
                if drop.config.environment == .development {
                    throw Abort.custom(status: .badRequest, message: "Could not fetch authenticated user. \(request.storage.description)")
                } else {
                    throw AuthenticationError.notAuthenticated
                }
            }
            
            return try maker.makeResponse()
        }
        
        builder.post("authentication") { request in
            
            let payload = try request.json()
            
            let token: String = try payload.extract("token")
            let subject: String = try payload.extract("subject")
        
            let jwt = try JWT(token: token)
            
            if drop.config.environment == .development && subject.hasPrefix("__testing__") {
                return try self.performFakeLogin(with: jwt, for: subject, from: request)
            }
            
            let keyId: String = try jwt.headers.extract("kid")
            let certificate = try self.fetchSigningKey(for: keyId).extractRSACertificate()
            let signer = try RS256(x509Cert: certificate)
        
            let claims: [Claim] = [
                ExpirationTimeClaim(createTimestamp: { return Seconds(Date().timeIntervalSince1970) }, leeway: 60),
                AudienceClaim(string: "tapcrate"),
                IssuerClaim(string: "https://securetoken.google.com/tapcrate"),
                SubjectClaim(string: subject),
                IssuedAtClaimComparison(createTimestamp: { return Seconds(Date().timeIntervalSince1970) }, leeway: 60)
            ]
            
            do {
                try jwt.verifySignature(using: signer)
            } catch {
                throw Abort.custom(status: .badRequest, message: "Failed to verify JWT token with error : \(error)")
            }
            
            if drop.config.environment != .development {
                do {
                    try jwt.verifyClaims(claims)
                } catch {
                    throw Abort.custom(status: .badRequest, message: "Failed to verifiy claims with error \(error)")
                }
            }
            
            return try self.authenticateUserFor(subject: subject, with: request, create: true).makeResponse()
        }
    }
}
