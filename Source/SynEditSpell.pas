(* Delphi unit
   Spell checker for SynEdit
   =========================

   © Dr. J. Rathlev, D-24222 Schwentinental (kontakt(a)rathlev-home.de)

   The contents of this file may be used under the terms of the
   Mozilla Public License ("MPL") or
   GNU Lesser General Public License Version 2 or later (the "LGPL")

   Software distributed under this License is distributed on an "AS IS" basis,
   WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
   the specific language governing rights and limitations under the License.

   based on SynSpellCheck by Jacob Dybala
   https://sourceforge.net/projects/hunspell/files/Misc/

   and NHunspell by Thomas Maierhofer
   http://nhunspell.sourceforge.net

   Vers. 1.0 - August 2019
   Vers. 1.1 - September 2021: Fixed underlining of bad words if WordWrap is enabled
   Vers. 1.2 - June 2022: Fixed issue on compiling as 64 bit application
   Vers. 1.3 - March 2024: Added "RemoveDictWord"  to remove an entry from the
               dictionary (suggested by Dimon-II - https://github.com/Dimon-II/DeCard64)
   Vers. 1.4 - March 2026: New functions for LanguageId processing

   last modified: March 2026
   *)

unit SynEditSpell;

interface

uses Winapi.Windows, System.SysUtils, System.Classes, System.Contnrs,
  Vcl.Graphics, Vcl.Controls,
  SynEdit, SynEditHighlighter, SynEditMiscProcs, SynEditTypes, HunSpellLib;

type
  TLanguage = record
    Id : TLocaleID;
    Shortname : string;
    end;

  TLoadedDict = record
    Id : TLocaleID;
    Filename,Shortname : string;
    mAff,mDic : TMemoryStream;
    end;

  TIdArray = array of word;
  TLoadedDicts = array of TLoadedDict;

  TDictionaryProps = class(TObject)
    Id : TLocaleID;
    Shortname : string;
    constructor Create (AId : word; const sn : string);
    end;

  TUnderlineStyle = (usCorelWordPerfect, usMicrosoftWord);
  TCheckAttribute = (caText,caComment,caString,caDocumentation);
  TCheckAttributes = set of TCheckAttribute;

const
  AllAttributes = [caText,caComment,caString,caDocumentation];

type
  TSynEditSpellCheck = class;

  TDrawAutoSpellCheckPlugin = class(TSynEditPlugin)
  private
    { Procedures }
  protected
    FEditor : TSynEdit;
    FSynEditSpellCheck : TSynEditSpellCheck;
    { Procedures }
    procedure AfterPaint(ACanvas : TCanvas; const AClip: TRect; FirstLine,LastLine : Integer); override;
  public
    constructor Create(AOwner : TCustomSynEdit; ASynEditSpellCheck : TSynEditSpellCheck);
    { Properties }
    end;

  TSynSpellCheckOption = (
    sscoAutoSpellCheck,
    sscoGoUp,
    sscoHideCursor,
    sscoHourGlass,
    sscoIgnoreSingleChars,
    sscoStartFromCursor,
    sscoSuggestWords);
  TSynSpellCheckOptions = set of TSynSpellCheckOption;

  { Procedure types }
  TOnLoadDict = procedure(Sender: TObject; AId : word) of object;
  TOnAddWord = procedure(Sender: TObject; AWord: String) of object;
  TOnCheckWord = procedure(Sender: TObject; AWord: String;
    ASuggestions: TStringList; var ACorrectWord: String; var AAction: Integer;
    const AUndoEnabled: Boolean = True) of object;

  TSynEditSpellCheck = class(TComponent)
  private
    FHunspellHandle: Pointer;
    FEnabled : boolean;
    FLangId : TLocaleID;
    FBusy, FModified, FUseUserDictionary : Boolean;
    FDictPath, FUserFileName, FUserDictPath : String;
    FUnderlineColor : TColor;
    FUnderlineStyle : TUnderlineStyle;
    FUserDict : TStringList;
    FDictionaries : TStringList;
    FLoadedDicts : TLoadedDicts;
    FOnAddWord : TOnAddWord;
    FOnAbort, FOnDictSelect, FOnDictClose, FOnDone, FOnStart : TNotifyEvent;
    FOnDictLoad : TOnLoadDict;
    FOnCheckWord: TOnCheckWord;
    FCheckAttribs : TStringList;
    FOptions : TSynSpellCheckOptions;
    { Functions }
    function GetDefaultDictionaryDir : string;
    function GetUserDictionaryDir : string;
    function GetDictLanguageName : string;
    { Procedures }
    procedure UserDictChange (Sender : TObject);
    procedure SetUnderlineColor (Value: TColor);
    procedure SetUnderlineStyle (Value: TUnderlineStyle);
  public
    constructor Create (AOwner : TComponent; ACheckAttri : TCheckAttributes = AllAttributes);
    destructor Destroy; override;

//    function GetLanguageIndex (const AShortName : string) : integer;
//    function GetLanguageNameFromId (LangId : TLocaleID) : string;
    function GetDictIndex (LangId : TLocaleID) : integer;
    function GetDictionaryFiles : boolean;
    function LoadDictionaries (const APath : string; Dicts : TIdArray = nil) : boolean;
    function SelectDictionary (const LangShortname : String) : boolean; overload;
    function SelectDictionary (LangId : TLocaleID) : boolean; overload;
    procedure CloseDictionary;
    procedure SaveUserDictionary;
    function GetDictLanguages (ALangList : TStringList) : boolean;

    function CheckHighlighterAttribute (const AttributeName : string) : boolean;
    function CheckWord (const AWord : String): Boolean;
    function GetSuggestions (const AWord : String; SuggestionList: TStringList): Integer;
    procedure AddDictWord (const AWord : String);
    procedure RemoveDictWord(const AWord: String);
    function SpellCheck (AEditor : TSynEdit) : boolean;
    property UserDict : TStringList read FUserDict write FUserDict;
  published
    { Properties }
    property Busy: Boolean read FBusy default False;
    property Enabled : boolean read FEnabled;
    property LanguageName : String read GetDictLanguageName;
    property DictionaryPath: String read FDictPath;
    property AllDictionaries : TStringList read FDictionaries;
    property Modified: Boolean read FModified write FModified default False;
    property Options: TSynSpellCheckOptions read FOptions write FOptions;
    property UnderlineColor: TColor read FUnderlineColor write SetUnderlineColor default clRed;
    property UnderlineStyle: TUnderlineStyle read FUnderlineStyle
      write SetUnderlineStyle default usMicrosoftWord;
    property UserDirectory: String read GetUserDictionaryDir write FUserDictPath;
    property UseUserDictionary: Boolean read FUseUserDictionary write
      FUseUserDictionary default True;
    { Events }
    property OnAbort: TNotifyEvent read FOnAbort write FOnAbort;
    property OnAddWord: TOnAddWord read FOnAddWord write FOnAddWord;
    property OnCheckWord: TOnCheckWord read FOnCheckWord write FOnCheckWord;
    property OnDictLoad: TOnLoadDict read FOnDictLoad write FOnDictLoad;
    property OnDictSelec: TNotifyEvent read FOnDictSelect write FOnDictSelect;
    property OnDictClose: TNotifyEvent read FOnDictClose write FOnDictClose;
    property OnDone: TNotifyEvent read FOnDone write FOnDone;
    property OnStart: TNotifyEvent read FOnStart write FOnStart;
  end;

function GetLanguageShortName(LangID : TLocaleID) : string;
function GetLanguageDisplayName(LangId : TLocaleID) : string;

procedure Register;

implementation

uses System.Math, System.StrUtils, Vcl.Forms;

const
  extAff = '.aff';
  extDic = '.dic';

function GetLanguageID (const LangName : string) : TLocaleID;
var
  nc : cardinal;
begin
  Result:=0; nc:=0;
  if GetLocaleInfoEx(pchar(LangName),LOCALE_RETURN_NUMBER or LOCALE_ILANGUAGE,@nc,4)>0 then begin
    Result:=nc;
    end;
  end;

function GetLanguageName (LangId : TLocaleID; Short : boolean) : string;
var
  nc,nt : cardinal;
  buf : array of Char;
begin
  Result:=''; nc:=0;
  if Short then nt:=LOCALE_SNAME else nt:=LOCALE_SLOCALIZEDDISPLAYNAME;
  nc:=GetLocaleInfo(LangId,nt,nil,nc);
  if nc>0 then begin
    SetLength(buf,nc);
    if GetLocaleInfo(LangId,nt,@buf[0],nc)>0 then
      Result:=PChar(@buf[0]);
    buf:=nil;
    end;
  end;

function GetLanguageShortName (LangId : TLocaleID) : string;
begin
  Result:=GetLanguageName(LangId,true);
  end;

function GetLanguageDisplayName (LangId : TLocaleID) : string;
begin
  Result:=GetLanguageName(LangId,false);
  end;

procedure Register;
begin
  RegisterComponents('SynEdit',[TSynEditSpellCheck]);
  end;

{ ------------------------------------------------------------------- }
constructor TDictionaryProps.Create (AId : word; const sn : string);
begin
  inherited Create;
  Id:=AId; Shortname:=sn;
  end;

{ ------------------------------------------------------------------- }
{ TDrawAutoSpellCheckPlugin }
constructor TDrawAutoSpellCheckPlugin.Create (AOwner : TCustomSynEdit;
                                              ASynEditSpellCheck : TSynEditSpellCheck);
begin
  inherited Create(AOwner);
  FEditor:=TSynEdit(AOwner);
  FSynEditSpellCheck:=ASynEditSpellCheck;
  end;

procedure TDrawAutoSpellCheckPlugin.AfterPaint(ACanvas : TCanvas; const AClip : TRect;
  FirstLine, LastLine : Integer);
var
  lh,cx,i     : Integer;
  CurrentWord : String;
  CurrentXY   : TBufferCoord;
  tp          : TPoint;
  sToken      : UnicodeString;
  Attri       : TSynHighlighterAttributes;

  procedure PaintUnderLine;
  var
    MaxX,NewPoint,NewY : Integer;
    mus                : boolean;

    procedure DrawPoint;
    begin
      // Do not draw on gutter.
      // This happens when a word is underlined and part of it is "hidden" under
      // the gutter.
      if tp.X <= FEditor.Gutter.RealGutterWidth(FEditor.CharWidth) then Exit;
      with ACanvas do begin
        if NewY=tp.Y-1 then Pen.Color:=FEditor.Color
        else Pen.Color:=FSynEditSpellCheck.UnderlineColor;
        Pixels[tp.X, NewY]:=Pen.Color;
        end;
      end;

  const
    // Microsoft Word style
    MW_POINTS: array[0..3] of ShortInt=(0, 1, 2, 1);
    // Corel Word Perfect style
    WP_POINTS: array[0..3] of ShortInt=(2, 1, 0, -1);

  begin
    Inc(tp.Y, lh-3);
    NewPoint:=0;
    mus:=FSynEditSpellCheck.UnderlineStyle=usMicrosoftWord;
    if mus then NewY:=tp.Y+MW_POINTS[NewPoint]
    else NewY:=tp.Y+WP_POINTS[NewPoint];
    DrawPoint;
    MaxX:=tp.X+ACanvas.TextWidth(CurrentWord);
    while tp.X <= MaxX do begin
      DrawPoint;
      Inc(NewPoint);
      if mus then begin
        if NewPoint > High(MW_POINTS) then NewPoint:=0
        end
      else begin
        if NewPoint > High(WP_POINTS) then NewPoint:=0;
        end;
      DrawPoint;
      Inc(tp.X);
      if mus then NewY:=tp.Y+MW_POINTS[NewPoint]
      else NewY:=tp.Y+WP_POINTS[NewPoint];
      end;
    end;

begin
  if not Assigned(FSynEditSpellCheck) or not Assigned(FEditor) or
    not FSynEditSpellCheck.Enabled or not(sscoAutoSpellCheck in FSynEditSpellCheck.Options) then Exit;
  lh:=FEditor.LineHeight;
  ACanvas.Font.Assign(FEditor.Font);
// if WordWrap is active FirstLine and Lastline are the index of the dospülayed rows
  for i:=FEditor.RowToLine(FirstLine) to FEditor.RowToLine(LastLine) do begin
    // Paint "Bad Words"
    cx:=1;
    while cx < Length(FEditor.Lines[i-1]) do begin
      CurrentXY:=BufferCoord(cx,i);
      CurrentWord:=FEditor.GetWordAtRowCol(CurrentXY);
      if length(CurrentWord)>0 then begin
        tp:=FEditor.RowColumnToPixels(FEditor.BufferToDisplayPos(CurrentXY));
        if tp.X>ACanvas.ClipRect.Right-ACanvas.ClipRect.Left then Break;
        if Assigned(FEditor.Highlighter) then begin
          if not FEditor.GetHighlighterAttriAtRowCol(CurrentXY, sToken, Attri) then
            Attri:=FEditor.Highlighter.WhitespaceAttribute;
          if Assigned(Attri) and (FSynEditSpellCheck.FCheckAttribs.IndexOf(Attri.Name)>=0) and
            not FSynEditSpellCheck.CheckWord(CurrentWord) then PaintUnderLine;
          end
        else if not FSynEditSpellCheck.CheckWord(CurrentWord) then PaintUnderLine;
        Inc(cx, Length(CurrentWord));
        end;
      Inc(cx);
      end;
    end;
  end;

{ TSynEditSpellCheck }

const
  cpUtf8 = 65001;  // UTF-8 code page

constructor TSynEditSpellCheck.Create (AOwner : TComponent; ACheckAttri : TCheckAttributes);
begin
  inherited Create(AOwner);
  FHunspellHandle:=nil;
  FEnabled:=false; FLangId:=0;
  FUnderlineColor:=clRed;
  FUnderlineStyle:=usMicrosoftWord;
  FDictPath:='';
  FBusy:=False;
  FModified:=False;
  FDictionaries:=TStringList.Create;
  FUseUserDictionary:=True;
// User dictionary
  FUserDict:=TStringList.Create;
  with FUserDict do begin
    CaseSensitive:=true;
    Sorted:=true;
    Duplicates:=dupIgnore;
    WriteBOM:=false;
    OnChange:=UserDictChange;
    end;
  FCheckAttribs:=TStringList.Create;
// List of highlighter attributes to be checked
  with FCheckAttribs do begin
    if caText in ACheckAttri then Add('Text');
    if caComment in ACheckAttri then Add('Comment');
    if caString in ACheckAttri then Add('String');
    if caDocumentation in ACheckAttri then Add('Documentation');
    end;
  end;

destructor TSynEditSpellCheck.Destroy;
var
  i : integer;
begin
  CloseDictionary;
  if FLoadedDicts<>nil then for i:=0 to High(FLoadedDicts) do with FLoadedDicts[i] do begin
    mAff.Free; mDic.Free;
    end;
  with FDictionaries do begin
    for i:=0 to Count-1 do if assigned(Objects[i]) then begin
      try Objects[i].Free; except end;
      Objects[i]:=nil;
      end;
    Free;
    end;
  FUserDict.Free; FCheckAttribs.Free;
  inherited;
  end;

procedure TSynEditSpellCheck.SetUnderlineColor (Value : TColor);
begin
  FUnderlineColor:=Value;
  end;

procedure TSynEditSpellCheck.SetUnderlineStyle (Value : TUnderlineStyle);
begin
  FUnderlineStyle:=Value;
  end;

function TSynEditSpellCheck.GetDictIndex (LangId : TLocaleID) : integer;
begin
  for Result:=0 to High(FLoadedDicts) do
    if LangId=FLoadedDicts[Result].Id then Exit;
  Result:=-1;
  end;

// Get a list of all available dictionary files in FDictPath
function TSynEditSpellCheck.GetDictionaryFiles : boolean;
var
  SearchRec: TSearchRec;
  FindResult,n : integer;
  sn     : string;
begin
  Result:=false;
  if length(FDictPath)>0 then begin
    FindResult:=FindFirst(FDictPath+'*'+extAff,faAnyFile,SearchRec);
    while (FindResult=0) do begin
      sn:=ChangeFileExt(SearchRec.Name,'');
      FDictionaries.AddObject(sn,TDictionaryProps.Create(GetLanguageID(sn),sn));

//      n:=GetLanguageIndex(sn);
//      if (n>=0) then begin
//        with Languages[n] do
//          FDictionaries.AddObject(sn,TDictionaryProps.Create(Id,Shortname));
//        end;
      FindResult:=FindNext(SearchRec);
      end;
    FindClose(SearchRec);
    end;
  Result:=FDictionaries.Count>0;
  end;

// Load all dictionaries found in APath
function TSynEditSpellCheck.LoadDictionaries (const APath : string; Dicts : TIdArray) : boolean;
var
  i,j,dcnt : integer;
  sn : string;
  aid    : TLocaleID;
  ok     : boolean;
begin
  Result:=false;
  if DirectoryExists(APath) then begin
    FDictPath:=IncludeTrailingBackslash(APath);
    dcnt:=0; FLoadedDicts:=nil;
    if GetDictionaryFiles then begin
      with FDictionaries do for i:=0 to Count-1 do begin
        aid:=(Objects[i] as TDictionaryProps).Id;
        ok:=length(Dicts)=0;
        if not ok then for j:=0 to High(Dicts) do if (aid=Dicts[j]) then begin
          ok:=true; Break;
          end;
        if ok then begin
          SetLength(FLoadedDicts,dcnt+1);
          with FLoadedDicts[dcnt] do begin
            Id:=aid;
            Shortname:=(Objects[i] as TDictionaryProps).Shortname;
            Filename:=Strings[i];
            end;
          inc(dcnt);
          end;
        end;
      end;
    Result:=dcnt>0;
    if Result then begin  // load dictionaries
      for i:=0 to High(FLoadedDicts) do with FLoadedDicts[i] do begin
        if Assigned(FOnDictLoad) then FOnDictLoad(Self,Id);
        sn:=FDictPath+Filename;
        mAff:=TMemoryStream.Create;
        mAff.LoadFromFile(sn+extAff);
        mDic:=TMemoryStream.Create;
        mDic.LoadFromFile(sn+extDic);
        end;
      end;
    end;
  if length(FUserDictPath)=0 then FUserDictPath:=GetUserDictionaryDir;
  end;

function TSynEditSpellCheck.GetDefaultDictionaryDir : string;
begin
  Result:=GetEnvironmentVariable('APPDATA')+'\SynSpell\';
//  Result:=GetDesktopFolder(CSIDL_APPDATA)+'\SynSpell\';
  end;

function TSynEditSpellCheck.GetUserDictionaryDir : string;
begin
  if FUserDictPath<>'' then Result:=IncludeTrailingBackslash(FUserDictPath)
  else Result:=IncludeTrailingBackslash(GetDefaultDictionaryDir);
  end;

function TSynEditSpellCheck.GetDictLanguageName : string;
begin
  Result:=GetLanguageDisplayName(FLangId);
  end;

// Select the current dictionary associated to LangId
function TSynEditSpellCheck.SelectDictionary (LangId : TLocaleID) : boolean;
var
  n     : integer;
  sn,sl : string;
  fOut  : TextFile;
  FCursor: TCursor;
begin
  Result:=true;
  if LangId=0 then FEnabled:=false
  else if FLangId<>LangId then begin // change dictionary
    n:=GetDictIndex(LangId);
    if n>=0 then begin
      if sscoHourGlass in FOptions then begin
        FCursor:=Screen.Cursor;
        Screen.Cursor:=crHourGlass;
        end;
      if FHunspellHandle<>nil then begin
        CloseDictionary;
        if FUseUserDictionary then SaveUserDictionary;
        end;
      with FLoadedDicts[n] do begin
        FLangId:=Id;
        FHunspellHandle:=HunspellInit(mAff.Memory,mAff.Size,mDic.Memory,mDic.Size,'');
        FUserFileName:=Shortname+'.user.dic';
        end;
      Result:=Assigned(FHunspellHandle);
    // Load user dictionary if present
      FModified:=False;
      if FUseUserDictionary and Result then begin
        sn:=IncludeTrailingBackslash(FUserDictPath)+FUserFileName;
        FUserDict.Clear;
        if FileExists(sn) then begin
          AssignFile(fOut,sn,cpUtf8);
          Reset(fOut);
          while not Eof(fOut) do begin
            ReadLn(fOut,sl);
            sl:=Trim(sl);
            if length(sl)>0 then begin
              FUserDict.Add(sl);
              HunspellAdd(FHunspellHandle,PChar(sl));
              end;
            end;
          CloseFile(fOut);
          end;
        end;
      if sscoHourGlass in FOptions then Screen.Cursor:=FCursor;
      if Assigned(FOnDictSelect) then FOnDictSelect(Self);
      end
    else begin
      Result:=false;
      CloseDictionary;
      FlangId:=0;
      end;
    FEnabled:=Result;
    end
  else FEnabled:=true;
  end;

function TSynEditSpellCheck.SelectDictionary (const LangShortname : String) : boolean;
begin
  Result:=SelectDictionary(GetLanguageID(LangShortname));
  end;

procedure TSynEditSpellCheck.UserDictChange (Sender : TObject);
begin
  FModified:=true;
  end;

procedure TSynEditSpellCheck.CloseDictionary;
begin
  if FUseUserDictionary then SaveUserDictionary;
  if Assigned(FOnDictClose) then FOnDictClose(Self);
  if Assigned(FHunspellHandle) then HunspellFree(FHunspellHandle);
  FHunspellHandle:=nil;
  end;

// Save user dictionary
procedure TSynEditSpellCheck.SaveUserDictionary;
begin
  if FModified then begin
    if DirectoryExists(ExtractFileDir(FUserDictPath)) or
        ForceDirectories(ExtractFileDir(FUserDictPath)) then with FUserDict do if (Count>0) then
      SaveToFile(IncludeTrailingBackslash(FUserDictPath)+FUserFileName,TEncoding.UTF8);
    end;
  FModified:=False;
  end;

// Get list of available dictionaries with full qualified names
function TSynEditSpellCheck.GetDictLanguages (ALangList : TStringList) : boolean;
var
  i : integer;
  w : TLocaleID;
begin
  for i:=0 to High(FLoadedDicts) do begin
    w:=FLoadedDicts[i].Id;
    ALangList.AddObject(GetLanguageDisplayName(w),pointer(w));
    end;
  Result:=ALangList.Count>0;
  end;

// Get suggestions for misspelled word
function TSynEditSpellCheck.GetSuggestions (const AWord : String; SuggestionList : TStringList): Integer;
var
  wrds : PPChar;
begin
  Result:=0;
  if not (sscoSuggestWords in FOptions) then Exit;
  if FEnabled and Assigned(FHunspellHandle) and Assigned(SuggestionList)  then begin
    wrds:=HunspellSuggest(FHunspellHandle,PChar(AWord));
    while wrds^<>nil do begin
      SuggestionList.Add(wrds^);
      inc(wrds);    // fixes the original statement "Inc(Integer(wrds), sizeOf(Pointer));"
      end;
    Result:=SuggestionList.Count;
    end;
  end;

// Add word to Hunspell dictionary
procedure TSynEditSpellCheck.AddDictWord (const AWord : String);
var
  sw : String;
begin
  sw:=Trim(AWord);
  if FEnabled and Assigned(FHunspellHandle) and (length(sw)>0) then with FUserDict do if IndexOf(sw)<0 then begin
    Add(sw);
    HunspellAdd(FHunspellHandle,PChar(sw));
    FModified:=true;
    if Assigned(FOnAddWord) then FOnAddWord(Self,AWord);
    end;
  end;

// remove a word from dictionary
procedure TSynEditSpellCheck.RemoveDictWord (const AWord : String);
var
  sw : String;
begin
  sw:=Trim(AWord);
  if FEnabled and Assigned(FHunspellHandle) and (length(sw)>0) then with FUserDict do if IndexOf(sw)>=0 then begin
    Delete(IndexOf(sw));
    HunspellRemove(FHunspellHandle,PChar(sw));
    FModified:=true;
    end;
  end;

// Return true if the highlighter attribute points to section to be checked
function TSynEditSpellCheck.CheckHighlighterAttribute (const AttributeName : string) : boolean;
begin
  Result:=FCheckAttribs.IndexOf(AttributeName)>=0;
  end;

// Check the spelling of AWord
function TSynEditSpellCheck.CheckWord (const AWord : String): Boolean;
var
  sw : String;
begin
  sw:=Trim(AWord);
  if FEnabled and Assigned(FHunspellHandle) and (length(sw)>0) and
      not ((sscoIgnoreSingleChars in FOptions) and (Length(sw)=1)) then begin
    Result:=HunspellSpell(FHunspellHandle,PChar(sw))<>0;
    end
  else Result:=true;
  end;

// Check the whole text
function TSynEditSpellCheck.SpellCheck (AEditor : TSynEdit) : boolean;
var
  bAborted     : boolean;
  sToken,sWord : UnicodeString;
  pLastWord,
  pNextWord    : TBufferCoord;
  Attri        : TSynHighlighterAttributes;
  FCursor      : TCursor;
begin
  Result:=FEnabled;
  if Result then begin
    FBusy:=True;
    if Assigned(FOnStart) then FOnStart(Self);
    bAborted:=False;
    if sscoHourGlass in FOptions then begin
      FCursor:=Screen.Cursor;
      Screen.Cursor:=crHourGlass;
      end;
    with AEditor do begin
      if Trim(Lines.Text)='' then begin
        if sscoHourGlass in FOptions then Screen.Cursor:=FCursor;
        if Assigned(FOnDone) then FOnDone(Self);
        FBusy:=False;
        Exit;
        end;
      if not (sscoStartFromCursor in FOptions) then CaretXY:=BufferCoord(1, 1);
      if sscoHideCursor in FOptions then BeginUpdate;
      if sscoGoUp in FOptions then pNextWord:=PrevWordPosEx(CaretXY)
      else pNextWord:=NextWordPosEx(CaretXY);
      pLastWord:=pNextWord;
      while pNextWord.Char > 0 do begin
        Attri:=nil;
        // Check if the word is the last word, is cursor at end of text?
        if sscoGoUp in FOptions then begin
          if (PrevWordPosEx(CaretXY).Char=CaretX) and (Lines.Count=CaretY) then Break;
          end
        else begin
          if (NextWordPosEx(CaretXY).Char=CaretX) and (Lines.Count=CaretY) then Break;
          end;
        // Make sure we do not get any 'blank' words
        while length(Trim(GetWordAtRowCol(CaretXY)))=0 do begin
          { Just move to next word }
          if sscoGoUp in FOptions then pNextWord:=PrevWordPosEx(CaretXY)
          else pNextWord:=NextWordPosEx(CaretXY);
          CaretXY:=pNextWord;
          { If it the last word then exit loop }
          if pNextWord.Char=0 then Break;
          end;
        if pNextWord.Char=0 then Break;
        sWord:=GetWordAtRowCol(CaretXY);
        // Check if the word is in the dictionary
        if not assigned(Highlighter) then begin
          if not CheckWord(sWord) then Break;
          end
        else begin
          if not GetHighlighterAttriAtRowCol(CaretXY, sToken, Attri) then
            Attri:=Highlighter.WhitespaceAttribute;
          if Assigned(Attri) and (FCheckAttribs.IndexOf(Attri.Name)<>-1) and
            (not CheckWord(sWord)) then Break;
          end;
        // Prepare next word position
        if sscoGoUp in FOptions then pNextWord:=PrevWordPosEx(CaretXY)
        else pNextWord:=NextWordPosEx(CaretXY);
        CaretXY:=pNextWord;
      end;
      if sscoHideCursor in FOptions then EndUpdate;
      if sscoHourGlass in FOptions then Screen.Cursor:=FCursor;
    // Remove last word selection
      BlockBegin:=CaretXY;
      BlockEnd:=BlockBegin;
      end;
    if bAborted then begin
      if Assigned(FOnAbort) then FOnAbort(Self)
      end
    else if Assigned(FOnDone) then FOnDone(Self);
    FBusy:=False;
    end;
  end;

initialization
  LoadHunspellDll;
end.
