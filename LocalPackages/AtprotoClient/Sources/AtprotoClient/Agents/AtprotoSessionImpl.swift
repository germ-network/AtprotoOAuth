import AtprotoTypes
import Foundation
import GermConvenience

public actor AtprotoSessionImpl {
}

extension AtprotoSessionImpl: AtprotoSession {
	public func authResponse(for request: URLRequest) async throws
		-> GermConvenience.HTTPDataResponse
	{
		throw HTTPResponseError.unsuccessfulString(400, "InvalidRequest")
	}
}
