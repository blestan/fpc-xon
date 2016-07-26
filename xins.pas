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
                       FCount: Cardinal;        // nominal count of items
                       FPagesCount: Cardinal;   // number of pages allocated
                       FPages: PPointer;        // array of pointers to pages memory

             end;


             XInstance = packed record
 	         FHeader: XHeader;
                 function InstanceType: XType;
                 class function Size:Cardinal;static; // instance size of test purposes
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
                   xtObject:  ( FContainer: XContainer;
                                FParent: PXInstance;     // nil if this is the top container
                               )
            end;


implementation

 const
                   FlagRoot =  %10000000;
                FlagDeleted =  %01000000;
               FlagModified =  %00100000;


var  DivMagic:Cardinal;


// XInstance functions

function XInstance.InstanceType: XType;inline;
begin
 Result:=XType(FHeader.FType)
end;

class function XInstance.Size: Cardinal;static;inline;
begin
  Result:=Sizeof(XInstance);
end;

function XInstance.GetChildPtr(Index: Cardinal): PXInstance;inline;
begin
    Result:= @PXInstance(FPages[Index shr DivMagic])[Index and ModMagic]
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
                        FCount:=0;
                        FPages:=nil;
                        FPagesCount:=0;
                       end;
 end
end;

procedure XInstance.Finalize;
var i: Cardinal;
begin
 case XType(FHeader.FType) of
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
    FPages[FPagesCOunt]:=GetMem(PageSize*Size); // to do: alloc new pages from pool to avoid memory fragmentation
    Inc(FPagesCount);
end;
begin
   Inc(FCount);
   if FCount>=FPagesCount*PageSize then Grow;
   Result:=GetChildPtr(FCount-1);
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
 DivMagic := BsrDWord(PageSize);
end.

