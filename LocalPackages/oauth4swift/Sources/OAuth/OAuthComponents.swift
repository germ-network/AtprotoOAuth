//
//  OAuthComponents.swift
//  OAuth
//
//  Created by Mark @ Germ on 3/5/26.
//

import Foundation
import GermConvenience

///Direct analog to oauth4web's OAuth module in providing stateless API as building blocks for a full client
public enum OAuthComponents {
	static public func validateAuthResponse(
		authServerMetadata: AuthServerMetadata,
		redirectURL: URL,
		expectedState: String
	) throws -> ParsedRedirect {
		// decode the params in the redirectURL
		let redirectComponents = try URLComponents(
			url: redirectURL,
			resolvingAgainstBaseURL: false
		).tryUnwrap

		guard
			let authCode = redirectComponents.queryItems?.first(where: {
				$0.name == "code"
			})?.value,
			let iss = redirectComponents.queryItems?.first(where: {
				$0.name == "iss"
			})?.value,
			let state = redirectComponents.queryItems?.first(where: {
				$0.name == "state"
			})?.value
		else {
			throw OAuthError.redirectMissingComponents
		}

		guard state == expectedState else {
			throw OAuthError.stateTokenMismatch(state, expectedState)
		}

		guard iss == authServerMetadata.issuer else {
			throw
				OAuthError
				.issuingServerMismatch(iss, authServerMetadata.issuer)
		}

		if let errorItem = redirectComponents.queryItems?.first(where: {
			$0.name == "error"
		}) {
			throw OAuthError.redirectError(errorItem.value ?? "")
		}

		return .init(
			authCode: authCode,
			issuer: iss,
			components: redirectComponents
		)
	}

	public struct ParsedRedirect {
		public let authCode: String
		public let issuer: String

		public let components: URLComponents
	}

	static func processGenericAccessToken(
		response: HTTPDataResponse
	) throws -> TokenEndpointResponse {
		let decoded: TokenEndpointResponse = try response.successDecode(successCode: 200)

		return decoded
	}

	struct TokenResponse: Decodable {
		let accessToken: String
		let tokenType: String
		let scope: String?
		let idToken: String?

		enum CodingKeys: String, CodingKey {
			case accessToken = "access_token"
			case tokenType = "token_type"
			case scope
			case idToken = "id_token"
		}
	}
}

extension AuthRequestable {
	public func authorizationCodeGrantRequest(
		authServerMetadata: AuthServerMetadata,
		redirectUrl: URL,
		parsedRedirect: OAuthComponents.ParsedRedirect,
		verifier: String?,
		additionalParameters: [String: String],
		manualRedirectFetch: HTTPDataResponse.Requester
	) async throws -> HTTPDataResponse {
		var parameters = additionalParameters
		parameters["redirect_url"] = redirectUrl.absoluteString
		parameters["code"] = parsedRedirect.authCode

		if let verifier {
			parameters["code_verifier"] = verifier
		}

		return try await tokenEndpointRequest(
			authServerMetadata: authServerMetadata,
			grantType: .authorizationCode,
			parameters: parameters,
			headers: [:],
			manualRedirectFetch: manualRedirectFetch
		)
	}

	func refreshTokenGrantRequest(
		authServerMetadata: AuthServerMetadata,
		refreshToken: String,
	) async throws -> HTTPDataResponse {
		var parameters = additionalParameters
		parameters["refresh_token"] = refreshToken

		return try await tokenEndpointRequest(
			authServerMetadata: authServerMetadata,
			grantType: .refreshToken,
			parameters: parameters,
			headers: [:],
			manualRedirectFetch: manualRedirectFetch
		)
	}

	func tokenEndpointRequest(
		authServerMetadata: AuthServerMetadata,
		grantType: GrantType,
		parameters: [String: String],
		headers: [String: String],
		manualRedirectFetch: HTTPDataResponse.Requester
	) async throws -> HTTPDataResponse {
		let url = try authServerMetadata.resolve(endpoint: .token)

		var modifiedParams = parameters
		modifiedParams["grant_type"] = grantType.rawValue

		var headers = headers
		//swift4web sets the "accept" header, but both may be appropriate
		headers["accept"] = "application/json"
		headers["Content-Type"] = "application/json"
		//swift4web sets the "accept" header, but Content-Type seems

		var request = URLRequest(url: url)

		if let dpopSigner = self as? DPoPSigning {
			try dpopSigner.addProof(request: &request)
		}

		request.httpMethod = HTTPMethod.post.rawValue
		request.httpBody = try JSONEncoder().encode(headers)

		let response = try await authenticated(
			request: request,
		)
		if let dpopSigner = self as? DPoPSigning {
			try dpopSigner.cacheNonce(response: response.response, requestUrl: url)
		}

		return response
	}

	//here for shadowing of oauth4web.authenticatedRequest
	//but most functionality has been lifted out
	func authenticated(
		request: URLRequest,
	) async throws -> HTTPDataResponse {
		try await manualRedirectFetch(request: request)
	}
}
