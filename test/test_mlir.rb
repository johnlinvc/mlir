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
      # start makeAndDumpAdd
      module_op = MLIR::CAPI.mlirModuleCreateEmpty(location)
      module_body = MLIR::CAPI.mlirModuleGetBody(module_op)
      memref_type = MLIR::CAPI.mlirTypeParseGet(@context, MLIR::CAPI.mlirStringRefCreateFromCString("memref<?xf32>"))
      func_body_region = MLIR::CAPI.mlirRegionCreate
      func_body_arg_types = MLIR::CAPI::MlirArrayRef.new([memref_type, memref_type]).to_typed_ptr
      func_body_arg_locs = MLIR::CAPI::MlirArrayRef.new([location, location]).to_typed_ptr
      func_body = MLIR::CAPI.mlirBlockCreate(2, func_body_arg_types, func_body_arg_locs)
      MLIR::CAPI.mlirRegionAppendOwnedBlock(func_body_region, func_body)

      # line 111 in ir.c
      func_type_str = MLIR::CAPI.mlirStringRefCreateFromCString("(memref<?xf32>, memref<?xf32>) -> ()")
      func_type_attr = MLIR::CAPI.mlirAttributeParseGet(@context, func_type_str)
      func_type_id = MLIR::CAPI.mlirIdentifierGet(@context, MLIR::CAPI.mlirStringRefCreateFromCString("function_type"))
      named_func_type_attr = MLIR::CAPI.mlirNamedAttributeGet(func_type_id, func_type_attr)
      func_name_attr = MLIR::CAPI.mlirAttributeParseGet(@context, MLIR::CAPI.mlirStringRefCreateFromCString("\"add\""))
      func_name_id = MLIR::CAPI.mlirIdentifierGet(@context, MLIR::CAPI.mlirStringRefCreateFromCString("sym_name"))
      named_func_name_attr = MLIR::CAPI.mlirNamedAttributeGet(func_name_id, func_name_attr)
      func_attrs = MLIR::CAPI::MlirArrayRef.new([named_func_type_attr, named_func_name_attr])
      func_state = MLIR::CAPI.mlirOperationStateGet(MLIR::CAPI.mlirStringRefCreateFromCString("func.func"), location)
      MLIR::CAPI.mlirOperationStateAddAttributes(func_state, func_attrs.size, func_attrs.to_typed_ptr)
      MLIR::CAPI.mlirOperationStateAddOwnedRegions(func_state, 1, func_body_region)
      func = MLIR::CAPI.mlirOperationCreate(func_state)
      MLIR::CAPI.mlirBlockInsertOwnedOperation(module_body, 0, func)

      # line 131 in ir.c
      index_type = MLIR::CAPI.mlirTypeParseGet(@context, MLIR::CAPI.mlirStringRefCreateFromCString("index"))
      index_zero_literal = MLIR::CAPI.mlirAttributeParseGet(@context,
                                                            MLIR::CAPI.mlirStringRefCreateFromCString("0 : index"))
      index_zero_id = MLIR::CAPI.mlirIdentifierGet(@context, MLIR::CAPI.mlirStringRefCreateFromCString("value"))
      index_zero_value_attr = MLIR::CAPI.mlirNamedAttributeGet(index_zero_id, index_zero_literal)
      const_zero_state = MLIR::CAPI.mlirOperationStateGet(MLIR::CAPI.mlirStringRefCreateFromCString("arith.constant"),
                                                          location)
      MLIR::CAPI.mlirOperationStateAddResults(const_zero_state, 1, index_type)
      MLIR::CAPI.mlirOperationStateAddAttributes(const_zero_state, 1, index_zero_value_attr)
      const_zero = MLIR::CAPI.mlirOperationCreate(const_zero_state)
      MLIR::CAPI.mlirBlockAppendOwnedOperation(func_body, const_zero)

      # line 145 in ir.c
      func_arg0 = MLIR::CAPI.mlirBlockGetArgument(func_body, 0)
      const_zero_value = MLIR::CAPI.mlirOperationGetResult(const_zero, 0)
      dim_operands = MLIR::CAPI::MlirArrayRef.new([func_arg0, const_zero_value])
      dim_state = MLIR::CAPI.mlirOperationStateGet(MLIR::CAPI.mlirStringRefCreateFromCString("memref.dim"), location)
      MLIR::CAPI.mlirOperationStateAddOperands(dim_state, 2, dim_operands.to_typed_ptr)
      MLIR::CAPI.mlirOperationStateAddResults(dim_state, 1, index_type)
      dim = MLIR::CAPI.mlirOperationCreate(dim_state)
      MLIR::CAPI.mlirBlockAppendOwnedOperation(func_body, dim)

      # line 155 in ir.c
      loop_body_region = MLIR::CAPI.mlirRegionCreate
      loop_body = MLIR::CAPI.mlirBlockCreate(0, nil, nil)
      MLIR::CAPI.mlirBlockAddArgument(loop_body, index_type, location)
      MLIR::CAPI.mlirRegionAppendOwnedBlock(loop_body_region, loop_body)

      # line 160-170 in ir.c
      line_one_literal = MLIR::CAPI.mlirAttributeParseGet(@context,
                                                          MLIR::CAPI.mlirStringRefCreateFromCString("1 : index"))
      index_one_value_id = MLIR::CAPI.mlirIdentifierGet(@context, MLIR::CAPI.mlirStringRefCreateFromCString("value"))
      index_one_value_attr = MLIR::CAPI.mlirNamedAttributeGet(index_one_value_id, line_one_literal)
      const_one_state = MLIR::CAPI.mlirOperationStateGet(MLIR::CAPI.mlirStringRefCreateFromCString("arith.constant"),
                                                         location)
      MLIR::CAPI.mlirOperationStateAddResults(const_one_state, 1, index_type)
      MLIR::CAPI.mlirOperationStateAddAttributes(const_one_state, 1, index_one_value_attr)
      const_one = MLIR::CAPI.mlirOperationCreate(const_one_state)
      MLIR::CAPI.mlirBlockAppendOwnedOperation(func_body, const_one)

      # line 172-180 in ir.c
      dim_value = MLIR::CAPI.mlirOperationGetResult(dim, 0)
      const_one_value = MLIR::CAPI.mlirOperationGetResult(const_one, 0)
      loop_operands = MLIR::CAPI::MlirArrayRef.new([const_zero_value, dim_value, const_one_value])
      loop_state = MLIR::CAPI.mlirOperationStateGet(MLIR::CAPI.mlirStringRefCreateFromCString("scf.for"), location)
      MLIR::CAPI.mlirOperationStateAddOperands(loop_state, 3, loop_operands.to_typed_ptr)
      MLIR::CAPI.mlirOperationStateAddOwnedRegions(loop_state, 1, loop_body_region)
      loop = MLIR::CAPI.mlirOperationCreate(loop_state)
      MLIR::CAPI.mlirBlockAppendOwnedOperation(func_body, loop)

      # line 182 (53-57) in ir.c
      # start polulating loop body
      iv = MLIR::CAPI.mlirBlockGetArgument(loop_body, 0)
      func_arg0 = MLIR::CAPI.mlirBlockGetArgument(func_body, 0)
      func_arg1 = MLIR::CAPI.mlirBlockGetArgument(func_body, 1)
      f32_type = MLIR::CAPI.mlirTypeParseGet(@context, MLIR::CAPI.mlirStringRefCreateFromCString("f32"))

      # line 59-65 in ir.c
      load_lhs_state = MLIR::CAPI.mlirOperationStateGet(MLIR::CAPI.mlirStringRefCreateFromCString("memref.load"),
                                                        location)
      load_lhs_operands = MLIR::CAPI::MlirArrayRef.new([func_arg0, iv])
      MLIR::CAPI.mlirOperationStateAddOperands(load_lhs_state, 2, load_lhs_operands.to_typed_ptr)
      MLIR::CAPI.mlirOperationStateAddResults(load_lhs_state, 1, f32_type)
      load_lhs = MLIR::CAPI.mlirOperationCreate(load_lhs_state)
      MLIR::CAPI.mlirBlockAppendOwnedOperation(loop_body, load_lhs)

      # line 67-73 in ir.c
      load_rhs_state = MLIR::CAPI.mlirOperationStateGet(MLIR::CAPI.mlirStringRefCreateFromCString("memref.load"),
                                                        location)
      load_rhs_operands = MLIR::CAPI::MlirArrayRef.new([func_arg1, iv])
      MLIR::CAPI.mlirOperationStateAddOperands(load_rhs_state, 2, load_rhs_operands.to_typed_ptr)
      MLIR::CAPI.mlirOperationStateAddResults(load_rhs_state, 1, f32_type)
      load_rhs = MLIR::CAPI.mlirOperationCreate(load_rhs_state)
      MLIR::CAPI.mlirBlockAppendOwnedOperation(loop_body, load_rhs)

      # line 75-82 in ir.c
      add_state = MLIR::CAPI.mlirOperationStateGet(MLIR::CAPI.mlirStringRefCreateFromCString("arith.addf"), location)
      add_operands = MLIR::CAPI::MlirArrayRef.new([MLIR::CAPI.mlirOperationGetResult(load_lhs, 0),
                                                   MLIR::CAPI.mlirOperationGetResult(load_rhs, 0)])
      MLIR::CAPI.mlirOperationStateAddOperands(add_state, 2, add_operands.to_typed_ptr)
      MLIR::CAPI.mlirOperationStateAddResults(add_state, 1, f32_type)
      add = MLIR::CAPI.mlirOperationCreate(add_state)
      MLIR::CAPI.mlirBlockAppendOwnedOperation(loop_body, add)

      # line 84-90 in ir.c
      store_state = MLIR::CAPI.mlirOperationStateGet(MLIR::CAPI.mlirStringRefCreateFromCString("memref.store"),
                                                     location)
      store_operands = MLIR::CAPI::MlirArrayRef.new([MLIR::CAPI.mlirOperationGetResult(add, 0), func_arg0, iv])
      MLIR::CAPI.mlirOperationStateAddOperands(store_state, 3, store_operands.to_typed_ptr)
      store = MLIR::CAPI.mlirOperationCreate(store_state)
      MLIR::CAPI.mlirBlockAppendOwnedOperation(loop_body, store)

      # line 91-94 in ir.c
      yield_state = MLIR::CAPI.mlirOperationStateGet(MLIR::CAPI.mlirStringRefCreateFromCString("scf.yield"), location)
      yield_op = MLIR::CAPI.mlirOperationCreate(yield_state)
      MLIR::CAPI.mlirBlockAppendOwnedOperation(loop_body, yield_op)

      # end polulating loop body

      # line 184-190 in ir.c
      ret_state = MLIR::CAPI.mlirOperationStateGet(MLIR::CAPI.mlirStringRefCreateFromCString("func.return"), location)
      ret = MLIR::CAPI.mlirOperationCreate(ret_state)
      MLIR::CAPI.mlirBlockAppendOwnedOperation(func_body, ret)
      # module_op1 maps to module, because module is a keyword in ruby
      module_op1 = MLIR::CAPI.mlirModuleGetOperation(module_op)
      MLIR::CAPI.mlirOperationDump(module_op1)
      # end makeAndDumpAdd

      # line 509 in ir.c
      expect(MLIR::CAPI.mlirModuleFromOperation(module_op1).to_ptr).wont_equal(nil)

      # line 511 in ir.c
      # start collectStats (Skipped for now)
      # end collectStats (Skipped for now)

      # line 515 in ir.c
      # start printFirstOfEach (Skipped for now)
      # end printFirstOfEach (Skipped for now)

      # line 517 in ir.c
      MLIR::CAPI.mlirModuleDestroy(module_op)
    end
  end
end
