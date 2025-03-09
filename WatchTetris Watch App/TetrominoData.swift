import SwiftUI

struct TetrominoData {
    static let allShapes: [String: (shape: [[Int]], color: Color)] = [
            
            "I": (
                shape: [
                    [0, 0, 0, 0],
                    [1, 1, 1, 1],
                    [0, 0, 0, 0],
                    [0, 0, 0, 0],
                ],
                color: .red
            ),
            
            "O": (
                shape: [
                    [1, 1],
                    [1, 1],
                ],
                color: .yellow
            ),
            
            "T": (
                shape: [
                    [0, 1, 0],
                    [1, 1, 1],
                    [0, 0, 0],
                ],
                color: .green
            ),
            
            "S": (
                shape: [
                    [0, 1, 1],
                    [1, 1, 0],
                    [0, 0, 0],
                ],
                color: .blue
            ),
            
            "Z": (
                shape: [
                    [1, 1, 0],
                    [0, 1, 1],
                    [0, 0, 0],
                ],
                color: .cyan // SwiftUI에서 하늘색
            ),
            
            "J": (
                shape: [
                    [1, 0, 0],
                    [1, 1, 1],
                    [0, 0, 0],
                ],
                color: .pink
            ),
            
            "L": (
                shape: [
                    [0, 0, 1],
                    [1, 1, 1],
                    [0, 0, 0],
                ],
                color: .purple
            ),
        ]
}
