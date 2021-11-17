import MLKitBarcodeScanning
import MLKitVision

@objc(VisionCameraQrcodeScanner)
class VisionCameraQrcodeScanner: NSObject, FrameProcessorPluginBase {
    
    static var barcodeScanner: BarcodeScanner?
    static var barcodeFormatOptionSet: BarcodeFormat = []
    
    @objc
    public static func callback(_ frame: Frame!, withArgs args: [Any]!) -> Any! {
        let image = VisionImage(buffer: frame.buffer)
        image.orientation = .up
        var barCodeAttributes: [Any] = []
        do {
            try self.createScanner(args)
            let barcodes: [Barcode] = try barcodeScanner!.results(in: image)
            if (!barcodes.isEmpty){
                for barcode in barcodes {
                    barCodeAttributes.append(self.convertBarcode(barcode: barcode))
                }
            }
        } catch _ {
            return nil
        }
        
        return barCodeAttributes
    }
    
    static func createScanner(_ args: [Any]!) throws {
        guard let rawFormats = args[0] as? [Int] else {
            throw BarcodeError.noBarcodeFormatProvided
        }
        var formatOptionSet: BarcodeFormat = []
        rawFormats.forEach { rawFormat in
            if (rawFormat == 0) {
                // ALL is a special case, since the Android and iOS option raw values don't match
                formatOptionSet.insert(.all)
            } else {
                formatOptionSet.insert(BarcodeFormat(rawValue: rawFormat))
            }
        }
        if (barcodeScanner == nil || barcodeFormatOptionSet != formatOptionSet) {
            let barcodeOptions = BarcodeScannerOptions(formats: formatOptionSet)
            barcodeScanner = BarcodeScanner.barcodeScanner(options: barcodeOptions)
            barcodeFormatOptionSet = formatOptionSet
        }
    }
    
    static func convertContent(barcode: Barcode) -> Any {
        var map: [String: Any] = [:]
        
        map["type"] = barcode.valueType
        
        switch barcode.valueType {
        case .unknown, .ISBN, .text:
            map["content"] = barcode.rawValue
        case .contactInfo:
            map["content"] = BarcodeConverter.convertToMap(contactInfo: barcode.contactInfo)
        case .email:
            map["content"] = BarcodeConverter.convertToMap(email: barcode.email)
        case .phone:
            map["content"] = BarcodeConverter.convertToMap(phone: barcode.phone)
        case .SMS:
            map["content"] = BarcodeConverter.convertToMap(sms: barcode.sms)
        case .URL:
            map["content"] = BarcodeConverter.convertToMap(url: barcode.url)
        case .wiFi:
            map["content"] = BarcodeConverter.convertToMap(wifi: barcode.wifi)
        case .geographicCoordinates:
            map["content"] = BarcodeConverter.convertToMap(geoPoint: barcode.geoPoint)
        case .calendarEvent:
            map["content"] = BarcodeConverter.convertToMap(calendarEvent: barcode.calendarEvent)
        case .driversLicense:
            map["content"] = BarcodeConverter.convertToMap(driverLicense: barcode.driverLicense)
        default:
            map = [:]
        }
        
        return map
    }
    
    static func convertBarcode(barcode: Barcode) -> Any {
        var map: [String: Any] = [:]
        
        map["cornerPoints"] = barcode.cornerPoints
        map["displayValue"] = barcode.displayValue
        map["rawValue"] = barcode.rawValue
        map["content"] = self.convertContent(barcode: barcode)
        
        return map
    }
}
