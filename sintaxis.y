%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    extern int yylex();
    extern int yylineno;   
    void yyerror(const char *msg); 
    void inicializar();
    int regs[10];
%}

// Definición de tipos de datos de símbolos de la gramática
%union {
    int entero;
    char *cadena;
}

%token SUMA "+"
%token REST "-"
%token MULT "*"
%token DIVI "/"
%token <entero> NUM "number"
%token PARI "("
%token PARD ")"
%token PYCO ";"
%token <cadena> REG "register"
%token ASIG "="
%token <cadena> ID "identifier"

%token LLAI "{"
%token LLAD "}"
%token COMA ","
%token QUES "?"
%token DOSP ":"
%token PRINT "print"
%token MAIN "main"
%token VAR "var"
%token CONST "const"
%token INT "int"
%token IF "if"
%token ELSE "else"
%token WHILE "while"
%token READ "read"

%type <entero> expresion

%define parse.error verbose

// Precedencia y asociatividad
// Asociatividad izquierda %left MAS
// Asociatividad izquierda %right MAS
// No tiene asociatividad %nonassoc MAS
// Los operadores cuya asociatividad se define primero tienen menos precedencia
%left "+" "-" 
%left "*" "/"

%%
  
program   : { inicializar(); } ID "(" ")" "{" declarations statement_list "}"
          ;

declarations  : declarations VAR tipo var_list ";" 
              | declarations CONST tipo const_list ";" 
              ;

tipo          : INT

var_list      : ID
              | var_list ID

const_list    : ID "=" expresion ";" 

statement_list: statement_list statement
              | 

statement     : ID "=" expresion ";"
              | "{" statement_list "}" ";"
              | IF "(" expresion ")" statement ";" ELSE statement ";"
              | IF "(" expresion ")" statement ";"
              | WHILE "(" expresion ")" statement ";"
              | PRINT "(" print_list ")" ";"
              | READ "(" read_list ")" ";"

print_list:   |

read_list:    |

asignacion: REG "=" expresion ";"  { printf("%s=%d\n", $1, $3); 
                                     int idx = $1[1] -'0';
                                     regs[idx] = $3;
                                    }
          ;

expresion : expresion "+" expresion   { printf("e->e+e\n"); $$ = $1+$3; }
          | expresion "-" expresion   { printf("e->e-e\n"); $$ = $1-$3; }
          | expresion "*" expresion   { printf("e->e*e\n"); $$ = $1*$3;}
          | expresion "/" expresion   { printf("e->e/e\n"); 
                                      if ($3 == 0) {
                                        printf("División por cero\n");
                                        exit(1);
                                      }
                                      $$ = $1/$3;
                                    }
          | NUM                     { printf("e->NUM %d\n", $1); $$ = $1;}
          | REG                     { printf("e->REG %s\n", $1); 
                                      // REG == r\d
                                      int idx = $1[1] -'0';
                                      $$ = regs[idx];
                                    }
          | "(" expresion ")"       { printf("e->(e)\n");  $$ = $2; }
          | "-" expresion           { printf("e->-e\n"); $$ = -$2; }
          ;

%%

void yyerror(const char *msg) {
    printf("Error en linea %d: %s\n", yylineno, msg);
}

void inicializar() {
    memset(regs, 0, sizeof(int)*10);
}