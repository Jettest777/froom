//
//  AthleticismView.swift
//  Redzone Tracker
//
//  Player's physical / athletic profile, powered by RAS data.
//  Components:
//    - Hero with overall RAS score + grade
//    - Radar chart of size / speed / explosion / agility / strength
//    - Raw combine numbers grid
//    - Source link footer
//

import SwiftUI

struct AthleticismView: View {
    let entry: RASEntry?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let entry {
                    overallHero(entry)
                    radarSection(entry)
                    combineGrid(entry)
                    sourceFooter(entry)
                } else {
                    notAvailable
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Overall hero

    private func overallHero(_ e: RASEntry) -> some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                Text(String(format: "%.2f", e.rasOverall ?? 0))
                    .font(FRTheme.Font.bebas(size: 76))
                    .foregroundStyle(gradeGradient(e.rasOverall ?? 0))
                VStack(alignment: .leading, spacing: 4) {
                    Text("RAS")
                        .font(.system(size: 11, weight: .heavy)).tracking(3)
                        .foregroundColor(FRTheme.Color.text2)
                    Text(e.gradeLabel)
                        .font(.system(size: 14, weight: .heavy)).tracking(2)
                        .foregroundColor(gradeColor(e.rasOverall ?? 0))
                    Text("/ 10")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(FRTheme.Color.text2)
                }
                Spacer()
            }

            // Overall progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(FRTheme.Color.bg3).frame(height: 6)
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [FRTheme.Color.elecBlue, FRTheme.Color.ezGold, FRTheme.Color.rzRed],
                            startPoint: .leading, endPoint: .trailing
                        ))
                        .frame(width: geo.size.width * e.overallNormalized, height: 6)
                }
                .clipShape(RoundedRectangle(cornerRadius: 3))
            }
            .frame(height: 6)

            HStack {
                Text(e.position)
                    .font(FRTheme.Font.bebas(size: 14)).tracking(2)
                    .foregroundColor(FRTheme.Color.text1)
                if let yr = e.draftYear {
                    Text("Class of \(String(yr))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(FRTheme.Color.text2)
                }
                Spacer()
            }
        }
        .padding(16)
        .background(FRTheme.Color.bg2)
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(FRTheme.Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Radar chart

    private func radarSection(_ e: RASEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ATHLETIC PROFILE")
                .font(.system(size: 11, weight: .heavy)).tracking(3)
                .foregroundColor(FRTheme.Color.text1)
            RadarChart(values: [
                ("SIZE", e.rasSize ?? 0),
                ("SPEED", e.rasSpeed ?? 0),
                ("EXPLOSION", e.rasExplosion ?? 0),
                ("AGILITY", e.rasAgility ?? 0),
                ("STRENGTH", e.rasStrength ?? 0),
            ])
            .frame(height: 260)
            .padding(.top, 8)
        }
        .padding(16)
        .background(FRTheme.Color.bg2)
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(FRTheme.Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Combine numbers

    private func combineGrid(_ e: RASEntry) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NFL COMBINE")
                .font(.system(size: 11, weight: .heavy)).tracking(3)
                .foregroundColor(FRTheme.Color.text1)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                combineCard("Height", value: e.heightDisplay, unit: nil)
                combineCard("Weight", value: e.weight.map { String(Int($0)) } ?? "—", unit: "LB")
                combineCard("40-yd", value: e.fortyYard.map { String(format: "%.2f", $0) } ?? "—", unit: "SEC")
                combineCard("Vertical", value: e.verticalJump.map { String(format: "%.1f", $0) } ?? "—", unit: "IN")
                combineCard("Broad Jump", value: e.broadJump.map { String(format: "%.0f", $0) } ?? "—", unit: "IN")
                combineCard("Bench", value: e.benchPress.map { "\($0)" } ?? "—", unit: "REPS")
                combineCard("3-Cone", value: e.threeConeShuttle.map { String(format: "%.2f", $0) } ?? "—", unit: "SEC")
                combineCard("Shuttle", value: e.shortShuttle.map { String(format: "%.2f", $0) } ?? "—", unit: "SEC")
            }
        }
        .padding(16)
        .background(FRTheme.Color.bg2)
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(FRTheme.Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func combineCard(_ label: String, value: String, unit: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .heavy)).tracking(2)
                .foregroundColor(FRTheme.Color.text2)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(FRTheme.Font.bebas(size: 22))
                    .foregroundColor(FRTheme.Color.text0)
                if let unit {
                    Text(unit)
                        .font(.system(size: 9, weight: .heavy)).tracking(1)
                        .foregroundColor(FRTheme.Color.text2)
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FRTheme.Color.bg3)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Source footer

    private func sourceFooter(_ e: RASEntry) -> some View {
        Link(destination: URL(string: e.sourceURL) ?? URL(string: "https://ras.football")!) {
            HStack(spacing: 8) {
                Image(systemName: "link").font(.system(size: 11))
                Text("Source: ras.football")
                    .font(.system(size: 10, weight: .semibold))
                Spacer()
                Image(systemName: "arrow.up.right.square").font(.system(size: 11))
            }
            .foregroundColor(FRTheme.Color.elecBlue)
            .padding(.horizontal, 12).padding(.vertical, 10)
            .background(FRTheme.Color.elecBlue.opacity(0.08))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(FRTheme.Color.elecBlue.opacity(0.3), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Empty state

    private var notAvailable: some View {
        VStack(spacing: 14) {
            Image(systemName: "figure.run")
                .font(.system(size: 36))
                .foregroundColor(FRTheme.Color.text2)
            Text("RAS データは未取得です")
                .font(.system(size: 14, weight: .heavy)).tracking(1)
                .foregroundColor(FRTheme.Color.text1)
            Text("この選手の RAS データはまだ収集されていません。\nras-seed.json に追加して GitHub Actions を実行してください。")
                .font(.system(size: 11))
                .foregroundColor(FRTheme.Color.text2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
        .background(FRTheme.Color.bg2)
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(FRTheme.Color.line, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Color helpers

    private func gradeColor(_ score: Double) -> Color {
        switch score {
        case 9.5...: return FRTheme.Color.rzRedBright
        case 8.5..<9.5: return FRTheme.Color.ezGold
        case 7.0..<8.5: return FRTheme.Color.good
        case 5.0..<7.0: return FRTheme.Color.elecBlue
        default: return FRTheme.Color.text2
        }
    }

    private func gradeGradient(_ score: Double) -> LinearGradient {
        switch score {
        case 9.5...:
            return LinearGradient(colors: [FRTheme.Color.rzRedBright, FRTheme.Color.rzRedDeep],
                                  startPoint: .top, endPoint: .bottom)
        case 8.5..<9.5:
            return FRTheme.Color.goldGradient
        case 7.0..<8.5:
            return LinearGradient(colors: [FRTheme.Color.good, FRTheme.Color.good.opacity(0.6)],
                                  startPoint: .top, endPoint: .bottom)
        default:
            return LinearGradient(colors: [FRTheme.Color.elecBlue, FRTheme.Color.elecBlueDeep],
                                  startPoint: .top, endPoint: .bottom)
        }
    }
}

// MARK: - Radar Chart

struct RadarChart: View {
    let values: [(String, Double)]  // each value 0..10

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size * 0.40
            let count = values.count

            ZStack {
                // Background grid (concentric polygons at 25/50/75/100%)
                ForEach(1...4, id: \.self) { ring in
                    polygonPath(center: center, radius: radius * CGFloat(ring) / 4, sides: count)
                        .stroke(FRTheme.Color.line.opacity(0.4), lineWidth: 1)
                }
                // Axes
                ForEach(0..<count, id: \.self) { i in
                    let angle = angleFor(i, count: count)
                    Path { p in
                        p.move(to: center)
                        p.addLine(to: CGPoint(
                            x: center.x + cos(angle) * radius,
                            y: center.y + sin(angle) * radius
                        ))
                    }
                    .stroke(FRTheme.Color.line.opacity(0.3), lineWidth: 0.5)
                }
                // Value polygon (filled)
                valuePath(center: center, radius: radius)
                    .fill(FRTheme.Color.rzRed.opacity(0.25))
                valuePath(center: center, radius: radius)
                    .stroke(FRTheme.Color.rzRedBright, lineWidth: 2)
                // Value dots
                ForEach(0..<count, id: \.self) { i in
                    let angle = angleFor(i, count: count)
                    let value = max(0, min(10, values[i].1)) / 10
                    let point = CGPoint(
                        x: center.x + cos(angle) * radius * value,
                        y: center.y + sin(angle) * radius * value
                    )
                    Circle().fill(FRTheme.Color.rzRedBright)
                        .frame(width: 6, height: 6)
                        .position(point)
                }
                // Labels
                ForEach(0..<count, id: \.self) { i in
                    let angle = angleFor(i, count: count)
                    let labelRadius = radius + 24
                    let point = CGPoint(
                        x: center.x + cos(angle) * labelRadius,
                        y: center.y + sin(angle) * labelRadius
                    )
                    VStack(spacing: 2) {
                        Text(values[i].0)
                            .font(.system(size: 9, weight: .heavy)).tracking(1.5)
                            .foregroundColor(FRTheme.Color.text2)
                        Text(String(format: "%.1f", values[i].1))
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundColor(FRTheme.Color.text0)
                    }
                    .position(point)
                }
            }
        }
    }

    private func angleFor(_ index: Int, count: Int) -> Double {
        // Start at top (-π/2) and rotate clockwise
        let step = 2 * .pi / Double(count)
        return -.pi / 2 + step * Double(index)
    }

    private func polygonPath(center: CGPoint, radius: CGFloat, sides: Int) -> Path {
        Path { p in
            for i in 0..<sides {
                let angle = angleFor(i, count: sides)
                let point = CGPoint(
                    x: center.x + cos(angle) * radius,
                    y: center.y + sin(angle) * radius
                )
                if i == 0 { p.move(to: point) } else { p.addLine(to: point) }
            }
            p.closeSubpath()
        }
    }

    private func valuePath(center: CGPoint, radius: CGFloat) -> Path {
        Path { p in
            for i in 0..<values.count {
                let angle = angleFor(i, count: values.count)
                let value = max(0, min(10, values[i].1)) / 10
                let point = CGPoint(
                    x: center.x + cos(angle) * radius * value,
                    y: center.y + sin(angle) * radius * value
                )
                if i == 0 { p.move(to: point) } else { p.addLine(to: point) }
            }
            p.closeSubpath()
        }
    }
}

#if DEBUG
#Preview {
    AthleticismView(entry: .mockMahomes)
        .background(FRTheme.Color.bg1)
        .preferredColorScheme(.dark)
}
#endif
