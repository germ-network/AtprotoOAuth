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
	case improperServiceUrl
	case couldntConstructUrl
	case requestFailed(responseCode: Int?)
}

extension ATProtoClientError: LocalizedError {
	var localizedDescription: String {
		switch self {
		case .unexpectedRecordType: "Unexpected record type"
		case .missingRecordValue: "Missing record value"
		case .failedToDecodeRecord: "Failed to decode record"
		case .improperServiceUrl: "Improper service URL"
		case .couldntConstructUrl: "Couldn't construct URL"
		case .requestFailed(let responseCode):
			if let responseCode {
				"Request failed with response code: \(responseCode)"
			} else {
				"Request failed with non-HTTP response"
			}
		}
	}
}
