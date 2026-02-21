//
//  LoginVM.swift
//  atprotoOAuthDemo
//
//  Created by Mark @ Germ on 2/19/26.
//

import ATProtoClient
import ATProtoOAuth
import ATProtoTypes
import AuthenticationServices
import Foundation
import Microcosm
import OAuthenticator
import SwiftUI

@Observable final class LoginVM {
	let oauthClient = ATProtoOAuthClient(
//		clientId: "https://static.germnetwork.com/client-metadata.json",
		appCredentials: .init(
			clientId: "https://static.germnetwork.com/client-metadata.json",
			callbackURL: URL(string: "com.germnetwork.static:/oauth")!
		),
		userAuthenticator: ASWebAuthenticationSession.userAuthenticator(),
		authenticationStatusHandler: nil,
		responseProvider: URLSession.defaultProvider,
		atprotoClient: ATProtoClient(
			responseProvider: URLSession.defaultProvider
		)
	)

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
				let resolvedDid = try await fallbackResolve(handle: handle)

				logs.append(.init(body: "Resolved DID: \(resolvedDid.fullId)"))

				let messageDelegate =
					try await oauthClient
					.fetchFromPDS(did: resolvedDid) {
						pdsUrl, responseProvider in
						try await ATProtoClient(
							responseProvider: responseProvider
						)
						.getGermMessagingDelegate(
							did: resolvedDid, pdsURL: pdsUrl)
					}

				if messageDelegate != nil {
					logs.append(.init(body: "Found a message delegate"))
				} else {
					logs.append(.init(body: "Didn't find a message delegate"))
				}

				let sessionArchive =
					try await oauthClient
					.authorize(identity: .did(resolvedDid))
			} catch {
				logs.append(.init(body: "Error: \(error)"))
			}
		}
	}

	func reset() {
		state = .collectHandle
		logs = []
	}
	
	func fallbackResolve(handle: String) async throws -> ATProtoDID {
		do {
			return try await Slingshot.resolve(handle: handle)
		} catch {
			return try await ATProtoOAuthClient.resolve(
				handle: handle
			)
		}
	}
}

extension LoginVM {
	enum State {
		case collectHandle
		case validating(String)

	}
}
