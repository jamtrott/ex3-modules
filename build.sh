#!/usr/bin/env bash
#
# Build modules and their dependencies
#
# Example usage: The following command will build openmpi and its
# dependencies, and install the modules and module files to the
# current user's home directory:
#
#   ./build.sh --prefix=$HOME openmpi/gcc/64/4.0.1
#
# The module can then be loaded as follows:
#
#   module use $HOME/modulefiles
#   MODULES_PREFIX=$HOME module load openmpi/gcc/64/4.0.1
#
#
set -o errexit

# Default options
PREFIX=/cm/shared/apps
MODULEFILESDIR=modulefiles
BUILD_DEPENDENCIES=
PRINT_DEPENDENCIES=
FORCE_REBUILD_DEPENDENCIES=
DRY_RUN=
top_modules=
STDOUT_LOG_PATH=build-output.log
STDERR_LOG_PATH=build-error.log
if [ -z "${JOBS}" ]; then
    # determine number of logical CPUs
    if command -v nproc >/dev/null 2>&1; then
        # Linux
        JOBS=$(nproc)
    elif command -v sysctl >/dev/null 2>&1; then
        # macOS
        JOBS=$(sysctl -n hw.ncpu)
    fi
fi

# Parse program options
help() {
    printf "Usage: ${0} [OPTION]... <MODULE>...\n"
    printf " Build modules and their dependencies"
    printf " Options are:\n"
    printf "  %-20s\t%s\n" "-h, --help" "display this help and exit"
    printf "  %-20s\t%s\n" "--prefix=PREFIX" "install files in PREFIX [${PREFIX}]"
    printf "  %-20s\t%s\n" "--modulefilesdir=DIR" "module files [PREFIX/${MODULEFILESDIR}]"
    printf "  %-20s\t%s\n" "--build-dependencies[=ARG]" "Build module dependencies [default=no]"
    printf "  %-20s\t%s\n" "--print-dependencies" "Print module dependencies"
    printf "  %-20s\t%s\n" "--dry-run" "Print the commands that would be executed, but do not execute them"
    printf "  %-20s\t%s\n" "-j [N], --jobs[=N]" "Allow N jobs at once."
    exit 1
}

while [ "$#" -gt 0 ]; do
    case "${1}" in
	-h | --help) help; exit 0;;
	--prefix=*) PREFIX="${1#*=}"; shift 1;;
	--modulefilesdir=*) MODULEFILESDIR="${1#*=}"; shift 1;;
	--build-dependencies | --build-dependencies=yes) BUILD_DEPENDENCIES=1; shift 1;;
	--print-dependencies) PRINT_DEPENDENCIES=1; shift 1;;
	--force-rebuild-dependencies) FORCE_REBUILD_DEPENDENCIES=1; BUILD_DEPENDENCIES=1; shift 1;;
	--dry-run) DRY_RUN=1; shift 1;;
	-j) case "${2}" in
		''|*[!0-9]*) JOBS=""; shift 1;;
		*) JOBS="${2}"; shift 2;;
	    esac ;;
	-j*) JOBS="${1#j}"; shift 1;;
        --jobs=*) JOBS="${1#*=}"; shift 1;;
	--) shift; break;;
	-*) echo "unknown option: ${1}" >&2; exit 1;;
	*) top_modules="${top_modules} ${1}"; shift 1;;
    esac
done
if [ -z "${top_modules}" ]; then
    help
fi

function init_log() {
    echo -n "" > ${STDOUT_LOG_PATH}
    echo -n "" > ${STDERR_LOG_PATH}
}

function log() {
    LOG_PATH=$1
    (
	while IFS= read -r line; do
	    printf '[%s] %s\n' "$(date +"%Y-%m-%d %T")" "$line";
	done
    ) | tee -a ${LOG_PATH}
}

function build_deps()
{
    module=$1

    module_build_deps="modules/${module}/build_deps"
    if [ ! -f "${module_build_deps}" ]; then
	printf "%s: No such file or directory\n" "${module_build_deps}" >&2
	exit 1
    fi

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
    printf "%s: Building %s\n" "${0}" "${module}"
    if [ -z ${DRY_RUN} ]; then
	pushd modules/${module}
	DESTDIR=${DESTDIR} MODULES_PREFIX=${DESTDIR} JOBS=${JOBS} \
	       ./build.sh \
	       --prefix=${PREFIX} \
	       --modulefilesdir=${MODULEFILESDIR}
	popd
    else
	echo "pushd modules/${module}"
	echo "DESTDIR=${DESTDIR} MODULES_PREFIX=${DESTDIR} " \
	     "./build.sh " \
	     "--prefix=${PREFIX} " \
	     "--modulefilesdir=${MODULEFILESDIR}"
	echo "popd"
    fi
    printf "%s: Done building %s\n" "${0}" "${module}"
}

function build_modules()
{
    modules=$1
    printf "%s: Building the following modules:\n%s\n" "${0}" "${modules}"

    if [ -z ${DRY_RUN} ]; then
	mkdir -p ${PREFIX}/${MODULEFILESDIR}
	module use ${PREFIX}/${MODULEFILESDIR}
    else
	echo "mkdir -p ${PREFIX}/${MODULEFILESDIR}"
	echo "module use ${PREFIX}/${MODULEFILESDIR}"
    fi
    for module in ${modules}; do
        # Use `module is-avail` to query the availability of a module, and use
        # the return code to determine if it is already built.
        # We need to temporarily disable termination on non-zero return codes in
        # order for this to work.
        set +o errexit
        eval module is-avail ${module}
        retval=$?
        set -o errexit
        is_top_module=0
        for top_module in $top_modules; do
            if [ "$module" = "${top_module}" ]; then
                is_top_module=1
            fi
        done
        if [ 0 -eq ${is_top_module} ] && [ ${retval} -eq 0 ] && [ -z "${FORCE_REBUILD_DEPENDENCIES}" ]; then
            echo "Skipping building of dependency ${module}, since it has already been built"
            continue
        fi
        build_module ${module}
    done
}

init_log

modules="${top_modules}"
if [ ! -z "${BUILD_DEPENDENCIES}" ] || [ ! -z "${PRINT_DEPENDENCIES}" ]; then
    # Get a list of required build-time dependencies by recursively
    # traversing modules and their dependencies.
    module_dependencies=
    for top_module in ${top_modules}; do
	module_dependencies="${module_dependencies} $(build_deps ${top_module})"
    done

    # Obtain a list of modules that must be built through a topological
    # sorting of the dependency list
    modules=$(printf "${module_dependencies}\n" | tsort | tac)

    if [ ! -z "${PRINT_DEPENDENCIES}" ]; then
	printf "%s\n" "${modules}"
	exit 1
    fi
fi

# Build the required modules
(build_modules "${modules}" | log ${STDOUT_LOG_PATH}) 3>&1 1>&2 2>&3 | log ${STDERR_LOG_PATH}
