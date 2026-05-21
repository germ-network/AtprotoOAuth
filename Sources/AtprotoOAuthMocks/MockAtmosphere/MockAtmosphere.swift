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
import CryptoKit
import Foundation
import GermConvenience
import Logging

///A local mock of the Atmosphere for local testing
public actor MockAtmosphere {
	static let logger = Logger(label: "MockAtmosphere")

	private let salt = SymmetricKey(size: .bits256)
	private var tokenLookup: [String: Atproto.DID] = [:]

	public var handleResolution: [Atproto.Handle: Atproto.DID] = [:]
	public var didDocs: [Atproto.DID: Atproto.DIDDocument] = [:]
	private var repos: [URL: MockPDS] = [:]

	//a big pause button
	private var holdingResponses: (AsyncStream<Void>, AsyncStream<Void>.Continuation)?

	enum Errors: LocalizedError {
		case notImplemented
		case incorrectRkey
		case noHost
		case authHeaderMismatch
		case unexpectedAuthHeader

		var errorDescription: String? {
			switch self {
			case .notImplemented: "Not implemented"
			case .incorrectRkey: "Incorrect rkey"
			case .noHost: "No host"
			case .authHeaderMismatch: "Auth header mismatch"
			case .unexpectedAuthHeader: "Unexpected auth header"
			}
		}
	}

	public init() {}

	func pds(for did: Atproto.DID) throws -> MockPDS? {
		guard let didDoc = didDocs[did] else {
			return nil
		}
		return try repos[didDoc.pdsUrl].tryUnwrap
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
		let newDid = Atproto.DID.mock()
		let newPds = try MockPDS()

		assert(handleResolution[handle] == nil)
		assert(didDocs[newDid] == nil)
		assert(repos[newPds.serviceUrl] == nil)

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

		return newDid
	}

	public func salted(did: Atproto.DID) throws -> String {
		var hmac = HMAC<SHA256>(key: salt)
		hmac.update(data: did.rawValue.utf8Data)
		return
			hmac
			.finalize().dataRepresentation
			.base64URLEncoded(padded: false)
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
		let url = try didDocs[did].tryUnwrap
			.pdsUrl

		return try await repos[url].tryUnwrap.publicAgent(did: did)
	}

	public func authAgent(did: Atproto.DID) async throws -> MockPDS.AuthAgent {
		let url = try didDocs[did].tryUnwrap
			.pdsUrl

		return try await repos[url].tryUnwrap.authAgent(did: did)
	}
}

extension MockAtmosphere: HTTPFetcher {
	public var mockClient: AtprotoOAuthClient {
		get throws {
			.init(
				clientInfo: .init(
					clientId: "https://client.example.com",
					scopes: ["atproto"],
					redirectURI: try URL(string: "com.example.static:/oauth")
						.tryUnwrap
				),
				resolver: self,
				authFetcher: self,
				userAuthenticator: { _, _ in
					try URL(string: "https://callback.example.com").tryUnwrap
				}
			)
		}
	}

	public func data(
		for bundledRequest: BundledHTTPRequest
	) async throws -> HTTPDataResponse {
		let (host, xrpcComponents) = try bundledRequest.decomposed

		let authedDid = try checkAuth(request: bundledRequest)

		if let proxyHeader =
			xrpcComponents
			.headers[try .atprotoProxy.tryUnwrap]
		{
			if try proxyHeader == Atproto.Service.bskyAppView.headerValue {
				return try await blueskyProxyResponse(
					authedDid: try authedDid.tryUnwrap,
					xrpcComponents: xrpcComponents
				)
			} else {
				throw HTTPResponseError.unsuccessfulString(400, "Invalid Request")
			}
		} else if host.absoluteString == "https://bsky.app.example.com" {
			return try await blueskyPublicServiceResponse(
				xrpcComponents: xrpcComponents
			)
		} else {
			let pds = try repos[host]
				.tryUnwrap(Errors.noHost)

			return try await pds.response(xrpcComponents, authedDid: authedDid)
		}
	}

	func checkAuth(request: BundledHTTPRequest) throws -> Atproto.DID? {
		let authHeader = request.request.headerFields[.authorization]
		let dpopHeader = request.request.headerFields[try .dpop.tryUnwrap]

		guard let authHeader, let dpopHeader else {
			guard authHeader == nil, dpopHeader == nil else {
				throw Errors.authHeaderMismatch
			}
			return nil
		}

		guard authHeader.lowercased().hasPrefix("dpop ") else {
			throw Errors.unexpectedAuthHeader
		}

		let suffix = String(authHeader.dropFirst(5))
		return try tokenLookup[suffix].tryUnwrap

	}
}

extension BundledHTTPRequest {
	var decomposed: (host: URL, xrpcComponents: XRPCRequestComponents) {
		get throws {
			let url = try request.url.tryUnwrap
			let components = try URLComponents(
				url: url,
				resolvingAgainstBaseURL: false
			).tryUnwrap

			var hostComponents = URLComponents()
			hostComponents.scheme = url.scheme
			hostComponents.host = url.host()

			return (
				try hostComponents.url.tryUnwrap,
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
