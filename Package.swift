// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "tapcrate-api",
    products: [
        .library(name: "lib", targets: ["lib"]),
        .executable(name: "api", targets: ["api"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/mysql-provider.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/auth-provider.git", from: "1.0.0"),
        .package(url: "https://github.com/nodes-vapor/paginator.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "lib",
            dependencies: [
                "Vapor",
                "MySQLProvider",
                "JWT",
                "AuthProvider",
                "Paginator",
                "Promise"
            ],
            path: "Sources",
            exclude: [
                "Config",
                "Database",
                "Public"
            ]
        ),
        .target(
            name: "api",
            dependencies: [
                "lib"
            ]
        )
    ]   
)
