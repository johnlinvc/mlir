require 'mkmf'
require 'pathname'

RbConfig::MAKEFILE_CONFIG['CC']='clang'
RbConfig::MAKEFILE_CONFIG['CXX']='clang++'
# homebrew_clang_dir = "/opt/homebrew/opt/llvm"
# dir_config("clang","#{homebrew_clang_dir}/include","#{homebrew_clang_dir}/lib")
llvm_dir = "/Users/johnlinvc/projs/ruby-mlir/llvm-project"
dir_config("llvm", "#{llvm_dir}/mlir/include/", "#{llvm_dir}/build/lib/")

# Dir["#{llvm_dir}/build/lib/*.a"].each do |lib|
#   File.basename(lib) =~ /lib(.*)\.a/
#   have_library($1)
# end
have_library("MLIR-C", "mlirContextCreate")
headers = %w[
mlir-c/IR.h
mlir-c/AffineExpr.h
mlir-c/AffineMap.h
mlir-c/BuiltinAttributes.h
mlir-c/BuiltinTypes.h
mlir-c/Diagnostics.h
mlir-c/Dialect/Func.h
mlir-c/IntegerSet.h
mlir-c/RegisterEverything.h
mlir-c/Support.h
]
headers.each do |header|
    have_header(header)
end

create_makefile("ir")
