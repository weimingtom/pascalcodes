{******************************************************************************}
{                       CnPack For Delphi/C++Builder                           }
{                     中国人自己的开放源码第三方开发包                         }
{                   (C)Copyright 2001-2011 CnPack 开发组                       }
{                   ------------------------------------                       }
{                                                                              }
{            本开发包是开源的自由软件，您可以遵照 CnPack 的发布协议来修        }
{        改和重新发布这一程序。                                                }
{                                                                              }
{            发布这一开发包的目的是希望它有用，但没有任何担保。甚至没有        }
{        适合特定目的而隐含的担保。更详细的情况请参阅 CnPack 发布协议。        }
{                                                                              }
{            您应该已经和开发包一起收到一份 CnPack 发布协议的副本。如果        }
{        还没有，可访问我们的网站：                                            }
{                                                                              }
{            网站地址：http://www.cnpack.org                                   }
{            电子邮件：master@cnpack.org                                       }
{                                                                              }
{******************************************************************************}

unit CnVerEnhancements;
{ |<PRE>
================================================================================
* 软件名称：CnPack IDE 专家包
* 单元名称：版本信息增强专家
* 单元作者：陈省（hubdog）
* 备    注：本专家不支持D5,C5
* 开发平台：JWinXPPro + Delphi 7.01
* 兼容测试：JWinXPPro ＋Delphi7.０１
* 本 地 化：该单元中的字符串支持本地化处理方式
* 单元标识：$Id: CnVerEnhancements.pas 763 2011-02-07 14:18:23Z liuxiao@cnpack.org $
* 修改记录：2007.01.22 V1.0 by liuxiao
*               使能此单元并加以适应性修改
*           2005.05.05 V1.0 by hubdog
*               创建单元
================================================================================
|</PRE>}

interface

{$I CnWizards.inc}

{$IFDEF CNWIZARDS_CNVERENHANCEWIZARD}

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, ToolsAPI, IniFiles,
  Forms, ExtCtrls, Menus, ComCtrls, Contnrs, CnCommon, CnWizUtils, CnWizNotifier,
  CnWizIdeUtils, CnWizConsts, CnMenuHook, CnConsts, CnWizClasses;

type

//==============================================================================
// 版本信息扩展专家
// Todo: 增加自定义添加新的版本信息，和通用的模版，如网站名称，公司名称等等
//==============================================================================

{ TCnVerEnhanceWizard }

  TCnVerEnhanceWizard = class(TCnIDEEnhanceWizard)
  private
    FLastCompiled: Boolean;
    FIncBuild: Boolean;

    FBeforeBuildNo: Integer;
    FAfterBuildNo: Integer;
    FIncludeVer: Boolean;
    FCompileNotifierAdded: Boolean;
    function GetCompileNotifyEnabled: Boolean;
    procedure SetIncBuild(const Value: Boolean);
    procedure SetLastCompiled(const Value: Boolean);
  protected
    procedure BeforeCompile(const Project: IOTAProject; IsCodeInsight: Boolean;
      var Cancel: Boolean);
    procedure AfterCompile(Succeeded: Boolean; IsCodeInsight: Boolean);
    procedure InsertTime;
    procedure DeleteTime;

    function GetHasConfig: Boolean; override;
    procedure UpdateCompileNotify;
    property CompileNotifyEnabled: Boolean read GetCompileNotifyEnabled;
  public
    constructor Create; override;
    destructor Destroy; override;

    class procedure GetWizardInfo(var Name, Author, Email,
      Comment: string); override;
    procedure LoadSettings(Ini: TCustomIniFile); override;
    procedure SaveSettings(Ini: TCustomIniFile); override;
    procedure Config; override;

    property LastCompiled: Boolean read FLastCompiled write SetLastCompiled;
    property IncBuild: Boolean read FIncBuild write SetIncBuild;
  end;

{$ENDIF CNWIZARDS_CNVERENHANCEWIZARD}

implementation

{$IFDEF CNWIZARDS_CNVERENHANCEWIZARD}

uses
{$IFDEF DEBUG}
  CnDebug,
{$ENDIF}
  CnVerEnhanceFrm, VersionInfo;

const
  csDateKeyName = 'LastCompiledTime';

  csLastCompiled = 'LastCompiled';
  csIncBuild = 'IncBuild';

{ TCnVerEnhanceWizard }

procedure TCnVerEnhanceWizard.AfterCompile(Succeeded,
  IsCodeInsight: Boolean);
var
  Options: IOTAProjectOptions;
  Project: IOTAProject;
begin
  if IsCodeInsight or not Active then Exit;

  //注意build project是在编译后才增加buildno的
  //如果不将版本信息加入可执行文件，退出
  if not FIncludeVer then Exit;

{$IFDEF DEBUG}
  CnDebugger.LogMsg('VerEnhance AfterCompile');
{$ENDIF}                                      
  Options := CnOtaGetActiveProjectOptions;
  if not Assigned(Options) then Exit;

  FAfterBuildNo := Options.GetOptionValue('Build');

{$IFDEF DEBUG}
  CnDebugger.LogMsg(Format('VerEnhance After Build No %d. Compile Succ %d.',
    [FAfterBuildNo, Integer(Succeeded)]));
{$ENDIF}

  Project := CnOtaGetCurrentProject;
  if not Assigned(Project) then
    Exit;

  if not Succeeded and FIncBuild and (FAfterBuildNo > FBeforeBuildNo) then
  begin
    // 编译失败，版本号改回去
{$IFDEF COMPILER6_UP} // 只 D6 及以上改回版本号，D5 由于 Bug 而无效
    CnOtaSetProjectOptionValue(Options, 'Build', Format('%d', [FBeforeBuildNo]));
{$ENDIF}
{$IFDEF DEBUG}
    CnDebugger.LogMsg(Format('VerEnhance Compiling Fail. Set Back Build No %d.', [FBeforeBuildNo]));
{$ENDIF}
  end;

  if not FIncBuild and FLastCompiled then
  begin
    // 不改版本号时如果需要插入时间，则需要这样重写一下让插入时间有效
{$IFDEF COMPILER6_UP} // 只 D6 及以上增加版本号，D5 由于 Bug 而无效
    CnOtaSetProjectOptionValue(Options, 'Build', Format('%d', [FAfterBuildNo]));
{$ENDIF}
  end;
end;

procedure TCnVerEnhanceWizard.BeforeCompile(const Project: IOTAProject;
  IsCodeInsight: Boolean; var Cancel: Boolean);
var
{$IFDEF COMPILER6_UP}
  I: Integer;
  ModuleFileEditor: IOTAEditor;
  ProjectResource: IOTAProjectResource;
  ResourceEntry: IOTAResourceEntry;
  VI: TVersionInfo;
  Stream: TMemoryStream;
{$ENDIF}
  Options: IOTAProjectOptions;
begin
  if IsCodeInsight then Exit;

{$IFDEF DEBUG}
  CnDebugger.LogMsg('VerEnhance BeforeCompile');
{$ENDIF}

  //Hubdog: 注意：通过检查dof文件来获得版本信息是没有用的，因为只有在save project后，才会将内存中的
  //Hubdog: 这些信息写进dof
  Options := CnOtaGetActiveProjectOptions(Project);
  if not Assigned(Options) then Exit;

  FIncludeVer := Options.GetOptionValue('IncludeVersionInfo') = '-1';
  if not FIncludeVer then Exit;

  FBeforeBuildNo := Options.GetOptionValue('Build');

  //先增加文件版本信息, 修改OptionValue的值就可以了
  //Hubdog:SetProjectOptionValue在D5下无法修改Build, Release等版本信息
  //（这是D5/BCB5/BCB6的一个Bug)，但在D6下有效
  if FIncBuild then
  begin
{$IFDEF COMPILER6_UP} // 只 D6 及以上增加版本号，D5 由于 Bug 而无效
    CnOtaSetProjectOptionValue(Options, 'Build', Format('%d', [FBeforeBuildNo + 1]));
{$ENDIF}
{$IFDEF DEBUG}
    CnDebugger.LogFmt('VerEnhance Set New Build No %d.', [FBeforeBuildNo + 1]);
{$ENDIF}
  end;

{$IFDEF COMPILER6_UP} // D6 及以上才处理编译时间

  //添加LastCompileTime信息
  if Active and FLastCompiled then
  begin
  {$IFDEF DEBUG}
    CnDebugger.LogMsg('VerEnhance. Set LastCompiledTime ');
  {$ENDIF}
    InsertTime;
  end
  else
  begin
    DeleteTime;
    Exit;
  end;

  //Hubdog: 注意不管是编译还是build，都会生成版本信息，只不过一个增加build no ,一个不增加
  //Hubdog: 注意：即便是Auto-inc Build No，也只是将当前的版本号编译进EXE，然后才增加BuildNo
  //LiuXiao: 再注意：以下对 BDS 2005/20006 无效，它们的 Bug 导致无法获得 Resource接口，但似乎没影响。
  for I := 0 to Project.GetModuleFileCount - 1 do
  begin
    ModuleFileEditor := CnOtaGetFileEditorForModule(Project, I);

    if Supports(ModuleFileEditor, IOTAProjectResource, ProjectResource) then
    begin
{$IFDEF DEBUG}
      CnDebugger.LogMsg('VerEnhance IOTAProjectResource Got.');
{$ENDIF}
    
      ResourceEntry := ProjectResource.FindEntry(RT_VERSION, PChar(1));
      if Assigned(ResourceEntry) then
      begin
        VI := TVersionInfo.Create(PChar(ResourceEntry.GetData));
        try
          Stream := TMemoryStream.Create;
          try
            VI.SaveToStream(Stream);
            ResourceEntry.DataSize := Stream.Size;
            Move(Stream.Memory^, ResourceEntry.GetData^, Stream.Size);
          finally
            Stream.Free;
          end;
        finally
          VI.Free;
        end;
      end;
    end
  end;
{$ENDIF}
end;

procedure TCnVerEnhanceWizard.Config;
begin
  // 进行配置。
  with TCnVerEnhanceForm.Create(nil) do
  try
    chkLastCompiled.Checked := FLastCompiled;
    chkIncBuild.Checked := FIncBuild;
    if ShowModal = mrOK then
    begin
      LastCompiled := chkLastCompiled.Checked;
      IncBuild := chkIncBuild.Checked;
      DoSaveSettings;
    end;
  finally
    Free;
  end;
end;

constructor TCnVerEnhanceWizard.Create;
begin
  inherited;
  CnWizNotifierServices.AddBeforeCompileNotifier(BeforeCompile);
  CnWizNotifierServices.AddAfterCompileNotifier(AfterCompile);
end;

procedure TCnVerEnhanceWizard.InsertTime;
var
  Keys: TStringList;
begin
  Keys := TStringList(CnOtaGetVersionInfoKeys);
  try
    Keys.Values[csDateKeyName] := DateTimeToStr(Now);
  except
    // 对于D5/BCB5/BCB6出错的，简单屏蔽
{$IFDEF DEBUG}
    CnDebugger.LogMsg('VerEnhance. Insert LastCompiledTime not Exists or Fail.');
{$ENDIF}
  end;
end;

procedure TCnVerEnhanceWizard.DeleteTime;
var
  Keys: TStringList;
  Index: Integer;
begin
  Keys := TStringList(CnOtaGetVersionInfoKeys);
  Keys.Values[csDateKeyName] := '';
  
  Index := Keys.IndexOfName(csDateKeyName);
  if Index > -1 then
  begin
    Keys.Delete(Index);
{$IFDEF DEBUG}
    CnDebugger.LogInteger(Index, 'VerEnhance VersionInfoKeys: DateTime.');
{$ENDIF}
  end;
end;

destructor TCnVerEnhanceWizard.Destroy;
begin
  if FCompileNotifierAdded then
  begin
    CnWizNotifierServices.RemoveAfterCompileNotifier(AfterCompile);
    CnWizNotifierServices.RemoveBeforeCompileNotifier(BeforeCompile);
    FCompileNotifierAdded := False;
  end;
  inherited;
end;

function TCnVerEnhanceWizard.GetHasConfig: Boolean;
begin
  Result := True;
end;

class procedure TCnVerEnhanceWizard.GetWizardInfo(var Name, Author, Email,
  Comment: string);
begin
  Name := SCnVerEnhanceWizardName;
  Author := SCnPack_Hubdog + ';' + SCnPack_LiuXiao;
  Email := SCnPack_HubdogEmail + ';' + SCnPack_LiuXiaoEmail;
  Comment := SCnVerEnhanceWizardComment;
end;


procedure TCnVerEnhanceWizard.LoadSettings(Ini: TCustomIniFile);
begin
  FLastCompiled := Ini.ReadBool('', csLastCompiled, False);
  FIncBuild := Ini.ReadBool('', csIncBuild, False);
  UpdateCompileNotify; // 改为有需要才进行通知器的增加
end;

procedure TCnVerEnhanceWizard.SaveSettings(Ini: TCustomIniFile);
begin
  Ini.WriteBool('', csLastCompiled, FLastCompiled);
  Ini.WriteBool('', csIncBuild, FIncBuild);
end;

function TCnVerEnhanceWizard.GetCompileNotifyEnabled: Boolean;
begin
  Result := FIncBuild or FLastCompiled;
end;

procedure TCnVerEnhanceWizard.SetIncBuild(const Value: Boolean);
begin
  if FIncBuild <> Value then
  begin
    FIncBuild := Value;
    UpdateCompileNotify;
  end;
end;

procedure TCnVerEnhanceWizard.SetLastCompiled(const Value: Boolean);
begin
  if FLastCompiled <> Value then
  begin
    FLastCompiled := Value;
    UpdateCompileNotify;
  end;
end;

procedure TCnVerEnhanceWizard.UpdateCompileNotify;
begin
  if CompileNotifyEnabled and not FCompileNotifierAdded then
  begin
    // 有需要并且以前没通知器就增加
    CnWizNotifierServices.AddBeforeCompileNotifier(BeforeCompile);
    CnWizNotifierServices.AddAfterCompileNotifier(AfterCompile);
    FCompileNotifierAdded := True;
  end
  else if not CompileNotifyEnabled and FCompileNotifierAdded then
  begin
    // 无需要并且以前有通知器就删除
    CnWizNotifierServices.RemoveAfterCompileNotifier(AfterCompile);
    CnWizNotifierServices.RemoveBeforeCompileNotifier(BeforeCompile);
    FCompileNotifierAdded := False;
  end;
end;

initialization
{$IFDEF COMPILER6_UP} // D5/BCB5/BCB6 由于 OTA Bug 而无效，故不注册
{$IFNDEF BCB6}
  RegisterCnWizard(TCnVerEnhanceWizard);
{$ENDIF}
{$ENDIF}

{$ENDIF CNWIZARDS_CNVERENHANCEWIZARD}
end.

 
