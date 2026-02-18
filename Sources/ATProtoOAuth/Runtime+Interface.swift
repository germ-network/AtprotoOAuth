//
//  Runtime+Interface.swift
//  ATProtoOAuth
//
//  Created by Mark @ Germ on 2/17/26.
//

import Foundation

extension ATProtoOAuthRuntime: ATProtoOAuthInterface {
	public func manualLogin(
		_ identity: AuthIdentity
	) async throws -> ATProtoOAuthSession.Archive {
		throw OAuthRuntimeError.notImplemented
	}
}
