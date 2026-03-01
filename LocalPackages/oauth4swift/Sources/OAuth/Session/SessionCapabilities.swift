//
//  SessionCapabilities.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/22/26.
//

import Crypto
import Foundation
import GermConvenience

public protocol OAuthSessionCapabilities: Actor, TokenHandling, DPoPNonceHolding {
	var appCredentials: AppCredentials { get }
	var pkceVerifier: PKCEVerifier { get }

	var lazyServerMetadata: LazyResource<AuthServerMetadata> { get }

	var session: SessionState { get throws }
	func refreshed(sessionMutable: SessionState.Mutable) throws
	var refreshTask: Task<SessionState.Mutable, Error>? { get set }
}

public protocol TokenHandling {
	func refreshProvider(
		sessionState: SessionState.Archive,
		appCredentials: AppCredentials,
	) async throws -> SessionState.Mutable
}
