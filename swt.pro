# many classes in SWT check package names in their constructors to
# prevent subclassing by classes outside SWT.  Rather than list them
# all here, we simply preserve all class names in SWT from
# obfuscation.

-keepnames class org.eclipse.swt.**


# the fields of many classes in org.eclipse.swt.internal are used from
# native code.

-keepclassmembernames class org.eclipse.swt.internal.** {
   <fields>;
 }
-keepclassmembers class org.eclipse.swt.internal.** {
   <fields>;
 }


# the following methods are called via reflection:

-keepclassmembers class org.eclipse.swt.graphics.Device {
   *** XErrorProc(...);
   *** XIOErrorProc(...);
   *** logProc(...);
   *** EnumFontFamProc(...);
   *** drawPatternProc(...);
   *** axialShadingProc(...);
   *** releaseProc(...);
 }
-keepclassmembers class org.eclipse.swt.graphics.GC {
   *** convertRgn(...);
 }
-keepclassmembers class org.eclipse.swt.graphics.Path {
   *** newPathProc(...);
   *** lineProc(...);
   *** curveProc(...);
   *** closePathProc(...);
   *** applierFunc(...);
 }
-keepclassmembers class org.eclipse.swt.graphics.TextLayout {
   *** regionToRects(...);
 }
-keepclassmembers class org.eclipse.swt.browser.MozillaDelegate {
   *** eventProc(...);
   *** eventProc3(...);
 }
-keepclassmembers class org.eclipse.swt.browser.Safari {
   *** eventProc3(...);
   *** eventProc7(...);
 }
-keepclassmembers class org.eclipse.swt.printing.Printer {
   *** GtkPrinterFunc_List(...);
   *** GtkPrinterFunc_Default(...);
   *** GtkPrinterFunc_FindNamedPrinter(...);
 }
-keepclassmembers class org.eclipse.swt.printing.PrintDialog {
   *** GtkPrintSettingsFunc(...);
 }
-keepclassmembers class org.eclipse.swt.dnd.DragSource {
   *** DragGetData(...);
   *** DragEnd(...);
   *** DragDataDelete(...);
   *** DragSendDataProc(...);
 }
-keepclassmembers class org.eclipse.swt.dnd.ClipboardProxy {
   *** getFunc(...);
   *** clearFunc(...);
 }
-keepclassmembers class org.eclipse.swt.dnd.DropTarget {
   *** Drag_Motion(...);
   *** Drag_Leave(...);
   *** Drag_Data_Received(...);
   *** Drag_Drop(...);
   *** DragTrackingHandler(...);
   *** DragReceiveHandler(...);
 }
-keepclassmembers class org.eclipse.swt.dnd.TableDropTargetEffect {
   *** AcceptDragProc(...);
 }
-keepclassmembers class org.eclipse.swt.dnd.TreeDropTargetEffect {
   *** AcceptDragProc(...);
 }
-keepclassmembers class org.eclipse.swt.internal.mozilla.XPCOMObject {
   <methods>;
 }
-keepclassmembers class org.eclipse.swt.widgets.Display {
   *** accessibilityProc(...);
   *** actionProc(...);
   *** allChildrenProc(...);
   *** appearanceProc(...);
   *** appleEventProc(...);
   *** caretProc(...);
   *** cellDataProc(...);
   *** checkIfEventProc(...);
   *** clockProc(...);
   *** colorProc(...);
   *** commandProc(...);
   *** controlProc(...);
   *** coreEventProc(...);
   *** drawItemProc(...);
   *** embeddedProc(...);
   *** emissionProc(...);
   *** eventProc(...);
   *** filterProc(...);
   *** fixedClassInitProc(...);
   *** fixedMapProc(...);
   *** fixedSizeAllocateProc(...);
   *** foregroundIdleProc(...);
   *** helpProc(...);
   *** hitTestProc(...);
   *** idleProc(...);
   *** itemCompareProc(...);
   *** itemDataProc(...);
   *** itemNotificationProc(...);
   *** keyboardProc(...);
   *** menuPositionProc(...);
   *** menuProc(...);
   *** messageProc(...);
   *** monitorEnumProc(...);
   *** mouseHoverProc(...);
   *** mouseProc(...);
   *** msgFilterProc(...);
   *** observerProc(...);
   *** pollingProc(...);
   *** releaseDataProc(...);
   *** rendererClassInitProc(...);
   *** rendererGetSizeProc(...);
   *** rendererRenderProc(...);
   *** searchProc(...);
   *** setDirectionProc(...);
   *** shellMapProc(...);
   *** sizeAllocateProc(...);
   *** sizeRequestProc(...);
   *** sourceProc(...);
   *** styleSetProc(...);
   *** textInputProc(...);
   *** timerProc(...);
   *** trackingProc(...);
   *** trayItemProc(...);
   *** treeSelectionProc(...);
   *** windowProc(...);
   *** windowTimerProc(...);
   *** pangoLayoutNewProc(...);
   *** applicationProc(...);
   *** dialogProc(...);
   *** fieldEditorProc(...);
   *** cursorSetProc(...);
 }
-keepclassmembers class org.eclipse.swt.widgets.FontDialog {
   *** fontProc(...);
 }
-keepclassmembers class org.eclipse.swt.accessibility.AccessibleFactory {
   <methods>;
 }
-keepclassmembers class org.eclipse.swt.accessibility.AccessibleObject {
   <methods>;
 }
-keepclassmembers class org.eclipse.swt.graphics.FontData {
   *** EnumLocalesProc(...);
 }
-keepclassmembers class org.eclipse.swt.internal.BidiUtil {
   *** windowProc(...);
   *** EnumSystemLanguageGroupsProc(...);
 }
-keepclassmembers class org.eclipse.swt.internal.ole.win32.COMObject {
   <methods>;
 }
-keepclassmembers class org.eclipse.swt.widgets.ColorDialog {
   *** CCHookProc(...);
 }
-keepclassmembers class org.eclipse.swt.widgets.Tree {
   *** CompareFunc(...);
 }
-keepclassmembers class org.eclipse.swt.widgets.Tracker {
   *** transparentProc(...);
 }
-keepclassmembers class org.eclipse.swt.widgets.Display {
   *** monitorEnumProc(...);
   *** embeddedProc(...);
   *** windowProc(...);
   *** messageProc(...);
   *** msgFilterProc(...);
   *** foregroundIdleProc(...);
 }
-keepclassmembers class org.eclipse.swt.widgets.Composite {
   *** getMsgProc(...);
 }
-keepclassmembers class org.eclipse.swt.widgets.FileDialog {
   *** OFNHookProc(...);
   *** filterProc(...);
   *** eventProc(...);
 }
-keepclassmembers class org.eclipse.swt.widgets.Combo {
   *** CBTProc(...);
 }
-keepclassmembers class org.eclipse.swt.widgets.DirectoryDialog {
   *** BrowseCallbackProc(...);
 }
-keepclassmembers class org.eclipse.swt.ole.win32.OleFrame {
   *** getMsgProc(...);
 }

# image file format parsing is done via reflection.

-keep class org.eclipse.swt.internal.image.*FileFormat {
   <init>();
 }


# options

-repackageclasses ''
-allowaccessmodification
-overloadaggressively
-dontpreverify
#-dontobfuscate

# ignore complaints about missing classes which we never actually use:
-ignorewarnings
