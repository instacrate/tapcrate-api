//
//  Octobat.swift
//  App
//
//  Created by Hakon Hanesand on 6/12/17.
//

import Foundation

public final class TaxJar {

    static var token = "pk_test_lGLXGH2jjEx7KFtPmAYz39VA"
    static var secret = "sk_test_WceGrEBqnYpjCYF6exFBXvnf"

    fileprivate static let base = HTTPClient(baseURL: "https://api.stripe.com/v1/", token, secret)

    
}
