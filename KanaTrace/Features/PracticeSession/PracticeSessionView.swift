import SwiftUI

struct PracticeSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: PracticeSessionViewModel
    @State private var shake: CGFloat = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(viewModel.current.romaji)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.ink)
                    .padding(.top, 8)

                WritingCanvas(viewModel: viewModel)
                    .padding(.horizontal, 20)
                    .offset(x: shake)
                    .opacity(viewModel.isRevealed ? 0.35 : 1)

                if viewModel.isRevealed {
                    revealCard
                } else {
                    hintButton
                }

                Spacer(minLength: 0)

                if viewModel.isRevealed {
                    continueButton
                }
            }
            .background(Color.paper.ignoresSafeArea())
            .navigationTitle(viewModel.progressLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        viewModel.close()
                    }
                    .foregroundStyle(Color.ink)
                }
            }
            .onChange(of: viewModel.lastStrokeRejected) { _, rejected in
                guard rejected else { return }
                withAnimation(.default) { shake = 10 }
                withAnimation(.default.delay(0.08)) { shake = -8 }
                withAnimation(.default.delay(0.16)) { shake = 0 }
            }
            .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
                if shouldDismiss { dismiss() }
            }
        }
        .tint(.indigo)
    }

    private var hintButton: some View {
        Button {
            viewModel.useHint()
        } label: {
            Text(viewModel.hintEnabled ? "Hint on" : "Hint")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(viewModel.hintEnabled ? Color.vermillion : Color.indigo)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(viewModel.hintEnabled ? Color.vermillion : Color.indigo, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .disabled(viewModel.hintEnabled)
        .opacity(viewModel.hintEnabled ? 0.7 : 1)
    }

    private var revealCard: some View {
        VStack(spacing: 6) {
            Text(viewModel.current.glyph)
                .font(.system(size: 72, weight: .medium))
                .foregroundStyle(Color.ink)
            Text(viewModel.current.romaji)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundStyle(Color.inkMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var continueButton: some View {
        Button {
            viewModel.continueOrFinish()
        } label: {
            Text(viewModel.isLastCharacter ? "Done" : "Continue")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Color.paperRaised)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.indigo)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }
}
