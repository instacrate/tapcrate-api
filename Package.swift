// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "tapcrate-api",
    products: [
        .library(name: "lib", type: .dynamic, targets: ["lib"]),
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
                .product(name: "Vapor"),
                .product(name: "MySQLProvider"),
                .product(name: "JWT"),
                .product(name: "AuthProvider"),
                .product(name: "Paginator")
            ]
        ),
        .target(
            name: "api",
            dependencies: [
                .target(name: "tapcrate-lib")
            ],
            exclude: [
                "Config",
                "Database",
                "Public"
            ]
        )
    ]
)

