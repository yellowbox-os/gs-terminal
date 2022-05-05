/*
   Project: vim

   Copyright (C) 2022 Free Software Foundation

   Author: Ondrej Florian,,,

   Created: 2022-04-19 08:52:45 +0200 by oflorian

   This application is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This application is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/

#import "VimTerminalView.h"

@implementation VimTerminalView

- (id) initWithFrame:(NSRect) frame {
  [super initWithFrame:frame];

  return self;
}

//ignore mouse selection, use vim selection commands instead
- (void)_setSelection:(struct selection_range)s {
}

- (void) runVimWithFile:(NSString*) path {
  NSMutableArray* args = [NSMutableArray new];
  NSString* td = NSTemporaryDirectory();
  NSString* cf = [td stringByAppendingString:[NSString stringWithFormat:@"/VimGS-copy.%lx", [self hash]]];
  NSString* pf = [td stringByAppendingString:[NSString stringWithFormat:@"/VimGS-paste.%lx", [self hash]]];

  copyDataFile = RETAIN(cf);
  pasteDataFile = RETAIN(pf);

  [args addObject:cf];
  [args addObject:pf];

  if (path) [args addObject:path];

  NSString* vp = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"vimview"];
  NSString* exec = [vp stringByAppendingPathComponent:@"start.sh"];

  [self runProgram:exec
     withArguments:args
      initialInput:nil];

}

- (void) help:(id) sender {
  [self ts_sendCString:"\e\e:help\r"];
}

- (void) saveDocument:(id) sender {
  [self ts_sendCString:"\e\e:w\r"];
}

- (void) moveLineDown:(id) sender {
  [self ts_sendCString:"\e\ej"];
}

- (void) moveLineUp:(id) sender {
  [self ts_sendCString:"\e\ek"];
}

- (void) selectAll:(id) sender {
  [self ts_sendCString:"\e\eggVG"];
}

- (void) undo:(id) sender {
  [self ts_sendCString:"\e\eu"];
}

- (void) cut:(id) sender {
  [self ts_sendCString:"\e[1;0X~"];
}

- (void) copy:(id) sender {
  [self ts_sendCString:"\e[1;0C~"];
}

- (void) paste:(id) sender {
  NSPasteboard* pb = [NSPasteboard generalPasteboard];
  NSString* txt = [pb stringForType:NSStringPboardType];
  if (txt) {
    [txt writeToFile:pasteDataFile atomically:NO];
    [self ts_sendCString:"\e[1;0P~"];
  }
}

- (void) quit:(id) sender {
  [self ts_sendCString:"\e\e:q\r"];
}

- (void)ts_handleXOSC:(NSString *)new_cmd {
  if ([new_cmd isEqualToString:@"COPY"]) {
    NSString* txt = [NSString stringWithContentsOfFile:copyDataFile];
    NSPasteboard* pb = [NSPasteboard generalPasteboard];

    [pb declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
    [pb setString:txt forType:NSStringPboardType];
  }
}


- (void) goToLine:(NSInteger) line {
  NSString* txt = [NSString stringWithFormat:@"\e\e:%ld\r", line];
  [self ts_sendCString:[txt UTF8String]];
}

- (void) dealloc {
  RELEASE(copyDataFile);
  RELEASE(pasteDataFile);

  [super dealloc];
}

@end
