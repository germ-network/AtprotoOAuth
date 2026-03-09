//
//  AuthorizerImpl.swift
//  AtprotoOAuth
//
//  Created by Mark @ Germ on 2/26/26.
//

import AtprotoTypes
import Foundation
import GermConvenience
import Logging
import OAuth

//a container for a nonce cache for getting authorization
//it should only make requests as necessary to authorize

actor AuthorizerImpl {
	static let logger = Logger(label: "AuthorizerImpl")

	let appCredentials: AppCredentials
	let authFetcher: HTTPFetcher

	let issuer: URL

	let stateToken = UUID().uuidString
	let dpopKey = DPoPKey.generateP256()
	let nonceCache: NSCache<NSString, IndexedNonce> = NSCache()
	let pkceVerifier = PKCEVerifier()

	init(
		issuer: URL,
		appCredentials: AppCredentials,
		authFetcher: HTTPFetcher
	) {
		self.issuer = issuer
		self.appCredentials = appCredentials
		self.authFetcher = authFetcher
	}
}

extension AuthorizerImpl: AuthorizerCapabilities {
	public static func authorizationURL(
		authEndpoint: URL,
		parRequestURI: String,
		clientId: String,
	) throws -> URL {
		var components = URLComponents(url: authEndpoint, resolvingAgainstBaseURL: false)

		components?.queryItems = [
			URLQueryItem(name: "request_uri", value: parRequestURI),
			URLQueryItem(name: "client_id", value: clientId),
		]

		guard let url = components?.url else {
			throw OAuthSessionError.cantFormURL
		}

		return url
	}
}
