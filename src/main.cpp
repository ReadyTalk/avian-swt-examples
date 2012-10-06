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
#  define PREFIX(x) x
#else
#  define PREFIX(x) _##x
#endif

// since we aren't linking against libstdc++, we must implement this
// ourselves:
extern "C" void __cxa_pure_virtual(void) { abort(); }

extern "C" {

#ifdef BOOT_IMAGE
#  define BOOTIMAGE_BIN(x) PREFIX(binary_bootimage_bin_##x)

  extern const uint8_t BOOTIMAGE_BIN(start)[];
  extern const uint8_t BOOTIMAGE_BIN(end)[];

  EXPORT const uint8_t*
  bootimageBin(unsigned* size)
  {
    *size = BOOTIMAGE_BIN(end) - BOOTIMAGE_BIN(start);
    return BOOTIMAGE_BIN(start);
  }

#  define CODEIMAGE_BIN(x) PREFIX(binary_codeimage_bin_##x)

  extern const uint8_t CODEIMAGE_BIN(start)[];
  extern const uint8_t CODEIMAGE_BIN(end)[];

  EXPORT const uint8_t*
  codeimageBin(unsigned* size)
  {
    *size = CODEIMAGE_BIN(end) - CODEIMAGE_BIN(start);
    return CODEIMAGE_BIN(start);
  }

#  define RESOURCES_JAR(x) PREFIX(binary_resources_jar_##x)

  extern const uint8_t RESOURCES_JAR(start)[];
  extern const uint8_t RESOURCES_JAR(end)[];

  EXPORT const uint8_t*
  resourcesJar(unsigned* size)
  {
    *size = RESOURCES_JAR(end) - RESOURCES_JAR(start);
    return RESOURCES_JAR(start);
  }
#else // not BOOT_IMAGE
#  define BOOT_JAR(x) PREFIX(binary_boot_jar_##x)

  extern const uint8_t BOOT_JAR(start)[];
  extern const uint8_t BOOT_JAR(end)[];

  EXPORT const uint8_t*
  bootJar(unsigned* size)
  {
    *size = BOOT_JAR(end) - BOOT_JAR(start);
    return BOOT_JAR(start);
  }
#endif // not BOOT_IMAGE

} // extern "C"

extern "C" EXPORT int
avianMain(const char* bootLibrary, int ac, const char** av)
{
  JavaVMInitArgs vmArgs;
  vmArgs.version = JNI_VERSION_1_2;
  vmArgs.nOptions = 3;
  vmArgs.ignoreUnrecognized = JNI_TRUE;

  JavaVMOption options[vmArgs.nOptions];
  vmArgs.options = options;

  options[0].optionString = (char*) "-Davian.bootimage=bootimageBin";
  options[1].optionString = (char*) "-Davian.codeimage=codeimageBin";
  options[2].optionString = (char*) "-Xbootclasspath:[bootJar]:[resourcesJar]";

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
