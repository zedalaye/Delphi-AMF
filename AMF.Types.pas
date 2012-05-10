unit AMF.Types;

interface

type
  TAMF0 = class
  public const
    { AMF0 Type Markers }
    NUMBER_MARKER       = $00;
    BOOLEAN_MARKER      = $01;
    STRING_MARKER       = $02;
    OBJECT_MARKER       = $03;
    MOVIE_CLIP_MARKER   = $04;
    NULL_MARKER         = $05;
    UNDEFINED_MARKER    = $06;
    REFERENCE_MARKER    = $07;
    HASH_MARKER         = $08;
    OBJECT_END_MARKER   = $09;
    STRICT_ARRAY_MARKER = $0A;
    DATE_MARKER         = $0B;
    LONG_STRING_MARKER  = $0C;
    UNSUPPORTED_MARKER  = $0D;
    RECORDSET_MARKER    = $0E;
    XML_MARKER          = $0F;
    TYPED_OBJECT_MARKER = $10;
    AMF3_MARKER         = $11;
  end;

  TAMF3 = class
  public const
    { AMF3 Type Markers }
    UNDEFINED_MARKER  = $00;
    NULL_MARKER       = $01;
    FALSE_MARKER      = $02;
    TRUE_MARKER       = $03;
    INTEGER_MARKER    = $04;
    DOUBLE_MARKER     = $05;
    STRING_MARKER     = $06;
    XML_DOC_MARKER    = $07;
    DATE_MARKER       = $08;
    ARRAY_MARKER      = $09;
    OBJECT_MARKER     = $0A;
    XML_MARKER        = $0B;
    BYTE_ARRAY_MARKER = $0C;
    DICT_MARKER       = $11;

    { Other AMF3 Markers }
    EMPTY_STRING         = $01;
    CLOSE_DYNAMIC_OBJECT = $01;
    CLOSE_DYNAMIC_ARRAY  = $01;

    { Other Constants }
    MAX_INTEGER = 268435455;
    MIN_INTEGER = -268435456;
  end;

implementation

end.
