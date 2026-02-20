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
import OAuthenticator
import SwiftUI

@Observable final class LoginVM {
	let oauthClient = ATProtoOAuthClient(
		clientId: "https://static.germnetwork.com/client-metadata.json",
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
	var log: [LogEntry] = []

	func login(handle: String) {
		state = .validating(handle)
		Task {
			do {
				let resolvedDid = try await ATProtoOAuthClient.resolve(
					handle: handle
				)

				log.append(.init(body: "Resolved DID: \(resolvedDid.fullId)"))
			} catch {
				log.append(.init(body: "Error: \(error)"))
			}
		}
	}

	func reset() {
		state = .collectHandle
	}
}

extension LoginVM {
	enum State {
		case collectHandle
		case validating(String)

	}
}
