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
	var lazyIssuer: LazyResource<URL> { get }
}

extension AuthRequestable {
	//initially rely on network stack caching
	func getAuthServerMetadata() async throws -> AuthServerMetadata {
		try await authServerDiscovery(
			issuer: lazyIssuer.lazyValue(isolation: self)
		)
		.successDecode(successCode: 200)
	}

	func finishAuthorization(
		authorizationUrl: URL,
		stateToken: String,
		redirectURI: URL,
		pkceVerifier: PKCEVerifier,
		appCredentials: AppCredentials,
		authServerMetadata: AuthServerMetadata,
		dpopKey: DPoPKey,
		dpopRequester: (URLRequest) async throws -> HTTPDataResponse
	) async throws -> SessionState.Archive {
		let parsedRedirect = try OAuthComponents.validateAuthResponse(
			authServerMetadata: authServerMetadata,
			redirectURL: redirectURI,
			expectedState: stateToken
		)

		let httpResponse = try await authorizationCodeGrantRequest(
			authServerMetadata: authServerMetadata,
			redirectUrl: redirectURI,
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

		//		let result = try await dpopRequester(request)
		//			.successErrorDecode(
		//				resultType: Atproto.TokenResponse.self,
		//				errorType: Atproto.TokenError.self,
		//			)

		//		switch result {
		//		case .result(let tokenResponse):
		//			guard tokenResponse.tokenType == "DPoP" else {
		//				throw OAuthClientError.dpopTokenExpected(
		//					tokenResponse.tokenType)
		//			}
		//
		//			try await Self.tokenSubscriberValidator(
		//				response: tokenResponse,
		//				sub: authServerMetadata.issuer
		//			)
		//
		//			return tokenResponse.session(
		//				for: parsedRedirect.issuer,
		//				dpopKey: dpopKey
		//			)
		//		case .error(let tokenError, let statusCode):

		//			if tokenError.errorDescription == "Code challenge already used" {
		//				throw OAuthClientError.codeChallengeAlreadyUsed
		//			}
		//			Self.logger.error(
		//				"Login error: \(tokenError.errorDescription), with status code \(statusCode)"
		//			)
		//			throw OAuthClientError.remoteTokenError(tokenError)
		//		}
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
}
