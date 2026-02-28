//
//  AtprotoOAuthSession.swift
//  AtprotoOAuth
//
//  Created by Mark @ Germ on 2/17/26.
//

import AtprotoTypes

///Usage pattern: A session starts out authenticated. May degrade to lose auth
///Parent should recognize it has an expired session and re-auth

///Use this to constrain the API when the implementation must have public conformance to OAuthSession
public protocol AtprotoOAuthSession {
	func authProcedure<X: XRPCProcedure>(
		_ xrpc: X.Type,
		parameters: X.Parameters
	) async throws -> X.Result

	func authRequest<X: XRPCRequest>(
		_ xrpc: X.Type,
		parameters: X.Parameters
	) async throws -> X.Result
}

extension AtprotoOAuthSessionImpl: AtprotoOAuthSession {}
