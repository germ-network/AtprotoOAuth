//
//  AuthorizerCapabilities.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/26/26.
//

import Foundation
import GermConvenience
import Logging

public protocol AuthorizerCapabilities: AuthRequestable, DPoPSigning {
	var appCredentials: AppCredentials { get }
	var stateToken: String { get }
	//now mandatory for all
	var pkceVerifier: PKCEVerifier { get }

	static func authorizationURL(
		authEndpoint: URL,
		parRequestURI: String,
		clientId: String,
	) throws -> URL
}

extension AuthorizerCapabilities {
	public func performUserAuthentication(
		parConfig: PARConfiguration,
		userAuthenticator: UserAuthenticator
	) async throws -> SessionState.Archive {
		let challenge = pkceVerifier.challenge
		let scopes = appCredentials.requestedScopes.joined(separator: " ")
		let callbackURI = appCredentials.callbackURL
		let clientId = appCredentials.clientId

		let parParams = [
			"client_id": clientId,
			"state": stateToken,
			"scope": scopes,
			"response_type": "code",
			"redirect_uri": callbackURI.absoluteString,
			"code_challenge": challenge.value,
			"code_challenge_method": challenge.method,
		].merging(parConfig.parameters, uniquingKeysWith: { a, b in a })

		let authServerMetadata = try await authFetcher.authServerDiscovery(
			issuer: try await retriableIssuer
		)

		let parHTTPResponse = try await pushedAuthorizationRequest(
			authServerMetadata: authServerMetadata,
			appCredentials: appCredentials,
			params: parParams,
			headers: [:],
		)

		let parResponse = try OAuthComponents.processPushedAuthorizationResponse(
			response: parHTTPResponse
		)

		let tokenURL = try Self.authorizationURL(
			authEndpoint: authServerMetadata.authorizationEndpoint,
			parRequestURI: parResponse.requestURI,
			clientId: appCredentials.clientId
		)

		let scheme = try appCredentials.callbackURLScheme

		let callbackURL = try await userAuthenticator(tokenURL, scheme)

		return try await finishAuthorization(
			authorizationUrl: tokenURL,
			stateToken: stateToken,
			redirectURI: callbackURL,
			pkceVerifier: pkceVerifier,
			appCredentials: appCredentials,
			authServerMetadata: authServerMetadata,
			dpopKey: dpopKey,
		)
	}
}
