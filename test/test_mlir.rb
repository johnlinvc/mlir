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

  describe "with arith and test dialects" do
    before do
      @context = MLIR::CAPI.mlirContextCreate
      MLIR::CAPI.register_all_upstream_dialects(@context)
      MLIR::CAPI.mlirContextGetOrLoadDialect(@context, MLIR::CAPI.mlirStringRefCreateFromCString("arith"))
      MLIR::CAPI.mlirContextGetOrLoadDialect(@context, MLIR::CAPI.mlirStringRefCreateFromCString("test"))
    end
    after do
      MLIR::CAPI.mlirContextDestroy(@context)
    end
  end
end
