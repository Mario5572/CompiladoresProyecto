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
    #include "listaCodigo.h"
    Lista tablaSimb;
    int contCadenas=0;
    bool insertaSimboloEnLista(Lista tablaSimb,char *nombre, Tipo tipo, int valor);
    void comprobaciones_finales();
    bool validarAsignacionDeIdentificador(Lista l, char *nombre);
    bool validarExistenciaDeIdentificador(Lista lista, char *nombre);
    void anade_operacion_lista_codigo(ListaC lc,char* op,char* reg,char* arg1,char* arg2);
    char* obtenerReg();
    void liberarReg(char* i_str);
    const int n_registros = 9;
    bool registros_en_uso[9];
%}
%code requires {
  #include "listaCodigo.h"
}

// Definición de tipos de datos de símbolos de la gramática
%union {
    char *cadena;
    ListaC codigo;
    int entero;
}

%token SUMA "+"
%token REST "-"
%token MULT "*"
%token DIVI "/"
%token <cadena> NUM "number"
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

%type <codigo> expresion

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
                  { printf("statement -> ID = e ;\n"); 
                    validarAsignacionDeIdentificador(tablaSimb,$1);}
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

read_list     : ID          {printf("read_list -> id");
                             validarExistenciaDeIdentificador(tablaSimb,$1);}
              | read_list "," ID  {printf("read_list -> read_list , ID\n");
                                   validarExistenciaDeIdentificador(tablaSimb,$3);}
              ;


expresion : expresion "+" expresion   { printf("e->e+e\n"); }
          | expresion "-" expresion   { printf("e->e-e\n"); }
          | expresion "*" expresion   { printf("e->e*e\n");}
          | expresion "/" expresion   { printf("e->e/e\n"); 
                                      if ($3 == 0) {
                                        printf("División por cero\n");
                                        exit(1);
                                      }
                                    }
          | NUM                     { printf("e->NUM %s\n", $1);
                                     $$ = creaLC();
                                     char* reg = obtenerReg();
                                     anade_operacion_lista_codigo($$,"li",reg,$1,NULL);
                                     guardaResLC($$,reg);}
          | ID                     { printf("e->ID %s\n", $1); 
                                      validarExistenciaDeIdentificador(tablaSimb,$1);
                                      $$ = creaLC();
                                      char* reg = obtenerReg();
                                      char *iden;
                                      asprintf(&iden,"_%s",$1);
                                      anade_operacion_lista_codigo($$,"lw",reg,iden,NULL);
                                      guardaResLC($$,reg);
                                    }
          | "(" expresion ")"       { printf("e->(e)\n");  }
          | "-" expresion           { printf("e->-e\n");  }
          ;

%%

void yyerror(const char *msg) {
    printf("Error en linea %d: %s\n", yylineno, msg);
}

void inicializar() {
    printf("Creo la tabla\n");
    tablaSimb = creaLS();
    for(int i=0;i<n_registros;i++){
        registros_en_uso[i] = false;
    }
}

void anade_operacion_lista_codigo(ListaC lc,char* op,char* reg,char* arg1,char* arg2){
    Operacion oper;
    oper.op = op;
    oper.res = reg;
    oper.arg1 = arg1;
    oper.arg2 = arg2;
    insertaLC(lc, finalLC(lc),oper);
}
char* obtenerReg(){
    for(int i=0;i<n_registros;i++){
        if(!registros_en_uso[i]) {
            char* buff;
            asprintf(&buff,"$t%d",i);
            return buff;
        }
    }
    yyerror("No hay suficientes registros para llevar a cabo la operacion");
}
void liberarReg(char* i_str){
    int i = i_str[2] - '0';
    if(!registros_en_uso[i]){
        printf("Se ha intentado liberar un registro no usado");
        return;
    }
    registros_en_uso[i] = false;
}

bool isNombreDeSimboloEnLista(Lista lista, char * nombre){
    return !(buscaLS(lista,nombre) == finalLS(lista));
}
bool validarAsignacionDeIdentificador(Lista lista, char *nombre){
    PosicionLista p = buscaLS(lista,nombre);
    if(p == finalLS(lista)){
        printf("ERROR: La variable %s ha sido asignada sin ser declarada\n",nombre);
        return false;
    }
    if(recuperaLS(lista,p).tipo == CONSTANTE){
        printf("ERROR: La variable %s es constante y ha sido reasignada\n",nombre);
        return false;
    }
    return true;
}
bool validarExistenciaDeIdentificador(Lista lista, char *nombre){
    PosicionLista p = buscaLS(lista,nombre);
    if(p == finalLS(lista)){
        printf("ERROR: La variable %s ha intentado ser leida sin ser declarada\n",nombre);
        return false;
    }
    return true;
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
