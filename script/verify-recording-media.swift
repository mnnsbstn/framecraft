import Foundation
import AVFoundation
import AppKit

@main struct VerifyLongMedia {
 static func main() async throws {
  var reports: [[String: Any]] = []
  for path in CommandLine.arguments.dropFirst() {
   let url = URL(fileURLWithPath: path), asset = AVURLAsset(url: URL(fileURLWithPath:path))
   let duration = try await asset.load(.duration).seconds
   let tracks = try await asset.loadTracks(withMediaType: .video)
   guard let track = tracks.first else { fatalError("Missing video") }
   let size = try await track.load(.naturalSize)
   let fps = try await track.load(.nominalFrameRate)
   let audio = try await asset.loadTracks(withMediaType: .audio)
   let reader = try AVAssetReader(asset: asset)
   let output = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
   reader.add(output); guard reader.startReading() else { throw reader.error! }
   var count = 0, times: [Double] = []
   while let sample = output.copyNextSampleBuffer() { count += 1; times.append(CMSampleBufferGetPresentationTimeStamp(sample).seconds) }
   guard reader.status == .completed else { throw reader.error! }
   times.sort()
   let gaps = zip(times, times.dropFirst()).map { $1 - $0 }
   let generator = AVAssetImageGenerator(asset: asset)
   generator.appliesPreferredTrackTransform = true
   var decoded: [Double] = []
   for (index, second) in [1.0, duration/2, max(0,duration-1)].enumerated() {
    let frame = try await generator.image(at: CMTime(seconds:second,preferredTimescale:600))
    decoded.append(frame.actualTime.seconds)
    let png = NSBitmapImageRep(cgImage:frame.image).representation(using:.png,properties:[:])!
    let name = url.lastPathComponent == "source.mp4" ? "long-source" : "long-export"
    try png.write(to:URL(fileURLWithPath:"work/\(name)-\(index).png"))
   }
   reports.append(["file":url.lastPathComponent,"duration_seconds":duration,"dimensions":[Int(size.width),Int(size.height)],"nominal_fps":fps,"audio_tracks":audio.count,"compressed_video_samples":count,"effective_samples_per_second":Double(count)/duration,"maximum_sorted_pts_gap_seconds":gaps.max() ?? 0,"decoded_sample_times":decoded,"full_frame_decode":false])
  }
  let json = try JSONSerialization.data(withJSONObject:reports,options:[.prettyPrinted,.sortedKeys])
  try json.write(to:URL(fileURLWithPath:"work/long-media-verification.json"))
  print(String(data:json,encoding:.utf8)!)
 }
}
