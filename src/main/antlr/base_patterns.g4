//
//  General purpose patterns used in all openEHR parser and lexer tools
//

grammar base_patterns;

//
// -------------------------- Parse Rules --------------------------
//

rm_type_id      : ALPHA_UC_ID ( '<' rm_type_id ( ',' rm_type_id )* '>' )? ;
rm_attribute_id : ALPHA_LC_ID ;
identifier   : ALPHA_UC_ID | ALPHA_LC_ID ;

archetype_ref : ARCHETYPE_HRID | ARCHETYPE_REF ;

//
// -------------------------- Lexer patterns --------------------------
//

// ---------- symbols ----------

SYM_GT : '>' ;
SYM_LT : '<' ;
SYM_LE : '<=' ;
SYM_GE : '>=' ;
SYM_NE : '/=' | '!=' ;
SYM_EQ : '=' ;

SYM_LIST_CONTINUE: '...' ;
SYM_INTERVAL_SEP: '..' ;
SYM_PLUS_OR_MINUS : '+/-' | '±' ;

// ---------- whitespace & comments ----------

WS         : [ \t\r]+    -> skip ;
LINE       : '\n'        -> skip ;     // increment line count
H_CMT_LINE : '--------' '-'*? '\n'  ;  // special type of comment for splitting template overlays
CMT_LINE   : '--' .*? '\n'  -> skip ;  // (increment line count)

// ---------- Delimited Regex matcher ------------
// allows for '/' or '^' delimiters
// logical form - REGEX: '/' ( '\\/' | ~'/' )+ '/' | '^' ( '\\^' | ~'^' )+ '^';
// The following is used to ensure REGEXes don't get mixed up with paths, which use '/' chars
// In ADL, a regexp can only exist between {}. It can optionally have an assumed value, by adding ;"value"
CONTAINED_REGEX: '{'WS* (SLASH_REGEX | CARET_REGEX) WS* (';' WS* STRING)? WS* '}';
fragment SLASH_REGEX: '/' SLASH_REGEX_CHAR+ '/';
fragment SLASH_REGEX_CHAR: ~[/\n\r] | ESCAPE_SEQ | '\\/';

fragment CARET_REGEX: '^' CARET_REGEX_CHAR+ '^';
fragment CARET_REGEX_CHAR: ~[^\n\r] | ESCAPE_SEQ | '\\^';

// ---------- ISO8601 Date/Time values ----------

ISO8601_DATE      : YEAR '-' MONTH ( '-' DAY )? | YEAR '-' MONTH '-' UNKNOWN_DT | YEAR '-' UNKNOWN_DT '-' UNKNOWN_DT ;
ISO8601_TIME      : ( HOUR ':' MINUTE ( ':' SECOND ( [,.] DIGIT+ )?)? | HOUR ':' MINUTE ':' UNKNOWN_DT | HOUR ':' UNKNOWN_DT ':' UNKNOWN_DT ) TIMEZONE? ;
ISO8601_DATE_TIME : ( YEAR '-' MONTH '-' DAY 'T' HOUR (':' MINUTE (':' SECOND ( [,.] DIGIT+ )?)?)? | YEAR '-' MONTH '-' DAY 'T' HOUR ':' MINUTE ':' UNKNOWN_DT | YEAR '-' MONTH '-' DAY 'T' HOUR ':' UNKNOWN_DT ':' UNKNOWN_DT ) TIMEZONE? ;
fragment TIMEZONE : 'Z' | [+-] HOUR ( ':' MINUTE )? ;   // hour offset, e.g. `+09:30`, or else literal `Z` indicating +0000.
fragment YEAR     : [1-9][0-9]* ;
fragment MONTH    : ( [0][0-9] | [1][0-2] ) ;    // month in year
fragment DAY      : ( [012][0-9] | [3][0-2] ) ;  // day in month
fragment HOUR     : ( [01]?[0-9] | [2][0-3] ) ;  // hour in 24 hour clock
fragment MINUTE   : [0-5][0-9] ;                 // minutes
fragment SECOND   : [0-5][0-9] ;                 // seconds
fragment UNKNOWN_DT  : '??' ;                    // any unknown date/time value, except years.

// ISO8601 DURATION PnYnMnWnDTnnHnnMnn.nnnS 
// here we allow a deviation from the standard to allow weeks to be // mixed in with the rest since this commonly occurs in medicine
// TODO: the following will incorrectly match just 'P'
ISO8601_DURATION : 'P' (DIGIT+ [yY])? (DIGIT+ [mM])? (DIGIT+ [wW])? (DIGIT+[dD])? ('T' (DIGIT+[hH])? (DIGIT+[mM])? (DIGIT+ ('.'DIGIT+)?[sS])?)? ;

// ------------------- special word symbols --------------
SYM_TRUE  : [Tt][Rr][Uu][Ee] ;
SYM_FALSE : [Ff][Aa][Ll][Ss][Ee] ;

// ---------------------- Identifiers ---------------------

ARCHETYPE_HRID      : ARCHETYPE_HRID_ROOT '.v' VERSION_ID ;
ARCHETYPE_REF       : ARCHETYPE_HRID_ROOT '.v' INTEGER ( '.' DIGIT+ )* ;
fragment ARCHETYPE_HRID_ROOT : (NAMESPACE '::')? IDENTIFIER '-' IDENTIFIER '-' IDENTIFIER '.' LABEL ;
VERSION_ID          : DIGIT+ '.' DIGIT+ '.' DIGIT+ ( ( '-rc' | '-alpha' ) ( '.' DIGIT+ )? )? ;
fragment IDENTIFIER : ALPHA_CHAR WORD_CHAR* ;

// --------------------- composed primitive types -------------------

TERM_CODE_REF : '[' NAME_CHAR+ ( '(' NAME_CHAR+ ')' )? '::' NAME_CHAR+ ']' ;  // e.g. [ICD10AM(1998)::F23]; [ISO_639-1::en]

// URIs - simple recogniser based on https://tools.ietf.org/html/rfc3986 and
// http://www.w3.org/Addressing/URL/5_URI_BNF.html
URI : URI_SCHEME ':' URI_HIER_PART ( '?' URI_QUERY )? ;
fragment URI_HIER_PART : ( '//' URI_AUTHORITY )? URI_PATH ;
fragment URI_AUTHORITY : ( URI_USER '@' )? URI_HOST ( ':' NATURAL )? ;
fragment URI_HOST : IP_LITERAL | NAMESPACE ;
fragment URI_USER : URI_RESERVED+ ;
fragment URI_SCHEME : ALPHANUM_CHAR URI_XALPHA* ;
fragment URI_PATH   : ( '/' URI_XPALPHA+ )+ ;
fragment URI_QUERY  : URI_XALPHA+ ( '+' URI_XALPHA+ )* ;

fragment IP_LITERAL   : IPV4_LITERAL | IPV6_LITERAL ;
fragment IPV4_LITERAL : NATURAL '.' NATURAL '.' NATURAL '.' NATURAL ;
fragment IPV6_LITERAL : HEX_QUAD (':' HEX_QUAD )* '::' HEX_QUAD (':' HEX_QUAD )* ;

fragment URI_XPALPHA : URI_XALPHA | '+' ;
fragment URI_XALPHA : ALPHANUM_CHAR | URI_SAFE | URI_EXTRA | URI_ESCAPE ;
fragment URI_SAFE   : [$@.&_-] ;
fragment URI_EXTRA  : [!*"'()] ;
fragment URI_ESCAPE : '%' HEX_DIGIT HEX_DIGIT ;
fragment URI_RESERVED : [=;/#?: ] ;

fragment NATURAL  : [1-9][0-9]* ;
fragment HEX_QUAD : HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT ;

// According to IETF http://tools.ietf.org/html/rfc1034[RFC 1034] and http://tools.ietf.org/html/rfc1035[RFC 1035],
// as clarified by http://tools.ietf.org/html/rfc2181[RFC 2181] (section 11)
fragment NAMESPACE : LABEL ('.' LABEL)+ ;
fragment LABEL : ALPHA_CHAR ( NAME_CHAR* ALPHANUM_CHAR )? ;

GUID : HEX_DIGIT+ '-' HEX_DIGIT+ '-' HEX_DIGIT+ '-' HEX_DIGIT+ '-' HEX_DIGIT+ ;

ALPHA_UC_ID : ALPHA_UCHAR WORD_CHAR* ;           // used for type ids
ALPHA_LC_ID : ALPHA_LCHAR WORD_CHAR* ;           // used for attribute / method ids

// --------------------- atomic primitive types -------------------

INTEGER : DIGIT+ E_SUFFIX? ;
REAL :    DIGIT+ '.' DIGIT+ E_SUFFIX? ;
fragment E_SUFFIX : [eE][+-]? DIGIT+ ;

STRING : '"' STRING_CHAR*? '"' ;
fragment STRING_CHAR : ~["\\] | ESCAPE_SEQ | UTF8CHAR ; // strings can be multi-line

CHARACTER : '\'' CHAR '\'' ;
fragment CHAR : ~['\\\r\n] | ESCAPE_SEQ | UTF8CHAR  ;

fragment ESCAPE_SEQ: '\\' ['"?abfnrtv\\] ;

// ------------------- character fragments ------------------

fragment NAME_CHAR     : WORD_CHAR | '-' ;
fragment WORD_CHAR     : ALPHANUM_CHAR | '_' ;
fragment ALPHANUM_CHAR : ALPHA_CHAR | DIGIT ;

fragment ALPHA_CHAR  : [a-zA-Z] ;
fragment ALPHA_UCHAR : [A-Z] ;
fragment ALPHA_LCHAR : [a-z] ;
fragment UTF8CHAR    : '\\u' HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT ;

fragment DIGIT     : [0-9] ;
fragment HEX_DIGIT : [0-9a-fA-F] ;
