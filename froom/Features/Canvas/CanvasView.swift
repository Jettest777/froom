//
//  CanvasView.swift
//  f/Room
//
//  Three-zone scouting canvas (iPad-focused) backed by SwiftData ScoutNote.
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
//  Drawings auto-save to ScoutNote (SwiftData) on a 500ms debounce.
//

import SwiftUI
import SwiftData
import PencilKit
import Combine

struct CanvasView: View {
    let context: CanvasContext

    @Environment(\.modelContext) private var modelContext
    @State private var note: ScoutNote?
    @State private var playDrawing = PKDrawing()
    @State private var memoDrawing = PKDrawing()
    @State private var flipV: Bool = false
    @State private var flipH: Bool = false
    @State private var selectedTool: CanvasTool = .pen
    @State private var inkColor: Color = Color(red: 0.102, green: 0.078, blue: 0.063)
    @State private var perspective: Perspective = .offense
    @State private var saveDebouncer = SaveDebouncer()
    @State private var availableTags: [String] = ["PA", "SHOTGUN", "11 PERS", "TRIPS R", "RED ZONE", "RPO", "BLITZ", "COVER 1"]
    @State private var activeTags: Set<String> = ["PA", "SHOTGUN", "11 PERS", "TRIPS R"]
    @State private var memoText: String = ""

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
        .onAppear { loadOrCreateNote() }
        .onDisappear { savePending() }
    }

    // MARK: - Load / Save

    private func loadOrCreateNote() {
        let store = ScoutNoteStore(context: modelContext)
        // Try to find an existing note for this play
        if let playId = context.play?.id {
            let existing = store.notes(for: context.game.id).first { $0.playId == playId }
            if let existing = existing {
                bindToNote(existing)
                return
            }
        }
        // Otherwise create a fresh one
        let newNote = store.newNote(for: context.game, play: context.play, perspective: perspective)
        bindToNote(newNote)
    }

    private func bindToNote(_ n: ScoutNote) {
        note = n
        playDrawing = n.playDrawing
        memoDrawing = n.memoDrawing
        perspective = n.perspective
        if !n.tags.isEmpty {
            activeTags = Set(n.tags)
        }
        memoText = n.notes ?? ""
    }

    private func savePending() {
        guard let n = note else { return }
        n.playDrawingData = playDrawing.dataRepresentation()
        n.memoDrawingData = memoDrawing.dataRepresentation()
        n.tags = Array(activeTags).sorted()
        n.perspective = perspective
        n.notes = memoText
        n.updatedAt = Date()
        try? modelContext.save()
    }

    private func scheduleSave() {
        saveDebouncer.schedule {
            savePending()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 14) {
            HStack(spacing: 8) {
                RZTLogo(style: .mark, size: .header, showsSubtitle: false)
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
            // Save indicator
            saveIndicator
            Spacer()
            FRIconButton(systemName: "square.and.arrow.down") { savePending() }
            FRIconButton(systemName: "square.and.arrow.up") { }
        }
        .padding(.horizontal, 18)
        .frame(height: 56)
        .background(FRTheme.Color.bg2)
        .overlay(alignment: .bottom) { Rectangle().fill(FRTheme.Color.line).frame(height: 1) }
    }

    private var saveIndicator: some View {
        HStack(spacing: 6) {
            Circle().fill(saveDebouncer.isPending ? FRTheme.Color.bronze : FRTheme.Color.good)
                .frame(width: 6, height: 6)
            Text(saveDebouncer.isPending ? "Saving..." : "Saved")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(FRTheme.Color.text2)
                .tracking(1)
        }
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
            FRIconButton(systemName: "arrow.uturn.backward") { }
            FRIconButton(systemName: "arrow.uturn.forward") { }
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
        Color(red: 0.102, green: 0.078, blue: 0.063),
        Color(red: 0.612, green: 0.271, blue: 0.137),
        Color(red: 0.082, green: 0.314, blue: 0.549),
        Color(red: 0.722, green: 0.518, blue: 0.227),
        Color(red: 0.365, green: 0.541, blue: 0.290)
    ]

    // MARK: - Canvas Stack

    private var canvasStack: some View {
        VStack(spacing: 0) {
            playArea
            memoArea
        }
    }

    private var playArea: some View {
        GeometryReader { geo in
            ZStack {
                FRTheme.Color.whiteboard
                Text("O# · OFFENSE")
                    .font(.system(size: 10, weight: .heavy)).tracking(3)
                    .foregroundColor(FRTheme.Color.rust.opacity(0.6))
                    .position(x: 90, y: 18)
                Text("D# · DEFENSE")
                    .font(.system(size: 10, weight: .heavy)).tracking(3)
                    .foregroundColor(Color(red: 0.29, green: 0.47, blue: 0.84).opacity(0.7))
                    .position(x: 90, y: geo.size.height - 18)
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

                CanvasInkView(
                    drawing: $playDrawing,
                    tool: selectedTool,
                    inkColor: inkColor,
                    onChange: { scheduleSave() }
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

                    Path { path in
                        path.move(to: CGPoint(x: 36, y: 0))
                        path.addLine(to: CGPoint(x: 36, y: geo.size.height))
                    }
                    .strokedPath(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundColor(FRTheme.Color.rust.opacity(0.4))
                }

                Text("NOTES · 手書きメモ")
                    .font(.system(size: 10, weight: .heavy)).tracking(3)
                    .foregroundColor(Color.black.opacity(0.5))
                    .padding(.leading, 50).padding(.top, 8)

                CanvasInkView(
                    drawing: $memoDrawing,
                    tool: selectedTool,
                    inkColor: inkColor,
                    onChange: { scheduleSave() }
                )
            }
        }
        .frame(height: UIScreen.main.bounds.height * 0.4)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.black.opacity(0.12)).frame(height: 2)
        }
        .clipped()
    }

    // MARK: - Perspective / Flip

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
        scheduleSave()
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
            FlowLayout(spacing: 4) {
                ForEach(availableTags, id: \.self) { tag in
                    Button(action: { toggleTag(tag) }) {
                        Text(tag)
                            .font(.system(size: 10, weight: .semibold)).tracking(1.5)
                            .foregroundColor(activeTags.contains(tag) ? .white : FRTheme.Color.text1)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(activeTags.contains(tag) ? FRTheme.Color.rust : FRTheme.Color.bg3)
                            .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(activeTags.contains(tag) ? FRTheme.Color.rust : FRTheme.Color.line, lineWidth: 1))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .buttonStyle(.plain)
                }
            }

            rightTitle("Text Notes")
            TextEditor(text: $memoText)
                .scrollContentBackground(.hidden)
                .background(FRTheme.Color.bg2)
                .font(.system(size: 12))
                .foregroundColor(FRTheme.Color.text0)
                .frame(minHeight: 80, maxHeight: 140)
                .padding(8)
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(FRTheme.Color.line, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onChange(of: memoText) { _, _ in scheduleSave() }
            Spacer()
        }
        .padding(16)
        .frame(width: 300)
        .background(FRTheme.Color.bg1)
        .overlay(alignment: .leading) { Rectangle().fill(FRTheme.Color.line).frame(width: 1) }
    }

    private func toggleTag(_ tag: String) {
        if activeTags.contains(tag) { activeTags.remove(tag) }
        else { activeTags.insert(tag) }
        scheduleSave()
    }

    private func rightTitle(_ s: String) -> some View {
        Text(s.uppercased())
            .font(.system(size: 10, weight: .heavy)).tracking(3)
            .foregroundColor(FRTheme.Color.text2)
    }
}

// MARK: - UIViewRepresentable PKCanvasView wrapper

struct CanvasInkView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let tool: CanvasView.CanvasTool
    let inkColor: Color
    let onChange: () -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawing = drawing
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawingPolicy = .anyInput
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
            parent.onChange()
        }
    }
}

// MARK: - Save Debouncer

@Observable
final class SaveDebouncer {
    private var workItem: DispatchWorkItem?
    private(set) var isPending: Bool = false
    let interval: TimeInterval = 0.5

    func schedule(_ block: @escaping () -> Void) {
        workItem?.cancel()
        isPending = true
        let item = DispatchWorkItem { [weak self] in
            block()
            self?.isPending = false
        }
        workItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: item)
    }
}

// MARK: - FlowLayout (simple tag wrap)

struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentRowHeight: CGFloat = 0

        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            if currentX + viewSize.width > width {
                height += currentRowHeight + spacing
                currentX = viewSize.width + spacing
                currentRowHeight = viewSize.height
            } else {
                currentX += viewSize.width + spacing
                currentRowHeight = max(currentRowHeight, viewSize.height)
            }
        }
        height += currentRowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var currentRowHeight: CGFloat = 0

        for view in subviews {
            let viewSize = view.sizeThatFits(.unspecified)
            if x + viewSize.width > bounds.maxX {
                x = bounds.minX
                y += currentRowHeight + spacing
                currentRowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(viewSize))
            x += viewSize.width + spacing
            currentRowHeight = max(currentRowHeight, viewSize.height)
        }
    }
}

// MARK: - Routing context

struct CanvasContext: Hashable {
    let game: Game
    let play: Play?
}
