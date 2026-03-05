//
//  AuthorizationServer.swift
//  OAuth
//
//  Created by Mark @ Germ on 3/4/26.
//

import Foundation
import GermConvenience

// See: https://www.rfc-editor.org/rfc/rfc8414.html
public struct AuthServerMetadata: Codable, Hashable, Sendable {
	public let issuer: String
	public let authorizationEndpoint: String
	public let tokenEndpoint: String
	public let responseTypesSupported: [String]
	public let grantTypesSupported: [String]
	public let codeChallengeMethodsSupported: [String]
	public let tokenEndpointAuthMethodsSupported: [String]
	public let tokenEndpointAuthSigningAlgValuesSupported: [String]
	public let scopesSupported: [String]
	public let authorizationResponseIssParameterSupported: Bool
	public let requirePushedAuthorizationRequests: Bool
	public let pushedAuthorizationRequestEndpoint: String
	public let dpopSigningAlgValuesSupported: [String]
	public let requireRequestUriRegistration: Bool
	public let clientIdMetadataDocumentSupported: Bool

	enum CodingKeys: String, CodingKey {
		case issuer
		case authorizationEndpoint = "authorization_endpoint"
		case tokenEndpoint = "token_endpoint"
		case responseTypesSupported = "response_types_supported"
		case grantTypesSupported = "grant_types_supported"
		case codeChallengeMethodsSupported = "code_challenge_methods_supported"
		case tokenEndpointAuthMethodsSupported = "token_endpoint_auth_methods_supported"
		case tokenEndpointAuthSigningAlgValuesSupported =
			"token_endpoint_auth_signing_alg_values_supported"
		case scopesSupported = "scopes_supported"
		case authorizationResponseIssParameterSupported =
			"authorization_response_iss_parameter_supported"
		case requirePushedAuthorizationRequests = "require_pushed_authorization_requests"
		case pushedAuthorizationRequestEndpoint = "pushed_authorization_request_endpoint"
		case dpopSigningAlgValuesSupported = "dpop_signing_alg_values_supported"
		case requireRequestUriRegistration = "require_request_uri_registration"
		case clientIdMetadataDocumentSupported = "client_id_metadata_document_supported"
	}

	//deprecate
	public static func load(
		for host: String,
		httpRequester: HTTPDataResponse.Requester
	) async throws -> AuthServerMetadata {
		var components = URLComponents()

		components.scheme = URLScheme.https.rawValue
		components.host = host
		components.path = "/.well-known/oauth-authorization-server"

		let url = try components.url.tryUnwrap(MetadataError.urlInvalid)

		var request = URLRequest(url: url)
		request.setValue("application/json", forHTTPHeaderField: "Accept")

		return try await httpRequester(request)
			.successDecode()
	}

	enum Endpoint {
		case authorization
		case token
		case pushedAuthorizationRequest

		var metadataPath: KeyPath<AuthServerMetadata, String> {
			switch self {
			case .authorization:
				\.authorizationEndpoint
			case .token:
				\.tokenEndpoint
			case .pushedAuthorizationRequest:
				\.pushedAuthorizationRequestEndpoint
			}
		}
	}

	//for our purposes require secure
	func resolve(endpoint: Endpoint) throws -> URL {
		let url = try URL(
			string: self[keyPath: endpoint.metadataPath]
		).tryUnwrap

		guard url.scheme == "https" else {
			throw OAuthError.insecureScheme
		}

		return url
	}
}

extension AuthServerMetadata {
	static func mock() throws -> Self {
		let data =
			"""
			{"issuer":"https://bsky.social","request_parameter_supported":true,"request_uri_parameter_supported":true,"require_request_uri_registration":true,"scopes_supported":["atproto","transition:email","transition:generic","transition:chat.bsky"],"subject_types_supported":["public"],"response_types_supported":["code"],"response_modes_supported":["query","fragment","form_post"],"grant_types_supported":["authorization_code","refresh_token"],"code_challenge_methods_supported":["S256"],"ui_locales_supported":["en-US"],"display_values_supported":["page","popup","touch"],"request_object_signing_alg_values_supported":["RS256","RS384","RS512","PS256","PS384","PS512","ES256","ES256K","ES384","ES512","none"],"authorization_response_iss_parameter_supported":true,"request_object_encryption_alg_values_supported":[],"request_object_encryption_enc_values_supported":[],"jwks_uri":"https://bsky.social/oauth/jwks","authorization_endpoint":"https://bsky.social/oauth/authorize","token_endpoint":"https://bsky.social/oauth/token","token_endpoint_auth_methods_supported":["none","private_key_jwt"],"token_endpoint_auth_signing_alg_values_supported":["RS256","RS384","RS512","PS256","PS384","PS512","ES256","ES256K","ES384","ES512"],"revocation_endpoint":"https://bsky.social/oauth/revoke","pushed_authorization_request_endpoint":"https://bsky.social/oauth/par","require_pushed_authorization_requests":true,"dpop_signing_alg_values_supported":["RS256","RS384","RS512","PS256","PS384","PS512","ES256","ES256K","ES384","ES512"],"client_id_metadata_document_supported":true}
			""".utf8Data

		return try JSONDecoder().decode(AuthServerMetadata.self, from: data)
	}
}
