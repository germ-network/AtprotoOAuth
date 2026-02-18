//
//  ATProtoOAuthRuntime+Shim.swift
//  SwiftATProtoOAuth
//
//  Created by Mark @ Germ on 2/17/26.
//

import ATProtoTypes
import ATResolve
import Foundation

/// a temp file meant to be deprecated

extension ATProtoOAuthRuntime {
	public static func resolve(handle: String) async throws -> ATProtoDID {
		guard
			let did = try? await ATResolver(provider: URLSession.shared).didForHandle(
				handle.lowercased())
		else {
			throw OAuthRuntimeError.noDidForHandle
		}
		return try .init(fullId: did)
	}
}
