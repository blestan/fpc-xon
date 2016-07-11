unit xins;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses xtypes,xstr;

type

             PXInstance=^XInstance;
             XInstance = packed record
 	         FType: byte; //  var type
                 FAttr: byte; // extra var flags
                 function InstanceType: XType;
                 class function Size:Cardinal;static;
                 function Count: Cardinal;
                 function Expand:PXInstance;
                 function Deleted:boolean;
                 function Modified: boolean;
                 function isRoot:boolean;inline;
                 function GetChildPtr(Index: Cardinal): PXInstance;
                 procedure Initialize(AType: XType; AParent: PXInstance=nil);
                 procedure Finalize;
                 case  Integer of
                   xtInteger: (FInt: XInt);
                     xtFloat: (FFloat: XFloat);
                   xtBoolean: (FBool: Boolean);
                    xtString: (FStr: XONStr);
                   xtArray,
                   xtObject:  ( FCount: Cardinal;
                                FPagesCount: Cardinal;
                                FPages: PPointer;
                                FParent: PXInstance;
                               )
            end;


implementation

const
              PageSize = 32; // vars per page - keep this always power of 2 ( i.e 2,4,8,16..1024)  !!!!
              PagesDelta = 8;
              ModMagic = PageSize-1;

                   FlagRoot =  %10000000;
                FlagDeleted =  %01000000;
               FlagModified =  %00100000;


var  DivMagic:Cardinal;


// XInstance functions

function XInstance.InstanceType: XType;inline;
begin
 Result:=XType(FType)
end;

class function XInstance.Size: Cardinal;static;inline;
begin
  Result:=Sizeof(XInstance);
end;

function XInstance.GetChildPtr(Index: Cardinal): PXInstance;
begin
 if Index<FCount then
    Result:= @PXInstance(FPages[Index shr DivMagic])[Index and ModMagic]
  else Result:=nil
end;


procedure XInstance.Initialize(AType: XType; AParent: PXInstance=nil);
begin
 FType:=ord(AType);
 if AParent=nil then FAttr:=FlagRoot
                else FAttr:=0;
 case XType(FType) of
     xtString: FStr.Initialize;
     xtObject,xtArray: begin
                        FParent:=AParent;
                        FCount:=0;
                        FPages:=nil;
                        FPagesCount:=0;
                       end;
 end
end;

procedure XInstance.Finalize;
var i: Cardinal;
begin
 case XType(FType) of
     xtString: FStr.Finalize;
     xtObject,xtArray: if FCOunt>0 then
         begin
           for i:=0 to FCount-1 do GetChildPtr(i)^.Finalize;
           for i:=0 to FPagesCount-1 do FreeMem(FPages[i]);
           FCount:=0;
           FreeMem(FPages);
           FPages:=nil;
           FPagesCount:=0
         end;
 end;
end;

function XInstance.Count: Cardinal;
begin
  case InstanceType of
   xtObject: Result:=FCount div 2; // half of the vars are keys
    xtArray: Result:=FCount;
    else Result:=0;
  end
end;


function XInstance.Expand:PXInstance;
procedure Grow;
begin
    if FPagesCount mod PagesDelta = 0 then FPages:=ReallocMem(FPages,(FPagesCount+PagesDelta)*SizeOf(PXInstance));
    FPages[FPagesCOunt]:=GetMem(PageSize*Size);
    Inc(FPagesCount);
end;
begin
   Inc(FCount);
   if FCount>=FPagesCount*PageSize then Grow;
   Result:=GetChildPtr(FCount-1);
end;

function XInstance.isRoot:boolean;inline;
begin
  Result:=FAttr and FlagRoot <>0;
end;

function XInstance.Deleted:boolean;inline;
begin
  Result:=FAttr and FlagDeleted <> 0;
end;

function XInstance.Modified:boolean;inline;
begin
  Result:=FAttr and FlagModified <> 0;
end;


initialization
 DivMagic := BsrDWord(PageSize);
end.

