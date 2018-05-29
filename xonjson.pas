unit xonjson;

{$mode objfpc}{$H+}

interface

uses xtypes,xon;

const
  JSON_ERROR_NONE = 0;   // No error
  JSON_ERROR_INVAL = -1; // Invalid character inside JSON string
  JSON_ERROR_PARTIAL = -2;  // The string is not a full JSON document, more characters expected

type

  TJSONParser = class
                private
                  FPos,            // offset in the JSON string
                  FDepth: Integer; // Current Depth in the xon structure
                  FXON,           // Result of the parsing;
                  FSuper: XVar; //  Current Upper Container
                  function ParseBuf(Buf: PChar; BufLen: Integer): Integer;
                public
                  constructor Create;
                  destructor Destroy;override;
                  function Parse(const js: string): integer;
                  function Parse( js: PChar; Len: Integer): Integer;
                  procedure Reset;
                  function UseXON: XVar; // detach xon from parser - you must free XVar later.
                  property Position: Integer read FPos;
                  property XON: XVar read FXON;
               end;


 function JSON2XON(const JS: String): XVar;

implementation


constructor TJSONParser.Create;
begin
   inherited create;
   FSuper:=XVar.Null;
   FXON:=XVar.Null;
   FDepth:=0;
   FPos:=0;
end;

destructor TJSONParser.Destroy;
begin
 Reset;
 Inherited Destroy;
end;

procedure TJSONParser.Reset;
begin
   FSuper:=XVar.Null;
   FXON.Free;
   FDepth:=0;
   FPos:=0;
end;

function TJSONParser.UseXON:XVar; // detach from parse for future use
begin
   Result:=FXON;
   FXON:=XVar.Null;
end;

function  TJSONParser.parse(const js: string): integer;
begin


   if js<>'' then Result:=ParseBuf(@js[1],Length(js))
             else result:=0;
   if (Result<0) and (FDepth>0) then // on error unwind back to the topmost container to avoid mem leaks
     begin
      FXON:=FSuper;
       while FXON.Parent.Assigned do FXON:=FXON.Parent;
     end;
end;

function  TJSONParser.parse( js: PChar; len: integer): integer;
begin
  if len>0 then Result:=ParseBuf(js,len)
           else Result:=0;

   if (Result<0) and (FDepth>0) then // on error unwind back to the topmost container to avoid mem leaks
     begin
      FXON:=FSuper;
       while FXON.Parent.Assigned do FXON:=FXON.Parent;
     end;
end;

function TJSONParser.ParseBuf(Buf: PChar; BufLen: Integer): Integer;
var
    StoredPos,
    r: integer;

function Parse_Number: integer;  // TODO: rework the code to handle exponents
var
    Sign: Integer =1;
  //  ExponentSign: integer =1; // to do: the exponent part
    Int: Qword = 0;
    Fract: Qword = 0;
    Pow10: Qword =1;
//    ExpPart: Qword =0;
begin
   // Deal with signs
  if Buf[Fpos]='-' then begin
                        Sign:=-1;
                        Inc(FPos)
                       end
    else if Buf[Fpos]='+' then inc(FPos);

  // Now the leading zeros
  while ((FPos<BufLen) and (Buf[Fpos]='0')) do Inc(Fpos);

  // Now the Integer part
  while ((FPos<BufLen) and (Buf[Fpos] in ['0'..'9'])) do
     begin
       Int:=(Int * 10) + (Ord(Buf[Fpos])-Ord('0'));
       Inc(FPos);
     end;

  //Now the factional part
  if Buf[Fpos]='.' then
   begin
     Inc(FPos);
     while ((Fpos<BufLen) and (Buf[Fpos] in ['0'..'9'])) do
      begin
       Fract:=(Fract * 10) + (Ord(Buf[Fpos])-Ord('0'));
       Pow10:=Pow10*10;
       Inc(FPos);
      end;
   end;

  if not (Buf[Fpos] in [#0..#32,',',']','}','0'..'9']) then exit(JSON_ERROR_INVAL);

  if fract=0 then
              begin
               FXON:=XVar.New(xtInteger,FSuper);
               FXON.AsInteger:=Sign*Int;
              end
             else
              begin
               FXON:=XVar.New(xtFloat,FSuper);
               FXON.AsFloat:=Sign*(Int+(Fract/Pow10));
              end;

  Result:=JSON_ERROR_NONE
end;

begin
  Result:=JSON_ERROR_NONE;
  FPos:=0;
  while FPos<BufLen do
    begin
     case Buf[FPos] of
     #0..#32: inc(FPos); // these are "empty" chars - skip them

     '"': begin // openning quote - string found
           StoredPos:=FPos;
           while true do
            begin
             if FPos<BufLen then inc(FPos) else exit(JSON_ERROR_PARTIAL); // end of string reached but no closing quote found
             if (Buf[FPos]='"') and (Buf[FPos-1]<>'\') then break; // this is a non escaped quote - end of string found
            end;
           FXON:=XVar.New(xtString,FSuper);
           FXON.SetString(@Buf[StoredPos+1],FPos-StoredPos-1);
           inc(FPos);
           inc(Result);
          end;

     ',': if not (FSuper.isContainer) then exit(JSON_ERROR_INVAL)
                                      else inc(FPos);

     ':': if (FSuper.VarType<>xtList) then exit(JSON_ERROR_INVAL)
                                      else inc(FPos);


     '[': begin
               FXON:=XVar.New(xtArray,FSuper);
               FSuper:=FXON;
               inc(Fpos);
               inc(Result);
               inc(FDepth)
          end;


     '{': begin
            FXON:=XVar.New(xtList,FSuper);
            FSuper:=FXON;
            inc(Fpos);
            inc(Result);
            inc(FDepth)
          end;

     ']','}':  if FSuper.isContainer then
                   begin
                    Dec(FDepth);
                    if FDepth=0 then // we are closing the top container
                     begin
                       FXON:=FSuper;
                       Break
                     end
                     else
                      begin
                       FSuper:=FSuper.Parent;
                       Inc(FPos);
                      end
                   end
                    else exit(JSON_ERROR_INVAL);

      'F','f': begin // unrolled for speed to parse "FALSE"
               if BufLen-FPos<4 then exit(JSON_ERROR_PARTIAL);
               inc(FPos);
               if (Buf[FPos]   in ['A','a']) and
                  (Buf[FPos+1] in ['L','l']) and
                  (Buf[FPos+2] in ['S','s']) and
                  (Buf[FPos+3] in ['E','e']) then
                    begin
                      Inc(FPos,4);
                      inc(Result);
                      FXON:=XVar.New(xtBoolean,FSuper);
                      FXON.AsBoolean:=False;
                    end
                   else exit(JSON_ERROR_INVAL);
       end;

      'N','n':begin // unrolled for speed to parse "NULL"
               if BufLen-FPos<3 then exit(JSON_ERROR_PARTIAL);
               inc(FPos);
               if (Buf[FPos]   in ['U','u']) and
                  (Buf[FPos+1] in ['L','l']) and
                  (Buf[FPos+2] in ['L','l']) then
                    begin
                      Inc(FPos,3);
                      inc(Result);
                      FXON:=XVar.New(xtNull,FSuper);
                    end
                   else exit(JSON_ERROR_INVAL);
              end;

      'T','t': begin // unrolled for speed to parse "TRUE"
                 if BufLen-FPos<3 then exit(JSON_ERROR_PARTIAL);
               inc(FPos);
               if (Buf[FPos]   in ['R','r']) and
                  (Buf[FPos+1] in ['U','u']) and
                  (Buf[FPos+2] in ['E','e']) then
                    begin
                      Inc(FPos,3);
                      inc(Result);
                      FXON:=XVar.New(xtBoolean,FSuper);
                      FXON.AsBoolean:=True;
                    end
                   else exit(JSON_ERROR_INVAL);
               end;
      '+','-',
      '.',
      '0'..'9' : begin
                  r := Parse_Number;
	         if (r <> JSON_ERROR_NONE ) then exit(r)
                                            else inc(Result);
               end;
      else
      exit(JSON_ERROR_INVAL); // Unexpected char
    end;
  end;
  if FDepth>0 then result:= JSON_ERROR_PARTIAL  // not all containners are closed .... unbalanced brackets
end;

function JSON2XON(const JS: String): XVar;
var P: TJSONParser;
    r: Integer;
begin
  try
   Result:=XVar.Null;
   P:=TJSONParser.Create;
   r:=P.Parse(JS);
   Result:=P.UseXON;
   if r<=0 then Result.Free;
  finally
    P.Free;
  end;
end;

end.

