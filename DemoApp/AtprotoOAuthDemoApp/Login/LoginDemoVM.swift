//
//  LoginVM.swift
//  atprotoOAuthDemo
//
//  Created by Mark @ Germ on 2/19/26.
//

import AtprotoClient
import AtprotoOAuth
import AtprotoTypes
import AuthenticationServices
import Foundation
import Microcosm
import OAuth
import SwiftUI

@Observable final class LoginDemoVM {
	let oauthClient = AtprotoOAuthClient(
		appCredentials: .init(
			clientId: "https://static.germnetwork.com/client-metadata.json",
			scopes: ["atproto transition:generic"],
			callbackURL: URL(string: "com.germnetwork.static:/oauth")!
		),
		userAuthenticator: ASWebAuthenticationSession.userAuthenticator(),
		responseProvider: URLSession.defaultProvider,
		atprotoClient: AtprotoClient(
			responseProvider: URLSession.defaultProvider
		)
	)

	enum State {
		case collectHandle
		case validating(String)
		case loggedIn(AtprotoOAuthSession)
	}
	var state: State = .collectHandle
	struct LogEntry: Identifiable {
		let id: UUID = .init()
		let body: String
	}
	var logs: [LogEntry] = []

	func login(handle: String) {
		state = .validating(handle)
		Task {
			do {
				let resolvedDid = try await Self.fallbackResolve(handle: handle)

				logs.append(.init(body: "Resolved DID: \(resolvedDid.fullId)"))

				let messageDelegate = try await AtprotoClient(
					responseProvider: URLSession.defaultProvider
				)
				.getGermMessagingDelegate(did: resolvedDid)

				if messageDelegate != nil {
					logs.append(.init(body: "Found a message delegate"))
				} else {
					logs.append(.init(body: "Didn't find a message delegate"))
				}

				let sessionArchive =
					try await oauthClient
					.authorize(identity: .did(resolvedDid))

				let (session, saveStream) =
					try AtprotoOAuthSessionImpl
					.restore(
						archive: .init(
							did: resolvedDid.fullId,
							session: sessionArchive,
						),
						appCredentials: oauthClient.appCredentials,
						atprotoClient: AtprotoClient(
							responseProvider: URLSession.defaultProvider
						)
					)
				state = .loggedIn(session)

				//make an auth request
				let profileMetadata = try await session.authRequest(
					Lexicon.App.Bsky.Actor.GetProfile.self,
					parameters: .init(actor: .did(resolvedDid))
				)
			} catch {
				logs.append(.init(body: "Error: \(error)"))
			}
		}
	}

	func reset() {
		state = .collectHandle
		logs = []
	}

	static func fallbackResolve(handle: String) async throws -> Atproto.DID {
		do {
			return try await Slingshot.resolve(handle: handle)
		} catch {
			return try await AtprotoOAuthClient.resolve(
				handle: handle
			)
		}
	}
}
