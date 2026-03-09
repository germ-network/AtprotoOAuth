//
//  OAuthClient+Interface.swift
//  AtprotoOAuth
//
//  Created by Mark @ Germ on 2/17/26.
//

import AtprotoTypes
import AuthenticationServices
import Crypto
import Foundation
import GermConvenience
import OAuth

extension AtprotoOAuthClient: AtprotoOAuthInterface {

	//Germ will always do pre-processing so we will know did,
	//but you can start from handle
	public enum AuthIdentity: Sendable {
		case handle(String)
		//optionally pass in handle to fill into the UI of the web auth sheet
		case did(Atproto.DID, handle: String?)

		var serverHint: String {
			switch self {
			case .handle(let string):
				string
			case .did(let did, let handle):
				handle ?? did.fullId
			}
		}
	}

	public func authorize(
		identity: AuthIdentity
	) async throws -> SessionState.Archive {
		let did: Atproto.DID
		switch identity {
		case .did(let _did, _):
			did = _did
		case .handle(let handle):
			//resolve handle to pds, uncached
			did = try await Self.resolve(handle: handle)
		}

		//resolve pds and pds metadata
		let didDoc = try await atprotoClient.plcDirectoryQuery(did)
		if case .handle(let handle) = identity {
			if handle != didDoc.handle {
				throw OAuthClientError.handleMismatch
			}
		}

		let authorizationServerUrl = try await getAuthorizationUrl(didDoc: didDoc)

		let parConfig = PARConfiguration(
			parameters: ["login_hint": identity.serverHint]
		)

		let additionaParameters = [
			"client_id": appCredentials.clientId,
			"redirect_url": appCredentials.callbackURL.absoluteString,
		]

		let validator:
			(
				AuthServerMetadata,
				TokenEndpointResponse
			) -> SessionState.Mutable = { authServerMetadata, tokenResponse in
				//TODO: finish validation

				.init(
					accessToken: .init(
						value: tokenResponse.accessToken,
						expiresIn: tokenResponse.expiresIn
					),
					refreshToken: .init(
						refreshToken: tokenResponse.refreshToken),
					scopes: tokenResponse.scope,
					//REVIEW: where should this come from?
					issuingServer: authServerMetadata.issuer
				)
			}

		return try await AuthComponents(
			additionalParameters: additionaParameters,
			authFetcher: authFetcher,
			validator: validator,
			issuer: authorizationServerUrl,
			dpopSigner: AuthDPopState(dpopKey: .generateP256())
		).performUserAuthentication(
			inputs: .init(
				appCredentials: appCredentials,
				stateToken: UUID().uuidString,
				pkceVerifier: .init()
			),
			parConfig: parConfig,
			userAuthenticator: {
				try await userAuthenticator($0, $1)
			}
		)

		//		return try await AuthorizerImpl(
		//			issuer: authorizationServerUrl,
		//			appCredentials: appCredentials,
		//			authFetcher: authFetcher
		//		)
		//		.performUserAuthentication(
		//			parConfig: parConfig,
		//			userAuthenticator: { try await userAuthenticator($0, $1) }
		//		)
	}

	private func getAuthorizationUrl(didDoc: DIDDocument) async throws -> URL {
		let pdsUrl = try didDoc.pdsUrl

		let pdsMetadata =
			try await authFetcher.resourceDiscoveryRequest(url: pdsUrl)

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

extension Atproto {
	struct TokenError: Hashable, Sendable, Codable {
		let error: String
		let errorDescription: String

		enum CodingKeys: String, CodingKey {
			case error
			case errorDescription = "error_description"
		}
	}
}
