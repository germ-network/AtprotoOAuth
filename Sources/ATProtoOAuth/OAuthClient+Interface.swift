//
//  Runtime+Interface.swift
//  ATProtoOAuth
//
//  Created by Mark @ Germ on 2/17/26.
//

import ATProtoTypes
import AuthenticationServices
import Crypto
import Foundation
import OAuth
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

	//Germ will always do pre-processing so we will know did,
	//but you can start from handle
	public enum AuthIdentity: Sendable {
		case handle(String)
		//optionally pass in handle to fill into the UI of the web auth sheet
		case did(ATProtoDID)
	}

	public func authorize(
		identity: AuthIdentity
	) async throws -> ATProtoOAuthSession.Archive {

		let did: ATProtoDID
		switch identity {
		case .did(let _did):
			did = _did
		case .handle(let handle):
			//resolve handle to pds, uncached
			did = try await Self.resolve(handle: handle)
		}

		//resolve pds and pds metadata
		let didDoc = try await resolveDidDocument(did: did)
		if case .handle(let handle) = identity {
			if handle != didDoc.handle {
				throw OAuthClientError.handleMismatch
			}
		}

		let authorizationServerUrl = try await getAuthorizationUrl(
			didDoc: didDoc
		)

		guard
			let authorizationServerHost = authorizationServerUrl.host()
		else {
			throw OAuthClientError.missingUrlHost
		}

		let serverConfig = try await getAuthServerMetadata(host: authorizationServerHost)

		let dpopKey = P256.Signing.PrivateKey()

		let tokenHandling = Bluesky.tokenHandling(
			account: did.fullId,
			server: serverConfig,
			jwtGenerator: try dpopKey.makeDpopSigner(),
			validator: { tokenResponse, sub in
				// TODO: GER-1343 - Implement validator
				// after a token is issued, it is critical that the returned
				// identity be resolved and its PDS match the issuing server
				//
				// check out draft-ietf-oauth-v2-1 section 7.3.1 for details
				return true
			}
		)

		let authenticator = Authenticator(
			config: .init(
				appCredentials: appCredentials,
				tokenHandling: tokenHandling,
				userAuthenticator: {
					try await ASWebAuthenticationSession.userAuthenticator(
						url: $0, scheme: $1)
				}
			)
		)
		let token = try await authenticator.authenticate()

		throw OAuthClientError.notImplemented
	}

	private func getAuthorizationUrl(didDoc: DIDDocument) async throws -> URL {
		guard let pdsHost = try didDoc.pdsUrl.host() else {
			throw OAuthClientError.missingUrlHost
		}

		let pdsMetadata = try await getProtectedResourceMetadata(host: pdsHost)

		//https://datatracker.ietf.org/doc/html/rfc7518#section-3.1
		//PDS doesn't actually fill this field, so we only check it if present
		if let supportedAlgs = pdsMetadata.dpopSigningAlgValuesSupported {
			guard supportedAlgs.contains("ES256")
			else {
				throw OAuthClientError.notImplemented
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
}
