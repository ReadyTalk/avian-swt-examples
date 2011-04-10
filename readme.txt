This package includes a set of three small sample applications taken
from the Eclipse CVS repository, plus makefiles to build them as
standalone executables using Avian.  The following instructions may be
used to build them:

  # Set the platform and swt_zip environment variables according to the
  # following table:
  #
  # platform               swt_zip
  # --------               -------
  # linux-x86_64           swt-3.6-gtk-linux-x86_64.zip
  # linux-i386             swt-3.6-gtk-linux-x86.zip
  # linux-arm              swt-3.6-gtk-linux-arm.zip
  # linux-powerpc          swt-3.6-gtk-linux-ppc.zip
  # darwin-x86_64-cocoa    swt-3.6-cocoa-macosx-x86_64.zip
  # darwin-i386-carbon     swt-3.6-carbon-macosx.zip
  # darwin-powerpc-carbon  swt-3.6-carbon-macosx.zip
  # windows-x86_64         swt-3.6-win32-win32-x86_64.zip
  # windows-i386           swt-3.6-win32-win32-x86.zip
  
  mkdir work
  cd work
  curl -Of http://oss.readytalk.com/avian/proguard4.6beta1.tar.gz
  tar xzf proguard4.6beta1.tar.gz
  curl -Of http://oss.readytalk.com/avian/${swt_zip}
  mkdir -p swt/${platform}
  unzip -d swt/${platform} ${swt_zip}
  git clone git://oss.readytalk.com/avian.git
  git clone git://oss.readytalk.com/avian-swt-examples.git
  # needed only for 32-bit Windows builds:
  git clone git://oss.readytalk.com/win32.git
  # needed only for 64-bit Windows builds:
  git clone git://oss.readytalk.com/win64.git
  cd avian-swt-examples
  # specify "upx=:" if UPX is not installed:
  make full-platform=${platform}

Alternatively, you can build using OpenJDK's class library instead of
the default Avian class library.  See the readme.txt in the Avian
source tree for examples of how to install OpenJDK and build Avian
with it.

  # Set the path_to_openjdk_build and path_to_openjdk_source
  # environment variables according to your system, e.g.:
  #
  # path_to_openjdk_build=/usr/lib/jvm/java-6-openjdk
  # path_to_openjdk_source=$HOME/openjdk-6-6b18-1.8.3/build/openjdk/jdk/src
  
  make full-platform=${platform} openjdk=${path_to_openjdk_build}
  make full-platform=${platform} openjdk=${path_to_openjdk_build} \
    openjdk-src=${path_to_openjdk_source}
