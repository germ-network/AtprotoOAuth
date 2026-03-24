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
import GermConvenience
import Microcosm
import OAuth
import SwiftUI

@Observable final class LoginDemoVM {
	enum State {
		case collectHandle
		case validating(String)
		case agentCreated(AtprotoOAuthAgent)
		case loggedIn(AtprotoOAuthAgent)
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
				let resolver = AtprotoLegacyResolver(
					resourceFetcher: URLSession.shared)
				let resolvedDid = try await resolver.resolve(handle: handle)
				logs.append(
					.init(
						body:
							"Resolved DID: \(resolvedDid.stringRepresentation)"
					))

				let sessionArchive =
					try await AtprotoOAuthAgent
					.authorize(
						identity: .did(resolvedDid, handle: handle),
						resolver: resolver,
						authFetcher: URLSession.manualRedirect(),
						appCredentials: .init(
							clientId:
								"https://static.germnetwork.com/client-metadata.json",
							scopes: ["atproto", "transition:generic"],
							callbackURL: URL(
								string:
									"com.germnetwork.static:/oauth"
							)!
						),
						userAuthenticator:
							ASWebAuthenticationSession.userAuthenticator()
					)
				logs.append(.init(body: "Authorized OAuth agent"))

				let (oauthAgent, _) = try AtprotoOAuthAgent.restore(
					archive: .init(
						did: resolvedDid.stringRepresentation,
						session: sessionArchive),
					appCredentials: .init(
						clientId:
							"https://static.germnetwork.com/client-metadata.json",
						scopes: ["atproto", "transition:generic"],
						callbackURL: URL(
							string: "com.germnetwork.static:/oauth")!
					),
					userAuthenticator:
						ASWebAuthenticationSession.userAuthenticator(),
					authFetcher: URLSession.manualRedirect(),
					atprotoResolver: resolver,
				)
				logs.append(.init(body: "Restored OAuth agent"))
				state = .loggedIn(oauthAgent)

				//make an auth request
				let client = AtprotoClient(agent: oauthAgent)
				let profileMetadata = try await client.authRequest(
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
}
