//
//  TetrisGame.swift
//  TetrisWatch (watchOS)
//
//  Created by Example on 2025/03/09.
//
//  이 파일은 '테트리스 게임 로직'을 담당하는 ObservableObject 클래스입니다.
//  - 보드(2차원 배열), 현재 테트리미노, 충돌 검사, 줄 제거, 게임 오버 판정 등
//  - SwiftUI 뷰에서 @ObservedObject로 감시하여 상태 변화를 UI에 반영
//

import SwiftUI
import Combine


/// 보드의 각 칸 상태
enum CellState: Equatable {
    case empty              // 빈 칸
    case filled(Color)      // 어떤 색상으로 채워진 칸
}


/// 테트리미노(블록) 정보를 담은 구조체
/// - shape: 2차원 Int 배열 (0: 빈칸, 1: 블록 존재)
/// - x, y : 보드 상에서 현재 블록의 위치(왼쪽 상단 (0,0) 기준)
struct Tetromino {
    var shape: [[Int]]
    var x: Int
    var y: Int
    var color: Color
}

/// 테트리스 전체 게임 로직을 관리하는 ObservableObject
class TetrisGame: ObservableObject {
    
    // MARK: - 게임 설정값
    let BOARD_HEIGHT = 17
    let BOARD_WIDTH = 10
    
    // MARK: - Published 프로퍼티 (UI가 관찰)
    /// 2차원 보드 배열 (0: 빈칸, 1: 블록이 있는 칸)
    @Published var board: [[CellState]]
    /// 현재 떨어지고 있는 테트리미노
    @Published var currentTetromino: Tetromino
    /// 게임 오버 여부
    @Published var gameOver: Bool = false
    
    // 1초 간격으로 블록이 한 칸씩 내려오도록 하는 타이머
    private var dropCancellable: AnyCancellable?
    
    // MARK: - 이니셜라이저
    init() {
        // 1) 빈 보드를 생성 (BOARD_HEIGHT x BOARD_WIDTH)
        board = Array(
            repeating: Array(repeating: CellState.empty, count: BOARD_WIDTH),
            count: BOARD_HEIGHT
        )
        
        // 2) 새로운 랜덤 테트리미노를 생성
        currentTetromino = Self.createRandomTetromino(boardWidth: BOARD_WIDTH)
        
        // 3) 일정 간격(1초)으로 자동으로 한 칸씩 아래로 이동
        dropCancellable = Timer.publish(every: 0.7, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.moveTetromino(dy: 1)
            }
    }
    
    deinit {
        // TetrisGame 객체가 해제될 때 타이머 해제
        dropCancellable?.cancel()
    }
    
    
    /// 보드 중앙에 새 테트리미노를 랜덤 생성
    static func createRandomTetromino(boardWidth: Int) -> Tetromino {
        let allTypes = Array(TetrominoData.allShapes.keys)
        let randType = allTypes.randomElement() ?? "I"
        let shapeInfo = TetrominoData.allShapes[randType]!
        
        // x 좌표를 가운데쯤으로 설정
        let startX = max(0, (boardWidth - shapeInfo.shape[0].count) / 2)
        
        return Tetromino(
            shape: shapeInfo.shape,
            x: startX,
            y: 0,
            color: shapeInfo.color
        )
    }
    
    // MARK: - 블록 이동
    /// dx: 좌우, dy: 아래쪽
    func moveTetromino(dx: Int = 0, dy: Int = 0) {
        guard !gameOver else { return }
        
        var moved = currentTetromino
        moved.x += dx
        moved.y += dy
        
        // 충돌 검사
        if !checkCollision(tetromino: moved) {
            currentTetromino = moved
        } else {
            // 아래로 이동하다 충돌 시 => 블록 고정
            if dy > 0 {
                placeTetromino()
            }
        }
    }
    
    // MARK: - 블록 회전
    func rotateTetromino() {
        guard !gameOver else { return }
        
        var rotated = currentTetromino
        rotated.shape = rotateMatrix(rotated.shape)
        
        if !checkCollision(tetromino: rotated) {
            currentTetromino = rotated
        }
    }
    
    // MARK: - 충돌 검사
    private func checkCollision(tetromino: Tetromino) -> Bool {
        for row in 0..<tetromino.shape.count {
            for col in 0..<tetromino.shape[row].count {
                if tetromino.shape[row][col] != 0 {
                    let testX = tetromino.x + col
                    let testY = tetromino.y + row
                    // 보드 범위 벗어나면 충돌
                    if testX < 0 || testX >= BOARD_WIDTH || testY >= BOARD_HEIGHT {
                        return true
                    }
                    // 보드 내부라도 이미 블록이 있으면 충돌
                    if testY >= 0 && board[testY][testX] != .empty {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    // MARK: - 블록 고정 & 줄 제거
    private func placeTetromino() {
        var newBoard = board
        let shape = currentTetromino.shape
        let x = currentTetromino.x
        let y = currentTetromino.y
        let blockColor = currentTetromino.color

        
        // 1) 현재 테트리미노를 보드에 반영
        for row in 0..<shape.count {
            for col in 0..<shape[row].count {
                if shape[row][col] != 0 {
                    let boardX = x + col
                    let boardY = y + row
                    if boardY >= 0 {
                        newBoard[boardY][boardX] = .filled(blockColor)
                    }
                }
            }
        }
        
        // 2) 가득 찬 줄 제거 (0이 하나도 없으면 제거)
        let filtered = newBoard.filter { rowArray in
            rowArray.contains(where: {
                if case .empty = $0 { return true}
                return false
            })
        }
        let linesCleared = BOARD_HEIGHT - filtered.count
        
        // 줄이 지워진 만큼 위에서 새로운 빈 행을 추가
        if linesCleared > 0 {
            let emptyRows = Array(
                repeating: Array(
                    repeating: CellState.empty,
                    count: BOARD_WIDTH
                ),
                count: linesCleared
            )
            newBoard = emptyRows + filtered
        }
        
        // 3) 보드 갱신
        board = newBoard
        
        // 4) 새로운 테트리미노 생성
        let newTetro = Self.createRandomTetromino(boardWidth: BOARD_WIDTH)
        // 5) 생성 즉시 충돌이면 -> 게임 오버
        if checkCollision(tetromino: newTetro) {
            gameOver = true
        } else {
            currentTetromino = newTetro
        }
    }
    
        
    
    // MARK: - 행렬 회전
    private func rotateMatrix(_ matrix: [[Int]]) -> [[Int]] {
        let N = matrix.count
        guard N > 0 else { return matrix }
        
        var rotated = Array(
            repeating: Array(repeating: 0, count: N),
            count: N
        )
        
        for y in 0..<N {
            for x in 0..<N {
                rotated[x][N - y - 1] = matrix[y][x]
            }
        }
        return rotated
    }
    
    // MARK: - 보드 + 블록 병합 (UI 표시용)
    /// UI에서 2차원 배열을 그릴 때 사용
    func mergedBoard() -> [[CellState]] {
        var tempBoard = board
        let shape = currentTetromino.shape
        let x = currentTetromino.x
        let y = currentTetromino.y
        let blockColor = currentTetromino.color
        
        for row in 0..<shape.count {
            for col in 0..<shape[row].count {
                if shape[row][col] != 0 {
                    let boardY = y + row
                    let boardX = x + col
                    if boardY >= 0 && boardY < BOARD_HEIGHT &&
                        boardX >= 0 && boardX < BOARD_WIDTH {
                        tempBoard[boardY][boardX] = .filled(blockColor)
                    }
                }
            }
        }
        return tempBoard
    }
}
