import Flutter
import UIKit
import AVFoundation

public class FlutterMidiProPlugin: NSObject, FlutterPlugin {
  private var audioEngine: AVAudioEngine!
  private var sampler: AVAudioUnitSampler!
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_midi_pro", binaryMessenger: registrar.messenger())
    let instance = FlutterMidiProPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "loadSoundfont":
        guard let args = call.arguments as? [String: Any],
            let sf2Path = args["path"] as? String else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for loading SF2", details: nil))
            return
        }
        loadSf2(sf2Path: sf2Path, result: result)
    case "selectInstrument":
        result(nil)
    case "playNote":
        guard let args = call.arguments as? [String: Any],
            let note = args["key"] as? UInt8,
            let velocity = args["velocity"] as? UInt8 else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for playing note", details: nil))
            return
        }
        playNote(note: note, velocity: velocity)
        result(nil)    
    case "stopNote":
        guard let args = call.arguments as? [String: Any],
            let note = args["key"] as? UInt8 else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments for stopping note", details: nil))
            return
        }
        stopNote(note: note)
        result(nil)  
    case "unloadSoundfont":
        result(nil)
    case "dispose":
        result(nil)
    default:
      result(FlutterMethodNotImplemented)
        break
    }
  }
  private func loadSf2(sf2Path: String, result: FlutterResult) {
      do {
          let url = URL(fileURLWithPath: sf2Path)
          sampler = AVAudioUnitSampler()
          audioEngine = AVAudioEngine()

          audioEngine.attach(sampler)
          audioEngine.connect(sampler, to: audioEngine.mainMixerNode, format: nil)

          try audioEngine.start()
          try sampler.loadSoundBankInstrument(at: url, program: 0, bankMSB: 0x79, bankLSB: 0x00) // Bank 0 is usually standard

          result(1)
      } catch {
          result(FlutterError(code: "LOAD_ERROR", message: "Failed to load SF2 file", details: error.localizedDescription))
      }
  }

    private func playNote(note: UInt8, velocity: UInt8) {
        sampler?.startNote(note, withVelocity: velocity, onChannel: 0)
    }

    private func stopNote(note: UInt8) {
        sampler?.stopNote(note, onChannel: 0)
    }  
}
