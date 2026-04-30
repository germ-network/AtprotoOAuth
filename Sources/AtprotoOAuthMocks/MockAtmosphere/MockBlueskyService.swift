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
			return try await handleGetProfile(
				queryParameters: queryParameters,
				authedDid: authedDid
			)
		default:
			throw Errors.notImplemented
		}
	}

	private func handleGetProfile(
		queryParameters: [String: String],
		authedDid: Atproto.DID,
	) async throws -> HTTPDataResponse {
		let actor = try queryParameters["actor"].tryUnwrap
		let actorDid = try Atproto.DID(string: actor)

		let (viewerFollows, viewerBlocks) = try await pds(for: authedDid)
			.getGraph(did: authedDid)

		let (subjectFollows, subjectBlocks) = try await pds(for: actorDid)
			.getGraph(did: actorDid)

		let actorProfile = try await pds(for: actorDid)
			.getBskyProfile(did: actorDid)
		let handle = try (resolve(did: actorDid)?.handle).tryUnwrap

		/// Indicates whether the authed user has been blocked by the account requested. Optional.
		let blockedBy = subjectBlocks.contains {
			$0.subject == authedDid
		}

		let blocking = viewerBlocks.contains {
			$0.subject == actorDid
		}

		let followedBy = subjectFollows.contains {
			$0.subject == authedDid
		}

		let following = viewerFollows.contains {
			$0.subject == actorDid
		}

		let output = Lexicon.App.Bsky.Actor.GetProfile.Output(
			did: try .init(string: actor),
			handle: handle,
			displayName: actorProfile?.displayName,
			pronouns: actorProfile?.pronouns,
			avatar: nil,
			viewer: .init(
				muted: nil,
				blockedBy: blockedBy ? true : nil,
				blocking: blocking ? "example.com" : nil,
				following: following ? "example.com" : nil,
				followedBy: followedBy ? "example.com" : nil
			)
		)

		return .init(
			data: try JSONEncoder().encode(output),
			response: .init(status: .ok)
		)
	}

	private func handlePublicXrpc(
		xrpcNsid: Atproto.NSID,
		queryParameters: [String: String],
		body: Data?,
	) async throws -> HTTPDataResponse {
		throw Errors.notImplemented
	}
}
