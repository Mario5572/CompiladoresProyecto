%{
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    extern int yylex();
    extern int yylineno;   
    void yyerror(const char *msg); 
    void inicializar();
    #include "listaSimbolos.h"
    #include <stdbool.h>
    Lista tablaSimb;
    int contCadenas=0;
    bool insertaSimboloEnLista(Lista tablaSimb,char *nombre, Tipo tipo, int valor);
    void comprobaciones_finales();
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

%expect 1

%%
  
program   : { inicializar(); } ID "(" ")" "{" declarations statement_list "}"  {comprobaciones_finales();}
          ;

    declarations  : declarations VAR tipo var_list ";" {printf("d -> d var t var_list\n");}
                | declarations CONST tipo const_list ";" {printf("d -> d const t const_list\n");}
                |
                ;

tipo          : INT {printf("t -> INT\n");}

var_list      : ID  {printf("var_list -> ID(%s)\n",$1);
                     insertaSimboloEnLista(tablaSimb,$1,VARIABLE,0);
                     }
              | var_list ID {printf("var_list -> var_list ID(%s)\n",$2);
                             insertaSimboloEnLista(tablaSimb,$2,VARIABLE,0);}
              ;

const_list    : ID "=" expresion {printf("const_list -> ID(%s) = e\n",$1);
                                  insertaSimboloEnLista(tablaSimb,$1,CONSTANTE,0);}
              | const_list "," ID "=" expresion {printf("const_list -> const_list , ID(%s) = e\n",$3);
                                                 insertaSimboloEnLista(tablaSimb,$3,CONSTANTE,0);}
              ;

statement_list: statement_list statement {printf("statement_list -> statement_list statement\n");}
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

print_list    : print_item {printf("print_list -> print_item\n");}
              | print_list "," print_item {printf("print_list -> print_list , print_item\n");}
              ;

print_item    : expresion  {printf("print_item -> e\n");}
              | STRING     {printf("print_item -> STRING\n");}
              ;

read_list     : ID          {printf("read_list -> id");}
              | read_list "," ID  {printf("read_list -> read_list , ID\n");}
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
          | ID                     { printf("e->ID %s\n", $1); 
                                      // REG == r\d
                                      int idx = $1[1] -'0';
                                    }
          | "(" expresion ")"       { printf("e->(e)\n");  $$ = $2; }
          | "-" expresion           { printf("e->-e\n"); $$ = -$2; }
          ;

%%

void yyerror(const char *msg) {
    printf("Error en linea %d: %s\n", yylineno, msg);
}

void inicializar() {
    printf("Creo la tabla\n");
    tablaSimb = creaLS();
}

bool isNombreDeSimboloEnLista(Lista lista, char * nombre){
    return !(buscaLS(lista,nombre) == finalLS(lista));
}


bool insertaSimboloEnLista(Lista tablaSimb,char *nombre, Tipo tipo, int valor){
    if(isNombreDeSimboloEnLista(tablaSimb,nombre)){
        printf("La variable %s ya ha sido declarada anteriormente\n",nombre);
        return false;
    }
    Simbolo s;
    s.nombre = malloc(strlen(nombre)+1);
    strcpy(s.nombre, nombre);
    s.tipo = tipo;
    s.valor = 0;
    insertaLS(tablaSimb,finalLS(tablaSimb),s);
    return true;
} 
void mostrarListaSimbolos(Lista lista) {
    if (longitudLS(lista) == 0) {
        printf("La lista de símbolos está vacía.\n");
        return;
    }
    printf("Lista de símbolos:\n");

    PosicionLista pos = inicioLS(lista);
    while (pos != finalLS(tablaSimb)) {
        Simbolo s = recuperaLS(lista, pos);
        char *tipoStr;
        switch (s.tipo) {
            case VARIABLE:
                tipoStr = "VARIABLE";
                break;
            case CONSTANTE:
                tipoStr = "CONSTANTE";
                break;
            case CADENA:
                tipoStr = "CADENA";
                break;
            default:
                tipoStr = "DESCONOCIDO";
                break;
        }
        printf("Nombre: %s, Tipo: %s, Valor: %d\n", s.nombre, tipoStr, s.valor);
        pos = siguienteLS(lista, pos);
    }
}

void liberaListaSimbolos(Lista lista){

    if (lista == NULL)
        return;

    PosicionLista pos = inicioLS(lista);

    while (pos != finalLS(lista)) {
        Simbolo s = recuperaLS(lista,pos);
        free(s.nombre);
        pos = siguienteLS(lista,pos);
    }
    free(lista);
}

void comprobaciones_finales(){
    mostrarListaSimbolos(tablaSimb);
    liberaListaSimbolos(tablaSimb);
}