import SwiftUI

struct PaywallView: View {

    @State private var viewModel = PaywallViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.tantrikaBackground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: TantrikaSpacing.sm) {
                        Text("Begin your practice.")
                            .font(.tantrikaDisplay)
                            .foregroundStyle(Color.tantrikaText)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Unlimited access to every lesson, every course.")
                            .font(.tantrikaBody)
                            .foregroundStyle(Color.tantrikaTextMuted)
                            .lineSpacing(15 * 0.6)
                    }
                    .padding(.horizontal, TantrikaSpacing.lg)
                    .padding(.top, TantrikaSpacing.xxl)
                    .padding(.bottom, TantrikaSpacing.xl)

                    // Offerings
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView().tint(Color.tantrikaAccent)
                            Spacer()
                        }
                        .padding(.vertical, TantrikaSpacing.xl)
                    } else {
                        VStack(spacing: TantrikaSpacing.sm) {
                            ForEach(viewModel.offerings) { offering in
                                OfferingRow(
                                    offering: offering,
                                    isSelected: viewModel.selectedOffering?.id == offering.id
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.selectedOffering = offering
                                }
                            }
                        }
                        .padding(.horizontal, TantrikaSpacing.lg)
                    }

                    Spacer().frame(height: TantrikaSpacing.xl)

                    // Error
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.tantrikaCaption)
                            .foregroundStyle(Color.tantrikaAccent)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, TantrikaSpacing.lg)
                            .padding(.bottom, TantrikaSpacing.sm)
                    }

                    // Purchase CTA
                    VStack(spacing: TantrikaSpacing.sm) {
                        Button {
                            Task { await viewModel.purchase() }
                        } label: {
                            ZStack {
                                if viewModel.isPurchasing {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Start Membership")
                                        .font(.tantrikaButton)
                                        .foregroundStyle(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.tantrikaAccent)
                            .cornerRadius(TantrikaRadius.md)
                        }
                        .disabled(viewModel.isPurchasing || viewModel.selectedOffering == nil)

                        Button {
                            Task { await viewModel.restorePurchases() }
                        } label: {
                            Text("Restore purchases")
                                .font(.tantrikaBody)
                                .foregroundStyle(Color.tantrikaTextMuted)
                                .underline()
                        }
                        .disabled(viewModel.isPurchasing)
                    }
                    .padding(.horizontal, TantrikaSpacing.lg)
                    .padding(.bottom, TantrikaSpacing.xxl)
                }
            }
        }
        .task { await viewModel.load() }
        .onChange(of: viewModel.purchaseSucceeded) { _, succeeded in
            if succeeded { dismiss() }
        }
    }
}

// MARK: — Offering row

private struct OfferingRow: View {
    let offering: SubscriptionOffering
    let isSelected: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: TantrikaSpacing.xxs) {
                Text(offering.title)
                    .font(.tantrikaSubhead)
                    .foregroundStyle(Color.tantrikaText)
                Text(offering.price)
                    .font(.tantrikaBody)
                    .foregroundStyle(Color.tantrikaTextMuted)
            }

            Spacer()

            Circle()
                .stroke(isSelected ? Color.tantrikaAccent : Color.tantrikaTextMuted, lineWidth: 1.5)
                .frame(width: 22, height: 22)
                .overlay(
                    Circle()
                        .fill(Color.tantrikaAccent)
                        .frame(width: 13, height: 13)
                        .opacity(isSelected ? 1 : 0)
                )
        }
        .padding(TantrikaSpacing.md)
        .background(Color.tantrikaSurface)
        .cornerRadius(TantrikaRadius.lg)
        .shadow(color: Color.tantrikaText.opacity(0.08), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: TantrikaRadius.lg)
                .stroke(isSelected ? Color.tantrikaAccent : Color.clear, lineWidth: 1.5)
        )
    }
}

#Preview {
    PaywallView()
}
