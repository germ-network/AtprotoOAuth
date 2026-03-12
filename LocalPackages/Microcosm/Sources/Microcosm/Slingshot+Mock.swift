import AtprotoTypes
import Foundation

public struct MockSlingshot: SlingshotInterface {
	public init() {}

	public func request<X>(
		_: X.Type,
		parameters: X.Parameters,
		service: URL?
	) async throws -> X.Result where X: XRPCRequest {
		.mock()
	}
}
