#include "stdlib.h"
#include "stdio.h"
#include "stdint.h"
#include "string.h"
#include "jni.h"

#ifdef __MINGW32__
#  define EXPORT __declspec(dllexport)
#  define SYMBOL(x) binary_demo_jar_##x
#else
#  define EXPORT __attribute__ ((visibility("default")))
#  define SYMBOL(x) _binary_demo_jar_##x
#endif

#ifndef __APPLE__
extern "C" {

  extern const uint8_t SYMBOL(start)[];
  extern const uint8_t SYMBOL(size)[];

  EXPORT const uint8_t*
  demoJar(unsigned* size)
  {
    *size = reinterpret_cast<uintptr_t>(SYMBOL(size));
    return SYMBOL(start);
  }

} // extern "C"
#endif

int
main(int ac, const char** av)
{
  JDK1_1InitArgs vmArgs;
  vmArgs.version = 0x00010001;
  JNI_GetDefaultJavaVMInitArgs(&vmArgs);

#ifdef __APPLE__
  vmArgs.classpath = const_cast<char*>("demo.jar");
#else
  vmArgs.classpath = const_cast<char*>("[demoJar]");
#endif

  JavaVM* vm;
  void* env;
  JNI_CreateJavaVM(&vm, &env, &vmArgs);
  JNIEnv* e = static_cast<JNIEnv*>(env);

  jclass c = e->FindClass(MAIN_CLASS);
  if (not e->ExceptionOccurred()) {
    jmethodID m = e->GetStaticMethodID(c, "main", "([Ljava/lang/String;)V");
    if (not e->ExceptionOccurred()) {
      jclass stringClass = e->FindClass("java/lang/String");
      if (not e->ExceptionOccurred()) {
        jobjectArray a = e->NewObjectArray(ac-1, stringClass, 0);
        if (not e->ExceptionOccurred()) {
          for (int i = 1; i < ac; ++i) {
            e->SetObjectArrayElement(a, i-1, e->NewStringUTF(av[i]));
          }
          
          e->CallStaticVoidMethod(c, m, a);
        }
      }
    }
  }

  int exitCode = 0;
  if (e->ExceptionOccurred()) {
    exitCode = -1;
    e->ExceptionDescribe();
  }

  vm->DestroyJavaVM();

  return exitCode;
}
