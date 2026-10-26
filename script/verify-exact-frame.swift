import Foundation
import AVFoundation
import AppKit
@main struct CheckSeek {
 static func main() async throws {
  let asset=AVURLAsset(url:URL(fileURLWithPath:CommandLine.arguments[1]))
  let generator=AVAssetImageGenerator(asset:asset)
  generator.appliesPreferredTrackTransform=true
  generator.requestedTimeToleranceBefore = .zero
  generator.requestedTimeToleranceAfter = .zero
  let frame=try await generator.image(at:CMTime(value:10411,timescale:30))
  try NSBitmapImageRep(cgImage:frame.image).representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"work/five-minute-fresh-seek-end.png"))
  print(frame.actualTime.seconds)
 }
}
