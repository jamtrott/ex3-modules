#!/usr/bin/env bash
#
# Build gcc
#
# The following command will build the module, write a module file,
# and temporarily install them to your home directory, so that you may
# test them before moving them to their final destinations:
#
#   DESTDIR=$HOME ./build.sh 2>&1 | tee build.log
#
# The module can then be loaded as follows:
#
#   module use $HOME/$prefix/$modulefilesdir
#   MODULES_PREFIX=$HOME module load gcc
#
set -o errexit

. ../../../common/module.sh

pkg_name=gcc
pkg_version=9.2.0
pkg_moduledir="${pkg_name}/${pkg_version}"
pkg_description="GNU Compiler Collection"
pkg_url="https://gcc.gnu.org"
src_url="ftp://ftp.fu-berlin.de/unix/languages/gcc/releases/gcc-${pkg_version}/gcc-${pkg_version}.tar.gz"
src_dir="${pkg_name}-${pkg_version}"
program_suffix="-${pkg_version%.*}"

function main()
{
    # Parse program options
    module_build_parse_command_line_args \
	"${0}" \
	"${pkg_name}" \
	"${pkg_version}" \
	"${pkg_moduledir}" \
	"${pkg_description}" \
	"${pkg_url}" \
	"$@"

    # Load build-time dependencies and determine prerequisite modules
    module_load_build_deps build_deps
    pkg_prereqs=$(module_prereqs prereqs)

    # Download and unpack source
    pkg_prefix=$(module_build_prefix "${prefix}" "${pkg_moduledir}")
    pkg_build_dir=$(module_build_create_build_dir "${pkg_name}" "${pkg_version}")
    pkg_src="${pkg_build_dir}/$(basename ${src_url})"
    module_build_download_package "${src_url}" "${pkg_src}"
    module_build_unpack "${pkg_src}" "${pkg_build_dir}"

    # Build
    pushd "${pkg_build_dir}/${src_dir}"
    mkdir -p build
    pushd build
    ../configure \
	--prefix="${pkg_prefix}" \
	--enable-languages=c,c++,fortran \
	--enable-checking=release \
	--disable-multilib \
	--program-suffix="${program_suffix}"
    make -j"${JOBS}"
    make install DESTDIR="${DESTDIR}"
    popd
    popd

    # Write the module file
    pkg_modulefile=$(module_build_modulefile "${prefix}" "${modulefilesdir}" "${pkg_moduledir}")
    mkdir -p "$(dirname ${pkg_modulefile})"
    cat >"${pkg_modulefile}" <<EOF
#%Module
# ${pkg_name} ${pkg_version}

proc ModulesHelp { } {
     puts stderr "\tSets up the environment for ${pkg_name} ${pkg_version}\n"
}

module-whatis "${pkg_description}"
module-whatis "${pkg_url}"

${pkg_prereqs}

set MODULES_PREFIX [getenv MODULES_PREFIX ""]
setenv CC \$MODULES_PREFIX${pkg_prefix}/bin/gcc${program_suffix}
setenv GCC \$MODULES_PREFIX${pkg_prefix}/bin/gcc${program_suffix}
setenv CXX \$MODULES_PREFIX${pkg_prefix}/bin/g++${program_suffix}
setenv FC \$MODULES_PREFIX${pkg_prefix}/bin/gfortran${program_suffix}
setenv F77 \$MODULES_PREFIX${pkg_prefix}/bin/gfortran${program_suffix}
setenv F90 \$MODULES_PREFIX${pkg_prefix}/bin/gfortran${program_suffix}
setenv F95 \$MODULES_PREFIX${pkg_prefix}/bin/gfortran${program_suffix}
prepend-path PATH \$MODULES_PREFIX${pkg_prefix}/bin
prepend-path C_INCLUDE_PATH \$MODULES_PREFIX${pkg_prefix}/include
prepend-path CPLUS_INCLUDE_PATH \$MODULES_PREFIX${pkg_prefix}/include
prepend-path LIBRARY_PATH \$MODULES_PREFIX${pkg_prefix}/lib
prepend-path LIBRARY_PATH \$MODULES_PREFIX${pkg_prefix}/libx32
prepend-path LIBRARY_PATH \$MODULES_PREFIX${pkg_prefix}/lib32
prepend-path LIBRARY_PATH \$MODULES_PREFIX${pkg_prefix}/lib64
prepend-path LD_LIBRARY_PATH \$MODULES_PREFIX${pkg_prefix}/lib
prepend-path LD_LIBRARY_PATH \$MODULES_PREFIX${pkg_prefix}/libx32
prepend-path LD_LIBRARY_PATH \$MODULES_PREFIX${pkg_prefix}/lib32
prepend-path LD_LIBRARY_PATH \$MODULES_PREFIX${pkg_prefix}/lib64
prepend-path MANPATH \$MODULES_PREFIX${pkg_prefix}/share/man
prepend-path INFOPATH \$MODULES_PREFIX${pkg_prefix}/share/info
set MSG "${pkg_name} ${pkg_version}"
EOF

    module_build_cleanup "${pkg_build_dir}"
}

main "$@"
