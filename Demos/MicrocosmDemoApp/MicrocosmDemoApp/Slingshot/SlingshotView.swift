import SwiftUI

struct SlingshotView: View {
	@State private var viewModel = SlingshotVM()

	var body: some View {
		VStack {
			switch viewModel.state {
			case .collectHandle:
				Text("TODO: Collect Handle")
			case .validating(let handle):
				Text("Validating \(handle)")
				Button("reset", action: viewModel.reset)
			case .resolved(_):
				Text("Successfully Logged In")
				Button("reset", action: viewModel.reset)
			}

			VStack {
				Text("Logs").bold()
				ForEach(viewModel.logs) { log in
					Text(log.body)
				}
			}
		}
	}
}

#Preview {
	SlingshotView()
}
