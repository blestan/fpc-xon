{

 Cross Platform Object Notation - XON

 (c) 2016 by Blestan Tabakov

}
unit xon;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses xtypes,xins,xstr;

type

// Opaque type to deal with XON internal structures
XVar =  record
         private
           FInstance: PXInstance;
           function GetVar(Index: Cardinal): XVar;
           function GetKey(Index: Cardinal): XVar;
         public
           const Null: XVar =( FInstance : Nil);
           class function InstanceSize: Cardinal;static;
           class function Create(AType: XType; AParent: XVar): XVar;overload;static;
           class function Create(AParent: XVar):XVar;overload;static; // create null
           class function Create(AValue: PChar; Size: Integer; AParent: XVar): XVar;overload;static;
           class function Create(AValue: Boolean; AParent: XVar): XVar;overload;static;
           class function Create(AValue: XInt; AParent: XVar): XVar;overload;static;
           class function Create(AValue: XFloat; AParent: XVar): XVar;overload;static;
           class function CreateArray(AParent: XVar): XVar;static;
           class function CreateObject(AParent: XVar): XVar;static;
           procedure Free;
           function DataType: XType;
           function Parent: XVar;
           function isValid:boolean;
           function isDeleted:boolean;
           function isModified: boolean;
           function IsNumeric: Boolean;
           function IsNull: Boolean;
           function AsString: String;
           function AsInteger: XInt;
           function AsBoolean: Boolean;
           function Count: Cardinal;
           property Vars[Index: Cardinal]: XVar read GetVar;default;
           property Keys[Index: Cardinal]: XVar read GetKey;
         end;


implementation

// The opaque XON type

class function XVar.InstanceSize:Cardinal;static;inline;
begin
  Result:=XInstance.Size;
end;

function XVar.Count:Cardinal;inline;
begin
  if isValid then Result:=FInstance^.Count
             else Result:=0;
end;

class function XVar.Create(AType: XType; AParent: XVar): XVar;
begin
  if AParent.isValid then Result.FInstance:=AParent.FInstance^.Expand // we expand the parent or
                     else Result.FInstance:=GetMem(InstanceSize); // we alloc mem for a root instance
  Result.FInstance^.Initialize(AType,AParent.FInstance);
end;

class function XVar.Create(AParent: XVar): XVar;inline;
begin
 Result:=Create(xtNull,AParent)
end;

class function XVar.Create( AValue: PChar; Size: Integer; AParent: XVar): XVar;inline;
begin
  Result:=Create(xtString,AParent);
  if Result.isValid then Result.FInstance^.FStr.SetString(AValue,Size);
end;

class function XVar.Create(AValue: Boolean; AParent: XVar): XVar;inline;
begin
  Result:=Create(xtBoolean,AParent);
  if Result.isValid then Result.FInstance^.FBool:=AValue;
end;

class function XVar.Create(AValue: XInt; AParent: XVar): XVar;inline;
begin
  Result:=Create(xtInteger,AParent);
  if Result.isValid then Result.FInstance^.FInt:=AValue;
end;

class function XVar.Create(AValue: XFloat; AParent: XVar): XVar;inline;
begin
   Result:=Create(xtFloat,AParent);
  if Result.isValid then Result.FInstance^.FFloat:=AValue;
end;

class function XVar.CreateObject(AParent: XVar): XVar;inline;
begin
   Result:=Create(xtObject,AParent);
end;

class function XVar.CreateArray(AParent: XVar): XVar;inline;
begin
  Result:=Create(xtArray,AParent);
end;

procedure XVar.Free;
begin
  if isValid then
   begin
     FInstance^.Finalize;
     if FInstance^.isRoot then
       begin
         FreeMem(FInstance);  // free mem only if this is a root
       end;
     FInstance:=nil;
   end
end;

function XVar.Parent: XVar;
begin
  if DataType in [xtObject,xtArray] then Result.FInstance:=FInstance^.FParent
                                    else Result:=null;
end;

function XVar.isValid:Boolean; inline;
begin
  Result:= FInstance<>nil;
end;

function XVar.DataType: XType; inline;
begin
  if isValid then Result := FInstance^.InstanceType
             else Result := xtNull;
end;

function XVar.IsNumeric:boolean;inline;
begin
  Result:= DataType in [xtInteger,xtFloat];
end;

function XVar.IsNull:Boolean;inline;
begin
  Result:= DataType=xtNull
end;

function XVar.AsBoolean:Boolean;
begin
  Result:=False;
  case DataType of
      xtNull: Result:=False;
   xtBoolean: Result:= FInstance^.FBool;
   xtInteger: Result:= FInstance^.FInt<>0;
     xtFloat: Result:= FInstance^.FFloat<>0;
  end;
end;

function XVar.AsInteger:XInt;
begin
  Result:=0;
  case DataType of
      xtNull: Result:=0;
   xtBoolean: Result:= Integer(FInstance^.FBool);
   xtInteger: Result:= FInstance^.FInt;
     xtFloat: Result:= Trunc(FInstance^.FFloat);
  end;
end;


function XVar.AsString: String;
begin
  Result:='';
   case DataType of
    xtNull: Result:='Null';
    xtInteger: Str(FInstance^.FInt,Result);
    xtFloat: Str(FInstance^.FFloat:10:15,Result);
    xtString: Result:=FInstance^.FStr.GetAsString;
    xtBoolean: if FInstance^.FBool then Result:='True'
                                   else Result:='False';
   end;
end;

function XVar.isDeleted:boolean;inline;
begin
  if isValid then Result:=FInstance^.Deleted
             else Result:=False;
end;

function XVar.isModified:boolean;inline;
begin
  if isValid then Result:=FInstance^.Modified
             else Result:=False;
end;

function XVar.GetVar(Index: Cardinal): XVar;
begin
  case DataType of
     xtObject:Result.FInstance:=FInstance^.GetChildPtr(Succ(Index shl 1));
      xtArray:Result.FInstance:=FInstance^.GetChildPtr(Index);
  else Result:=XVar.Null;
end;
end;

function XVar.GetKey(Index: Cardinal): XVar;
begin
    if DataType = xtObject then Result.FInstance:=FInstance^.GetChildPtr(Index shl 1)
                           else Result:=XVar.Null;
end;


initialization

end.

