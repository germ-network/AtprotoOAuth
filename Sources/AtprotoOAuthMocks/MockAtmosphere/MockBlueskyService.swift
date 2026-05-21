//
//  MockBlueskyService.swift
//  AtprotoGerm
//
//  Created by Mark @ Germ on 4/8/26.
//

import AtprotoClient
import AtprotoTypes
import Foundation
import GermConvenience

extension MockAtmosphere {
	func blueskyProxyResponse(
		authedDid: Atproto.DID,
		xrpcComponents: XRPCRequestComponents
	) async throws -> HTTPDataResponse {
		let request = try xrpcComponents.constructUrl(
			serviceUrl: URL(string: "https://public.api.bsky.app").tryUnwrap
		)
		let requestUrl = try request.request.url.tryUnwrap

		let components = try URLComponents(
			url: requestUrl,
			resolvingAgainstBaseURL: false
		).tryUnwrap

		let pathComponents = requestUrl.pathComponents
		switch pathComponents[1] {
		case "xrpc":
			//TODO: determine auth from headers
			return try await handleProxyXrpc(
				xrpcNsid: .init(string: pathComponents[2]),
				queryItems: components.queryItems,
				body: xrpcComponents.body,
				authedDid: authedDid
			)
		default:
			throw HTTPResponseError.unsuccessfulString(400, "InvalidRequest")
		}
	}

	func blueskyPublicServiceResponse(
		xrpcComponents: XRPCRequestComponents
	) async throws -> HTTPDataResponse {
		let request = try xrpcComponents.constructUrl(
			serviceUrl: URL(string: "https://public.api.bsky.app").tryUnwrap
		)
		let requestUrl = try request.request.url.tryUnwrap

		let components = try URLComponents(
			url: requestUrl,
			resolvingAgainstBaseURL: false
		).tryUnwrap

		let pathComponents = requestUrl.pathComponents
		switch pathComponents[1] {
		case "xrpc":
			return try await handlePublicXrpc(
				xrpcNsid: .init(string: pathComponents[2]),
				queryItems: components.queryItems,
				body: xrpcComponents.body,
			)
		default:
			throw HTTPResponseError.unsuccessfulString(400, "InvalidRequest")
		}
	}

	private func handleProxyXrpc(
		xrpcNsid: Atproto.NSID,
		queryItems: [URLQueryItem]?,
		body: Data?,
		authedDid: Atproto.DID,
	) async throws -> HTTPDataResponse {
		switch xrpcNsid {
		case Lexicon.App.Bsky.Actor.GetProfile.Id.nsid:
			return try await handleGetDetailedProfile(
				queryItems: queryItems,
				authedDid: authedDid
			)
		default:
			throw Errors.notImplemented
		}
	}

	private func handleGetRecordProfile(
		queryParameters: [String: String],
		authedDid: Atproto.DID,
	) async throws -> HTTPDataResponse {
		let repo = try queryParameters["repo"].tryUnwrap
		let did = try Atproto.DID(string: repo)

		let output = Lexicon.Com.Atproto.Repo.GetRecord<
			Lexicon.App.Bsky.Actor.Profile
		>.Output(
			uri: .mock(),
			cid: Atproto.CID.mock().string,
			value: try await profile(did: did)
		)

		return .init(
			data: try JSONEncoder().encode(output),
			response: .init(status: .ok)
		)
	}

	private func profile(
		did: Atproto.DID,
	) async throws -> Lexicon.App.Bsky.Actor.Profile {
		let actorProfile = try await pds(for: did)
			.tryUnwrap
			.getBskyProfile(did: did)

		return .init(
			avatar: nil,
			banner: nil,
			createdAt: .distantPast,
			description: actorProfile?.description,
			displayName: actorProfile?.displayName,
			pronouns: actorProfile?.pronouns,
			website: nil
		)
	}

	private func profileView(
		did: Atproto.DID,
	) async throws -> Lexicon.App.Bsky.Actor.Defs.ProfileView {
		let actorProfile = try await pds(for: did)
			.tryUnwrap
			.getBskyProfile(did: did)
		let handle = try await verifiedResolve(atIdentifier: .did(did))
			.tryUnwrap
			.verifiedHandle

		return .init(
			did: did,
			handle: handle,
			displayName: actorProfile?.displayName,
			pronouns: actorProfile?.pronouns,
			description: actorProfile?.description,
			avatar: nil,
			indexedAt: .init(date: .now),
			createdAt: .init(date: .distantPast),
			viewer: nil
		)
	}

	private func handleGetDetailedProfile(
		queryItems: [URLQueryItem]?,
		authedDid: Atproto.DID?,
	) async throws -> HTTPDataResponse {
		let actor = try (queryItems?["actor"]).tryUnwrap
		let actorDid = try Atproto.DID(string: actor)

		let output = try await detailedProfile(
			actor: actorDid,
			authedViewer: authedDid
		)

		return .init(
			data: try JSONEncoder().encode(output),
			response: .init(status: .ok)
		)
	}

	private func detailedProfile(
		actor: Atproto.DID,
		authedViewer: Atproto.DID?,
	) async throws -> Lexicon.App.Bsky.Actor.Defs.ProfileViewDetailed {

		let (actorFollows, actorBlocks) = try await pds(for: actor)
			.tryUnwrap
			.getGraph(did: actor)

		let actorProfile = try await pds(for: actor)
			.tryUnwrap
			.getBskyProfile(did: actor)
		let handle = try await verifiedResolve(atIdentifier: .did(actor))
			.tryUnwrap
			.verifiedHandle

		let viewer: Lexicon.App.Bsky.Actor.Defs.ViewerState? = try await {
			guard let authedViewer else {
				return nil
			}
			let (viewerFollows, viewerBlocks) = try await pds(for: authedViewer)
				.tryUnwrap
				.getGraph(did: authedViewer)

			/// Indicates whether the authed user has been blocked by the account requested. Optional.
			let blockedBy = actorBlocks.contains {
				$0.subject == authedViewer
			}

			let blocking = viewerBlocks.contains {
				$0.subject == actor
			}

			let followedBy = actorFollows.contains {
				$0.subject == authedViewer
			}

			let following = viewerFollows.contains {
				$0.subject == actor
			}

			return .init(
				muted: nil,
				blockedBy: blockedBy ? true : nil,
				blocking: blocking ? .mock() : nil,
				following: following ? .mock() : nil,
				followedBy: followedBy ? .mock() : nil
			)
		}()

		return .init(
			did: actor,
			handle: handle,
			displayName: actorProfile?.displayName,
			description: actorProfile?.description,
			pronouns: actorProfile?.pronouns,
			website: nil,
			avatar: nil,
			banner: nil,
			followersCount: 2,
			followsCount: 5,
			postsCount: 10,
			indexedAt: .init(date: .now),
			createdAt: .init(date: .distantPast),
			viewer: viewer
		)
	}

	private func handlePublicXrpc(
		xrpcNsid: Atproto.NSID,
		queryItems: [URLQueryItem]?,
		body: Data?,
	) async throws -> HTTPDataResponse {
		switch xrpcNsid {
		case Lexicon.Com.Atproto.Repo.GetRecordNSID.nsid:
			return try await handleGetRecord(
				queryItems: queryItems,
				body: body
			)
		case Lexicon.App.Bsky.Actor.GetProfile.Id.nsid:
			return try await handleGetDetailedProfile(
				queryItems: queryItems,
				authedDid: nil
			)
		case Lexicon.App.Bsky.Graph.GetRelationships.Id.nsid:
			return try await handleGetRelationships(
				queryItems: queryItems,
			)
		default:
			throw Errors.notImplemented
		}
	}

	private func handleGetRecord(
		queryItems: [URLQueryItem]?,
		body: Data?,
	) async throws -> HTTPDataResponse {
		let did = try Atproto.DID(
			string: (queryItems?["repo"]).tryUnwrap
		)

		return try await pds(for: did)
			.tryUnwrap
			.getRecord(queryItems: queryItems)
	}

	private func handleGetRelationships(
		queryItems: [URLQueryItem]?,
	) async throws -> HTTPDataResponse {
		let actor = try (queryItems?["actor"]).tryUnwrap
		let others = queryItems?
			.filter { $0.name == "other" }
			.compactMap(\.value)
			.compactMap { try? LexiconString.AtIdentifier(string: $0) }

		let output = try await getRelationships(
			actor: .init(string: actor),
			others: others
		)

		return .init(
			data: try JSONEncoder().encode(output),
			response: .init(status: .ok)
		)
	}

	private func getRelationships(
		actor: LexiconString.AtIdentifier,
		others: [LexiconString.AtIdentifier]?
	) async throws -> Lexicon.App.Bsky.Graph.GetRelationships.Output {
		guard case .did(let actorDid) = actor else {
			throw Errors.notImplemented
		}

		var relationships: [Lexicon.App.Bsky.Graph.GetRelationships.Result] = []
		for target in others ?? [] {
			do {
				relationships
					.append(
						try await getRelationship(
							actor: actorDid,
							target: target
						)
					)
			} catch {
				Self.logger
					.error("Computing getRelationship for \(target), \(error)")
			}
		}

		return .init(
			actor: actorDid,
			relationships: relationships
		)
	}

	private func getRelationship(
		actor: Atproto.DID,
		target: LexiconString.AtIdentifier
	) async throws -> Lexicon.App.Bsky.Graph.GetRelationships.Result {
		guard case .did(let targetDid) = target else {
			throw Errors.notImplemented
		}

		guard let targetPds = try self.pds(for: targetDid) else {
			return .notFoundActor(.init(actor: .did(actor)))
		}

		let (actorFollows, actorBlocks) = try await pds(for: actor)
			.tryUnwrap
			.getGraph(did: actor)

		let (targetFollows, targetBlocks) =
			try await targetPds
			.getGraph(did: targetDid)

		let blockedBy = targetBlocks.contains {
			$0.subject == actor
		}

		let blocking = actorBlocks.contains {
			$0.subject == targetDid
		}

		let followedBy = targetFollows.contains {
			$0.subject == actor
		}

		let following = actorFollows.contains {
			$0.subject == targetDid
		}

		return .relationship(
			.init(
				did: actor,
				blocking: blocking ? .mock() : nil,
				blockedBy: blockedBy ? .mock() : nil,
				following: following ? .mock() : nil,
				followedBy: followedBy ? .mock() : nil,
				blockedByList: nil,
				blockingbyList: nil
			)
		)
	}
}
