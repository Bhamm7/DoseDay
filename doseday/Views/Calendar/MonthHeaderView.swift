import SwiftUI

struct MonthHeaderView: View {
    let month: Date
    let onPrev: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack {
            Button(action: onPrev) {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(DDTheme.accent)
            }
            Spacer()
            Text(month, format: .dateTime.month(.wide).year())
                .font(.title3.weight(.bold))
                .foregroundStyle(DDTheme.textPrimary)
            Spacer()
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(DDTheme.accent)
            }
        }
        .padding(.horizontal)
    }
}
