import AppKit
import AVFoundation
import Foundation

/// Нативный экстрактор ключевых кадров: не зависит от ffmpeg и сохраняет
/// ориентацию видео через appliesPreferredTrackTransform.
let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    fputs("Usage: swift extract_video_frames.swift <video> <output-directory>\n", stderr)
    exit(2)
}

let videoURL = URL(fileURLWithPath: arguments[1])
let outputURL = URL(fileURLWithPath: arguments[2], isDirectory: true)
try FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

let asset = AVURLAsset(url: videoURL)
let duration = CMTimeGetSeconds(asset.duration)
let videoTrack = asset.tracks(withMediaType: .video).first
let frameRate = videoTrack?.nominalFrameRate ?? 0
let naturalSize = videoTrack?.naturalSize ?? .zero
let transform = videoTrack?.preferredTransform ?? .identity
let transformedSize = naturalSize.applying(transform)

print("duration=\(String(format: "%.3f", duration))")
print("fps=\(String(format: "%.3f", frameRate))")
print("encodedSize=\(Int(naturalSize.width))x\(Int(naturalSize.height))")
print("displaySize=\(Int(abs(transformedSize.width)))x\(Int(abs(transformedSize.height)))")

let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero

// 25 кадров дают начало, конец и 23 равномерные промежуточные фазы.
let sampleCount = 25
for index in 0..<sampleCount {
    let progress = Double(index) / Double(sampleCount - 1)
    let seconds = max(0, duration * progress - (index == sampleCount - 1 ? 0.001 : 0))
    let time = CMTime(seconds: seconds, preferredTimescale: 600)

    do {
        let image = try generator.copyCGImage(at: time, actualTime: nil)
        let bitmap = NSBitmapImageRep(cgImage: image)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            continue
        }
        let fileName = String(format: "frame-%03d-%.3fs.png", index + 1, seconds)
        try data.write(to: outputURL.appendingPathComponent(fileName), options: .atomic)
    } catch {
        fputs("frame \(index + 1) failed: \(error)\n", stderr)
    }
}
