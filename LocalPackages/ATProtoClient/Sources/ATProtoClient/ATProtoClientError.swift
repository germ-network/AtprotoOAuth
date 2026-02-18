//
//  ATProtoClientError.swift
//  ATProtoClient
//
//  Created by Mark @ Germ on 2/17/26.
//

import Foundation

enum ATProtoClientError: Error {
	case unexpectedRecordType
	case missingRecordValue
	case failedToDecodeRecord
}

extension ATProtoClientError: LocalizedError {
	var localizedDescription: String {
		switch self {
		case .unexpectedRecordType: "Unexpected record type"
		case .missingRecordValue: "Missing record value"
		case .failedToDecodeRecord: "Failed to decode record"
		}
	}
}
