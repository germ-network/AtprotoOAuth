//
//  OAuthErrorResponse.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/24/26.
//

/// Decodes a OAuth Error Response.
public struct OAuthErrorResponse: Codable, Hashable, Sendable {
	public let error: String
	public let errorDescription: String?

	enum CodingKeys: String, CodingKey {
		case error
		case errorDescription = "error_description"
	}
}

/// Additional common OAuth responses can be included here later.
/// For example OAuthTokenResponse or similar.
