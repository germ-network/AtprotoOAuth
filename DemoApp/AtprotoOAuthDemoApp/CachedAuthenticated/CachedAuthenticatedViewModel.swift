//
//  CachedAuthenticatedViewModel.swift
//  AtprotoOAuthDemoApp
//
//  Created by Mark @ Germ on 2/27/26.
//

import AtprotoClient
import AtprotoOAuth
import AtprotoTypes
import AuthenticationServices
import OAuth
import SwiftUI
import os

@MainActor
@Observable class CachedAuthenticatedViewModel {
	static let logger = Logger(
		subsystem: "com.germnetwork.ATProtoLiteClient",
		category: "CachedAuthenticatedViewModel")

	//	let oauthClient = AtprotoOAuthClient(
	//		appCredentials: .init(
	//			clientId: "https://static.germnetwork.com/client-metadata.json",
	//			scopes: ["atproto transition:generic"],
	//			callbackURL: URL(string: "com.germnetwork.static:/oauth")!
	//		),
	//		userAuthenticator: ASWebAuthenticationSession.userAuthenticator(),
	//		responseProvider: URLSession.defaultProvider,
	//		atprotoClient: AtprotoClient(
	//			responseProvider: URLSession.defaultProvider
	//		)
	//	)
	enum State {
		case entry(Error?)
		case handleToDid(Task<Atproto.DID, Error>)
		case login(String, Atproto.DID)
	}
	private(set) var state: State = .entry(nil)

	func check(
		_ handle: String,
		cachePolicy: NSURLRequest.CachePolicy = .useProtocolCachePolicy
	) {
		guard case .entry = state else {
			Self.logger.error("incorrect state")
			return
		}

		let task = Task {
			try await LoginDemoVM.fallbackResolve(handle: handle)

			//			let sessionArchive =
			//				try await oauthClient
			//				.authorize(identity: .did(resolvedDid))
			//
			//			return try AtprotoOAuthSession(
			//				archive: .init(
			//					did: resolvedDid.fullId,
			//					session: sessionArchive,
			//				),
			//				appCredentials: oauthClient.appCredentials,
			//				atprotoClient: AtprotoClient(
			//					responseProvider: URLSession.defaultProvider
			//				)
			//			)
		}
		state = .handleToDid(task)

		Task {
			do {
				let result = try await task.value
				state = .login(handle, result)
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

//extension CachedAuthenticatedViewModel {
//	//in-memory login store
//	@MainActor
//	@Observable class LoginStore {
//		let dPoPKey = P256.Signing.PrivateKey()
//		var login: Login?
//
//		var oauthStorage: OAuthStorage {
//			.init(
//				dpopKey: dPoPKey,
//				retrieveLogin: { await self.login },
//				storeLogin: { await self.store(login: $0) },
//				clearLogin: { await self.store(login: nil) }
//			)
//		}
//
//		private func store(login: Login?) {
//			self.login = login
//		}
//
//		func clear() {
//			self.login = nil
//		}
//	}
//}
