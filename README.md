XON is A Cross Platform Object Notation writen in pure object pascal.
it can be used to consume & create different types of structured data like
JSON, XML, HTML
A simple but very fast and capable JSON parser is included.
A Binary serialyzer / deserialyzer is also included

Supported data types are

Tokens (identifiers) 
Strings
Integer
Float
Boolean
Null
Binary
Date/Time
GUID

Array
List (Map)


creation example:

example:

var X: XVar =XVar.Null;

begin

X:=XVar.New(xtList); //Creates a new "root" list object

X.Add(xtString,AKey).SetStr('Hello');

...


Writeln(X['AKey'].AsString);

X.Free;

end;


please note that the code is in alpha stage but usefull and used in real apps!!!