#!/usr/bin/env bash
#
# Build hpl
#
# The following command will build the module, write a module file,
# and install them to the directory 'modules' in your home directory:
#
#   build.sh --prefix=$HOME/modules 2>&1 | tee build.log
#
# The module can then be loaded as follows:
#
#   module use $HOME/modules/modulefiles
#   module load hpl
#
set -o errexit

. ../../../common/module.sh

pkg_name=hpl
pkg_version=2.3
pkg_moduledir="${pkg_name}/${pkg_version}"
pkg_description="Portable implementation of the High-Performance Linpack Benchmark for distributed-memory computers"
pkg_url="http://www.netlib.org/benchmark/hpl/"
src_url="http://www.netlib.org/benchmark/hpl/hpl-${pkg_version}.tar.gz"
src_dir="${pkg_name}-${pkg_version}"

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
    ./configure --prefix="${pkg_prefix}"
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
setenv ${pkg_name^^}_LIBDIR ${pkg_prefix}/lib
setenv ${pkg_name^^}_LIBRARYDIR ${pkg_prefix}/lib
prepend-path PATH ${pkg_prefix}/bin
prepend-path LIBRARY_PATH ${pkg_prefix}/lib
set MSG "${pkg_name} ${pkg_version}"
EOF

    module_build_cleanup "${pkg_build_dir}"
}

main "$@"