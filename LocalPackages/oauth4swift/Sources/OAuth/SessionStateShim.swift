//
//  Token.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/22/26 from OAuthenticator
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

//best way to express fixed key and variable accessToken is as a reference type
public class SessionState {
	public var accessToken: Token
	public var refreshToken: Token?

	let dPopKey: DPoPKey?

	// User authorized scopes
	public var scopes: String?
	public let issuingServer: String?

	public let additionalParams: [String: String]?

	public init(
		accessToken: Token,
		refreshToken: Token? = nil,
		dPopKey: DPoPKey?,
		scopes: String? = nil,
		issuingServer: String? = nil,
		additionalParams: [String: String]? = nil,
	) {
		self.accessToken = accessToken
		self.refreshToken = refreshToken
		self.dPopKey = dPopKey
		self.scopes = scopes
		self.issuingServer = issuingServer
		self.additionalParams = additionalParams
	}

	public convenience init(
		accessToken: String,
		validUntilDate: Date? = nil,
		dPopKey: DPoPKey?
	) {
		self.init(
			accessToken: Token(
				value: accessToken,
				expiry: validUntilDate
			),
			dPopKey: dPopKey
		)
	}
}

extension SessionState {
	public struct Archive: Sendable, Codable {
		public let accessToken: Token
		public let refreshToken: Token?

		let dPopKey: DPoPKey?

		// User authorized scopes
		public let scopes: String?
		public let issuingServer: String?

		public let additionalParams: [String: String]?
	}

	public convenience init(archive: Archive) {
		self.init(
			accessToken: archive.accessToken,
			refreshToken: archive.refreshToken,
			dPopKey: archive.dPopKey,
			scopes: archive.scopes,
			issuingServer: archive.issuingServer,
			additionalParams: archive.additionalParams
		)
	}

	public var archive: Archive {
		.init(
			accessToken: accessToken,
			refreshToken: refreshToken,
			dPopKey: dPopKey,
			scopes: scopes,
			issuingServer: issuingServer,
			additionalParams: additionalParams
		)
	}
}

public struct SessionStateShim: Codable, Hashable, Sendable {
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
