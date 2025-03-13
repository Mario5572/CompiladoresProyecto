/* Sección de definiciones */
%{
    #include "sintaxis.tab.h"
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
"?"         {return QUES;}
":"         {return DOSP;}
"print"     {return PRINT;}
"main"      {return MAIN;}
"var"       {return VAR;}
"const"     {return CONST;}
"int"       {return INT;}
"if"        {return IF;}
"else"      {return ELSE;}
"while"     {return WHILE;}
"read"      {return READ;}
\"([^"\n\\]|\\.)*\"      {return STRING;}
({letra}|_)({letra}|{digito}|_)* {
    if(strlen(yytext) > 32){
        printf("Identificador demasiado largo en la linea %d\n",yylineno);
    }
    yylval.cadena = strdup(yytext);
    return ID;
}
{digito}+   {
    if(atol(yytext) > 2147483648){
        printf("Entero demasiado largo en linea %d\n",yylineno);
    }
    yylval.entero = atoi(yytext);
    return NUM;
}
\"([^"\n\\]|\\.)*   {printf("Cadena sin cerrar en linea %d\n",yylineno);}

{errores}          {printf("Error en linea %d: %s\n",yylineno, yytext);}


%%
