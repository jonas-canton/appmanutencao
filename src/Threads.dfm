object fThreads: TfThreads
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  Caption = 'Threads'
  ClientHeight = 398
  ClientWidth = 282
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object btIniciar: TButton
    Left = 8
    Top = 91
    Width = 266
    Height = 25
    Caption = 'Iniciar'
    TabOrder = 2
    OnClick = btIniciarClick
  end
  object ProgressBar: TProgressBar
    Left = 8
    Top = 375
    Width = 266
    Height = 17
    TabOrder = 4
  end
  object memoLog: TMemo
    Left = 8
    Top = 122
    Width = 266
    Height = 247
    ReadOnly = True
    TabOrder = 3
  end
  object edtNumeroThreads: TLabeledEdit
    Left = 8
    Top = 24
    Width = 266
    Height = 21
    EditLabel.Width = 98
    EditLabel.Height = 13
    EditLabel.Caption = 'N'#250'mero de Threads:'
    NumbersOnly = True
    TabOrder = 0
  end
  object edtMilissegundos: TLabeledEdit
    Left = 8
    Top = 64
    Width = 266
    Height = 21
    EditLabel.Width = 265
    EditLabel.Height = 13
    EditLabel.Caption = 'Tempo m'#225'ximo entre cada itera'#231#227'o (em milissegundos):'
    NumbersOnly = True
    TabOrder = 1
  end
end
