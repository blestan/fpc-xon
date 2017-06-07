unit xtypes;

{$mode objfpc}{$H+}

interface

type

 XType =  ( // basic types
               xtNull= 0,
               xtToken, // identifier - interaly this is a string - can be used for various data models implementations
               xtInteger,
               xtFloat,
               xtBoolean,
               xtString,
               xtArray,
               xtList,
            // extra types
               xtInt64,
               xtInt128, // reserved for future use
               xtBinary,
               xtDateTime,
               xtGUID
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
               xtToken: Result:='Token';
               xtInteger: Result:='Integer';
               xtFloat: Result:='Float';
               xtBoolean: Result:='Boolean';
               xtString: Result:='String';
               xtList: Result:='List';
               xtArray: Result:='Array';
               xtInt64: Result:= 'Int64';
               xtBinary: Result:='Binary';
               xtDateTime: Result:='DateTime';
               xtGUID: Result:='GUID';

  end
end;

end.

