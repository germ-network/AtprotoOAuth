//
//  Slingshot.swift
//  Microcosm
//
//  Created by Mark @ Germ on 2/20/26.
//

import AtprotoTypes
import Foundation

// namespaces
public enum Slingshot {
	public static func resolve(handle: String) async throws -> ATProtoDID {
		throw SlingshotError.notImplemented
	}
}

enum SlingshotError: Error {
	case notImplemented
}

extension SlingshotError: LocalizedError {
	public var errorDescription: String? {
		switch self {
		case .notImplemented: "Not implemented."
		}
	}
}
