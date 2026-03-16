import AtprotoTypes
import Foundation
import GermConvenience

public actor AtprotoAgentImpl {
}

extension AtprotoAgentImpl: AtprotoAgent {
	public func authResponse(for request: URLRequest) async throws
		-> GermConvenience.HTTPDataResponse
	{
		throw HTTPResponseError.unsuccessfulString(400, "InvalidRequest")
	}
}
