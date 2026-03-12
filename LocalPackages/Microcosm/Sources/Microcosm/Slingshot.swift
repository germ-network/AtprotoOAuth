//
//  Slingshot.swift
//  Microcosm
//
//  Created by Mark @ Germ on 2/20/26.
//

import AtprotoTypes
import Foundation
import GermConvenience

// namespaces
public protocol SlingshotInterface: Sendable {
	func request<X: XRPCRequest>(
		_: X.Type,
		parameters: X.Parameters,
		service: URL?,
	) async throws -> X.Result

	func resolveHandle(handle: String) async throws -> Atproto.DID
	func resolveMiniDoc(identifier: String, serviceUrl: URL?) async throws
		-> Lexicon.Blue.Microcosm.Identity.ResolveMiniDoc.Result?
}

public struct Slingshot {
	public static let defaultServiceURL = URL(string: "https://slingshot.microcosm.blue/")!

	let responseProvider: HTTPDataResponse.Requester

	public init(responseProvider: @escaping HTTPDataResponse.Requester) {
		self.responseProvider = responseProvider
	}
}

extension Slingshot: SlingshotInterface {}

extension SlingshotInterface {
	// This feels like it should be in AtIdentifier as a static method?
	private func fromIdentifier(_ identifier: String) throws -> AtIdentifier {
		if identifier.starts(with: "did") {
			return try AtIdentifier.did(.init(fullId: identifier))
		} else {
			return AtIdentifier.handle(identifier)
		}
	}

	public func resolveHandle(handle: String) async throws -> AtprotoTypes.Atproto.DID {
		throw SlingshotError.notImplemented
	}

	public func resolveMiniDoc(identifier: String, serviceUrl: URL?)
		async throws
		-> Lexicon.Blue.Microcosm.Identity.ResolveMiniDoc.Result?
	{
		let id = try fromIdentifier(identifier)

		do {
			return try await request(
				Lexicon.Blue.Microcosm.Identity.ResolveMiniDoc.self,
				parameters: .init(identifier: id),
				service: serviceUrl,
			)
			//this is per the api docs, not the lexicon
		} catch SlingshotError.requestFailed(400, let error) {
			if error == "RecordNotFound" {
				return nil
			} else {
				throw SlingshotError.requestFailed(responseCode: 400, error: error)
			}
		}
	}
}
