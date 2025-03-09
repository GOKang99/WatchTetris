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
import WatchKit  // ✅ 디지털 크라운 사용 등에 필요

/// SwiftUI View: Apple Watch에서 테트리스를 플레이
/// - 크라운 회전: 좌우 이동
/// - 화면 탭: 블록 회전
struct TetrisWatchView: View {
    
    // 게임 로직이 담긴 TetrisGame
    @ObservedObject var game = TetrisGame()
    
    // 디지털 크라운 회전을 감지할 값
    @State private var crownValue: Double = 0.0
    // 직전 crownValue(크라운 값)를 저장해, 이동 방향/크기 계산
    @State private var previousCrownValue: Double = 0.0
    
    // 크라운 회전을 사용하기 위해 초점이 필요
    @FocusState private var isCrownFocused: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            
            // 게임 오버 출력
            if game.gameOver {
                Text("GAME OVER")
                    .foregroundColor(.red)
                    .padding()
            } else {
                Text("TETRIS on Apple Watch")
                    .font(.headline)
                    .padding(.top, 4)
            }
            
            // 보드 + 현재 블록을 합쳐 만든 2차원 배열
            let merged = game.mergedBoard()
            
            // 20행 x 10열 보드
            ForEach(0..<merged.count, id: \.self) { rowIndex in
                HStack(spacing: 1) {
                    ForEach(0..<merged[rowIndex].count, id: \.self) { colIndex in
                        Rectangle()
                            // 1이면 블록, 0이면 빈 칸
                            .foregroundColor(merged[rowIndex][colIndex] == 1 ? .pink : .gray)
                            .frame(width: 10, height: 10)
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
            // crownValue의 변화량(정수 단위)을 측정
            let delta = Int(newValue - previousCrownValue)
            if delta != 0 {
                // delta > 0 ⇒ 오른쪽 이동, delta < 0 ⇒ 왼쪽 이동
                game.moveTetromino(dx: delta > 0 ? 1 : -1)
                previousCrownValue = newValue
            }
        }
        // 화면 탭 → 블록 회전
        .onTapGesture {
            game.rotateTetromino()
        }
        // 최초 진입 시 포커스를 얻어 크라운 제어 가능하도록
        .onAppear {
            isCrownFocused = true
        }
    }
}
