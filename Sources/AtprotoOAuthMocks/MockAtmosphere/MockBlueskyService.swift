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
		case Lexicon.App.Bsky.Graph.GetKnownFollowers.Id.nsid:
			return try await handleGetKnownFollowers(
				queryItems: queryItems,
				authedDid: authedDid
			)
		default:
			throw Errors.notImplemented
		}
	}

	private func handleGetKnownFollowers(
		queryItems: [URLQueryItem]?,
		authedDid: Atproto.DID,
	) async throws -> HTTPDataResponse {
		let actor = try (queryItems?["actor"]).tryUnwrap
		let actorDid = try Atproto.DID(string: actor)
		let limit = Self.clampedLimit((queryItems?["limit"]).flatMap(Int.init))
		let cursorParam = queryItems?["cursor"]

		//resume an in-flight query, or compute a fresh result set keyed by a new uuid
		let cursorId: UUID
		var remaining: [Atproto.DID]
		if let cursorParam {
			guard
				let id = UUID(uuidString: cursorParam),
				let stored = pendingKnownFollowers[id]
			else {
				throw Errors.invalidCursor
			}
			cursorId = id
			remaining = stored
		} else {
			cursorId = UUID()
			remaining = try await computeKnownFollowers(
				actor: actorDid,
				viewer: authedDid
			)
		}

		let pageSize = limit ?? remaining.count
		let page = Array(remaining.prefix(pageSize))
		remaining.removeFirst(page.count)

		let nextCursor: String?
		if remaining.isEmpty {
			pendingKnownFollowers[cursorId] = nil
			nextCursor = nil
		} else {
			pendingKnownFollowers[cursorId] = remaining
			nextCursor = cursorId.uuidString
		}

		var followerViews: [Lexicon.App.Bsky.Actor.Defs.ProfileView] = []
		for did in page {
			followerViews.append(try await profileView(did: did))
		}

		let output = Lexicon.App.Bsky.Graph.GetKnownFollowers.Output(
			subject: try await profileView(did: actorDid),
			cursor: nextCursor,
			followers: followerViews
		)

		return .init(
			data: try JSONEncoder().encode(output),
			response: .init(status: .ok)
		)
	}

	private func computeKnownFollowers(
		actor: Atproto.DID,
		viewer: Atproto.DID
	) async throws -> [Atproto.DID] {
		let (viewerFollows, _) = try await pds(for: viewer)
			.tryUnwrap
			.getGraph(did: viewer)
		let viewerFollowDids = Set(viewerFollows.map(\.subject))

		var found: [Atproto.DID] = []
		for candidate in didDocs.keys
		where candidate != actor && candidate != viewer
			&& viewerFollowDids.contains(candidate)
		{
			let (candidateFollows, _) = try await pds(for: candidate)
				.tryUnwrap
				.getGraph(did: candidate)
			if candidateFollows.contains(where: { $0.subject == actor }) {
				found.append(candidate)
			}
		}

		//deterministic order; mock has no native ordering
		found.sort { $0.rawValue < $1.rawValue }
		return found
	}

	//mirrors GetKnownFollowers.Parameters.boundLimit: clamp to 1...100
	private static func clampedLimit(_ limit: Int?) -> Int? {
		guard let limit else { return nil }
		switch limit {
		case 100...: return 100
		case ...1: return 1
		default: return limit
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
			associated: nil,
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
			associated: nil,
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
			.filter { $0.name == "others" }
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
				did: targetDid,
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
