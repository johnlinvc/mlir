# frozen_string_literal: true

require_relative "mlir/version"
require "ffi"
require "forwardable"

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

    # mapped from MlirNamedAttribute
    class MlirNamedAttribute < FFI::Struct
      layout :name, MlirIdentifier.by_value,
             :attribute, MlirAttribute.by_value
    end

    # mapped from MlirStringRef
    class MlirStringRef < FFI::Struct
      layout :data, :pointer,
             :length, :size_t
    end

    # mapped from MlirOperationState
    class MlirOperationState < FFI::Struct
      layout :name, MlirStringRef.by_value,
             :location, MlirLocation.by_value,
             :nResults, :int,
             :results, :pointer,
             :nOperands, :int,
             :operands, :pointer,
             :nRegions, :int,
             :regions, :pointer,
             :nSuccessors, :int,
             :successors, :pointer,
             :nAttributes, :int,
             :attributes, :pointer,
             :enableResultTypeInference, :bool
    end

    # Helper class to create C array of Mlir C API structs
    class MlirArrayRef
      attr_reader :array, :klass, :item_size

      extend Forwardable
      include Enumerable
      def_delegators :@array, :each, :size

      def initialize(array)
        @klass = array.first.class
        @item_size = klass.size
        @array_ref = FFI::MemoryPointer.new(:pointer, array.size * item_size)
        copy_values(array)
      end

      def copy_values(array)
        @array = array.each_with_index.collect do |item, index|
          x = klass.new(@array_ref + (index * item_size))
          item.members.each do |member|
            x[member] = item[member]
          end
        end
      end

      def to_ptr
        @array_ref
      end
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

    # Type related
    attach_function :mlirTypeDump, [MlirType.by_value], :void
    attach_function :mlirTypeParseGet, [MlirContext.by_value, MlirStringRef.by_value], MlirType.by_value

    # Attribute related
    attach_function :mlirAttributeParseGet, [MlirContext.by_value, MlirStringRef.by_value], MlirAttribute.by_value
    attach_function :mlirAttributeDump, [MlirAttribute.by_value], :void
    attach_function :mlirNamedAttributeGet, [MlirIdentifier.by_value, MlirAttribute.by_value],
                    MlirNamedAttribute.by_value

    # Identifier related
    attach_function :mlirIdentifierGet, [MlirContext.by_value, MlirStringRef.by_value], MlirIdentifier.by_value

    # Module related
    attach_function :mlirModuleCreateEmpty, [MlirLocation.by_value], MlirModule.by_value
    attach_function :mlirModuleGetBody, [MlirModule.by_value], MlirBlock.by_value

    # Region related
    attach_function :mlirRegionCreate, [], MlirRegion.by_value
    attach_function :mlirRegionAppendOwnedBlock, [MlirRegion.by_value, MlirBlock.by_value], :void

    # Block related
    attach_function :mlirBlockCreate, %i[size_t pointer pointer], MlirBlock.by_value
    attach_function :mlirBlockInsertOwnedOperation, [MlirBlock.by_value, :size_t, MlirOperation.by_value], :void

    # Operation related
    attach_function :mlirOperationStateGet, [MlirStringRef.by_value, MlirLocation.by_value], MlirOperationState.by_value
    attach_function :mlirOperationStateAddAttributes, [MlirOperationState.by_ref, :int, :pointer], :void
    attach_function :mlirOperationStateAddOwnedRegions, [MlirOperationState.by_ref, :int, :pointer], :void
    attach_function :mlirOperationCreate, [MlirOperationState.by_ref], MlirOperation.by_value

    module_function

    def register_all_upstream_dialects(context)
      dialect_registry = mlirDialectRegistryCreate
      mlirRegisterAllDialects(dialect_registry)
      mlirContextAppendDialectRegistry(context, dialect_registry)
      mlirDialectRegistryDestroy(dialect_registry)
    end
  end
end
