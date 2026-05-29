//
//  OAuthRuntimeError.swift
//  SwiftAtprotoOAuth
//
//  Created by Mark @ Germ on 2/17/26.
//

import AtprotoTypes
import Foundation

package enum OAuthClientError: Error, Equatable {
	case missingUrlHost
	case codeChallengeAlreadyUsed
	case tokenInvalid
	case stateTokenMismatch(String, String)
	case issuingServerMismatch(String, String)
	case generic(String)
	case notImplemented
}

extension OAuthClientError: LocalizedError {
	package var errorDescription: String? {
		switch self {
		case .missingUrlHost: "URL did not contain a host."
		case .codeChallengeAlreadyUsed: "Code challenge has already been used."
		case .tokenInvalid: "Token was invalid."
		case .stateTokenMismatch(
			let expected,
			let got
		): "State token did not match, expected \(expected), got \(got)"
		case .issuingServerMismatch(let expected, let got):
			"Issuing server did not match, expected \(expected), got \(got)"
		case .generic(let string): "Generic: \(string)"
		case .notImplemented: "Not implemented."
		}
	}
}
