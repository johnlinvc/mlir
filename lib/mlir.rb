# frozen_string_literal: true

require_relative "mlir/version"
require "ffi"
require "forwardable"

module MLIR
  class Error < StandardError; end
  MLIR::LIB_NAME = ENV["MLIR_LIB_NAME"] || "MLIR-C"
  # FFI wrapper for MLIR C API
  module CAPI
    extend FFI::Library
    ffi_lib(MLIR::LIB_NAME)
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

    class MlirDialectHandle < FFI::Struct
      layout :ptr, :pointer
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
             :results, MlirType.by_ref,
             :nOperands, :int,
             :operands, MlirValue.by_ref,
             :nRegions, :int,
             :regions, MlirRegion.by_ref,
             :nSuccessors, :int,
             :successors, MlirBlock.by_ref,
             :nAttributes, :int,
             :attributes, MlirNamedAttribute.by_ref,
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
          x
        end
      end

      def to_ptr
        @array_ref
      end

      def to_typed_ptr
        @array[0]
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
    attach_function :mlirDialectHandleRegisterDialect, [MlirDialectHandle.by_value, MlirContext.by_value], :void
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
    attach_function :mlirModuleGetOperation, [MlirModule.by_value], MlirOperation.by_value
    attach_function :mlirModuleFromOperation, [MlirOperation.by_value], MlirModule.by_value
    attach_function :mlirModuleDestroy, [MlirModule.by_value], :void
    attach_function :mlirModuleCreateParse, [MlirContext.by_value, MlirStringRef.by_value], MlirModule.by_value

    # Region related
    attach_function :mlirRegionCreate, [], MlirRegion.by_value
    attach_function :mlirRegionAppendOwnedBlock, [MlirRegion.by_value, MlirBlock.by_value], :void

    # Block related
    attach_function :mlirBlockCreate, [:size_t, MlirType.by_ref, MlirLocation.by_ref], MlirBlock.by_value
    attach_function :mlirBlockInsertOwnedOperation, [MlirBlock.by_value, :size_t, MlirOperation.by_value], :void
    attach_function :mlirBlockAppendOwnedOperation, [MlirBlock.by_value, MlirOperation.by_value], :void
    attach_function :mlirBlockGetArgument, [MlirBlock.by_value, :int], MlirValue.by_value
    attach_function :mlirBlockAddArgument, [MlirBlock.by_value, MlirRegion.by_value, MlirLocation.by_value], :void

    # OperationState related
    attach_function :mlirOperationStateGet, [MlirStringRef.by_value, MlirLocation.by_value], MlirOperationState.by_value
    attach_function :mlirOperationStateAddAttributes, [MlirOperationState.by_ref, :int, MlirNamedAttribute.by_ref],
                    :void
    attach_function :mlirOperationStateAddOwnedRegions, [MlirOperationState.by_ref, :int, MlirRegion.by_ref], :void
    attach_function :mlirOperationStateAddResults, [MlirOperationState.by_ref, :int, MlirType.by_ref], :void
    attach_function :mlirOperationStateAddOperands, [MlirOperationState.by_ref, :int, MlirValue.by_ref], :void
    attach_function :mlirOperationGetResult, [MlirOperation.by_value, :int], MlirValue.by_value

    # Operation related
    attach_function :mlirOperationCreate, [MlirOperationState.by_ref], MlirOperation.by_value
    attach_function :mlirOperationDump, [MlirOperation.by_value], :void

    module_function

    def register_all_upstream_dialects(context)
      dialect_registry = mlirDialectRegistryCreate
      mlirRegisterAllDialects(dialect_registry)
      mlirContextAppendDialectRegistry(context, dialect_registry)
      mlirDialectRegistryDestroy(dialect_registry)
    end
  end
end
