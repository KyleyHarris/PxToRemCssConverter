unit PxToRemMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm1 = class(TForm)
    Edit1: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Button1: TButton;
    Memo1: TMemo;
    Button2: TButton;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    Memo2: TMemo;
    Button3: TButton;
    Button4: TButton;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
  private
    FFiles: TStringList;
    procedure ProcessFile;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

uses
  Clipbrd;

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    FFiles.LoadFromFile(OpenDialog1.FileName);
    ProcessFile;
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  if SaveDialog1.Execute then
    Memo1.Lines.SaveToFile(SaveDialog1.FileName);
  MessageDlg('File Saved.', mtInformation, [mbOK], 0);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  Clipboard.AsText := Memo1.Lines.Text;
  ShowMessage('Copied');
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  if Clipboard.AsText <> '' then
  begin
    FFiles.Text := Clipboard.AsText;
    ProcessFile;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FFiles := TStringList.Create;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FFiles);
end;

procedure TForm1.ProcessFile;
var
  Pixels: Integer;

  function ProcessLine(aLine: string): string;
  (*
   // This code is simply going to parse each line looking for variables in the format of

   0px
   -0.0px
   0.0px

   etc. extract, and convert to rem using the conversion factor entered


  *)
  var
    iPos: Integer;
    iStart: Integer;
    aResult: string;
    pxValue: Double;
    remValue: Double;
    sRemValue: string;


    function EOL: Boolean;
    // True when the iterator pos is greater than what we careabout, Length - "px"
    begin
      Result := iPos > Length(aResult)-2;
    end;

    function GetChar(x: Integer): Char;
    // Virtual Char without errors. Treat Before start, or after end as ' ', to make processing simple.
    begin
      if (x > 1) and (x <= Length(aResult)) then
        Result := aResult[x] else
        Result := #32;
    end;


    function IsNumber: Boolean;
    // Test if the current position is part of a number, or a '.' dp if inside other numbers '0.0';
    begin
      Result := (GetChar(iPos) in ['0'..'9']) or ((GetChar(iPos) = '.')
                                                     and (GetChar(iPos-1) in ['0'..'9'])
                                                     and (GetChar(iPos+1) in ['0'..'9']) );
    end;

    function IsGap(x: Integer): Boolean;
    // basic style sheet convention, for what consititues "not a number" that could touch a number.
    // '-' is treated as such as for conversion the negative value does not need to be part of the number
    begin
      Result := GetChar(x) in [' ',',',';',':','-'];
    end;

    function isNumberStart: Boolean;
    // tells us we have found the beginning of a number.
    begin
      Result := IsNumber and IsGap(iPos -1);
    end;


    function isPx: Boolean;
    // is the current position in the data a 'px' variable that is followed by a gap char.
    // 104px; etc is a pass. 104pxy is a fail.
    begin
      Result := (LowerCase(Copy(aResult, iPos, 2)) = 'px') and IsGap(iPos+2);
    end;

  begin
    aResult := aLine;
    iPos := 1;
    iStart := 0;
    while not EOL do
    begin
      while (not EOL) and (not IsNumberStart) do
        Inc(iPos);

      //only reach this point if we found a number, or nothing.
      if not EOL then
      begin
        iStart := iPos;
        while not EOL and IsNumber do
          Inc(iPos);

        //only reach this point if we found the end of a number, or the number went to the end of data.
        if isPx then
        begin
          // only here if the data was a number and suffixed with a px terminator.
          pxValue := StrToFloat(Copy(aResult, iStart, iPos-iStart));

          // extract, convert and replace px with rem using the converter value
          Delete(aResult, iStart, iPos-iStart+2);
          remValue := pxValue/Pixels;
          sRemValue := Trim(Format('%10.6grem',[remValue]));
          Insert(sRemValue, aResult, iStart);
          iPos := iStart + Length(sRemValue);

          //add to the visual log the things we converted that are distinct.
          sConversion := format('%10.6gpx = %10.6grem',[pxValue,remValue]);
          if Memo2.Lines.IndexOf(sConversion) = -1 then
            Memo2.Lines.Add(sConversion);
        end;

      end;
      
    end;
    Result := aResult;
  end;

var
  i: Integer;
  Line: string;
  NewFile: TStrings;
begin
  Pixels := StrToInt(Edit1.Text);

  Memo2.Lines.Clear;
  NewFile := Memo1.Lines;
  NewFile.BeginUpdate;
  try
    NewFile.Clear;
    for i := 0 to FFiles.Count -1 do
    begin
      NewFile.Add(ProcessLine(FFiles[i]));
    end;

  finally
    NewFile.EndUpdate;
  end;
end;

end.
