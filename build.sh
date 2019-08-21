#!/bin/bash -e
#
# Build modules and their dependencies
#
# Example usage: The following command will build openmpi and its
# dependencies, and install the modules and module files to the
# current user's home directory:
#
#   ./build.sh --prefix=$HOME openmpi/gcc/4.0.1 2>&1 | tee build.log
#
# The module can then be loaded as follows:
#
#   module use $HOME/modulefiles
#   MODULES_PREFIX=$HOME module load openmpi/gcc/4.0.1
#
#

# Default options
PREFIX=/cm/shared/apps
MODULEFILESDIR=modulefiles
top_modules=
LOG_PATH=build.log

# Parse program options
help() {
    printf "Usage: ${0} [OPTION]... <MODULE>...\n"
    printf " Build modules and their dependencies"
    printf " Options are:\n"
    printf "  %-20s\t%s\n" "-h, --help" "display this help and exit"
    printf "  %-20s\t%s\n" "--prefix=PREFIX" "install files in PREFIX [${PREFIX}]"
    printf "  %-20s\t%s\n" "--modulefilesdir=DIR" "module files [PREFIX/${MODULEFILESDIR}]"
    exit 1
}

while [ "$#" -gt 0 ]; do
    case "${1}" in
	-h | --help) help; exit 0;;
	--prefix=*) PREFIX="${1#*=}"; shift 1;;
	--modulefilesdir=*) MODULEFILESDIR="${1#*=}"; shift 1;;
	--) shift; break;;
	-*) echo "unknown option: ${1}" >&2; exit 1;;
	*) top_modules="${top_modules} ${1}"; shift 1;;
    esac
done
if [ -z "${top_modules}" ]; then
    help
fi

function build_deps()
{
    module=$1
    module_build_deps="$(dirname ${module})/build_deps"
    (
	printf "%s %s\n" "${module}" "${module}"
	while read dep; do
	    printf "%s %s\n" "${module}" "${dep}"
	    printf "%s\n" "$(build_deps ${dep})"
	done<${module_build_deps}
    ) | cat
}

function build_module()
{
    module=$1
    echo "Building ${module}"
    if [ -z ${dry_run} ]; then
	pushd $(dirname ${module})
	DESTDIR=${DESTDIR} MODULES_PREFIX=${DESTDIR}${PREFIX} \
	       ./build.sh \
	       --prefix=${PREFIX} \
	       --modulefilesdir=${MODULEFILESDIR} \
	    | tee ${LOG_PATH}
	popd
    fi
    echo "Done building ${module}"
}

# Get a list of required build-time dependencies by recursively
# traversing modules and their dependencies.
module_dependencies=
for top_module in ${top_modules}; do
    module_dependencies="${module_dependencies} $(build_deps ${top_module})"
done

# Obtain a list of modules that must be built through a topological
# sorting of the dependency list
modules=$(printf "${module_dependencies}\n" | tsort | tac)

# Build the required modules
echo "Building the following modules:" | tee ${LOG_PATH}
echo "${modules}" | tee -a ${LOG_PATH}
(
    for module in ${modules}; do
	build_module ${module}
    done
) | tee -a ${LOG_PATH}