# frozen_string_literal: true

require "test_helper"

class TestMLIR < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::MLIR::VERSION
  end

  def test_mlir_context_create
    context = MLIR::CAPI.mlirContextCreate
    MLIR::CAPI.mlirContextDestroy(context)
  end

  def test_mlir_register_all_dialects
    context = MLIR::CAPI.mlirContextCreate
    MLIR::CAPI.registerAllUpstreamDialects(context)
    MLIR::CAPI.mlirContextDestroy(context)
  end

  def test_mlirStringRefCreateFromCString
    MLIR::CAPI.mlirStringRefCreateFromCString("hello")
  end

  def test_mlirContextGetOrLoadDialect
    context = MLIR::CAPI.mlirContextCreate
    MLIR::CAPI.registerAllUpstreamDialects(context)
    MLIR::CAPI.mlirContextGetOrLoadDialect(context, MLIR::CAPI.mlirStringRefCreateFromCString("arith"))
    MLIR::CAPI.mlirContextDestroy(context)
  end
end
