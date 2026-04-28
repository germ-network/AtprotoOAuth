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
import OAuth4Swift
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

	let client = AtprotoOAuthClient(
		clientInfo: .demo,
		resolver: ATResolveResolver(resourceFetcher: URLSession.shared),
		authFetcher: URLSession.manualRedirect(),
		userAuthenticator: ASWebAuthenticationSession.userAuthenticator()
	)

	private func appendLog(_ body: String) {
		logs.append(.init(body: body))
	}

	func login(handle: String) {
		state = .validating(handle)
		Task {
			do {
				let resolver = ATResolveResolver(
					resourceFetcher: URLSession.shared)
				let resolvedDid = try await resolver.resolve(
					handle: .init(string: handle)
				)
					.tryUnwrap
				appendLog(
					"Resolved DID: \(resolvedDid.rawValue)"
				)

				let sessionArchive =
					try await client
					.authorize(
						identity:
								.did(
									resolvedDid,
									handle: .init(rawValue: handle)
								)
					)

				appendLog("Authorized OAuth agent")

				let (oauthAgent, _) = try client.restore(
					archive: .init(
						did: resolvedDid.rawValue,
						session: sessionArchive,
					),
				)

				state = .loggedIn(oauthAgent)
				appendLog("Restored OAuth agent")

				//make an auth request
				let profileMetadata =
					try await oauthAgent.authBskyProfileViewerState(
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
