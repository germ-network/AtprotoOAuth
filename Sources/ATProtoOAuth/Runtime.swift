import ATProtoTypes

public protocol ATProtoOAuthInterface {
	//MARK: Resolution
	static func resolve(handle: String) async throws -> ATProtoDID

	//MARK: Authentication
	func manualLogin(_: ATProtoOAuthRuntime.AuthIdentity) async throws
		-> ATProtoOAuthSession.Archive
}

public class ATProtoOAuthRuntime {

}

extension ATProtoOAuthRuntime {
	public enum AuthIdentity {
		case handle(String)
		//optionally pass in handle to fill into the UI of the web auth sheet
		case did(ATProtoDID, String?)
	}
}
