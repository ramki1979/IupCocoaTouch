/** \file
 * \brief IupDialog class
 *
 * See Copyright Notice in "iup.h"
 */

#import <UIKit/UIKit.h>
#import <objc/runtime.h>


#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <memory.h>
#include <stdarg.h>
#include <limits.h>
#include <time.h>

#include "iup.h"
#include "iupcbs.h"

#include "iup_class.h"
#include "iup_object.h"
#include "iup_layout.h"
#include "iup_dlglist.h"
#include "iup_attrib.h"
#include "iup_drv.h"
#include "iup_drvfont.h"
#include "iup_drvinfo.h"
#include "iup_focus.h"
#include "iup_str.h"
#define _IUPDLG_PRIVATE
#include "iup_dialog.h"
#include "iup_image.h"
#include "iup_assert.h"

#include "iupcocoatouch_drv.h"
#include "IupAppDelegateProtocol.h"
#include "IupLaunchViewController.h"

/*
@interface UIWindow () 
@property(readwrite, unsafe_unretained) Ihandle* iupIhandle;
@end

@implementation UIWindow
@synthesize iupIhandle = _iupIhandle;
@end
 */
#if 0
@interface IupcocoaTouchWindowDelegate : NSObject <UIWindowDelegate>
- (BOOL) windowShouldClose:(id)the_sender;
- (NSSize) windowWillResize:(UIWindow*)the_sender toSize:(NSSize)frame_size;
@end

static void cocoaTouchCleanUpWindow(Ihandle* ih)
{
	UIWindow* the_window = (__bridge UIWindow*)ih->handle;
	[the_window close];
	
	IupcocoaTouchWindowDelegate* window_delegate = [the_window delegate];
	[the_window setDelegate:nil];
	[window_delegate release];
	
	[the_window release];
}



@implementation IupcocoaTouchWindowDelegate

- (BOOL) windowShouldClose:(id)the_sender
{
	// I'm using objc_setAssociatedObject/objc_getAssociatedObject because it allows me to avoid making subclasses just to hold ivars. And category extension isn't working for some reason...UIWindow might be too big/complicated and is expecting me to define Apple stuff.
	
	Ihandle* ih = (Ihandle*)objc_getAssociatedObject(the_sender, IHANDLE_ASSOCIATED_OBJ_KEY);
	
	/* even when ACTIVE=NO the dialog gets this evt */
#if 0
	if (!iupdrvIsActive(ih)) // not implemented yet
	{
		return YES;
	}
#endif
	
	Icallback callback_function = IupGetCallback(ih, "CLOSE_CB");
	if(callback_function)
	{
		int ret = callback_function(ih);
		if (ret == IUP_IGNORE)
		{
			return NO;
		}
		if (ret == IUP_CLOSE)
		{
			IupExitLoop();
		}
	}

	// I think??? we need to hide and not destroy because the user is supposed to call IupDestroy explicitly
	IupHide(ih); /* default: close the window */

//	IupDestroy(ih);
	
	return YES; /* do not propagate */
	
}

- (NSSize) windowWillResize:(UIWindow*)the_sender toSize:(NSSize)frame_size
{
	// I'm using objc_setAssociatedObject/objc_getAssociatedObject because it allows me to avoid making subclasses just to hold ivars. And category extension isn't working for some reason...UIWindow might be too big/complicated and is expecting me to define Apple stuff.
	
	Ihandle* ih = (Ihandle*)objc_getAssociatedObject(the_sender, IHANDLE_ASSOCIATED_OBJ_KEY);
	
	/* even when ACTIVE=NO the dialog gets this evt */
#if 0
	if (!iupdrvIsActive(ih)) // not implemented yet
	{
		return YES;
	}
#endif
	
//	iupdrvDialogGetSize(ih, NULL, &(ih->currentwidth), &(ih->currentheight));

	ih->currentwidth = frame_size.width;
	ih->currentheight = frame_size.height;
	
	return frame_size;
	
}


@end

#endif
/****************************************************************
 Utilities
 ****************************************************************/

int iupdrvDialogIsVisible(Ihandle* ih)
{
#if 0
//	return iupdrvIsVisible(ih);
	UIWindow* the_window = (UIWindow*)ih->handle;
	int ret_val = (int)[the_window isVisible];
	return ret_val;
#else
	return 1;
#endif
}


void iupdrvDialogGetSize(Ihandle* ih, InativeHandle* handle, int *w, int *h)
{
	UIWindow* the_window = (UIWindow*)ih->handle;
	CGRect the_rect = [the_window frame];
	
	if (w) *w = the_rect.size.width;
	if (h) *h = the_rect.size.height;
}

void iupdrvDialogSetVisible(Ihandle* ih, int visible)
{
#if 0
	UIWindow* the_window = (UIWindow*)ih->handle;

	if(visible)
	{
		[the_window makeKeyAndOrderFront:nil];

	}
	else
	{

		[the_window orderOut:nil];
	}
#endif
}

void iupdrvDialogGetPosition(Ihandle *ih, InativeHandle* handle, int *x, int *y)
{
#if 0
	UIWindow* the_window = (UIWindow*)ih->handle;
	CGRect the_rect = [the_window frame];
	
	if (x) *x = the_rect.origin.x;
	if (y) *y = iupcocoaTouchComputeIupScreenHeightFromCartesian(the_rect.origin.y);
#endif
}

void iupdrvDialogSetPosition(Ihandle *ih, int x, int y)
{
#if 0
	UIWindow* the_window = (UIWindow*)ih->handle;
	CGRect the_rect = [the_window frame];
	
	int inverted_height = iupcocoaTouchComputeCartesianScreenHeightFromIup(y);

	[the_window setFrame:NSMakeRect(x, inverted_height, the_rect.size.width , the_rect.size.height) display:YES];
#endif
}


void iupdrvDialogGetDecoration(Ihandle* ih, int *border, int *caption, int *menu)
{
}

int iupdrvDialogSetPlacement(Ihandle* ih)
{
#if 0
	char* placement;
	
	UIWindow* the_window = (UIWindow*)ih->handle;
	CGRect the_rect = [the_window frame];
	
	
	int old_state = ih->data->show_state;
	ih->data->show_state = IUP_SHOW;
	
	if (iupAttribGetBoolean(ih, "FULLSCREEN"))
	{

		NSUInteger masks = [the_window styleMask];
		if ( masks & NSFullScreenWindowMask)
		{
			// Do something
		}
		else
		{
			[the_window toggleFullScreen:nil];
		}
		
		
		return 1;
	}
	
	placement = iupAttribGet(ih, "PLACEMENT");
	if (!placement)
	{
		if (old_state == IUP_MAXIMIZE || old_state == IUP_MINIMIZE)
			ih->data->show_state = IUP_RESTORE;
		
//		gtk_window_unmaximize((GtkWindow*)ih->handle);
//		gtk_window_deiconify((GtkWindow*)ih->handle);
		return 0;
	}
	
	if (iupStrEqualNoCase(placement, "MINIMIZED"))
	{
//		ih->data->show_state = IUP_MINIMIZE;
//		gtk_window_iconify((GtkWindow*)ih->handle);
	}
	else if (iupStrEqualNoCase(placement, "MAXIMIZED"))
	{
//		ih->data->show_state = IUP_MAXIMIZE;
//		gtk_window_maximize((GtkWindow*)ih->handle);
	}
	else if (iupStrEqualNoCase(placement, "FULL"))
	{
#if 0
		int width, height, x, y;
		int border, caption, menu;
		iupdrvDialogGetDecoration(ih, &border, &caption, &menu);
		
		/* position the decoration outside the screen */
		x = -(border);
		y = -(border+caption+menu);
		
		/* the dialog client area will cover the task bar */
		iupdrvGetFullSize(&width, &height);
		
		height += menu; /* menu is inside the client area. */
		
		/* set the new size and position */
		/* The resize evt will update the layout */
		gtk_window_move((GtkWindow*)ih->handle, x, y);
		gtk_window_resize((GtkWindow*)ih->handle, width, height);
		
		if (old_state == IUP_MAXIMIZE || old_state == IUP_MINIMIZE)
			ih->data->show_state = IUP_RESTORE;
#endif
	}
	
	iupAttribSet(ih, "PLACEMENT", NULL); /* reset to NORMAL */
	

#endif
	return 1;
}


/****************************************************************
 Callbacks and Events
 ****************************************************************/

static int cocoaTouchDialogSetTitleAttrib(Ihandle* ih, const char* value)
{
	UIWindow* the_window = (UIWindow*)ih->handle;

	if(value)
	{
		NSString* ns_string = [NSString stringWithUTF8String:value];

		[the_window setTitle:ns_string];

	}
	else
	{
		[the_window setTitle:nil];

	}

	
	return 1;
}

static int cocoaTouchDialogMapMethod(Ihandle* ih)
{
	UIResponder<IupAppDelegateProtocol>* app_delegate = (UIResponder<IupAppDelegateProtocol>*)[[UIApplication sharedApplication] delegate];
	
	UIWindow* the_window = [app_delegate currentWindow];
	
	UIViewController* root_view_controller = [the_window rootViewController];
	
	// If we still have our placeholder class, time to replace it.
	if([root_view_controller isKindOfClass:[IupLaunchViewController class]])
	{
		UIViewController* new_view_controller = [[[UIViewController alloc] init] autorelease];
		CGRect window_bounds = [[UIScreen mainScreen] bounds];
		UIView* root_view = [[UIView alloc] initWithFrame:window_bounds];
		[root_view setBackgroundColor:[UIColor redColor]];
		[new_view_controller setView:root_view];

		
		
		UINavigationController* navigation_controller = [[[UINavigationController alloc] initWithRootViewController:new_view_controller] autorelease];
		
		[the_window setRootViewController:navigation_controller];
		
		ih->handle = [new_view_controller retain];
		
	}
	else
	{
		UIViewController* new_view_controller = [[[UIViewController alloc] init] autorelease];
		CGRect window_bounds = [[UIScreen mainScreen] bounds];
		UIView* root_view = [[UIView alloc] initWithFrame:window_bounds];
		[root_view setBackgroundColor:[UIColor greenColor]];
		[new_view_controller setView:root_view];
	
		[root_view_controller pushViewController:new_view_controller animated:YES];

		ih->handle = [new_view_controller retain];

	}
	
#if 0
	iupAttribSet(ih, "RASTERSIZE", "500x400");
	
	UIWindow* the_window = [[UIWindow alloc] initWithContentRect:NSMakeRect(0, 0, 200, 200)
													styleMask:NSTitledWindowMask|NSClosableWindowMask|NSResizableWindowMask|NSMiniaturizableWindowMask backing:NSBackingStoreBuffered defer:NO];

	// We are manually managing the memory, so don't let the window release itself
	[the_window setReleasedWhenClosed:NO];
	
	[the_window cascadeTopLeftFromPoint:NSMakePoint(20,20)];
//	[window setTitle:appName];
	[the_window makeKeyAndOrderFront:nil];
	
	ih->handle = (__unsafe_unretained void*)the_window;
	
	IupcocoaTouchWindowDelegate* window_delegate = [[IupcocoaTouchWindowDelegate alloc] init];
//	[window setIupIhandle:ih];
	
	// I'm using objc_setAssociatedObject/objc_getAssociatedObject because it allows me to avoid making subclasses just to hold ivars. And category extension isn't working for some reason...UIWindow might be too big/complicated and is expecting me to define Apple stuff.
	objc_setAssociatedObject(the_window, IHANDLE_ASSOCIATED_OBJ_KEY, (id)ih, OBJC_ASSOCIATION_ASSIGN);

	
	[the_window setDelegate:window_delegate];
	
	

//	ih->currentwidth = 200;
//	ih->currentheight = 200;
#endif
	return IUP_NOERROR;

}

static void cocoaTouchDialogUnMapMethod(Ihandle* ih)
{

	UIViewController* view_controller = ih->handle;
	
	[view_controller release];
	

//	cocoaTouchCleanUpWindow(ih);
	
}

static void cocoaTouchDialogLayoutUpdateMethod(Ihandle* ih)
{
#if 0
#if 0
	if (ih->data->ignore_resize)
		return;
	
	ih->data->ignore_resize = 1;
	
	/* for dialogs the position is not updated here */
	SetWindowPos(ih->handle, 0, 0, 0, ih->currentwidth, ih->currentheight,
				 SWP_NOMOVE|SWP_NOZORDER|SWP_NOACTIVATE|SWP_NOOWNERZORDER|SWP_NOSENDCHANGING);
	
	ih->data->ignore_resize = 0;
#endif
	
	UIWindow* the_window = (UIWindow*)ih->handle;
//	CGRect the_rect = [the_window frame];
	
	int inverted_height = iupcocoaTouchComputeCartesianScreenHeightFromIup(ih->y);

	[the_window setFrame:NSMakeRect(ih->x, inverted_height, ih->currentwidth , ih->currentheight) display:YES];
#endif
}



void iupdrvDialogInitClass(Iclass* ic)
{
	/* Driver Dependent Class methods */
	ic->Map = cocoaTouchDialogMapMethod;
	ic->UnMap = cocoaTouchDialogUnMapMethod;
	ic->LayoutUpdate = cocoaTouchDialogLayoutUpdateMethod;

#if 0
	ic->LayoutUpdate = gtkDialogLayoutUpdateMethod;
	ic->GetInnerNativeContainerHandle = gtkDialogGetInnerNativeContainerHandleMethod;
	ic->SetChildrenPosition = gtkDialogSetChildrenPositionMethod;
	
	/* Callback Windows and GTK Only */
	iupClassRegisterCallback(ic, "TRAYCLICK_CB", "iii");
	
	/* Driver Dependent Attribute functions */
#ifndef GTK_MAC
#ifdef WIN32
	iupClassRegisterAttribute(ic, "HWND", iupgtkGetNativeWindowHandle, NULL, NULL, NULL, IUPAF_NO_STRING|IUPAF_NO_INHERIT);
#else
	iupClassRegisterAttribute(ic, "XWINDOW", iupgtkGetNativeWindowHandle, NULL, NULL, NULL, IUPAF_NO_INHERIT|IUPAF_NO_STRING);
#endif
#endif
	
	/* Visual */
	iupClassRegisterAttribute(ic, "BGCOLOR", NULL, iupdrvBaseSetBgColorAttrib, "DLGBGCOLOR", NULL, IUPAF_DEFAULT);  /* force new default value */
	
	/* Base Container */
	iupClassRegisterAttribute(ic, "CLIENTSIZE", gtkDialogGetClientSizeAttrib, iupDialogSetClientSizeAttrib, NULL, NULL, IUPAF_NO_SAVE|IUPAF_NO_DEFAULTVALUE|IUPAF_NO_INHERIT);  /* dialog is the only not read-only */
	iupClassRegisterAttribute(ic, "CLIENTOFFSET", gtkDialogGetClientOffsetAttrib, NULL, NULL, NULL, IUPAF_NO_DEFAULTVALUE|IUPAF_READONLY|IUPAF_NO_INHERIT);
#endif
	
	
	/* Special */
	iupClassRegisterAttribute(ic, "TITLE", NULL, cocoaTouchDialogSetTitleAttrib, NULL, NULL, IUPAF_NO_DEFAULTVALUE|IUPAF_NO_INHERIT);
	
	
#if 0
	/* IupDialog only */
	iupClassRegisterAttribute(ic, "BACKGROUND", NULL, gtkDialogSetBackgroundAttrib, IUPAF_SAMEASSYSTEM, "DLGBGCOLOR", IUPAF_NO_INHERIT);
	iupClassRegisterAttribute(ic, "ICON", NULL, gtkDialogSetIconAttrib, NULL, NULL, IUPAF_IHANDLENAME|IUPAF_NO_INHERIT);
	iupClassRegisterAttribute(ic, "FULLSCREEN", NULL, gtkDialogSetFullScreenAttrib, NULL, NULL, IUPAF_WRITEONLY|IUPAF_NO_INHERIT);
	iupClassRegisterAttribute(ic, "MINSIZE", NULL, gtkDialogSetMinSizeAttrib, IUPAF_SAMEASSYSTEM, "1x1", IUPAF_NO_INHERIT);
	iupClassRegisterAttribute(ic, "MAXSIZE", NULL, gtkDialogSetMaxSizeAttrib, IUPAF_SAMEASSYSTEM, "65535x65535", IUPAF_NO_INHERIT);
	iupClassRegisterAttribute(ic, "SAVEUNDER", NULL, NULL, NULL, NULL, IUPAF_NOT_SUPPORTED|IUPAF_NO_INHERIT);  /* saveunder not supported in GTK */
	
	/* IupDialog Windows and GTK Only */
	iupClassRegisterAttribute(ic, "ACTIVEWINDOW", gtkDialogGetActiveWindowAttrib, NULL, NULL, NULL, IUPAF_READONLY|IUPAF_NO_INHERIT);
	iupClassRegisterAttribute(ic, "TOPMOST", NULL, gtkDialogSetTopMostAttrib, NULL, NULL, IUPAF_WRITEONLY|IUPAF_NO_INHERIT);
	iupClassRegisterAttribute(ic, "DIALOGHINT", NULL, NULL, NULL, NULL, IUPAF_NO_INHERIT);
#if GTK_CHECK_VERSION(2, 12, 0)
	iupClassRegisterAttribute(ic, "OPACITY", NULL, gtkDialogSetOpacityAttrib, NULL, NULL, IUPAF_NO_INHERIT);
	iupClassRegisterAttribute(ic, "OPACITYIMAGE", NULL, gtkDialogSetOpacityImageAttrib, NULL, NULL, IUPAF_NO_INHERIT);
#endif
#if GTK_CHECK_VERSION(2, 10, 0)
	iupClassRegisterAttribute(ic, "TRAY", NULL, gtkDialogSetTrayAttrib, NULL, NULL, IUPAF_NO_INHERIT);
	iupClassRegisterAttribute(ic, "TRAYIMAGE", NULL, gtkDialogSetTrayImageAttrib, NULL, NULL, IUPAF_NO_INHERIT);
	iupClassRegisterAttribute(ic, "TRAYTIP", NULL, gtkDialogSetTrayTipAttrib, NULL, NULL, IUPAF_NO_INHERIT);
	iupClassRegisterAttribute(ic, "TRAYTIPMARKUP", NULL, NULL, IUPAF_SAMEASSYSTEM, NULL, IUPAF_NOT_MAPPED);
#endif
	
	/* Not Supported */
	iupClassRegisterAttribute(ic, "BRINGFRONT", NULL, NULL, NULL, NULL, IUPAF_NOT_SUPPORTED|IUPAF_NO_INHERIT);
	iupClassRegisterAttribute(ic, "COMPOSITED", NULL, NULL, NULL, NULL, IUPAF_NOT_SUPPORTED|IUPAF_NOT_MAPPED);
	iupClassRegisterAttribute(ic, "CONTROL", NULL, NULL, NULL, NULL, IUPAF_NOT_SUPPORTED|IUPAF_NO_INHERIT);
	iupClassRegisterAttribute(ic, "HELPBUTTON", NULL, NULL, NULL, NULL, IUPAF_NOT_SUPPORTED|IUPAF_NO_INHERIT);
	iupClassRegisterAttribute(ic, "TOOLBOX", NULL, NULL, NULL, NULL, IUPAF_NOT_SUPPORTED|IUPAF_NO_INHERIT);
	iupClassRegisterAttribute(ic, "MDIFRAME", NULL, NULL, NULL, NULL, IUPAF_NOT_SUPPORTED|IUPAF_NO_INHERIT);
	iupClassRegisterAttribute(ic, "MDICLIENT", NULL, NULL, NULL, NULL, IUPAF_NOT_SUPPORTED|IUPAF_NO_INHERIT);
	iupClassRegisterAttribute(ic, "MDIMENU", NULL, NULL, NULL, NULL, IUPAF_NOT_SUPPORTED|IUPAF_NO_INHERIT);
	iupClassRegisterAttribute(ic, "MDICHILD", NULL, NULL, NULL, NULL, IUPAF_NOT_SUPPORTED|IUPAF_NO_INHERIT);
#endif
	
}
