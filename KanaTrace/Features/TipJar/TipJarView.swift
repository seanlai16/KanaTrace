import SwiftUI

struct TipJarView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var store: TipStore
    var onThanked: () -> Void

    init(store: TipStore? = nil, onThanked: @escaping () -> Void) {
        _store = State(initialValue: store ?? TipStore())
        self.onThanked = onThanked
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Practice is free, with no ads. Tips are optional.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.ink)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)

                if store.isLoading && store.products.isEmpty {
                    ProgressView()
                        .padding(.top, 24)
                } else if store.isUnavailable {
                    Text("Tips aren’t available in this build.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.inkMuted)
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                } else {
                    VStack(spacing: 10) {
                        ForEach(store.products) { product in
                            tipButton(product)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.paper.ignoresSafeArea())
            .navigationTitle("Buy me a coffee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.ink)
                }
            }
            .task { await store.load() }
        }
        .tint(.indigo)
        .presentationDetents([.medium])
    }

    private func tipButton(_ product: TipProduct) -> some View {
        let busy = store.purchasingID != nil
        let thisBusy = store.purchasingID == product.id
        return Button {
            Task {
                let result = await store.purchase(product)
                if result == .success {
                    dismiss()
                    onThanked()
                }
            }
        } label: {
            HStack {
                Text(product.title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                Spacer()
                if thisBusy {
                    ProgressView()
                } else {
                    Text(product.displayPrice)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                }
            }
            .foregroundStyle(Color.paperRaised)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.indigo)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(busy)
        .accessibilityLabel("\(product.title), \(product.displayPrice)")
    }
}
