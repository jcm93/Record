import Foundation
import CoreMediaIO
import AVFoundation
import OSLog


class RecordCameraStreamSink: NSObject {
    
    private let logger = Logger.virtualCamera
    
    var sourceStream: CMIOStreamID?
    var sinkStream: CMIOStreamID?
    var sinkQueue: CMSimpleQueue?
    var cameraName = "RecordCameraExtension (Swift)"
    var testProperty = "dog"
    
    private var needToStream: Bool = false
    private var mirrorCamera: Bool = false
    private var activating: Bool = false
    private var readyToEnqueue = false
    private var enqueued = false
    private var _videoDescription: CMFormatDescription!
    private var _bufferPool: CVPixelBufferPool!
    private var _bufferAuxAttributes: NSDictionary!
    private var _whiteStripeStartRow: UInt32 = 0
    private var _whiteStripeIsAscending: Bool = false
    private var overlayMessage: Bool = false
    private var sequenceNumber = 0
    private var timer: Timer?
    private var propTimer: Timer?
    
    func getJustProperty(streamId: CMIOStreamID) -> String? {
        let selector = "just".convertedToCMIOObjectPropertySelectorName()
        var address = CMIOObjectPropertyAddress(selector, .global, .main)
        let exists = CMIOObjectHasProperty(streamId, &address)
        if exists {
            var dataSize: UInt32 = 0
            var dataUsed: UInt32 = 0
            CMIOObjectGetPropertyDataSize(streamId, &address, 0, nil, &dataSize)
            var name: CFString = "" as NSString
            CMIOObjectGetPropertyData(streamId, &address, 0, nil, dataSize, &dataUsed, &name);
            return name as String
        } else {
            return nil
        }
    }

    func setJustProperty(streamId: CMIOStreamID, newValue: String) {
        let selector = "just".convertedToCMIOObjectPropertySelectorName()
        var address = CMIOObjectPropertyAddress(selector, .global, .main)
        let exists = CMIOObjectHasProperty(streamId, &address)
        if exists {
            var settable: DarwinBoolean = false
            CMIOObjectIsPropertySettable(streamId,&address,&settable)
            if settable == false {
                return
            }
            var dataSize: UInt32 = 0
            CMIOObjectGetPropertyDataSize(streamId, &address, 0, nil, &dataSize)
            var newName: CFString = newValue as NSString
            CMIOObjectSetPropertyData(streamId, &address, 0, nil, dataSize, &newName)
        }
    }
    
    
    func initSink(deviceId: CMIODeviceID, sinkStream: CMIOStreamID, width: Int32, height: Int32) {
        let dims = CMVideoDimensions(width: width, height: height)
        CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: kCVPixelFormatType_32BGRA,
            width: dims.width, height: dims.height, extensions: nil, formatDescriptionOut: &_videoDescription)
        
        var pixelBufferAttributes: NSDictionary!
           pixelBufferAttributes = [
                kCVPixelBufferWidthKey: dims.width,
                kCVPixelBufferHeightKey: dims.height,
                kCVPixelBufferPixelFormatTypeKey: _videoDescription.mediaSubType,
                kCVPixelBufferIOSurfacePropertiesKey: [:]
            ]
        
        CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, pixelBufferAttributes, &_bufferPool)

        let pointerQueue = UnsafeMutablePointer<Unmanaged<CMSimpleQueue>?>.allocate(capacity: 1)
        let pointerRef = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let result = CMIOStreamCopyBufferQueue(sinkStream, {
            (sinkStream: CMIOStreamID, buf: UnsafeMutableRawPointer?, refcon: UnsafeMutableRawPointer?) in
            let sender = Unmanaged<RecordCameraStreamSink>.fromOpaque(refcon!).takeUnretainedValue()
            sender.readyToEnqueue = true
        },pointerRef,pointerQueue)
        if result != 0 {
            logger.error("error copying buffer queue")
        } else {
            if let queue = pointerQueue.pointee {
                self.sinkQueue = queue.takeUnretainedValue()
            }
            let resultStart = CMIODeviceStartStream(deviceId, sinkStream) == 0
            if resultStart {
                logger.info("virtual camera sink started")
            } else {
                logger.error("error starting virtual camera sink")
            }
        }
    }
    
    func getDevice(name: String) -> AVCaptureDevice? {
        print("getDevice name=",name)
        var devices: [AVCaptureDevice]?
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.externalUnknown],
                                                                mediaType: .video,
                                                                position: .unspecified)
        devices = discoverySession.devices
        guard let devices = devices else { return nil }
        return devices.first { $0.localizedName == name}
    }

    func getCMIODevice(uid: String) -> CMIOObjectID? {
        var dataSize: UInt32 = 0
        var devices = [CMIOObjectID]()
        var dataUsed: UInt32 = 0
        var opa = CMIOObjectPropertyAddress(CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices), .global, .main)
        CMIOObjectGetPropertyDataSize(CMIOObjectPropertySelector(kCMIOObjectSystemObject), &opa, 0, nil, &dataSize);
        let nDevices = Int(dataSize) / MemoryLayout<CMIOObjectID>.size
        devices = [CMIOObjectID](repeating: 0, count: Int(nDevices))
        CMIOObjectGetPropertyData(CMIOObjectPropertySelector(kCMIOObjectSystemObject), &opa, 0, nil, dataSize, &dataUsed, &devices);
        for deviceObjectID in devices {
            opa.mSelector = CMIOObjectPropertySelector(kCMIODevicePropertyDeviceUID)
            CMIOObjectGetPropertyDataSize(deviceObjectID, &opa, 0, nil, &dataSize)
            var name: CFString = "" as NSString
            //CMIOObjectGetPropertyData(deviceObjectID, &opa, 0, nil, UInt32(MemoryLayout<CFString>.size), &dataSize, &name);
            CMIOObjectGetPropertyData(deviceObjectID, &opa, 0, nil, dataSize, &dataUsed, &name);
            if String(name) == uid {
                return deviceObjectID
            }
        }
        return nil
    }

    func getInputStreams(deviceId: CMIODeviceID) -> [CMIOStreamID] {
        var dataSize: UInt32 = 0
        var dataUsed: UInt32 = 0
        var opa = CMIOObjectPropertyAddress(CMIOObjectPropertySelector(kCMIODevicePropertyStreams), .global, .main)
        CMIOObjectGetPropertyDataSize(deviceId, &opa, 0, nil, &dataSize);
        let numberStreams = Int(dataSize) / MemoryLayout<CMIOStreamID>.size
        var streamIds = [CMIOStreamID](repeating: 0, count: numberStreams)
        CMIOObjectGetPropertyData(deviceId, &opa, 0, nil, dataSize, &dataUsed, &streamIds)
        return streamIds
    }
    
    func connectToCamera(width: Int32, height: Int32) {
        if let device = getDevice(name: "RecordCameraExtension (Swift)"), let deviceObjectId = getCMIODevice(uid: device.uniqueID) {
            let streamIds = getInputStreams(deviceId: deviceObjectId)
            if streamIds.count == 2 {
                sinkStream = streamIds[1]
                logger.info("found sink stream")
                initSink(deviceId: deviceObjectId, sinkStream: streamIds[1], width: width, height: height)
            }
            if let firstStream = streamIds.first {
                logger.info("found source stream")
                sourceStream = firstStream
            }
        }
    }
    
    func enqueue(_ image: IOSurfaceRef) {
        guard CMSimpleQueueGetCount(sinkQueue!) < CMSimpleQueueGetCapacity(sinkQueue!) else {
            print("error enqueuing")
            return
        }
        var err: OSStatus = 0
        var pixelBuffer: Unmanaged<CVPixelBuffer>?
        CVPixelBufferCreateWithIOSurface(kCFAllocatorDefault, image, self._bufferAuxAttributes, &pixelBuffer)
        if let pixelBuffer = pixelBuffer {
            
            var sbuf: CMSampleBuffer!
            var timingInfo = CMSampleTimingInfo()
            timingInfo.presentationTimeStamp = CMClockGetTime(CMClockGetHostTimeClock())
            err = CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer.takeRetainedValue(), dataReady: true, makeDataReadyCallback: nil, refcon: nil, formatDescription: self._videoDescription, sampleTiming: &timingInfo, sampleBufferOut: &sbuf)
            if err == 0 {
                if let sbuf = sbuf {
                    let pointerRef = UnsafeMutableRawPointer(Unmanaged.passRetained(sbuf).toOpaque())
                    CMSimpleQueueEnqueue(self.sinkQueue!, element: pointerRef)
                }
            }
        } else {
            print("error getting pixel buffer")
        }
    }
    
}

extension String {
    func convertedToCMIOObjectPropertySelectorName() -> CMIOObjectPropertySelector {
        let noName: CMIOObjectPropertySelector = 0
        if count == MemoryLayout<CMIOObjectPropertySelector>.size {
            return data(using: .utf8, allowLossyConversion: false)?.withUnsafeBytes { propertySelector in
                propertySelector.load(as: CMIOObjectPropertySelector.self).byteSwapped
            } ?? noName
        } else {
            return noName
        }
    }
}

public extension CMIOObjectPropertyAddress {
    init(_ selector: CMIOObjectPropertySelector,
         _ scope: CMIOObjectPropertyScope = .anyScope,
         _ element: CMIOObjectPropertyElement = .anyElement) {
        self.init(mSelector: selector, mScope: scope, mElement: element)
    }
}

public extension CMIOObjectPropertyScope {
    /// The CMIOObjectPropertyScope for properties that apply to the object as a whole.
    /// All CMIOObjects have a global scope and for some it is their only scope.
    static let global = CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal)
    
    /// The wildcard value for CMIOObjectPropertyScopes.
    static let anyScope = CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard)
    
    /// The CMIOObjectPropertyScope for properties that apply to the input signal paths of the CMIODevice.
    static let deviceInput = CMIOObjectPropertyScope(kCMIODevicePropertyScopeInput)
    
    /// The CMIOObjectPropertyScope for properties that apply to the output signal paths of the CMIODevice.
    static let deviceOutput = CMIOObjectPropertyScope(kCMIODevicePropertyScopeOutput)
    
    /// The CMIOObjectPropertyScope for properties that apply to the play through signal paths of the CMIODevice.
    static let devicePlayThrough = CMIOObjectPropertyScope(kCMIODevicePropertyScopePlayThrough)
}

public extension CMIOObjectPropertyElement {
    /// The CMIOObjectPropertyElement value for properties that apply to the master element or to the entire scope.
    //static let master = CMIOObjectPropertyElement(kCMIOObjectPropertyElementMaster)
    static let main = CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
    /// The wildcard value for CMIOObjectPropertyElements.
    static let anyElement = CMIOObjectPropertyElement(kCMIOObjectPropertyElementWildcard)
}
