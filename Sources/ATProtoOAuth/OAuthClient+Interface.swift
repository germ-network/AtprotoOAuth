//
//  Runtime+Interface.swift
//  ATProtoOAuth
//
//  Created by Mark @ Germ on 2/17/26.
//

import ATProtoTypes
import Foundation
import OAuthenticator

extension ATProtoOAuthClient: ATProtoOAuthInterface {
	public func fetchFromPDS<Result: Sendable>(
		did: ATProtoDID,
		request: UnauthPDSRequest<Result>
	) async throws -> Result {
		try await request(
			resolvePdsUrl(did: did),
			responseProvider
		)
	}

	public func initialLogin(
		handle: String
	) async throws -> ATProtoOAuthSession.Archive {

		//resolve handle to pds, uncached
		let did = try await Self.resolve(handle: handle)

		//resolve pds and pds metadata
		let pdsUrl = try await resolvePdsUrl(did: did)

		//https://datatracker.ietf.org/doc/html/rfc7518#section-3.1
		//PDS doesn't actually fill this field, so we only check it if present
		//		if let supportedAlgs = pdsMetadata.dpopSigningAlgValuesSupported {
		//			guard supportedAlgs.contains("ES256")
		//			else {
		//				throw ATProtoAPIError.notImplemented
		//			}
		//		}

		//		guard
		//			let authorizationServerUrl = pdsMetadata.authorizationServers?.first,
		//			let authorizationServerHost = URL(string: authorizationServerUrl)?.host()
		//		else {
		//			throw ATProtoAPIError.badUrl
		//		}

		throw OAuthRuntimeError.notImplemented
	}
}
