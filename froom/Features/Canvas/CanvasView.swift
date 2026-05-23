//
//  CanvasView.swift
//  f/Room
//
//  Three-zone scouting canvas (iPad-focused).
//
//  Layout (vertical stack):
//    ┌──────────────────────────────┐
//    │  O# (Offense) — handwritten  │
//    ├ ─ ─ ─ ─ LOS ─ ─ ─ ─ ─ ─ ─ ─ │   <- play area (60%)
//    │  D# (Defense) — handwritten  │   <- can flip (V/H/180°)
//    ├══════════════════════════════┤
//    │  Notes — separate canvas,    │
//    │  always upright              │   <- memo area (40%)
//    └──────────────────────────────┘
//
//  Memo area is a SEPARATE PKCanvasView so it never flips when FLIP V/H/180° is applied.
//

import SwiftUI
import PencilKit

struct CanvasView: View {
    let context: CanvasContext

    @State private var playDrawing = PKDrawing()
    @State private var memoDrawing = PKDrawing()
    @State private var flipV: Bool = false
    @State private var flipH: Bool = false
    @State private var selectedTool: CanvasTool = .pen
    @State private var inkColor: Color = Color(red: 0.102, green: 0.078, blue: 0.063)  // #1a1410
    @State private var perspective: Perspective = .offense

    enum CanvasTool: String, CaseIterable {
        case pen, marker, highlighter, eraser, lasso
    }

    var body: some View {
        HStack(spacing: 0) {
            leftRail
            VStack(spacing: 0) {
                topBar
                ZStack {
                    canvasStack
                    perspectiveBadge
                    flipToolbar
                }
            }
            rightRail
        }
        .background(FRTheme.Color.bg1)
        .navigationBarBackButtonHidden(false)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 14) {
            HStack(spacing: 8) {
                FRAppIcon(size: 24)
                HStack(spacing: 6) {
                    Text(context.game.awayTeamId).font(FRTheme.Font.bebas(size: 18)).tracking(2)
                    Text("vs").foregroundColor(FRTheme.Color.rustBright).italic().font(.system(size: 12))
                    Text(context.game.homeTeamId).font(FRTheme.Font.bebas(size: 18)).tracking(2)
                }
                .foregroundColor(FRTheme.Color.text0)
            }
            if let p = context.play {
                Text("Q\(p.quarter) \(p.gameClock) · \(p.down ?? 1)&\(p.distance ?? 0) · \(p.yardLine)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(FRTheme.Color.text1)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(FRTheme.Color.bg3)
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(FRTheme.Color.line, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            Spacer()
            FRIconButton(systemName: "square.and.arrow.down") { saveDrawing() }
            FRIconButton(systemName: "square.and.arrow.up") { }
        }
        .padding(.horizontal, 18)
        .frame(height: 56)
        .background(FRTheme.Color.bg2)
        .overlay(alignment: .bottom) { Rectangle().fill(FRTheme.Color.line).frame(height: 1) }
    }

    // MARK: - Left tool rail

    private var leftRail: some View {
        VStack(spacing: 10) {
            ForEach(CanvasTool.allCases, id: \.self) { tool in
                toolBtn(tool)
            }
            Divider().padding(.vertical, 4)
            ForEach(inkColors, id: \.self) { color in
                Button(action: { inkColor = color }) {
                    Circle()
                        .fill(color)
                        .frame(width: 28, height: 28)
                        .overlay(Circle().strokeBorder(Color.white.opacity(inkColor == color ? 1 : 0.2), lineWidth: 2))
                        .overlay(Circle().strokeBorder(FRTheme.Color.rustBright, lineWidth: inkColor == color ? 2 : 0).padding(-2))
                }
                .buttonStyle(.plain)
            }
            Spacer()
            FRIconButton(systemName: "arrow.uturn.backward") { undo() }
            FRIconButton(systemName: "arrow.uturn.forward") { redo() }
        }
        .frame(width: 64)
        .padding(.vertical, 14)
        .background(FRTheme.Color.bg1)
        .overlay(alignment: .trailing) { Rectangle().fill(FRTheme.Color.line).frame(width: 1) }
    }

    private func toolBtn(_ tool: CanvasTool) -> some View {
        Button(action: { selectedTool = tool }) {
            Image(systemName: iconName(tool))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(selectedTool == tool ? .white : FRTheme.Color.text1)
                .frame(width: 44, height: 44)
                .background(selectedTool == tool ?
                            AnyShapeStyle(LinearGradient(colors: [FRTheme.Color.rust, FRTheme.Color.leatherEdge], startPoint: .topLeading, endPoint: .bottomTrailing)) :
                            AnyShapeStyle(FRTheme.Color.bg2))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(selectedTool == tool ? FRTheme.Color.rust : FRTheme.Color.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func iconName(_ tool: CanvasTool) -> String {
        switch tool {
        case .pen: return "pencil"
        case .marker: return "highlighter"
        case .highlighter: return "marker.line"
        case .eraser: return "eraser"
        case .lasso: return "lasso"
        }
    }

    private let inkColors: [Color] = [
        Color(red: 0.102, green: 0.078, blue: 0.063), // black/ink
        Color(red: 0.612, green: 0.271, blue: 0.137), // rust
        Color(red: 0.082, green: 0.314, blue: 0.549), // navy
        Color(red: 0.722, green: 0.518, blue: 0.227), // bronze
        Color(red: 0.365, green: 0.541, blue: 0.290)  // good (green)
    ]

    // MARK: - Canvas Stack (3 zones)

    private var canvasStack: some View {
        VStack(spacing: 0) {
            // Play area: 60%
            playArea
            // Memo area: 40%
            memoArea
        }
    }

    private var playArea: some View {
        GeometryReader { geo in
            ZStack {
                // Whiteboard surface
                FRTheme.Color.whiteboard
                // Zone labels
                Text("O# · OFFENSE")
                    .font(.system(size: 10, weight: .heavy)).tracking(3)
                    .foregroundColor(FRTheme.Color.rust.opacity(0.6))
                    .position(x: 90, y: 18)
                Text("D# · DEFENSE")
                    .font(.system(size: 10, weight: .heavy)).tracking(3)
                    .foregroundColor(Color(red: 0.29, green: 0.47, blue: 0.84).opacity(0.7))
                    .position(x: 90, y: geo.size.height - 18)
                // LOS horizontal line
                HStack {
                    Text("LOS").font(.system(size: 11, design: .monospaced)).foregroundColor(Color.black.opacity(0.45)).tracking(2)
                    Spacer()
                    Text("LOS").font(.system(size: 11, design: .monospaced)).foregroundColor(Color.black.opacity(0.45)).tracking(2)
                }
                .padding(.horizontal, 20)
                .position(x: geo.size.width / 2, y: geo.size.height / 2 - 14)

                Path { path in
                    path.move(to: CGPoint(x: geo.size.width * 0.05, y: geo.size.height / 2))
                    path.addLine(to: CGPoint(x: geo.size.width * 0.95, y: geo.size.height / 2))
                }
                .strokedPath(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                .foregroundColor(Color.black.opacity(0.3))

                // PencilKit ink (flippable)
                CanvasInkView(
                    drawing: $playDrawing,
                    tool: selectedTool,
                    inkColor: inkColor
                )
                .scaleEffect(x: flipH ? -1 : 1, y: flipV ? -1 : 1)
                .animation(.easeInOut(duration: 0.4), value: flipV)
                .animation(.easeInOut(duration: 0.4), value: flipH)
            }
        }
        .clipped()
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .background(FRTheme.Color.whiteboard)
    }

    private var memoArea: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // Lined memo pad background
                ZStack {
                    FRTheme.Color.memoPad
                    Path { path in
                        let lineSpacing: CGFloat = 32
                        var y = lineSpacing
                        while y < geo.size.height {
                            path.move(to: CGPoint(x: 36, y: y))
                            path.addLine(to: CGPoint(x: geo.size.width - 8, y: y))
                            y += lineSpacing
                        }
                    }
                    .strokedPath(StrokeStyle(lineWidth: 1))
                    .foregroundColor(Color.black.opacity(0.06))

                    // Red margin on the left
                    Path { path in
                        path.move(to: CGPoint(x: 36, y: 0))
                        path.addLine(to: CGPoint(x: 36, y: geo.size.height))
                    }
                    .strokedPath(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundColor(FRTheme.Color.rust.opacity(0.4))
                }

                // Label
                Text("NOTES · 手書きメモ")
                    .font(.system(size: 10, weight: .heavy)).tracking(3)
                    .foregroundColor(Color.black.opacity(0.5))
                    .padding(.leading, 50).padding(.top, 8)

                // Independent PencilKit canvas (never flips)
                CanvasInkView(
                    drawing: $memoDrawing,
                    tool: selectedTool,
                    inkColor: inkColor
                )
            }
        }
        .frame(height: UIScreen.main.bounds.height * 0.4)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.black.opacity(0.12)).frame(height: 2)
        }
        .clipped()
    }

    // MARK: - Perspective badge & flip controls

    private var perspectiveBadge: some View {
        VStack {
            HStack {
                HStack(spacing: 6) {
                    Circle().fill(perspective == .defense
                                  ? Color(red: 0.29, green: 0.47, blue: 0.84)
                                  : FRTheme.Color.rustBright)
                        .frame(width: 6, height: 6)
                    Text(perspective == .defense ? "DEFENSE VIEW" : "OFFENSE VIEW")
                        .font(.system(size: 10, weight: .heavy)).tracking(2)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .overlay(Capsule().strokeBorder(
                    perspective == .defense ? Color(red: 0.29, green: 0.47, blue: 0.84) : FRTheme.Color.rust,
                    lineWidth: 1))
                .clipShape(Capsule())
                Spacer()
            }
            .padding(.top, 14).padding(.leading, 16)
            Spacer()
        }
    }

    private var flipToolbar: some View {
        VStack {
            HStack {
                Spacer()
                VStack(spacing: 8) {
                    flipBtn(label: "FLIP V", systemName: "arrow.up.arrow.down", isActive: flipV) {
                        flipV.toggle()
                        updatePerspective()
                    }
                    flipBtn(label: "FLIP H", systemName: "arrow.left.arrow.right", isActive: flipH) {
                        flipH.toggle()
                    }
                    flipBtn(label: "180°", systemName: "arrow.clockwise", isActive: flipV && flipH) {
                        flipV.toggle()
                        flipH.toggle()
                        updatePerspective()
                    }
                    Divider().padding(.vertical, 4)
                    flipBtn(label: "RESET", systemName: "arrow.counterclockwise", isActive: false) {
                        flipV = false
                        flipH = false
                        updatePerspective()
                    }
                }
            }
            .padding(.top, 14).padding(.trailing, 16)
            Spacer()
        }
    }

    private func flipBtn(label: String, systemName: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemName).font(.system(size: 18)).foregroundColor(.white)
                Text(label).font(.system(size: 9, weight: .semibold)).tracking(1.5)
                    .foregroundColor(isActive ? .white : FRTheme.Color.text2)
            }
            .frame(width: 52)
            .padding(.vertical, 10).padding(.horizontal, 8)
            .background(isActive ?
                        AnyShapeStyle(LinearGradient(colors: [FRTheme.Color.rust, FRTheme.Color.leatherEdge], startPoint: .topLeading, endPoint: .bottomTrailing)) :
                        AnyShapeStyle(.ultraThinMaterial))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(isActive ? FRTheme.Color.rust : FRTheme.Color.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func updatePerspective() {
        perspective = flipV ? .defense : .offense
    }

    // MARK: - Right Rail

    private var rightRail: some View {
        VStack(alignment: .leading, spacing: 14) {
            rightTitle("Game")
            VStack(alignment: .leading, spacing: 4) {
                Text("\(context.game.awayTeamId) @ \(context.game.homeTeamId) · WK \(context.game.week)")
                    .font(FRTheme.Font.bebas(size: 14)).tracking(2)
                Text("2026.12.07 · SUN NIGHT")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(FRTheme.Color.text2)
            }
            .padding(10)
            .background(FRTheme.Color.bg2)
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(FRTheme.Color.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            rightTitle("Play Tags")
            HStack {
                Text("PA").modifier(TagOnStyle())
                Text("SHOTGUN").modifier(TagOnStyle())
            }
            Text("+ ADD").modifier(TagOffStyle())

            rightTitle("Result")
            HStack(spacing: 8) {
                Text("+12 YDS").modifier(ResultChip(bg: FRTheme.Color.good))
                Text("1ST DOWN").modifier(ResultChip(bg: FRTheme.Color.bg3))
            }

            rightTitle("Notes")
            Text("LB #44 stepped up on PA fake. Worthy's skinny post pulls FS off the hash, dig hits in vacated zone.")
                .font(.system(size: 12))
                .foregroundColor(FRTheme.Color.text0)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FRTheme.Color.bg2)
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(FRTheme.Color.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Spacer()
        }
        .padding(16)
        .frame(width: 300)
        .background(FRTheme.Color.bg1)
        .overlay(alignment: .leading) { Rectangle().fill(FRTheme.Color.line).frame(width: 1) }
    }

    private func rightTitle(_ s: String) -> some View {
        Text(s.uppercased())
            .font(.system(size: 10, weight: .heavy)).tracking(3)
            .foregroundColor(FRTheme.Color.text2)
    }

    // MARK: - Actions

    private func undo() { /* PKCanvasView.undoManager?.undo() — wired in UIKit wrapper */ }
    private func redo() { /* same as above */ }
    private func saveDrawing() {
        // TODO: persist playDrawing + memoDrawing to CanvasNote storage.
    }
}

// MARK: - UIViewRepresentable PKCanvasView wrapper

struct CanvasInkView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let tool: CanvasView.CanvasTool
    let inkColor: Color

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput   // allow finger + pencil
        canvas.tool = currentTool()
        canvas.delegate = context.coordinator
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        canvas.tool = currentTool()
        if canvas.drawing != drawing {
            canvas.drawing = drawing
        }
    }

    private func currentTool() -> PKTool {
        let uiColor = UIColor(inkColor)
        switch tool {
        case .pen: return PKInkingTool(.pen, color: uiColor, width: 4)
        case .marker: return PKInkingTool(.marker, color: uiColor, width: 12)
        case .highlighter: return PKInkingTool(.marker, color: uiColor.withAlphaComponent(0.4), width: 16)
        case .eraser: return PKEraserTool(.vector)
        case .lasso: return PKLassoTool()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasInkView
        init(_ parent: CanvasInkView) { self.parent = parent }
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
    }
}

// MARK: - small styles
struct TagOnStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 10, weight: .semibold)).tracking(1.5)
            .foregroundColor(.white)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(FRTheme.Color.rust)
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(FRTheme.Color.rust, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
struct TagOffStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 10, weight: .semibold)).tracking(1.5)
            .foregroundColor(FRTheme.Color.text1)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(FRTheme.Color.bg3)
            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(FRTheme.Color.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
struct ResultChip: ViewModifier {
    let bg: Color
    func body(content: Content) -> some View {
        content
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(bg == FRTheme.Color.good ? .white : FRTheme.Color.text1)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(bg)
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(FRTheme.Color.line, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        CanvasView(context: CanvasContext(game: MockData.sampleGame, play: MockData.sampleGame.playByPlay[2]))
            .preferredColorScheme(.dark)
    }
}
#endif
