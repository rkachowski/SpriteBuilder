//
//  XCodeRun.m
//  SpriteBuilder
//
//  Created by Nicky Weber on 10.04.14.
//
//

#import "XCodeRun.h"

@implementation XCodeRun

- (void)runProject:(NSString *)projectPath
{
    NSAssert(projectPath != nil, @"projectPath should be set");

    NSString *templateScriptPath = [[NSBundle mainBundle] pathForResource:@"runInXcode" ofType:@"AppleScript"];
    NSString *templateScript = [NSString stringWithContentsOfFile:templateScriptPath encoding:NSUTF8StringEncoding error:nil];
    templateScript = [templateScript stringByReplacingOccurrencesOfString:@"ABSOLUTE_PATH_TO_PROJECT" withString:projectPath];

    NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:templateScript];
    NSDictionary *errors;
    if (![appleScript executeAndReturnError:&errors])
    {
        NSLog(@"ERRORS: %@", errors);
    }
}

@end
