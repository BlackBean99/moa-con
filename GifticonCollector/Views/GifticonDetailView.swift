import SwiftData
import SwiftUI

struct GifticonDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let gifticon: Gifticon
    @State private var initialAmountText = ""
    @State private var deductionText = ""
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("기프트콘 정보") {
                infoRow("브랜드", gifticon.brand)
                infoRow("상품", gifticon.title)
                infoRow("바코드", gifticon.barcodeNumber ?? "-")
                if let expiryDate = gifticon.expiryDate {
                    infoRow("유효기간", expiryDate.formatted(date: .numeric, time: .omitted))
                }
            }

            Section("금액") {
                if let remainingAmount = gifticon.remainingAmount {
                    infoRow("남은 금액", formatAmount(remainingAmount))
                    if let originalAmount = gifticon.originalAmount {
                        infoRow("처음 금액", formatAmount(originalAmount))
                    }
                    Button(gifticon.allowsPartialRedemption ? "부분 차감 끄기" : "부분 차감 허용") {
                        updatePartialRedemption(!gifticon.allowsPartialRedemption)
                    }
                    if gifticon.allowsPartialRedemption && !gifticon.isUsed {
                        HStack {
                            TextField("차감할 금액", text: $deductionText)
                                .keyboardType(.decimalPad)
                            Button("차감") { deduct() }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                } else {
                    Text("금액이 인식되지 않았습니다. 직접 입력하면 차감 기능을 사용할 수 있습니다.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    HStack {
                        TextField("처음 금액", text: $initialAmountText)
                            .keyboardType(.decimalPad)
                        Button("저장") { setInitialAmount() }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }

            Section {
                Button(gifticon.isUsed ? "사용 처리 취소" : "사용 완료 처리") {
                    do {
                        try PersistenceService(modelContext: modelContext).toggleUsed(gifticon)
                    } catch {
                        errorMessage = "사용 상태를 저장하지 못했습니다."
                    }
                }
                .foregroundStyle(gifticon.isUsed ? .orange : .green)
            }

            if let errorMessage {
                Section { Text(errorMessage).foregroundStyle(.red) }
            }
        }
        .navigationTitle(gifticon.brand)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }

    private func formatAmount(_ amount: Double) -> String {
        "\(amount.formatted(.number.precision(.fractionLength(0))))원"
    }

    private func updatePartialRedemption(_ enabled: Bool) {
        do {
            try PersistenceService(modelContext: modelContext).setPartialRedemption(enabled, for: gifticon)
            errorMessage = nil
        } catch {
            errorMessage = "차감 설정을 저장하지 못했습니다."
        }
    }

    private func setInitialAmount() {
        guard let amount = Double(initialAmountText), amount > 0 else {
            errorMessage = "처음 금액을 숫자로 입력해 주세요."
            return
        }
        do {
            try PersistenceService(modelContext: modelContext).setInitialAmount(amount, for: gifticon)
            initialAmountText = ""
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deduct() {
        guard let amount = Double(deductionText), amount > 0 else {
            errorMessage = "차감 금액을 숫자로 입력해 주세요."
            return
        }
        do {
            try PersistenceService(modelContext: modelContext).deduct(amount, from: gifticon)
            deductionText = ""
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
