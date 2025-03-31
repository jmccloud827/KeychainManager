import Foundation

/// A class that manages access to the keychain for storing and retrieving data.
///
/// The `KeychainManager` class conforms to the `KeychainManagerHandler` protocol and provides
/// methods to set, get, delete, and clear items in the keychain. It is designed to be thread-safe
/// and utilizes a lock to manage concurrent access.
public final class KeychainManager: KeychainManagerHandler {
    /// The shared instance of the `KeychainManager`.
    public static let shared: KeychainManager = .init()

    /// Initializes a new instance of `KeychainManager` with the specified access group.
    ///
    /// - Parameter accessGroup: The access group to use for keychain items.
    public init(accessGroup: String) {
        self.accessGroup = accessGroup
    }
    
    private init() {
        self.accessGroup = nil
    }
    
    private let accessGroup: String?
    private let lock = NSLock()
    
    /// Retrieves all keys stored in the Keychain.
    ///
    /// - Returns: An array of strings representing all the keys currently stored in the Keychain.
    public var allKeys: [String] {
        var result: AnyObject?
        
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true,
            kSecReturnAttributes: true,
            kSecReturnPersistentRef: true,
            kSecMatchLimit: kSecMatchLimitAll
        ]
        query.addAccessGroupWhenPresent(accessGroup: accessGroup)

        _ = withUnsafeMutablePointer(to: &result) { pointer in
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer(pointer))
        }
    
        if let result = result as? [[CFString: Any]] {
            return result.compactMap { dictionary in
                dictionary[kSecAttrAccount] as? String
            }
        }
        
        return []
    }
    
    /// Stores a value in the keychain under the specified key.
    ///
    /// - Parameters:
    ///   - value: The value to store, which must conform to the `Datafiable` protocol.
    ///   - key: The key under which to store the value.
    public func set<T: Datafiable>(_ value: T, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
    
        deleteWithNoLock(key)
        
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData: value.getData(),
            kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        query.addAccessGroupWhenPresent(accessGroup: accessGroup)
    
        SecItemAdd(query as CFDictionary, nil)
    }
    
    /// Retrieves a value from the keychain for the specified key.
    ///
    /// - Parameter key: The key associated with the value to retrieve.
    /// - Returns: The retrieved value, or `nil` if no value exists for the key.
    public func get<T: Datafiable>(_ key: String) -> T? {
        lock.lock()
        defer { lock.unlock() }
    
        var result: AnyObject?
        
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        query.addAccessGroupWhenPresent(accessGroup: accessGroup)
    
        _ = withUnsafeMutablePointer(to: &result) { pointer in
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer(pointer))
        }
    
        return T.from(data: result as? Data)
    }

    /// Deletes a value from the keychain for the specified key.
    ///
    /// - Parameter key: The key associated with the value to delete.
    public func delete(_ key: String) {
        lock.lock()
        defer { lock.unlock() }
    
        deleteWithNoLock(key)
    }
    
    /// Clears all items from the keychain associated with this manager.
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
    
        var query: [CFString: Any] = [kSecClass: kSecClassGenericPassword]
        query.addAccessGroupWhenPresent(accessGroup: accessGroup)
        
        SecItemDelete(query as CFDictionary)
    }
    
    private func deleteWithNoLock(_ key: String) {
        SecItemDelete([
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: key
        ] as CFDictionary)
    }
}

private extension [CFString: Any] {
    mutating func addAccessGroupWhenPresent(accessGroup: String?) {
        if let accessGroup {
            self[kSecAttrAccessGroup] = accessGroup
        }
    }
}

/// A protocol that defines methods for converting data to and from `Data`.
public protocol Datafiable: Sendable {
    /// Converts the value to `Data`.
    func getData() -> Data
    
    /// Creates a value from `Data`.
    static func from(data: Data?) -> Self?
}

extension Data: Datafiable {
    public func getData() -> Data {
        self
    }
    
    public static func from(data: Data?) -> Data? {
        data
    }
}

extension String: Datafiable {
    public func getData() -> Data {
        self.data(using: String.Encoding.utf8) ?? Data()
    }
    
    public static func from(data: Data?) -> String? {
        if let data {
            return String(data: data, encoding: .utf8)
        }

        return nil
    }
}

extension Bool: Datafiable {
    public func getData() -> Data {
        let bytes: [UInt8] = self ? [1] : [0]
        return Data(bytes)
    }
    
    public static func from(data: Data?) -> Bool? {
        guard let data,
              let firstBit = data.first else {
            return nil
        }
        
        return firstBit == 1
    }
}

extension Int: Datafiable {
    public func getData() -> Data {
        withUnsafeBytes(of: self) { Data($0) }
    }
    
    public static func from(data: Data?) -> Int? {
        data?.withUnsafeBytes { $0.load(as: Self.self) }
    }
}

extension Double: Datafiable {
    public func getData() -> Data {
        withUnsafeBytes(of: self) { Data($0) }
    }
    
    public static func from(data: Data?) -> Double? {
        data?.withUnsafeBytes { $0.load(as: Self.self) }
    }
}

extension Date: Datafiable {
    public func getData() -> Data {
        self.timeIntervalSince1970.getData()
    }
    
    public static func from(data: Data?) -> Date? {
        if let epochTime = Double.from(data: data) {
            return Date(timeIntervalSince1970: epochTime)
        }

        return nil
    }
}

extension URL: Datafiable {
    public func getData() -> Data {
        self.dataRepresentation
    }
    
    public static func from(data: Data?) -> URL? {
        if let data {
            return Self(dataRepresentation: data, relativeTo: nil)
        }
        
        return nil
    }
}

/// A protocol that defines methods for interacting with the keychain.
///
/// # How to mock
/// ```
/// class MockKeychainManager: KeychainManagerHandler {
///     var backingData: [String: any Datafiable] = [:]
///     var allKeys: [String] {
///         Array(backingData.keys)
///     }
///
///     func set(_ value: some Datafiable, forKey key: String) {
///         backingData[key] = value
///     }
///
///     func get<T>(_ key: String) -> T? where T: UWM.Datafiable {
///         backingData[key] as? T
///     }
///
///     func delete(_ key: String) {
///         backingData.removeValue(forKey: key)
///     }
///
///     func clear() {
///         backingData = [:]
///     }
/// }
/// ```
@MainActor public protocol KeychainManagerHandler: Sendable {
    /// Returns an array of all keys stored in the keychain.
    var allKeys: [String] { get }
    
    /// Stores a value in the keychain under the specified key.
    func set<T: Datafiable>(_ value: T, forKey key: String)
    
    /// Retrieves a value from the keychain for the specified key.
    func get<T: Datafiable>(_ key: String) -> T?
    
    /// Deletes a value from the keychain for the specified key.
    func delete(_ key: String)
    
    /// Clears all items from the keychain.
    func clear()
}
