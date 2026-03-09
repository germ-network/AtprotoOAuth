//
//  AuthorizerImpl+AuthRequestable.swift
//  AtprotoOAuth
//
//  Created by Mark @ Germ on 3/5/26.
//

import Foundation
import GermConvenience
import OAuth

extension AuthorizerImpl: AuthRequestable {
	var retriableIssuer: URL {
		issuer
	}

	var additionalParameters: [String: String] {
		[
			"client_id": appCredentials.clientId,
			"redirect_url": appCredentials.callbackURL.absoluteString,
		]
	}

	func validate(
		authMetadata: OAuth.AuthServerMetadata, tokenResponse: OAuth.TokenEndpointResponse
	) throws -> OAuth.SessionState.Mutable {
		//TODO: finish validation

		.init(
			accessToken: .init(
				value: tokenResponse.accessToken, expiresIn: tokenResponse.expiresIn
			),
			refreshToken: .init(refreshToken: tokenResponse.refreshToken),
			scopes: tokenResponse.scope,
			//REVIEW: where should this come from?
			issuingServer: authMetadata.issuer
		)
	}
}

extension AuthorizerImpl: DPoPSigning {
	func getNonce(origin: String) -> OAuth.IndexedNonce? {
		nonceCache.object(forKey: origin as NSString)
	}

	func cacheNonce(response: HTTPDataResponse, requestUrl: URL) throws {
		let indexedNonce = try Self.decode(dataResponse: response, requestUrl: requestUrl)
		if let indexedNonce {
			nonceCache.setObject(indexedNonce, forKey: indexedNonce.origin as NSString)
		}
	}

	static func decode(
		dataResponse: HTTPDataResponse,
		requestUrl: URL,
	) throws -> IndexedNonce? {
		guard let nonce = dataResponse.response.value(forHTTPHeaderField: "DPoP-Nonce")
		else {
			return nil
		}

		//henceforth should throw instead of return nil as nonce is expected
		return try IndexedNonce(
			responseUrl: dataResponse.response.url,
			requestUrl: requestUrl,
			nonce: nonce
		)
	}
}
