//
//  DailyDigestCard.swift
//  Redzone Tracker
//
//  Hero card shown at the top of the News tab. Displays the AI-generated daily
//  digest with EN/JA toggle and expandable topics.
//

import SwiftUI

struct DailyDigestCard: View {
    let envelope: DigestEnvelope
    @State private var isJapanese: Bool = true
    @State private var isExpanded: Bool = false

    private var d: DailyDigest { envelope.digest }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            metaBar
            heroBlock
            if isExpanded {
                Divider().background(FRTheme.Color.line).padding(.top, 4)
                bodyArticle
                topicsList
                watchTomorrow
            }
            expandToggle
        }
        .background(
            ZStack {
                FRTheme.Color.bg2
                RadialGradient(colors: [FRTheme.Color.rzRed.opacity(0.14), .clear],
                               center: .topTrailing, startRadius: 0, endRadius: 280)
            }
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(FRTheme.Color.logoGradient)
                .frame(width: 3)
        }
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(FRTheme.Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Meta bar (time of day + EN/JA toggle)

    private var metaBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: envelope.timeOfDay == "morning" ? "sunrise.fill" : "moon.stars.fill")
                    .font(.system(size: 12))
                    .foregroundColor(FRTheme.Color.ezGold)
                Text(envelope.timeOfDay.uppercased() + " DIGEST")
                    .font(.system(size: 10, weight: .heavy)).tracking(2)
                    .foregroundColor(FRTheme.Color.ezGold)
            }
            Spacer()
            Text(envelope.generatedDate.formatted(.relative(presentation: .named)))
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(FRTheme.Color.text2)
            // EN/JA toggle
            HStack(spacing: 0) {
                langChip("JA", isActive: isJapanese) { isJapanese = true }
                langChip("EN", isActive: !isJapanese) { isJapanese = false }
            }
            .background(FRTheme.Color.bg3)
            .clipShape(Capsule())
        }
        .padding(14)
    }

    private func langChip(_ label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 9, weight: .heavy)).tracking(1)
                .foregroundColor(isActive ? .white : FRTheme.Color.text2)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(isActive ? FRTheme.Color.rzRed : .clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Hero (headline + lead)

    private var heroBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isJapanese ? d.headlineJA : d.headlineEN)
                .font(FRTheme.Font.bebas(size: 24))
                .tracking(1.5)
                .foregroundColor(FRTheme.Color.text0)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            Text(isJapanese ? d.leadJA : d.leadEN)
                .font(.system(size: 13))
                .foregroundColor(FRTheme.Color.text1)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
    }

    // MARK: - Body article (long-form analysis paragraphs)

    @ViewBuilder
    private var bodyArticle: some View {
        let text = (isJapanese ? d.bodyJA : d.bodyEN) ?? ""
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(isJapanese ? "詳しい分析" : "DEEP DIVE")
                    .font(.system(size: 10, weight: .heavy)).tracking(2)
                    .foregroundColor(FRTheme.Color.text2)
                ForEach(paragraphs(of: text), id: \.self) { para in
                    Text(para)
                        .font(.system(size: 13))
                        .foregroundColor(FRTheme.Color.text0)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 4)
        }
    }

    private func paragraphs(of text: String) -> [String] {
        text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Topics

    private var topicsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(isJapanese ? "今日の注目トピックス" : "TODAY'S TOP STORIES")
                .font(.system(size: 10, weight: .heavy)).tracking(2)
                .foregroundColor(FRTheme.Color.text2)
            ForEach(d.topics) { topic in
                topicRow(topic)
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private func topicRow(_ t: DigestTopic) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle().fill(importanceColor(t.importance)).frame(width: 6, height: 6)
                if let team = t.teamAbbrev {
                    Text(team)
                        .font(FRTheme.Font.bebas(size: 13)).tracking(1)
                        .foregroundColor(FRTheme.Color.ezGold)
                }
                Text(isJapanese ? t.titleJA : t.titleEN)
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundColor(FRTheme.Color.text0)
                    .lineLimit(2)
                Spacer()
            }
            Text(isJapanese ? t.bodyJA : t.bodyEN)
                .font(.system(size: 12))
                .foregroundColor(FRTheme.Color.text1)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .background(FRTheme.Color.bg3.opacity(0.5))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(FRTheme.Color.line, lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func importanceColor(_ imp: TopicImportance) -> Color {
        switch imp {
        case .high: return FRTheme.Color.rzRedBright
        case .medium: return FRTheme.Color.ezGold
        case .low: return FRTheme.Color.text2
        }
    }

    // MARK: - Watch tomorrow

    private var watchTomorrow: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "eye.fill")
                .font(.system(size: 14))
                .foregroundColor(FRTheme.Color.elecBlue)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(isJapanese ? "明日の見どころ" : "WATCH TOMORROW")
                    .font(.system(size: 9, weight: .heavy)).tracking(2)
                    .foregroundColor(FRTheme.Color.elecBlue)
                Text(isJapanese ? d.watchTomorrowJA : d.watchTomorrowEN)
                    .font(.system(size: 12))
                    .foregroundColor(FRTheme.Color.text1)
            }
            Spacer()
        }
        .padding(12)
        .background(FRTheme.Color.elecBlue.opacity(0.08))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(FRTheme.Color.elecBlue.opacity(0.3), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    // MARK: - Expand toggle

    private var expandToggle: some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
            HStack(spacing: 6) {
                Text(isExpanded
                     ? (isJapanese ? "閉じる" : "Collapse")
                     : (isJapanese ? "詳しく読む" : "Read more"))
                    .font(.system(size: 11, weight: .heavy)).tracking(2)
                    .textCase(.uppercase)
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 10, weight: .heavy))
            }
            .foregroundColor(FRTheme.Color.rzRedBright)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(FRTheme.Color.bg3.opacity(0.5))
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    ScrollView {
        DailyDigestCard(envelope: DigestEnvelope(
            version: 1,
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            timeOfDay: "morning",
            sourceItemCount: 50,
            rankedItemCount: 20,
            digest: .mock
        ))
        .padding()
    }
    .background(FRTheme.Color.bg1)
    .preferredColorScheme(.dark)
}
#endif
