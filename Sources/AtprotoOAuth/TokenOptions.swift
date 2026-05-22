//
//  TokenOptions.swift
//  AtprotoOAuth
//
//  Created by Mark @ Germ on 3/9/26.
//

import AtprotoTypes
import Foundation
import GermConvenience
import OAuth4Swift

extension AtprotoOAuthClient {
	struct TokenOptions: OAuth.TokenAuthorizeOptions {
		//unless a user entered an auth server, in most cases
		//we resolve from a did to this issuer so we don't need to check it again
		let alreadyResolvedDIDs: Set<Atproto.DID>
		let resolver: Atproto.Resolver
		let authFetcher: HTTPFetcher

		func validate(
			tokenResponse: TokenEndpointResponse,
			authServerMetadata: AuthServerMetadata
		) async throws -> Atproto.DID {
			guard tokenResponse.tokenType == .dpop else {
				throw OAuthSessionError.expectedDpopToken(
					tokenResponse.tokenType.rawValue)
			}

			let sub = try tokenResponse.additionalTokenFields?["sub"].tryUnwrap
			let subString = try (sub as? String).tryUnwrap
			let subDid = try Atproto.DID(string: subString)

			if alreadyResolvedDIDs.contains(subDid) {
				return subDid
			}

			//otherwise we need to resolve
			let didDoc = try await resolver.resolve(did: subDid).tryUnwrap

			let (resolvedAuthServerMetadata, _) =
				try await AtprotoOAuthUtils.getAuthorizationServerURL(
					pdsServiceEndpoint: didDoc.pdsUrl,
					authFetcher: authFetcher
				)

			guard resolvedAuthServerMetadata.issuer == authServerMetadata.issuer else {
				throw
					OAuthClientError
					.issuingServerMismatch(
						resolvedAuthServerMetadata.issuer,
						authServerMetadata.issuer
					)
			}

			return subDid
		}
	}
}

extension AtprotoOAuthAgent {
	struct TokenOptions: OAuth.TokenRefreshOptions {
		let additionalParameters: [String: String]

		let did: Atproto.DID

		func validate(
			tokenResponse: TokenEndpointResponse,
			authServerMetadata: AuthServerMetadata,
			previousState: OAuth.SessionState.Snapshot?
		) async throws -> Bool {
			guard tokenResponse.tokenType == .dpop else {
				throw OAuthSessionError.expectedDpopToken(
					tokenResponse.tokenType.rawValue)
			}

			let sub = try tokenResponse.additionalTokenFields?["sub"].tryUnwrap
			let subString = try (sub as? String).tryUnwrap
			guard subString == did.rawValue else {
				throw OAuthClientError.subDidMismatch
			}
			return true
		}
	}
}
