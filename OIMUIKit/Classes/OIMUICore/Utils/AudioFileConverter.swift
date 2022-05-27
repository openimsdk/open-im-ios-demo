





import Foundation
import AVFoundation

class AudioFileConverter {
    
    static func convertAudioToM4a(inputUrlString: String, outputUrlString: String, completion: ((Error?) -> Void)) {
        do {
            let manager = FileManager.default
            if manager.fileExists(atPath: outputUrlString) {
                try? manager.removeItem(atPath: outputUrlString)
            }
            let originURL = URL.init(fileURLWithPath: inputUrlString)
            let destURL = URL.init(fileURLWithPath: outputUrlString)
            
            let songAsset: AVURLAsset = AVURLAsset.init(url: originURL)
            let assetReader: AVAssetReader = try AVAssetReader.init(asset: songAsset)
            let assetReaderOutput: AVAssetReaderOutput = AVAssetReaderAudioMixOutput.init(audioTracks: songAsset.tracks, audioSettings: nil)
            
            if assetReader.canAdd(assetReaderOutput) {
                assetReader.add(assetReaderOutput)
            } else {
                completion(ConvertError.init(reason: "can not add reader output"))
                debugPrint("can not add reader output")
                return
            }
            
            let assetWriter: AVAssetWriter = try AVAssetWriter.init(outputURL: destURL, fileType: AVFileType.m4a)
            
            var channelLayout = AudioChannelLayout()
            memset(&channelLayout, 0, MemoryLayout<AudioChannelLayout>.size);
            channelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
            
            let outputSettings: [String: Any] = [
                AVChannelLayoutKey: NSData(bytes:&channelLayout, length:  MemoryLayout.size(ofValue: AudioChannelLayout.self)),
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2
            ]
            let assetWriterInput: AVAssetWriterInput = AVAssetWriterInput.init(mediaType: AVMediaType.audio, outputSettings: outputSettings)
            if assetWriter.canAdd(assetWriterInput) {
                assetWriter.add(assetWriterInput)
            } else {
                debugPrint("can not add writer input")
                completion(ConvertError.init(reason: "can not add writer input"))
                return
            }
            assetWriterInput.expectsMediaDataInRealTime = false
            assetWriter.startWriting()
            assetReader.startReading()
            
            let soundTrack: AVAssetTrack = songAsset.tracks[0]
            let startTime = CMTime.init(value: 0, timescale: soundTrack.naturalTimeScale)
            assetWriter.startSession(atSourceTime: startTime)
            
            let mediaInputQueue = DispatchQueue.init(label: "MediaInputQueue")
            var convertedByteCount: Int = 0
            assetWriterInput.requestMediaDataWhenReady(on: mediaInputQueue) {
                while assetWriterInput.isReadyForMoreMediaData {
                    let nextBuffer = assetReaderOutput.copyNextSampleBuffer()
                    if let nextBuffer = nextBuffer {
                        assetWriterInput.append(nextBuffer)
                        convertedByteCount += CMSampleBufferGetTotalSampleSize(nextBuffer)
                    } else {
                        assetWriterInput.markAsFinished()
                        assetWriter.finishWriting {
                            
                        }
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

