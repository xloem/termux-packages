TERMUX_PKG_HOMEPAGE=https://pytorch.org/
TERMUX_PKG_DESCRIPTION='Tensors and Dynamic neural networks'
TERMUX_PKG_LICENSE=non-free
TERMUX_PKG_LICENSE_FILE=LICENSE
TERMUX_PKG_MAINTAINER='@termux'
TERMUX_PKG_VERSION=1.10.1
TERMUX_PKG_SRCURL=https://github.com/pytorch/pytorch/releases/download/v${TERMUX_PKG_VERSION}/pytorch-v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=635ce1ae2af286d0f401cb0342bcf0a337f774c3f91f3dfcb11013fff61c3c73
# note: these dependencies are all optional
TERMUX_PKG_BUILD_DEPENDS=python,zstd,libprotobuf,fmt,eigen,valgrind,opencv,gflags,liblmdb,leveldb,openmpi,fftw,ffmpeg
_PYTHON_MAJOR_VERSION="$(. $TERMUX_SCRIPTDIR/packages/python/build.sh; echo ${TERMUX_PKG_VERSION%.*})" # 3.10 at time of writing
TERMUX_PKG_HOSTBUILD=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DBUILD_TEST=OFF
-DBUILD_CUSTOM_PROTOBUF=OFF
-DUSE_CCACHE=OFF
-DUSE_FFMPEG=ON
-DUSE_LEVELDB=ON
-DUSE_LMDB=ON
-DUSE_FFTW=ON
-DUSE_OPENMP=ON
-DPROTOBUF_PROTOC_EXECUTABLE=$TERMUX_PKG_HOSTBUILD_DIR/build_host_protoc/bin/protoc
-DCAFFE2_CUSTOM_PROTOC_EXECUTABLE=$TERMUX_PKG_HOSTBUILD_DIR/build_host_protoc/bin/protoc
-DANDROID_NDK=$NDK
-DANDROID_NDK_HOST_SYSTEM_NAME=linux-$HOSTTYPE
-DNATIVE_BUILD_DIR=$TERMUX_PKG_HOSTBUILD_DIR/sleef
-DPYTHON_EXECUTABLE=$(which python${_PYTHON_MAJOR_VERSION})
-DPYTHON_INCLUDE_DIR=$PREFIX/include/python${_PYTHON_MAJOR_VERSION}
-DPYTHON_LIBRARY=$PREFIX/lib/libpython${_PYTHON_MAJOR_VERSION}.so.1.0
-DPYTHONLIBS_FOUND=ON
-DPYTHONLIBS_VERSION_STRING=${_PYTHON_MAJOR_VERSION}
"

termux_step_host_build() {
	# use the protoc build script from pytorch to build the protoc from termux so the header versions align
	local PYTORCH_HOSTBUILD_DIR="$TERMUX_PKG_HOSTBUILD_DIR"
	(
		# link to pytorch script
		mkdir scripts
		ln -s "$TERMUX_PKG_SRCDIR"/scripts/build_host_protoc.sh scripts/

		# change termux pkg variables to libprotobuf, and extract it
		TERMUX_PKG_BUILDER_SCRIPT="$TERMUX_SCRIPTDIR"/packages/libprotobuf/build.sh
		termux_step_setup_variables
		termux_step_start_build
		cd "$TERMUX_PKG_CACHEDIR"
		termux_step_get_source

		# link to libprotobuf
		cd "$PYTORCH_HOSTBUILD_DIR"
		mkdir third_party
		ln -s "$TERMUX_PKG_SRCDIR" third_party/protobuf

		# build
		scripts/build_host_protoc.sh
	)

	# sleef uses an entire host build: https://github.com/shibatch/sleef/issues/249
	mkdir -p sleef
	cd sleef
	cmake -G Ninja "$TERMUX_PKG_SRCDIR"/third_party/sleef
	ninja all
}

termux_step_pre_configure() {
	# install python libs
	python${_PYTHON_MAJOR_VERSION} -m pip install --upgrade numpy pyyaml typing_extensions

	# ensure vulkan wrappers are present
	local VULKAN_ANDROID_NDK_WRAPPER_DIR="$NDK/sources/third_party/vulkan/src/common"
	mkdir -p "$VULKAN_ANDROID_NDK_WRAPPER_DIR"
	cp -v "$TERMUX_PKG_BUILDER_DIR"/vulkan_wrapper* "$VULKAN_ANDROID_NDK_WRAPPER_DIR"
}
