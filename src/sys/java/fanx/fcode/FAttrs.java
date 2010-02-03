//
// Copyright (c) 2006, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   26 Dec 05  Brian Frank  Creation
//
package fanx.fcode;

import java.io.*;
import java.util.HashMap;
import fan.sys.*;

/**
 * FAttrs is meta-data for a FType of FSlot - we only decode
 * what we understand and ignore anything else.
 */
public class FAttrs
  implements FConst
{

//////////////////////////////////////////////////////////////////////////
// Access
//////////////////////////////////////////////////////////////////////////

  public Facets facets() { return Facets.make(facets); }

//////////////////////////////////////////////////////////////////////////
// Read
//////////////////////////////////////////////////////////////////////////

  public static FAttrs read(FStore.Input in) throws IOException
  {
    int n = in.u2();
    if (n == 0) return none;
    FAttrs attrs = new FAttrs();
    for (int i=0; i<n; ++i)
    {
      String name = in.name();

// TODO-FACETS
if ((in.fpod.version == 0x1000045 && name == "Facets") ||
    name.equals("OldFacets")) { attrs.facets(in); continue; }

      switch (name.charAt(0))
      {
        case 'E':
          if (name.equals(ErrTableAttr)) { attrs.errTable(in); continue; }
          break;
        case 'F':
System.out.println("TODO: new facets!");
          break;
        case 'L':
          if (name.equals(LineNumberAttr)) { attrs.lineNumber(in); continue; }
          if (name.equals(LineNumbersAttr)) { attrs.lineNumbers(in); continue; }
          break;
        case 'S':
          if (name.equals(SourceFileAttr)) { attrs.sourceFile(in); continue; }
          break;
      }
      int skip = in.u2();
      if (in.skip(skip) != skip) throw new IOException("Can't skip over attr " + name);
    }
    return attrs;
  }

  private void errTable(FStore.Input in) throws IOException
  {
    errTable = FBuf.read(in);
  }

  private void facets(FStore.Input in) throws IOException
  {
    in.u2();
    int n = in.u2();
    HashMap map = new HashMap();
    for (int i=0; i<n; ++i)
    {
      String qname = in.fpod.symbolRef(in.u2()).qname();
      Object val = Symbol.initVal(in.utf());
      map.put(qname, val);
    }
    facets = map;
  }

  private void lineNumber(FStore.Input in) throws IOException
  {
    in.u2();
    lineNum = in.u2();
  }

  private void lineNumbers(FStore.Input in) throws IOException
  {
    lineNums = FBuf.read(in);
  }

  private void sourceFile(FStore.Input in) throws IOException
  {
    in.u2();
    sourceFile = in.utf();
  }

//////////////////////////////////////////////////////////////////////////
// Fields
//////////////////////////////////////////////////////////////////////////

  static final FAttrs none = new FAttrs();

  public FBuf errTable;
  public HashMap facets;
  public int lineNum;
  public FBuf lineNums;
  public String sourceFile;

}