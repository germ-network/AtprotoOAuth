//
//  Token.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/22/26.
//

import Foundation

/// Holds an access token value and its expiry.
public struct Token: Codable, Hashable, Sendable {
	/// The access token.
	public let value: String

	/// An optional expiry.
	public let expiry: Date?

	public init(value: String, expiry: Date? = nil) {
		self.value = value
		self.expiry = expiry
	}

	public init(value: String, expiresIn seconds: Int) {
		self.value = value
		self.expiry = Date(timeIntervalSinceNow: TimeInterval(seconds))
	}

	/// Determines if the token object is valid.
	///
	/// A token without an expiry is unconditionally valid.
	public var valid: Bool {
		guard let date = expiry else { return true }

		return date.timeIntervalSinceNow > 0
	}
}

public struct SessionState: Codable, Hashable, Sendable {
	public var accessToken: Token
	public var refreshToken: Token?

	// User authorized scopes
	public var scopes: String?
	public let issuingServer: String?

	public let additionalParams: [String: String]?

	public init(
		accessToken: Token,
		refreshToken: Token? = nil,
		scopes: String? = nil,
		issuingServer: String? = nil,
		additionalParams: [String: String]? = nil,
	) {
		self.accessToken = accessToken
		self.refreshToken = refreshToken
		self.scopes = scopes
		self.issuingServer = issuingServer
		self.additionalParams = additionalParams
	}

	public init(token: String, validUntilDate: Date? = nil) {
		self.init(accessToken: Token(value: token, expiry: validUntilDate))
	}
}
