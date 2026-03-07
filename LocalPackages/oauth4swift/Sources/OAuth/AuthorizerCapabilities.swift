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

	//	static func finishAuthorization(
	//		authorizationUrl: URL,
	//		stateToken: String,
	//		redirectURI: URL,
	//		pkceVerifier: PKCEVerifier,
	//		appCredentials: AppCredentials,
	//		authServerMetadata: AuthServerMetadata,
	//		dpopKey: DPoPKey,  //only for archiving
	//		dpopRequester: HTTPDataResponse.Requester
	//	) async throws -> SessionState.Archive

	//	associatedtype TokenResponse
	//	static func tokenSubscriberValidator(
	//		response: TokenResponse,
	//		sub: String
	//	) async throws
}

extension AuthorizerCapabilities {
	public func performUserAuthentication(
		parConfig: PARConfiguration,
		authServerMetadata: AuthServerMetadata,
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

	//	private func getPARRequestURI(
	//		appCredentials: AppCredentials,
	//		parConfig: PARConfiguration,
	//		stateToken: String,
	//	) async throws -> String {
	//		let result = try await parRequest(
	//			appCredentials: appCredentials,
	//			url: parConfig.url,
	//			params: parConfig.parameters,
	//			stateToken: stateToken,
	//		)
	//
	//		Logger(label: "PreSessionInterface")
	//			.debug("Received PAR response that expires in \(result.expiresIn)")
	//
	//		return result.requestURI
	//	}

	//	private func parRequest(
	//		appCredentials: AppCredentials,
	//		url: URL,
	//		params: [String: String],
	//		stateToken: String,
	//	) async throws -> PARResponse {
	//		let challenge = pkceVerifier.challenge
	//		let scopes = appCredentials.requestedScopes.joined(separator: " ")
	//		let callbackURI = appCredentials.callbackURL
	//		let clientId = appCredentials.clientId
	//
	//		var request = URLRequest(url: url)
	//		request.httpMethod = HTTPMethod.post.rawValue
	//		request.setValue("application/json", forHTTPHeaderField: "Accept")
	//		request.setValue(
	//			"application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
	//
	//		let base: [String: String] = [
	//			"client_id": clientId,
	//			"state": stateToken,
	//			"scope": scopes,
	//			"response_type": "code",
	//			"redirect_uri": callbackURI.absoluteString,
	//			"code_challenge": challenge.value,
	//			"code_challenge_method": challenge.method,
	//		]
	//
	//		let body =
	//			params
	//			.merging(base, uniquingKeysWith: { a, b in a })
	//			.map({ [$0, $1].joined(separator: "=") })
	//			.joined(separator: "&")
	//
	//		request.httpBody = body.utf8Data
	//
	//		return try await dpopResponse(
	//			for: request,
	//			issuerOrigin: nil,
	//			token: nil,
	//		).successDecode()
	//	}
}
