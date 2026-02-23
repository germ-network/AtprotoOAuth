//
//  SessionError.swift
//  ATProtoOAuth
//
//  Created by Mark @ Germ on 2/23/26.
//

import Foundation

enum OAuthSessionError: Error {
	case cantFormURL
	case incorrectResponseType
}

extension OAuthSessionError: LocalizedError {
	var localizedDescription: String? {
		switch self {
		case .cantFormURL: "can't form URL"
		case .incorrectResponseType: "incorrect response type"
		}
	}
}
