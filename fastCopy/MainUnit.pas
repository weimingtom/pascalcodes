unit MainUnit;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, CoolTrayIcon, Menus,ShellApi,Ini;
const
  WM_TrayIcon = WM_USER + 1280;
type
  TMain = class(TForm)
    Timer: TTimer;
    Logs: TMemo;
    CoolTrayIcon: TCoolTrayIcon;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    procedure N4Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure CoolTrayIconDblClick(Sender: TObject);
    procedure TimerTimer(Sender: TObject);
    procedure FormHide(Sender: TObject);
  private
    { Private declarations }
    IconData: TNotifyIconData;
  public
    { Public declarations }
    procedure AddIconToTray;
    procedure DelIconFromTray;
  end;

var
  Main: TMain;
  ServerDescription: ShortString;
  Cl,shows,OverWrite,Del:Boolean;
  fileFrom,fileTo : string;
implementation

{$R *.dfm}
procedure TMain.AddIconToTray;
begin
    ZeroMemory(@IconData, SizeOf(TNotifyIconData));
    IconData.cbSize := SizeOf(TNotifyIconData);
    IconData.Wnd := Handle;
    IconData.uID := 1;
    IconData.uFlags := NIF_MESSAGE or NIF_ICON or NIF_TIP;
    IconData.uCallbackMessage := WM_TrayIcon;
    IconData.hIcon := Application.Icon.Handle;
    StrPCopy(IconData.szTip, ServerDescription);
    Shell_NotifyIcon(NIM_ADD, @IconData);
end;
procedure TMain.CoolTrayIconDblClick(Sender: TObject);
begin
  if shows then Hide
  else Show;
end;

procedure TMain.DelIconFromTray;
begin
  Shell_NotifyIcon(NIM_DELETE, @IconData);
end;
procedure TMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if not Cl then
  begin
    Hide;
    Abort;
  end;
end;

procedure TMain.FormCreate(Sender: TObject);
var
    Temp:string;
begin
    Cl := False;
    fileFrom := Ini.ReadIni('server','fileFrom');
    fileTo := Ini.ReadIni('server','fileTo');
    Temp := Ini.ReadIni('server','time');
    if Temp = '' then Timer.Interval := 1 * 1000
    else  Timer.Interval := StrToInt(Temp) * 1000;
    
    OverWrite := Ini.ReadIni('server','overwrite') = 'True';
    Del := Ini.ReadIni('server','Del') = 'True';
    Timer.Enabled := True;
end;

procedure TMain.FormHide(Sender: TObject);
begin
  shows := False;
end;

procedure TMain.FormShow(Sender: TObject);
begin
    shows := True;
end;

procedure TMain.N2Click(Sender: TObject);
begin
    Show;
end;

procedure TMain.N3Click(Sender: TObject);
begin
    Hide;
end;

procedure TMain.N4Click(Sender: TObject);
begin
     DelIconFromTray;
     Cl := True;
     Close;
end;

procedure TMain.TimerTimer(Sender: TObject);
var
  sr:TSearchRec;
  HFile,Times : Integer;
  Today : string;
begin
    Application.ProcessMessages;
    Today := FormatDateTime('yyyy-MM-dd',Now);
    if SysUtils.FindFirst(fileFrom + '\*', faAnyFile, sr) = 0 then
    begin
      repeat
        if (sr.Name<>'.') and (sr.Name<>'..') then
        begin
          CopyFile(PChar(fileFrom + '\' + sr.Name),PChar(fileTo + '\' + sr.Name),OverWrite);
          if Logs.Lines.Count > 200 then Logs.Lines.Clear;
          Logs.Lines.Add(FormatDateTime('hh:mm:ss', now) + ' ������:' + sr.Name);
          if Del then
          begin
//            HFile := FileOpen(fileFrom + '\' + sr.Name,fmOpenRead);
//            Times := FileGetDate(HFile);
//            FileClose(HFile);
//
//            if FormatDateTime('yyyy-mm-dd',FileDateToDateTime(Times)) <> Today then
//            begin
               DeleteFile(PChar(fileFrom + '\' + sr.Name));
               Logs.Lines.Add(FormatDateTime('hh:mm:ss', now) + ' ɾ����:' + sr.Name);
//            end;
          end;
        end;
      until SysUtils.FindNext(sr) <> 0;
      SysUtils.FindClose(sr);
    end;
end;

end.
