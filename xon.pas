{

 Cross Platform Object Notation - XON

 (c) 2016 by Blestan Tabakov

}
unit xon;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface

uses xtypes,xins;

type

// Opaque type to deal with XON internal structures
XVar =  record
         private
           FInstance: PXInstance;
           function GetString:String;
           procedure SetString(const AValue: String);overload;
           function GetBoolean: Boolean;
           procedure SetBoolean(AValue:Boolean);
           function GetInteger: XInt;
           procedure SetInteger(AValue: XInt);
           function GetFloat: XFloat;
           procedure SetFloat(AValue: XFloat);
         public
           const Null: XVar =( FInstance : Nil);
           class function InstanceSize: Cardinal;static;
           class function New(AType: XType; AParent: XVar): XVar;static; // Create New Variable
           procedure Free;
           function VarType: XType;
           function Assigned:boolean;
           function Deleted:boolean;
           function Modified: boolean;
           function isContainer: boolean;
           function IsNumeric: Boolean;
           function IsNull: Boolean;
           procedure SetString(AValue: PChar; Size: Cardinal);overload;
           property AsInteger: XInt read GetInteger write SetInteger;
           property AsBoolean: Boolean read GetBoolean write SetBoolean;
           property AsString: String read GetString write SetString;
           property AsFloat: XFloat read GetFloat write SetFloat;
         end;


XObject = record
          private
           FInstance: PXInstance;
           function GetItemByKey(const S: String): XVar;
           function GetVar(Index: Cardinal): XVar;
           function GetKey(Index: Cardinal): XVar;
          public
           const Null: XObject =( FInstance : Nil);
           function VarType: XType;
           function Assigned:boolean;
           function Count: Cardinal;
           function Parent: XVar;
           function Add(AType: XType;const AKey:String=''): XVar;
           property ItemByKey[const S: String]: XVar read GetItemByKey;default;
           property Vars[Index: Cardinal]: XVar read GetVar;
           property Keys[Index: Cardinal]: XVar read GetKey;
end;

XArray = record
          Private
           FInstance: PXInstance;
           function GetVar(Index: Cardinal): XVar;
          public
           const Null: XArray = ( FInstance : Nil);
           function VarType: XType;
           function Assigned:boolean;
           function Count: Cardinal;
           function Parent: XVar;
           function Add(AType: XType): XVar;
           property Vars[Index: Cardinal]: XVar read GetVar;default;
end;


XVarHelper = record helper for XVAR
               function AsObject: XObject;
                function AsArray: XArray;
end;

operator := (AnArray: XArray) : XVar;
operator := (AnObject: XObject) : XVar;

resourcestring

  XON_Expand_Exception='Cannot expand XON Container';
  XON_Assign_Exception='Wrong XON Assignment. Expented :%s: got :%s:';


implementation

uses sysutils;

type

    EXONException= class (Exception);

// The opaque XON type
class function XVar.InstanceSize:Cardinal;static;inline;
begin
  Result:=XInstance.Size;
end;


// create a root
class function XVar.New(AType: XType; AParent: XVar): XVar;inline;
begin
 Result.FInstance:=XInstance.New(AType,AParent.FInstance);
end;

procedure XVar.Free;
begin
 if Assigned then
   begin
     FInstance^.Free;
     FInstance:=nil;
   end
end;

function XVar.GetString: String;
begin
  Result:='';
   case VarType of
    xtNull: Result:='Null';
    xtInteger: Str(FInstance^.FInt,Result);
    xtFloat: Str(FInstance^.FFloat:10:3,Result);
    xtString: Result:=FInstance^.FStr.GetStr;
    xtBoolean: if FInstance^.FBool then Result:='True'
                                   else Result:='False';
   end;
end;

procedure XVar.SetString( AValue: PChar; Size: Cardinal);
begin
  if Assigned  and (VarType = xtString) then FInstance^.FStr.SetStr(AValue,Size)
                                         else raise EXONException.Create(XON_Assign_Exception);
end;

procedure XVar.SetString(const AValue: String);
begin
  if VarType = xtString then FInstance^.FStr.SetStr(AValue)
                         else raise EXONException.Create(XON_Assign_Exception);
end;

function XVar.GetBoolean:Boolean;
begin
  Result:=False;
  case VarType of
      xtNull: Result:=False;
   xtBoolean: Result:= FInstance^.FBool;
   xtInteger: Result:= FInstance^.FInt<>0;
     xtFloat: Result:= FInstance^.FFloat<>0;
  end;
end;

procedure XVar.SetBoolean(AValue: Boolean);
begin
  if VarType = xtBoolean then FInstance^.FBool:=AValue
                          else raise EXONException.Create(XON_Assign_Exception);

end;

function XVar.GetInteger:XInt;
begin
  Result:=0;
  case VarType of
      xtNull: Result:=0;
      xtInteger: Result:= FInstance^.FInt;
   xtBoolean: Result:= Ord(FInstance^.FBool);
     xtFloat: Result:= Trunc(FInstance^.FFloat);
  end;
end;

procedure XVar.SetInteger(AValue: Integer);
begin
  case VarType of
       xtInteger: FInstance^.FInt:=AValue;
         xtFloat: FInstance^.FFloat:=AValue;
       xtBoolean: FInstance^.FBool:=AValue<>0;
        xtString: FInstance^.FStr.SetStr(IntToStr(AValue));
        else raise EXONException.CreateFmt(XON_Assign_Exception,[XTypeName(xtInteger),XTypeName(VarType)]);
  end
end;

function XVar.GetFloat:XFloat;
begin
  Result:=0;
  case VarType of
      xtNull: Result:=0;
      xtInteger: Result:= FInstance^.FInt;
   xtBoolean: Result:= Ord(FInstance^.FBool);
     xtFloat: Result:= FInstance^.FFloat;
  end;
end;

procedure XVar.SetFloat(AValue: XFloat);
begin
  case VarType of
       xtInteger: FInstance^.FInt:=round(AValue);
         xtFloat: FInstance^.FFloat:=AValue;
       xtBoolean: FInstance^.FBool:=AValue<>0;
        xtString: FInstance^.FStr.SetStr(FloatToStr(AValue));
        else raise EXONException.CreateFmt(XON_Assign_Exception,[XTypeName(xtFloat),XTypeName(VarType)]);
  end
end;

function XVar.Assigned:Boolean; inline;
begin
  Result:= FInstance<>nil;
end;

function XVar.VarType: XType; inline;
begin
  if Assigned then Result := FInstance^.InstanceType
              else Result := xtNull;
end;

function XVar.IsNumeric:boolean;inline;
begin
  Result:=(VarType=xtInteger) or (VarType=xtFloat);
end;

function XVar.isContainer:boolean;inline;
begin
  Result:=(VarType=xtObject) or (VarType=xtArray);
end;

function XVar.IsNull:Boolean;inline;
begin
  Result:= VarType=xtNull
end;


function XVar.Deleted:boolean;inline;
begin
  if Assigned then Result:=FInstance^.Deleted
              else Result:=False;
end;

function XVar.Modified:boolean;inline;
begin
  if Assigned then Result:=FInstance^.Modified
              else Result:=False;
end;

function XVarHelper.AsObject: XObject;inline;
begin
  if VarType=xtObject then Result.FInstance:=FInstance
                       else Result:=XObject.Null;
end;


function XVarHelper.AsArray: XArray;inline;
begin
  //XObjects also can be typecasted to arrays
  if (VarType=xtArray) or (VarType=xtObject) then Result.FInstance:=FInstance
                                             else Result:=XArray.Null;
end;


// XArray
operator := ( AnArray: XArray): XVar;inline;
begin
 Result.FInstance:=AnArray.FInstance;
end;

function XArray.Assigned: boolean; Inline;
begin
 Result:=FInstance<>nil;
end;

function XArray.Count: Cardinal; Inline;
begin
  if Assigned then Result:=FInstance^.Count
              else Result:=0;
end;

function XArray.Parent: XVar;inline;
begin
 if Assigned then Result.FInstance:=FInstance^.FParent
             else Result:=null;
end;

function XArray.VarType: XType; inline;
begin
  if Assigned then Result := FInstance^.InstanceType
              else Result := xtNull;
end;

function XArray.GetVar(Index: Cardinal): XVar;
begin
   if Assigned then Result.FInstance:=FInstance^.FContainer^.ItemPtr(Index)
               else Result:=XVar.Null;
end;

function XArray.Add(AType: XType): XVar;
begin
  if Assigned then Result.FInstance:=XInstance.New(AType,FInstance)
              else raise EXONException.Create(XON_Expand_Exception);
end;

// XObject

operator := ( AnObject: XObject): XVar;inline;
begin
  Result.FInstance:=AnObject.FInstance;
end;

function XObject.Assigned: boolean; Inline;
begin
 Result:=FInstance<>nil;
end;

function XObject.Count: Cardinal; Inline;
begin
 if Assigned then Result:=FInstance^.Count
             else Result:=0;
end;

function XObject.Parent: XVar;inline;
begin
 if Assigned then Result.FInstance:=FInstance^.FParent
             else Result:=null;
end;

function XObject.VarType: XType; inline;
begin
  if Assigned then Result := xtObject
              else Result := xtNull;
end;

function XObject.GetVar(Index: Cardinal): XVar;
begin
  if Assigned then Result.FInstance:=FInstance^.FContainer^.ItemPtr(Succ(Index shl 1))
              else Result:=XVar.Null;
end;

function XObject.GetKey(Index: Cardinal): XVar;
begin
 if Assigned then Result.FInstance:=FInstance^.FContainer^.ItemPtr(Index shl 1)
             else Result:=XVar.Null;
end;

// linear search in object
function XObject.GetItemByKey(const S: String): XVar;
var i: integer;
begin
 Result:=XVar.Null;
 for i:=00 to Count-1 do
  if Keys[i].AsString=S then
    begin
      Result:=Vars[i];
      Break
    end;
end;

function XObject.Add(AType: XType;const AKey:String=''): XVar;
begin
  if Assigned then
    begin
      if AKey<>'' then XInstance.New(xtString,FInstance)^.FStr.SetStr(AKey);
       Result.FInstance:=XInstance.New(AType,FInstance);
    end
     else Raise EXONException.Create(XON_Expand_Exception);
end;

initialization

end.

