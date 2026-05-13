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
		let queryParameters = try components.queryItems.tryUnwrap.asDictionary

		let pathComponents = requestUrl.pathComponents
		switch pathComponents[1] {
		case "xrpc":
			//TODO: determine auth from headers
			return try await handleProxyXrpc(
				xrpcNsid: .init(string: pathComponents[2]),
				queryParameters: queryParameters,
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
		let queryParameters = try components.queryItems.tryUnwrap.asDictionary

		let pathComponents = requestUrl.pathComponents
		switch pathComponents[1] {
		case "xrpc":
			return try await handlePublicXrpc(
				xrpcNsid: .init(string: pathComponents[2]),
				queryParameters: queryParameters,
				body: xrpcComponents.body,
			)
		default:
			throw HTTPResponseError.unsuccessfulString(400, "InvalidRequest")
		}
	}

	private func handleProxyXrpc(
		xrpcNsid: Atproto.NSID,
		queryParameters: [String: String],
		body: Data?,
		authedDid: Atproto.DID,
	) async throws -> HTTPDataResponse {
		switch xrpcNsid {
		case Lexicon.App.Bsky.Actor.GetProfile.Id.nsid:
			return try await handleGetDetailedProfile(
				queryParameters: queryParameters,
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
		queryParameters: [String: String],
		authedDid: Atproto.DID?,
	) async throws -> HTTPDataResponse {
		let actor = try queryParameters["actor"].tryUnwrap
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

		let (subjectFollows, subjectBlocks) = try await pds(for: actor)
			.getGraph(did: actor)

		let actorProfile = try await pds(for: actor)
			.getBskyProfile(did: actor)
		let handle = try await verifiedResolve(atIdentifier: .did(actor))
			.tryUnwrap
			.verifiedHandle

		let viewer: Lexicon.App.Bsky.Actor.Defs.ViewerState? = try await {
			guard let authedViewer else {
				return nil
			}
			let (viewerFollows, viewerBlocks) = try await pds(for: authedViewer)
				.getGraph(did: authedViewer)

			/// Indicates whether the authed user has been blocked by the account requested. Optional.
			let blockedBy = subjectBlocks.contains {
				$0.subject == authedViewer
			}

			let blocking = viewerBlocks.contains {
				$0.subject == actor
			}

			let followedBy = subjectFollows.contains {
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
		queryParameters: [String: String],
		body: Data?,
	) async throws -> HTTPDataResponse {
		switch xrpcNsid {
		case Lexicon.Com.Atproto.Repo.GetRecordNSID.nsid:
			return try await handleGetRecord(
				queryParameters: queryParameters,
				body: body
			)
		case Lexicon.App.Bsky.Actor.GetProfile.Id.nsid:
			return try await handleGetDetailedProfile(
				queryParameters: queryParameters,
				authedDid: nil
			)

		default:
			throw Errors.notImplemented
		}
	}

	private func handleGetRecord(
		queryParameters: [String: String],
		body: Data?,
	) async throws -> HTTPDataResponse {
		let did = try Atproto.DID(
			string: queryParameters["repo"].tryUnwrap
		)

		return try await pds(for: did)
			.getRecord(queryParameters: queryParameters)
	}
}
