//
//  PARConfiguration.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/22/26 from OAuthenticator
//

import Foundation

public struct PARConfiguration: Hashable, Sendable {
	public let url: URL
	public let parameters: [String: String]

	public init(url: URL, parameters: [String: String] = [:]) {
		self.url = url
		self.parameters = parameters
	}
}

public struct PARResponse: Codable, Hashable, Sendable {
	public let requestURI: String
	public let expiresIn: Int

	enum CodingKeys: String, CodingKey {
		case requestURI = "request_uri"
		case expiresIn = "expires_in"
	}
}
