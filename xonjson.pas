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
                  FDepth: Integer; // Current Depth in the xon structure
                  FXON,           // Result of the parsing;
                  FSuper: XVar; //  Current Upper Container
              	  FPos: Cardinal;   // offset in the JSON string
                  function internal_Parse(const js: string): integer;
                public
                  constructor Create;
                  function Parse(const js: string): integer;
                  procedure Reset;
                  property Position: Cardinal read FPos;
                  property XON: XVar read FXON;
               end;


implementation


constructor TJSONParser.Create;
begin
   inherited create;
   FSuper:=XVar.Null;
   FXON:=XVar.Null;
   FDepth:=0;
   FPos:=0;
end;

procedure TJSONParser.Reset;
begin
   FSuper:=XVar.Null;
   FXON.Free;
   FDepth:=0;
   FPos:=0;
end;


function  TJSONParser.parse(const js: string): integer;
begin
   Result:=Internal_Parse(js);
   if (Result<0) and (FDepth>0) then // on error unwind back to the topmost container to avoid mem leaks
     begin
      FXON:=FSuper;
      while FXON.Parent.isValid do FXON.Parent;
     end;
end;

function  TJSONParser.internal_parse(const js: string): integer;

var       len,
   StoredPos : Cardinal;
            r: integer;
ValueExpected: Boolean;


function skip:boolean;inline;
begin
   if FPos>=len then exit(false);
   Inc(FPos);
   Result:=True;
end;

function Parse_Number: integer;  // Do to : rework the code to handle exponents
var
    Sign: Integer =1;
  //  ExponentSign: integer =1; // to do: the exponent part
    Int: Qword = 0;
    Fract: Qword = 0;
    Pow10: Qword =1;
//    ExpPart: Qword =0;
begin
   // Deal with signs
  if js[Fpos]='-' then begin
                        Sign:=-1;
                        Inc(FPos)
                       end
    else if js[Fpos]='+' then inc(FPos);

  // Now the leading zeros
  while ((Fpos<=len) and (js[Fpos]='0')) do Inc(Fpos);

  // Now the Integer part
  while ((Fpos<=len) and (js[Fpos] in ['0'..'9'])) do
     begin
       Int:=(Int * 10) + (Ord(js[Fpos])-Ord('0'));
       Inc(FPos);
     end;

  //Now the factional part
  if js[Fpos]='.' then
   begin
     Inc(FPos);
     while ((Fpos<=len) and (js[Fpos] in ['0'..'9'])) do
      begin
       Fract:=(Fract * 10) + (Ord(js[Fpos])-Ord('0'));
       Pow10:=Pow10*10;
       Inc(FPos);
      end;
   end;

  if not (js[Fpos] in [#0..#32,',',']','}','0'..'9']) then exit(JSON_ERROR_INVAL);

  if fract=0 then FXON:=XVar.Create(Sign*Int,FSuper)
             else FXON:=XVar.Create(Sign*(Int+(Fract/Pow10)),FSuper);

  Result:=JSON_ERROR_NONE
end;

begin
  Result:=0;
  len:=Length(js);
  FPos:=1;
  ValueExpected:=False;
  while FPos<=len do
    begin
     case js[FPos] of
     #0..#32: inc(FPos); // these are "empty" chars - skip them

     '"': begin // openning quote - string found
           StoredPos:=FPos;
           while true do
            begin
             if FPos<=len then inc(FPos) else exit(JSON_ERROR_PARTIAL); // end of string reached but no closing quote found
             if (js[FPos]='"') and (js[FPos-1]<>'\') then break; // this is a non escaped quote - end of string found
            end;
           FXON:=XVar.Create(@js[StoredPos+1],FPos-StoredPos-1,FSuper);
           inc(FPos);
           inc(Result);
          end;

     ',': if not (FSuper.DataType in [xtArray,xtObject]) then exit(JSON_ERROR_INVAL)
             else begin
               ValueExpected:=False;
               inc(FPos);
             end;

       ':': if (FSuper.DataType<>xtObject) and ValueExpected then exit(JSON_ERROR_INVAL)
              else
                begin
                ValueExpected:=True;
                inc(FPos);
              end;

     '[': begin
               FXON:=XVar.CreateArray(FSuper);
               FSuper:=FXON;
               inc(Fpos);
               inc(Result);
               inc(FDepth)
          end;


     '{': begin
            FXON:=XVar.CreateObject(FSuper);
            FSuper:=FXON;
            inc(Fpos);
            inc(Result);
            inc(FDepth)
          end;

     ']','}':  if FSuper.DataType in [xtObject,xtArray] then
                   begin
                    Dec(FDepth);
                    if FDepth=0 then // we are closing the last container
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
               if FPos<len then inc(FPos) else exit(JSON_ERROR_PARTIAL); // skip F
               if js[Fpos] in ['A','a']  then inc(FPos)
                                         else exit(JSON_ERROR_INVAL);
               if FPos>len then exit(JSON_ERROR_PARTIAL);
               if js[Fpos] in ['L','l'] then inc(FPos)
                                      else exit(JSON_ERROR_INVAL);
               if FPos>len then exit(JSON_ERROR_PARTIAL);
               if js[Fpos] in ['S','s'] then inc(FPos)
                                      else exit(JSON_ERROR_INVAL);
               if FPos>len then exit(JSON_ERROR_PARTIAL);
               if js[Fpos] in ['E','e'] then inc(FPos)
                                      else exit(JSON_ERROR_INVAL);
               FXON:=XVar.Create(False,FSuper);
               inc(Result);
       end;

      'N','n':begin // unrolled for speed to parse "NULL"
               if FPos<len then inc(FPos) else exit(JSON_ERROR_PARTIAL); // skip N
               if js[Fpos] in ['U','u']  then inc(FPos)
                                         else exit(JSON_ERROR_INVAL);
               if FPos>len then exit(JSON_ERROR_PARTIAL);
               if js[Fpos] in ['L','l'] then inc(FPos)
                                        else exit(JSON_ERROR_INVAL);
               if FPos>len then exit(JSON_ERROR_PARTIAL);
               if js[Fpos] in ['L','l'] then inc(FPos)
                                        else exit(JSON_ERROR_INVAL);
               FXON:=XVar.Create(FSuper);
               inc(Result);
              end;

      'T','t': begin // unrolled for speed to parse "TRUE"
                 if FPos<len then inc(FPos) else exit(JSON_ERROR_PARTIAL); // skip T
                 if js[Fpos] in ['R','r']  then inc(FPos)
                                         else exit(JSON_ERROR_INVAL);
                 if FPos>len then exit(JSON_ERROR_PARTIAL);
                 if js[Fpos] in ['U','u'] then inc(FPos)
                                      else exit(JSON_ERROR_INVAL);
                 if FPos>len then exit(JSON_ERROR_PARTIAL);
                 if js[Fpos] in ['E','e'] then inc(FPos)
                                       else exit(JSON_ERROR_INVAL);
                FXON:=XVar.Create(True,FSuper);
                inc(Result);
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

end.
