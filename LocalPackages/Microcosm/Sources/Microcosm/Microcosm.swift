//
//  Slingshot.swift
//  Microcosm
//
//  Created by Emelia @ Germ on 2/20/26.
//
import Foundation

public enum Microcosm {
	enum Errors: Error {
		case notImplemented
		case unexpectedRecordType
		case missingRecordValue
		case failedToDecodeRecord
		case improperServiceUrl
		case couldntConstructUrl
		case nonHTTPResponse
		case requestFailed(responseCode: Int, error: String)
	}
}

extension Microcosm.Errors: LocalizedError {
	var localizedDescription: String {
		switch self {
		case .notImplemented: "Method not implemented"
		case .unexpectedRecordType: "Unexpected record type"
		case .missingRecordValue: "Missing record value"
		case .failedToDecodeRecord: "Failed to decode record"
		case .improperServiceUrl: "Improper service URL"
		case .couldntConstructUrl: "Couldn't construct URL"
		case .nonHTTPResponse: "Request failed with non-HTTP response"
		case .requestFailed(let responseCode, let errorString):
			"Request failed with response code: \(responseCode), error \(errorString)"
		}
	}
}
