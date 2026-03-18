//
//  AtprotoOAuth.swift
//  AtprotoOAuth
//
//  Created by Mark @ Germ on 3/9/26.
//

import AtprotoTypes
import Foundation
import GermConvenience
import OAuth

extension AuthServerRequestOptions {
	static func atproto(
		appCredentials: AppCredentials,
		did: Atproto.DID,
		authFetcher: HTTPFetcher,
		dpopSigner: DPoPSigning,
	) -> AuthServerRequestOptions {
		.init(
			additionalParameters: [
				"client_id": appCredentials.clientId,
				"redirect_url": appCredentials.callbackURL.absoluteString,
			],
			authFetcher: authFetcher,
			tokenValidator: { authServerMetadata, tokenResponse in
				guard tokenResponse.tokenType == .dpop else {
					throw OAuthSessionError.expectedDpopToken(
						tokenResponse.tokenType.rawValue)
				}

				let sub = try tokenResponse.additionalFields?["sub"].tryUnwrap
				let subString = try (sub as? String).tryUnwrap

				//for now, enforcing the did is the same as what we started with
				//(and checked)

				// TODO: GER-1388 - Implement validator
				// after a token is issued, it is critical that the returned
				// identity be resolved and its PDS match the issuing server
				//
				// check out draft-ietf-oauth-v2-1 section 7.3.1 for details

				//more full implementation is to check the new did if different
				//and its issuer
				guard subString == did.fullId else {
					throw OAuthClientError.subDidMismatch
				}

				let returnedScopes: [String]? = try {
					guard let scope = tokenResponse.scope else {
						return nil
					}
					let scopes = scope.components(separatedBy: " ")

					guard
						Set(appCredentials.requestedScopes).contains(
							scopes)
					else {
						throw OAuthSessionError.receivedScopeNotRequested
					}

					return scopes
				}()

				return .init(
					accessToken: .init(
						value: tokenResponse.accessToken,
						expiresIn: tokenResponse.expiresIn
					),
					refreshToken: .init(
						refreshToken: tokenResponse.refreshToken),
					scopes: returnedScopes ?? appCredentials.requestedScopes,
					issuingServer: authServerMetadata.issuer
				)
			},
			dpopSigner: dpopSigner
		)
	}
}

extension AuthDPopState {
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
