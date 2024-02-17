import Foundation
import CoreMediaIO
import IOKit.audio
import os.log
import AppKit

// MARK: -

let customExtensionPropertyTest: CMIOExtensionProperty = CMIOExtensionProperty(rawValue: "4cc_just_glob_0000")
let kFrameRate: Int = 120

class RecordCameraExtensionDeviceSource: NSObject, CMIOExtensionDeviceSource {
	
	private(set) var device: CMIOExtensionDevice!
	
	private var _streamSource: RecordCameraExtensionStreamSource!
    public var _streamSink: RecordCameraExtensionStreamSink!
    private var _streamingCounter: UInt32 = 0
    private var _streamingSinkCounter: UInt32 = 0
    
    let kWhiteStripeHeight: Int = 10
    
    var lastMessage = ""
    
    var textFontAttributes: [NSAttributedString.Key : Any]!
    
    let textColor = NSColor.white
    let fontSize = 24.0
    var textFont: NSFont!
    
    func myStreamingCounter() -> String {
        return "sc=\(_streamingCounter)"
    }
	
	private var _timer: DispatchSourceTimer?
	
	private let _timerQueue = DispatchQueue(label: "timerQueue", qos: .userInteractive, attributes: [], autoreleaseFrequency: .workItem, target: .global(qos: .userInteractive))
	
	private var _videoDescription: CMFormatDescription!
	
	private var _bufferPool: CVPixelBufferPool!
	
	private var _bufferAuxAttributes: NSDictionary!
	
	private var _whiteStripeStartRow: UInt32 = 0
	
	private var _whiteStripeIsAscending: Bool = false
    
    private var client: CMIOExtensionClient!
    
    var stupidCount = 0
	
	init(localizedName: String) {
		
		super.init()
        textFont = NSFont.systemFont(ofSize: fontSize)
        textFontAttributes = [
                    NSAttributedString.Key.font: textFont,
                    NSAttributedString.Key.foregroundColor: textColor,
                    NSAttributedString.Key.paragraphStyle: NSTextAlignment.center
                ]
		let deviceID = UUID(uuidString: "4B8051B1-26DF-4958-8354-F01DCB1DB02D")! // replace this with your device UUID
		self.device = CMIOExtensionDevice(localizedName: localizedName, deviceID: deviceID, legacyDeviceID: nil, source: self)
		
		let dims = CMVideoDimensions(width: 3456, height: 2234)
		CMVideoFormatDescriptionCreate(allocator: kCFAllocatorDefault, codecType:  kCVPixelFormatType_32BGRA, width: dims.width, height: dims.height, extensions: nil, formatDescriptionOut: &_videoDescription)
		
		let pixelBufferAttributes: NSDictionary = [
			kCVPixelBufferWidthKey: dims.width,
			kCVPixelBufferHeightKey: dims.height,
			kCVPixelBufferPixelFormatTypeKey: _videoDescription.mediaSubType,
			kCVPixelBufferIOSurfacePropertiesKey: [:] as NSDictionary
		]
		CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, pixelBufferAttributes, &_bufferPool)
		
		let videoStreamFormat = CMIOExtensionStreamFormat.init(formatDescription: _videoDescription, maxFrameDuration: CMTime(value: 1, timescale: Int32(kFrameRate)), minFrameDuration: CMTime(value: 1, timescale: Int32(kFrameRate)), validFrameDurations: nil)
		_bufferAuxAttributes = [kCVPixelBufferPoolAllocationThresholdKey: 5]
		
		let videoID = UUID(uuidString: "5A36AE62-37CF-4D89-AF81-F9E03FC15907")! // replace this with your video UUID
		_streamSource = RecordCameraExtensionStreamSource(localizedName: "RecordCameraExtension.Video", streamID: videoID, streamFormat: videoStreamFormat, device: device)
        let videoSinkID = UUID(uuidString: "26CCE162-2DB0-4C71-A92C-4F81437BD883")!
        _streamSink = RecordCameraExtensionStreamSink(localizedName: "RecordCameraExtension.Video.Sink", streamID: videoSinkID, streamFormat: videoStreamFormat, device: device)
		do {
			try device.addStream(_streamSource.stream)
            try device.addStream(_streamSink.stream)
		} catch let error {
			fatalError("Failed to add stream: \(error.localizedDescription)")
		}
	}
	
	var availableProperties: Set<CMIOExtensionProperty> {
		
		return [.deviceTransportType, .deviceModel]
	}
	
	func deviceProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionDeviceProperties {
		
		let deviceProperties = CMIOExtensionDeviceProperties(dictionary: [:])
		if properties.contains(.deviceTransportType) {
			deviceProperties.transportType = kIOAudioDeviceTransportTypeVirtual
		}
		if properties.contains(.deviceModel) {
			deviceProperties.model = "RecordCameraExtension Model"
		}
		
		return deviceProperties
	}
	
	func setDeviceProperties(_ deviceProperties: CMIOExtensionDeviceProperties) throws {
		
		// Handle settable properties here.
	}
	
	func startStreaming() {
		
		guard let _ = _bufferPool else {
			return
		}
		
		_streamingCounter += 1
		
		_timer = DispatchSource.makeTimerSource(flags: .strict, queue: _timerQueue)
		_timer!.schedule(deadline: .now(), repeating: 1.0 / Double(kFrameRate), leeway: .seconds(0))
		
		_timer!.setEventHandler {
            if self.sinkStarted {
                guard let client = self.client else { return }
                self._streamSink.stream.consumeSampleBuffer(from: client) { sbuf, seq, discontinuity, hasMoreSampleBuffers, err in
                    if sbuf != nil {
                        if let surface = CVPixelBufferGetIOSurface(sbuf?.imageBuffer)?.takeUnretainedValue() {
                            IOSurfaceLock(surface, [], nil)
                        }
                        self.lastTimingInfo.presentationTimeStamp = CMClockGetTime(CMClockGetHostTimeClock())
                        let output: CMIOExtensionScheduledOutput = CMIOExtensionScheduledOutput(sequenceNumber: seq, hostTimeInNanoseconds: UInt64(self.lastTimingInfo.presentationTimeStamp.seconds * Double(NSEC_PER_SEC)))
                        if self._streamingCounter > 0 {
                            self._streamSource.stream.send(sbuf!, discontinuity: [], hostTimeInNanoseconds: UInt64(sbuf!.presentationTimeStamp.seconds * Double(NSEC_PER_SEC)))
                        }
                        self._streamSink.stream.notifyScheduledOutputChanged(output)
                        if let surface = CVPixelBufferGetIOSurface(sbuf?.imageBuffer)?.takeUnretainedValue() {
                            IOSurfaceUnlock(surface, [], nil)
                        }
                        os_log("queue fullness is \(client)")
                    }
                    if err != nil {
                        os_log("LOGGING AN ERROR POOPY")
                        os_log("\(err!.localizedDescription)")
                    }
                }
            } else {
                
                var err: OSStatus = 0
                let now = CMClockGetTime(CMClockGetHostTimeClock())
                
                var pixelBuffer: CVPixelBuffer?
                err = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(kCFAllocatorDefault, self._bufferPool, self._bufferAuxAttributes, &pixelBuffer)
                if err != 0 {
                    os_log(.error, "out of pixel buffers \(err)")
                }
                
                if let pixelBuffer = pixelBuffer {
                    
                    CVPixelBufferLockBaseAddress(pixelBuffer, [])
                    
                    var bufferPtr = CVPixelBufferGetBaseAddress(pixelBuffer)!
                    let width = CVPixelBufferGetWidth(pixelBuffer)
                    let height = CVPixelBufferGetHeight(pixelBuffer)
                    let rowBytes = CVPixelBufferGetBytesPerRow(pixelBuffer)
                    memset(bufferPtr, 0, rowBytes * height)
                    
                    let whiteStripeStartRow = self._whiteStripeStartRow
                    if self._whiteStripeIsAscending {
                        self._whiteStripeStartRow = whiteStripeStartRow - 1
                        self._whiteStripeIsAscending = self._whiteStripeStartRow > 0
                    }
                    else {
                        self._whiteStripeStartRow = whiteStripeStartRow + 1
                        self._whiteStripeIsAscending = self._whiteStripeStartRow >= (height - self.kWhiteStripeHeight)
                    }
                    bufferPtr += rowBytes * Int(whiteStripeStartRow)
                    for _ in 0..<self.kWhiteStripeHeight {
                        for _ in 0..<width {
                            var white: UInt32 = 0xFFFFFFFF
                            memcpy(bufferPtr, &white, MemoryLayout.size(ofValue: white))
                            bufferPtr += MemoryLayout.size(ofValue: white)
                        }
                    }
                    
                    CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
                    
                    var sbuf: CMSampleBuffer!
                    var timingInfo = CMSampleTimingInfo()
                    timingInfo.presentationTimeStamp = CMClockGetTime(CMClockGetHostTimeClock())
                    err = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, dataReady: true, makeDataReadyCallback: nil, refcon: nil, formatDescription: self._videoDescription, sampleTiming: &timingInfo, sampleBufferOut: &sbuf)
                    if err == 0 {
                        self._streamSource.stream.send(sbuf, discontinuity: [], hostTimeInNanoseconds: UInt64(timingInfo.presentationTimeStamp.seconds * Double(NSEC_PER_SEC)))
                    }
                    os_log(.info, "video time \(timingInfo.presentationTimeStamp.seconds) now \(now.seconds) err \(err)")
                }
            }
		}
		
		_timer!.setCancelHandler {
		}
		
		_timer!.resume()
	}
	
	func stopStreaming() {
		
		if _streamingCounter > 1 {
			_streamingCounter -= 1
		}
		else {
			_streamingCounter = 0
			if let timer = _timer {
				timer.cancel()
				_timer = nil
			}
		}
	}
    
    var sinkStarted = false
    var lastTimingInfo = CMSampleTimingInfo()
    func consumeBuffer(_ client: CMIOExtensionClient) {
        if sinkStarted == false {
            return
        }
        self._streamSink.stream.consumeSampleBuffer(from: client) { sbuf, seq, discontinuity, hasMoreSampleBuffers, err in
            if sbuf != nil {
                if let surface = CVPixelBufferGetIOSurface(sbuf?.imageBuffer)?.takeUnretainedValue() {
                    IOSurfaceLock(surface, [], nil)
                }
                self.lastTimingInfo.presentationTimeStamp = CMClockGetTime(CMClockGetHostTimeClock())
                let output: CMIOExtensionScheduledOutput = CMIOExtensionScheduledOutput(sequenceNumber: seq, hostTimeInNanoseconds: UInt64(self.lastTimingInfo.presentationTimeStamp.seconds * Double(NSEC_PER_SEC)))
                if self._streamingCounter > 0 {
                    self._streamSource.stream.send(sbuf!, discontinuity: [], hostTimeInNanoseconds: UInt64(sbuf!.presentationTimeStamp.seconds * Double(NSEC_PER_SEC)))
                }
                self._streamSink.stream.notifyScheduledOutputChanged(output)
                if let surface = CVPixelBufferGetIOSurface(sbuf?.imageBuffer)?.takeUnretainedValue() {
                    IOSurfaceUnlock(surface, [], nil)
                }
            }
            if err != nil {
                os_log("LOGGING AN ERROR POOPY")
                os_log("\(err!.localizedDescription)")
            }
        }
    }
    
    func otherConsumeBuffer() {
        guard let client = self.client else { return }
        os_log("dequeue called")
        self._streamSink.stream.consumeSampleBuffer(from: client) { sbuf, seq, discontinuity, hasMoreSampleBuffers, err in
            if sbuf != nil {
                self.lastTimingInfo.presentationTimeStamp = CMClockGetTime(CMClockGetHostTimeClock())
                let output: CMIOExtensionScheduledOutput = CMIOExtensionScheduledOutput(sequenceNumber: seq, hostTimeInNanoseconds: UInt64(self.lastTimingInfo.presentationTimeStamp.seconds * Double(NSEC_PER_SEC)))
                os_log("streamingCounter is \(self._streamingCounter)")
                if self._streamingCounter > 0 {
                    os_log("sending boofer")
                    self._streamSource.stream.send(sbuf!, discontinuity: [], hostTimeInNanoseconds: UInt64(sbuf!.presentationTimeStamp.seconds * Double(NSEC_PER_SEC)))
                }
                self._streamSink.stream.notifyScheduledOutputChanged(output)
            }
            if err != nil {
                os_log("LOGGING AN ERROR POOPY")
                os_log("\(err!.localizedDescription)")
            }
        }
    }
    
    func startStreamingSink(client: CMIOExtensionClient) {
        _streamingSinkCounter += 1
        self.sinkStarted = true
        self.client = client
    }
        
    func stopStreamingSink() {
        self.sinkStarted = false
        if _streamingSinkCounter > 1 {
            _streamingSinkCounter -= 1
        }
        else {
            _streamingSinkCounter = 0
        }
    }
}

// MARK: -

class RecordCameraExtensionStreamSource: NSObject, CMIOExtensionStreamSource {
	
    private(set) var stream: CMIOExtensionStream!
        
    let device: CMIOExtensionDevice
    //public var nConnectedClients = 0
    private let _streamFormat: CMIOExtensionStreamFormat
    
    init(localizedName: String, streamID: UUID, streamFormat: CMIOExtensionStreamFormat, device: CMIOExtensionDevice) {
        
        self.device = device
        self._streamFormat = streamFormat
        super.init()
        self.stream = CMIOExtensionStream(localizedName: localizedName, streamID: streamID, direction: .source, clockType: .hostTime, source: self)
    }
    
    var formats: [CMIOExtensionStreamFormat] {
        
        return [_streamFormat]
    }
    
    var activeFormatIndex: Int = 0 {
        
        didSet {
            if activeFormatIndex >= 1 {
                os_log(.error, "Invalid index")
            }
        }
    }
    
    var availableProperties: Set<CMIOExtensionProperty> {
        
        return [.streamActiveFormatIndex, .streamFrameDuration, customExtensionPropertyTest]
    }

    public var test: String = "dog"
    var count = 0

    func streamProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionStreamProperties {
        let streamProperties = CMIOExtensionStreamProperties(dictionary: [:])
        if properties.contains(.streamActiveFormatIndex) {
            streamProperties.activeFormatIndex = 0
        }
        if properties.contains(.streamFrameDuration) {
            let frameDuration = CMTime(value: 1, timescale: Int32(kFrameRate))
            streamProperties.frameDuration = frameDuration
        }
        if properties.contains(customExtensionPropertyTest) {
            streamProperties.setPropertyState(CMIOExtensionPropertyState(value: self.test as NSString), forProperty: customExtensionPropertyTest)

        }
        return streamProperties
    }
    
    func setStreamProperties(_ streamProperties: CMIOExtensionStreamProperties) throws {
        
        if let activeFormatIndex = streamProperties.activeFormatIndex {
            self.activeFormatIndex = activeFormatIndex
        }
        
        if let state = streamProperties.propertiesDictionary[customExtensionPropertyTest] {
            if let newValue = state.value as? String {
                self.test = newValue
                os_log("test is \(self.test, privacy: .public)")
            }
        }
    }
    
    func authorizedToStartStream(for client: CMIOExtensionClient) -> Bool {
        
        // An opportunity to inspect the client info and decide if it should be allowed to start the stream.
        return true
    }
    
    func startStream() throws {
        
        guard let deviceSource = device.source as? RecordCameraExtensionDeviceSource else {
            fatalError("Unexpected source type \(String(describing: device.source))")
        }
        deviceSource.startStreaming()
    }
    
    func stopStream() throws {
        
        guard let deviceSource = device.source as? RecordCameraExtensionDeviceSource else {
            fatalError("Unexpected source type \(String(describing: device.source))")
        }
        deviceSource.stopStreaming()
    }
}

// MARK: -

class RecordCameraExtensionProviderSource: NSObject, CMIOExtensionProviderSource {
	
	private(set) var provider: CMIOExtensionProvider!
	
	private var deviceSource: RecordCameraExtensionDeviceSource!
	
	// CMIOExtensionProviderSource protocol methods (all are required)
	
	init(clientQueue: DispatchQueue?) {
		
		super.init()
		
		provider = CMIOExtensionProvider(source: self, clientQueue: clientQueue)
		deviceSource = RecordCameraExtensionDeviceSource(localizedName: "RecordCameraExtension (Swift)")
		
		do {
			try provider.addDevice(deviceSource.device)
		} catch let error {
			fatalError("Failed to add device: \(error.localizedDescription)")
		}
	}
	
	func connect(to client: CMIOExtensionClient) throws {
		
		// Handle client connect
	}
	
	func disconnect(from client: CMIOExtensionClient) {
		
		// Handle client disconnect
	}
	
	var availableProperties: Set<CMIOExtensionProperty> {
		
		// See full list of CMIOExtensionProperty choices in CMIOExtensionProperties.h
		return [.providerManufacturer]
	}
	
	func providerProperties(forProperties properties: Set<CMIOExtensionProperty>) throws -> CMIOExtensionProviderProperties {
		
		let providerProperties = CMIOExtensionProviderProperties(dictionary: [:])
		if properties.contains(.providerManufacturer) {
			providerProperties.manufacturer = "RecordCameraExtension Manufacturer"
		}
		return providerProperties
	}
	
	func setProviderProperties(_ providerProperties: CMIOExtensionProviderProperties) throws {
		
		// Handle settable properties here.
	}
}
