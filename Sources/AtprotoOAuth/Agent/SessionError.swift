//
//  SessionError.swift
//  AtprotoOAuth
//
//  Created by Mark @ Germ on 2/23/26.
//

import Foundation

package enum OAuthSessionError: Error, Equatable {
	case cantFormURL
	case sessionInactive
	case incorrectResponseType
	case expectedDpopToken(String)
	case receivedScopeNotRequested
	case unsupportedDpopSigningAlgorithm
	case unsupported
}

extension OAuthSessionError: LocalizedError {
	package var errorDescription: String? {
		switch self {
		case .cantFormURL: "can't form URL"
		case .sessionInactive: "session is inactive"
		case .incorrectResponseType: "incorrect response type"
		case .receivedScopeNotRequested: "received scope not requested"
		case .unsupportedDpopSigningAlgorithm: "Unsupported dpop signing algorithm"
		case .unsupported: "unsupported"
		case .expectedDpopToken(let tokenType):
			"expected dpop token, got \(tokenType) token"
		}
	}
}
