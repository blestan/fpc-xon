unit xtypes;

{$mode objfpc}{$H+}

interface

type

 XType =  ( // basic types
               xtNull= 0,
               xtInteger,
               xtFloat,
               xtBoolean,
               xtString,
               xtObject,
               xtArray,
            // extra types
               xtBinary,
               xtDateTime
 );

 // Number types
 XFloat = Double;
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

