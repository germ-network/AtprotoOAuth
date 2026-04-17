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
		// If the pdsServiceEndpoint represents resource server metadata for the PDS
		if let authURL = try await urlAsResourceServer(
			pdsServiceEndpoint: pdsServiceEndpoint,
			authFetcher: authFetcher
		) {
			return authURL
		}

		// If the pdsServiceEndpoint represents authorization server metadata for the PDS
		return try await urlAsAuthServer(
			pdsServiceEndpoint: pdsServiceEndpoint,
			authFetcher: authFetcher
		).tryUnwrap
	}

	// Treat the PDS service endpoint as a resource server
	private static func urlAsResourceServer(
		pdsServiceEndpoint: URL,
		authFetcher: HTTPFetcher
	) async throws -> URL? {
		//We start with a resource server so missing metadata is a throwing error
		let pdsMetadata = try await authFetcher.resourceDiscoveryRequest(
			url: pdsServiceEndpoint)
			.tryUnwrap

		//https://datatracker.ietf.org/doc/html/rfc7518#section-3.1
		//PDS doesn't actually fill this field, so we only check it if present
		if let supportedAlgs = pdsMetadata.dpopSigningAlgValuesSupported {
			guard supportedAlgs.contains("ES256") else {
				throw OAuthSessionError.unsupportedDpopSigningAlgorithm
			}
		}

		// Return nil if there is not a single auth server
		guard
			let authServers = pdsMetadata.authorizationServers,
			authServers.count == 1,
			let authorizationServerString = authServers.first
		else {
			return nil
		}

		// Throw an error if there is an auth server but it doesn't parse to a URL
		guard let authorizationServerUrl = URL(string: authorizationServerString) else {
			throw OAuthClientError.missingUrlHost
		}

		return authorizationServerUrl
	}

	// Treat the PDS service endpoint as an authorization server
	private static func urlAsAuthServer(
		pdsServiceEndpoint: URL,
		authFetcher: HTTPFetcher
	) async throws -> URL? {
		// TODO: Update authServerDiscovery to return optional, and return nil
		// if we get a nil result from authServerDiscovery instead of throwing
		let pdsMetadata = try await authFetcher
			.authServerDiscovery(issuer: pdsServiceEndpoint)
			.tryUnwrap

		//https://datatracker.ietf.org/doc/html/rfc7518#section-3.1
		//PDS doesn't actually fill this field, so we only check it if present
		if let supportedAlgs = pdsMetadata.dpopSigningAlgValuesSupported {
			guard supportedAlgs.contains("ES256") else {
				throw OAuthSessionError.unsupportedDpopSigningAlgorithm
			}
		}

		return pdsServiceEndpoint
	}
}
