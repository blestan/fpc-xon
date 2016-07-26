unit xptr;
{$mode objfpc}
{$H+}
{$modeswitch advancedrecords}

interface

type

 XPointers =record
                 public
                   const
                        PageSize = 64; // Pointers per page - keep this a power of 2 ( i.e 2,4,8,16..1024)  !!!!
                        Delta = 16; // Array Grows by "Delta" buckets
                  private
                       FPages: PPointer;
                    FPagesCount: Integer;
                    FItemsCount: PtrUInt;
                    function PtrPtr(Index: PtrUInt): PPointer;
                    function GetPtr(Index:PtrUInt): Pointer;
                    procedure SetPtr(Index: PtrUInt; Value: Pointer);
                    function GetCapacity: PtrUInt;
                  public
                    procedure Initialize;
                    procedure Finalize;
                    property Capacity: PtrUInt read GetCapacity;
                    property Count: PtrUInt read FItemsCount;
                    procedure Clear(DisposeMem: Boolean=true);
                    property Items[Index: PtrUInt]: Pointer read GetPtr write SetPtr; default;
                    procedure Push(P: Pointer);
                    function Pull: Pointer;
                    function Last: Pointer;
                    function First: Pointer;
  end;


implementation

const

  Platform_bits= SizeOf(PtrUInt) * 8;

  BoundsError = 'XPointers of out bounds (index:%d  limit:%d)';

var
    ModMagic: PtrUInt;
    DivMagic: PtrUInt;

procedure XPointers.Initialize;
begin
  FPages:=nil;
  FPagesCount:=0;
  FItemsCount:=0;
end;

procedure XPointers.Finalize;inline;
begin
   Clear(True);
end;

procedure XPointers.Clear(DisposeMem: Boolean=true);
var i: integer;
begin
   FItemsCount:=0;
   if DisposeMem and (FPagesCount>0) then
    begin
      for i:=0 to FPagesCount-1 do FreeMem(FPages[i]);
      FreeMem(FPages);
      FPages:=nil;
      FPagesCount:=0;
    end;
end;

function XPointers.GetCapacity: PtrUInt;inline;
begin
  Result:=FPagesCount*PageSize;
end;


function XPointers.PtrPtr(Index: PtrUInt): PPointer;inline;
begin
  if Index<FItemsCount then
   begin
    Result:= FPages[Index shr DivMagic];
    Result:=@Result[Index and ModMagic];
   end
    else Result:=nil
end;

function XPointers.GetPtr(Index: PtrUInt): Pointer;
begin
     Result:=PtrPtr(Index);
     if Result<>nil then Result:=PPointer(Result)^
      else Exception.CreateFmt(BoundsError,[Index,FItemsCount-1])
end;

procedure XPointers.SetPtr(Index: PtrUInt; Value: Pointer);
Var P: PPointer;
begin
  P:=PtrPtr(Index);
  if (P<>nil) then P^:=Value
     else Exception.CreateFmt(BoundsError,[Index,FItemsCount-1]);
end;

procedure XPointers.Push(P: Pointer);
procedure Grow;
begin
    // if needed we alloc pointers to new "delta" buckets
    if FPagesCount mod Delta = 0 then FPages:=ReallocMem(FPages,(FPagesCount+Delta)*SizeOf(Pointer));
    // we alloc mem for "bucketsize" pointers
    FPages[FPagesCount]:=GetMem(PageSize*SizeOf(Pointer));
    Inc(FPagesCount);
end;

begin
 Inc(FItemsCount);
 if FItemsCount>=Capacity then Grow;
 SetPtr(FItemsCount-1,P);
end;

function XPointers.Pull: Pointer;inline;
begin
  Result:=GetPtr(FItemsCount-1);
  Dec(FItemsCount);
end;

function XPointers.Last: Pointer;inline;
begin
 Result:=GetPtr(FItemsCount-1);
end;

function XPointers.First: Pointer;inline;
begin
 Result:=GetPtr(0);
end;

initialization

ModMagic:= XPointers.PageSize-1;
case Platform_bits of
 32: DivMagic:=BsrDWord(XPointers.PageSize);
 64: DivMagic:=BsrQWord(XPointers.PageSize);
end;

end.

