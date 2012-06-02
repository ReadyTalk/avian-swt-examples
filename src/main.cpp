#include "stdlib.h"
#include "stdio.h"
#include "stdint.h"
#include "string.h"
#include "jni.h"

#ifdef __MINGW32__
#  define EXPORT __declspec(dllexport)
#else
#  define EXPORT __attribute__ ((visibility("default")))
#endif

#if defined __MINGW32__ && ! defined __x86_64__
#  define SYMBOL(x) binary_boot_jar_##x
#else
#  define SYMBOL(x) _binary_boot_jar_##x
#endif

// since we aren't linking against libstdc++, we must implement this
// ourselves:
extern "C" void __cxa_pure_virtual(void) { abort(); }

extern "C" {

  extern const uint8_t SYMBOL(start)[];
  extern const uint8_t SYMBOL(end)[];

  EXPORT const uint8_t*
  bootJar(unsigned* size)
  {
    *size = SYMBOL(end) - SYMBOL(start);
    return SYMBOL(start);
  }

} // extern "C"

extern "C" EXPORT int
avianMain(const char* bootLibrary, int ac, const char** av)
{
  JavaVMInitArgs vmArgs;
  vmArgs.version = JNI_VERSION_1_2;
  vmArgs.nOptions = 0;
  vmArgs.ignoreUnrecognized = JNI_TRUE;

  JavaVMOption options[2];
  vmArgs.options = options;

  options[vmArgs.nOptions++].optionString
    = const_cast<char*>("-Xbootclasspath:[bootJar]");

  char* buffer;
  if (bootLibrary) {
    const char* const property = "-Davian.bootstrap=";
    const unsigned propertySize = strlen(property);
    const unsigned bootLibrarySize = strlen(bootLibrary);
    buffer = static_cast<char*>(malloc(propertySize + bootLibrarySize + 1));
    memcpy(buffer, property, propertySize);
    memcpy(buffer + propertySize, bootLibrary, bootLibrarySize);
    buffer[propertySize + bootLibrarySize] = 0;

    vmArgs.options[vmArgs.nOptions++].optionString = buffer;
  } else {
    buffer = 0;
  }

  JavaVM* vm;
  void* env;
  JNI_CreateJavaVM(&vm, &env, &vmArgs);
  JNIEnv* e = static_cast<JNIEnv*>(env);

  jclass c = e->FindClass(MAIN_CLASS);
  if (not e->ExceptionCheck()) {
    jmethodID m = e->GetStaticMethodID(c, "main", "([Ljava/lang/String;)V");
    if (not e->ExceptionCheck()) {
      jclass stringClass = e->FindClass("java/lang/String");
      if (not e->ExceptionCheck()) {
        jobjectArray a = e->NewObjectArray(ac-1, stringClass, 0);
        if (not e->ExceptionCheck()) {
          for (int i = 1; i < ac; ++i) {
            e->SetObjectArrayElement(a, i-1, e->NewStringUTF(av[i]));
          }
          
          e->CallStaticVoidMethod(c, m, a);
        }
      }
    }
  }

  int exitCode = 0;
  if (e->ExceptionCheck()) {
    exitCode = -1;
    e->ExceptionDescribe();
  }

  vm->DestroyJavaVM();

  if (buffer) {
    free(buffer);
  }

  return exitCode;
}

int
main(int ac, const char** av)
{
  avianMain(0, ac, av);
}
