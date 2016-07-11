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
               xtIdentifier,
               xtBinary,
               xtDateTime,
               xtHash
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
               xtIdentifier: Result:='Identifier';
               xtBinary: Result:='Binary';
               xtDateTime: Result:='DateTime';
               xtHash: Result:='Hash';

  end;
end;

end.

