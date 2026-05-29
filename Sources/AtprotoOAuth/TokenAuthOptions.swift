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
	struct TokenAuthOptions: OAuth.TokenAuthorizeOptions {
		//unless a user entered an auth server, in most cases
		//we resolve from a did to this issuer so we don't need to check it again
		//The DID <> Issuer link should only be cached for at most 10 minutes
		//https://atproto.com/specs/oauth#identity-authentication
		//so this is not expeted to be used more broadly than this just
		//resolved scenario
		let justResolved: Atproto.DID?
		let resolver: Atproto.Resolver
		let authFetcher: HTTPFetcher

		func validate(
			tokenResponse: TokenEndpointResponse,
			authServerMetadata: AuthServerMetadata
		) async throws -> Atproto.DID {
			let subDid = try tokenResponse.atprotoParse()

			if subDid == justResolved {
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
	struct TokenRefreshOptions: OAuth.TokenRefreshOptions {
		let did: Atproto.DID

		func validate(
			tokenResponse: TokenEndpointResponse,
			authServerMetadata: AuthServerMetadata,
			previousState: OAuth.SessionState.Snapshot
		) async throws -> Bool {
			let subDid = try tokenResponse.atprotoParse()

			guard subDid == did else {
				throw OAuth.Errors
					.subjectMismatch(
						actual: subDid.rawValue,
						expected: did.rawValue
					)
			}
			return true
		}
	}
}

extension TokenEndpointResponse {
	func atprotoParse() throws -> Atproto.DID {
		guard tokenType == .dpop else {
			throw OAuthSessionError.expectedDpopToken(tokenType.rawValue)
		}

		let sub = try additionalTokenFields?["sub"].tryUnwrap
		let subString = try (sub as? String).tryUnwrap
		return try .init(string: subString)
	}
}
