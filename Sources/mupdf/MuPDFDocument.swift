import Foundation
#if SWIFT_PACKAGE
import cmupdf
#endif

public class BookDocument {
    
    private let _doc: CMuPDFDocument
    
    init?(url: URL) {
        guard let dc = CMuPDFDocument(url: url) else {
            return nil
        }
        _doc = dc
    }
    
    var numberOfPages: Int {
        Int(_doc.numberOfPages())
    }
}
