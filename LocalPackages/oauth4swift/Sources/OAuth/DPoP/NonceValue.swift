//
//  NonceValue.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/24/26.
//

//
//  NonceValue.swift
//  ATProtoOAuth
//
//  Created by Mark @ Germ on 2/24/26.
//

import Foundation

public typealias NonceDecoder = (Data, HTTPURLResponse) throws -> NonceValue?

public final class NonceValue {
	public let origin: String
	public let nonce: String

	public init(origin: String, nonce: String) {
		self.origin = origin
		self.nonce = nonce
	}
}

extension NSCache where KeyType == NSString, ObjectType == NonceValue {
	subscript(_ url: URL) -> String? {
		get {
			guard let key = url.origin else {
				return nil
			}
			let value = object(forKey: key as NSString)
			return value?.nonce
		}
		set {
			guard let key = url.origin else {
				return
			}

			if let entry = newValue {
				let value = NonceValue(origin: key, nonce: entry)
				setObject(value, forKey: key as NSString)
			} else {
				removeObject(forKey: key as NSString)
			}
		}
	}
}
