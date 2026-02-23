//
//  AuthorizationURLParameters.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/23/26.
//

import Foundation

public struct AuthorizationURLParameters: Sendable {
	public let credentials: AppCredentials
	public let parRequestURI: String
	public let stateToken: String
	public let responseProvider: URLResponseProvider

	public init(
		credentials: AppCredentials,
		parRequestURI: String,
		stateToken: String,
		responseProvider: @escaping URLResponseProvider
	) {
		self.credentials = credentials
		self.parRequestURI = parRequestURI
		self.stateToken = stateToken
		self.responseProvider = responseProvider
	}
}

/// The output of this is a URL suitable for user authentication in a browser.
public typealias AuthorizationURLProvider =
	@Sendable (AuthorizationURLParameters) async throws -> URL
