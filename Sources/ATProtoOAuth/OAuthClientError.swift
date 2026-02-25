//
//  OAuthRuntimeError.swift
//  SwiftATProtoOAuth
//
//  Created by Mark @ Germ on 2/17/26.
//

import Foundation

enum OAuthClientError: Error {
	case noDidForHandle
	case missingUrlHost
	case handleMismatch
	case missingTokenURL
	case missingAuthorizationCode
	case pkceRequired
	case codeChallengeAlreadyUsed
	case tokenInvalid
	case stateTokenMismatch(String, String)
	case issuingServerMismatch(String, String)
	case remoteTokenError(ATProto.TokenError)
	case dpopTokenExpected(String)
	case generic(String)
	case notImplemented
}

extension OAuthClientError: LocalizedError {
	var errorDescription: String? {
		switch self {
		case .noDidForHandle: "Handle didn't resolve to a did."
		case .missingUrlHost: "URL did not contain a host."
		case .handleMismatch: "Did Doc handle did not match the expected handle."
		case .missingTokenURL: "Token URL was missing."
		case .missingAuthorizationCode: "Authorization code was missing."
		case .pkceRequired: "PKCE was required but not provided."
		case .codeChallengeAlreadyUsed: "Code challenge has already been used."
		case .tokenInvalid: "Token was invalid."
		case .stateTokenMismatch(
			let expected,
			let got
		): "State token did not match, expected \(expected), got \(got)"
		case .issuingServerMismatch(let expected, let got):
			"Issuing server did not match, expected \(expected), got \(got)"
		case .remoteTokenError(let tokenError):
			"Failed to exchange authorization code for a token: \(tokenError)"
		case .dpopTokenExpected(let string): "Expected a dpop token, got: \(string)"
		case .generic(let string): "Generic: \(string)"
		case .notImplemented: "Not implemented."
		}
	}
}
