//
//  ScoutNote.swift
//  f/Room
//
//  SwiftData model for a single scouting canvas page (one play / one note).
//

import Foundation
import SwiftData
import PencilKit

@Model
final class ScoutNote {
    // MARK: - Identity
    @Attribute(.unique) var id: UUID

    // MARK: - Game context
    var gameId: UUID?
    var gameLabel: String          // e.g. "KC vs BUF · WK 14"
    var awayTeamId: String
    var homeTeamId: String
    var week: Int
    var season: Int

    // MARK: - Play context (optional — note can be a free-floating game note)
    var playId: UUID?
    var quarter: Int?
    var gameClock: String?         // "8:42"
    var down: Int?
    var distance: Int?
    var yardLine: String?

    // MARK: - Drawings (PencilKit PKDrawing serialized as Data)
    /// Play area drawing (subject to FLIP V/H/180°)
    var playDrawingData: Data?
    /// Memo area drawing (always upright)
    var memoDrawingData: Data?

    // MARK: - Metadata
    var tags: [String]
    var formationLabel: String?    // "SHOTGUN · 11 PERS · TRIPS R"
    var resultYards: Int?
    var resultLabel: String?       // "1ST DOWN", "TD", etc.
    var perspectiveRaw: String     // "offense" | "defense" | "neutral"
    var notes: String?             // optional plain-text note alongside handwriting

    // MARK: - Timestamps
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Init

    init(
        id: UUID = UUID(),
        gameId: UUID? = nil,
        gameLabel: String,
        awayTeamId: String,
        homeTeamId: String,
        week: Int,
        season: Int,
        playId: UUID? = nil,
        quarter: Int? = nil,
        gameClock: String? = nil,
        down: Int? = nil,
        distance: Int? = nil,
        yardLine: String? = nil,
        playDrawingData: Data? = nil,
        memoDrawingData: Data? = nil,
        tags: [String] = [],
        formationLabel: String? = nil,
        resultYards: Int? = nil,
        resultLabel: String? = nil,
        perspective: Perspective = .offense,
        notes: String? = nil
    ) {
        self.id = id
        self.gameId = gameId
        self.gameLabel = gameLabel
        self.awayTeamId = awayTeamId
        self.homeTeamId = homeTeamId
        self.week = week
        self.season = season
        self.playId = playId
        self.quarter = quarter
        self.gameClock = gameClock
        self.down = down
        self.distance = distance
        self.yardLine = yardLine
        self.playDrawingData = playDrawingData
        self.memoDrawingData = memoDrawingData
        self.tags = tags
        self.formationLabel = formationLabel
        self.resultYards = resultYards
        self.resultLabel = resultLabel
        self.perspectiveRaw = perspective.rawValue
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Convenience

    var perspective: Perspective {
        get { Perspective(rawValue: perspectiveRaw) ?? .offense }
        set { perspectiveRaw = newValue.rawValue }
    }

    var playDrawing: PKDrawing {
        get {
            guard let data = playDrawingData else { return PKDrawing() }
            return (try? PKDrawing(data: data)) ?? PKDrawing()
        }
        set {
            playDrawingData = newValue.dataRepresentation()
            updatedAt = Date()
        }
    }

    var memoDrawing: PKDrawing {
        get {
            guard let data = memoDrawingData else { return PKDrawing() }
            return (try? PKDrawing(data: data)) ?? PKDrawing()
        }
        set {
            memoDrawingData = newValue.dataRepresentation()
            updatedAt = Date()
        }
    }
}
