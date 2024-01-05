# frozen_string_literal: true

require_relative "mlir/version"
require "ffi"

module MLIR
  class Error < StandardError; end

  # FFI wrapper for MLIR C API
  module CAPI
    extend FFI::Library
    ffi_lib "MLIR-C"
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
    ].freeze

    IR_C_API_STRUCT_SYMBOLS.each do |struct_symbol|
      klass = Class.new(FFI::Struct)
      klass.layout :storage, :pointer
      Kernel.const_set(struct_symbol, klass)
    end

    # mapped from MlirStringRef
    class MlirStringRef < FFI::Struct
      layout :data, :pointer,
             :length, :size_t
    end

    attach_function :mlirContextCreate, [], MlirContext.by_value
    attach_function :mlirContextDestroy, [MlirContext.by_value], :void

    attach_function :mlirDialectRegistryCreate, [], MlirDialectRegistry.by_value
    attach_function :mlirDialectRegistryDestroy, [MlirDialectRegistry.by_value], :void
    attach_function :mlirRegisterAllDialects, [MlirDialectRegistry.by_value], :void
    attach_function :mlirContextAppendDialectRegistry, [MlirContext.by_value, MlirDialectRegistry.by_value], :void
    attach_function :mlirStringRefCreateFromCString, [:string], MlirStringRef.by_value
    attach_function :mlirContextGetOrLoadDialect, [MlirContext.by_value, MlirStringRef.by_value], :void
    attach_function :mlirLocationUnknownGet, [MlirContext.by_value], MlirLocation.by_value
    attach_function :mlirIndexTypeGet, [MlirContext.by_value], MlirType.by_value
    attach_function :mlirTypeDump, [MlirType.by_value], :void
    attach_function :mlirAttributeParseGet, [MlirContext.by_value, MlirStringRef.by_value], MlirAttribute.by_value
    attach_function :mlirAttributeDump, [MlirAttribute.by_value], :void

    module_function

    def register_all_upstream_dialects(context)
      dialect_registry = mlirDialectRegistryCreate
      mlirRegisterAllDialects(dialect_registry)
      mlirContextAppendDialectRegistry(context, dialect_registry)
      mlirDialectRegistryDestroy(dialect_registry)
    end
  end
end
