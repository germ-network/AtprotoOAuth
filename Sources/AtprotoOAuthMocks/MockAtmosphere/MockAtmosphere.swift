//
//  MockAtmosphere.swift
//  AtprotoGerm
//
//  Created by Mark @ Germ on 4/6/26.
//

import AtprotoClient
import AtprotoClientMocks
import AtprotoOAuth
import AtprotoTypes
import Base64
import Crypto
import Foundation
import GermConvenience
import GermConvenienceHTTP
import Logging

///A local mock of the Atmosphere for local testing
public actor MockAtmosphere {
	static let logger = Logger(label: "MockAtmosphere")

	private let salt = SymmetricKey(size: .bits256)
	private var tokenLookup: [String: Atproto.DID] = [:]

	public var handleResolution: [Atproto.Handle: Atproto.DID] = [:]
	public var didDocs: [Atproto.DID: Atproto.DIDDocument] = [:]
	private var repos: [URL: MockPDS] = [:]
	//authorization servers on their own host, in front of PDSes in `repos`
	private var entryways: [MockAS] = []

	//server-side state for cursor-paginated queries, keyed by an opaque cursor uuid.
	//the originating query is retained so a cursor can't be replayed against a
	//different endpoint than the one that minted it.
	var pendingProfilePages: [UUID: (query: Atproto.NSID, remaining: [Atproto.DID])] = [:]

	//a big pause button
	private var holdingResponses: (AsyncStream<Void>, AsyncStream<Void>.Continuation)?

	enum Errors: LocalizedError {
		case notImplemented
		case incorrectRkey
		case noHost
		case authHeaderMismatch
		case unexpectedAuthHeader
		case invalidCursor

		var errorDescription: String? {
			switch self {
			case .notImplemented: "Not implemented"
			case .incorrectRkey: "Incorrect rkey"
			case .noHost: "No host"
			case .authHeaderMismatch: "Auth header mismatch"
			case .unexpectedAuthHeader: "Unexpected auth header"
			case .invalidCursor: "Invalid cursor"
			}
		}
	}

	public init() {}

	func pds(for did: Atproto.DID) throws -> MockPDS? {
		guard let didDoc = didDocs[did] else {
			return nil
		}
		return try repos[didDoc.pdsUrl].unwrapped
	}

	///The authorization server behind `did`'s PDS, for scripting its `/oauth/`
	///endpoints and reading back what the client sent.
	public func authorizationServer(for did: Atproto.DID) throws -> MockAS? {
		try pds(for: did)?.authorizationServer
	}
}

extension MockAtmosphere: Atproto.Resolver {
	public func resolve(
		handle: Atproto.Handle
	) -> Atproto.DID? {
		handleResolution[handle]
	}

	public func resolve(did: Atproto.DID) -> Atproto.DIDDocument? {
		didDocs[did]
	}
}

extension MockAtmosphere {
	public func createDid(
		handle: Atproto.Handle,
		bskyProfile: Lexicon.App.Bsky.Actor.Profile? = .mock()
	) async throws -> Atproto.DID {
		try await createDid(handle: handle, bskyProfile: bskyProfile).0
	}

	///`pds` defaults to a new PDS that is its own authorization server
	func createDid(
		handle: Atproto.Handle,
		bskyProfile: Lexicon.App.Bsky.Actor.Profile?,
		pds: MockPDS? = nil
	) async throws -> (Atproto.DID, MockPDS) {
		let newDid = Atproto.DID.mock()
		let newPds = try pds ?? MockPDS()

		assert(handleResolution[handle] == nil)
		assert(didDocs[newDid] == nil)
		assert(repos[newPds.serviceUrl] == nil)
		//data(for:) can only route to a PDS's own authorization server or a
		//registered entryway; any other would fail discovery with noHost
		let authorizationServer = newPds.authorizationServer
		assert(
			authorizationServer.serviceUrl == newPds.serviceUrl
				|| entryways.contains { $0.issuerUrl == authorizationServer.issuerUrl },
			"the PDS's authorization server must be itself or a registered entryway"
		)

		let _ = try await newPds.host(did: newDid, bskyProfile: bskyProfile)

		handleResolution[handle] = newDid
		didDocs[newDid] = .init(
			context: [],
			id: newDid.rawValue,
			alsoKnownAs: ["at://" + handle.rawValue],
			verificationMethod: [],
			service: [
				.init(
					id: "#atproto_pds",
					type: "AtprotoPersonalDataServer",
					serviceEndpoint: newPds.serviceUrl
				)
			]
		)

		repos[newPds.serviceUrl] = newPds

		let saltedToken = try salted(did: newDid)
		tokenLookup[saltedToken] = newDid

		return (newDid, newPds)
	}

	///An authorization server on its own host, as bsky.social is, that DIDs
	///created through it sit behind:
	///
	///    let entryway = try await MockAtmosphere().createEntryway()
	///    let did = try await entryway.createDid(handle: handle)
	///
	///`serviceUrl` defaults to a random host.
	public func createEntryway(serviceUrl: URL? = nil) throws -> Entryway {
		guard let serviceUrl else {
			//a minted URL is a fresh host, so it can't collide
			return register(entryway: try MockAS())
		}

		//issuers are origins, so compare origins: a trailing slash is the same host
		let origin = try serviceUrl.origin
		assert(!entryways.contains { $0.issuerUrl.absoluteString == origin })
		return register(entryway: try MockAS(serviceUrl: serviceUrl))
	}

	private func register(entryway authorizationServer: MockAS) -> Entryway {
		entryways.append(authorizationServer)
		return .init(atmosphere: self, authorizationServer: authorizationServer)
	}

	public struct Entryway: Sendable {
		public let atmosphere: MockAtmosphere
		public let authorizationServer: MockAS

		///Each DID gets its own PDS, all sharing this authorization server.
		public func createDid(
			handle: Atproto.Handle,
			bskyProfile: Lexicon.App.Bsky.Actor.Profile? = .mock()
		) async throws -> Atproto.DID {
			try await atmosphere.createDid(
				handle: handle,
				bskyProfile: bskyProfile,
				pds: .withEntryway(authorizationServer)
			).0
		}
	}

	public func salted(did: Atproto.DID) throws -> String {
		var hmac = HMAC<SHA256>(key: salt)
		hmac.update(data: did.rawValue.utf8Data)
		return Base64.encodedString(
			hmac.finalize().dataRepresentation,
			variant: .url,
			pad: .unpadded
		)
	}
}

extension MockAtmosphere {
	public func holdResponses() {
		assert(holdingResponses == nil)
		holdingResponses = AsyncStream<Void>.makeStream()
	}

	public func releaseHold() {
		assert(holdingResponses != nil)
		if let holdingResponses {
			self.holdingResponses = nil
			holdingResponses.1.yield()
			holdingResponses.1.finish()
		}
	}

	public func awaitHold() async {
		if let holdingResponses {
			for await _ in holdingResponses.0 {
				print("waiting")
			}
			print("finished")
		}
	}
}

extension MockAtmosphere {
	public func publicAgent(did: Atproto.DID) async throws -> MockPDS.PublicAgent {
		let url = try didDocs[did].unwrapped
			.pdsUrl

		return try await repos[url].unwrapped.publicAgent(did: did)
	}
}

extension MockAtmosphere: HTTPFetcher {
	public var mockClient: AtprotoOAuthClient {
		get throws {
			try mockClient(userAuthenticator: { _, _ in
				try URL(string: "https://callback.example.com").unwrapped
			})
		}
	}

	public func mockClient(
		userAuthenticator: @escaping @Sendable (URL, String) async throws -> URL
	) throws -> AtprotoOAuthClient {
		.init(
			clientInfo: .init(
				clientId: "https://client.example.com",
				scopes: ["atproto"],
				redirectURI: try URL(string: "com.example.static:/oauth")
					.unwrapped
			),
			resolver: self,
			authFetcher: self,
			userAuthenticator: userAuthenticator
		)
	}

	public func data(
		for bundledRequest: BundledHTTPRequest
	) async throws -> HTTPDataResponse {
		let (host, xrpcComponents) = try bundledRequest.decomposed

		let authedDid = try checkAuth(request: bundledRequest)

		if let proxyHeader =
			xrpcComponents
			.headers[try .atprotoProxy.unwrapped]
		{
			if try proxyHeader == Atproto.Service.bskyAppView.headerValue {
				return try await blueskyProxyResponse(
					authedDid: try authedDid.unwrapped,
					xrpcComponents: xrpcComponents
				)
			} else {
				throw HTTPResponseError.unsuccessfulString(400, "Invalid Request")
			}
		} else if host.absoluteString == "https://bsky.app.example.com" {
			return try await blueskyPublicServiceResponse(
				xrpcComponents: xrpcComponents
			)
		} else if let entryway = try entryways.first(where: {
			try $0.handles(bundledRequest)
		}) {
			return try await entryway.response(for: bundledRequest)
		} else {
			let pds = try repos[host]
				.unwrap(or: Errors.noHost)

			return try await pds.response(for: bundledRequest, authedDid: authedDid)
		}
	}

	func checkAuth(request: BundledHTTPRequest) throws -> Atproto.DID? {
		let authHeader = request.request.headerFields[.authorization]
		let dpopHeader = request.request.headerFields[try .dpop.unwrapped]

		//a DPoP proof alone is unauthenticated: PAR and token requests send one
		//before there is an access token to bind it to
		guard let authHeader else {
			return nil
		}
		guard dpopHeader != nil else {
			throw Errors.authHeaderMismatch
		}

		guard authHeader.lowercased().hasPrefix("dpop ") else {
			throw Errors.unexpectedAuthHeader
		}

		let suffix = String(authHeader.dropFirst(5))
		return try tokenLookup[suffix].unwrapped

	}
}

extension BundledHTTPRequest {
	var decomposed: (host: URL, xrpcComponents: XRPCRequestComponents) {
		get throws {
			let url = try request.url.unwrapped
			let components = try URLComponents(
				url: url,
				resolvingAgainstBaseURL: false
			).unwrapped

			var hostComponents = URLComponents()
			hostComponents.scheme = url.scheme
			hostComponents.host = url.host()

			return (
				try hostComponents.url.unwrapped,
				.init(
					relativePath: components.path,
					queryItems: components.queryItems ?? [],
					headers: request.headerFields,
					method: request.method,
					body: body
				)
			)
		}
	}
}
