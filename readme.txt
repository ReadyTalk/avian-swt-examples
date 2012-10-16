This package includes a set of three small sample applications taken
from the Eclipse CVS repository, plus makefiles to build them as
standalone executables using Avian.  The following instructions may be
used to build them:

  # Set the platform and swt_zip environment variables according to the
  # following table:
  #
  # platform               swt_zip
  # --------               -------
  # linux-x86_64           swt-3.7-gtk-linux-x86_64.zip
  # linux-i386             swt-3.7-gtk-linux-x86.zip
  # linux-arm              swt-3.7-gtk-linux-arm.zip
  # linux-powerpc          swt-3.7-gtk-linux-powerpc.zip
  # darwin-x86_64-cocoa    swt-3.7-cocoa-macosx-x86_64.zip
  # darwin-i386-carbon     swt-3.7-carbon-macosx.zip
  # darwin-powerpc-carbon  swt-3.7-carbon-macosx.zip
  # windows-x86_64         swt-3.7-win32-win32-x86_64.zip
  # windows-i386           swt-3.7-win32-win32-x86.zip

  mkdir work
  cd work
  curl -Of http://oss.readytalk.com/avian/proguard4.8.tar.gz
  tar xzf proguard4.8.tar.gz
  curl -Of http://oss.readytalk.com/avian/lzma920.tar.bz2
  (mkdir -p lzma-920 && cd lzma-920 && tar xjf ../lzma920.tar.bz2)
  curl -Of http://oss.readytalk.com/avian/${swt_zip}
  mkdir -p swt/${platform}
  unzip -d swt/${platform} ${swt_zip}
  git clone https://github.com/ReadyTalk/avian
  git clone https://github.com/ReadyTalk/avian-swt-examples
  # needed only for 32-bit Windows builds:
  git clone git://oss.readytalk.com/win32.git
  # needed only for 64-bit Windows builds:
  git clone git://oss.readytalk.com/win64.git
  cd avian-swt-examples
  make lzma=$(pwd)/../lzma-920 full-platform=${platform}

Alternatively, you can build using OpenJDK's class library instead of
the default Avian class library.  See the readme.txt in the Avian
source tree for examples of how to install OpenJDK and build Avian
with it.

  # Set the path_to_openjdk_build and path_to_openjdk_source
  # environment variables according to your system, e.g.:
  #
  # path_to_openjdk_build=$HOME/jdk7u-dev/build/linux-amd64/j2sdk-image
  # path_to_openjdk_source=$HOME/jdk7u-dev/jdk/src
  
  make full-platform=${platform} openjdk=${path_to_openjdk_build}
  make full-platform=${platform} openjdk=${path_to_openjdk_build} \
    openjdk-src=${path_to_openjdk_source}
