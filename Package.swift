// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "tapcrate-api",
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/mysql-provider.git", majorVersion: 2),
        .Package(url: "https://github.com/instacrate/jwt.git", majorVersion: 2),
        .Package(url: "https://github.com/vapor/auth-provider.git", majorVersion: 1)
    ],
    exclude: [
        "Config",
        "Database",
        "Public"
    ]
)

