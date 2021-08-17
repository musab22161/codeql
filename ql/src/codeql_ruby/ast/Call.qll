private import codeql_ruby.AST
private import internal.AST
private import internal.Call
private import internal.TreeSitter
private import codeql_ruby.dataflow.internal.DataFlowDispatch
private import codeql_ruby.dataflow.internal.DataFlowImplCommon

/**
 * A call.
 */
class Call extends Expr, TCall {
  override string getAPrimaryQlClass() { result = "Call" }

  /**
   * Gets the `n`th argument of this method call. In the following example, the
   * result for n=0 is the `IntegerLiteral` 0, while for n=1 the result is a
   * `Pair` (whose `getKey` returns the `SymbolLiteral` for `bar`, and
   * `getValue` returns the `IntegerLiteral` 1). Keyword arguments like this
   * can be accessed more naturally using the
   * `getKeywordArgument(string keyword)` predicate.
   * ```rb
   * foo(0, bar: 1)
   * yield 0, bar: 1
   * ```
   */
  final Expr getArgument(int n) { result = this.(CallImpl).getArgumentImpl(n) }

  /**
   * Gets an argument of this method call.
   */
  final Expr getAnArgument() { result = this.getArgument(_) }

  /**
   * Gets the value of the keyword argument whose key is `keyword`, if any. For
   * example, the result for `getKeywordArgument("qux")` in the following
   * example is the `IntegerLiteral` 123.
   * ```rb
   * foo :bar "baz", qux: 123
   * ```
   */
  final Expr getKeywordArgument(string keyword) {
    exists(Pair p |
      p = this.getAnArgument() and
      p.getKey().(SymbolLiteral).getValueText() = keyword and
      result = p.getValue()
    )
  }

  /**
   * Gets the number of arguments of this method call.
   */
  final int getNumberOfArguments() { result = this.(CallImpl).getNumberOfArgumentsImpl() }

  /** Gets a potential target of this call, if any. */
  final Callable getATarget() {
    exists(DataFlowCall c | this = c.getExpr() |
      result = viableCallable(c)
      or
      result = viableCallableLambda(c, _)
    )
  }

  override AstNode getAChild(string pred) {
    result = super.getAChild(pred)
    or
    pred = "getArgument" and result = this.getArgument(_)
  }
}

/**
 * A method call.
 */
class MethodCall extends Call, TMethodCall {
  override string getAPrimaryQlClass() { result = "MethodCall" }

  /**
   * Gets the receiver of this call, if any. For example:
   *
   * ```rb
   * foo.bar
   * Baz::qux
   * corge()
   * ```
   *
   * The result for the call to `bar` is the `Expr` for `foo`; the result for
   * the call to `qux` is the `Expr` for `Baz`; for the call to `corge` there
   * is no result.
   */
  final Expr getReceiver() { result = this.(MethodCallImpl).getReceiverImpl() }

  /**
   * Gets the name of the method being called. For example, in:
   *
   * ```rb
   * foo.bar x, y
   * ```
   *
   * the result is `"bar"`.
   */
  final string getMethodName() { result = this.(MethodCallImpl).getMethodNameImpl() }

  /**
   * Gets the block of this method call, if any.
   * ```rb
   * foo.each { |x| puts x }
   * ```
   */
  Block getBlock() { none() }

  override string toString() { result = "call to " + this.getMethodName() }

  override AstNode getAChild(string pred) {
    result = super.getAChild(pred)
    or
    pred = "getReceiver" and result = this.getReceiver()
    or
    pred = "getBlock" and result = this.getBlock()
  }
}

/**
 * A call to a setter method.
 * ```rb
 * self.foo = 10
 * a[0] = 10
 * ```
 */
class SetterMethodCall extends MethodCall {
  SetterMethodCall() { this = TMethodCallSynth(_, _, _, true, _) }

  final override string getAPrimaryQlClass() { result = "SetterMethodCall" }
}

/**
 * An element reference; a call to the `[]` method.
 * ```rb
 * a[0]
 * ```
 */
class ElementReference extends MethodCall, TElementReference {
  final override string getAPrimaryQlClass() { result = "ElementReference" }

  final override string toString() { result = "...[...]" }
}

/**
 * A call to `yield`.
 * ```rb
 * yield x, y
 * ```
 */
class YieldCall extends Call, TYieldCall {
  Ruby::Yield g;

  YieldCall() { this = TYieldCall(g) }

  final override string getAPrimaryQlClass() { result = "YieldCall" }

  final override string toString() { result = "yield ..." }
}

/**
 * A call to `super`.
 * ```rb
 * class Foo < Bar
 *   def baz
 *     super
 *   end
 * end
 * ```
 */
class SuperCall extends MethodCall, TSuperCall {
  final override string getAPrimaryQlClass() { result = "SuperCall" }
}

/**
 * A block argument in a method call.
 * ```rb
 * foo(&block)
 * ```
 */
class BlockArgument extends Expr, TBlockArgument {
  private Ruby::BlockArgument g;

  BlockArgument() { this = TBlockArgument(g) }

  final override string getAPrimaryQlClass() { result = "BlockArgument" }

  /**
   * Gets the underlying expression representing the block. In the following
   * example, the result is the `Expr` for `bar`:
   * ```rb
   * foo(&bar)
   * ```
   */
  final Expr getValue() { toGenerated(result) = g.getChild() }

  final override string toString() { result = "&..." }

  final override AstNode getAChild(string pred) {
    result = super.getAChild(pred)
    or
    pred = "getValue" and result = this.getValue()
  }
}