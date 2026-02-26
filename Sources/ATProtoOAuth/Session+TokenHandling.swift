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
			refresh_token: refreshToken.value,
			redirect_uri: appCredentials.callbackURL.absoluteString,
			grant_type: "refresh_token",
			client_id: appCredentials.clientId
		)

		var request = URLRequest(url: tokenURL)

		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpBody = try JSONEncoder().encode(tokenRequest)

		let tokenResponse: TokenResponse = try await Self.response(for: request)
			.successDecode()


		guard tokenResponse.token_type == "DPoP" else {
			throw OAuthSessionError
				.expectedDpopToken(tokenResponse.token_type)
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
	struct RefreshTokenRequest: Hashable, Sendable, Codable {
		public let refresh_token: String
		public let redirect_uri: String
		public let grant_type: String
		public let client_id: String

		public init(refresh_token: String, redirect_uri: String, grant_type: String, client_id: String) {
			self.refresh_token = refresh_token
			self.redirect_uri = redirect_uri
			self.grant_type = grant_type
			self.client_id = client_id
		}
	}
	
	public struct TokenResponse: Hashable, Sendable, Codable {
		public let access_token: String
		public let refresh_token: String?
		public let sub: String
		public let scope: String
		public let token_type: String
		public let expires_in: Int

		public func refreshOutput(for issuingServer: String) -> SessionState.Mutable {
			.init(
				accessToken: .init(value: access_token, expiresIn: expires_in),
				refreshToken: refresh_token.map { Token(value: $0) },
				scopes: scope,
				issuingServer: issuingServer
			)
		}

		public var accessToken: String { access_token }
		public var refreshToken: String? { refresh_token }
		public var tokenType: String { token_type }
		public var expiresIn: Int { expires_in }
	}

}
