unit xonbinary;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,xtypes,xins,xon;

type

   XONBaseIO=class
      protected
         class function IntLen(AValue: DWord): Cardinal;overload;
         class function IntToZigZag(I: Integer): Cardinal;
         class function FloatToZigZag(F: Single): Cardinal;
         class function ZigZagToInt(Z: Cardinal): Integer;
         class function ZigZagToFloat(Z: Cardinal): Single;
     end;

   XONBaseWriter=class(XONBaseIO)
       protected
         procedure Write(var Buf; Len: LongInt);virtual; abstract;
       public
         procedure WriteXON(AVar: XVar);
   end;

    XONBaseReader=class(XONBaseIO)
       protected
         procedure Read(out Buf; Len: LongInt);virtual; abstract;
       public
         function ReadXON: XVar;
   end;

   XONStreamWriter=class(XONBaseWriter)
     private
       FStream: TStream;
     protected
       procedure Write(var Buf; Len: LongInt);override;
     public
       Constructor Create(AStream: TStream);
   end;

   XONStreamReader=class(XONBaseReader)
     private
       FStream: TStream;
     protected
       procedure Read(out Buf; Len: LongInt);override;
     public
       Constructor Create(AStream: TStream);
   end;



implementation

class function XONBaseIO.IntLen(AValue: DWord): Cardinal; inline;
begin
 if AValue=0 then exit(0);
 Result:=BsrDWord(AValue) div 8;
 Inc(Result);
end;

class function XONBaseIO.IntToZigZag(I: Integer): Cardinal;
begin
  Result:= Cardinal(SarLongint(I,31)) xor Cardinal(I shl 1);

end;

class function XONBaseIO.FloatToZigZag(F: Single): Cardinal;
Var I: Integer absolute F;
begin
  Result:= Cardinal(SarLongint(I,31)) xor Cardinal(I shl 1);

end;

class function XONBaseIO.ZigZagToInt(Z: Cardinal): Integer;
begin
  Result := integer (Z shr 1) xor integer (-(Z and 1));
end;

class function XONBaseIO.ZigZagToFloat(Z: Cardinal):Single;
Var I: Integer;
    F: Single absolute I;
begin
 I:=ZigZagToInt(Z);
 Result:=F;
end;

procedure XONBaseWriter.WriteXON(AVar: XVar);
var i: Integer;
    S: String;

procedure WriteHeader(Signature: XType; Int: Cardinal);
var L,B: Byte;
      LE: Cardinal;
begin
  L:=IntLen(Int);
  LE:=NtoLE(Int);
  B:=Byte(Signature) or (L shl 5);
  Write(B,1);
  Write(LE,L);
end;

begin
  Case AVar.VarType of
               xtNull: WriteHeader(xtNull,0);
               xtInteger: WriteHeader(AVar.VarType,IntToZigZag(AVar.AsInteger));
               xtFloat:  WriteHeader(AVar.VarType,FloatToZigZag(AVar.AsFloat));
               xtBoolean: WriteHeader(AVar.VarType,Ord(AVar.AsBoolean));
  xtString: begin  // do to: optimize
                 S:=AVar.AsString;
                 WriteHeader(AVAr.VarType,Length(S));
                 Write(S[1],Length(S));
            end;
               xtList: with AVar do
                         begin
                          WriteHeader(AVar.VarType,Count);
                          if count>0 then
                           for i:=0 to Count-1 do
                            begin
                              WriteXON(Keys[i]);
                              WriteXON(Vars[i]);
                            end;
               end;
               xtArray:with AVar do
                         begin
                          WriteHeader(AVar.VarType,Count);
                           if count>0 then for i:=0 to Count-1 do WriteXON(Vars[i]);
               end;
  end;
end;


function XONBaseReader.ReadXON: XVar;
var
 FSuper: XVar;

function ReadVar: XVar;
var Sign,L:byte;
         I,N: Cardinal;
         S: String;
begin
 Read(Sign,1);
 L:=sign shr 5;
 Sign:=sign and %00011111;
 I:=00;
 Read(I,L);
 I:=LEtoN(I);
 case XType(Sign) of
      xtNull: Result:=XVar.New(xtNull,FSuper);
      xtInteger: begin
                   Result:=XVar.New(xtInteger,FSuper);
                   Result.AsInteger:=ZigZagToInt(I);
                 end;
      xtFloat:  begin
                   Result:=XVar.New(xtFloat,FSuper);
                   Result.AsFloat:=ZigZagToFloat(I);
                 end;

      xtBoolean: begin
                  Result:=XVar.New(xtBoolean,FSuper);
                  Result.AsBoolean:=I<>0;
                 end;
      xtString: Begin
                 Result:=XVar.New(xtString,FSuper);
                 S:='';
                 SetLength(S,I);
                 Read(S[1],I);
                 Result.AsString:=S;
      end;

      xtArray: begin
                 Result:=XVar.New(xtArray,FSuper);
                 if I>0 then
                   begin
                    FSuper:=Result;
                    for N:=0 to I-1 do ReadVar();
                    FSuper:=Result.Parent;
                   end;
                end;
       xtList: begin
                 Result:=XVar.New(xtList,FSuper);
                 if I>0 then
                   begin
                    FSuper:=Result;
                    for N:=0 to I-1 do
                     begin
                      ReadVar();
                      ReadVar();
                     end;
                    FSuper:=Result.Parent;
                   end;

      end;

 end;


end;

begin

FSuper:=XVar.Null;
Result:=ReadVar;

end;

Constructor XONStreamWriter.Create(AStream: TStream);
begin
  Inherited Create;
  FStream:=AStream;
end;

procedure XONStreamWriter.Write(var Buf; Len: LongInt);
begin
 FStream.Write(buf,Len);
end;

Constructor XONStreamReader.Create(AStream: TStream);
begin
  Inherited Create;
  FStream:=AStream;
end;

procedure XONStreamReader.Read(out Buf; Len: LongInt);
begin
 FStream.Read(buf,Len);
end;

end.

