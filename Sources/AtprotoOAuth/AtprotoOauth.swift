//
//  AtprotoOauth.swift
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
		dpopSigner: DPoPSigning
	) -> AuthServerRequestOptions {
		.init(
			additionalParameters: [
				"client_id": appCredentials.clientId,
				"redirect_url": appCredentials.callbackURL.absoluteString,
			],
			authFetcher: authFetcher,
			validator: { authServerMetadata, tokenResponse in
				let sub = try tokenResponse.additionalFields?["sub"].tryUnwrap
				let subString = try (sub as? String).tryUnwrap

				//for now, enforcing the did is the same as what we started with
				//(and checked)

				//more full implementation is to check the new did if different
				//and its issuer
				guard subString == did.fullId else {
					throw OAuthClientError.subDidMismatch
				}

				return .init(
					accessToken: .init(
						value: tokenResponse.accessToken,
						expiresIn: tokenResponse.expiresIn
					),
					refreshToken: .init(
						refreshToken: tokenResponse.refreshToken),
					scopes: tokenResponse.scope,
					//REVIEW: do we need to compare the authmetadata issuer against some response from the auth server?
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
