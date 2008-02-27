name = demo

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
bld = $(base)/build/$(platform)-$(arch)-$(process)-$(mode)
stage1 = $(bld)/stage1
stage2 = $(bld)/stage2
vm-bld = $(vm)/build/$(platform)-$(arch)-$(process)-$(mode)
examples = $(base)/org.eclipse.swt.examples/src

controlexample = org/eclipse/swt/examples/controlexample

main-class = $(controlexample)/ControlExample

cxx = g++
cc = gcc
objcopy = objcopy
proguard = $(root)/proguard4.1/lib/proguard.jar

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

common-cflags = -Wextra -Werror -Wunused-parameter -Winit-self -Wconversion \
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
	lflags = $(common-lflags) -ldl
	upx = :
	strip = strip -S -x

	so-suffix = .jnilib
	binaryToMacho = $(vm-bld)/binaryToMacho
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
	lflags = -L$(lib) $(common-lflags) -lws2_32 -Wl,--kill-at -mwindows -mconsole
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

javas = $(shell find $(examples)/$(controlexample) -name '*.java')
classes = $(call java-classes,$(javas),$(examples),$(stage1))

cpps = $(src)/$(name).cpp
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
	(cd $(vm) && \
	 make mode=$(mode) process=$(process) arch=$(arch) platform=$(platform))
endef

define slink
	$(cxx) $(^) -shared $(lflags) -o $(@)
	$(strip) $(@)
endef

## targets ####################################################################

.PHONY: build
build: $(executable) $(bld)/$(name).jar

.PHONY: run
run: $(executable)
	$(<)

$(classes): $(javas)
	$(make-vm)
	@rm -rf $(stage1)
	@mkdir -p $(stage1)
	javac -d $(stage1) -sourcepath $(generated-src):$(src) \
		-cp $(swt) -bootclasspath $(vm)/build/classpath $(javas)

$(properties): $(classes)
	cp $(examples)/examples_control.properties $(stage1)
	@touch $(@)

$(data): $(classes)
	@mkdir -p $(stage1)/$(controlexample)
	cp $(examples)/$(controlexample)/*.png \
		$(examples)/$(controlexample)/*.gif \
		$(examples)/$(controlexample)/*.bmp \
		$(examples)/$(controlexample)/*.html \
		$(stage1)/$(controlexample)
	@touch $(@)

$(vm-classes): $(classes)
	cp -r $(vm)/build/classpath/* $(stage1)
	@touch $(@)

$(jars): $(classes)
	(cd $(stage1) && jar xf $(swt))
	rm -r $(stage1)/org/eclipse/swt/awt
	@touch $(@)

$(bld)/$(name).jar: \
		$(classes) $(properties) $(data) $(jars) $(vm-classes)
	@mkdir -p $(dir $(bld)/tmp)
ifdef proguard
	java -jar $(proguard) \
		-injars $(stage1) \
		-outjars $(stage2) \
		-printmapping $(bld)/mapping.txt \
		@$(vm)/vm.pro \
		@$(name).pro
	(cd $(stage2) && jar c0f $(@) .)
else
	(cd $(stage1) && jar c0f $(@) .)
endif

$(jar-object): $(bld)/$(name).jar
ifeq ($(platform),darwin)
	$(binaryToMacho) $(bld)/client.jar \
		__binary_$(name)_jar_start __binary_$(name)_jar_size > $(@)
else
	(cd $(bld) && $(objcopy) -I binary $(name).jar \
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

.PHONY: clean
clean:
	rm -rf build
