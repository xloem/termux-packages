TERMUX_SUBPKG_DESCRIPTION="Python bindings for PyTorch"
TERMUX_SUBPKG_INCLUDE="lib/python$(. $TERMUX_SCRIPTDIR/packages/python/build.sh; echo $_MAJOR_VERSION)/site-packages/torch"
