/*
     File: Controller.m 
 Abstract: Main controller for the SBSendEmail sample. 
  Version: 1.1 
  
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple 
 Inc. ("Apple") in consideration of your agreement to the following 
 terms, and your use, installation, modification or redistribution of 
 this Apple software constitutes acceptance of these terms.  If you do 
 not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software. 
  
 In consideration of your agreement to abide by the following terms, and 
 subject to these terms, Apple grants you a personal, non-exclusive 
 license, under Apple's copyrights in this original Apple software (the 
 "Apple Software"), to use, reproduce, modify and redistribute the Apple 
 Software, with or without modifications, in source and/or binary forms; 
 provided that if you redistribute the Apple Software in its entirety and 
 without modifications, you must retain this notice and the following 
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. may 
 be used to endorse or promote products derived from the Apple Software 
 without specific prior written permission from Apple.  Except as 
 expressly stated in this notice, no other rights or licenses, express or 
 implied, are granted by Apple herein, including but not limited to any 
 patent rights that may be infringed by your derivative works or by other 
 works in which the Apple Software may be incorporated. 
  
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE 
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION 
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS 
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND 
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS. 
  
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL 
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, 
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED 
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), 
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE 
 POSSIBILITY OF SUCH DAMAGE. 
  
 Copyright (C) 2011 Apple Inc. All Rights Reserved. 
  
 */

#import <CoreServices/CoreServices.h>
#import "Controller.h"
#import "Mail.h"

const int MAX_SENDING_MAIL_CONTENT_LENGTH = 0x1F4; //500

const int LCD_PIXEL_WIDTH = 128;
const int LCD_PIXEL_HEIGHT = 128;

const int ICON_WIDTH = 64;
const int ICON_HEIGHT = 64;

@interface Controller (delegate) <SBApplicationDelegate>
@end

@implementation Controller


@synthesize toField, fromField, messageContent, isBkg, toScreen,
coordX, coordY, picW, picH, picOperation, progressIndicator, lblError,
stepperToScreen, iconToBkg;


- (void)awakeFromNib {
	
    [self.messageContent setFont:[NSFont fontWithName:@"Courier" size:12]];
    [self.toScreen setTitleWithMnemonic: @"1"];
    [self.toScreen.formatter setNilSymbol: @"1"];

}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;
}


/* Part of the SBApplicationDelegate protocol.  Called when an error occurs in
 Scripting Bridge method. */
- (id)eventDidFail:(const AppleEvent *)event withError:(NSError *)error
{
    [[NSAlert alertWithMessageText:@"Error" defaultButton:@"OK" alternateButton:nil otherButton:nil
         informativeTextWithFormat: @"%@", [error localizedDescription]] runModal];
    return nil;
}


- (IBAction)sendEmailMessage:(id)sender {

		/* create a Scripting Bridge object for talking to the Mail application */
	MailApplication *mail = [SBApplication applicationWithBundleIdentifier:@"com.apple.Mail"];
    
        /* set ourself as the delegate to receive any errors */
    mail.delegate = self;
	
    NSString *strContent = [[self.messageContent textStorage] string];
    strContent = [strContent stringByReplacingOccurrencesOfString:@"0x" withString:@""];
    strContent = [strContent stringByReplacingOccurrencesOfString:@"," withString:@""];
    strContent = [strContent stringByReplacingOccurrencesOfString:@" " withString:@""];
    strContent = [strContent stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    int length_strContent = [strContent length];
    int length_toSend = MIN(length_strContent, MAX_SENDING_MAIL_CONTENT_LENGTH);
    
    NSString *strBufferNumber = [self.toScreen stringValue];
    int bufferNumber = 1;
    @try {
        bufferNumber = [strBufferNumber intValue];
    }
    @catch (NSException *exception) {
        bufferNumber = 1;
    }
    if (bufferNumber < 1 || bufferNumber > 8)
        bufferNumber = 1;
    bufferNumber--;

    NSString *strX = [self.coordX stringValue];
    int x = 0;
    @try {
        x = [strX intValue];
    }
    @catch (NSException *exception) {
        x = -1;
    }
    
    NSString *strY = [self.coordY stringValue];
    int y = 0;
    @try {
        y = [strY intValue];
    }
    @catch (NSException *exception) {
        y = -1;
    }

    NSString *strW = [self.picW stringValue];
    int w = 1;
    @try {
        w = [strW intValue];
    }
    @catch (NSException *exception) {
        w = -1;
    }
    
    NSString *strH = [self.picH stringValue];
    int h = 1;
    @try {
        h = [strH intValue];
    }
    @catch (NSException *exception) {
        h = -1;
    }
    
    if (w <= 0 || w > 128 || w%8 != 0)
    {
        [self.lblError setStringValue:@"Error: width [1-128], divisible with 8!"];
        [self.lblError setHidden:false];
        return;
    }
    
    if (h <= 0 || h > 128)
    {
        [self.lblError setStringValue:@"Error: height (H) [1-128]!"];
        [self.lblError setHidden:false];
        return;
    }
 
    if (x < 0 || x >= 128)
    {
        [self.lblError setStringValue:@"Error: X [0-127]!"];
        [self.lblError setHidden:false];
        return;
    }
    
    if (y < 0 || y >= 128)
    {
        [self.lblError setStringValue:@"Error: Y [0-127]!"];
        [self.lblError setHidden:false];
        return;
    }
    
    if ( (((int)(w/8))+(w%8 == 0 ? 0 : 1))*2*h != length_strContent)
    {
        [self.lblError setStringValue:@"Error: data amount isn't as required by width and heigh!"];
        [self.lblError setHidden:false];
        return;
    }

    int isBkgOrIcon = (int)[[self.isBkg selectedCell] tag];
    if (isBkgOrIcon == 2)
    {
        if (w * h > ICON_WIDTH * ICON_HEIGHT)
        {
            [self.lblError setStringValue:@"Error: size of icon is too big, max 4096!"];
            [self.lblError setHidden:false];
            return;
        }
    }
    
    int operationNumber = [self.picOperation indexOfSelectedItem];
    if (operationNumber < 0)
        operationNumber = 0;
    
    [self.lblError setStringValue:@""];
    [self.lblError setHidden:true];
    
    [self.progressIndicator setMaxValue: length_strContent];
    [self.progressIndicator setDoubleValue:0];
    [self.progressIndicator setHidden:false];

    int sentData = 0;
 
    for (int i = 1; length_toSend > 0; i++) {
        
        NSString *strSubject = [NSString stringWithFormat:@"sbs%01i.%01i.%02i.%02i.%03i.%03i.%03i.%03i.%02i.%04i.%01i part of bitmap to metawatch",
                                (int)[[self.isBkg selectedCell] tag],
                                (int)[self.iconToBkg state],
                                bufferNumber, i,
                                x, y, w, h,
                                operationNumber, (int)(sentData/2),
                                (length_toSend >= length_strContent) ? 1 : 0];
 
        NSString *strMailContent = [strContent substringWithRange: NSMakeRange (0, length_toSend)];
        
        /* create a new outgoing message object */
        MailOutgoingMessage *emailMessage = [[[mail classForScriptingClass:@"outgoing message"] alloc] initWithProperties:
                                                    [NSDictionary dictionaryWithObjectsAndKeys:
                                                        strSubject, @"subject",
                                                        strMailContent, @"content",
                                                        nil]];
                    
            /* add the object to the mail app  */
        [[mail outgoingMessages] addObject: emailMessage];

            /* set the sender, show the message */
        emailMessage.sender = [self.fromField stringValue];
        emailMessage.visible = YES;
        
            /* Test for errors */
        if ( [mail lastError] != nil )
            return;
                    
            /* create a new recipient and add it to the recipients list */
        MailToRecipient *theRecipient = [[[mail classForScriptingClass:@"to recipient"] alloc] initWithProperties:
                                            [NSDictionary dictionaryWithObjectsAndKeys:
                                                [self.toField stringValue], @"address",
                                                nil]];
        [emailMessage.toRecipients addObject: theRecipient];
        [theRecipient release];
        
            /* Test for errors */
        if ( [mail lastError] != nil )
            return;
        
            /* send the message */
        
        [emailMessage send];
        
        [emailMessage release];
        
        sentData += length_toSend;
        
        strContent = [strContent substringFromIndex: length_toSend];
        length_strContent = [strContent length];
        length_toSend = MIN(length_strContent, MAX_SENDING_MAIL_CONTENT_LENGTH);
        
        [self.progressIndicator setDoubleValue:sentData];

        if (length_toSend > 0)
        {
            [NSThread sleepForTimeInterval:20.0f];
        }
    }
    
    [self.progressIndicator setHidden:true];
}

@end
