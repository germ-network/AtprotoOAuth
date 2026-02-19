//
//  AtIdentifier.swift
//  ATProtoTypes
//
//  Created by Mark @ Germ on 2/18/26.
//

import Foundation

///parameters take a did or handle
public enum AtIdentifier {
	public typealias Handle = String

	case handle(Handle)
	case did(ATProtoDID)

	//over the wire, passed as a string
	public var wireFormat: String {
		switch self {
		case .handle(let handle): handle
		case .did(let did): did.fullId
		}
	}
}

///https://atproto.com/specs/nsid
public typealias NSID = String

///https://atproto.com/specs/record-key
public typealias RecordKey = String
