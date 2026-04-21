//
//  BoardViewModel.swift
//  Block-Jack
//

import Foundation
import SwiftUI
import Combine

// MARK: - BoardViewModel
final class BoardViewModel: ObservableObject {

    // MARK: - Grid State
    @Published var grid: [[GameCell]] = []
    @Published var ghostCells: Set<GridPosition> = []   // Preview için
    @Published var isGhostValid: Bool = true
    @Published var hintPositions: Set<GridPosition> = [] // AAA: For Clear Hints

    static let size = 13

    // MARK: - Init
    init() { resetGrid() }

    // MARK: - Grid Setup
    func resetGrid() {
        grid = (0..<Self.size).map { _ in
            (0..<Self.size).map { _ in GameCell() }
        }
        ghostCells = []
        hintPositions = []
    }

    // MARK: - Placement Logic

    /// Bloğu verilen pozisyona koyabilir miyiz?
    func canPlace(_ block: GameBlock, at origin: GridPosition) -> Bool {
        for (dr, dc) in block.cells {
            let r = origin.row + dr
            let c = origin.col + dc
            guard r >= 0, r < Self.size, c >= 0, c < Self.size else { return false }
            let cell = grid[r][c]
            if cell.isOccupied || cell.isLocked { return false }
        }
        return true
    }

    /// Bloğu grid'e yerleştir, temizlenen satır/sütun hücrelerini döndür
    @discardableResult
    func placeBlock(_ block: GameBlock, at origin: GridPosition) -> ClearResult? {
        guard canPlace(block, at: origin) else { return nil }

        // Hücreleri doldur
        for (dr, dc) in block.cells {
            let r = origin.row + dr
            let c = origin.col + dc
            grid[r][c].state = .filled(color: block.color)
        }

        ghostCells = []
        
        // MARK: Özel Yetenek Efektleri
        switch block.ability {
        case .lightning:
            // ⚡ Yerleştiği ilk satırı anında sil
            let targetRow = origin.row
            for c in 0..<Self.size {
                grid[targetRow][c].state = .empty
            }
        case .bomb:
            // 💣 3x3 alanı temizle
            let centerR = origin.row + (block.rows / 2)
            let centerC = origin.col + (block.cols / 2)
            for r in max(0, centerR-1)...min(Self.size-1, centerR+1) {
                for c in max(0, centerC-1)...min(Self.size-1, centerC+1) {
                    grid[r][c].state = .empty
                }
            }
        case .wild:
            // 🌀 Bloğun sınır komşularındaki boş hücreleri doldur
            var filled: Set<GridPosition> = []
            for (dr, dc) in block.cells {
                let r = origin.row + dr
                let c = origin.col + dc
                let neighbors = [(-1,0),(1,0),(0,-1),(0,1)]
                for (nr, nc) in neighbors {
                    let rr = r + nr, cc = c + nc
                    if rr >= 0, rr < Self.size, cc >= 0, cc < Self.size,
                       grid[rr][cc].isEmpty,
                       !filled.contains(GridPosition(row: rr, col: cc)) {
                        grid[rr][cc].state = .filled(color: block.color)
                        filled.insert(GridPosition(row: rr, col: cc))
                    }
                }
            }
        case .normal:
            break
        }
        
        let result = clearFullLinesAndZones()
        return result
    }

    /// Ghost (önizleme) güncelle — sadece değişince publish et
    func updateGhost(_ block: GameBlock, at origin: GridPosition) {
        var positions: Set<GridPosition> = []
        for (dr, dc) in block.cells {
            let r = origin.row + dr
            let c = origin.col + dc
            if r >= 0, r < Self.size, c >= 0, c < Self.size {
                positions.insert(GridPosition(row: r, col: c))
            }
        }
        let valid = canPlace(block, at: origin)
        // Gereksiz re-render önle
        if positions != ghostCells { ghostCells = positions }
        if valid != isGhostValid { isGhostValid = valid }
    }

    func clearGhost() {
        ghostCells = []
    }

    // MARK: - Line Clearing

    struct ClearResult {
        let clearedCells: [GameCell]
        let clearedPositions: [GridPosition]
        let rowsCleared: Int
        let colsCleared: Int
        let zonesCleared: Int // NEW: 3x3 Area clears
    }

    @discardableResult
    func clearFullLinesAndZones() -> ClearResult {
        var clearedCells: [GameCell] = []
        var targetPositions: Set<GridPosition> = []
        
        // 1. Detect Rows & Cols
        let fullRows = (0..<Self.size).filter { row in
            grid[row].allSatisfy { $0.isOccupied }
        }
        let fullCols = (0..<Self.size).filter { col in
            (0..<Self.size).allSatisfy { row in grid[row][col].isOccupied }
        }
        
        for r in fullRows {
            for c in 0..<Self.size { targetPositions.insert(GridPosition(row: r, col: c)) }
        }
        for c in fullCols {
            for r in 0..<Self.size { targetPositions.insert(GridPosition(row: r, col: c)) }
        }
        
        // 2. Detect Specific Scoring Zones (4x4 Corners, 5x5 Center)
        var zoneCount = 0
        
        let scoringZones: [(String, Range<Int>, Range<Int>)] = [
            ("Top Left", 0..<4, 0..<4),
            ("Top Right", 0..<4, 9..<13),
            ("Bottom Left", 9..<13, 0..<4),
            ("Bottom Right", 9..<13, 9..<13),
            ("Center", 4..<9, 4..<9)
        ]
        
        for (_, rows, cols) in scoringZones {
            var isFull = true
            for r in rows {
                for c in cols {
                    if !grid[r][c].isOccupied {
                        isFull = false
                        break
                    }
                }
                if !isFull { break }
            }
            
            if isFull {
                zoneCount += 1
                for r in rows {
                    for c in cols {
                        targetPositions.insert(GridPosition(row: r, col: c))
                    }
                }
            }
        }

        if targetPositions.isEmpty { 
            return ClearResult(clearedCells: [], clearedPositions: [], rowsCleared: 0, colsCleared: 0, zonesCleared: 0)
        }

        // Temizlenecek hücrelerin koordinatlarını belirle (targetPositions zaten yukarıda toplandı)
        
        // Hücreleri işle
        for pos in targetPositions {
            let cell = grid[pos.row][pos.col]
            clearedCells.append(cell)
            
            switch cell.state {
            case .heavy(let hits):
                if hits > 1 {
                    grid[pos.row][pos.col].state = .heavy(hits: hits - 1)
                } else {
                    grid[pos.row][pos.col].state = .empty
                }
            case .filled, .locked:
                grid[pos.row][pos.col].state = .empty
            case .empty:
                break
            }
        }
        
        return ClearResult(
            clearedCells: clearedCells,
            clearedPositions: Array(targetPositions),
            rowsCleared: fullRows.count,
            colsCleared: fullCols.count,
            zonesCleared: zoneCount
        )
    }
    
    /// Simüle ederek yerleştirildiğinde hangi hücrelerin patlayacağını söyler (HINT)
    func detectPotentialClears(block: GameBlock, at origin: GridPosition) {
        guard canPlace(block, at: origin) else {
            if !hintPositions.isEmpty { hintPositions = [] }
            return
        }
        
        // Geçici doluluk seti
        var tempOccupied: Set<GridPosition> = []
        for (dr, dc) in block.cells {
            tempOccupied.insert(GridPosition(row: origin.row + dr, col: origin.col + dc))
        }
        
        var targets: Set<GridPosition> = []
        
        // 1. Satırlar — sadece bloğun etkilediği satırları tara
        let affectedRows = Set(block.cells.map { origin.row + $0.0 }).filter { $0 >= 0 && $0 < Self.size }
        for r in affectedRows {
            let rowFull = (0..<Self.size).allSatisfy { c in
                grid[r][c].isOccupied || tempOccupied.contains(GridPosition(row: r, col: c))
            }
            if rowFull {
                for c in 0..<Self.size { targets.insert(GridPosition(row: r, col: c)) }
            }
        }
        
        // 2. Sütunlar — sadece bloğun etkilediği sütunları tara
        let affectedCols = Set(block.cells.map { origin.col + $0.1 }).filter { $0 >= 0 && $0 < Self.size }
        for c in affectedCols {
            let colFull = (0..<Self.size).allSatisfy { r in
                grid[r][c].isOccupied || tempOccupied.contains(GridPosition(row: r, col: c))
            }
            if colFull {
                for r in 0..<Self.size { targets.insert(GridPosition(row: r, col: c)) }
            }
        }
        
        // Gereksiz re-render'ı önle: sadece değiştiyse güncelle
        if targets != hintPositions {
            hintPositions = targets
        }
    }
    
    private func is3x3ZoneMatched(startRow: Int, startCol: Int) -> Bool {
        // First check if all are occupied
        for r in startRow..<startRow+3 {
            for c in startCol..<startCol+3 {
                if !grid[r][c].isOccupied { return false }
            }
        }
        
        // Match same color
        let firstColor = grid[startRow][startCol].color
        for r in startRow..<startRow+3 {
            for c in startCol..<startCol+3 {
                if grid[r][c].color != firstColor { return false }
            }
        }
        return true
    }

    // MARK: - Game State Checks

    /// Akıllı deadlock kontrolü: sadece tray'deki en küçük bloğu referans alır.
    /// Büyük blok sığmıyorsa bile küçük bloğun yeri varsa deadlock sayılmaz.
    func isDeadlock(blocks: [GameBlock]) -> Bool {
        guard !blocks.isEmpty else { return true }
        
        // En az hücreye sahip bloğu bul (deadlock için en zor blok = en küçük)
        let smallestBlock = blocks.min(by: { $0.cells.count < $1.cells.count }) ?? blocks[0]
        
        // Sadece en küçük blok için pozisyon tara
        for r in 0..<Self.size {
            for c in 0..<Self.size {
                if canPlace(smallestBlock, at: GridPosition(row: r, col: c)) {
                    return false // En küçük bile sığıyorsa deadlock yok
                }
            }
        }
        return true
    }

    // MARK: - Boss Modifiers

    func applyGlitch(count: Int) {
        let positions = allEmptyPositions().shuffled().prefix(count)
        for pos in positions {
            grid[pos.row][pos.col].state = .locked
        }
    }

    func applyHeavy() {
        // Mevcut dolu kutuları heavy yap
        for r in 0..<Self.size {
            for c in 0..<Self.size {
                if case .filled(let color) = grid[r][c].state {
                    grid[r][c].state = .heavy(hits: 2)
                }
            }
        }
    }
    
    // MARK: - Phase 5 / 1.4 Grid Modifiers Setup
    
    func applyLockedCells(count: Int) {
        let positions = allEmptyPositions().shuffled().prefix(count)
        for pos in positions {
            grid[pos.row][pos.col].modifier = .locked
        }
    }
    
    func applyBonusCells(count: Int, bonus: BonusType = .gold(5)) {
        let positions = allEmptyPositions().shuffled().prefix(count)
        for pos in positions {
            grid[pos.row][pos.col].modifier = .bonus(bonus)
        }
    }
    
    func applyCursedCells(count: Int) {
        let positions = allEmptyPositions().shuffled().prefix(count)
        for pos in positions {
            grid[pos.row][pos.col].modifier = .cursed
        }
    }
    
    func applyGravity() {
        // Phase 5.2: Shift floating cells downwards
        // Bottom row is Self.size - 1, we start from second to last row and move down.
        var movedAny = false
        
        for c in 0..<Self.size {
            for r in (0..<Self.size-1).reversed() { // from bottom to top
                if case .filled = grid[r][c].state {
                    // Try to drop it as far down as possible
                    var targetRow = r
                    while targetRow + 1 < Self.size && grid[targetRow + 1][c].isEmpty {
                        targetRow += 1
                    }
                    if targetRow != r {
                        grid[targetRow][c].state = grid[r][c].state
                        grid[r][c].state = .empty
                        movedAny = true
                    }
                } else if case .heavy = grid[r][c].state {
                    var targetRow = r
                    while targetRow + 1 < Self.size && grid[targetRow + 1][c].isEmpty {
                        targetRow += 1
                    }
                    if targetRow != r {
                        grid[targetRow][c].state = grid[r][c].state
                        grid[r][c].state = .empty
                        movedAny = true
                    }
                }
            }
        }
        
        if movedAny {
            // Animasyon GameViewModel tarafından çağırılan SwiftUI framework'ü sayesinde tetiklenecek.
        }
    }


    // MARK: - Overdrive Powers
    
    @discardableResult
    func applyArchitectOverdrive(at center: GridPosition) -> [GameCell] {
        var clearedCells: [GameCell] = []
        for r in (center.row - 1)...(center.row + 1) {
            for c in (center.col - 1)...(center.col + 1) {
                if r >= 0, r < Self.size, c >= 0, c < Self.size {
                    let cell = grid[r][c]
                    if cell.isOccupied {
                        clearedCells.append(cell)
                        grid[r][c].state = .empty
                    }
                }
            }
        }
        grid = grid
        return clearedCells
    }

    // MARK: - Helpers
    func cell(at pos: GridPosition) -> GameCell { grid[pos.row][pos.col] }

    func allEmptyPositions() -> [GridPosition] {
        var result: [GridPosition] = []
        for r in 0..<Self.size {
            for c in 0..<Self.size {
                if grid[r][c].isEmpty { result.append(GridPosition(row: r, col: c)) }
            }
        }
        return result
    }
    
    func allOccupiedPositions() -> [GridPosition] {
        var result: [GridPosition] = []
        for r in 0..<Self.size {
            for c in 0..<Self.size {
                if grid[r][c].isOccupied { result.append(GridPosition(row: r, col: c)) }
            }
        }
        return result
    }

    func removeCell(at pos: GridPosition) {
        guard pos.row >= 0, pos.row < Self.size, pos.col >= 0, pos.col < Self.size else { return }
        grid[pos.row][pos.col].state = .empty
    }
    
    @discardableResult
    func removeCells(at positions: [GridPosition]) -> ClearResult {
        var cleared: [GameCell] = []
        var posList: [GridPosition] = []
        for pos in positions {
            guard pos.row >= 0, pos.row < Self.size, pos.col >= 0, pos.col < Self.size else { continue }
            let cell = grid[pos.row][pos.col]
            if cell.isOccupied {
                cleared.append(cell)
                posList.append(pos)
                grid[pos.row][pos.col].state = .empty
            }
        }
        grid = grid
        return ClearResult(clearedCells: cleared, clearedPositions: posList, rowsCleared: 0, colsCleared: 0, zonesCleared: 0)
    }
}

// MARK: - GridPosition
struct GridPosition: Hashable, Equatable {
    let row: Int
    let col: Int
}
