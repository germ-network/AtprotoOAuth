//
//  ATProtoTypeError.swift
//  ATProtoTypes
//
//  Created by Mark @ Germ on 2/18/26.
//

import Foundation

enum ATProtoTypeError: Error {
	case invalidPrefix
	case invalidBase32Data
}

extension ATProtoTypeError: LocalizedError {
	var errorDescription: String? {
		switch self {
		case .invalidPrefix: "Invalid prefix"
		case .invalidBase32Data: "Invalid Base32 data"
		}
	}
}
