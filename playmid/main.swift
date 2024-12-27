//
//  playmid.swift
//  使用 mac 自带的音色播放一个 mid 文件
//  play .mid file with the system sound font resources of MacOS
//
//  Created by 张宇飞 on 2024/12/16.
//

import AVFoundation
import Foundation
import Progress

private func formatTime(_ seconds: TimeInterval) -> String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.minute, .second]
    formatter.unitsStyle = .positional
    formatter.zeroFormattingBehavior = .pad

    let formattedString = formatter.string(from: seconds) ?? "00:00"
    let milliseconds = Int((seconds.truncatingRemainder(dividingBy: 1)) * 1000)

    return "\(formattedString).\(String(format: "%03d", milliseconds))"
}

private func timeToTicks(_ secs: TimeInterval) -> Int {
    let ms = Int((secs.truncatingRemainder(dividingBy: 1)) * 1000)
    let s = Int(secs.rounded(.towardZero))
    return s * 1000 + ms
}

private func parseArgs() -> URL {
    let args = CommandLine.arguments
    if args.count != 2 {
        let p = URL(fileURLWithPath: args[0]).lastPathComponent
        print("Usage: \(p) <mid file path>")
        exit(-1)
    }

    return URL(fileURLWithPath: args[1])
}

private struct ProgressPlayerCursor: ProgressElementType {
    let player: AVMIDIPlayer

    init(player: AVMIDIPlayer) {
        self.player = player
    }

    public func value(_: ProgressBar) -> String {
        return formatTime(player.currentPosition)
    }
}

private func main() {
    if let player = try? AVMIDIPlayer(contentsOf: parseArgs(), soundBankURL: nil) {
        var running = true
        player.play {
            running = false
        }

        let totalTicks = timeToTicks(player.duration)
        let duration = formatTime(player.duration)
        var bar = ProgressBar(
            count: totalTicks,
            configuration: [
                ProgressPlayerCursor(player: player),
                ProgressBarLine(barLength: 60),
                ProgressString(string: duration),
            ])

        while running {
            let ticks = timeToTicks(player.currentPosition)
            bar.setValue(ticks)
            usleep(500_000)
        }
        bar.setValue(totalTicks)
    }
}

main()
