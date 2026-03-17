//
//  AtprotoTypeError.swift
//  AtprotoTypes
//
//  Created by Mark @ Germ on 2/18/26.
//

import Foundation

public enum AtprotoTypeError: Error {
	case invalidRecordType
	case invalidPrefix
	case invalidBase32Data
}

extension AtprotoTypeError: LocalizedError {
	public var errorDescription: String? {
		switch self {
		case .invalidRecordType: "Invalid Record type"
		case .invalidPrefix: "Invalid prefix"
		case .invalidBase32Data: "Invalid Base32 data"
		}
	}
}
