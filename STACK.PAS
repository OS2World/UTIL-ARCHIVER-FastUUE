unit Stack;

interface

const
 MaxStackSize = 16384;
 StackSeg: Word = 0;

type
 PStack = ^TStack;
 TStack = object
  procedure Assign;
  procedure Reset;
 private
  rAX, rDI, rES, rBP, rIP, rCS, rSS, rSP: Word;
  Body: array[0..MaxStackSize-1] of Word;
  Tail: record end;
 end;

implementation

procedure TStack.Assign; assembler;
 asm
  {.$IfNDef _DPMI}
  push   ax
  push   ds

  mov    ax, Seg @Data
  mov    ds, ax
  mov    ax, ss
  cmp    ax, StackSeg

  pop    ds
  pop    ax
  je     @Exit           { Exit if stack is mine }

{.$EndIF DPMI}
  push   es
  push   di

  les    di, Self

  { Store AX }
  mov    es:[di].TStack.rAX, ax
  { Store DI from stack }
  pop    es:[di].TStack.rDI
  { Store ES from stack }
  pop    es:[di].TStack.rES
  { Store BP from stack frame }
  pop    es:[di].TStack.rBP
  { Store ret IP from stack frame }
  pop    es:[di].TStack.rIP
  { Store ret CS from stack frame }
  pop    es:[di].TStack.rCS
  { Store SP before call }
  add    sp, 4  { Add Sizeof(Pointer) }
  mov    es:[di].TStack.rSP, sp
  { Store SS }
  mov    ax, ss
  mov    es:[di].TStack.rSS, ax
  { Check and set up new stack }
  lea    sp, es:[di].TStack.Tail
  mov    ax, es
  mov    ss, ax
  push   es:[di].TStack.rCS
  push   es:[di].TStack.rIP
  push   es:[di].TStack.rES
  push   es:[di].TStack.rDI
  mov    ax, es:[di].TStack.rAX
  mov    bp, es:[di].TStack.rBP
  pop    di
  pop    es
  retf
@Exit:
 end;

procedure TStack.Reset; assembler;
 asm
  push   ax
  push   ds
  mov    ax, Seg @Data
  mov    ds, ax
  mov    ax, ss
  cmp    ax, StackSeg
  pop    ds
  pop    ax
  je     @Exit           { Exit if stack is mine }
  push   es
  push   di
  les    di, Self
  { Store AX }
  mov    es:[di].TStack.rAX, ax
  { Store DI }
  pop    es:[di].TStack.rDI
  { Store ES }
  pop    es:[di].TStack.rES
  { Store BP }
  pop    es:[di].TStack.rBP
  { Store ret IP }
  pop    es:[di].TStack.rIP
  { Store ret CS }
  pop    es:[di].TStack.rCS
  { Restore stack }
  mov    ax, es:[di].TStack.rSS
  mov    ss, ax
  mov    sp, es:[di].TStack.rSP
  push   es:[di].TStack.rCS
  push   es:[di].TStack.rIP
  push   es:[di].TStack.rES
  push   es:[di].TStack.rDI
  mov    ax, es:[di].TStack.rAX
  mov    bp, es:[di].TStack.rBP
  pop    di
  pop    es
  retf
@Exit:
  end;

end.