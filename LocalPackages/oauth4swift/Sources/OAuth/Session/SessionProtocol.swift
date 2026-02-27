//
//  SessionProtocol.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/22/26.
//

import Crypto
import Foundation
import GermConvenience

public protocol OAuthSession: Actor, TokenHandling, DPoPNonceHolding {
	static func response(for: URLRequest) async throws -> HTTPDataResponse

	var appCredentials: AppCredentials { get }
	var pkceVerifier: PKCEVerifier { get }

	var lazyServerMetadata: LazyResource<AuthServerMetadata> { get }

	var session: SessionState { get throws }
	func refreshed(sessionMutable: SessionState.Mutable) throws
	var refreshTask: Task<SessionState.Mutable, Error>? { get set }
}

public protocol TokenHandling {
	//	static func loginProvider(params: LoginProviderParameters) async throws -> SessionState.Archive

	func refreshProvider(
		sessionState: SessionState.Archive,
		appCredentials: AppCredentials,
		//		urlResponseProvider: URLResponseProvider
		//URLResponseProvider expect to use the response
	) async throws -> SessionState.Mutable
}
