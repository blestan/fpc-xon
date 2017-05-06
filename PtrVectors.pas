unit PtrVectors;
{$mode objfpc}
{$H+}
{$modeswitch advancedrecords}

interface

type

 PtrVector =record
                 public
                   const
                        DefaultPageSize = 64; // Pointers per page - keep this a power of 2 ( i.e 2,4,8,16..1024)  !!!!
                        DefaultDelta = 16; // Array Grows by "Delta" buckets
                  private
                         FPages: PPointer;
                    FPagesCount: Cardinal;
                    FItemsCount: Cardinal;
                      FPageSize: Word;
                         FDelta: Word;
                      FModMagic: Word;
                      FDivMagic: Byte;
                    function PtrPtr(Index: PtrUInt): PPointer;
                    function GetPtr(Index:PtrUInt): Pointer;
                    procedure SetPtr(Index: PtrUInt; Value: Pointer);
                    function GetCapacity: PtrUInt;
                  public
                    procedure Initialize(APageSize:Word; ADelta: Word);overload;
                    procedure Initialize;overload;
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

uses sysutils;

const

  Platform_bits= SizeOf(PtrUInt) * 8;

  BoundsError = 'XPointers of out bounds (index:%d  limit:%d)';

procedure PtrVector.Initialize(APageSize:Word; ADelta: Word);
begin
  FPages:=nil;
  FPagesCount:=0;
  FItemsCount:=0;
  FPageSize:=APageSize;
  FDelta:=ADelta;
  FModMagic:= FPageSize-1;
  case Platform_bits of
    32: FDivMagic:=BsrDWord(FPageSize);
    64: FDivMagic:=BsrQWord(FPageSize);
  end
end;

procedure PtrVector.Initialize;
begin
  Initialize(DefaultPageSize,DefaultDelta);
end;

procedure PtrVector.Finalize;inline;
begin
   Clear(True);
end;

procedure PtrVector.Clear(DisposeMem: Boolean=true);
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

function PtrVector.GetCapacity: PtrUInt;inline;
begin
  Result:=FPagesCount*FPageSize;
end;


function PtrVector.PtrPtr(Index: PtrUInt): PPointer;inline;
begin
  if Index<FItemsCount then
   begin
    Result:= FPages[Index shr FDivMagic];
    Result:=@Result[Index and FModMagic];
   end
    else Result:=nil
end;

function PtrVector.GetPtr(Index: PtrUInt): Pointer;
begin
     Result:=PtrPtr(Index);
     if Result<>nil then Result:=PPointer(Result)^
      else Exception.CreateFmt(BoundsError,[Index,FItemsCount-1])
end;

procedure PtrVector.SetPtr(Index: PtrUInt; Value: Pointer);
Var P: PPointer;
begin
  P:=PtrPtr(Index);
  if (P<>nil) then P^:=Value
     else Exception.CreateFmt(BoundsError,[Index,FItemsCount-1]);
end;

procedure PtrVector.Push(P: Pointer);
procedure Grow;
begin
    // if needed we alloc memory for new "delta" pointers to page of pointers
    if FPagesCount mod FDelta = 0 then FPages:=ReallocMem(FPages,(FPagesCount+FDelta)*SizeOf(Pointer));
    // we alloc mem for "PageSize" pointers
    FPages[FPagesCount]:=GetMem(FPageSize*SizeOf(Pointer));
    Inc(FPagesCount);
end;

begin
 Inc(FItemsCount);
 if FItemsCount>=Capacity then Grow;
 SetPtr(FItemsCount-1,P);
end;

function PtrVector.Pull: Pointer;inline;
begin
  Result:=GetPtr(FItemsCount-1);
  Dec(FItemsCount);
end;

function PtrVector.Last: Pointer;inline;
begin
 Result:=GetPtr(FItemsCount-1);
end;

function PtrVector.First: Pointer;inline;
begin
 Result:=GetPtr(0);
end;

end.

