//
//  ATProtoOAuthRuntime+Shim.swift
//  SwiftATProtoOAuth
//
//  Created by Mark @ Germ on 2/17/26.
//

import ATResolve
import AtprotoTypes
import Foundation

/// a temp file meant to be deprecated

extension ATProtoOAuthClient {
	public static func resolve(handle: String) async throws -> Atproto.DID {
		guard
			let did = try? await ATResolver(provider: URLSession.shared).didForHandle(
				handle.lowercased())
		else {
			throw OAuthClientError.noDidForHandle
		}
		return try .init(fullId: did)
	}
}
