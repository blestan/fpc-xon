unit test_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, Menus, ExtCtrls, xon, xonjson,xtypes;

type

  { TForm1 }

  TForm1 = class(TForm)
    JSONMemo: TMemo;
    Panel1: TPanel;
    Panel2: TPanel;
    ParseBtn: TButton;
    LoadBtn: TButton;
    LogOutput: TMemo;
    OpenDialog1: TOpenDialog;
    XONTree: TTreeView;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure JsonMemoChange(Sender: TObject);
    procedure Panel2Click(Sender: TObject);
    procedure ParseBtnClick(Sender: TObject);
    procedure LoadBtnClick(Sender: TObject);
    procedure XONTreeDblClick(Sender: TObject);
    procedure XONTreeMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { private declarations }
    parser: TJSONParser;
  public
    { public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

var
  T,T1: Int64;

{ TForm1 }

procedure TForm1.ParseBtnClick(Sender: TObject);
var

    s: String;
    r: integer;

procedure DumpNode( X: XVar; AParent: TTreeNode;const APrefix: string);
var NodeTxt: String;
    Node: TTreeNode;
    Prefix: String;
    C: Integer;
begin
  NodeTxt:=APrefix+' : '+XTypeName(X.VarType);
  if X.isContainer then NodeTxt:=NodeTxt+Format('[%d]',[X.AsArray.Count])
                   else NodeTxt:=NodeTxt+Format(':(%s)',[X.AsString]);
  Node:=XONTree.Items.AddChildObject(AParent,NodeTxt,Pointer(X));

  if X.isContainer then
    for c:=0 to X.asArray.Count-1 do
    begin
      case X.VarType of

      xtObject: with X.AsObject do
                  begin
                   Prefix:=Keys[C].AsString;
                   DumpNode(Vars[C],Node,Prefix);
                  end;
      xtArray: DumpNode(X.AsArray[c],Node,'');
    end
   end
end;


begin
  Caption:=IntToStr(XVar.InstanceSize);
  LogOutput.Lines.Clear;
  s:=JsonMemo.Text;
  Parser.Reset;
  T:=GetTickCount64;
  r:=parser.parse(s);
  T1:=GetTickCount64;
  LogOutput.Append(Format('JSON Parsing Time: %d',[t1-t]));
  XONTree.Items.Clear;
  if R<0 then LogOutput.Append(format('Error code: %d @ %d:"%s"  near <*%s*>',[r,parser.position,s[parser.position],copy(s,parser.position-32,64)]))
         else
           begin
             LogOutput.Append( format ('OK! %d json chars parsed into %d XON instances.',[length(s),r]));
             T:=GetTickCount64;
             XONTree.BeginUpdate;
             DumpNode(Parser.XON,nil,'');
             XONTree.EndUpdate;
             T1:=GetTickCount64;
             LogOutput.Append(Format('Tree Update Time: %d',[t1-t]));
           end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 parser:= TJSONParser.Create;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
 Parser.Free;
end;

procedure TForm1.JsonMemoChange(Sender: TObject);
begin

end;

procedure TForm1.Panel2Click(Sender: TObject);
begin

end;

procedure TForm1.LoadBtnClick(Sender: TObject);
begin
  if OpenDialog1.Execute then with JsonMemo do
       Lines.LoadFromFile(OpenDialog1.FileName);
end;


procedure TForm1.XONTreeDblClick(Sender: TObject);
var Sel: XVar;
    S: String;
    N: TTreeNode;
begin
  if assigned(XONTree.Selected) then
    begin
     Sel:=XVar(XONTree.Selected.Data);
     if sel.VarType=xtObject then
      begin
       S:=InputBox('Find key','Please enter key name','');
       Sel:=Sel.asObject[S];
       Caption:=Sel.AsString;
       N:=XONTree.Selected.GetFirstChild;
       while N<>nil do if N.Data=Pointer(Sel) then Break
                                              else N:=N.GetNextSibling;
       if N<>nil then XONTree.Selected:=N;
      end;
    end;
end;

procedure TForm1.XONTreeMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin

end;


end.

