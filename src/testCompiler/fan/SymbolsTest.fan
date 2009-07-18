//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   13 Jul 09  Brian Frank  Creation
//

using compiler

**
** SymbolsTest
**
class SymbolsTest : CompilerTest
{

//////////////////////////////////////////////////////////////////////////
// Basics
//////////////////////////////////////////////////////////////////////////

  Void testBasics()
  {
    symbolsStr =
    "Int foo := 3
     bar := 10sec"
    compile("class Foo {}")

    x := pod.symbol("foo")
    verifyEq(x.name, "foo")
    verifyEq(x.qname, "${pod.name}::foo")
    verifyEq(x.pod, pod)
    verifyEq(x.of, Int#)
    verifyEq(x.val, 3)

    x = pod.symbol("bar")
    verifyEq(x.name, "bar")
    verifyEq(x.qname, "${pod.name}::bar")
    verifyEq(x.pod, pod)
    verifyEq(x.of, Duration#)
    verifyEq(x.val, 10sec)
  }

//////////////////////////////////////////////////////////////////////////
// Const Folding
//////////////////////////////////////////////////////////////////////////

  Void testConstFolding()
  {
    symbolsStr =
    """a := -3
       b := 30 * -7
       c := "foo" + "bar"
       """
    compile("class Foo {}")

    x := pod.symbol("a"); verifyEq(x.of, Int#); verifyEq(x.val, -3)
    x = pod.symbol("b");  verifyEq(x.of, Int#); verifyEq(x.val, -210)
    x = pod.symbol("c");  verifyEq(x.of, Str#); verifyEq(x.val, "foobar")
  }

//////////////////////////////////////////////////////////////////////////
// Intra-Pod
//////////////////////////////////////////////////////////////////////////

  Void testIntraPod()
  {
    symbolsStr =
    "Int a := -3
     b := 10sec"
    compile(
    "class Foo
     {
       Symbol a() { @a }
       Symbol b() { @${podName}::b }
       Obj? av() { @a.val }
       Obj? bv() { @${podName}::b.val }
     }")

    obj := pod.types.first.make
    verifySame(obj->a, pod.symbol("a"))
    verifySame(obj->b, pod.symbol("b"))
    verifyEq(obj->av, -3)
    verifyEq(obj->bv, 10sec)
  }

//////////////////////////////////////////////////////////////////////////
// Inter-Pod
//////////////////////////////////////////////////////////////////////////

  Void testInterPod()
  {
    x := podName
    symbolsStr =
    "a := \"x.a\"
     d1 := 3"
    compile("class Foo {}")
    xp := pod

    y := podName
    symbolsStr =
    "b := \"y.b\"
     d1 := 4
     d2 := 5"
    compile("class Foo {}")
    yp := pod

    z := podName
    symbolsStr =
    "c := \"z.c\"
     d2 := 6"
    compile(
    "using $x
     using $y
     class Foo
     {
       Symbol a1() { @a }
       Symbol a2() { @${x}::a }
       Symbol b1() { @b }
       Symbol b2() { @${y}::b }
       Symbol c1() { @c }
       Symbol c2() { @${z}::c }
     }")
    zp := pod

    obj := pod.types.first.make
    verifySame(obj->a1, xp.symbol("a"))
    verifySame(obj->a2, xp.symbol("a"))
    verifySame(obj->b1, yp.symbol("b"))
    verifySame(obj->b2, yp.symbol("b"))
    verifySame(obj->c1, zp.symbol("c"))
    verifySame(obj->c2, zp.symbol("c"))

    symbolsStr =
    "d2 := 6"
    verifyErrors(
    "using $x
     using $y
     class Foo
     {
       Symbol m05() { @d1 }
       Symbol m06() { @d2 }
       Symbol m07() { @foo }
       Symbol m08() { @foo::bar }
       Symbol m09() { @compiler::baz}
     }",
     [
       5, 18, "Ambiguous symbol '$x::d1' and '$y::d1'",
       6, 18, "Ambiguous symbol '$podName::d2' and '$y::d2'",
       7, 18, "Unresolved symbol 'foo'",
       8, 18, "Pod not found 'foo'",
       9, 18, "Unresolved symbol 'compiler::baz'",
     ])
  }

//////////////////////////////////////////////////////////////////////////
// Errors
//////////////////////////////////////////////////////////////////////////

  Void testErrors()
  {
    // ParseErrors
    podStr =
    "pod $podName {
     xx := 3
     xx := 4
     yy = 5 }"
    verifyErrors("class Foo {}",
     [
       3, 1, "Duplicate symbol name 'xx'",
       4, 4, "Expected ':=', not '='",
     ])

    // UnresolvedExpr
    podStr =
    "using compiler; pod $podName {
     a := @foo
     b := @bar::foo
     c := @compiler::baz
     d := 4.fooBar }"
    verifyErrors("class Foo {}",
     [
       2, 6, "Unresolved symbol 'foo'",
       3, 6, "Pod not found 'bar'",
       4, 6, "Unresolved symbol 'compiler::baz'",
       5, 8, "Unknown slot 'sys::Int.fooBar'",
     ])

    // CheckErrors
  podStr = "@js @js @nodoc @sys::nodoc pod $podName { }"
  verifyErrors(
        "@sys::simple @simple class Foo
         { @transient @sys::transient Int x }",
     [
       1, 1, "Duplicate facet 'sys::js'",
       1, 9, "Duplicate facet 'sys::nodoc'",
       2, 3, "Duplicate facet 'sys::transient'",
       1, 1, "Duplicate facet 'sys::simple'",
     ])

    // Assemble
    podStr =
    "using compiler; pod $podName {
     a := 4
     b := @a }"
    verifyErrors("class Foo {}",
     [
       3, 6, "Symbol value is not serializable: 'b' ('symbolLiteral' not serializable)",
     ])
  }
}