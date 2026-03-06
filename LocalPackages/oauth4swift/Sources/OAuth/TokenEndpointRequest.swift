//
//  TokenEndpointRequest.swift
//  OAuth
//
//  Created by Mark @ Germ on 3/4/26.
//

import Foundation
import GermConvenience

enum GrantType: String {
	case authorizationCode = "authorization_code"
	case refreshToken = "refresh_token"
}

//make this a protocol so both the Authorizer and Session can use it
public protocol AuthRequestable: Actor {
	var additionalParameters: [String: String] { get }
	func manualRedirectFetch(request: URLRequest) async throws -> HTTPDataResponse
	func validate(
		authMetadata: AuthServerMetadata,
		tokenResponse: TokenEndpointResponse
	) throws -> SessionState.Mutable
	//	var lazyIssuer: LazyResource<URL> { get }
	//want to be able to create a session offline and eventually resolve
	//the issuer for the fixed session id
	var retriableIssuer: URL { get async throws }
}

extension AuthRequestable {
	//initially rely on network stack caching
	func getAuthServerMetadata() async throws -> AuthServerMetadata {
		try await authServerDiscovery(
			issuer: try await retriableIssuer
		)
		.expect(successCode: 200)
		.decode()
	}

	func finishAuthorization(
		authorizationUrl: URL,
		stateToken: String,
		redirectURI: URL,
		pkceVerifier: PKCEVerifier,
		appCredentials: AppCredentials,
		authServerMetadata: AuthServerMetadata,
		dpopKey: DPoPKey,
	) async throws -> SessionState.Archive {
		let parsedRedirect = try OAuthComponents.validateAuthResponse(
			authServerMetadata: authServerMetadata,
			redirectURL: redirectURI,
			expectedState: stateToken
		)

		let httpResponse = try await authorizationCodeGrantRequest(
			authServerMetadata: authServerMetadata,
			redirectUrl: appCredentials.callbackURL,
			parsedRedirect: parsedRedirect,
			verifier: pkceVerifier.verifier,
			additionalParameters: additionalParameters,
			manualRedirectFetch: manualRedirectFetch
		)

		let result = try processAuthorizationCodeOAuth2Response(
			authServerMetadata: authServerMetadata,
			response: httpResponse
		)

		let mutable = try validate(authMetadata: authServerMetadata, tokenResponse: result)

		return .init(dPopKey: dpopKey, additionalParams: nil, mutable: mutable)
	}

	private func authServerDiscovery(issuer: URL) async throws -> HTTPDataResponse {
		guard issuer.scheme == "https" else {
			throw OAuthError.insecureScheme
		}
		//NOTE: oauth4web prepends this to the incoming path,
		let requestUrl = issuer.appending(path: "/.well-known/oauth-authorization-server")
		var request = URLRequest(url: requestUrl)
		request.setValue("application/json", forHTTPHeaderField: "Accept")
		request.httpMethod = HTTPMethod.get.rawValue

		return try await manualRedirectFetch(request: request)
	}

	func processRefreshTokenResponse(
		response: HTTPDataResponse
	) throws -> TokenEndpointResponse {
		try OAuthComponents.processGenericAccessToken(response: response)
	}

	func processAuthorizationCodeOAuth2Response(
		authServerMetadata: AuthServerMetadata,
		response: HTTPDataResponse
	) throws -> TokenEndpointResponse {
		let result = try OAuthComponents.processGenericAccessToken(response: response)

		//check the claims
		try validate(authMetadata: authServerMetadata, tokenResponse: result)
		// TODO: GER-1343 - Implement validator
		// after a token is issued, it is critical that the returned
		// identity be resolved and its PDS match the issuing server
		//
		// check out draft-ietf-oauth-v2-1 section 7.3.1 for details

		return result
	}

	func pushedAuthorizationRequest(
		authServerMetadata: AuthServerMetadata,
		appCredentials: AppCredentials,
		params: [String: String],
		headers: [String: String],
	) async throws -> HTTPDataResponse {
		let parEndpoint = try authServerMetadata.resolve(
			endpoint: .par)

		var bodyParams = params
		bodyParams["client_id"] = appCredentials.clientId

		var headers = headers
		headers["accept"] = "application/json"

		var request = URLRequest(url: parEndpoint)
		for (key, value) in headers {
			request.setValue(value, forHTTPHeaderField: key)
		}
		request.httpMethod = HTTPMethod.post.rawValue
		let paramsString =
			try bodyParams
			.map({ [$0, $1].joined(separator: "=") })
			.joined(separator: "&")
		request.httpBody = paramsString.utf8Data

		if let dpopSigner = self as? DPoPSigning {
			request = try await dpopSigner.addProof(
				request: request,
				//Review: what's correct here
				token: nil,
			)
		}

		let response = try await nonceRetryAuthenticated(
			request: request,
			token: nil
		)

		return response
	}
}
