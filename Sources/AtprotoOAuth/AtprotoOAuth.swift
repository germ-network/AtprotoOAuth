//
//  AtprotoOAuth.swift
//  AtprotoOAuth
//
//  Created by Mark @ Germ on 3/9/26.
//

import AtprotoTypes
import Foundation
import GermConvenience
import OAuth4Swift

extension OAuth.TokenRequestOptions {
	static func atproto(
		did: Atproto.DID,
		authFetcher: HTTPFetcher,
	) -> Self {
		.init(
			additionalParameters: [:],
			tokenValidator: { tokenResponse, authServerMetadata, previousSession in
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
				guard subString == did.stringRepresentation else {
					throw OAuthClientError.subDidMismatch
				}

				// FIXME: Move to `authorizationValidator` (coming soon)
				//				let returnedScopes: [String]? = try {
				//					guard let scope = tokenResponse.scope else {
				//						return nil
				//					}
				//					let scopes = scope.components(separatedBy: " ")
				//					// FIXME: https://github.com/germ-network/oauth4swift/pull/3
				//					let requestedScopes = Set(clientMetadata.scopes)
				//
				//					for returnedScope in scopes {
				//						guard requestedScopes.contains(returnedScope)
				//						else {
				//							throw OAuthSessionError
				//								.receivedScopeNotRequested
				//						}
				//					}
				//					return scopes
				//				}()

				return true
			},
		)
	}
}
