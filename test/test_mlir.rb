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
end
