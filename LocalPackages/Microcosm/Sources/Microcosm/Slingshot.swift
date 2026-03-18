//
//  Slingshot.swift
//  Microcosm
//
//  Created by Mark @ Germ on 2/20/26.
//

import AtprotoClient
import AtprotoTypes
import Foundation
import GermConvenience

extension Microcosm {
	public protocol SlingshotInterface: Sendable {
		func request<X: XRPCRequest>(
			_: X.Type,
			parameters: X.Parameters,
			service: URL?,
		) async throws -> X.Result

		func resolveHandle(handle: String) async throws -> Atproto.DID
		func resolveMiniDoc(identifier: String) async throws
			-> Lexicon.Blue.Microcosm.Identity.ResolveMiniDoc.Result?
		func resolveMiniDoc(identifier: String, serviceUrl: URL?) async throws
			-> Lexicon.Blue.Microcosm.Identity.ResolveMiniDoc.Result?
	}
}

extension Microcosm {
	public struct Slingshot {
		public static let defaultServiceURL = URL(
			string: "https://slingshot.microcosm.blue")

		let resourceFetcher: HTTPFetcher

		public init(resourceFetcher: HTTPFetcher) {
			self.resourceFetcher = resourceFetcher
		}
	}
}

extension Microcosm.Slingshot: Microcosm.SlingshotInterface {}

extension Microcosm.SlingshotInterface {
	// This feels like it should be in AtIdentifier as a static method?
	private func fromIdentifier(_ identifier: String) throws -> AtIdentifier {
		if identifier.starts(with: "did") {
			return try AtIdentifier.did(.init(string: identifier))
		} else {
			return AtIdentifier.handle(identifier)
		}
	}

	public func resolveHandle(handle: String) async throws -> AtprotoTypes.Atproto.DID {
		throw Microcosm.Errors.notImplemented
	}

	public func resolveMiniDoc(identifier: String) async throws -> Lexicon.Blue.Microcosm
		.Identity.ResolveMiniDoc.Result?
	{
		return try await resolveMiniDoc(identifier: identifier, serviceUrl: nil)
	}

	public func resolveMiniDoc(identifier: String, serviceUrl: URL?)
		async throws
		-> Lexicon.Blue.Microcosm.Identity.ResolveMiniDoc.Result?
	{
		let id = try fromIdentifier(identifier)

		do {
			return try await request(
				Lexicon.Blue.Microcosm.Identity.ResolveMiniDoc.self,
				parameters: Lexicon.Blue.Microcosm.Identity.ResolveMiniDoc
					.Parameters(identifier: id),
				service: serviceUrl,
			)
		} catch Microcosm.Errors.requestFailed(400, let error) {
			if error == "RecordNotFound" {
				return nil
			} else {
				throw Microcosm.Errors.requestFailed(
					responseCode: 400, error: error)
			}
		}
	}
}
