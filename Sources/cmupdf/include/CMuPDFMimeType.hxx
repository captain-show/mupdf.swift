//
//  CMuPDFMimeType.h
//  
//
//  Created by Radzivon Bartoshyk on 22/05/2022.
//

#ifndef CMuPDFMimeType_h
#define CMuPDFMimeType_h

#import <Foundation/Foundation.h>

@interface CMuPDFMimeType : NSObject
-(nonnull id)initWithData:(nonnull NSData*)data;
-(nonnull NSString*)getMagic;
@end

#endif /* CMuPDFMimeType_h */
