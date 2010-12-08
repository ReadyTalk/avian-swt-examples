# browser classes are needed as the browser is selected via reflection
-keep class * extends org.eclipse.swt.browser.WebBrowser

-keepclassmembers class org.eclipse.swt.browser.MozillaDelegate {
   *** eventProc(...);
   *** eventProc3(...);
 }

-keepclassmembers class org.eclipse.swt.browser.Safari {
   *** eventProc3(...);
   *** eventProc7(...);
   *** browserProc(...);
 }
