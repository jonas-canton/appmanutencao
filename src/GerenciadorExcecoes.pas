unit GerenciadorExcecoes;

interface

uses
  SysUtils, Forms, System.Classes;

type
  TGerenciadorExcecoes = class
  private
    FCaminhoArquivoLog: String;
  public
    constructor Create;
    procedure ManipularExcecao(Sender: TObject; E: Exception);
    procedure SalvarLog(const AMensagem: string);
  end;

var
  MeuGerenciadorExcecoes: TGerenciadorExcecoes;

implementation

uses
  Dialogs, System.UITypes;

{ TExceptionHandler }

constructor TGerenciadorExcecoes.Create;
begin
  FCaminhoArquivoLog := ChangeFileExt(ParamStr(0), '.log');
  Application.OnException := ManipularExcecao;
end;

procedure TGerenciadorExcecoes.ManipularExcecao(Sender: TObject; E: Exception);
begin
  SalvarLog(E.ClassName + ': ' + E.Message);
  MessageDlg(E.Message, mtError, [mbOK], 0);
end;

procedure TGerenciadorExcecoes.SalvarLog(const AMensagem: string);
var
  arquivoLog: TextFile;
  dataHora: string;
begin
  AssignFile(arquivoLog, FCaminhoArquivoLog);

  if FileExists(FCaminhoArquivoLog) then
    Append(arquivoLog)
  else
    Rewrite(arquivoLog);

  dataHora := FormatDateTime('dd/mm/YY hh:nn:ss', Now);

  Writeln(arquivoLog, dataHora + ' - ' + AMensagem);

  CloseFile(arquivoLog);
end;

initialization

MeuGerenciadorExcecoes := TGerenciadorExcecoes.Create;

finalization

MeuGerenciadorExcecoes.Free;

end.
