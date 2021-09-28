unit Threads;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.ExtCtrls;

type
  TMinhaThread = class(TThread)
  private
  public
    constructor Create;
    procedure Execute; override;
    procedure EscreverTextoNoMemo;
    procedure IncrementarProgressBar;
  end;

  TfThreads = class(TForm)
    btIniciar: TButton;
    ProgressBar: TProgressBar;
    memoLog: TMemo;
    edtNumeroThreads: TLabeledEdit;
    edtMilissegundos: TLabeledEdit;

    procedure btIniciarClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
  private
    FMinhasThreads: array of TMinhaThread;

    procedure ExecutarAoFinalizarThread(Sender: TObject);
    procedure FecharForm(Sender: TObject);
    procedure ResetarProgressBar;
    function ValidarCampos: Boolean;
    function TemThreadExecutando: Boolean;
  public
    FMilissegundos: Integer;
    FQuantThreads: Integer;
    FQuantThreadsEmExecucao: Integer;
  end;

var
  fThreads: TfThreads;

implementation

uses
  System.UITypes;

{$R *.dfm}
{ TMinhaThread }

constructor TMinhaThread.Create;
begin
  inherited Create(True);
  Self.FreeOnTerminate := True;
end;

procedure TMinhaThread.Execute;
var
  i: Integer;
  tempoDeEspera: Integer;
begin
  inherited;
  Self.Synchronize(Self.EscreverTextoNoMemo);

  for i := 0 to 100 do
  begin
    if Self.Terminated then
      Break;

    tempoDeEspera := Random(fThreads.FMilissegundos + 1);
    Sleep(tempoDeEspera);
    Self.Synchronize(Self.IncrementarProgressBar);
  end;
end;

procedure TMinhaThread.IncrementarProgressBar;
begin
  fThreads.ProgressBar.Position := fThreads.ProgressBar.Position + 1;
end;

procedure TMinhaThread.EscreverTextoNoMemo;
var
  mensagem: string;
begin
  mensagem := IntToStr(Self.ThreadID) + ' - Iniciando processamento';
  fThreads.memoLog.Lines.Add(mensagem);
end;

procedure TfThreads.btIniciarClick(Sender: TObject);

  procedure CriarThreads;
  var
    i: Integer;
  begin
    SetLength(FMinhasThreads, FQuantThreads);
    for i := 0 to Pred(FQuantThreads) do
    begin
      FMinhasThreads[i] := TMinhaThread.Create;
      FMinhasThreads[i].OnTerminate := ExecutarAoFinalizarThread;
      FMinhasThreads[i].Start;
    end;
  end;

begin
  if not ValidarCampos then
    Exit;

  FQuantThreads := StrToInt(edtNumeroThreads.Text);
  FQuantThreadsEmExecucao := FQuantThreads;
  FMilissegundos := StrToInt(edtMilissegundos.Text);

  ResetarProgressBar;
  CriarThreads;
end;

procedure TfThreads.ExecutarAoFinalizarThread(Sender: TObject);
var
  mensagem: string;
begin
  mensagem := IntToStr(TMinhaThread(Sender).ThreadID) +
    ' - Processamento finalizado';
  memoLog.Lines.Add(mensagem);

  Dec(FQuantThreadsEmExecucao);
end;

procedure TfThreads.FecharForm(Sender: TObject);
begin
  Self.Close;
end;

procedure TfThreads.FormClose(Sender: TObject; var Action: TCloseAction);
var
  i: Integer;

  procedure AguardarThreadsEFecharFormulario;
  var
    threadFechamento: TThread;
  begin
    threadFechamento := TThread.CreateAnonymousThread(
      procedure
      begin
        while TemThreadExecutando do
      end);
    threadFechamento.OnTerminate := FecharForm;
    threadFechamento.Start;
  end;

begin
  if TemThreadExecutando then
  begin
    Action := caNone;

    if MessageDlg
      ('Não foi possível fechar o formulário pois uma ou mais threads estão em execução. Deseja finalizá-la(s)?',
      mtWarning, [mbYes, mbNo], 0) = mrYes then
    begin
      for i := 0 to Pred(FQuantThreads) do
        FMinhasThreads[i].Terminate;

      AguardarThreadsEFecharFormulario;
    end;
  end;
end;

procedure TfThreads.FormShow(Sender: TObject);
begin
  edtNumeroThreads.Clear;
  edtMilissegundos.Clear;
  memoLog.Clear;
  ResetarProgressBar;

  edtNumeroThreads.SetFocus;
end;

procedure TfThreads.ResetarProgressBar;
begin
  ProgressBar.Position := 0;
  ProgressBar.Max := FQuantThreads * 101;
end;

function TfThreads.ValidarCampos: Boolean;
begin
  Result := (not string(edtNumeroThreads.Text).IsEmpty) and
    (not string(edtMilissegundos.Text).IsEmpty);

  if not Result then
    MessageDlg('Obrigatório o preenchimento dos campos.', mtWarning, [mbOK], 0);
end;

function TfThreads.TemThreadExecutando: Boolean;
begin
  Result := FQuantThreadsEmExecucao > 0;
end;

end.
