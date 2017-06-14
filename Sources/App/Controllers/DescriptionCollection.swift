//
//  DescriptionController.swift
//  polymr-api
//
//  Created by Hakon Hanesand on 3/19/17.
//
//

import Vapor
import HTTP
import Fluent
import FluentProvider
import Routing
import Node
import JWT
import AuthProvider
import Foundation

fileprivate func handle(upload request: Request, for product: Int) throws -> String {
    guard let data = request.formData?.first?.value.part.body else {
        throw Abort.custom(status: .badRequest, message: "No file in request")
    }
    
    return try save(data: Data(bytes: data), for: product)
}

func save(data: Data, for product: Int) throws -> String {
    
    let descriptionFolder = "Public/descriptions"
    
    let saveURL = URL(fileURLWithPath: drop.config.workDir)
        .appendingPathComponent(descriptionFolder, isDirectory: true)
        .appendingPathComponent("\(product).json", isDirectory: false)
    
    do {
        try data.write(to: saveURL)
    } catch {
        throw Abort.custom(status: .internalServerError, message: "Unable to write multipart form data to file. Underlying error \(error)")
    }
    
    return "https://static.tapcrate.com/descriptions/\(product).json"
}

final class DescriptionCollection: RouteCollection, EmptyInitializable {
    
    init() {
        
    }
    
    func build(_ builder: RouteBuilder) {
        
        builder.grouped("descriptions").get(String.parameter) { request in
            let product = try request.parameters.next(String.self)
            return "https://static.tapcrate.com/descriptions/\(product)"
        }
        
        builder.grouped("descriptions").patch(String.parameter) { request in
            let product = try request.parameters.next(String.self)
            
            guard let product_id = Int(product) else {
                throw Abort.custom(status: .badRequest, message: "Invalid product id")
            }
            
            return try handle(upload: request, for: product_id)
        }
    }
}
