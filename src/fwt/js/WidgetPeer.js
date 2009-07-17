//
// Copyright (c) 2009, Brian Frank and Andy Frank
// Licensed under the Academic Free License version 3.0
//
// History:
//   8 May 09  Andy Frank  Creation
//

/**
 * WidgetPeer.
 */
fan.fwt.WidgetPeer = fan.sys.Obj.$extend(fan.sys.Obj);
fan.fwt.WidgetPeer.prototype.$ctor = function(self) {}

//////////////////////////////////////////////////////////////////////////
// Layout
//////////////////////////////////////////////////////////////////////////

fan.fwt.WidgetPeer.prototype.relayout = function(self)
{
  // short-circuit if not mounted
  if (this.elem == null) return;

  this.sync(self);
  if (self.onLayout) self.onLayout();

  var kids = self.kids;
  for (var i=0; i<kids.length; i++)
  {
    var kid = kids[i];
    kid.peer.relayout(kid);
  }

  return self;
}

fan.fwt.WidgetPeer.prototype.posOnDisplay = function(self)
{
  var x = this.pos.x;
  var y = this.pos.y;
  var p = self.parent$get();
  while (p != null)
  {
    x += p.peer.pos.x;
    y += p.peer.pos.y;
    p = p.parent$get();
  }
  return fan.gfx.Point.make(x, y);
}

fan.fwt.WidgetPeer.prototype.prefSize = function(self, hints)
{
  // cache size
  var oldw = this.elem.style.width;
  var oldh = this.elem.style.height;

  // sync and measure pref
  this.sync(self);
  this.elem.style.width  = "auto";
  this.elem.style.height = "auto";
  var pw = this.elem.offsetWidth;
  var ph = this.elem.offsetHeight;

  // restore old size
  this.elem.style.width  = oldw;
  this.elem.style.height = oldh;
  return fan.gfx.Size.make(pw, ph);
}

fan.fwt.WidgetPeer.prototype.enabled$get = function(self) { return this.enabled; }
fan.fwt.WidgetPeer.prototype.enabled$set = function(self, val) { this.enabled = val; }
fan.fwt.WidgetPeer.prototype.enabled = true;

fan.fwt.WidgetPeer.prototype.visible$get = function(self) { return this.visible; }
fan.fwt.WidgetPeer.prototype.visible$set = function(self, val) { this.visible = val; }
fan.fwt.WidgetPeer.prototype.visible = true;

fan.fwt.WidgetPeer.prototype.pos$get = function(self) { return this.pos; }
fan.fwt.WidgetPeer.prototype.pos$set = function(self, val) { this.pos = val; }
fan.fwt.WidgetPeer.prototype.pos = fan.gfx.Point.make(0,0);

fan.fwt.WidgetPeer.prototype.size$get = function(self) { return this.size; }
fan.fwt.WidgetPeer.prototype.size$set = function(self, val) { this.size = val; }
fan.fwt.WidgetPeer.prototype.size = fan.gfx.Size.make(0,0);

//////////////////////////////////////////////////////////////////////////
// Attach
//////////////////////////////////////////////////////////////////////////

fan.fwt.WidgetPeer.prototype.attached = function(self)
{
}

fan.fwt.WidgetPeer.prototype.attach = function(self)
{
  // short circuit if I'm already attached
  if (this.elem != null) return;

  // short circuit if my parent isn't attached
  var parent = self.parent;
  if (parent == null || parent.peer.elem == null) return;

  // create control and initialize
  var elem = this.create(parent.peer.elem, self);
  this.attachTo(self, elem);

  // callback on parent
  //parent.peer.childAdded(self);
}

fan.fwt.WidgetPeer.prototype.attachTo = function(self, elem)
{
  // sync to elem
  this.elem = elem;
  this.sync(self);
  this.attachEvents(elem, "mousedown", self.onMouseDown.list());
  // rest of events...

  // recursively attach my children
  var kids = self.kids;
  for (var i=0; i<kids.length; i++)
  {
    var kid = kids[i];
    kid.peer.attach(kid);
  }
}

fan.fwt.WidgetPeer.prototype.attachEvents = function(elem, event, list)
{
  for (var i=0; i<list.length; i++)
  {
    if (elem.addEventListener)
      elem.addEventListener(event, list[i], false);
    else
      elem.attachEvent("on"+event, list[i]);
  }
}

fan.fwt.WidgetPeer.prototype.create = function(parentElem, self)
{
  var div = this.emptyDiv();
  parentElem.appendChild(div);
  return div;
}

fan.fwt.WidgetPeer.prototype.emptyDiv = function()
{
  var div = document.createElement("div");
  with (div.style)
  {
    position = "absolute";
    overflow = "hidden";
    top  = "0";
    left = "0";
  }
  return div;
}

fan.fwt.WidgetPeer.prototype.detach = function(self)
{
  var elem = self.peer.elem;
  elem.parentNode.removeChild(elem);
  delete self.peer.elem;
}

//////////////////////////////////////////////////////////////////////////
// Widget/Element synchronization
//////////////////////////////////////////////////////////////////////////

fan.fwt.WidgetPeer.prototype.sync = function(self, w, h)  // w,h override
{
  with (this.elem.style)
  {
    if (w == undefined) w = this.size.w;
    if (h == undefined) h = this.size.h;

    // TEMP fix for IE
    if (w < 0) w = 0;
    if (h < 0) h = 0;

    display = this.visible ? "block" : "none";
    left    = this.pos.x  + "px";
    top     = this.pos.y  + "px";
    width   = w + "px";
    height  = h + "px";
  }
}

