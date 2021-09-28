unit ClienteServidor;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls, Vcl.StdCtrls, Datasnap.DBClient, Data.DB;

type
  TServidor = class
  private
    FPath: string;
    FArquivosSalvos: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    // Tipo do parâmetro não pode ser alterado
    function SalvarArquivos(AData: OleVariant): Boolean;
    function RemoverArquivos: Boolean;
  end;

  TfClienteServidor = class(TForm)
    ProgressBar: TProgressBar;
    btEnviarSemErros: TButton;
    btEnviarComErros: TButton;
    btEnviarParalelo: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btEnviarSemErrosClick(Sender: TObject);
    procedure btEnviarComErrosClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ResetarProgressBar;
    procedure IncrementarProgressBar;
    procedure btEnviarParaleloClick(Sender: TObject);
  private
    FPath: string;
    FServidor: TServidor;

    function InitDataset: TClientDataset;
  public
  end;

var
  fClienteServidor: TfClienteServidor;

const
  QTD_ARQUIVOS_ENVIAR = 100;
  QTD_ARQUIVOS_PARALELO = 50;

implementation

uses
  IOUtils, System.Threading, System.UITypes, System.Math;

{$R *.dfm}

procedure TfClienteServidor.btEnviarComErrosClick(Sender: TObject);
var
  cds: TClientDataset;
  i: Integer;
begin
  cds := InitDataset;
  try
    try
      for i := 1 to QTD_ARQUIVOS_ENVIAR do
      begin
        cds.Append;
        cds.FieldByName('Id').AsInteger := i;
        cds.FieldByName('Arquivo').AsString := FPath;
        cds.Post;

        {$REGION Simulação de erro, não alterar}
        if i = (QTD_ARQUIVOS_ENVIAR / 2) then
          FServidor.SalvarArquivos(NULL);
        {$ENDREGION}

        IncrementarProgressBar;
      end;

      FServidor.SalvarArquivos(cds.Data);
    except
      MessageDlg('Erro no envio. Os arquivos salvos serão apagados.', mtError,
        [mbOK], 0);
      FServidor.RemoverArquivos;
    end;
  finally
    cds.Free;
    ResetarProgressBar;
  end;
end;

procedure TfClienteServidor.btEnviarParaleloClick(Sender: TObject);
var
  i, ultimo, faltantes, idxTask: Integer;
  tasks: array of ITask;

  function EnviarArquivos(AInicio, AFim: Integer): TProc;
  begin
    Result :=
      procedure
      var
        i: Integer;
        cds: TClientDataset;
      begin
        cds := InitDataset;
        for i := AInicio to AFim do
        begin
          cds.Append;
          cds.FieldByName('Id').AsInteger := i;
          cds.FieldByName('Arquivo').AsString := FPath;
          cds.Post;

          TThread.Synchronize(TThread.CurrentThread,
          procedure
          begin
            IncrementarProgressBar;
          end);
        end;
        FServidor.SalvarArquivos(cds.Data);
        cds.Free;
      end;
  end;
begin
  SetLength(tasks, Ceil(QTD_ARQUIVOS_ENVIAR / QTD_ARQUIVOS_PARALELO));
  idxTask := 0;
  ultimo := 0;

  for i := 1 to QTD_ARQUIVOS_ENVIAR do
    if i mod QTD_ARQUIVOS_PARALELO = 0 then
    begin
      tasks[idxTask] := TTask.Create(EnviarArquivos(i - Pred(QTD_ARQUIVOS_PARALELO), i));
      tasks[idxTask].Start;
      Inc(idxTask);
      ultimo := i;
    end;

  if QTD_ARQUIVOS_ENVIAR > ultimo then
  begin
    faltantes := QTD_ARQUIVOS_ENVIAR - ultimo;
    tasks[idxTask] := TTask.Create(EnviarArquivos(ultimo + 1, ultimo + faltantes));
    tasks[idxTask].Start;
  end;
end;

procedure TfClienteServidor.btEnviarSemErrosClick(Sender: TObject);
var
  cds: TClientDataset;
  i: Integer;
begin
  cds := InitDataset;
  try
    for i := 1 to QTD_ARQUIVOS_ENVIAR do
    begin
      cds.Append;
      cds.FieldByName('Id').AsInteger := i;
      cds.FieldByName('Arquivo').AsString := FPath;
      cds.Post;

      IncrementarProgressBar;
    end;

    if FServidor.SalvarArquivos(cds.Data) then
      MessageDlg('Arquivos enviados com sucesso.', mtInformation, [mbOK], 0)
    else
      MessageDlg('Ocorreu um erro no envio dos arquivos.', mtError, [mbOK], 0);
  finally
    cds.Free;
    ResetarProgressBar;
  end;
end;

procedure TfClienteServidor.FormClose(Sender: TObject;
var Action: TCloseAction);
begin
  if Assigned(FServidor) then
    FreeAndNil(FServidor);
end;

procedure TfClienteServidor.FormCreate(Sender: TObject);
begin
  inherited;
  FPath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'pdf.pdf';
  FServidor := TServidor.Create;
  ProgressBar.Max := QTD_ARQUIVOS_ENVIAR;
end;

procedure TfClienteServidor.IncrementarProgressBar;
begin
  ProgressBar.Position := ProgressBar.Position + 1;
end;

function TfClienteServidor.InitDataset: TClientDataset;
begin
  Result := TClientDataset.Create(nil);
  Result.FieldDefs.Add('Id', ftInteger);
  Result.FieldDefs.Add('Arquivo', ftBlob);
  Result.CreateDataSet;
end;

procedure TfClienteServidor.ResetarProgressBar;
begin
  ProgressBar.Position := 0;
end;

{ TServidor }

constructor TServidor.Create;
begin
  FArquivosSalvos := TStringList.Create;
  FPath := ExtractFilePath(ParamStr(0)) + 'Servidor\';

  if not DirectoryExists(FPath) then
    CreateDir(FPath);
end;

destructor TServidor.Destroy;
begin
  FArquivosSalvos.Free;
  inherited;
end;

function TServidor.RemoverArquivos: Boolean;
var
  arquivo: string;
begin
  try
    for arquivo in FArquivosSalvos do
      TFile.Delete(arquivo);

    Result := True;
  except
    raise;
  end;
end;

function TServidor.SalvarArquivos(AData: OleVariant): Boolean;
var
  cds: TClientDataset;
  FileName: string;
begin
  cds := TClientDataset.Create(nil);

  try
    try
      cds.Data := AData;

      {$REGION Simulação de erro, não alterar}
      if cds.RecordCount = 0 then
        Exit(False);
      {$ENDREGION}
      cds.First;

      while not cds.Eof do
      begin
        FileName := FPath + cds.FieldByName('Id').AsString + '.pdf';
        if TFile.Exists(FileName) then
          TFile.Delete(FileName);

        //CopyFile(PChar(cds.FieldByName('Arquivo').AsString), PChar(FileName), False);
        TFile.Copy(cds.FieldByName('Arquivo').AsString, FileName);
        FArquivosSalvos.Add(FileName);

        cds.Next;
      end;

      Result := True;
    except
      raise;
    end;
  finally
    cds.Free;
  end;
end;

end.
