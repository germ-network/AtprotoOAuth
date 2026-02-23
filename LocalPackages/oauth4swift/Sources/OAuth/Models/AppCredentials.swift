//
//  AppCredentials.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/22/26 from OAuthenticator
//

import Foundation

public struct AppCredentials: Codable, Hashable, Sendable {
	public var clientId: String
	public var scopes: [String]
	public var callbackURL: URL

	public init(clientId: String, scopes: [String], callbackURL: URL) {
		self.clientId = clientId
		self.scopes = scopes
		self.callbackURL = callbackURL
	}

	public var callbackURLScheme: String {
		get throws {
			guard let scheme = callbackURL.scheme else {
				throw OAuthError.missingScheme
			}

			return scheme
		}
	}
}
