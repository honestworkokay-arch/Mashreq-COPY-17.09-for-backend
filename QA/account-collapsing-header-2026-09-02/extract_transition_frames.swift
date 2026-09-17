import AppKit
import AVFoundation
import Foundation

/// Извлекает частые кадры вокруг фактического жеста прокрутки,
/// чтобы отделить движение ScrollView от состояния закреплённого хедера.
let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    fputs("Usage: swift extract_transition_frames.swift <video> <output-directory>\n", stderr)
    exit(2)
}

let videoURL = URL(fileURLWithPath: arguments[1])
let outputURL = URL(fileURLWithPath: arguments[2], isDirectory: true)
try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

let generator = AVAssetImageGenerator(asset: AVURLAsset(url: videoURL))
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero

let firstSecond = 11.50
let lastSecond = 12.50
let step = 0.10
let frameCount = Int(((lastSecond - firstSecond) / step).rounded()) + 1

for index in 0..<frameCount {
    let seconds = firstSecond + Double(index) * step
    let time = CMTime(seconds: seconds, preferredTimescale: 600)

    do {
        let image = try generator.copyCGImage(at: time, actualTime: nil)
        let bitmap = NSBitmapImageRep(cgImage: image)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            continue
        }
        let fileName = String(format: "transition-%02d-%.2fs.png", index + 1, seconds)
        try data.write(to: outputURL.appendingPathComponent(fileName), options: .atomic)
    } catch {
        fputs("frame \(index + 1) failed: \(error)\n", stderr)
    }
}
