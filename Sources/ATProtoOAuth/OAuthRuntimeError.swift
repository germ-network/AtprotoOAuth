//
//  OAuthRuntimeError.swift
//  SwiftATProtoOAuth
//
//  Created by Mark @ Germ on 2/17/26.
//

import Foundation

enum OAuthRuntimeError: Error {
	case noDidForHandle
}

extension OAuthRuntimeError: LocalizedError {
	var errorDescription: String? {
		switch self {
		case .noDidForHandle: "Handle didn't resolve to a did."
		}
	}
}
