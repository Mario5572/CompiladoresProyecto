/* Sección de definiciones */
%{
    #include "lexico.h"
    #include <stdio.h>    
    #include <stdlib.h>
%}

letra [a-zA-Z]
digito [0-9]
errores [^ \n\t\ra-zA-Z_$0-9(){},;=/+*\-\?:]+ 

 /* Opcion para contabilizar lineas */

%option yylineno

/* Declaracion contexto de comentario */
%x comentario

%%

 /* Comentarios y espacios en blanco */

"//".*      { }
[\n\t\r ]+   { }

"/*"        {BEGIN(comentario);}

<comentario>"*/"    {BEGIN(INITIAL);}
<comentario>(?s:.)  {} //No termino de entender esta expresion regular
<comentario><<EOF>> {printf("Comentario sin cerrar: %d\n",yylineno);
                    return 0;
                    }

 /* Tokens */

\"([^"\n\\]|\\.)*\"      {return CADE;}
"{"         {return LLAI;}
"}"         {return LLAD;}
"="         {return ASIG;}
"+"         {return SUMA;}
"-"         {return REST;}
"*"         {return MULT;}
"/"         {return DIVI;}
"("         {return PARI;}
")"         {return PARD;}
","         {return COMA;}
";"         {return PYCO;}
"*"         {return MULT;}
"?"         {return QUES;}
":"         {return DOSP;}
"print"     {return PRIN;}
"main"      {return MAIN;}
"var"       {return VARI;}
"const"     {return CONS;}
"int"       {return INTE;}
"if"        {return IF;}
"else"      {return ELSE;}
"while"     {return WHIL;}
"read"      {return READ;}
({letra}|_|$)({letra}|{digito}|_|$)* {
    if(strlen(yytext) > 32){
        printf("Identificador demasiado largo en la linea %d\n",yylineno);
    }
}
{digito}+   {
    if(atol(yytext) > 2147483648){
        printf("Entero demasiado largo en linea %d\n",yylineno);
    }
}
\"([^"\n\\]|\\.)*   {printf("Cadena sin cerrar en linea %d\n",yylineno);}
{errores}          {printf("Error en linea %d: %s\n",yylineno, yytext);}


%%
