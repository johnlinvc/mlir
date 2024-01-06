# frozen_string_literal: true

require "test_helper"

describe MLIR do
  it "has a version number" do
    refute_nil MLIR::VERSION
  end

  it "creates and destroys MLIR context" do
    context = MLIR::CAPI.mlirContextCreate
    MLIR::CAPI.mlirContextDestroy(context)
  end

  it "registers all upstream dialects" do
    context = MLIR::CAPI.mlirContextCreate
    MLIR::CAPI.register_all_upstream_dialects(context)
    MLIR::CAPI.mlirContextDestroy(context)
  end

  it "creates string ref from C string" do
    MLIR::CAPI.mlirStringRefCreateFromCString("hello")
  end

  it "gets or loads dialect" do
    context = MLIR::CAPI.mlirContextCreate
    MLIR::CAPI.register_all_upstream_dialects(context)
    MLIR::CAPI.mlirContextGetOrLoadDialect(context, MLIR::CAPI.mlirStringRefCreateFromCString("arith"))
    MLIR::CAPI.mlirContextDestroy(context)
  end

  it "creates a unknown location" do
    context = MLIR::CAPI.mlirContextCreate
    MLIR::CAPI.mlirLocationUnknownGet(context)
  end

  it "get a index type" do
    context = MLIR::CAPI.mlirContextCreate
    MLIR::CAPI.mlirIndexTypeGet(context)
  end

  it "dumps a type" do
    context = MLIR::CAPI.mlirContextCreate
    index_type = MLIR::CAPI.mlirIndexTypeGet(context)
    MLIR::CAPI.mlirTypeDump(index_type)
  end

  it "create a attribute" do
    context = MLIR::CAPI.mlirContextCreate
    MLIR::CAPI.mlirAttributeParseGet(context, MLIR::CAPI.mlirStringRefCreateFromCString("0 : index"))
  end

  it "dump a attribute" do
    context = MLIR::CAPI.mlirContextCreate
    attr = MLIR::CAPI.mlirAttributeParseGet(context, MLIR::CAPI.mlirStringRefCreateFromCString("0 : index"))
    MLIR::CAPI.mlirAttributeDump(attr)
  end

  it "create a identifier" do
    context = MLIR::CAPI.mlirContextCreate
    MLIR::CAPI.mlirIdentifierGet(context, MLIR::CAPI.mlirStringRefCreateFromCString("value"))
  end

  it "create a named attribute" do
    context = MLIR::CAPI.mlirContextCreate
    index_zero_literal = MLIR::CAPI.mlirAttributeParseGet(context,
                                                          MLIR::CAPI.mlirStringRefCreateFromCString("0 : index"))
    identifier = MLIR::CAPI.mlirIdentifierGet(context, MLIR::CAPI.mlirStringRefCreateFromCString("value"))
    MLIR::CAPI.mlirNamedAttributeGet(identifier, index_zero_literal)
  end

  it "create a empty module" do
    context = MLIR::CAPI.mlirContextCreate
    location = MLIR::CAPI.mlirLocationUnknownGet(context)
    MLIR::CAPI.mlirModuleCreateEmpty(location)
  end

  describe "full test" do
    before do
      @context = MLIR::CAPI.mlirContextCreate
      MLIR::CAPI.register_all_upstream_dialects(@context)
      MLIR::CAPI.mlirContextGetOrLoadDialect(@context, MLIR::CAPI.mlirStringRefCreateFromCString("func"))
      MLIR::CAPI.mlirContextGetOrLoadDialect(@context, MLIR::CAPI.mlirStringRefCreateFromCString("memref"))
      MLIR::CAPI.mlirContextGetOrLoadDialect(@context, MLIR::CAPI.mlirStringRefCreateFromCString("shape"))
      MLIR::CAPI.mlirContextGetOrLoadDialect(@context, MLIR::CAPI.mlirStringRefCreateFromCString("scf"))
    end
    after do
      MLIR::CAPI.mlirContextDestroy(@context)
    end
    it "construct And Traverse IR" do
      location = MLIR::CAPI.mlirLocationUnknownGet(@context)
      module_op = MLIR::CAPI.mlirModuleCreateEmpty(location)
      module_body = MLIR::CAPI.mlirModuleGetBody(module_op)
      memref_type = MLIR::CAPI.mlirTypeParseGet(@context, MLIR::CAPI.mlirStringRefCreateFromCString("memref<?xf32>"))
      func_body_region = MLIR::CAPI.mlirRegionCreate
      func_body_arg_types = MLIR::CAPI::MlirArrayRef.new([memref_type, memref_type]).to_ptr
      func_body_arg_locs = MLIR::CAPI::MlirArrayRef.new([location, location]).to_ptr
      func_body = MLIR::CAPI.mlirBlockCreate(2, func_body_arg_types, func_body_arg_locs)
    end
  end
end
