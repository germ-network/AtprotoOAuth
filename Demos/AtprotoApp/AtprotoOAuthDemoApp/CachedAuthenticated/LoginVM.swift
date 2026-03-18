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
import GermConvenience
import OAuth
import os

//has a storage that my

@Observable final class SessionVM {
	static let logger = Logger(
		subsystem: "com.germnetwork.ATProtoLiteClient",
		category: "SessionVM")

	let oauthClient = AtprotoOAuthClient(
		appCredentials: .init(
			clientId: "https://static.germnetwork.com/client-metadata.json",
			scopes: ["atproto", "transition:generic"],
			callbackURL: URL(string: "com.germnetwork.static:/oauth")!
		),
		userAuthenticator: ASWebAuthenticationSession.userAuthenticator(),
		resourceFetcher: URLSession.shared,
		authFetcher: URLSession.manualRedirect(),
		atprotoClient: AtprotoClient(
			resourceFetcher: URLSession.shared
		),
	)

	let handle: String
	let sessionStorage: InMemorySessionStore

	var processingTask: (Task<Void, Error>, String)? = nil
	var session: SessionWrapper? = nil

	var blocked: Bool? = nil
	var blocking: Bool? = nil
	var following: Bool? = nil
	var followedBy: Bool? = nil

	var messageDelegate: Lexicon.Com.GermNetwork.Declaration? = nil

	init(did: Atproto.DID, handle: String) {
		self.handle = handle
		self.sessionStorage = .init(did: did)
	}

	func login() {
		guard sessionStorage.sessionArchive == nil else {
			Self.logger.error("already have a valid token")
			return
		}
		guard processingTask == nil else {
			Self.logger.error("Can't login with pending task")
			return
		}

		let authenticatingTask = Task {
			let sessionArchive =
				try await oauthClient
				.authorize(identity: .did(sessionStorage.did, handle: handle))

			assert(sessionStorage.sessionArchive == nil)
			sessionStorage.sessionArchive = sessionArchive

			let (session, saveStream) = try AtprotoOAuthSessionImpl.restore(
				archive: .init(
					did: sessionStorage.did.stringRepresentation,
					session: sessionArchive,
				),
				appCredentials: oauthClient.appCredentials,
				resourceFetcher: URLSession.shared,
				authFetcher: URLSession.manualRedirect(),
				atprotoClient: AtprotoClient(
					resourceFetcher: URLSession.shared
				),
			)

			if !Task.isCancelled {
				self.session = .init(
					session: session,
					saveStream: saveStream,
				) {
					for await value in saveStream {
						guard !Task.isCancelled else {
							return
						}
						self.saved(update: value)
					}
				}
			}
		}
		self.processingTask = (authenticatingTask, "Authenticating")

		Task {
			do {
				let _ = try await authenticatingTask.value
				if self.processingTask?.0 == authenticatingTask {
					self.processingTask = nil
				}
			} catch {
				Self.logger.error(
					"Error: authenticating \(error.localizedDescription)")
				self.processingTask = nil
			}
		}
	}

	private func saved(update: SessionState.Mutable?) {
		//if we get nil, signifies we tear down the session
		guard let update else {
			self.sessionStorage.sessionArchive = nil
			return
		}
		guard let existing = self.sessionStorage.sessionArchive else {
			Self.logger.error("saving without an archive to save to")
			return
		}
		self.sessionStorage.sessionArchive =
			existing
			.merge(update: update)
	}

	//clear inMemory state
	func sleep() {
		guard let session else {
			Self.logger.error("missing session")
			return
		}
		session.saveTask.cancel()

		self.session = nil
	}

	func restore() {
		guard let archive = sessionStorage.sessionArchive else {
			Self.logger.error("tried to restore without an archive")
			return
		}
		let restoreTask = Task {
			let (restored, saveStream) = try AtprotoOAuthSessionImpl.restore(
				archive: .init(
					did: sessionStorage.did.stringRepresentation,
					session: archive,
				),
				appCredentials: oauthClient.appCredentials,
				resourceFetcher: URLSession.shared,
				authFetcher: URLSession.manualRedirect(),
				atprotoClient: AtprotoClient(
					resourceFetcher: URLSession.shared
				),
			)
			if !Task.isCancelled {
				self.session = .init(
					session: restored,
					saveStream: saveStream,
				) {
					for await value in saveStream {
						guard !Task.isCancelled else {
							return
						}
						self.saved(update: value)
					}
				}
			}
		}
		self.processingTask = (restoreTask, "Restoring")

		Task {
			do {
				let _ = try await restoreTask.value
				if self.processingTask?.0 == restoreTask {
					self.processingTask = nil
				}
			} catch {
				Self.logger.error(
					"Error: authenticating \(error.localizedDescription)")
				self.processingTask = nil
			}
		}
	}

	func logout() {
		processingTask?.0.cancel()
		processingTask = nil
		session?.saveTask.cancel()
		session = nil
		sessionStorage.sessionArchive = nil
	}

	func getMetadata(for otherHandle: String) async throws {
		guard let session else {
			return
		}

		let otherDid = try await LoginDemoVM.fallbackResolve(handle: otherHandle)

		if let metadata = try await session.session.authRequest(
			Lexicon.App.Bsky.Actor.GetProfile.self,
			parameters: .init(actor: .did(otherDid))
		).viewer {
			blocking = metadata.blocking != nil
			blocked = metadata.blockedBy
			following = metadata.following != nil
			followedBy = metadata.followedBy != nil
		}
	}

	func getMessageDelegate() async throws {
		messageDelegate = try await oauthClient.atprotoClient.getGermMessagingDelegate(
			did: sessionStorage.did
		)
	}

	func postMessagingDelegate(for showButtonTo: Lexicon.Com.GermNetwork.ShowButtonTo)
		async throws
	{
		guard let session = session?.session as? AtprotoSession else {
			return
		}

		do {
			return try await oauthClient.atprotoClient.postGermMessagingDelegate(
				.init(
					version: "1.1.0",
					currentKey: Data("mock".utf8).base64EncodedData(),
					keyPackage: Data("mock".utf8).base64EncodedData(),
					messageMe: showButtonTo == .none
						? nil
						: .init(
							showButtonTo:
								.usersIFollow,
							messageMeUrl:
								"germnetwork.com"
						),
					continuityProofs: nil
				),
				did: sessionStorage.did,
				session: session
			)
			//			let _ = try await session.session.authProcedure(
			//				Lexicon.Com.Atproto.Repo.PutRecord<Lexicon.Com.GermNetwork.Declaration>
			//					.self,
			//				parameters: .init(
			//					repo: .did(sessionStorage.did),
			//					rkey: "self",
			//					record: record ?? .mock(),
			//					validate: true,
			//				)
			//			)
		} catch {
			Self.logger.error("Error posting message delegate: \(error)")
		}
	}
}

struct SessionWrapper {
	let session: AtprotoOAuthSession
	private let saveStream: AsyncStream<SessionState.Mutable?>
	//hold onto the save continuation
	let saveTask: Task<Void, Never>

	init(
		session: AtprotoOAuthSession,
		saveStream: AsyncStream<SessionState.Mutable?>,
		saveClosure: @escaping () async -> Void
	) {
		self.session = session
		self.saveStream = saveStream
		self.saveTask = Task { await saveClosure() }
	}
}
