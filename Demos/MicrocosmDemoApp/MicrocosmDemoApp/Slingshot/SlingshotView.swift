import SwiftUI

struct SlingshotView: View {
	@State private var viewModel = SlingshotVM()
	@State private var identifier: String = ""

	var body: some View {
		VStack {
			switch viewModel.state {
			case .start:
				Section("Resolve Handle") {
					HStack(alignment: .center, spacing: 10) {
						Text("@")
						TextField(
							"handle.bsky.social",
							text: $identifier
						)
						.onSubmit {
							viewModel.fetchIdentity(
								identifier: identifier)
						}
						.textInputAutocapitalization(.never)
						.autocorrectionDisabled()
					}
					Button("Resolve") {
						viewModel.fetchIdentity(
							identifier: identifier)
					}.buttonStyle(BorderedButtonStyle())
				}
			case .fetching(let identity):
				HStack {
					Text("Fetching \(identity)")
					ProgressView()
				}
			case .resolved:
				Text("Successfully resolved").bold()
				Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 5)
				{
					GridRow {
						Text("Handle:")
						Text("@\(viewModel.handle)")
					}
					GridRow {
						Text("DID:")
						Text(viewModel.did)
					}
					GridRow {
						Text("PDS:")
						Text(viewModel.pds)
					}
				}
				Button("reset", action: viewModel.reset)
			}

			Spacer()
			VStack {
				Text("Logs").bold()
				ForEach(viewModel.logs) { log in
					Text(log.body)
				}
			}
			Spacer()
		}
	}
}

#Preview {
	SlingshotView()
}
