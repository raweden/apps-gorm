/** <title>GormCustomClassInspector</title>

   <abstract>allow user to select custom classes</abstract>

   Copyright (C) 2002 Free Software Foundation, Inc.
   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: September 2002

   This file is part of GNUstep.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "GormCustomClassInspector.h"
#include "GormPrivate.h"
#include "GormClassManager.h"
#include "GormDocument.h"
#include "GormPrivate.h"

@implementation GormCustomClassInspector
+ (void) initialize
{
  if (self == [GormCustomClassInspector class])
    {
      // TBD
    }
}

- (id) init
{
  self = [super init];
  if (self != nil)
    {
      // initialize all member variables...
      _classManager = nil;
      _currentSelection = nil;
      _currentSelectionClassName = nil;
      _rowToSelect = 0;
      
      // load the gui...
      if (![NSBundle loadNibNamed: @"GormCustomClassInspector"
			    owner: self])
	{
	  NSLog(@"Could not open gorm GormCustomClassInspector");
	  return nil;
	}
    }
  return self;
}

- (void) _setCurrentSelectionClassName: (id)anobject
{
  NSString	 *className;
  NSMutableArray *classes = nil; 

  className = [_classManager customClassForObject: anobject];
  if ([className isEqualToString: @""]
    || className == nil)
    {
      className = NSStringFromClass([anobject class]);
    }

  ASSIGN(_currentSelectionClassName,
    [GormClassManager correctClassName: className]);
  ASSIGN(_parentClassName,
    [GormClassManager correctClassName: NSStringFromClass([anobject class])]);

  // get a list of all of the classes allowed and the class to be shown.
  classes = [NSMutableArray arrayWithObject: _parentClassName];
  [classes addObjectsFromArray: [_classManager allCustomSubclassesOf: _parentClassName]];

  // select the appropriate row in the inspector...
  _rowToSelect = [classes indexOfObject: className];
  _rowToSelect = (_rowToSelect != NSNotFound)?_rowToSelect:0;
}

- (void) setObject: (id)anObject
{
  [super setObject: anObject];
  _document = [(Gorm *)NSApp activeDocument];
  _classManager = [(Gorm *)NSApp classManager];
  _currentSelection = anObject;

  [browser loadColumnZero];  
  NSDebugLog(@"Current selection %@", _currentSelection);
  [self _setCurrentSelectionClassName: _currentSelection];
  
  // select the class...
  [browser selectRow: _rowToSelect inColumn: 0];
  [browser setNeedsDisplay: YES];

}


- (void) awakeFromNib
{
  [browser setTarget: self];
  [browser setAction: @selector(select:)];
  [browser reloadColumn: 0];
}

- (void) _replaceCellClassForObject: (id)obj
			  className: (NSString *)name
{
  if([name isEqualToString: @"NSSecureTextField"] || 
     [name isEqualToString: @"NSTextField"])
    {
      NSCell *cell = [obj cell];
      NSCell *newCell = nil;

      // instantiate the cell...
      if([name isEqualToString: @"NSSecureTextField"])
	{
	  newCell = [[NSSecureTextFieldCell alloc] init];
	}
      else if([name isEqualToString: @"NSTextField"])
	{
	  newCell = [[NSTextFieldCell alloc] init];
	}

      // copy everything from the old cell...
      [newCell setFont: [cell font]];
      [newCell setEnabled: [cell isEnabled]];
      [newCell setEditable: [cell isEditable]];
      // [newCell setRichText: [cell isRichText]];
      [newCell setImportsGraphics: [cell importsGraphics]];
      [newCell setShowsFirstResponder: [cell showsFirstResponder]];
      [newCell setRefusesFirstResponder: [cell refusesFirstResponder]];
      [newCell setBordered: [cell isBordered]];
      [newCell setBezeled: [cell isBezeled]];
      [newCell setScrollable: [cell isScrollable]];
      [newCell setSelectable: [cell isSelectable]];
      [newCell setState: [cell state]];

      [object setCell: newCell];
    }
}

- (void) select: (id)sender
{
  NSCell *cell = [browser selectedCellInColumn: 0];
  NSString *stringValue = [NSString stringWithString: [cell stringValue]];
  NSString *nameForObject = [_document nameForObject: _currentSelection];
  NSString *classForObject = [GormClassManager correctClassName: NSStringFromClass([_currentSelection class])];

  NSDebugLog(@"selected = %@, class = %@",stringValue,nameForObject);

  /* add or remove the mapping as necessary. */
  if(nameForObject != nil)
    {
      if (![stringValue isEqualToString: classForObject])
	{
	  [_classManager setCustomClass: stringValue
			 forObject: nameForObject];
	}
      else
	{
	  [_classManager removeCustomClassForObject: nameForObject];
	}

      [self _replaceCellClassForObject: [self object]
	    className: stringValue];

    }
  else
    NSLog(@"name for object %@ returned as nil",_currentSelection);
}

// Browser delegate
- (void)    browser: (NSBrowser *)sender 
createRowsForColumn: (int)column
	   inMatrix: (NSMatrix *)matrix
{
  if (_parentClassName != nil)
    {
      NSMutableArray	*classes;
      NSEnumerator	*e = nil;
      NSString		*class = nil;
      NSBrowserCell	*cell = nil;
      int		i = 0;
      
      classes = [NSMutableArray arrayWithObject: _parentClassName];
      // get a list of all of the classes allowed and the class to be shown.
      [classes addObjectsFromArray:
	[_classManager allCustomSubclassesOf: _parentClassName]];
      
      // enumerate through the classes...
      e = [classes objectEnumerator];
      while ((class = [e nextObject]) != nil)
	{
	  if ([class isEqualToString: _currentSelectionClassName])
	    {
	      _rowToSelect = i;
	    }
	  [matrix insertRow: i withCells: nil];
	  cell = [matrix cellAtRow: i column: 0];
	  [cell setLeaf: YES];
	  i++;
	  [cell setStringValue: class];
	}
    }
}

- (NSString*) browser: (NSBrowser*)sender 
	titleOfColumn: (int)column
{
  NSDebugLog(@"Delegate called");
  return @"Class";
}

- (void) browser: (NSBrowser *)sender 
 willDisplayCell: (id)cell 
	   atRow: (int)row 
	  column: (int)column
{
}

- (BOOL) browser: (NSBrowser *)sender 
   isColumnValid: (int)column
{
  return YES;
}
@end
