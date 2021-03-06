unit xstr;

{$mode objfpc}{$H+}
{$modeswitch advancedrecords}

interface


type

    XONStr = packed record
              private
               const xstrInlineSize=6; // do not modify ... binary comptibility will be broken!
               type
                TXONStrType=(
                              xstNull=0, // Empty
                              xstInline, // Directly encoded in the record... up to xstrInlineSize chars
                              xstNative // Native FPC String
                             );
              private
               FType: Byte;
             public
              procedure Initialize;
              procedure Finalize;
              procedure SetString( Source: PChar; L: Cardinal);overload;
              procedure SetString( const Source: String);overload;
              function Length: Integer;
              function GetAsString: String;
            private
              case TXONStrType of
               xstInline: ( FLength: Byte; FChars: Array [01..xstrInlineSize] of Char);
               xstNative: ( FStr: Pointer); // fpc string
          end;

implementation

procedure XONStr.Initialize;inline;
begin
  FType:=Ord(xstNull);
  FStr:=nil; // set to zeros - just in case ;)
end;

procedure XONStr.Finalize;
begin
  case TXONStrType(FType) of
   xstNull: exit;
   xstInline: FLength:=0;
   xstNative: begin
                String(FStr):='';
                FStr:=nil
              end;
  end;
  FType:=Ord(xstNull);
end;

function XONStr.Length:Integer;
begin
  Result:=0;
  case TXONStrType(FType) of
   xstInline: Result:=FLength;
   xstNative: Result:=system.Length(String(FStr));
  end;
end;

procedure  XONStr.SetString( Source: PChar; L: Cardinal);
var Dest: PChar;
begin
  Finalize;
  if L=0 then exit;
  if L>xstrInlineSize then
   begin
    FType:=ord(xstNative);
    FStr:=nil;
    SetLength(String(FStr),L);
    Dest:=@String(FStr)[1]
   end
   else
    begin
     FType:=ord(xstInline);
     FLength:=L;
     Dest:=@FChars[1];
    end;
  Move(Source^,Dest^,L);
end;

procedure  XONStr.SetString( const Source: String);
var L: Integer;
begin
  Finalize;
  L:=System.Length(Source);
  if L=0 then exit;
  if L>xstrInlineSize then
   begin
    FType:=ord(xstNative);
    FStr:=nil;
    String(FStr):=Source;
   end
   else
    begin
     FType:=ord(xstInline);
     FLength:=L;
     Move(Source[1],FChars[1],L);
    end;
end;

function XONStr.GetAsString: string;
begin
  case TXONStrType(FType) of
   xstNull: Result:='';
   xstInline: begin
               SetLength(Result,FLength);
               Move(FChars,Result[1],FLength)
              end;
   xstNative: Result:=String(FStr)
  end;
end;

end.

