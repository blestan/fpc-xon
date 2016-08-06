unit xonbinary;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,xtypes,xins,xon;


type

   XONBaseWriter=class
       private
       protected
         procedure Write(var Buf; Len: Cardinal);
       public
         procedure WriteXON(AVar: XVar);
   end;

implementation

procedure XONBaseWriter.WriteXON(AVar: XVar);
begin
  Write(
end;

end.

