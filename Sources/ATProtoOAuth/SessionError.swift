//
//  SessionError.swift
//  ATProtoOAuth
//
//  Created by Mark @ Germ on 2/23/26.
//

import Foundation

enum OAuthSessionError: Error {
	case cantFormURL
	case sessionInactive
	case incorrectResponseType
	case expectedDpopToken(String)
	case unsupported
}

extension OAuthSessionError: LocalizedError {
	var localizedDescription: String? {
		switch self {
		case .cantFormURL: "can't form URL"
		case .sessionInactive: "session is inactive"
		case .incorrectResponseType: "incorrect response type"
		case .unsupported: "unsupported"
		case .expectedDpopToken(let tokenType): "expected dpop token, got \(tokenType) token"
		}
	}
}
