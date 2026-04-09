//
//  AtprotoOAuthUtils.swift
//  AtprotoOAuth
//
//  Created by Anna Mistele on 4/9/26.
//

import AtprotoTypes
import Foundation
import GermConvenience

public struct AtprotoOAuthUtils {
	public static func getAuthorizationServerURL(
		pdsServiceEndpoint: URL,
		authFetcher: HTTPFetcher
	) async throws -> URL {
		do {
			// If the pdsServiceEndpoint represents resource server metadata for the PDS
			return try await urlAsResourceServer(
				pdsServiceEndpoint: pdsServiceEndpoint,
				authFetcher: authFetcher
			)
		} catch {
			// If the pdsServiceEndpoint represents authorization server metadata for the PDS
			return try await urlAsAuthServer(
				pdsServiceEndpoint: pdsServiceEndpoint,
				authFetcher: authFetcher
			)
		}
	}

	// Treat the PDS service endpoint as a resource server
	private static func urlAsResourceServer(
		pdsServiceEndpoint: URL,
		authFetcher: HTTPFetcher
	) async throws -> URL {
		let pdsMetadata = try await authFetcher.resourceDiscoveryRequest(
			url: pdsServiceEndpoint)

		//https://datatracker.ietf.org/doc/html/rfc7518#section-3.1
		//PDS doesn't actually fill this field, so we only check it if present
		if let supportedAlgs = pdsMetadata.dpopSigningAlgValuesSupported {
			guard supportedAlgs.contains("ES256") else {
				throw OAuthSessionError.unsupportedDpopSigningAlgorithm
			}
		}

		guard
			let authorizationServerString = pdsMetadata.authorizationServers?.first,
			let authorizationServerUrl = URL(string: authorizationServerString)
		else {
			throw OAuthClientError.missingUrlHost
		}
		return authorizationServerUrl
	}

	// Treat the PDS service endpoint as an authorization server
	private static func urlAsAuthServer(
		pdsServiceEndpoint: URL,
		authFetcher: HTTPFetcher
	) async throws -> URL {
		let pdsMetadata = try await authFetcher.authServerDiscovery(
			issuer: pdsServiceEndpoint)

		//https://datatracker.ietf.org/doc/html/rfc7518#section-3.1
		//PDS doesn't actually fill this field, so we only check it if present
		if let supportedAlgs = pdsMetadata.dpopSigningAlgValuesSupported {
			guard supportedAlgs.contains("ES256") else {
				throw OAuthClientError.notImplemented
			}
		}

		return pdsServiceEndpoint
	}
}
