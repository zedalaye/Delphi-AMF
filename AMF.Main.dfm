object Form2: TForm2
  Left = 0
  Top = 0
  Caption = 'Form2'
  ClientHeight = 282
  ClientWidth = 622
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    622
    282)
  PixelsPerInch = 96
  TextHeight = 13
  object btTest: TButton
    Left = 260
    Top = 16
    Width = 102
    Height = 25
    Anchors = [akTop]
    Caption = 'Test'
    TabOrder = 0
    OnClick = btTestClick
  end
  object mDump: TMemo
    Left = 8
    Top = 56
    Width = 606
    Height = 218
    Anchors = [akLeft, akTop, akRight, akBottom]
    ScrollBars = ssVertical
    TabOrder = 1
  end
end
