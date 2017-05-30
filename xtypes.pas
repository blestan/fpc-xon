unit xtypes;

{$mode objfpc}{$H+}

interface

type

 XType =  ( // basic types
               xtNull= 0,
               xtToeken, // Interaly this is a unresolved string - can be used for various data models implementations
               xtInteger,
               xtFloat,
               xtBoolean,
               xtString,
               xtObject,
               xtArray,
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

 XPoolModel = (
               xpNone, // No Pool - default behaviour  getmem / freemem
               xpShareLock, // One pool for all threads
               xpPerThread // One pool per thread
              );


function XTypeName( AType: XType): String;

 var XONPoolModel: XPoolModel = xpNone;

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
               xtInt64: Result:= 'Int64';
               xtBinary: Result:='Binary';
               xtDateTime: Result:='DateTime';

  end;
end;

end.

