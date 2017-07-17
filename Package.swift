// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "api",
    products: [
        .executable(name: "api", targets: ["api"])
    ],
    dependencies: [
        .package(url: "https://github.com/hhanesand/vapor.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/mysql-provider.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/auth-provider.git", from: "1.0.0"),
        .package(url: "https://github.com/nodes-vapor/paginator.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "api",
            dependencies: [
                "Vapor",
                "MySQLProvider",
                "JWT",
                "AuthProvider",
                "Paginator"
            ],
            path: "Sources",
            exclude: [
                "Config",
                "Public"
            ]
        )
    ]   
)
