#!/usr/bin/env bash
#
# Build fenics
#
# The following command will build the module, write a module file,
# and install them to the directory 'modules' in your home directory:
#
#   build.sh --prefix=$HOME/modules 2>&1 | tee build.log
#
# The module can then be loaded as follows:
#
#   module use $HOME/modules/modulefiles
#   module load fenics
#
set -o errexit

pkg_name=fenics
pkg_version=2019.1.0
pkg_moduledir="${pkg_name}/${pkg_version}"
pkg_description="Computing platform for solving partial differential equations"
pkg_url="https://fenicsproject.org"

function main()
{
    . ../../../common/module.sh

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

    # Nothing to build

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

set MSG "${pkg_name} ${pkg_version}"
EOF
}

main "$@"
