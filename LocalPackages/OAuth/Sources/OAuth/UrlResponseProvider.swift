//
//  UrlResponseProvider.swift
//  OAuth
//
//  Created by Mark @ Germ on 2/20/26.
//

import Foundation
/// Function that can execute a `URLRequest`.
///
/// This is used to abstract the actual networking system from the underlying authentication
/// mechanism.
public typealias URLResponseProvider = @Sendable (URLRequest) async throws -> (Data, URLResponse)
