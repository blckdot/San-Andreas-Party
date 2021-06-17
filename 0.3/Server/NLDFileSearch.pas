(* ----------------------------------------------------------------------------
unit NLDFileSearch
Download the latest version at http://www.nldelphi.com/Forum
Look for GolezTrol in the Open Source section
-------------------------------------------------------------------------------
Author:  Jos Visser aka GolezTrol
Date  :  january 2003
Web   :  www.goleztrol.nl
-------------------------------------------------------------------------------
This unit provides various easy ways to wrap around the FindFirst/FindNext APIs.

Three procedures are implemented to easily obtain a list of files.
-  NLDEnumFiles:
   Search a folder and report each found file to a callback procedure or
   class method.
-  NLDGetFiles:
   Search a folder and add each found file to a TStrings.

These methods use descendants of the TNLDCustomFileSearch helper class.
This customizable class does the actual searching and triggers an event for
each file that matches the search criteria. (Mask and options)
-------------------------------------------------------------------------------
Changes:    Version and description
----------  -------------------------------------------------------------------
2003-02-01  1.1.1: First release
            Changed some of the names
            Fix: Only folders matching the mask were returned. This is now
            optional
2003-01-28  1.0: Created
-------------------------------------------------------------------------------
ToDo:
- Implement 'Ex'tended FoundFile callbacks to return Search Record instead of
  FileName and Attributes only.
---------------------------------------------------------------------------- *)

unit NLDFileSearch;

interface

uses
  Classes, SysUtils;

type
  { Search Options:
    soRecursive: Searches the path recursively
    soNoDirs: Returns files only
    soDirsOnly: Returns directories only.
        This flag is ignored when soNoDirs is set.
    soExcludePath: Returns the filename only
    soRelativePaths: Returns the filename, including the relative
        path, excluding the leading path separator. This flag is ignored
        when soExcludePaths is set
    soProcessMessages: Call application.processmessages in each iteration.
  }
  TFSOption = (soRecursive, soNoDirs, soDirsOnly, soExcludePath,
      soRelativePaths, soUseMaskForDirs, soProcessMessages);
  TFSOptions = set of TFSOption;

  TFSContinue = (cCancel, cNextFile, cEnterFolder);
  TNLDFoundFileProc = procedure(const FileName: string;
      Attributes: Integer; var Continue: TFSContinue);
  TNLDFoundFileEvent = procedure(const FileName: string;
      Attributes: Integer; var Continue: TFSContinue) of object;
  // Ex is for your future entertainment
  //TFoundFileExProc = procedure(const SearchRec: TSearchRec;
  //   var Continue: Boolean);


  { TNLDCustomFileSearch:
    Helper class for file searches.
    When a file is found in the EnumFiles method the OnFoundFile event is
    called. The FoundFile method is de default event handler for this event,
    but this can be changed.
    The FoundFile method can be overridden by descendant classes to implement
    specific action when a file is found. }
  TNLDCustomFileSearch = class
  private
    FOnFoundFile: TNLDFoundFileEvent;
    FTerminated: Boolean;
  protected
    function GetTerminated: Boolean;
    procedure DoFoundFile(FileName: string; SR: TSearchRec;
        var DoContinue: TFSContinue); virtual;
    procedure SetOnFoundFile(const Value: TNLDFoundFileEvent); virtual;
    procedure FoundFileHandler(const FileName: string; Attributes: Integer;
        var Continue: TFSContinue); virtual; abstract;
    procedure EnumFiles(Path: string; Options: TFSOptions);
    property OnFoundFile: TNLDFoundFileEvent
        read FOnFoundFile write SetOnFoundFile;
  public
    constructor Create; virtual;
    procedure Terminate; virtual;
  end;

  { TNLDEnumFiles:
    Allows to set a CallBack procedure which will be called when a file is
    found. }
  TNLDEnumFiles = class(TNLDCustomFileSearch)
  private
    FFoundFileProc: TNLDFoundFileProc;
  protected
    procedure FoundFileHandler(const FileName: string; Attributes: Integer;
        var Continue: TFSContinue); override;
  public
    property OnFoundFile;
    property FoundFileProc: TNLDFoundFileProc
        read FFoundFileProc write FFoundFileProc;
  end;

  { TNLDStringsFileSearch:
    Fills a TStrings with found files. }
  TNLDStringsFileSearch = class(TNLDCustomFileSearch)
  private
    FStrings: TStrings;
  protected
    property Strings: TStrings read FStrings write FStrings;
    procedure FoundFileHandler(const FileName: string; Attributes: Integer;
        var Continue: TFSContinue); override;
  end;

{ - NLDEnumFiles:
   Search a folder and report each found file to a callback procedure or
   class method.
  - NLDGetFiles:
    Search a folder and add each found file to a TStrings.
    Path should end with a backslash, or with a mask. For instance:
    'c:\media\' looks up all files (*.*) in the c:\media folder.
    'c:\media\*.mp3' returns only the. mp3 audio files is this folder.
}
function NLDEnumFiles(Path: string; CallBack: TNLDFoundFileProc;
    Options: TFSOptions): Integer; overload;
function NLDEnumFiles(Path: string; CallBack: TNLDFoundFileEvent;
    Options: TFSOptions): Integer; overload;
procedure NLDGetFiles(Path: string; List: TStrings;
    Options: TFSOptions);

implementation

uses
  Forms, Masks;

function NLDEnumFiles(Path: string; CallBack: TNLDFoundFileProc;
    Options: TFSOptions): Integer; overload;
begin
  with TNLDEnumFiles.Create do
  try
    FoundFileProc := CallBack;
    EnumFiles(Path, Options);
  finally
    Free;
  end;
end;

function NLDEnumFiles(Path: string; CallBack: TNLDFoundFileEvent;
    Options: TFSOptions): Integer; overload;
begin
  with TNLDEnumFiles.Create do
  try
    OnFoundFile := CallBack;
    EnumFiles(Path, Options);
  finally
    Free;
  end;
end;

procedure NLDGetFiles(Path: string; List: TStrings;
    Options: TFSOptions);
begin
  List.Clear;
  with TNLDStringsFileSearch.Create do
  try
    Strings := List;
    EnumFiles(Path, Options);
  finally
    Free;
  end;
end;

{ TNLDCustomFileSearch }

constructor TNLDCustomFileSearch.Create;
begin
  OnFoundFile := FoundFileHandler;
end;

procedure TNLDCustomFileSearch.DoFoundFile(FileName: string; SR: TSearchRec;
    var DoContinue: TFSContinue);
begin
  if Assigned(OnFoundFile) then
    OnFoundFile(FileName, SR.Attr, DoContinue);
end;

procedure TNLDCustomFileSearch.EnumFiles(Path: string; Options: TFSOptions);
{ Extracts a mask from the given path and searches the path for files matching
  the mask. Triggers the OnFoundFile event for each file. }
var
  Mask: string;
  DoContinue: TFSContinue;

  procedure WalkDir(Dir: string);
  { Reads files from a given path. Dir is the relative path from Path.
    Calls the OnFoundFile events when a file is found, matching the options. }
  var
    SR: TSearchRec;
    Res: Integer;
    IsDir: Boolean;
    FileName: string;
  begin
    Res := FindFirst(Path + Dir + '*.*', faAnyFile, SR);
    try
      while (Res = 0) and not GetTerminated do
      begin
        try
          if (SR.Name = '.') or (SR.Name = '..') then
            Continue;
          IsDir := SR.Attr and faDirectory <> 0;
          if IsDir then
          begin
            if soUseMaskForDirs in Options then
              if not MatchesMask(SR.Name, Mask) then
                Continue;
            DoContinue := cEnterFolder
          end else
          begin
            if not MatchesMask(SR.Name, Mask) then
              Continue;
            DoContinue := cNextFile;
          end;

          FileName := SR.Name;
          if not (soExcludePath in Options) then
          begin
            FileName := Dir + FileName;
            if not (soRelativePaths in Options) then
              FileName := Path + FileName;
          end;
          if soProcessMessages in Options then
            Application.ProcessMessages;

          // If it is not a folder, or folders are allowed then
          if not IsDir or not (soNoDirs in Options) then
            // If it is a folder or other files are allowed then
            if IsDir or not (soDirsOnly in Options) then
              // FoundFile!
              DoFoundFile(FileName, SR, DoContinue);

          if DoContinue = cCancel then
          begin
            Terminate;
            Break;
          end;

          if IsDir and (soRecursive in Options) and
              (DoContinue = cEnterFolder) then
            WalkDir(Dir + SR.Name + '\');
        finally
          Res := FindNext(SR);
        end;
      end;
    finally
      FindClose(SR);
    end;
  end;

begin
  if soDirsOnly in Options then
    Include(Options, soUseMaskForDirs);
  Mask := ExtractFileName(Path);
  if Mask = '' then
    Mask := '*.*';
  Path := ExtractFilePath(Path);
  FTerminated := False;
  WalkDir('');
end;

function TNLDCustomFileSearch.GetTerminated: Boolean;
begin
  Result := FTerminated or Application.Terminated;
end;

procedure TNLDCustomFileSearch.SetOnFoundFile(const Value: TNLDFoundFileEvent);
begin
  FOnFoundFile := Value;
end;

procedure TNLDCustomFileSearch.Terminate;
begin
  FTerminated := True;
end;

{ TNLDEnumFiles }

procedure TNLDEnumFiles.FoundFileHandler(const FileName: string;
  Attributes: Integer; var Continue: TFSContinue);
begin
  FFoundFileProc(FileName, Attributes, Continue);
end;

{ TNLDStringsFileSearch }

procedure TNLDStringsFileSearch.FoundFileHandler(const FileName: string;
  Attributes: Integer; var Continue: TFSContinue);
begin
  FStrings.Add(FileName);
end;

end.
