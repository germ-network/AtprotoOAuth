//
//  Url+oauth.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/24/26.
//

import Foundation

extension URL {
	public var origin: String? {
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
