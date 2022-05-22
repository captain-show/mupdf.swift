//
//  CMuPDFMimeType.mm
//
//  Created by Radzivon Bartoshyk on 22/05/2022.
//

#include "CMuPDFMimeType.hxx"

@implementation CMuPDFMimeType {
    NSData* storedData;
}

-(id)initWithData:(nonnull NSData*)data {
    storedData = data;
    return self;
}

-(nonnull NSString*)getMagic {
    auto subdata4 = [storedData subdataWithRange:NSMakeRange(0, 4)];
    char headEpubArr[4] = {0x50, 0x4B, 0x03, 0x04};
    char epubMagic[28] = {0x6D, 0x69, 0x6D, 0x65, 0x74, 0x79, 0x70, 0x65, 0x61, 0x70, 0x70, 0x6C,
        0x69, 0x63, 0x61, 0x74, 0x69, 0x6F, 0x6E, 0x2F, 0x65, 0x70, 0x75, 0x62,
        0x2B, 0x7A, 0x69, 0x70};
    auto headEpub = [[NSData alloc] initWithBytes: &headEpubArr[0] length: sizeof(headEpubArr)];
    auto magicEpub = [[NSData alloc] initWithBytes: &epubMagic[0] length: sizeof(epubMagic)];
    if ([subdata4 isEqualToData: [@"%PDF" dataUsingEncoding: NSUTF8StringEncoding]]) {
        return @"application/pdf";
    } else if ([subdata4 isEqualToData: headEpub]
               && [[storedData subdataWithRange: NSMakeRange(30, 57)] isEqualToData: magicEpub]) {
        return @"application/epub+zip";
    }
    return @"application/octet-stream";
}

@end
