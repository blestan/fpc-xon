{
  XON Instance - Internal Memory XON Sructures
  modify with extreme care!!!
}
unit xins;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses xtypes;

type
             PXInstance=^XInstance;
             PXContainer=^XContainer;

             // XON Instance Header
             XHeader=packed record
                    FType,      //  var type
                    FAttr: Byte;  // extra flags
                    FVMTIndex: Word // reserved for future use;
             end;

             XStr = packed record
                    const
                        InlineSz=12; // do not modify ... binary persistance comptibility will be broken!
                    private
                        FLen: Integer;
                    public
                        Procedure SetStr(const S: String);overload;
                        Procedure SetStr (P: PChar; Len: Integer);overload;
                        Function GetStr: String;
                    private
                     case integer of
                        0: ( FChars: array[01..InlineSz] of char); //  inline characters
                        1: ( FNative: Pointer); // fpc string
                        2: ( FCharBuf: PChar); // ptr to user managed buffer or chars  - to do!!!
              end;

             XContainer= packed record
                       private
                        const
                             PageSize = 32; // vars per page - keep this always power of 2 ( i.e 2,4,8,16..1024)  !!!!
                             PagesDelta = 8;
                             ModMagic = PageSize-1;
                        private
                         FNextFree: PXContainer;
                         FInternalSize: Cardinal;
                         FCount: Cardinal;        // nominal count of items
                         FPagesCount: Cardinal;   // number of pages allocated
                         FPages: PPointer;        // array of pointers to pages memory
                         function Expand:PXInstance;
                         function GetInstance(Index: Cardinal): PXInstance;
                       public
                        class function New(ASize:Cardinal): PXContainer;static;
                        procedure Finalize;
                        property  Items[index: cardinal]: PXInstance read GetInstance;default;

             end;

             XInstance =   packed record
 	         FHeader: XHeader;
                 function InstanceType: XType;
                 class function Size:Cardinal;static; // instance size
                 class function Alloc( AType: XType; AParent: PXInstance): PXInstance;static;
                 procedure Free;
                 function Deleted:boolean;
                 function Modified: boolean;
                 function isRoot:boolean;inline;
                 procedure Init(AType: XType; AParent: PXInstance=nil);
                 procedure Finalize;
                 function AddItem: PXInstance;
                 function Count: Cardinal;
                 procedure InitContainer(InitialSize:Cardinal);
                 case  Xtype of
                   xtInteger: (FInt: XInt);
                     xtFloat: (FFloat: XFloat);
                   xtBoolean: (FBool: Boolean);
                    xtString: (FStr: XStr);
                     xtArray,
                    xtObject: (FContainer: PXContainer;
                               FParent: PXInstance;);
                      xtGUID: (FGUID: TGuid)
            end;


implementation

uses PtrVectors;

 const
                   FlagRoot =  %10000000;
                FlagDeleted =  %01000000;
               FlagModified =  %00100000;


var  DivMagic:Cardinal;


threadvar

   FreeContainersList: PtrVector;


// XContainer
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
    for i:=0 to FCount-1 do GetInstance(i)^.Finalize;
  if FPagesCount>0 then
   begin
    for i:=0 to FPagesCount-1 do FreeMem(FPages[i]);
    FreeMem(FPages);
    FPages:=nil;
    FPagesCount:=00;
   end;
  FCount:=00;
end;

function XContainer.GetInstance(Index: Cardinal): PXInstance;
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
begin
   Inc(FCount);
   if FCount-FInternalSize>=FPagesCount*PageSize then
    begin
     if FPagesCount mod PagesDelta = 0 then
       FPages:=ReallocMem(FPages,(FPagesCount+PagesDelta)*SizeOf(PXInstance));
     FPages[FPagesCOunt]:=GetMem(PageSize*XInstance.Size); // to do: alloc new pages from a pool to avoid memory fragmentation
     Inc(FPagesCount)
    end;
   Result:=GetInstance(FCount-1);
end;

// XStr

procedure XStr.SetStr(P: PChar; Len: Integer);
begin
 if FLen>InlineSz then RawByteString(FNative):=''; // release previous string if any
 if Len<InlineSz  then
  begin
   FLen:=Len;
   if Len<>0 then Move(P^,FChars[1],FLen);
  end
  else
   begin
     FNative:=nil;
     FLen:=High(FLen); // indicates native string
     System.SetLength(RawByteString(FNative),Len);
     Move(P^,RawByteString(FNative)[1],Len);
   end
end;

procedure XStr.SetStr(const S:String);inline;
Var Len: Cardinal;
begin
  if FLen>InlineSz then String(FNative):=''; // release previous string if any
  Len:=System.Length(S);
  if Len<InlineSz  then
  begin
   FLen:=Len;
   if Len<>0 then Move(S[1],FChars[1],FLen);
  end
  else
   begin
     FNative:=nil;
     FLen:=High(FLen); // indicates native string
     String(FNative):=S;
   end
end;
Function XStr.GetStr: String;
begin
 if FLen=0 then exit;
 if FLen<InlineSz then
   begin
     System.SetLength(Result,FLen);
     Move(FChars[1],Result[1],Flen)
   end
    else Result:=String(FNative);
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

class function XInstance.Alloc(AType: XType; AParent: PXInstance): PXInstance;
begin
 if AParent<>nil then Result:=AParent^.AddItem // we expand the parent or
                 else Result:=GetMem(XInstance.Size); // we alloc mem for a root instance


 Result^.Init(AType,AParent);
end;

procedure XInstance.Free;
begin
 Finalize;
 if isRoot then FreeMem(@Self);  // free mem only if this is a root instance
end;

procedure XInstance.InitContainer(InitialSize: Cardinal);
begin
  if FContainer=nil then FContainer:=XContainer.New(InitialSize);
end;

function XInstance.AddItem: PXInstance;
begin
  if FContainer=nil then FContainer:=XContainer.New(XContainer.PageSize);
  Result:=FContainer^.Expand;
end;

procedure XInstance.Init(AType: XType; AParent: PXInstance=nil);
begin
 FHeader.FType:=ord(AType);
 if AParent=nil then FHeader.FAttr:=FlagRoot
                else FHeader.FAttr:=0;
 case XType(FHeader.FType) of
     xtString: FStr.FLen:=00;
     xtObject,xtArray: begin
                        FParent:=AParent;
                        FContainer:=nil;
                       end;
 end
end;

procedure XInstance.Finalize;
begin
 case XType(FHeader.FType) of
     xtString: FStr.SetStr('');
     xtObject,xtArray: if FContainer<>nil then
                         begin
                          FContainer^.Finalize;
                          Freemem(FContainer);
                          FContainer:=nil;
                         end;
 end;
end;


function XInstance.isRoot:boolean;inline;
begin
  Result:=ByteBool(FHeader.FAttr and FlagRoot);
end;

function XInstance.Deleted:boolean;inline;
begin
  Result:=ByteBool(FHeader.FAttr and FlagDeleted);
end;

function XInstance.Modified:boolean;inline;
begin
  Result:=ByteBool(FHeader.FAttr and FlagModified);
end;

function XInstance.Count:Cardinal;
begin
 if FContainer<>nil then
  begin
   Result:=FContainer^.FCount;
   if InstanceType=xtObject then Result:=Result div 2;
  end
   else Result:=0;
end;


initialization
 DivMagic := BsrDWord(XContainer.PageSize);

 {
   we initialize free lists for the main thread.
   but this must be done in every thred if Pool Model is changed to xpPerThread!!!
 }

 FreeContainersList.Initialize;

 finalization

 FreeContainersList.Finalize;

end.

