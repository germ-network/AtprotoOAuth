//
//  DPoPTokenPayload.swift
//  OAuth
//
//  Created by Mark @ Germ on 10/6/25.
//

import Foundation

//was removed from OAuthenticator

public struct DPoPTokenPayload: Codable, Hashable, Sendable {
	public let uniqueCode: String
	public let httpMethod: String
	public let httpRequestURL: String
	/// UNIX type, seconds since epoch
	public let createdAt: Int
	/// UNIX type, seconds since epoch
	public let expiresAt: Int
	public let nonce: String?

	public enum CodingKeys: String, CodingKey {
		case uniqueCode = "jti"
		case httpMethod = "htm"
		case httpRequestURL = "htu"
		case createdAt = "iat"
		case expiresAt = "exp"
		case nonce
	}

	public init(
		httpMethod: String,
		httpRequestURL: String,
		createdAt: Int,
		expiresAt: Int,
		nonce: String? = nil
	) {
		self.uniqueCode = UUID().uuidString
		self.httpMethod = httpMethod
		self.httpRequestURL = httpRequestURL
		self.createdAt = createdAt
		self.expiresAt = expiresAt
		self.nonce = nonce
	}
}
