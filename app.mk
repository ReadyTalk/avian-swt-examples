build-arch := $(shell uname -m \
	| sed 's/^i.86$$/i386/' \
	| sed 's/^x86pc$$/i386/' \
	| sed 's/amd64/x86_64/' \
	| sed 's/^arm.*$$/arm/' \
	| sed 's/aarch64/arm64/')

build-platform = \
	$(shell uname -s | tr [:upper:] [:lower:] \
		| sed 's/^mingw32.*$$/mingw32/' \
		| sed 's/^cygwin.*$$/cygwin/')

arch = $(build-arch)
platform = $(subst cygwin,windows,$(subst mingw32,windows,$(build-platform)))

mode = fast
process = compile

ifneq ($(process),compile)
	options := -$(process)
endif
ifneq ($(mode),fast)
	options := $(options)-$(mode)
endif
ifneq ($(lzma),)
	options := $(options)-lzma
endif
ifeq ($(bootimage),true)
	options := $(options)-bootimage
	boot-cflags = -DBOOT_IMAGE
	vm-targets = \
		build/$(platform)-$(arch)$(options)/bootimage-generator \
		build/$(platform)-$(arch)$(options)/binaryToObject/binaryToObject \
		build/$(platform)-$(arch)$(options)/classpath.jar \
		build/$(platform)-$(arch)$(options)/libavian.a
	ifneq ($(lzma),)
		vm-targets += \
			build/$(platform)-$(arch)$(options)/lzma/lzma \
			build/$(platform)-$(arch)$(options)/lzma/load.o
	endif
	boot-objects = \
		$(bld)/bootimage-bin.o \
		$(bld)/codeimage-bin.o
	resources-object = $(bld)/resources-jar.o
else
	boot-objects = $(jar-object)
endif
ifeq ($(heapdump),true)
	options := $(options)-heapdump
endif

proguard-flags = \
	$(extra-proguard-flags) \
	-renamesourcefileattribute SourceFile \
	-keepattributes SourceFile,LineNumberTable \
	-dontoptimize

ifneq ($(openjdk),)
	ifneq ($(openjdk-src),)
		options := $(options)-openjdk-src
	else
		options := $(options)-openjdk
	endif

	proguard-flags += -include $(vm)/openjdk.pro -dontobfuscate
else
	proguard-flags += -overloadaggressively
endif

ifneq ($(android),)
	options := $(options)-android

	classpath-lflags = \
		$(android)/icu4c/lib/libicui18n.a \
		$(android)/icu4c/lib/libicuuc.a \
		$(android)/icu4c/lib/libicudata.a \
		$(android)/fdlibm/libfdm.a \
		$(android)/expat/.libs/libexpat.a \
		$(android)/openssl-upstream/libssl.a \
		$(android)/openssl-upstream/libcrypto.a \
		-lstdc++

	proguard-flags += -include $(vm)/android.pro -dontobfuscate
endif

ifneq (,$(full-platform))
	platform = $(word 1,$(subst -, ,$(full-platform)))
	arch = $(word 2,$(subst -, ,$(full-platform)))
	subplatform = $(word 3,$(subst -, ,$(full-platform)))
else
	full-platform = $(platform)-$(arch)
endif

root = ..
base = $(shell pwd)
vm = $(root)/avian
swt = $(root)/swt/$(full-platform)/swt.jar
src = src
bld = build/$(full-platform)$(options)/$(name)
stage1 = $(bld)/stage1
stage2 = $(bld)/stage2
resources = $(bld)/resources
vm-bld = $(vm)/build/$(platform)-$(arch)$(options)

ifneq ($(platform),macosx)
	ifeq ($(arch),i386)
		mflag = -m32
	endif
	ifeq ($(arch),x86_64)
		mflag = -m64
	endif
endif

cxx = g++ $(mflag)
cc = gcc $(mflag)
ar = ar

dlltool = dlltool
proguard = $(root)/proguard4.11/lib/proguard.jar
java = "$(JAVA_HOME)/bin/java"
javac = "$(JAVA_HOME)/bin/javac"
jar = "$(JAVA_HOME)/bin/jar"

converter = $(vm-bld)/binaryToObject/binaryToObject
bootimage-generator = $(vm-bld)/bootimage-generator
lzma-encoder = $(vm-bld)/lzma/lzma

ifeq ($(mode),fast)
	strip = strip --strip-all
else
	strip = :
endif

so-prefix = lib
so-suffix = .so

shared = -shared

pointer-size = 8

common-cflags = $(boot-cflags) -Wextra -Werror -Wunused-parameter -Winit-self \
	-I"$(JAVA_HOME)/include" \
	-fno-rtti -fno-exceptions \
	-D__STDC_LIMIT_MACROS -D_JNI_IMPLEMENTATION_ -DMAIN_CLASS=\"$(main-class)\"

cflags = $(common-cflags) \
	-I"$(JAVA_HOME)/include/linux" \
	-fvisibility=hidden -fPIC

common-lflags = -lz -lm $(classpath-lflags)

lflags = $(common-lflags) -rdynamic -lpthread -ldl

native-path = echo

ifeq ($(arch),i386)
	pointer-size = 4
endif
ifeq ($(arch),arm)
	pointer-size = 4

	ifneq ($(arch),$(build-arch))
		cxx = arm-linux-gnueabi-g++
		cc = arm-linux-gnueabi-gcc
		ar = arm-linux-gnueabi-ar
		ranlib = arm-linux-gnueabi-ranlib
		strip = arm-linux-gnueabi-strip
	endif
endif
ifeq ($(arch),arm64)
	pointer-size = 8

	ifneq ($(arch),$(build-arch))
		cxx = aarch64-linux-gnu-g++
		cc = aarch64-linux-gnu-gcc
		ar = aarch64-linux-gnu-ar
		ranlib = aarch64-linux-gnu-ranlib
		strip = aarch64-linux-gnu-strip
	endif
endif

ifeq ($(platform),macosx)
	cflags = $(common-cflags) -Wno-deprecated -Wno-deprecated-declarations \
			-I"$(JAVA_HOME)/include/darwin"
	lflags = $(common-lflags) -ldl -framework CoreFoundation -framework Carbon
	strip = strip -S -x

	ifeq ($(arch),i386)
		cross-flags := -mmacosx-version-min=10.4 -arch i386
	endif

	so-suffix = .jnilib
	shared = -dynamiclib
	ifdef proguard
		proguard += -dontusemixedcaseclassnames
	endif
endif

ifeq ($(platform),windows)
	inc = "$(root)/win32/include"
	lib = "$(root)/win32/lib"

	so-prefix =
	so-suffix = .dll
	exe-suffix = .exe

	cflags = -I$(inc) $(common-cflags)
	lflags = -L$(lib) $(common-lflags) -lws2_32 -liphlpapi -Wl,--kill-at -mwindows

	ifeq (,$(filter mingw32 cygwin,$(build-platform)))
		cxx = i686-w64-mingw32-g++ -m32 -march=i586
		cc = i686-w64-mingw32-gcc -m32 -march=i586
		dlltool = i686-w64-mingw32-dlltool -mi386 --as-flags=--32
		ar = i686-w64-mingw32-ar
		ar-flags = --target=pe-i386
		ranlib = i686-w64-mingw32-ranlib
		strip = i686-w64-mingw32-strip --strip-all
	else
		common-cflags += "-I$(JAVA_HOME)/include/win32"
		build-cflags = $(common-cflags) -I$(src) -mthreads
		ifdef proguard
			proguard += -dontusemixedcaseclassnames
		endif
		ifeq ($(build-platform),cygwin)
			native-path = cygpath -m
			cxx = i686-w64-mingw32-g++
			cc = i686-w64-mingw32-gcc
			dlltool = i686-w64-mingw32-dlltool
			ar = i686-w64-mingw32-ar
			ranlib = i686-w64-mingw32-ranlib
			strip = i686-w64-mingw32-strip
		endif
	endif

	ifeq ($(arch),x86_64)
		wine-include-flags =

		cxx = x86_64-w64-mingw32-g++
		cc = x86_64-w64-mingw32-gcc
		dlltool = x86_64-w64-mingw32-dlltool
		ar = x86_64-w64-mingw32-ar
		ranlib = x86_64-w64-mingw32-ranlib
		restool = x86_64-w64-mingw32-windres
		strip = x86_64-w64-mingw32-strip --strip-all
		inc = "$(root)/win64/include"
		lib = "$(root)/win64/lib"

		lflags = -Wl,--as-needed -L$(lib) $(common-lflags) \
			-lws2_32 -lversion -lpsapi -lz -ljpeg -lole32 -lurlmon -luuid \
			-lwininet -mwindows
	else
		shared += -Wl,--add-stdcall-alias
	endif
endif

ifeq ($(mode),debug)
	opt = -O0 -g3
	strip = :
endif
ifeq ($(mode),debug-fast)
	opt = -O0 -g3 -DNDEBUG
	strip = :
endif
ifeq ($(mode),fast)
	opt = -O3 -g3 -DNDEBUG
endif

ifeq ($(use-lto),true)
# only try to use LTO when GCC 4.6.0 or greater is available
	gcc-major := $(shell $(cc) -dumpversion | cut -f1 -d.)
	gcc-minor := $(shell $(cc) -dumpversion | cut -f2 -d.)
	ifeq ($(shell expr 4 \< $(gcc-major) \
			\| \( 4 \<= $(gcc-major) \& 6 \<= $(gcc-minor) \)),1)
		opt += -flto
		no-lto = -fno-lto
		lflags += $(opt)
	endif
endif

ifdef cross-flags
	cc := $(cc) $(cross-flags)
	cxx := $(cxx) $(cross-flags)
endif

cflags += $(opt)

cpp-objects = $(foreach x,$(1),$(patsubst $(2)/%.cpp,$(3)/%.o,$(x)))
java-classes = $(foreach x,$(1),$(patsubst $(2)/%.java,$(3)/%.class,$(x)))

classes = $(call java-classes,$(sources),$(source-directory),$(stage1))

cpps = $(src)/main.cpp
objects = $(call cpp-objects,$(cpps),$(src),$(bld))

jar-object = $(bld)/jar.o
vm-lib = $(vm-bld)/libavian.a
executable = $(bld)/$(name)${exe-suffix}

properties = $(stage1)/properties.d
data = $(stage1)/data.d
jars = $(stage1)/jars.d
vm-classes = $(stage1)/vm-classes.d
vm-objects = $(bld)/vm-objects.d

define make-vm
	(cd $(vm) && unset MAKEFLAGS && \
	 make mode=$(mode) process=$(process) arch=$(arch) platform=$(platform) \
		 lzma=$(lzma) "openjdk=$(openjdk)" "openjdk-src=$(openjdk-src)" \
		 android=$(android) $(vm-targets))
	cd "$(base)"
endef

ifneq ($(lzma),)
	executable-lzma = $(executable)
	executable-nolzma = $(executable)-nolzma
else
	executable-lzma = $(executable)-lzma
	executable-nolzma = $(executable)
endif

## targets ####################################################################

.PHONY: build
build: vm $(executable)

.PHONY: vm
vm:
	$(make-vm)

$(classes): $(sources) $(jars)
	$(make-vm)
	@mkdir -p $(stage1)
	$(javac) -d $(stage1) -sourcepath $(src) \
		-cp $(swt) -bootclasspath $(vm-bld)/classpath $(sources)

$(properties): $(classes)
	cp $(properties-file) $(stage1)
	@touch $(@)

$(data): $(classes)
	@mkdir -p $(stage1)/$(data-directory)
	cp $(data-files) $(stage1)/$(data-directory)
	@touch $(@)

$(vm-classes): $(classes)
	cp -r $(vm-bld)/classpath/* $(stage1)
	@touch $(@)

$(jars):
	@mkdir -p $(stage1)
	(cd $(stage1) && $(jar) xf "$$($(native-path) "$(base)/$(swt)")")
	rm -r $(stage1)/org/eclipse/swt/awt
	@touch $(@)

$(bld)/boot.jar: \
		$(classes) $(properties) $(data) $(jars) $(vm-classes)
	@mkdir -p $(dir $(bld)/tmp)
ifdef proguard
	$(java) -jar $(proguard) \
		-injars $(stage1) \
		-outjars $(stage2) \
		-printmapping $(bld)/mapping.txt \
		-include $(vm)/vm.pro \
		-include swt.pro \
		$(proguard-flags) \
		-keep class $(main-class) \{ \
			public static void 'main(java.lang.String[]);' \
		\}
	($(jar) c0f "$(@)" -C $(stage2) .)
else
	($(jar) c0f "$(@)" -C $(stage1) .)
endif

$(jar-object): $(bld)/boot.jar
	$(converter) $(<) $(@) _binary_boot_jar_start \
		_binary_boot_jar_end $(platform) $(arch)

$(bld)/%.o: $(src)/%.cpp
	@mkdir -p $(dir $(@))
	$(cxx) $(cflags) -c $(<) -o $(@)

$(vm-lib):
	$(make-vm)

$(vm-objects): $(vm-lib)
	$(make-vm)
	@mkdir -p $(bld)/vm
	(cd $(bld)/vm && $(ar) x $(ar-flags) "$(base)/$(vm-lib)")

$(bld)/resources.jar: $(resources).d
	cd $(resources) && jar cf ../resources.jar *

$(bld)/resources-jar.o: $(bld)/resources.jar
	$(converter) $(<) $(@) _binary_resources_jar_start \
		_binary_resources_jar_end $(platform) $(arch) 1

$(resources).d: $(bld)/boot.jar
	@mkdir -p $(dir $(@))
	rm -rf $(resources)
	mkdir -p $(resources)
	cp -a $(stage2)/* $(resources)/
	find $(resources) -type f -name '*.class' -exec rm '{}' \;
	@touch $(@)

$(bld)/bootimage-bin.o: $(bld)/boot.jar
	$(bootimage-generator) -cp $(stage2) -bootimage $(@) \
		-codeimage $(bld)/codeimage-bin.o

$(executable-nolzma): $(boot-objects) $(objects) $(vm-objects) \
		$(resources-object)
ifeq ($(platform),windows)
	$(dlltool) -z $(@).def $(objects) $(bld)/vm/*
	$(dlltool) -d $(@).def -e $(@).exp
	$(cc) $(@).exp $(boot-objects) $(objects) $(bld)/vm/*.o \
		$(resources-object) $(lflags) -o $(@)
else
	$(cc) $(boot-objects) $(objects) $(bld)/vm/*.o $(resources-object) \
		$(lflags) -o $(@)
endif
	$(strip) $(@)

$(executable).so: $(boot-objects) $(objects) $(vm-objects) $(resources-object)
	$(cc) $(boot-objects) $(objects) $(resources-object) $(bld)/vm/*.o \
		$(lflags) $(shared) -o $(@)
	$(strip) $(@)

$(executable).lzma: $(executable).so
	$(lzma-encoder) encode $(<) $(@)

$(executable).o: $(executable).lzma
	$(converter) $(<) $(@) _binary_exe_start _binary_exe_end $(platform) $(arch)

$(executable-lzma): $(executable).o
	$(cc) $(^) $(vm-bld)/lzma/load.o $(vm-bld)/LzmaDec.o $(lflags) -o $(@)
	$(strip) $(@)
