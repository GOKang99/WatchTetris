//
//  TetrisWatchView.swift
//  TetrisWatch (watchOS)
//
//  Created by Example on 2025/03/09.
//
//  - 디지털 크라운과 화면 터치(탭)으로 테트리스 블록을 제어하는 SwiftUI View
//  - .digitalCrownRotation => 블록 좌우 이동
//  - .onTapGesture => 블록 회전
//  - TetrisGame (로직) 객체를 @ObservedObject로 관찰
//
import SwiftUI
import WatchKit  // 디지털 크라운 사용 등에 필요

struct TetrisWatchView: View {
    
    @ObservedObject var game = TetrisGame()
    
    @State private var crownValue: Double = 0.0
    @State private var previousCrownValue: Double = 0.0
    @FocusState private var isCrownFocused: Bool
    
    var body: some View {
        ZStack {
            VStack(spacing: 4) {
                HStack {
                    Text("Score: \(game.score)")
                        .font(.system(size: 12))

                }
                
                VStack(spacing: 2) {
                    Text("Next")
                        .font(.system(size: 10))
                    let nextShape = game.nextTetromino.shape
                    ForEach(0..<nextShape.count, id: \.self) { row in
                        HStack(spacing: 1) {
                            ForEach(0..<nextShape[row].count, id: \.self) { col in
                                Rectangle()
                                    .foregroundColor(
                                        nextShape[row][col] == 1
                                        ? game.nextTetromino.color
                                        : Color.clear
                                    )
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                }
                .padding(.bottom, 4)
                
                // 보드 + 현재 블록을 합쳐 만든 2차원 배열
                let merged = game.mergedBoard()
                
                // 17행 x 10열 보드
                
                VStack(spacing: 1)  {
                    ForEach(0..<merged.count, id: \.self) { rowIndex in
                        HStack(spacing: 1) {
                            ForEach(0..<merged[rowIndex].count, id: \.self) { colIndex in
                                let cellState = merged[rowIndex][colIndex]
                                Rectangle()
                                    .foregroundColor({
                                        switch cellState {
                                        case .empty:
                                            return .gray
                                        case .filled(let color):
                                            return color
                                        }
                                    }())
                                    .frame(width: 12, height: 12)
                            }
                        }
                    }
                }
            }
            // 디지털 크라운(WatchKit) 연동
            .focusable(true)
            .digitalCrownRotation(
                $crownValue,
                from: -100.0,
                through: 100.0,
                by: 1.0,
                sensitivity: .low,
                isHapticFeedbackEnabled: true
            )
            .focused($isCrownFocused)
            .onChange(of: crownValue) { newValue in
                let delta = Int(newValue - previousCrownValue)
                if delta != 0 {
                    game.moveTetromino(dx: delta > 0 ? 1 : -1)
                    previousCrownValue = newValue
                }
            }
            .onTapGesture {
                game.rotateTetromino()
            }
            .onAppear {
                isCrownFocused = true
            }
            
            // GAME OVER 화면 중앙 표시
            if game.gameOver {
                VStack {
                    Text("GAME OVER")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                    
                    Button("Restart") {
                        game.restartGame()
                    }
                    .padding(.bottom, 4)
                }
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct TetrisWatchView_Previews: PreviewProvider {
    static var previews: some View {
        TetrisWatchView()
    }
}
