build-arch = $(shell uname -m)
ifeq ($(build-arch),i586)
	build-arch = i386
endif
ifeq ($(build-arch),i686)
	build-arch = i386
endif
ifeq ('$(build-arch)','Power Macintosh')
	build-arch = powerpc
endif

build-platform = $(shell uname -s | tr [:upper:] [:lower:])

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
ifeq ($(bootimage),true)
	options := $(options)-bootimage
endif
ifeq ($(heapdump),true)
	options := $(options)-heapdump
endif

root = ..
base = $(shell pwd)
vm = $(root)/avian
swt = $(root)/swt-3.5/$(platform)-$(arch)/swt.jar
src = src
bld = build/$(platform)-$(arch)$(options)/$(name)
stage1 = $(bld)/stage1
stage2 = $(bld)/stage2
vm-bld = $(vm)/build/$(platform)-$(arch)$(options)

cxx = g++
cc = gcc
dlltool = dlltool
proguard = $(root)/proguard4.4/lib/proguard.jar
java = "$(JAVA_HOME)/bin/java"
javac = "$(JAVA_HOME)/bin/javac"
jar = "$(JAVA_HOME)/bin/jar"

converter = $(vm-bld)/binaryToObject

ifeq ($(mode),fast)
	upx = upx
	strip = strip --strip-all
else
	upx = :
	strip = :
endif

so-prefix = lib
so-suffix = .so

pointer-size = 8

asm = x86

common-cflags = -Wextra -Werror -Wunused-parameter -Winit-self \
	-I"$(JAVA_HOME)/include" \
	-fno-rtti -fno-exceptions \
	-D__STDC_LIMIT_MACROS -D_JNI_IMPLEMENTATION_ -DMAIN_CLASS=\"$(main-class)\"

cflags = $(common-cflags) \
	-I"$(JAVA_HOME)/include/linux" \
	-fvisibility=hidden -fPIC

common-lflags = -lz -lm -lstdc++

lflags = $(common-lflags) -rdynamic -lpthread -ldl

native-path = echo

ifeq ($(arch),i386)
	pointer-size = 4
endif
ifeq ($(arch),powerpc)
	asm = powerpc
	pointer-size = 4
endif

ifeq ($(platform),darwin)
	ifneq ($(arch),x86_64)
# SWT >= 3.5 only works on OS X 10.5 and above, so we use 3.4 instead
		swt = $(root)/swt-3.4/$(platform)-$(arch)/swt.jar
	endif

	cflags = $(common-cflags)	-Wno-deprecated -Wno-deprecated-declarations
	lflags = $(common-lflags) -ldl -framework CoreFoundation -framework Carbon
	upx = :
	strip = strip -S -x

	ifeq ($(arch),powerpc)
		cross-flags := -mmacosx-version-min=10.4 -arch ppc
	endif

	ifeq ($(arch),i386)
		cross-flags := -mmacosx-version-min=10.4 -arch i386
	endif

	so-suffix = .jnilib
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
	lflags = -L$(lib) $(common-lflags) -lws2_32 -Wl,--kill-at -mwindows

	ifeq (,$(filter mingw32 cygwin,$(build-platform)))
		cxx = i586-mingw32msvc-g++
		cc = i586-mingw32msvc-gcc
		dlltool = i586-mingw32msvc-dlltool
		ar = i586-mingw32msvc-ar
		ranlib = i586-mingw32msvc-ranlib
		strip = i586-mingw32msvc-strip
	else
		common-cflags += "-I$(JAVA_HOME)/include/win32"
		build-cflags = $(common-cflags) -I$(src) -mthreads
		ifdef proguard
			proguard += -dontusemixedcaseclassnames
		endif
		ifeq ($(build-platform),cygwin)
			build-lflags += -mno-cygwin
			build-cflags += -mno-cygwin
			lflags += -mno-cygwin
			cflags += -mno-cygwin
			native-path = cygpath -m
		endif
	endif

	ifeq ($(arch),x86_64)
		wine-include-flags =
		upx = :

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
	endif
endif

ifeq ($(mode),debug)
	opt = -O0 -g3
endif
ifeq ($(mode),debug-fast)
	opt = -O0 -g3 -DNDEBUG
endif
ifeq ($(mode),fast)
	opt = -O3 -g3 -DNDEBUG
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
	 make mode=$(mode) process=$(process) arch=$(arch) platform=$(platform))
	cd "$(base)"
endef

## targets ####################################################################

.PHONY: build
build: $(executable)

$(classes): $(sources)
	$(make-vm)
	@rm -rf $(stage1)
	@mkdir -p $(stage1)
	$(javac) -d $(stage1) -sourcepath $(src) \
		-cp $(swt) -bootclasspath $(vm)/build/classpath $(sources)

$(properties): $(classes)
	cp $(properties-file) $(stage1)
	@touch $(@)

$(data): $(classes)
	@mkdir -p $(stage1)/$(data-directory)
	cp $(data-files) $(stage1)/$(data-directory)
	@touch $(@)

$(vm-classes): $(classes)
	cp -r $(vm)/build/classpath/* $(stage1)
	@touch $(@)

$(jars): $(classes)
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
	(cd $(bld)/vm && ar x "$(base)/$(vm-lib)")

$(executable): $(jar-object) $(objects) $(vm-objects)
ifeq ($(platform),windows)
	$(dlltool) -z $(@).def $(objects) $(bld)/vm/*
	$(dlltool) -d $(@).def -e $(@).exp
	$(cc) $(@).exp $(jar-object) $(objects) $(hook-lib) $(bld)/vm/*.o \
		$(lflags) -o $(@)
else
	$(cc) $(jar-object) $(objects) $(bld)/vm/*.o $(lflags) -o $(@)
endif
	$(strip) $(@)
	$(upx) $(@)
