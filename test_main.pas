unit test_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ComCtrls, Menus, ExtCtrls, xon, xonjson,xtypes,xonbinary;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    JSONMemo: TMemo;
    LoadBtn1: TButton;
    Panel1: TPanel;
    Panel2: TPanel;
    ParseBtn: TButton;
    LoadBtn: TButton;
    LogOutput: TMemo;
    OpenDialog1: TOpenDialog;
    XONTree: TTreeView;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure JsonMemoChange(Sender: TObject);
    procedure LoadBtn1Click(Sender: TObject);
    procedure Panel1Click(Sender: TObject);
    procedure Panel2Click(Sender: TObject);
    procedure ParseBtnClick(Sender: TObject);
    procedure LoadBtnClick(Sender: TObject);
    procedure XONTreeDblClick(Sender: TObject);
  private
    { private declarations }
    parser: TJSONParser;
    procedure DumpNode( X: XVar; AParent: TTreeNode;const APrefix: string);
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

procedure TForm1.DumpNode( X: XVar; AParent: TTreeNode;const APrefix: string);
var NodeTxt: String;
    Node: TTreeNode;
    Prefix: String;
    C: Integer;
begin
  NodeTxt:=APrefix+' : '+XTypeName(X.VarType);
  if X.isContainer then NodeTxt:=NodeTxt+Format('[%d]',[X.Count])
                   else NodeTxt:=NodeTxt+Format(':(%s)',[X.AsString]);
  Node:=XONTree.Items.AddChildObject(AParent,NodeTxt,Pointer(X));

  if X.isContainer then
    for c:=0 to X.Count-1 do
    begin
      case X.VarType of

      xtObject: with X do
                  begin
                   Prefix:=Keys[C].AsString;
                   DumpNode(Vars[C],Node,Prefix);
                  end;
      xtArray: DumpNode(X[c],Node,'');
    end
   end
end;

procedure TForm1.ParseBtnClick(Sender: TObject);
var

    s: String;
    r: integer;
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
             LogOutput.Append(Format('Tree Update Time: %d ms',[t1-t]));
           end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
 parser:= TJSONParser.Create;
end;

procedure TForm1.Button1Click(Sender: TObject);
var S: TStream;
    W: XONBaseWriter;
begin
  S:=TFileStream.Create('c:\temp\test.xon',fmCreate);
  W:=XONStreamWriter.Create(S);
  W.WriteXON(parser.XON);
  W.Free;
  S.Free;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
 Parser.Free;
end;

procedure TForm1.JsonMemoChange(Sender: TObject);
begin

end;

procedure TForm1.LoadBtn1Click(Sender: TObject);
var S: TStream;
    R: XONStreamReader;
    X: XVar;
begin
  S:=TFileStream.Create('c:\temp\test.xon',fmOpenRead);
  R:=XONStreamReader.Create(S);
  T:=GetTickCount64;
  X:=R.ReadXON;
  T1:=GetTickCount64;
  LogOutput.Append(Format('Reading XON Binary: %d ms',[t1-t]));
  T:=GetTickCount64;
  XONTree.BeginUpdate;
  DumpNode(X,nil,'');
  XONTree.EndUpdate;
  T1:=GetTickCount64;
  LogOutput.Append(Format('Tree Update Time: %d ms',[t1-t]));
  R.Free;
  S.Free;
  X.Free;
end;

procedure TForm1.Panel1Click(Sender: TObject);
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
       Sel:=Sel[S];
       Caption:=Sel.AsString;
       N:=XONTree.Selected.GetFirstChild;
       while N<>nil do if N.Data=Pointer(Sel) then Break
                                              else N:=N.GetNextSibling;
       if N<>nil then XONTree.Selected:=N;
      end;
    end;
end;


end.

