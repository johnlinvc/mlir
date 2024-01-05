# frozen_string_literal: true

require_relative "mlir/version"
require 'ffi'

module MLIR
  module CAPI
    class Error < StandardError; end
    extend FFI::Library
    ffi_lib 'MLIR-C'
    IR_C_API_STRUCT_SYMBOLS = %i[
      MlirAsmState
      MlirBytecodeWriterConfig
      MlirContext
      MlirDialect
      MlirDialectRegistry
      MlirOperation
      MlirOpOperand
      MlirOpPrintingFlags
      MlirBlock
      MlirRegion
      MlirSymbolTable
      MlirAttribute
      MlirIdentifier
      MlirLocation
      MlirModule
      MlirType
      MlirValue
    ]

    IR_C_API_STRUCT_SYMBOLS.each do |struct_symbol|
      klass = Class.new(FFI::Struct)
      klass.layout :storage,  :pointer
      Kernel.const_set(struct_symbol, klass)
    end

    class MlirStringRef < FFI::Struct
      layout :data,    :pointer,
            :length,  :size_t
    end

    attach_function :mlirContextCreate, [], MlirContext.by_value
    attach_function :mlirContextDestroy, [ MlirContext.by_value ], :void

    attach_function :mlirDialectRegistryCreate, [], MlirDialectRegistry.by_value
    attach_function :mlirDialectRegistryDestroy, [ MlirDialectRegistry.by_value ], :void
    attach_function :mlirRegisterAllDialects, [ MlirDialectRegistry.by_value ], :void
    attach_function :mlirContextAppendDialectRegistry, [ MlirContext.by_value, MlirDialectRegistry.by_value ], :void
    attach_function :mlirStringRefCreateFromCString, [ :string ], MlirStringRef.by_value
    attach_function :mlirContextGetOrLoadDialect, [ MlirContext.by_value, MlirStringRef.by_value ], :void

    module_function 
    def registerAllUpstreamDialects(context)
      dialectRegistry = self.mlirDialectRegistryCreate()
      self.mlirRegisterAllDialects(dialectRegistry)
      self.mlirContextAppendDialectRegistry(context, dialectRegistry)
      self.mlirDialectRegistryDestroy(dialectRegistry)
    end
  end



end
