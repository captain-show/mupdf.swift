//
//  MuPDFDocument.h
//
//  Created by Radzivon Bartoshyk on 21/05/2022.
//

#ifndef MuPDFDocument_h
#define MuPDFDocument_h

#import "Foundation/Foundation.h"
#import "TargetConditionals.h"

#if TARGET_OS_OSX
#import <AppKit/AppKit.h>
#define CMuPDFImage   NSImage
#else
#import <UIKit/UIKit.h>
#define CMuPDFImage   UIImage
#endif

@interface CMuPDFDocument: NSObject
-(nullable id)initWithURL:(nonnull NSURL*)url;
-(nullable id)initWithData:(nonnull NSData*)data magic:(nullable NSString*)magic;
-(nullable CMuPDFImage*)page:(int)at dpi:(int)dpi;
-(bool)isEncrypted;
-(bool)authenticate:(nonnull NSString*)password;
-(int)numberOfPages;
@end

#endif /* MuPDFDocument_h */
