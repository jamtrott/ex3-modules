#!/usr/bin/env bash
#
# Build python
#
# The following command will build the module, write a module file,
# and install them to the directory 'modules' in your home directory:
#
#   build.sh --prefix=$HOME/modules 2>&1 | tee build.log
#
# The module can then be loaded as follows:
#
#   module use $HOME/modules/modulefiles
#   module load python
#
set -o errexit

. ../../../common/module.sh

pkg_name=python
pkg_version=3.7.4
pkg_moduledir="${pkg_name}/${pkg_version}"
pkg_description="Python programming language"
pkg_url="https://www.python.org/"
src_url="https://www.python.org/ftp/python/${pkg_version}/Python-${pkg_version}.tar.xz"
src_dir="Python-${pkg_version}"

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
    module_build_unpack "${pkg_src}" "${pkg_build_dir}" -x

    # Build
    pushd "${pkg_build_dir}/${src_dir}"
    # https://mail.python.org/pipermail/python-list/2018-December/738568.html
    LDFLAGS=$(pkg-config --libs-only-L libffi) ./configure \
	   --prefix="${pkg_prefix}" \
	   --enable-shared \
	   --enable-optimizations \
	   --with-ensurepip=install \
	   --with-system-ffi \
	   --with-openssl="${OPENSSL_ROOT}"
    make -j"${JOBS}"
    make install
    popd

    # Write the module file
    pkg_modulefile=$(module_build_modulefile "${prefix}" "${modulefilesdir}" "${pkg_moduledir}")
    cat >"${pkg_modulefile}" <<EOF
#%Module
# ${pkg_name} ${pkg_version}

proc ModulesHelp { } {
     puts stderr "\tSets up the environment for ${pkg_name} ${pkg_version}\n"
}

module-whatis "${pkg_description}"
module-whatis "${pkg_url}"

${pkg_prereqs}

setenv ${pkg_name^^}_ROOT ${pkg_prefix}
setenv ${pkg_name^^}_INCDIR ${pkg_prefix}/include
setenv ${pkg_name^^}_INCLUDEDIR ${pkg_prefix}/include
setenv ${pkg_name^^}_LIBDIR ${pkg_prefix}/lib
setenv ${pkg_name^^}_LIBRARYDIR ${pkg_prefix}/lib
setenv ${pkg_name^^}_VERSION ${pkg_version}
setenv ${pkg_name^^}_VERSION_SHORT ${pkg_version%.*}
prepend-path PATH ${pkg_prefix}/bin
prepend-path C_INCLUDE_PATH ${pkg_prefix}/include/python${pkg_version%.*}m
prepend-path CPLUS_INCLUDE_PATH ${pkg_prefix}/include/python${pkg_version%.*}m
prepend-path LIBRARY_PATH ${pkg_prefix}/lib
prepend-path LD_LIBRARY_PATH ${pkg_prefix}/lib
prepend-path PYTHONPATH ${pkg_prefix}/lib/python${pkg_version%.*}
prepend-path PKG_CONFIG_PATH ${pkg_prefix}/lib/pkgconfig
prepend-path MANPATH ${pkg_prefix}/share/man
set MSG "${pkg_name} ${pkg_version}"
EOF

    module_build_cleanup "${pkg_build_dir}"
}

main "$@"
