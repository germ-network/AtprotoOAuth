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

	private func appendLog(_ body: String) {
		logs.append(.init(body: body))
	}

	func login(handle: String) {
		state = .validating(handle)
		Task {
			do {
				let resolver = AtprotoLegacyResolver(
					resourceFetcher: URLSession.shared)
				let resolvedDid = try await resolver.resolve(handle: handle)
				appendLog("Resolved DID: \(resolvedDid.stringRepresentation)")

				let sessionArchive =
					try await AtprotoOAuthAgent
					.authorize(
						identity: .did(resolvedDid, handle: handle),
						resolver: resolver,
						authFetcher: URLSession.manualRedirect(),
						clientMetadata: .init(
							clientId:
								"https://static.germnetwork.com/client-metadata.json",
							scopes: ["atproto", "transition:generic"],
							redirectURI: URL(
								string:
									"com.germnetwork.static:/oauth"
							)!
						),
						userAuthenticator:
							ASWebAuthenticationSession.userAuthenticator()
					)

				appendLog("Authorized OAuth agent")

				let (oauthAgent, _) = try AtprotoOAuthAgent.restore(
					archive: .init(
						did: resolvedDid.stringRepresentation,
						session: sessionArchive),
					clientMetadata: .init(
						clientId:
							"https://static.germnetwork.com/client-metadata.json",
						scopes: ["atproto", "transition:generic"],
						redirectURI: URL(
							string:
								"com.germnetwork.static:/oauth"
						)!
					),
					userAuthenticator:
						ASWebAuthenticationSession.userAuthenticator(),
					authFetcher: URLSession.manualRedirect(),
					atprotoResolver: resolver,
				)

				state = .loggedIn(oauthAgent)
				appendLog("Restored OAuth agent")

				//make an auth request
				let profileMetadata = try await oauthAgent.authBskyProfileViewerState(
					for: resolvedDid
				)

				debugPrint(profileMetadata)
				appendLog("Fetched profile metadata: \(profileMetadata)")
			} catch {
				appendLog("Error: \(error)")
			}
		}
	}

	func reset() {
		state = .collectHandle
		logs = []
	}
}
