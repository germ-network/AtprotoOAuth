//
//  LoginVM.swift
//  AtprotoOAuthDemoApp
//
//  Created by Mark @ Germ on 2/27/26.
//

import AtprotoClient
import AtprotoOAuth
import AtprotoTypes
import AuthenticationServices
import Foundation
import OAuth
import os

@Observable final class LoginVM {
	static let logger = Logger(
		subsystem: "com.germnetwork.ATProtoLiteClient",
		category: "LoginView")

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

	var authenticatingTask: Task<Void, Error>? = nil
	var session: AtprotoOAuthSession? = nil

	func login(did: Atproto.DID) {
		guard authenticatingTask == nil else {
			Self.logger.error("Can't login with pending task")
			return
		}

		let authenticatingTask = Task {
			let sessionArchive =
				try await oauthClient
				.authorize(identity: .did(did))

			let (session, saveStream) = try AtprotoOAuthSessionImpl.restore(
				archive: .init(
					did: did.fullId,
					session: sessionArchive,
				),
				appCredentials: oauthClient.appCredentials,
				atprotoClient: AtprotoClient(
					responseProvider: URLSession.defaultProvider
				)
			)
			if !Task.isCancelled {
				self.session = session
			}
		}
		self.authenticatingTask = authenticatingTask

		Task {
			do {
				let _ = try await authenticatingTask.value
				if self.authenticatingTask == authenticatingTask {
					self.authenticatingTask = nil
				}
			} catch {
				Self.logger.error(
					"Error: authenticating \(error.localizedDescription)")
				self.authenticatingTask = nil
			}
		}
	}

	func clearLogin() {
		authenticatingTask?.cancel()
		authenticatingTask = nil
		session = nil
	}

	func postMessagingDelegate(did: Atproto.DID) async throws {
		guard let session else {
			return
		}

		try await session.authProcedure(
			Lexicon.Com.Atproto.Repo.PutRecord<Lexicon.Com.GermNetwork.Declaration>
				.self,
			parameters: .init(
				repo: .did(did),
				collection: Lexicon.Com.GermNetwork.Declaration.nsid,
				rkey: "self",
				record: .mock(),
				validate: true,
			)
		)
	}
	//	func postMessagingDelegate() {}

	//	func postMessagingDelegate(
	//		loginViewModel: ATProtoLiteClientViewModel
	//	) async throws {
	//		let myDID = try await ATProtoPublicAPI.getTypedDID(handle: storedHandle)
	//		if let myPDS = try await ATProtoPublicAPI.getPds(for: loginViewModel.did.fullId),
	//			let pdsURL = URL(string: myPDS)
	//		{
	//			let authenticator = try await loginViewModel.getAuthenticator(
	//				pdsURL: pdsURL)
	//			let _ = try await ATProtoAuthAPI.update(
	//				delegateRecord: GermLexicon.MessagingDelegateRecord(
	//					version: "2.3.0",
	//					currentKey: "testingKey".utf8Data,
	//					keyPackage: "testingKeyPackage".utf8Data,
	//					messageMe: GermLexicon.MessageMeInstructions(
	//						showButtonTo: .everyone,
	//						messageMeUrl: "message-me-url.com"
	//					),
	//					continuityProofs: ["proof1".utf8Data, "proof2".utf8Data]
	//				),
	//				for: myDID.fullId,
	//				pdsURL: pdsURL,
	//				authenticator: authenticator.authenticator
	//			)
	//		}
	//	}
}
