//
//  NonceValue.swift
//  ATProtoOAuth
//
//  Created by Mark @ Germ on 2/24/26.
//

import Foundation

public final class NonceValue {
	public let origin: String
	public let nonce: String

	init(origin: String, nonce: String) {
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

extension URL {
	var origin: String? {
		guard
			let host = self.host,
			let scheme = self.scheme
		else {
			return nil
		}

		var originComponents = URLComponents()
		originComponents.scheme = scheme
		originComponents.host = host
		originComponents.port = nonDefaultHTTPort()
		return originComponents.string
	}

	private func nonDefaultHTTPort() -> Int? {
		switch (scheme, port) {
		case ("http", 80): nil
		case ("https", 443): nil
		default: port
		}
	}
}
