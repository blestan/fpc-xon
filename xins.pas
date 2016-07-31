{
  Internal XON Sructures
}
unit xins;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses xtypes,xstr;

type
             PXInstance=^XInstance;
             PXContainer=^XContainer;

             // 32 bits header of each XON Instance
             XHeader=packed record
                    FType,   //  var type
                    FAttr,   // extra var flags
                    FExtra1, // For future usage
                    FExtra2: Byte
             end;

             XContainer= packed record
                       private
                        const
                             PageSize = 32; // vars per page - keep this always power of 2 ( i.e 2,4,8,16..1024)  !!!!
                             PagesDelta = 8;
                             ModMagic = PageSize-1;
                       private
                        FInternalSize: Cardinal;
                        FCount: Cardinal;        // nominal count of items
                        FPagesCount: Cardinal;   // number of pages allocated
                        FPages: PPointer;        // array of pointers to pages memory
                        function Expand:PXInstance;
                       public
                        class function New(ASize:Cardinal): PXContainer;static;
                        procedure Finalize;
                        function GetChildPtr(Index: Cardinal): PXInstance;
             end;


             XInstance = packed record
 	         FHeader: XHeader;
                 function InstanceType: XType;
                 class function Size:Cardinal;static; // instance size of test purposes
                 function Count: Cardinal;
                 function Deleted:boolean;
                 function Modified: boolean;
                 function isRoot:boolean;inline;
                 procedure Initialize(AType: XType; AParent: PXInstance=nil);
                 procedure Finalize;
                 function AllocChild: PXInstance;
                 procedure InitContainer(InitialSize:Cardinal);
                 case  Integer of
                   xtInteger: (FInt: XInt);
                     xtFloat: (FFloat: XFloat);
                   xtBoolean: (FBool: Boolean);
                    xtString: (FStr: XONStr);
                   xtArray,
                   xtObject:  ( FContainer: PXContainer;
                                FParent: PXInstance;     // nil if this is the top container
                               )
            end;


implementation

 const
                   FlagRoot =  %10000000;
                FlagDeleted =  %01000000;
               FlagModified =  %00100000;


var  DivMagic:Cardinal;


// XCOntainer

class function XContainer.New(ASize: Cardinal): PXContainer;
begin
  Result:=GetMem(SizeOf(XContainer)+(ASize*XInstance.Size));
  with Result^ do
   begin
     FInternalSize:=ASize;
     FCount:=00;
     FPagesCount:=00;
     FPages:=nil;
   end;
end;

procedure XContainer.Finalize;
var i: Cardinal;
begin
  if FCount>0 then
    for i:=0 to FCount-1 do GetChildPtr(i)^.Finalize;
  if FPagesCount>0 then
   begin
    for i:=0 to FPagesCount-1 do FreeMem(FPages[i]);
    FreeMem(FPages);
    FPages:=nil;
    FPagesCount:=00;
   end;
  FCount:=00;
end;

function XContainer.GetChildPtr(Index: Cardinal): PXInstance;
begin
  if FCount=0 then exit(nil);
  if Index>=FCount then exit(nil);
  if Index in [00.. FInternalSize-1] then
   begin
     Result:=@self;
     inc(Pointer(Result),SizeOf(XContainer));
     Result:=@Result[Index];
   end
   else
    begin
      Dec(Index,FInternalSize);
      Result:= @PXInstance(FPages[Index shr DivMagic])[Index and ModMagic];
    end;
end;

function XContainer.Expand:PXInstance;
procedure Grow;
begin
    if FPagesCount mod PagesDelta = 0 then FPages:=ReallocMem(FPages,(FPagesCount+PagesDelta)*SizeOf(PXInstance));
    FPages[FPagesCOunt]:=GetMem(PageSize*XInstance.Size); // to do: alloc new pages from pool to avoid memory fragmentation
    Inc(FPagesCount);
end;
begin
   Inc(FCount);
   if FCount-FInternalSize>=FPagesCount*PageSize then Grow;
   Result:=GetChildPtr(FCount-1);
end;

// XInstance functions

function XInstance.InstanceType: XType;inline;
begin
 Result:=XType(FHeader.FType)
end;

class function XInstance.Size: Cardinal;static;inline;
begin
  Result:=Sizeof(XInstance);
end;

procedure XInstance.InitContainer(InitialSize: Cardinal);
begin
  if FContainer=nil then FContainer:=XContainer.New(InitialSize);
end;

function XInstance.AllocChild: PXInstance;
begin
  if FContainer=nil then FContainer:=XContainer.New(XContainer.PageSize);
  Result:=FContainer^.Expand;
end;

procedure XInstance.Initialize(AType: XType; AParent: PXInstance=nil);
begin
 FHeader.FType:=ord(AType);
 if AParent=nil then FHeader.FAttr:=FlagRoot
                else FHeader.FAttr:=0;
 case XType(FHeader.FType) of
     xtString: FStr.Initialize;
     xtObject,xtArray: begin
                        FParent:=AParent;
                        FContainer:=nil;
                       end;
 end
end;

procedure XInstance.Finalize;
begin
 case XType(FHeader.FType) of
     xtString: FStr.Finalize;
     xtObject,xtArray: if FContainer<>nil then
                         begin
                          FContainer^.Finalize;
                          Freemem(FContainer);
                          FContainer:=nil;
                         end;
 end;
end;

function XInstance.Count: Cardinal;
begin
  case InstanceType of
   xtObject: if FContainer<>nil then Result:=FContainer^.FCount div 2 // half of the vars are keys
                                else Result:=0;
    xtArray: if FContainer<>nil then Result:=FContainer^.FCount
                                else Result:=0;
    else Result:=0;
  end
end;


function XInstance.isRoot:boolean;inline;
begin
  Result:=FHeader.FAttr and FlagRoot <>0;
end;

function XInstance.Deleted:boolean;inline;
begin
  Result:=FHeader.FAttr and FlagDeleted <> 0;
end;

function XInstance.Modified:boolean;inline;
begin
  Result:=FHeader.FAttr and FlagModified <> 0;
end;


initialization
 DivMagic := BsrDWord(XContainer.PageSize);
end.

