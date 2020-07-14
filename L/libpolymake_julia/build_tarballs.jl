# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder
import Pkg: PackageSpec

const name = "libpolymake_julia"
const version = v"0.0.3"

# Collection of sources required to build libpolymake_julia
const sources = [
    GitSource("https://github.com/oscar-system/libpolymake-julia.git",
              "068f92d7c3ab7745940b129cefd73522c9cddea3"),
]

# Bash recipe for building across all platforms
const script = raw"""
# work around weird LD_LIBRARY_PATH for linux targets:
# remove $libdir
if [[ -n "$LD_LIBRARY_PATH" ]]; then
LD_LIBRARY_PATH=$(echo -n $LD_LIBRARY_PATH | sed -e "s|[:^]$libdir\w*|:|g")
fi

cmake libpolymake-j*/ -B build \
   -DJulia_PREFIX="$prefix" \
   -DCMAKE_INSTALL_PREFIX="$prefix" \
   -DCMAKE_FIND_ROOT_PATH="$prefix" \
   -DCMAKE_TOOLCHAIN_FILE="${CMAKE_TARGET_TOOLCHAIN}" \
   -DCMAKE_BUILD_TYPE=Release

VERBOSE=ON cmake --build build --config Release --target install -- -j${nproc}

install_license $WORKSPACE/srcdir/libpolymake-j*/LICENSE.md
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
const platforms = expand_cxxstring_abis([
    Linux(:x86_64; libc=:glibc, compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
    MacOS(:x86_64; compiler_abi=CompilerABI(cxxstring_abi=:cxx11)),
])

# The products that we will ensure are always built
const products = [
    LibraryProduct("libpolymake_julia", :libpolymake_julia; dont_dlopen=true),
    FileProduct(joinpath("share","libpolymake_julia","type_translator.jl"),:type_translator),
    ExecutableProduct("polymake_run_script", :polymake_run_script),
]

# Dependencies that must be installed before this package can be built
const dependencies = [
    BuildDependency(PackageSpec(name="Julia_jll", version="v1.4.1")),
    Dependency(PackageSpec(name="libcxxwrap_julia_jll")),
    Dependency(PackageSpec(name="polymake_jll",uuid="7c209550-9012-526c-9264-55ba7a78ba2c",url="https://github.com/benlorenz/polymake_jll.jl")),
    Dependency(PackageSpec(name="CompilerSupportLibraries_jll", uuid="e66e0078-7015-5450-92f7-15fbd957f2ae"))
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; preferred_gcc_version=v"7")
