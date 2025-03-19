import SwiftUI

/// A property wrapper that provides a convenient way to store and retrieve values in the keychain.
///
/// This `Keychain` property wrapper conforms to the `DynamicProperty` protocol, allowing it to
/// integrate seamlessly with SwiftUI views. It uses a `KeychainManagerHandler` to handle
/// the actual storage and retrieval of data.
///
/// The type of value that can be stored must conform to the `Datafiable` protocol.
///
/// - Parameters:
///   - wrappedValue: The default value to use when the keychain does not have a stored value.
///   - keyName: The key associated with the value in the keychain.
///   - keychainManager: An instance of `KeychainManagerHandler` used to interact with the keychain.
///                      Defaults to `KeychainManager.shared`.
@propertyWrapper
@MainActor public struct Keychain<Value: Datafiable>: DynamicProperty {
    private let keychainManager: KeychainManagerHandler
    private let key: String
    private let initialValue: Value
    
    /// The wrapped value stored in the Keychain.
    ///
    /// When getting the value, it retrieves the corresponding value from the Keychain
    /// based on the stored key. When setting the value, it saves the new value to the Keychain.
    public var wrappedValue: Value {
        get {
            keychainManager.get(key) ?? self.initialValue
        }
        
        nonmutating set {
            keychainManager.set(newValue, forKey: key)
        }
    }
    
    /// A binding to the wrapped value, allowing for two-way data binding.
    ///
    /// This can be used in SwiftUI views to create a binding to the property wrapper's value.
    public var projectedValue: Binding<Value> {
        Binding(get: { wrappedValue },
                set: { value in wrappedValue = value })
    }
    
    /// Initializes a new `Keychain` property wrapper.
    ///
    /// - Parameters:
    ///   - defaultValue: The default value to use when the keychain does not have a stored value.
    ///   - keyName: The key associated with the value in the keychain.
    ///   - keychainManager: An instance of `KeychainManagerHandler` used to interact with the keychain.
    ///                      Defaults to `KeychainManager.shared`.
    public init(wrappedValue defaultValue: Value, _ keyName: String, keychainManager: KeychainManagerHandler = KeychainManager.shared) {
        self.key = keyName
        self.initialValue = defaultValue
        self.keychainManager = keychainManager
    }
}

public extension Keychain where Value == Bool {
    /// A shared instance of `KeychainManager`.
    static var shared: KeychainManager { KeychainManager.shared }
}
