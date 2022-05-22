//
//  MuPDFDocument.m
//  testmacosapp
//
//  Created by Radzivon Bartoshyk on 21/05/2022.
//

#import <Foundation/Foundation.h>
#import "CMuPDFDocument.hxx"
#import "mupdf/fitz.h"
#import "CMuPDFMimeType.hxx"
#include <pthread.h>

void fast_unpack(char* rgba, const char* rgb, const int count) {
    if(count==0)
        return;
    for(int i=count; --i; rgba+=4, rgb+=3) {
        *(uint32_t*)(void*)rgba = *(const uint32_t*)(const void*)rgb;
    }
    for(int j=0; j<3; ++j) {
        rgba[j] = rgb[j];
    }
}

void lock_mutex(void *user, int lock)
{
    pthread_mutex_t *mutex = (pthread_mutex_t *) user;

    if (pthread_mutex_lock(&mutex[lock]) != 0)
        return;
}

void unlock_mutex(void *user, int lock)
{
    pthread_mutex_t *mutex = (pthread_mutex_t *) user;

    if (pthread_mutex_unlock(&mutex[lock]) != 0)
        return;
}

@implementation CMuPDFDocument {
    pthread_mutex_t mutex[FZ_LOCK_MAX];
    fz_context *ctx;
    fz_document *doc;
    fz_locks_context locks;
    unsigned char* storedBuffer;
    fz_stream* openedStream;
}

-(nullable id)initWithData:(nonnull NSData*)data magic:(nullable NSString*)magic {
    storedBuffer = nullptr;
    for (int i = 0; i < FZ_LOCK_MAX; i++)
    {
        if (pthread_mutex_init(&mutex[i], NULL) != 0)
            return nil;
    }

    locks.user = mutex;
    locks.lock = lock_mutex;
    locks.unlock = unlock_mutex;

    ctx = fz_new_context(NULL, &locks, FZ_STORE_DEFAULT);
    fz_try(ctx)
    fz_register_document_handlers(ctx);
    fz_catch(ctx)
    {
        NSLog(@"cannot register document handlers: %s\n", fz_caught_message(ctx));
        fz_drop_context(ctx);
        ctx = nullptr;
        return nil;
    }
    storedBuffer = static_cast<unsigned char*>(malloc(data.length));
    memcpy(storedBuffer, data.bytes, data.length);
    fz_try(ctx)
    {
        openedStream = fz_open_memory(ctx, storedBuffer, data.length);
        if (!openedStream) {
            fz_drop_context(ctx);
            ctx = nullptr;
            return nil;
        }
        auto realMagic = magic;
        if (!realMagic) {
            realMagic = [[[CMuPDFMimeType alloc] initWithData:data] getMagic];
        }
        doc = fz_open_document_with_stream(ctx, [realMagic UTF8String], openedStream);
    }
    fz_catch(ctx)
    {
        NSLog(@"cannot open document: %s\n", fz_caught_message(ctx));
        fz_drop_context(ctx);
        ctx = nullptr;
        return nil;
    }
    return self;
}

-(nullable id)initWithURL:(nonnull NSURL*)url {
    if ([[url scheme] isEqualToString:@"http"] || [[url scheme] isEqualToString:@"https"]) {
        auto data = [[NSData alloc] initWithContentsOfURL:url];
        return [[CMuPDFDocument alloc] initWithData:data magic:nil];
    }
    storedBuffer = nullptr;
    
    for (int i = 0; i < FZ_LOCK_MAX; i++)
    {
        if (pthread_mutex_init(&mutex[i], NULL) != 0)
            return nil;
    }

    locks.user = mutex;
    locks.lock = lock_mutex;
    locks.unlock = unlock_mutex;

    ctx = fz_new_context(NULL, &locks, FZ_STORE_DEFAULT);
    fz_try(ctx)
    fz_register_document_handlers(ctx);
    fz_catch(ctx)
    {
        NSLog(@"cannot register document handlers: %s\n", fz_caught_message(ctx));
        fz_drop_context(ctx);
        ctx = nullptr;
        return nil;
    }
    fz_try(ctx)
        doc = fz_open_document(ctx, [[url path] UTF8String]);
    fz_catch(ctx)
    {
        NSLog(@"cannot open document: %s\n", fz_caught_message(ctx));
        fz_drop_context(ctx);
        ctx = nullptr;
        return nil;
    }
    return self;
}

-(CGRect)getPageSize:(int)pageNumber {
    fz_page* page;
    fz_try(ctx)
    page = fz_load_page(ctx, doc, pageNumber);
    fz_catch(ctx)
    {
        NSLog(@"cannot load page: %s\n", fz_caught_message(ctx));
        return CGRectZero;
    }
    auto bbox = fz_bound_page(ctx, page);
    fz_drop_page(ctx, page);
    
    return CGRectMake(bbox.x0, bbox.y0, bbox.x1 - bbox.x0, bbox.y1 - bbox.y0);
}

-(int)numberOfPages {
    int pageCount = 0;
    fz_try(ctx)
    pageCount = fz_count_pages(ctx, doc);
    fz_catch(ctx)
    {
        NSLog(@"cannot count number of pages: %s\n", fz_caught_message(ctx));
        return 0;
    }
    return pageCount;
}

-(nullable CMuPDFImage*)page:(int)at dpi:(int)dpi {
    auto zoom = (float)dpi / 72.0f;
    fz_matrix ctm = fz_scale(zoom, zoom);
    fz_pixmap* pix;
    
    fz_try(ctx)
        pix = fz_new_pixmap_from_page_number(ctx, doc, at, ctm, fz_device_rgb(ctx), 0);
    fz_catch(ctx)
    {
        return nil;
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    int flags = kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipLast;
    auto finalBuffer = malloc(pix->w * pix->h * 4);
    fast_unpack((char*)finalBuffer, (char*) pix->samples, pix->w*pix->h);
    CGContextRef gtx = CGBitmapContextCreate(finalBuffer, pix->w, pix->h, 8, pix->w * 4, colorSpace, flags);
    fz_drop_pixmap(ctx, pix);
    if (gtx == NULL) {
        free(finalBuffer);
        return nil;
    }
    CGImageRef imageRef = CGBitmapContextCreateImage(gtx);
    CMuPDFImage *image = nil;
    free(finalBuffer);
#if TARGET_OS_OSX
    image = [[NSImage alloc] initWithCGImage:imageRef size: CGSizeMake(pix->w, pix->h)];
#else
    image = [UIImage imageWithCGImage:imageRef scale:1 orientation: UIImageOrientationUp];
#endif
    
    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorSpace);
    return image;
}

-(bool)isEncrypted {
    bool isPasswordRequired = false;
    fz_try(ctx)
    isPasswordRequired = fz_needs_password(ctx, doc) != 0;
    fz_catch(ctx)
    {
        NSLog(@"cannot check document password: %s\n", fz_caught_message(ctx));
    }
    return isPasswordRequired;
}

-(bool)authenticate:(nonnull NSString*)password {
    bool successfullyDecrypted = false;
    fz_try(ctx)
    successfullyDecrypted = fz_authenticate_password(ctx, doc, [password UTF8String]) != 0;
    fz_catch(ctx)
    {
        NSLog(@"cannot check document password: %s\n", fz_caught_message(ctx));
        return 0;
    }
    return successfullyDecrypted;
}

-(void)dealloc {
    if (doc) {
        fz_drop_document(ctx, doc);
        doc = nullptr;
    }
    if (openedStream) {
        fz_drop_stream(ctx, openedStream);
        openedStream = nullptr;
    }
    if (ctx) {
        fz_drop_context(ctx);
        ctx = nullptr;
    }
    for (int i = 0; i < FZ_LOCK_MAX; i++) {
        pthread_mutex_destroy(&mutex[i]);
    }
    if (storedBuffer) {
        free(storedBuffer);
        storedBuffer = nullptr;
    }
}

@end
