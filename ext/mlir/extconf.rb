require 'mkmf'
llvm_dir = "/Users/johnlinvc/projs/ruby-mlir/llvm-project"
dir_config("llvm", "#{llvm_dir}/mlir/include/", "#{llvm_dir}/build/lib/")
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
libs = headers.map do |header|
    header =~ /mlir-c\/(.*)\.h/
    "MLIRCAPI#{$~[1]}"
end
libs.each do |lib|
    have_library(lib)
end
have_header("mlir-c/Debug.h")
have_library("MLIRCAPIDebug")
create_makefile("mlir/extension")
