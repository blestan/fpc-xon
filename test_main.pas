unit test_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, xon;

type

  { TForm1 }

  TForm1 = class(TForm)
    ParseBtn: TButton;
    LoadBtn: TButton;
    LogOutput: TMemo;
    JsonMemo: TMemo;
    OpenDialog1: TOpenDialog;
    XONTree: TTreeView;
    procedure ParseBtnClick(Sender: TObject);
    procedure LoadBtnClick(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;

implementation

uses xonjson,xtypes;

{$R *.lfm}

var
  T,T1: Int64;

{ TForm1 }

procedure TForm1.ParseBtnClick(Sender: TObject);
var
    parser: TJSONParser;
    s: String;
    r: integer;

procedure DumpNode( X: XVar; AParent: TTreeNode;const APrefix: string);
var NodeTxt: String;
    Node: TTreeNode;
    Prefix: String;
    C: Integer;
begin
  NodeTxt:=APrefix+' : '+XTypeName(X.DataType);
  if X.DataType in [xtObject,xtArray] then NodeTxt:=NodeTxt+Format('[%d]',[X.Count])
                                      else NodeTxt:=NodeTxt+Format(':(%s)',[X.AsString]);
  Node:=XONTree.Items.AddChild(AParent,NodeTxt);
  if X.DataType in [xtObject,xtArray] then
    for c:=0 to X.Count-1 do
    begin
      If X.DataType=xtObject then Prefix:=X.Keys[C].AsString
                             else Prefix:='';
      DumpNode(X[c],Node,Prefix);
    end;
end;

begin
  Caption:=IntToStr(XVar.InstanceSize);
  LogOutput.Lines.Clear;
  s:=JsonMemo.Text;
  parser:= TJSONParser.Create;
  T:=GetTickCount64;
  r:=parser.parse(s);
  T1:=GetTickCount64;
  XONTree.Items.Clear;
  LogOutput.Append(Format('JSON Parsing Time: %d',[t1-t]));
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
  T:=GetTickCount64;
  Parser.Reset;
  T1:=GetTickCount64;
  LogOutput.Append(Format('XON Release Time: %d',[t1-t]));
  Parser.Free;
end;

procedure TForm1.LoadBtnClick(Sender: TObject);
begin
  if OpenDialog1.Execute then with JsonMemo do
       Lines.LoadFromFile(OpenDialog1.FileName);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin

end;


end.

