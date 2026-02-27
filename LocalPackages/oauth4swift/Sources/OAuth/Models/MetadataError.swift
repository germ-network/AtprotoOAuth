//
//  MetadataError.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/23/26 from OAuthenticator
//

import Foundation
import GermConvenience

enum MetadataError: Error {
	case urlInvalid
}

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

	public static func load(
		for host: String,
		provider: HTTPDataResponse.Requester
	) async throws -> AuthServerMetadata {
		var components = URLComponents()

		components.scheme = URLScheme.https.rawValue
		components.host = host
		components.path = "/.well-known/oauth-authorization-server"

		let url = try components.url.tryUnwrap(MetadataError.urlInvalid)

		var request = URLRequest(url: url)
		request.setValue("application/json", forHTTPHeaderField: "Accept")

		return try await provider(request)
			.successDecode()
	}
}

// See: https://datatracker.ietf.org/doc/draft-ietf-oauth-client-id-metadata-document/
public struct ClientMetadata: Hashable, Codable, Sendable {
	public let clientId: String
	public let scope: String
	public let redirectURIs: [String]
	public let dpopBoundAccessTokens: Bool

	enum CodingKeys: String, CodingKey {
		case clientId = "client_id"
		case scope
		case redirectURIs = "redirect_uris"
		case dpopBoundAccessTokens = "dpop_bound_access_tokens"
	}

	public static func load(
		for clientId: String,
		provider: HTTPDataResponse.Requester
	) async throws -> ClientMetadata {
		let url = try URL(string: clientId).tryUnwrap(MetadataError.urlInvalid)

		var request = URLRequest(url: url)
		request.setValue("application/json", forHTTPHeaderField: "Accept")

		return try await provider(request)
			.successDecode()
	}
}

extension ClientMetadata {
	public var credentials: AppCredentials {
		let url = redirectURIs.first.map({ URL(string: $0)! })!

		return AppCredentials(
			clientId: clientId,
			scopes: scope.components(separatedBy: " "),
			callbackURL: url
		)
	}
}

// See: https://www.rfc-editor.org/rfc/rfc9728.html
public struct ProtectedResourceMetadata: Codable, Hashable, Sendable {
	public let resource: String
	public let authorizationServers: [String]?
	public let jwksUri: String?
	public let scopesSupported: [String]?
	public let bearerMethodsSupported: [String]?
	public let resourceSigningAlgValuesSupported: [String]?
	public let resourceName: String?
	public let resourceDocumentation: String?
	public let resourcePolicyUri: String?
	public let resourceTosUri: String?
	public let tlsClientCertificateBoundAccessTokens: Bool?
	public let authorizationDetailsTypesSupported: [String]?
	public let dpopSigningAlgValuesSupported: [String]?
	public let dpopBoundAccessTokensRequired: Bool?
	public let signedMetadata: String?

	enum CodingKeys: String, CodingKey {
		case resource
		case authorizationServers = "authorization_servers"
		case jwksUri = "jwks_uri"
		case scopesSupported = "scopes_supported"
		case bearerMethodsSupported = "bearer_methods_supported"
		case resourceSigningAlgValuesSupported = "resource_signing_alg_values_supported"
		case resourceName = "resource_name"
		case resourceDocumentation = "resource_documentation"
		case resourcePolicyUri = "resource_policy_uri"
		case resourceTosUri = "resource_tos_uri"
		case tlsClientCertificateBoundAccessTokens =
			"tls_client_certificate_bound_access_tokens"
		case authorizationDetailsTypesSupported = "authorization_details_types_supported"
		case dpopSigningAlgValuesSupported = "dpop_signing_alg_values_supported"
		case dpopBoundAccessTokensRequired = "dpop_bound_access_tokens_required"
		case signedMetadata = "signed_metadata"
	}

	public static func load(
		for host: String,
		provider: HTTPDataResponse.Requester
	) async throws -> ProtectedResourceMetadata {
		var components = URLComponents()
		components.scheme = "https"
		components.host = host
		components.path = "/.well-known/oauth-protected-resource"

		let url = try components.url.tryUnwrap(MetadataError.urlInvalid)

		var request = URLRequest(url: url)
		request.setValue("application/json", forHTTPHeaderField: "Accept")

		return try await provider(request)
			.successDecode()
	}
}
