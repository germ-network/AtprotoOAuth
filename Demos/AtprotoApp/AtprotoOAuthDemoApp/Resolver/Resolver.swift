//
//  Resolver.swift
//  AtprotoOAuthDemoApp
//
//  Created by Mark @ Germ on 4/23/26.
//

import Combine
import SwiftUI

struct Resolver: View {
	@State private var viewModel = ResolverVM()
	private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
	
	var body: some View {
		VStack(alignment: .center, spacing: 20) {
			Picker("Resolver", selection: $viewModel.choices) {
				Text("Slingshot").tag(ResolverVM.Choices.slingshot)
				Text("ATResolve").tag(ResolverVM.Choices.atresolve)
				Text("Fallback").tag(ResolverVM.Choices.fallback)
			}
			
			switch viewModel.state {
			case .collectHandle:
				EmptyView()
			default:
				Button("reset", action: viewModel.reset)
					.apply { view in
						if #available(iOS 17.0, macOS 26.0, *) {
							view.buttonStyle(.glassProminent)
						} else {
							view
						}
					}
			}
			
			switch viewModel.state {
			case .collectHandle:
				Spacer()
				CollectHandleView(viewModel: viewModel)
			case .resolving(let handle, _, _):
				if let timeElapsed = viewModel.timeElapsed {
					Text(
						"Resolving \(handle), \(Int(timeElapsed)) seconds elapsed"
					)
				}
			case .complete(let time):
				Text("Resolution took \(time) seconds")
			}
			
			Spacer()
			
			Section(viewModel.logs.count > 0 ? "Logs" : "") {
				VStack(alignment: .leading, spacing: 10) {
					ForEach(viewModel.logs) { log in
						Text(log.body)
					}
				}
			}
			Spacer()
		}
		.onReceive(timer) { _ in
			viewModel.timer()
		}
	}
}

#Preview {
    Resolver()
}
