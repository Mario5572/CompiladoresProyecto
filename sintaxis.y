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
    Simbolo insertaSimboloEnLista(Lista tablaSimb,char *nombre, Tipo tipo, int valor);
    void comprobaciones_finales();
    bool validarAsignacionDeIdentificador(Lista l, char *nombre);
    bool validarExistenciaDeIdentificador(Lista lista, char *nombre);
    void anade_operacion_lista_codigo(ListaC lc,char* op,char* reg,char* arg1,char* arg2);
    ListaC expresion_binop(ListaC l1,ListaC l2,char *op);
    ListaC expresion_unop(ListaC l1,char *op);
    ListaC statement_asig(char* iden, ListaC l1, char* op);
    ListaC cargaStringEnRegistro(int string_identifier, char* reg);
    char* obtenerReg();
    void liberarReg(char* i_str);
    const int n_registros = 9;
    bool registros_en_uso[9];
    int errores = 0;
    int strIdentifier = 0;
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

%type <codigo> expresion statement statement_list declarations const_list print_item print_list

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
  
program   : { inicializar(); } ID "(" ")" "{" declarations statement_list "}"  {concatenaLC($6,$7); comprobaciones_finales($6);}
          ;

declarations  : declarations VAR tipo var_list ";" {printf("d -> d var t var_list\n"); $$ = $1;}
            | declarations CONST tipo const_list ";" {printf("d -> d const t const_list\n");
                                                      concatenaLC($1,$4); $$ = $1;}
            | {$$ = creaLC();}
            ;

tipo          : INT {printf("t -> INT\n");}

var_list      : ID  {printf("var_list -> ID(%s)\n",$1);
                     insertaSimboloEnLista(tablaSimb,$1,VARIABLE,0);
                     }
              | var_list ID {printf("var_list -> var_list ID(%s)\n",$2);
                             insertaSimboloEnLista(tablaSimb,$2,VARIABLE,0);}
              ;

const_list    : ID "=" expresion {printf("const_list -> ID(%s) = e\n",$1);
                                  insertaSimboloEnLista(tablaSimb,$1,CONSTANTE,0);
                                  $$ = statement_asig($1,$3,"sw");}
              | const_list "," ID "=" expresion {printf("const_list -> const_list , ID(%s) = e\n",$3);
                                                 insertaSimboloEnLista(tablaSimb,$3,CONSTANTE,0);
                                                 concatenaLC($1,statement_asig($3,$5,"sw"));
                                                 $$ = $1;}
              ;

statement_list: statement_list statement {printf("statement_list -> statement_list statement\n");
                                          concatenaLC($1,$2);
                                          $$ = $1;}
              | statement {printf("statement_list -> statement\n");
                           $$ = $1;}
              ;

statement     : ID "=" expresion ";" 
                  { printf("statement -> ID = e ;\n"); 
                    validarAsignacionDeIdentificador(tablaSimb,$1);
                     $$ = statement_asig($1,$3,"sw");
                    }
              | "{" statement_list "}" 
                  { printf("statement -> { statement_list }\n"); }
              | IF "(" expresion ")" statement ELSE statement 
                  { printf("statement -> IF ( e ) statement ELSE statement\n"); }
              | IF "(" expresion ")" statement 
                  { printf("statement -> IF ( e ) statement\n"); }
              | WHILE "(" expresion ")" statement 
                  { printf("statement -> WHILE ( e ) statement\n"); }
              | PRINT "(" print_list ")" ";" 
                  { printf("statement -> PRINT ( print_list ) ;\n"); $$ = $3; } // TODO AQUI VA LA LOGICA DE IMPRIMIR Y LIBERACION DE REGISTROSSS
              | READ "(" read_list ")" ";" 
                  { printf("statement -> READ ( read_list ) ;\n"); }
              ;

print_list    : print_item {printf("print_list -> print_item\n"); $$ = $1;}
              | print_list "," print_item {printf("print_list -> print_list , print_item\n"); concatenaLC($1,$3); $$ = $1;}
              ;

print_item    : expresion  {printf("print_item -> e\n"); $$ = $1;}
              | STRING     {printf("print_item -> %s\n",$1);
                            Simbolo s = insertaSimboloEnLista(tablaSimb,$1,CADENA,strIdentifier++);
                            $$ = cargaStringEnRegistro(s.valor,obtenerReg());
                            }
              ;

read_list     : ID          {printf("read_list -> id");
                             validarExistenciaDeIdentificador(tablaSimb,$1);}
              | read_list "," ID  {printf("read_list -> read_list , ID\n");
                                   validarExistenciaDeIdentificador(tablaSimb,$3);}
              ;


expresion : expresion "+" expresion   { printf("e->e+e\n");
                                      $$ = expresion_binop($1,$3,"add"); }
          | expresion "-" expresion   { printf("e->e-e\n");
                                        $$ = expresion_binop($1,$3,"sub"); }
          | expresion "*" expresion   { printf("e->e*e\n");
                                        $$ = expresion_binop($1,$3,"mul");}
          | expresion "/" expresion   { printf("e->e/e\n"); 
                                      if ($3 == 0) {
                                        printf("División por cero\n");
                                        exit(1);
                                      }
                                      $$ = expresion_binop($1,$3,"div");
                                    }
          
          | "(" expresion "?" expresion ":" expresion ")" { $$ = creaLC();}

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
          | "(" expresion ")"       { printf("e->(e)\n"); 
                                      $$ = $2;
                                     }
          | "-" expresion           { printf("e->-e\n"); 
                                      $$ = expresion_unop($2,"neg"); }
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
ListaC expresion_binop(ListaC l1,ListaC l2,char *op){
    if(errores > 0) return NULL;
    Operacion oper;
    oper.op = op;
    oper.res = recuperaResLC(l1);
    oper.arg1 = recuperaResLC(l1);
    oper.arg2 = recuperaResLC(l2);
    concatenaLC(l1,l2);
    insertaLC(l1,finalLC(l1),oper);
    return l1;
}
ListaC expresion_unop(ListaC l1,char *op){
    if(errores > 0) return NULL;
    Operacion oper;
    oper.op = op;
    oper.res = recuperaResLC(l1);
    oper.arg1 = recuperaResLC(l1);
    oper.arg2 = NULL;
    insertaLC(l1,finalLC(l1),oper);
    return l1;
}
ListaC statement_asig(char* iden, ListaC l1, char* op){ //ESTO ESTA MAL MIRAR https://stackoverflow.com/questions/10324691/storing-addresses-in-a-register-for-mips
    if(errores > 0) return NULL;
    //CARGO EN UN REGISTRO LA DIR DE MEMORIA DE MI VARIABLE
    Operacion op1;
    op1.op = "la";
    op1.arg1 = obtenerReg();
    asprintf(&op1.arg2,"_%s",iden);
    op1.res = 0;
    insertaLC(l1,finalLC(l1),op1);
    //Una vez que tengo la direccion de mi variable en el registro op1.arg1 hago sw
    Operacion oper;
    oper.op = "sw";
    asprintf(&oper.arg1,"%s",recuperaResLC(l1)); //En el primer parametro del sw va el registro donde se encuentran los datos a cargar
    asprintf(&oper.arg2,"0(%s)",op1.arg1); //En el segundo paraemtro del sw ira algo de la forma 0($t0) donde $t0 es el registro en el que hemos
    // usado para cargar la dir de nuestra variable
    oper.res = 0;
    insertaLC(l1,finalLC(l1),oper);
    printf("lirililalila %s\n",op1.arg1);
    liberarReg(op1.arg1); //Tras esto podemos liberar el registro que hemos usado para almacenar la dir de la variable
    liberarReg(recuperaResLC(l1)); // Creo que tambien puedo liberar este registro que el que almacena el valor de la expresion
    return l1;
}
ListaC cargaStringEnRegistro(int string_identifier, char* reg){
    ListaC l1 = creaLC();
    Operacion oper;
    oper.op = "la";
    asprintf(&oper.arg1,"$str%d",string_identifier);
    guardaResLC(l1,reg);
    return l1;
}
char* obtenerReg(){
    for(int i=0;i<n_registros;i++){
        if(!registros_en_uso[i]) {
            char* buff;
            asprintf(&buff,"$t%d",i);
            registros_en_uso[i] = true;
            return buff;
        }
    }
    yyerror("No hay suficientes registros para llevar a cabo la operacion");
}
void liberarReg(char* i_str){
    printf("Voy a liberar el reg ");
    int i = i_str[2] - '0';
    if(!registros_en_uso[i]){
        printf("Se ha intentado liberar un registro no usado\n");
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

Simbolo insertaSimboloEnLista(Lista tablaSimb,char *nombre, Tipo tipo, int valor){
    if(isNombreDeSimboloEnLista(tablaSimb,nombre)){
        printf("La variable %s ya ha sido declarada anteriormente\n",nombre);
    }
    Simbolo s;
    s.nombre = malloc(strlen(nombre)+1);
    strcpy(s.nombre, nombre);
    s.tipo = tipo;
    s.valor = 0;
    insertaLS(tablaSimb,finalLS(tablaSimb),s);
    return s;
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

void imprimirTablaSimbolos(){
    if(errores > 0) return ;
    printf(".data\n");
    PosicionLista pos = inicioLS(tablaSimb);
    while(pos != finalLS(tablaSimb)){
        Simbolo s = recuperaLS(tablaSimb,pos);
        if(s.tipo != CADENA) printf("_%s : .word %d\n",s.nombre,s.valor);
        if(s.tipo == CADENA) printf("$str%d : .asciiz %s\n",s.valor,s.nombre);
        pos = siguienteLS(tablaSimb,pos);
    }
}
void imprimirLC(ListaC codigo){
    PosicionListaC p = inicioLC(codigo);
    Operacion oper;
    while (p != finalLC(codigo)) {
    oper = recuperaLC(codigo,p);
    if(!strcmp(oper.op,"etiq")){
        printf("%s:\n",oper.res);
    }else{ //TENGO QUE ARREGLAR LO DE LAS COMAS 
    printf("%s",oper.op);
    if (oper.res) printf(" %s",oper.res);
    if (oper.arg1) printf(", %s",oper.arg1);
    if (oper.arg2) printf(", %s",oper.arg2);
    printf("\n");
    }
    p = siguienteLC(codigo,p);
  }
}
void comprobaciones_finales(ListaC l){
    mostrarListaSimbolos(tablaSimb);
    printf("\n\n ----------- CODIGO MIPS --------------\n\n");
    imprimirTablaSimbolos();
    imprimirLC(l);
    liberaListaSimbolos(tablaSimb);
    
}
