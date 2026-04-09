//
//  OAuthClient+Interface.swift
//  AtprotoOAuth
//
//  Created by Mark @ Germ on 2/17/26.
//

import AtprotoClient
import AtprotoTypes
import AuthenticationServices
import Crypto
import Foundation
import GermConvenience
import OAuth

public protocol AtprotoOAuthInterface {
	//MARK: Authentication
	//want to end up with a valid archive, not a live object
	static func authorize(
		identity: AuthIdentity,
		resolver: Atproto.Resolver,
		authFetcher: HTTPFetcher,
		clientMetadata: OAuthClient,
		userAuthenticator: UserAuthenticator
	) async throws -> SessionState.Archive
}

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
			handle ?? did.stringRepresentation
		}
	}
}

extension AtprotoOAuthAgent: AtprotoOAuthInterface {
	public static func authorize(
		identity: AuthIdentity,
		resolver: Atproto.Resolver,
		authFetcher: HTTPFetcher,
		clientMetadata: OAuthClient,
		userAuthenticator: UserAuthenticator
	) async throws -> SessionState.Archive {
		let did: Atproto.DID
		switch identity {
		case .did(let _did, _):
			did = _did
		case .handle(let handle):
			//resolve handle to pds, uncached
			did = try await resolver.resolve(handle: handle)
		}

		//resolve pds and pds metadata
		let didDoc = try await resolver.resolve(did: did)
		if case .handle(let handle) = identity {
			if handle != didDoc.handle {
				throw OAuthClientError.handleMismatch
			}
		}

		let authorizationServerUrl = try await AtprotoOAuthUtils.getAuthorizationServerURL(
			pdsServiceEndpoint: didDoc.pdsUrl,
			authFetcher: authFetcher
		)

		return try await AuthServerRequestOptions.atproto(
			clientMetadata: clientMetadata,
			did: did,
			authFetcher: authFetcher,
			dpopSigner: AuthDPopState(
				dpopKey: .generateP256(),
				decoder: AuthDPopState.decode
			)
		).performUserAuthentication(
			authorizeInputs: .init(
				clientMetadata: clientMetadata,
				parConfig: .init(
					parameters: ["login_hint": identity.serverHint]
				),
				issuer: authorizationServerUrl
			),
			userAuthenticator: { try await userAuthenticator($0, $1) },
		)
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
