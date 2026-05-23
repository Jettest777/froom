//
//  ScoutNoteStore.swift
//  f/Room
//
//  Thin wrapper around SwiftData ModelContext for ScoutNote CRUD.
//

import Foundation
import SwiftData
import PencilKit

@Observable
final class ScoutNoteStore {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Create

    func newNote(for game: Game, play: Play? = nil, perspective: Perspective = .offense) -> ScoutNote {
        let gameLabel = "\(game.awayTeamId) vs \(game.homeTeamId) · WK \(game.week)"
        let note = ScoutNote(
            gameId: game.id,
            gameLabel: gameLabel,
            awayTeamId: game.awayTeamId,
            homeTeamId: game.homeTeamId,
            week: game.week,
            season: game.season,
            playId: play?.id,
            quarter: play?.quarter,
            gameClock: play?.gameClock,
            down: play?.down,
            distance: play?.distance,
            yardLine: play?.yardLine,
            perspective: perspective
        )
        context.insert(note)
        try? context.save()
        return note
    }

    // MARK: - Save

    /// Persist any pending changes. Call this from the canvas on a debounce.
    func save() {
        do {
            try context.save()
        } catch {
            print("[ScoutNoteStore] save error: \(error)")
        }
    }

    // MARK: - Fetch

    func notes(for gameId: UUID?) -> [ScoutNote] {
        var descriptor = FetchDescriptor<ScoutNote>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        if let gameId {
            descriptor.predicate = #Predicate<ScoutNote> { $0.gameId == gameId }
        }
        return (try? context.fetch(descriptor)) ?? []
    }

    func notes(matchingTag tag: String) -> [ScoutNote] {
        let descriptor = FetchDescriptor<ScoutNote>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let all = (try? context.fetch(descriptor)) ?? []
        let needle = tag.uppercased()
        return all.filter { $0.tags.contains(where: { $0.uppercased() == needle }) }
    }

    func allNotes() -> [ScoutNote] {
        let descriptor = FetchDescriptor<ScoutNote>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Group notes by game, sorted by most recent activity.
    struct GameNoteGroup: Identifiable {
        let id: String  // composite key
        let gameLabel: String
        let week: Int
        let season: Int
        let awayTeamId: String
        let homeTeamId: String
        let notes: [ScoutNote]
        var lastUpdated: Date { notes.first?.updatedAt ?? .distantPast }
    }

    func groupedByGame() -> [GameNoteGroup] {
        let all = allNotes()
        let groups = Dictionary(grouping: all) { note in
            "\(note.season)-W\(note.week)-\(note.awayTeamId)-\(note.homeTeamId)"
        }
        return groups
            .map { (key, notes) in
                let first = notes.first!
                return GameNoteGroup(
                    id: key,
                    gameLabel: first.gameLabel,
                    week: first.week,
                    season: first.season,
                    awayTeamId: first.awayTeamId,
                    homeTeamId: first.homeTeamId,
                    notes: notes.sorted { $0.updatedAt > $1.updatedAt }
                )
            }
            .sorted { $0.lastUpdated > $1.lastUpdated }
    }

    /// Collect all unique tags across all notes.
    func allTags() -> [String] {
        let all = allNotes()
        var set = Set<String>()
        for n in all { for t in n.tags { set.insert(t.uppercased()) } }
        return Array(set).sorted()
    }

    // MARK: - Delete

    func delete(_ note: ScoutNote) {
        context.delete(note)
        try? context.save()
    }
}
