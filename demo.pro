# our entry point:

-keep class org.eclipse.swt.examples.controlexample.ControlExample {
   public static void main(java.lang.String[]);
 }


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
 }
-keepclassmembers class org.eclipse.swt.browser.MozillaDelegate {
   *** eventProc(...);
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
 }
-keepclassmembers class org.eclipse.swt.internal.mozilla.XPCOMObject {
   <methods>;
 }
-keepclassmembers class org.eclipse.swt.widgets.Display {
   *** fixedClassInitProc(...);
   *** fixedMapProc(...);
   *** rendererClassInitProc(...);
   *** rendererRenderProc(...);
   *** rendererGetSizeProc(...);
   *** eventProc(...);
   *** filterProc(...);
   *** windowProc(...);
   *** timerProc(...);
   *** windowTimerProc(...);
   *** mouseHoverProc(...);
   *** caretProc(...);
   *** menuPositionProc(...);
   *** sizeAllocateProc(...);
   *** sizeRequestProc(...);
   *** shellMapProc(...);
   *** treeSelectionProc(...);
   *** cellDataProc(...);
   *** setDirectionProc(...);
   *** allChildrenProc(...);
   *** checkIfEventProc(...);
   *** idleProc(...);
   *** styleSetProc(...);
 }
-keepclassmembers class org.eclipse.swt.accessibility.AccessibleFactory {
   <methods>;
 }
-keepclassmembers class org.eclipse.swt.accessibility.AccessibleObject {
   <methods>;
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
