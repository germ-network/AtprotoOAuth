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
	//not mandatory in OAuth 2.1
	let dPopKey: DPoPKey?

	public let additionalParams: [String: String]?
	
	var mutable: Mutable

	public init(
		dPopKey: DPoPKey?,
		additionalParams: [String: String]? = nil,
		mutable: Mutable
	) {
		self.dPopKey = dPopKey
		self.additionalParams = additionalParams
		self.mutable = mutable
	}

	public convenience init(
		accessToken: String,
		validUntilDate: Date? = nil,
		dPopKey: DPoPKey?
	) {
		self.init(
			dPopKey: dPopKey,
			mutable: .init(
				accessToken: .init(value: accessToken, expiry: validUntilDate)
			)
		)
	}
	
	public struct Mutable {
		let accessToken: Token
		let refreshToken: Token?

		// User authorized scopes
		let scopes: String?
		let issuingServer: String?
		
		public init(
			accessToken: Token,
			refreshToken: Token? = nil,
			scopes: String? = nil,
			issuingServer: String? = nil
		) {
			self.accessToken = accessToken
			self.refreshToken = refreshToken
			self.scopes = scopes
			self.issuingServer = issuingServer
		}
	}
	
	public func updated(mutable: Mutable) {
		self.mutable = mutable
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
			dPopKey: archive.dPopKey,
			additionalParams: archive.additionalParams,
			mutable: .init(
				accessToken: archive.accessToken,
				refreshToken: archive.refreshToken,
				scopes: archive.scopes,
				issuingServer: archive.issuingServer
			)
		)
	}

	public var archive: Archive {
		.init(
			accessToken: mutable.accessToken,
			refreshToken: mutable.refreshToken,
			dPopKey: dPopKey,
			scopes: mutable.scopes,
			issuingServer: mutable.issuingServer,
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
