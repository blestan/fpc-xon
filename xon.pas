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

           function GetVar(index: Cardinal): XVar;overload;
           function GetVar(const index: string): XVar;overload;
           function GetKey(index: Cardinal): XVar;

         public
           const Null: XVar =( FInstance : Nil);

           function VarType: XType;

           class function InstanceSize: Cardinal;static;

           class function New(AType: XType):XVar;static; //Create New ROOT Variable
           class function New(AType: XType; AParent: XVar): XVar;static; // Create New Variable as child of an existing xon
           function Add(AType: XType): XVar; // Add new child in Array
           function Add(AType: XType;const AKey:String): XVar; // Add new child in Object
           procedure Free;  //

           function Assigned:boolean;

           function Count: Cardinal;
           function Parent: XVar;

           procedure SetString(AValue: PChar; Size: Cardinal);overload;
           property AsInteger: XInt read GetInteger write SetInteger;
           property AsBoolean: Boolean read GetBoolean write SetBoolean;
           property AsString: String read GetString write SetString;
           property AsFloat: XFloat read GetFloat write SetFloat;
           property Vars[index: cardinal]: XVar read GetVar;default;
           property Keys[Index: Cardinal]: XVar read GetKey;

           function Deleted:boolean;
           function Modified: boolean;
           function isContainer: boolean;
           function IsNumeric: Boolean;
           function IsNull: Boolean;
         end;

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
class function XVar.New(AType: XType): XVar;inline;
begin
  Result.FInstance:=XInstance.Alloc(AType,nil);
end;

// create child
class function XVar.New(AType: XType; AParent: XVar): XVar;inline;
begin
 Result.FInstance:=XInstance.Alloc(AType,AParent.FInstance);
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
                                         else raise EXONException.CreateFmt(XON_Assign_Exception,[XTypeName(xtString),XTypeName(VarType)]);
end;

procedure XVar.SetString(const AValue: String);
begin
  if VarType = xtString then FInstance^.FStr.SetStr(AValue)
                         else raise EXONException.CreateFmt(XON_Assign_Exception,[XTypeName(xtString),XTypeName(VarType)]);
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
     xtFloat: Result:= Round(FInstance^.FFloat);
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

function XVar.Count: Cardinal; Inline;
begin
  if isContainer then Result:=FInstance^.Count
                 else Result:=0;
end;

function XVar.Parent: XVar;inline;
begin
 if isContainer then Result.FInstance:=FInstance^.FParent
                else Result:=null;
end;


// linear search in object
function XVar.GetVar(const Index: String): XVar;
var i: integer;
begin
 if (VarType<>xtObject) or (FInstance^.FContainer=nil) then exit(XVar.Null);
 for i:=00 to Count-1 do
  if Keys[i].AsString=Index then
    begin
      Result:=Vars[i];
      Break
    end;
end;


function XVar.GetVar( Index: Cardinal): XVar;
begin
 if (not (VarType in [xtArray,xtObject])) or (FInstance^.FContainer=nil)  then exit(XVar.Null);
 if VarType=xtObject then Index:=Succ(Index shl 1);
 Result.FInstance:=FInstance^.FContainer^[Index];
end;


function XVar.GetKey(Index: Cardinal): XVar;
begin
 if VarType=xtObject then Result.FInstance:=FInstance^.FContainer^[Index shl 1]
                      else Result:=XVar.Null;
end;

function XVar.Add(AType: XType): XVar;
begin
  if VarType=xtArray then Result.FInstance:=XInstance.Alloc(AType,FInstance)
                      else raise EXONException.Create(XON_Expand_Exception);
end;

function XVar.Add(AType: XType;const AKey:String): XVar;
begin
  if VarType=xtObject then
    begin
      XInstance.Alloc(xtString,FInstance)^.FStr.SetStr(AKey);
      Result.FInstance:=XInstance.Alloc(AType,FInstance);
    end
     else Raise EXONException.Create(XON_Expand_Exception);
end;

end.

