#!/usr/bin/env bash
#
# Build doxygen
#
# The following command will build the module, write a module file,
# and install them to the directory 'modules' in your home directory:
#
#   build.sh --prefix=$HOME/modules 2>&1 | tee build.log
#
# The module can then be loaded as follows:
#
#   module use $HOME/modules/modulefiles
#   module load doxygen
#
set -o errexit

. ../../../common/module.sh

pkg_name=doxygen
pkg_version=1.8.16
pkg_moduledir="${pkg_name}/${pkg_version}"
pkg_description="Tool for generating documentation from annotated C++ source code"
pkg_url="http://www.doxygen.nl/"
src_url="http://doxygen.nl/files/doxygen-1.8.16.src.tar.gz"
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
    mkdir -p build
    pushd build
    cmake -G "Unix Makefiles" .. \
	  -DCMAKE_INSTALL_PREFIX="${pkg_prefix}" \
	  -DPYTHON_EXECUTABLE="${PYTHON_ROOT}/bin/python3"
    make $([ ! -z "${JOBS}" ] && -j"${JOBS}")
    make install
    popd
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

set MODULES_PREFIX [getenv MODULES_PREFIX ""]
setenv ${pkg_name^^}_ROOT \$MODULES_PREFIX${pkg_prefix}
prepend-path PATH \$MODULES_PREFIX${pkg_prefix}/bin
set MSG "${pkg_name} ${pkg_version}"
EOF

    module_build_cleanup "${pkg_build_dir}"
}

main "$@"