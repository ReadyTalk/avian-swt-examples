build-arch = $(shell uname -m)
ifeq ($(build-arch),i586)
	build-arch = i386
endif
ifeq ($(build-arch),i686)
	build-arch = i386
endif

build-platform = $(shell uname -s | tr [:upper:] [:lower:])

arch = $(build-arch)
platform = $(build-platform)
mode = fast
process = compile

ifeq ($(platform),windows)
	arch = i386
endif

root = $(shell (cd .. && pwd))
base = $(shell pwd)
vm = $(root)/avian
swt = $(root)/swt-3.3/$(platform)-$(arch)/swt.jar
src = $(base)/src
bld = $(base)/build/$(platform)-$(arch)-$(process)-$(mode)/$(name)
stage1 = $(bld)/stage1
stage2 = $(bld)/stage2
vm-bld = $(vm)/build/$(platform)-$(arch)-$(process)-$(mode)

cxx = g++
cc = gcc
objcopy = objcopy
proguard = $(root)/proguard4.2/lib/proguard.jar

ifeq ($(mode),fast)
	upx = upx
	strip = strip --strip-all
else
	upx = :
	strip = :
endif

object-arch = i386:x86-64
object-format = elf64-x86-64

so-prefix = lib
so-suffix = .so

pointer-size = 8

common-cflags = -Wextra -Werror -Wunused-parameter -Winit-self \
	-I$(JAVA_HOME)/include \
	-fno-rtti -fno-exceptions \
	-D__STDC_LIMIT_MACROS -D_JNI_IMPLEMENTATION_ -DMAIN_CLASS=\"$(main-class)\"

cflags = $(common-cflags) \
	-I$(JAVA_HOME)/include/linux \
	-fvisibility=hidden -fPIC

common-lflags = -lz -lm -lstdc++

lflags = $(common-lflags) -rdynamic -lpthread -ldl

ifeq ($(arch),i386)
	object-arch = i386
	object-format = elf32-i386
	pointer-size = 4
endif

ifeq ($(platform),darwin)
	cflags = $(common-cflags)	-Wno-deprecated -Wno-deprecated-declarations
	lflags = $(common-lflags) -ldl -framework CoreFoundation
	upx = :
	strip = strip -S -x

	so-suffix = .jnilib
	binaryToMacho = $(vm-bld)/binaryToMacho
ifdef proguard
	proguard += -dontusemixedcaseclassnames
endif
endif

ifeq ($(platform),windows)
	inc = $(root)/win32/include
	lib = $(root)/win32/lib

	object-format = pe-i386
	cxx = i586-mingw32msvc-g++
	cc = i586-mingw32msvc-gcc
	objcopy = i586-mingw32msvc-objcopy
	dlltool = i586-mingw32msvc-dlltool

	so-prefix =
	so-suffix = .dll

	cflags = -I$(inc) $(common-cflags)
	lflags = -L$(lib) $(common-lflags) -lws2_32 -Wl,--kill-at -mwindows
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

cflags += $(opt)

cpp-objects = $(foreach x,$(1),$(patsubst $(2)/%.cpp,$(3)/%.o,$(x)))
java-classes = $(foreach x,$(1),$(patsubst $(2)/%.java,$(3)/%.class,$(x)))

classes = $(call java-classes,$(sources),$(source-directory),$(stage1))

cpps = $(src)/main.cpp
objects = $(call cpp-objects,$(cpps),$(src),$(bld))

jar-object = $(bld)/jar.o
vm-lib = $(vm-bld)/libavian.a
executable = $(bld)/$(name)

properties = $(stage1)/properties.d
data = $(stage1)/data.d
jars = $(stage1)/jars.d
vm-classes = $(stage1)/vm-classes.d
vm-objects = $(bld)/vm-objects.d

define make-vm
	(cd $(vm) && unset MAKEFLAGS && \
	 make mode=$(mode) process=$(process) arch=$(arch) platform=$(platform))
endef

## targets ####################################################################

.PHONY: build
build: $(executable)

$(classes): $(sources)
	$(make-vm)
	@rm -rf $(stage1)
	@mkdir -p $(stage1)
	javac -d $(stage1) -sourcepath $(src) \
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
	(cd $(stage1) && jar xf $(swt))
	rm -r $(stage1)/org/eclipse/swt/awt
	@touch $(@)

$(bld)/boot.jar: \
		$(classes) $(properties) $(data) $(jars) $(vm-classes)
	@mkdir -p $(dir $(bld)/tmp)
ifdef proguard
	java -jar $(proguard) \
		-injars $(stage1) \
		-outjars $(stage2) \
		-printmapping $(bld)/mapping.txt \
		@$(vm)/vm.pro \
		@$(base)/swt.pro \
		-keep class $(main-class) \{ \
			public static void 'main(java.lang.String[]);' \
		\}
	(cd $(stage2) && jar c0f $(@) .)
else
	(cd $(stage1) && jar c0f $(@) .)
endif

$(jar-object): $(bld)/boot.jar
ifeq ($(platform),darwin)
	$(binaryToMacho) $(bld)/boot.jar \
		__binary_boot_jar_start __binary_boot_jar_end > $(@)
else
	(cd $(bld) && $(objcopy) -I binary boot.jar \
		 -O $(object-format) -B $(object-arch) $(@))
endif

$(bld)/%.o: $(src)/%.cpp
	@mkdir -p $(dir $(@))
	$(cxx) $(cflags) -c $(<) -o $(@)

$(vm-lib):
	$(make-vm)

$(vm-objects): $(vm-lib)
	$(make-vm)
	@mkdir -p $(bld)/vm
	(cd $(bld)/vm && ar x $(vm-lib))

$(executable): $(jar-object) $(objects) $(vm-objects)
ifeq ($(platform),windows)
	$(dlltool) -z $(@).def $(objects) $(bld)/vm/*
	$(dlltool) -k -d $(@).def -e $(@).exp
	$(cc) $(@).exp $(jar-object) $(objects) $(hook-lib) $(bld)/vm/*.o \
		$(lflags) -o $(@)
else
	$(cc) $(jar-object) $(objects) $(bld)/vm/*.o $(lflags) -o $(@)
endif
	$(strip) $(@)
	$(upx) $(@)
ifeq ($(platform),windows)
	mv $(@) $(@).exe
endif
