//
//  CachedAuthenticatedViewModel.swift
//  AtprotoOAuthDemoApp
//
//  Created by Mark @ Germ on 2/27/26.
//

import ATResolve
import AtprotoClient
import AtprotoOAuth
import AtprotoTypes
import AuthenticationServices
<<<<<<< HEAD
import OAuth4Swift
=======
import GermConvenience
import OAuth
>>>>>>> main
import SwiftUI
import os

@MainActor
@Observable class CachedAuthenticatedViewModel {
	let resolver = ATResolveResolver(
		resourceFetcher: URLSession.shared
	)
	static let logger = Logger(
		subsystem: "com.germnetwork.ATProtoLiteClient",
		category: "CachedAuthenticatedViewModel")

	enum State {
		case entry(Error?)
		case handleToDid(Task<Atproto.DID, Error>)
		case login(SessionVM)
	}
	private(set) var state: State = .entry(nil)

	//commits to a did
	var sessionStore: InMemorySessionStore?

	func check(
		_ handle: String,
		cachePolicy: NSURLRequest.CachePolicy = .useProtocolCachePolicy
	) {
		guard case .entry = state else {
			Self.logger.error("incorrect state")
			return
		}

		let task = Task {
			try await resolver.resolve(handle: handle).tryUnwrap
		}
		state = .handleToDid(task)

		Task {
			do {
				let resolvedDid = try await task.value
				state = .login(
					.init(
						did: resolvedDid,
						handle: handle,
						resolver: resolver
					)
				)
			} catch {
				Self.logger.error(
					"Error: checking handle \(error.localizedDescription)")
				state = .entry(error)
			}
		}
	}

	func reset() {
		state = .entry(nil)
	}
}
