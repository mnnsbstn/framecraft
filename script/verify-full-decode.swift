import Foundation
import AVFoundation
import AppKit
@main struct DecodeExport {
 static func main() async throws {
  let asset=AVURLAsset(url:URL(fileURLWithPath:CommandLine.arguments[1]))
  let tracks=try await asset.loadTracks(withMediaType:.video)
  let reader=try AVAssetReader(asset:asset)
  let output=AVAssetReaderTrackOutput(track:tracks[0],outputSettings:[kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA])
  output.alwaysCopiesSampleData=false;reader.add(output)
  guard reader.startReading() else {throw reader.error!}
  let context=CIContext();var count=0;var saved=false
  while let sample=output.copyNextSampleBuffer() {
   count+=1
   let t=CMSampleBufferGetPresentationTimeStamp(sample).seconds
   if t>=347.03 && !saved,let pixel=CMSampleBufferGetImageBuffer(sample) {
    let image=CIImage(cvPixelBuffer:pixel)
    let cg=context.createCGImage(image,from:image.extent)!
    try NSBitmapImageRep(cgImage:cg).representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:"work/five-minute-sequential-end.png"))
    print("Saved sequential frame at \(t)");saved=true
   }
  }
  guard reader.status == .completed else {throw reader.error!}
  print("Fully decoded \(count) video frames without reader error")
 }
}
