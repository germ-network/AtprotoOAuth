//
//  LoginVM.swift
//  atprotoOAuthDemo
//
//  Created by Mark @ Germ on 2/19/26.
//

import ATProtoClient
import ATProtoOAuth
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

	var handle: String = ""

	var log: [String] = []

	func login() {

	}
}
