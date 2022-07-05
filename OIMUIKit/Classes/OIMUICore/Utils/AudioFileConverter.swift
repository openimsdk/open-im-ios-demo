
import AVFoundation
import Foundation

class AudioFileConverter {
    // 转.wav为.m4a格式
    static func convertAudioToM4a(inputUrlString: String, outputUrlString: String, completion: (Error?) -> Void) {
        do {
            let manager = FileManager.default
            if manager.fileExists(atPath: outputUrlString) {
                try? manager.removeItem(atPath: outputUrlString)
            }
            let originURL = URL(fileURLWithPath: inputUrlString)
            let destURL = URL(fileURLWithPath: outputUrlString)

            let songAsset: AVURLAsset = .init(url: originURL)
            let assetReader: AVAssetReader = try AVAssetReader(asset: songAsset)
            let assetReaderOutput: AVAssetReaderOutput = AVAssetReaderAudioMixOutput(audioTracks: songAsset.tracks, audioSettings: nil)
            // 读取原始文件
            if assetReader.canAdd(assetReaderOutput) {
                assetReader.add(assetReaderOutput)
            } else {
                completion(ConvertError(reason: "can not add reader output"))
                debugPrint("can not add reader output")
                return
            }
            // 这里定义了输出格式
            let assetWriter: AVAssetWriter = try AVAssetWriter(outputURL: destURL, fileType: AVFileType.m4a)

            var channelLayout = AudioChannelLayout()
            memset(&channelLayout, 0, MemoryLayout<AudioChannelLayout>.size)
            channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo

            let outputSettings: [String: Any] = [
                AVChannelLayoutKey: NSData(bytes: &channelLayout, length: MemoryLayout.size(ofValue: AudioChannelLayout.self)),
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
            ]
            let assetWriterInput: AVAssetWriterInput = .init(mediaType: AVMediaType.audio, outputSettings: outputSettings)
            if assetWriter.canAdd(assetWriterInput) {
                assetWriter.add(assetWriterInput)
            } else {
                debugPrint("can not add writer input")
                completion(ConvertError(reason: "can not add writer input"))
                return
            }
            assetWriterInput.expectsMediaDataInRealTime = false
            assetWriter.startWriting()
            assetReader.startReading()

            let soundTrack: AVAssetTrack = songAsset.tracks[0]
            let startTime = CMTime(value: 0, timescale: soundTrack.naturalTimeScale)
            assetWriter.startSession(atSourceTime: startTime)

            let mediaInputQueue = DispatchQueue(label: "MediaInputQueue")
            var convertedByteCount: Int = 0
            assetWriterInput.requestMediaDataWhenReady(on: mediaInputQueue) {
                while assetWriterInput.isReadyForMoreMediaData {
                    let nextBuffer = assetReaderOutput.copyNextSampleBuffer()
                    if let nextBuffer = nextBuffer {
                        assetWriterInput.append(nextBuffer)
                        convertedByteCount += CMSampleBufferGetTotalSampleSize(nextBuffer)
                    } else {
                        assetWriterInput.markAsFinished()
                        assetWriter.finishWriting {}
                        assetReader.cancelReading()
                        break
                    }
                }
            }

            if manager.fileExists(atPath: inputUrlString) {
                try manager.removeItem(atPath: inputUrlString)
            }
            completion(nil)
        } catch {
            completion(error)
        }
    }
}

struct ConvertError: Error {
    let reason: String
}
