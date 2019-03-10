%{
    /* need this for the call to atof() below */
#include <stdio.h>
#include <math.h>
#include <stdbool.h>
#include "ostatniparser.tab.h"  // to get the token types that we return

int num_lines = 0; // ilosc linii
bool error_zlyznak = false;
bool is_number = false; // czy wczytywany token to liczba
//#define YY_DECL extern int yylex(); //force the g++ compiler to not apply "name-mangling" to the yylex identifier.
//If we don't do this, g++ generates the function's name as something like "_Z5yylexv", where no one will ever be able to find it or link to it.


void create_token()
{
    if(is_number)
    {
        yylval.token.ival = atoll(yytext);
    }
    else
    {
        if( asprintf(&yylval.token.name, "%s", yytext) == -1 )
            printf("blad w asprintf.\n");
    }
}

%}

%x COMMENT

%option noyywrap



%%
VAR         { create_token(); return VAR; }
BEGIN       { create_token(); num_lines++; return _BEGIN; } //zwiekszenie liczby linii zeby dobrze wypisywalo potem
END          { create_token(); return END; }
IF         { create_token(); return IF; }
THEN       { create_token(); return THEN; }
ELSE          { create_token(); return ELSE; }
ENDIF        { create_token(); return ENDIF; }
WHILE       { create_token(); return WHILE; }
DO          { create_token(); return DO; }
ENDWHILE         { create_token(); return ENDWHILE; }
FOR       { create_token(); return FOR; }
FROM          { create_token(); return FROM; }
TO         { create_token(); return TO; }
DOWNTO       { create_token(); return DOWNTO; }
ENDFOR          { create_token(); return ENDFOR; }
READ        { create_token(); return READ; }
WRITE       { create_token(); return WRITE; }
SKIP          { create_token(); return SKIP; }

\+         { create_token(); return ADD; }
\-       { create_token(); return SUB; }
\*          { create_token(); return MULT; }
\/        { create_token(); return DIV; }
\%       { create_token(); return MOD; }
\[          { create_token(); return L_BRACKET; }
\]         { create_token(); return R_BRACKET; }
\=       { create_token(); return EQ; }
\<\>          { create_token(); return NE; }
\<          { create_token(); return LT; }
\>         { create_token(); return GT; }
\<\=         { create_token(); return LE; }
\>\=       { create_token(); return GE; }
\:\=          { create_token(); return ASSIGN; }
\;        { create_token(); return SEM; }

[0-9]+      { is_number = true; create_token(); is_number = false; return NUM; }
[_a-z]+          { create_token(); return PIDENTIFIER; }

\{          BEGIN(COMMENT);

<COMMENT>\}  BEGIN(INITIAL);
<COMMENT>\n  { num_lines++; }
<COMMENT>\\\{ { }
<COMMENT>\\\} { }
<COMMENT>[^}]  { }


\n          { num_lines++; error_zlyznak = false; }
.           { error_zlyznak = true; }



%%
