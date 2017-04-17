unit xtypes;

{$mode objfpc}{$H+}

interface

type

 XType =  ( // basic types - use only the lower 5 bits - max 32 types!!!
               xtNull= 0,
               xtInteger,
               xtFloat,
               xtBoolean,
               xtString,
               xtObject,
               xtArray,
            // extra types
               xtInt64,
               xtBinary,
               xtDateTime
 );

 // Number types
 XFloat = Single;
 XInt = Integer;

 function XTypeName( AType: XType): String;

implementation

function XTypeName( AType: XType): String;
begin
  case AType of
               xtNull: Result:='Null';
               xtInteger: Result:='Integer';
               xtFloat: Result:='Float';
               xtBoolean: Result:='Boolean';
               xtString: Result:='String';
               xtObject: Result:='Object';
               xtArray: Result:='Array';
               xtBinary: Result:='Binary';
               xtDateTime: Result:='DateTime';

  end;
end;

end.

