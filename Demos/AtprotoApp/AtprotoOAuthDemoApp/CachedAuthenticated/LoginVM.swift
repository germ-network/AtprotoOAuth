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
import Microcosm
import OAuth4Swift
import os

//has a storage that my

@Observable final class SessionVM {
	static let logger = Logger(
		subsystem: "com.germnetwork.AtprotoOAuthDemoApp",
		category: "SessionVM")

	let handle: String
	let did: Atproto.DID

	var processingTask: (Task<Void, Error>, String)? = nil
	let client: AtprotoOAuthClient
	var authedClient: AtprotoOAuthAgent? = nil
	let resolver: Atproto.Resolver

	var sessionWrapper: SessionWrapper? = nil
	var sessionStorage: InMemorySessionStore

	var blocked: Bool? = nil
	var blocking: Bool? = nil
	var following: Bool? = nil
	var followedBy: Bool? = nil

	var blockingTask: Task<Void, Never>? = nil
	var blockResult: String? = nil

	var messageDelegate: Lexicon.Com.GermNetwork.Declaration? = nil

	init(did: Atproto.DID, handle: String, resolver: Atproto.Resolver) {
		self.handle = handle
		self.did = did
		self.resolver = resolver
		self.sessionStorage = .init(did: did)

		self.client = AtprotoOAuthClient(
			clientInfo: .demo,
			resolver: resolver,
			authFetcher: URLSession.manualRedirect(),
			userAuthenticator: ASWebAuthenticationSession.userAuthenticator()
		)
	}

	func login() {
		guard processingTask == nil else {
			Self.logger.error("Can't login with pending task")
			return
		}

		let authenticatingTask = Task {
			if authedClient != nil {
				Self.logger.error("already have an authed client")
				return
			}

			let sessionState = try await client.authorize(
				identity: .did(did, handle: .init(string: handle))
			)

			let (oauthAgent, saveStream) =
				try client
				.restore(
					archive:
						.init(
							did: did.rawValue,
							session: sessionState
						)
				)

			if !Task.isCancelled {
				self.authedClient = oauthAgent
				self.sessionWrapper = .init(
					agent: oauthAgent,
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

	private func saved(update: OAuth.SessionState.Archive.Mutable?) {
		//if we get nil, signifies we tear down the session
		guard let update else {
			self.sessionStorage.sessionArchive = nil
			return
		}
		guard var editState = self.sessionStorage.sessionArchive else {
			Self.logger.error("saving without an archive to save to")
			return
		}
		editState.clientAuth = update.clientAuth
		editState.tokenState = update.tokenState
		self.sessionStorage.sessionArchive = editState
	}

	//clear inMemory state
	func sleep() {
		guard let sessionWrapper else {
			Self.logger.error("missing session")
			return
		}
		sessionWrapper.saveTask.cancel()

		self.sessionWrapper = nil
	}

	func restore() {
		guard let archive = sessionStorage.sessionArchive else {
			Self.logger.error("tried to restore without an archive")
			return
		}
		let restoreTask = Task {
			let (restored, saveStream) = try client.restore(
				archive: .init(
					did: sessionStorage.did.rawValue,
					session: archive,
				),
			)
			if !Task.isCancelled {
				self.authedClient = restored
				self.sessionWrapper = .init(
					agent: restored,
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
		sessionWrapper?.saveTask.cancel()
		sessionWrapper = nil
		authedClient = nil
	}

	func getMetadata(for otherHandle: String) async throws {
		guard let authedClient else {
			return
		}
		let otherDid = try await resolver.resolve(
			handle: .init(string: otherHandle)
		).tryUnwrap
		let metadata = try await authedClient.authBskyProfileViewerState(for: otherDid)
		blocking = metadata.blocking != nil
		blocked = metadata.blockedBy
		following = metadata.following != nil
		followedBy = metadata.followedBy != nil
	}

	func getMessageDelegate() async throws {
		messageDelegate =
			try await lazyPDSAgent
			.getGermMessagingDelegate()
	}

	private var lazyPDSAgent: PublicPDSAgent {
		get async throws {
			let pdsUrl = try await Microcosm.Slingshot(
				resourceFetcher: URLSession.shared
			)
			.resolveMiniDoc(identifier: .did(did))
			.tryUnwrap
			.pds

			return PublicPDSAgent(
				did: did,
				resourceFetcher: URLSession.shared,
				serviceUrl: pdsUrl
			)
		}
	}

	func blockUser(_ otherHandle: String) {
		guard let authedClient else {
			return
		}
		blockingTask = Task {
			do {
				let otherDid =
					try await resolver
					.resolve(handle: .init(string: otherHandle))
					.tryUnwrap
				let _ = try await authedClient.createRecord(
					Lexicon.App.Bsky.Graph.Block.init(subject: otherDid)
				)
				blockResult = "Blocked @\(otherHandle)!"
			} catch {
				blockResult = error.localizedDescription
			}
		}
		Task {
			await blockingTask?.value
			blockingTask = nil
		}
	}

	func postMessagingDelegate(for showButtonTo: Lexicon.Com.GermNetwork.ShowButtonTo)
		async throws
	{
		guard let authedClient else {
			return
		}

		do {
			return try await authedClient.postGermMessagingDelegate(
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
				)
			)
		} catch {
			Self.logger.error("Error posting message delegate: \(error)")
		}
	}
}

struct SessionWrapper {
	// TODO: I don't know that the agent is the right thing to store here
	let agent: AtprotoOAuthAgent
	private let saveStream: AsyncStream<OAuth.SessionState.Archive.Mutable?>
	//hold onto the save continuation
	let saveTask: Task<Void, Never>

	init(
		agent: AtprotoOAuthAgent,
		saveStream: AsyncStream<OAuth.SessionState.Archive.Mutable?>,
		saveClosure: @escaping () async -> Void
	) {
		self.agent = agent
		self.saveStream = saveStream
		self.saveTask = Task { await saveClosure() }
	}
}
