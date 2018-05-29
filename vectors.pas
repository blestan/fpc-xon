unit vectors;

{$mode objfpc}
{$H+}
{$modeswitch advancedrecords}

interface

type

      TVector=record
               private
                const DefaultDelta = 32;
               private
                FInstance: Pointer;
                procedure InternalSetCapacity(NewCapacity: PtrUInt);
                procedure SetCapacity( NewCapacity: PtrUInt);
                function GetCapacity: PtrUInt;
               public
                class function New( InitialCapacity: PtrUInt=4): TVector;static;
                procedure Free;
                property Capacity: PtrUInt read GetCapacity write SetCapacity;
                function Count: PtrUInt;
                procedure Grow( Delta: PtrUInt=DefaultDelta);
                function Push( P: Pointer): PtrUInt;
      end;

implementation

type

   VHeader= packed record
             FCapacity: PtrUInt;
             FCount: PtrUInt;
             FPointers: array [0..512*1024*1024-4] of Pointer;
   end;

class function TVector.New( InitialCapacity: PtrUInt=4 ): TVector;
begin
  Result.FInstance:=nil;
  if InitialCapacity>0 then Result.SetCapacity(InitialCapacity);
end;

procedure TVector.Free;
begin
  if FInstance<>nil then
    begin
      FreeMem(FInstance);
      FInstance:=nil;
    end;
end;

function TVector.Count: PtrUInt;inline;
begin
  if FInstance=nil then Result:=0
   else Result:=VHeader(FInstance^).FCount
end;

function TVector.GetCapacity: PtrUInt;inline;
begin
  if FInstance<>nil then
     Result:=VHeader(FInstance^).FCapacity
   else Result:=0;
end;

procedure TVector.InternalSetCapacity( NewCapacity: PtrUInt);
begin
  ReAllocMem(FInstance,(NewCapacity+2)*SizeOf(PtrUInt));
  VHeader(FInstance^).FCapacity:=NewCapacity;
end;

procedure TVector.SetCapacity( NewCapacity: PtrUInt );
begin
 if NewCapacity=0 then Free
  else
   begin
    InternalSetCapacity(NewCapacity);
    with VHeader(FInstance^) do if FCount>FCapacity then FCount:=FCapacity;
   end
end;

procedure TVector.Grow( Delta: PtrUInt=DefaultDelta);inline;
begin
 InternalSetCapacity(Capacity+Delta);
end;

function TVector.Push( P: Pointer): PtrUInt;
var C: PtrUInt;
begin
 C:=Count;
 if C>=Capacity then Grow;
 with VHeader(FInstance^) do
   begin
     FPointers[C]:=P;
     Inc(C);
     FCount:=C
   end
end;

end.

