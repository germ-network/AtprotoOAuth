//
//  ATProtoClient+Mock.swift
//  ATProtoClient
//
//  Created by Mark @ Germ on 2/18/26.
//

import ATProtoTypes
import Foundation
import OAuthenticator

public struct MockATProtoClient: ATProtoClientInterface {
	public init() {}

	public func plcDirectoryQuery(_: ATProtoTypes.ATProtoDID) async throws
		-> ATProtoTypes.DIDDocument
	{
		try .mock()
	}

	public func loadProtectedResourceMetadata(
		host: String,
	) async throws -> ProtectedResourceMetadata {
		try JSONDecoder().decode(
			ProtectedResourceMetadata.self,
			from:
				"""
				{"resource":"https://blacksky.app","authorization_servers":["https://blacksky.app"],"scopes_supported":[],"bearer_methods_supported":["header"],"resource_documentation":"https://atproto.com"}
				""".utf8Data
		)
	}

	public func loadAuthServerMetadata(
		host: String
	) throws -> ServerMetadata {
		try JSONDecoder().decode(
			ServerMetadata.self,
			from:
				"""
				{"issuer":"https://bsky.social","request_parameter_supported":true,"request_uri_parameter_supported":true,"require_request_uri_registration":true,"scopes_supported":["atproto","transition:email","transition:generic","transition:chat.bsky"],"subject_types_supported":["public"],"response_types_supported":["code"],"response_modes_supported":["query","fragment","form_post"],"grant_types_supported":["authorization_code","refresh_token"],"code_challenge_methods_supported":["S256"],"ui_locales_supported":["en-US"],"display_values_supported":["page","popup","touch"],"request_object_signing_alg_values_supported":["RS256","RS384","RS512","PS256","PS384","PS512","ES256","ES256K","ES384","ES512","none"],"authorization_response_iss_parameter_supported":true,"request_object_encryption_alg_values_supported":[],"request_object_encryption_enc_values_supported":[],"jwks_uri":"https://bsky.social/oauth/jwks","authorization_endpoint":"https://bsky.social/oauth/authorize","token_endpoint":"https://bsky.social/oauth/token","token_endpoint_auth_methods_supported":["none","private_key_jwt"],"token_endpoint_auth_signing_alg_values_supported":["RS256","RS384","RS512","PS256","PS384","PS512","ES256","ES256K","ES384","ES512"],"revocation_endpoint":"https://bsky.social/oauth/revoke","pushed_authorization_request_endpoint":"https://bsky.social/oauth/par","require_pushed_authorization_requests":true,"dpop_signing_alg_values_supported":["RS256","RS384","RS512","PS256","PS384","PS512","ES256","ES256K","ES384","ES512"],"client_id_metadata_document_supported":true}
				""".utf8Data
		)
	}
}

enum MockATProtoClientError: Error {
	case urlConstructionFailed
}

extension MockATProtoClientError: LocalizedError {
	var localizedDescription: String {
		switch self {
		case .urlConstructionFailed: "Failed to construct URL"
		}
	}
}

extension String {
	var utf8Data: Data {
		Data(utf8)
	}
}
