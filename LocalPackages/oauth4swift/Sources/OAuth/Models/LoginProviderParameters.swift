//
//  LoginProviderParameters.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/23/26 from OAuthenticate
//

import Foundation

public struct LoginProviderParameters: Sendable {
	public let authorizationURL: URL
	public let credentials: AppCredentials
	public let redirectURL: URL
	public let responseProvider: URLResponseProvider
	public let stateToken: String
	public let pkceVerifier: PKCEVerifier?

	public init(
		authorizationURL: URL,
		credentials: AppCredentials,
		redirectURL: URL,
		responseProvider: @escaping URLResponseProvider,
		stateToken: String,
		pkceVerifier: PKCEVerifier?
	) {
		self.authorizationURL = authorizationURL
		self.credentials = credentials
		self.redirectURL = redirectURL
		self.responseProvider = responseProvider
		self.stateToken = stateToken
		self.pkceVerifier = pkceVerifier
	}
}

public typealias LoginProvider =
	@Sendable (LoginProviderParameters, DPoPKey) async throws -> SessionState
