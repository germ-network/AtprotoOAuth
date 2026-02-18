import SwiftATProtoTypes


public class ATProtoOAuthRuntime {

}

extension ATProtoOAuthRuntime {
	public enum AuthIdentity {
		case handle(String)
		case did(ATProtoDID)
	}
}
