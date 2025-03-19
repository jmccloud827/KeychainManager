# KeychainManager

`KeychainManager` is a Swift package that provides a simple and secure way to manage sensitive data in the iOS/macOS keychain. It allows you to store, retrieve, delete, and clear items in the keychain while ensuring thread safety. The package also includes a property wrapper for easy integration into SwiftUI applications.

## Features

- Secure storage of sensitive data using iOS/macOS Keychain.
- Thread-safe operations with locking mechanisms.
- Support for various data types through the `Datafiable` protocol.
- Property wrapper for easy integration with SwiftUI.

## Requirements

- Swift 5.0+
- Xcode 12.0+
- iOS 13.0+ / macOS 10.15+

## Installation

You can add this package to your Xcode project using Swift Package Manager. Follow these steps:

1. Open your Xcode project.
2. Select `File` > `Swift Packages` > `Add Package Dependency`.
3. Enter the repository URL: `https://github.com/jmccloud827/KeychainManager.git`.
4. Choose the version or branch you would like to use.
5. Click `Finish`.

## Usage

### KeychainManager

To use the `KeychainManager`, you can create an instance and use its methods to manage keychain items.

```swift
import KeychainManager

let keychain = KeychainManager.shared

// Store a value
keychain.set("mySecretPassword", forKey: "password")

// Retrieve a value
if let password: String = keychain.get("password") {
    print("Retrieved password: (password)")
}

// Delete a value
keychain.delete("password")

// Clear all items
keychain.clear()
```

### Datafiable Protocol

The `Datafiable` protocol allows various data types to be easily converted to and from `Data`. This includes built-in types like `String`, `Bool`, `Int`, `Double`, `Date`, and `URL`.

### Keychain Property Wrapper

The `Keychain` property wrapper provides a convenient way to manage keychain values within your SwiftUI views.

```swift
import KeychainManager

struct ContentView: View {
    @Keychain("password")
    var password: String = "defaultPassword"

    var body: some View {
        TextField("Password", text: $password)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding()
    }
}
```

### Error Handling

The `KeychainManager` class handles errors internally using the keychain API. If an operation fails, it will not throw errors but will instead return `nil` for retrieval methods or simply not store the item.

## License

This package is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.
