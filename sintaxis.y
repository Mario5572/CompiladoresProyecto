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
%token <cadena> STRING "string"

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

declarations  : declarations VAR tipo var_list ";" {printf("d -> d var t var_list\n");}
              | declarations CONST tipo const_list ";" {printf("d -> d const t const_list\n");}
              |
              ;

tipo          : INT {printf("t -> INT\n");}

var_list      : ID  {printf("var_list -> ID");}
              | var_list ID {printf("var_list -> var_list ID");}
              ;

const_list    : ID "=" expresion {printf("const_list -> ID = e");}
              | const_list "," ID "=" expresion {printf("const_list -> const_list , ID = e ");}
              ;

statement_list: statement_list statement {printf("statement_list -> statement_list statement");}
              |
              ;

statement     : ID "=" expresion ";" 
                  { printf("statement -> ID = e ;\n"); }
              | "{" statement_list "}" 
                  { printf("statement -> { statement_list }\n"); }
              | IF "(" expresion ")" statement ELSE statement 
                  { printf("statement -> IF ( e ) statement ELSE statement\n"); }
              | IF "(" expresion ")" statement 
                  { printf("statement -> IF ( e ) statement\n"); }
              | WHILE "(" expresion ")" statement 
                  { printf("statement -> WHILE ( e ) statement\n"); }
              | PRINT "(" print_list ")" ";" 
                  { printf("statement -> PRINT ( print_list ) ;\n"); }
              | READ "(" read_list ")" ";" 
                  { printf("statement -> READ ( read_list ) ;\n"); }
              ;

print_list    : print_item {printf("print_list -> print_item");}
              | print_list "," print_item {printf("print_list -> print_list , print_item ");}
              ;

print_item    : expresion  {printf("print_item -> e");}
              | STRING     {printf("print_item -> STRING");}
              ;

read_list     : ID          {printf("read_list -> id");}
              | read_list "," ID  {printf("read_list -> read_list , ID");}
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