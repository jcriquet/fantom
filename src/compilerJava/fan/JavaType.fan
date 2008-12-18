//
// Copyright (c) 2008, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   17 Nov 08  Brian Frank  Creation
//

using compiler

**
** JavaType is the implementation of CType for a Java class.
**
class JavaType : CType
{

//////////////////////////////////////////////////////////////////////////
// Construction
//////////////////////////////////////////////////////////////////////////

  **
  ** Construct with loaded Type.
  **
  new make(JavaPod pod, Str name)
  {
    this.pod    = pod
    this.name   = name
    this.qname  = pod.name + "::" + name
    this.base   = ns.objType
    this.mixins = CType[,]
  }

//////////////////////////////////////////////////////////////////////////
// CType
//////////////////////////////////////////////////////////////////////////

  override CNamespace ns() { return pod.ns }
  override readonly JavaPod pod
  override readonly Str name
  override readonly Str qname
  override Str signature() { return qname }

  override CType? base { get { load; return @base } internal set}
  override CType[] mixins { get { load; return @mixins } internal set }
  override Int flags { get { load; return @flags } internal set }

  override Bool isForeign() { return true }
  override Bool isSupported() { return arrayRank <= 1 } // multi-dimensional arrays unsupported

  override Bool isValue() { return false }

  override Bool isNullable() { return false }
  override once CType toNullable() { return NullableType(this) }

  override Bool isGeneric() { return false }
  override Bool isParameterized() { return false }
  override Bool isGenericParameter() { return false }

  override once CType toListOf() { return ListType(this) }

  override readonly Str:CSlot slots { get { load; return @slots } }

  override CSlot? slot(Str name) { return slots[name] }

  ** Handle the case where a field and method have the same
  ** name; in this case the field will always be first with
  ** a linked list to the overloaded methods
  override CMethod? method(Str name)
  {
    x := slots[name]
    if (x == null) return null
    if (x is JavaField) return ((JavaField)x).next
    return x
  }

  override CType inferredAs()
  {
    if (isPrimitive)
      return name == "float" ? ns.floatType : ns.intType

    if (isArray && !arrayOf.isPrimitive && !arrayOf.isArray)
      return inferredArrayOf.toListOf

    return this
  }

//////////////////////////////////////////////////////////////////////////
// Fits
//////////////////////////////////////////////////////////////////////////

  override Bool fits(CType t)
  {
    if (CType.super.fits(t)) return true
    t = t.toNonNullable
    if (t is JavaType) return fitsJava(t)
    return fitsFan(t)
  }

  private Bool fitsJava(JavaType t)
  {
    // * => java.lang.Object
    if (t.qname == "[java]java.lang::Object") return !isPrimitive

    // array => array
    if (isArray && t.isArray) return arrayOf.fits(t.arrayOf)

    // doesn't fit
    return false
  }

  private Bool fitsFan(CType t)
  {
    // floats => Float; byte,short,char,int => Int
    if (isPrimitive) return name == "float" ? t.isFloat : t.isInt

    // arrays => List
    if (isArray && t is ListType) return arrayOf.fits(((ListType)t).v)

    // doesn't fit
    return false
  }

//////////////////////////////////////////////////////////////////////////
// Load
//////////////////////////////////////////////////////////////////////////

  private Void load()
  {
    if (loaded) return
    slots := Str:CSlot[:]
    if (isPrimitive)
    {
      flags = FConst.Public
    }
    else
    {
      // map Java members to slots using Java reflection
      JavaReflect.load(this, slots)

      // merge in sys::Obj slots
      ns.objType.slots.each |CSlot s|
      {
        if (s.isCtor) return
        if (slots[name] == null) slots[s.name] = s
      }
    }
    this.slots = slots
    loaded = true
  }

//////////////////////////////////////////////////////////////////////////
// Primitives
//////////////////////////////////////////////////////////////////////////

  Bool isPrimitive()
  {
    return pod === pod.bridge.primitives && arrayRank == 0
  }

  Bool isPrimitiveIntLike()
  {
    primitives := pod.bridge.primitives
    return this === primitives.intType ||
           this === primitives.charType ||
           this === primitives.shortType ||
           this === primitives.byteType
  }

  Bool isPrimitiveFloat()
  {
    primitives := pod.bridge.primitives
    return this === primitives.floatType
  }

//////////////////////////////////////////////////////////////////////////
// Arrays
//////////////////////////////////////////////////////////////////////////

  **
  ** Return if this is an interop array like
  ** 'fanx.interop.IntArray' which models 'int[]'.
  **
  Bool isInteropArray()
  {
    return pod.isInterop && name.endsWith("Array")
  }

  **
  ** Is this a array type such as '[java]foo.bar::[Baz'
  **
  Bool isArray() { return arrayRank > 0 }

  **
  ** The rank of the array where 0 is not an array,
  ** 1 is one dimension, 2 is two dimensional, etc.
  **
  Int arrayRank := 0

  **
  ** If this an array, this is the component type.
  **
  JavaType? arrayOf

  **
  ** The arrayOf field always stores a JavaType so that we
  ** can correctly resolve the FFI qname.  This means that
  ** that an array of java.lang.Object will have an arrayOf
  ** value of [java]java.lang::Object.  This method correctly
  ** maps the arrayOf map to its canonical Fan type.
  **
  CType? inferredArrayOf()
  {
    if (arrayOf == null) return null
    if (arrayOf.qname == "[java]java.lang::Object") return ns.objType
    if (arrayOf.qname == "[java]java.lang::String") return ns.strType
    return arrayOf
  }

  **
  ** Get the type which is an array of this type.
  **
  once JavaType toArrayOf()
  {
    return JavaType(pod, "[" + name)
    {
      arrayRank = this.arrayRank + 1
      arrayOf = this
    }
  }

//////////////////////////////////////////////////////////////////////////
// Utils
//////////////////////////////////////////////////////////////////////////

  **
  ** We use an implicit constructor called "<new>" on
  ** each type as the protocol for telling the Java runtime
  ** to perform a 'new' opcode for object allocation:
  **   CallNew Type.<new>  // allocate object
  **   args...             // arguments are pushed onto stack
  **   CallCtor <init>     // call to java constructor
  **
  once CMethod newMethod()
  {
    return JavaMethod
    {
      parent = this
      name = "<new>"
      flags = FConst.Ctor | FConst.Public
      returnType = this
      params = JavaParam[,]
    }
  }

  **
  ** We use an implicit method called "<class>" on
  ** each type as the protocol for telling the Java runtime
  ** to load a class literal
  **
  static CMethod classLiteral(JavaBridge bridge, CType base)
  {
    return JavaMethod
    {
      parent = base
      name = "<class>"
      flags = FConst.Public | FConst.Static
      returnType = bridge.classType
      params = JavaParam[,]
    }
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  private Bool loaded := false
}