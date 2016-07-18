Avian SWT Examples
==================

This package includes a set of three small sample applications taken
from the Eclipse CVS repository, plus makefiles to build them as
standalone executables using Avian.  The following instructions may be
used to build them:

    # Set the platform and swt_zip environment variables according to the
    # following table:
    #
    # platform               swt_zip
    # --------               -------
    # linux-x86_64           swt-4.3-gtk-linux-x86_64.zip
    # linux-i386             swt-4.3-gtk-linux-x86.zip
    # linux-arm64            swt-4.3-gtk-linux-arm64.zip
    # linux-arm              swt-4.3-gtk-linux-arm.zip
    # macosx-x86_64          swt-4.3-cocoa-macosx-x86_64.zip
    # macosx-i386            swt-4.3-cocoa-macosx.zip
    # windows-x86_64         swt-4.3-win32-win32-x86_64.zip
    # windows-i386           swt-4.3-win32-win32-x86.zip

    mkdir work
    cd work
    curl -Of http://readytalk.github.io/avian-web/proguard4.11.tar.gz
    tar xzf proguard4.11.tar.gz
    curl -Of http://readytalk.github.io/avian-web/lzma920.tar.bz2
    (mkdir -p lzma-920 && cd lzma-920 && tar xjf ../lzma920.tar.bz2)
    curl -Of http://readytalk.github.io/avian-web/${swt_zip}
    mkdir -p swt/${platform}
    unzip -d swt/${platform} ${swt_zip}
    curl -Of http://readytalk.github.io/avian-web/avian-1.2.0.tar.bz2
    tar xjf avian-1.2.0.tar.bz2
    curl -Of http://readytalk.github.io/avian-web/avian-swt-examples-1.2.0.tar.bz2
    tar xjf avian-swt-examples-1.2.0.tar.bz2
    # needed only for 32-bit Windows builds:
    git clone https://github.com/ReadyTalk/win32.git
    # needed only for 64-bit Windows builds:
    git clone https://github.com/ReadyTalk/win64.git
    cd avian-swt-examples
    make lzma=$(pwd)/../lzma-920 full-platform=${platform} example

Alternatively, you can build using OpenJDK's class library instead of
the default Avian class library.  See the [readme file](https://github.com/ReadyTalk/avian/blob/master/README.md#avian---a-lightweight-java-virtual-machine-jvm) in the Avian
source tree for examples of how to install OpenJDK and build Avian
with it.

    # Set the path_to_openjdk_build and path_to_openjdk_source
    # environment variables according to your system, e.g.:
    #
    # path_to_openjdk_build=$HOME/jdk7u-dev/build/linux-amd64/j2sdk-image
    # path_to_openjdk_source=$HOME/jdk7u-dev/jdk/src

    $ make full-platform=${platform} openjdk=${path_to_openjdk_build}
    $ make full-platform=${platform} openjdk=${path_to_openjdk_build} \
        openjdk-src=${path_to_openjdk_source}
