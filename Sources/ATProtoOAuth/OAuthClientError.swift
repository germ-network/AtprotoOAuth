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
	case notImplemented
}

extension OAuthClientError: LocalizedError {
	var errorDescription: String? {
		switch self {
		case .noDidForHandle: "Handle didn't resolve to a did."
		case .missingUrlHost: "URL did not contain a host."
		case .handleMismatch: "Did Doc handle did not match the expected handle."
		case .notImplemented: "Not implemented."
		}
	}
}
