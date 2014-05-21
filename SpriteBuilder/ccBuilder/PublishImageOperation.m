#import "PublishImageOperation.h"

#import "FCFormatConverter.h"
#import "CCBFileUtil.h"
#import "ResourceManager.h"
#import "ResourceManagerUtil.h"
#import "DateCache.h"
#import "NSString+Publishing.h"
#import "PublishRenamedFilesLookup.h"
#import "PublishingTaskStatusProgress.h"
#import "ProjectSettings.h"
#import "PublishLogging.h"


@interface PublishImageOperation ()

@property (nonatomic, strong) FCFormatConverter *formatConverter;

@end


@implementation PublishImageOperation

- (void)main
{
    [super main];

    [self assertProperties];

    [self publishImage];

    [_publishingTaskStatusProgress taskFinished];
}

- (void)assertProperties
{
    NSAssert(_srcFilePath != nil, @"srcPath should not be nil");
    NSAssert(_dstFilePath != nil, @"dstPath should not be nil");
    NSAssert(_outputDir != nil, @"outDir should not be nil");
    NSAssert(_resolution != nil, @"resolution should not be nil");
    NSAssert(_publishedPNGFiles != nil, @"publishedPNGFiles should not be nil");
    NSAssert(_fileLookup != nil, @"fileLookup should not be nil");
}

- (void)publishImage
{
    // TODO: this is a long method -> split up!
    NSString *relPath = [ResourceManagerUtil relativePathFromAbsolutePath:_srcFilePath];

    if (_isSpriteSheet
        && [self isSpriteSheetAlreadyPublished:_srcFilePath outDir:_outputDir resolution:_resolution])
    {
        LocalLog(@"[%@] SKIPPING spritesheet and already published - %@", [self class], [self description]);
        return;
    }

    [_publishingTaskStatusProgress updateStatusText:[NSString stringWithFormat:@"Publishing %@...", [_dstFilePath lastPathComponent]]];

    // Find out which file to copy for the current resolution
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *srcFileName = [_srcFilePath lastPathComponent];
    NSString *dstFileName = [_dstFilePath lastPathComponent];
    NSString *srcDir = [_srcFilePath stringByDeletingLastPathComponent];
    NSString *dstDir = [_dstFilePath stringByDeletingLastPathComponent];
    NSString *srcAutoPath = [_srcFilePath resourceAutoFilePath];

    // Update path to reflect resolution
    srcDir = [srcDir stringByAppendingPathComponent:[@"resources-" stringByAppendingString:_resolution]];
    dstDir = [dstDir stringByAppendingPathComponent:[@"resources-" stringByAppendingString:_resolution]];

    self.srcFilePath = [srcDir stringByAppendingPathComponent:srcFileName];
    self.dstFilePath = [dstDir stringByAppendingPathComponent:dstFileName];

    // Sprite Kit requires specific extensions for specific image resolutions (ie @2x, ~ipad, ..)
    if (_projectSettings.engine == CCBTargetEngineSpriteKit)
    {
        self.dstFilePath = [self pathWithCocoaImageResolutionSuffix:_dstFilePath resolution:_resolution];
    }

    // Create destination directory if it doesn't exist
    [fileManager createDirectoryAtPath:dstDir withIntermediateDirectories:YES attributes:NULL error:NULL];

    // Get the format of the published image
    int format = kFCImageFormatPNG;
    BOOL dither = NO;
    BOOL compress = NO;

    // TODO: Move to data object: format, dither, compress
    if (!_isSpriteSheet)
    {
        if (_targetType == kCCBPublisherTargetTypeIPhone)
        {
            format = [[_projectSettings valueForRelPath:relPath andKey:@"format_ios"] intValue];
            dither = [[_projectSettings valueForRelPath:relPath andKey:@"format_ios_dither"] boolValue];
            compress = [[_projectSettings valueForRelPath:relPath andKey:@"format_ios_compress"] boolValue];
        }
        else if (_targetType == kCCBPublisherTargetTypeAndroid)
        {
            format = [[_projectSettings valueForRelPath:relPath andKey:@"format_android"] intValue];
            dither = [[_projectSettings valueForRelPath:relPath andKey:@"format_android_dither"] boolValue];
            compress = [[_projectSettings valueForRelPath:relPath andKey:@"format_android_compress"] boolValue];
        }
    }

    // Fetch new name
    NSString *dstPathProposal = [[FCFormatConverter defaultConverter] proposedNameForConvertedImageAtPath:_dstFilePath
                                                                                                   format:format
                                                                                                 compress:compress
                                                                                            isSpriteSheet:_isSpriteSheet];

    // Add renaming rule
    NSString *relPathRenamed = [[FCFormatConverter defaultConverter] proposedNameForConvertedImageAtPath:relPath
                                                                                                  format:format
                                                                                                compress:compress
                                                                                           isSpriteSheet:_isSpriteSheet];

    [_fileLookup addRenamingRuleFrom:relPath to:relPathRenamed];

    // Copy and convert the image
    BOOL isDirty = [_projectSettings isDirtyRelPath:relPath];

    if ([fileManager fileExistsAtPath:_srcFilePath])
    {
        // Has customized file for resolution

        // Check if file already exists
        NSDate *srcDate = [CCBFileUtil modificationDateForFile:_srcFilePath];
        NSDate *dstDate = [CCBFileUtil modificationDateForFile:dstPathProposal];

        if (dstDate
            && [srcDate isEqualToDate:dstDate]
            && !isDirty)
        {
            LocalLog(@"[%@] SKIPPING file exists, same dates (src: %@, dst: %@) and not dirty - %@", [self class], srcDate, dstDate, [self description]);
            return;
        }

        // Copy file
        [fileManager copyItemAtPath:_srcFilePath toPath:_dstFilePath error:NULL];

        // Convert it
        NSString *dstPathConverted = nil;
        NSError *error;

        self.formatConverter = [FCFormatConverter defaultConverter];
        if (![_formatConverter convertImageAtPath:_dstFilePath
                                           format:format
                                           dither:dither
                                         compress:compress
                                    isSpriteSheet:_isSpriteSheet
                                   outputFilename:&dstPathConverted
                                            error:&error])
        {
            [_warnings addWarningWithDescription:[NSString stringWithFormat:@"Failed to convert image: %@. Error Message:%@", srcFileName, error.localizedDescription]
                                         isFatal:NO];
            self.formatConverter = nil;
            return;
        }
        self.formatConverter = nil;

        // Update modification date
        [CCBFileUtil setModificationDate:srcDate forFile:dstPathConverted];

        if (!_isSpriteSheet
            && format == kFCImageFormatPNG)
        {
            [_publishedPNGFiles addObject:dstPathConverted];
        }
    }
    else if ([fileManager fileExistsAtPath:srcAutoPath])
    {
        // Use resources-auto file for conversion

        // Check if file already exist
        NSDate *srcDate = [CCBFileUtil modificationDateForFile:srcAutoPath];
        NSDate *dstDate = [CCBFileUtil modificationDateForFile:dstPathProposal];

        if (dstDate
            && [srcDate isEqualToDate:dstDate]
            && !isDirty)
        {
            LocalLog(@"[%@] SKIPPING file exists, same dates (src: %@, dst: %@) and not dirty - %@", [self class], srcDate, dstDate, [self description]);
            return;
        }

        // Copy file and resize
        [[ResourceManager sharedManager] createCachedImageFromAuto:srcAutoPath saveAs:_dstFilePath forResolution:_resolution];

        // Convert it
        NSString *dstPathConverted = nil;
        NSError *error;

        self.formatConverter = [FCFormatConverter defaultConverter];
        if (![_formatConverter convertImageAtPath:_dstFilePath
                                           format:format
                                           dither:dither
                                         compress:compress
                                    isSpriteSheet:_isSpriteSheet
                                   outputFilename:&dstPathConverted
                                            error:&error])
        {
            [_warnings addWarningWithDescription:[NSString stringWithFormat:@"Failed to convert image: %@. Error Message:%@", srcFileName, error.localizedDescription]
                                         isFatal:NO];
        }
        self.formatConverter = nil;

        // Update modification date
        [CCBFileUtil setModificationDate:srcDate forFile:dstPathConverted];

        if (!_isSpriteSheet
            && format == kFCImageFormatPNG)
        {
            [_publishedPNGFiles addObject:dstPathConverted];
        }
    }
    else
    {
        [_warnings addWarningWithDescription:[NSString stringWithFormat:@"Failed to publish file %@, make sure it is in the resources-auto folder.", srcFileName] isFatal:NO];
    }
}

- (void)cancel
{
    [super cancel];
    [_formatConverter cancel];
}

- (BOOL)isSpriteSheetAlreadyPublished:(NSString *)srcPath outDir:(NSString *)outDir resolution:(NSString *)resolution
{
    NSString *ssDir = [srcPath stringByDeletingLastPathComponent];
    NSString *ssDirRel = [ResourceManagerUtil relativePathFromAbsolutePath:ssDir];
    NSString *ssName = [ssDir lastPathComponent];

    NSDate *srcDate = [self modifiedDateOfSpriteSheetDirectory:ssDir];

    BOOL isDirty = [_projectSettings isDirtyRelPath:ssDirRel];

    // Make the name for the final sprite sheet
    NSString *ssDstPath = [[[[outDir stringByDeletingLastPathComponent]
                                     stringByAppendingPathComponent:[NSString stringWithFormat:@"resources-%@", resolution]]
                                     stringByAppendingPathComponent:ssName] stringByAppendingPathExtension:@"plist"];

    NSDate *ssDstDate = [self modifiedDataOfSpriteSheetFile:ssDstPath];

    return ssDstDate && [ssDstDate isEqualToDate:srcDate] && !isDirty;
}

// TODO: spritesheet logic needed in here?
- (NSDate *)modifiedDataOfSpriteSheetFile:(NSString *)spriteSheetFile
{
    id ssDstDate = [_modifiedFileDateCache cachedDateForKey:spriteSheetFile];

    if ([ssDstDate isMemberOfClass:[NSNull class]])
    {
        return nil;
    }

    if (!ssDstDate)
    {
        ssDstDate = [CCBFileUtil modificationDateForFile:spriteSheetFile];
        // Storing NSNull since CCBFileUtil can return nil due to a non existing file
        // So we don't run into the whole fille IO process again, rather hit the cache and
        // bend the result here
        if (ssDstDate == nil)
        {
            [_modifiedFileDateCache setCachedDate:[NSNull null] forKey:spriteSheetFile];
        }
        else
        {
            [_modifiedFileDateCache setCachedDate:ssDstDate forKey:spriteSheetFile];
        }
    }

    return ssDstDate;
}

// TODO: spritesheet logic needed in here?
- (NSDate *)modifiedDateOfSpriteSheetDirectory:(NSString *)directory
{
    NSDate *srcDate = [_modifiedFileDateCache cachedDateForKey:directory];
    if (!srcDate)
    {
        srcDate = [self latestModifiedDateForDirectory:directory];
        [_modifiedFileDateCache setCachedDate:srcDate forKey:directory];
    }
    return srcDate;
}

- (NSString *)pathWithCocoaImageResolutionSuffix:(NSString *)path resolution:(NSString *)resolution
{
    NSString *extension = [path pathExtension];

    if ([resolution isEqualToString:@"phonehd"])
    {
        path = [NSString stringWithFormat:@"%@@2x.%@", [path stringByDeletingPathExtension], extension];
    }
    else if ([resolution isEqualToString:@"tablet"])
    {
        path = [NSString stringWithFormat:@"%@~ipad.%@", [path stringByDeletingPathExtension], extension];
    }
    else if ([resolution isEqualToString:@"tablethd"])
    {
        path = [NSString stringWithFormat:@"%@@2x~ipad.%@", [path stringByDeletingPathExtension], extension];
    }

    return path;
}

- (NSDate *)latestModifiedDateForDirectory:(NSString *)dir
{
    NSDate *latestDate = [CCBFileUtil modificationDateForFile:dir];

    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dir error:NULL];
    for (NSString *file in files)
    {
        NSString *absFile = [dir stringByAppendingPathComponent:file];

        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:absFile isDirectory:&isDir])
        {
            NSDate *fileDate = NULL;

            if (isDir)
            {
                fileDate = [self latestModifiedDateForDirectory:absFile];
            }
            else
            {
                fileDate = [CCBFileUtil modificationDateForFile:absFile];
            }

            if ([fileDate compare:latestDate] == NSOrderedDescending)
            {
                latestDate = fileDate;
            }
        }
    }

    return latestDate;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"src: %@, dst: %@, target: %i, resolution: %@, srcfull: %@, dstfull: %@", [_srcFilePath lastPathComponent], [_dstFilePath lastPathComponent], _targetType, _resolution, _srcFilePath, _dstFilePath];
}

@end