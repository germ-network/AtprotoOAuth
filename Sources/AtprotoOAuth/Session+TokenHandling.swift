//
//  Session+TokenHandling.swift
//  ATProtoOAuth
//
//  Created by Mark @ Germ on 2/25/26.
//

import Foundation
import OAuth

extension ATProtoOAuthSession: TokenHandling {
	//	public static func loginProvider(params: OAuth.LoginProviderParameters) async throws -> OAuth.SessionState.Archive {
	//		<#code#>
	//	}

	public func refreshProvider(
		sessionState: SessionState.Archive,
		appCredentials: AppCredentials
	) async throws -> SessionState.Mutable {
		let refreshToken = try sessionState.refreshToken.tryUnwrap
		let serverMetadata = try await lazyServerMetadata.lazyValue(
			isolation: self
		)

		let tokenURL = try URL(string: serverMetadata.tokenEndpoint)
			.tryUnwrap(OAuthSessionError.cantFormURL)

		let tokenRequest = RefreshTokenRequest(
			refreshToken: refreshToken.value,
			redirectUri: appCredentials.callbackURL.absoluteString,
			grantType: "refresh_token",
			clientId: appCredentials.clientId
		)

		var request = URLRequest(url: tokenURL)

		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = try JSONEncoder().encode(tokenRequest)

		let tokenResponse: TokenResponse = try await Self.response(for: request)
			.successDecode()

		guard tokenResponse.tokenType == "DPoP" else {
			throw
				OAuthSessionError
				.expectedDpopToken(tokenResponse.tokenType)
		}

		try await tokenSubscriberValidator(
			response: tokenResponse,
			sub: serverMetadata.issuer
		)

		return tokenResponse.refreshOutput(for: serverMetadata.issuer)
	}

	//throws if invalid
	private func tokenSubscriberValidator(
		response: TokenResponse,
		sub: String
	) async throws {
		// TODO: GER-1343 - Implement validator
		// after a token is issued, it is critical that the returned
		// identity be resolved and its PDS match the issuing server
		//
		// check out draft-ietf-oauth-v2-1 section 7.3.1 for details
	}
}

extension ATProtoOAuthSession {
	struct TokenRequest: Hashable, Sendable, Codable {
		public let code: String
		public let codeVerifier: String
		public let redirectUri: String
		public let grantType: String
		public let clientId: String

		public init(
			code: String,
			codeVerifier: String,
			redirectUri: String,
			grantType: String,
			clientId: String
		) {
			self.code = code
			self.codeVerifier = codeVerifier
			self.redirectUri = redirectUri
			self.grantType = grantType
			self.clientId = clientId
		}

		public enum CodingKeys: String, CodingKey {
			case code
			case codeVerifier = "code_verifier"
			case redirectUri = "redirect_uri"
			case grantType = "grant_type"
			case clientId = "client_id"
		}
	}

	struct RefreshTokenRequest: Hashable, Sendable, Codable {
		public let refreshToken: String
		public let redirectUri: String
		public let grantType: String
		public let clientId: String

		public init(
			refreshToken: String,
			redirectUri: String,
			grantType: String,
			clientId: String
		) {
			self.refreshToken = refreshToken
			self.redirectUri = redirectUri
			self.grantType = grantType
			self.clientId = clientId
		}

		public enum CodingKeys: String, CodingKey {
			case refreshToken = "refresh_token"
			case redirectUri = "redirect_uri"
			case grantType = "grant_type"
			case clientId = "client_id"
		}
	}

	struct TokenResponse: Hashable, Sendable, Codable {
		public let accessToken: String
		public let refreshToken: String?
		public let sub: String
		public let scope: String
		public let tokenType: String
		public let expiresIn: Int

		public func refreshOutput(for issuingServer: String) -> SessionState.Mutable {
			.init(
				accessToken: .init(value: accessToken, expiresIn: expiresIn),
				refreshToken: refreshToken.map { Token(value: $0) },
				scopes: scope,
				issuingServer: issuingServer
			)
		}

		public func login(for issuingServer: String, dpopKey: OAuth.DPoPKey) -> SessionState
		{
			.init(
				dPopKey: dpopKey,
				additionalParams: ["did": sub],
				mutable: .init(
					accessToken: .init(
						value: accessToken, expiresIn: expiresIn),
					refreshToken: refreshToken.map { .init(value: $0) },
					scopes: scope,
					issuingServer: issuingServer,
				)
			)
		}

		enum CodingKeys: String, CodingKey {
			case accessToken = "access_token"
			case refreshToken = "refresh_token"
			case sub
			case scope
			case tokenType = "token_type"
			case expiresIn = "expires_in"

		}
	}

}
