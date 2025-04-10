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
    bool validarNoConstanteIdentificador(Lista l, char *nombre);
    bool validarExistenciaDeIdentificador(Lista lista, char *nombre);
    void anade_operacion_lista_codigo(ListaC lc,char* op,char* reg,char* arg1,char* arg2);
    ListaC expresion_binop(ListaC l1,ListaC l2,char *op);
    ListaC expresion_unop(ListaC l1,char *op);
    ListaC statement_asig(char* iden, ListaC l1, char* op);
    ListaC cargaStringEnRegistro(int string_identifier, char* reg);
    char * cargaDireccionDeIdentificadorAUnRegistro(ListaC l1,char * ident);
    void imprimirRegistro(ListaC l1, char* reg);
    void imprimirFromMemoria(ListaC l1, char* ident);
    void leerIdentificador(ListaC l1,char* iden);
    void statementIf(ListaC l,ListaC expresion,ListaC statement);
    char* obtenerReg();
    char* obtenerEtiq();
    void liberarReg(char* i_str);
    const int n_registros = 9;
    int contador_etiq = 1;
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

%type <codigo> expresion statement statement_list declarations const_list print_item print_list read_list

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
  
program   : { inicializar(); } ID "(" ")" "{" declarations statement_list "}"  {if (errores == 0) concatenaLC($6,$7); comprobaciones_finales($6);}
          ;

declarations  : declarations VAR tipo var_list ";" {printf("d -> d var t var_list\n"); $$ = $1;}
            | declarations CONST tipo const_list ";" {printf("d -> d const t const_list\n");
                                                      if (errores == 0) concatenaLC($1,$4); $$ = $1;}
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
                                                 if (errores == 0) concatenaLC($1,statement_asig($3,$5,"sw"));
                                                 $$ = $1;}
              ;

statement_list: statement_list statement {printf("statement_list -> statement_list statement\n");
                                          if (errores == 0) concatenaLC($1,$2);
                                          $$ = $1;}
              | {$$ = creaLC();}
              ;

statement     : ID "=" expresion ";" 
                  { printf("statement -> ID = e ;\n"); 
                    validarNoConstanteIdentificador(tablaSimb,$1);
                     $$ = statement_asig($1,$3,"sw");
                    }
              | "{" statement_list "}" { printf("statement -> { statement_list }\n"); 
                                         $$ = $2; }
              | IF "(" expresion ")" statement ELSE statement 
                  { printf("statement -> IF ( e ) statement ELSE statement\n"); 
                    $$ = creaLC();
                    //statementIfElse($$,$3,$5,$7);
                  }
              | IF "(" expresion ")" statement 
                  { printf("statement -> IF ( e ) statement\n");
                    $$ = creaLC();
                    statementIf($$,$3,$5); }
              | WHILE "(" expresion ")" statement 
                  { printf("statement -> WHILE ( e ) statement\n"); }
              | PRINT "(" print_list ")" ";" 
                  { printf("statement -> PRINT ( print_list ) ;\n"); $$ = $3; } // TODO AQUI VA LA LOGICA DE IMPRIMIR Y LIBERACION DE REGISTROSSS
              | READ "(" read_list ")" ";" 
                  { printf("statement -> READ ( read_list ) ;\n"); $$ = $3; }
              ;

print_list    : print_item {printf("print_list -> print_item\n"); $$ = $1;}
              | print_list "," print_item {printf("print_list -> print_list , print_item\n"); if (errores == 0) concatenaLC($1,$3); $$ = $1;}
              ;

print_item    : expresion  {printf("print_item -> e\n"); imprimirRegistro($1,recuperaResLC($1));
                                                                          liberarReg(recuperaResLC($1));
                                                                          $$ = $1;}
              | STRING     {printf("print_item -> %s\n",$1);
                            Simbolo s = insertaSimboloEnLista(tablaSimb,$1,CADENA,strIdentifier++);
                            $$ = creaLC();
                            char* ident;
                            asprintf(&ident,"$str%d",s.valor);
                            imprimirFromMemoria($$,ident);
                            }

              ;

read_list     : ID          {printf("read_list -> id");
                             validarNoConstanteIdentificador(tablaSimb,$1);
                             $$ = creaLC();
                             leerIdentificador($$,$1);
                             }
              | read_list "," ID  {printf("read_list -> read_list , ID\n");
                                   validarNoConstanteIdentificador(tablaSimb,$3);
                                   $$ = $1;
                                   leerIdentificador($$,$3);
                                   }
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
    liberarReg(oper.arg2); // Puedo liberar el registro de la expresion 2
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
ListaC statement_asig(char* iden, ListaC l1, char* op){
    if(errores > 0) return NULL;
    Operacion oper;
    oper.op = "sw";
    asprintf(&oper.arg1,"%s",recuperaResLC(l1)); //En el primer parametro del sw va el registro donde se encuentran los datos a cargar
    asprintf(&oper.arg2,"_%s",iden); //En el segundo paraemtro del sw ira el _identificador 
    // usado para cargar la dir de nuestra variable
    oper.res = 0;
    insertaLC(l1,finalLC(l1),oper);
    liberarReg(recuperaResLC(l1)); // Creo que tambien puedo liberar este registro que el que almacena el valor de la expresion
    return l1;
}
char * cargaDireccionDeIdentificadorAUnRegistro(ListaC l1,char * ident){
    /*Busca un registro para cargar la direccion de memoria de un identificador, lo concatena a la lista de codigo y devuelve el registro */
    // Esta funcion es innecesaria puesto que existe la pseudo instruccion sw $t0, _hola que ya carga automaticamente la direccion de memoria de _hola
    Operacion cargarMem;
    cargarMem.op = "la";
    char* registro = obtenerReg();
    cargarMem.arg1 = registro;
    asprintf(&cargarMem.arg2,"_%s",ident);
    cargarMem.res = 0;
    insertaLC(l1,finalLC(l1),cargarMem);
    return registro;
}
ListaC cargaStringEnRegistro(int string_identifier, char* reg){
    ListaC l1 = creaLC();
    Operacion oper;
    oper.op = "la";
    asprintf(&oper.arg1,"$str%d",string_identifier);
    guardaResLC(l1,reg);
    return l1;
}
void imprimirFromMemoria(ListaC l1, char* ident){

    //Movemos el valor de memoria a $a0
    Operacion op1;
    op1.op = "lw";
    op1.res = "$a0";
    asprintf(&op1.arg1,"%s",ident);
    op1.arg2 = 0;
    insertaLC(l1,finalLC(l1),op1);
    //Movemos el valor 4 al registro $v0
    Operacion op2;
    op2.op = "li";
    op2.res = "$v0";
    op2.arg1 = "4";
    op2.arg2 = 0;
    insertaLC(l1,finalLC(l1),op2);
    //Finalmente hacemos un syscall
    Operacion op3;
    op3.op = "syscall";
    op3.arg1 = op3.arg2 = op3.res = 0;
    insertaLC(l1,finalLC(l1),op3);
}
void imprimirRegistro(ListaC l1, char* reg){

    //Movemos el valor del registro a $a0
    Operacion op1;
    op1.op = "move";
    op1.res = "$a0";
    asprintf(&op1.arg1,"%s",reg);
    op1.arg2 = 0;
    insertaLC(l1,finalLC(l1),op1);
    //Movemos el valor 4 al registro $v0
    Operacion op2;
    op2.op = "li";
    op2.res = "$v0";
    op2.arg1 = "1";
    op2.arg2 = 0;
    insertaLC(l1,finalLC(l1),op2);
    //Finalmente hacemos un syscall
    Operacion op3;
    op3.op = "syscall";
    op3.arg1 = op3.arg2 = op3.res = 0;
    insertaLC(l1,finalLC(l1),op3);
}
void leerIdentificador(ListaC l1,char* iden){
    Operacion op1;
    op1.op = "li";
    op1.res = "$v0";
    op1.arg1 = "5";
    op1.arg2 = 0;
    insertaLC(l1,finalLC(l1),op1);
    Operacion op2;
    op2.op = "syscall";
    op2.res = op2.arg1 = op2.arg2 = 0;
    insertaLC(l1,finalLC(l1),op2);
    Operacion op3;
    op3.op = "sw";
    op3.res = "$v0";
    asprintf(&op3.arg1,"_%s",iden);
    op3.arg2 = 0;
    insertaLC(l1,finalLC(l1),op3);
}
void statementIf(ListaC l, ListaC expresion, ListaC statement){
    char *etiq = obtenerEtiq();
    Operacion op1;
    op1.op = "beqz";
    op1.res = recuperaResLC(expresion);
    op1.arg1 = etiq;
    op1.arg2 = 0;
    insertaLC(expresion,finalLC(expresion),op1);
    concatenaLC(l,expresion);
    concatenaLC(l,statement);
    Operacion op2;
    op2.op = "etiq";
    op2.res = etiq;
    op2.arg1 = op2.arg2 = 0;
    insertaLC(l,finalLC(l),op2);
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
char* obtenerEtiq(){
    char* etiq;
    asprintf(&etiq,"$l%d",contador_etiq++);
    return etiq;
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
bool validarNoConstanteIdentificador(Lista lista, char *nombre){
    PosicionLista p = buscaLS(lista,nombre);
    if(p == finalLS(lista)){
        printf("ERROR: La variable %s ha sido asignada sin ser declarada\n",nombre);
        errores++;
        return false;
    }
    if(recuperaLS(lista,p).tipo == CONSTANTE){
        printf("ERROR: La variable %s es constante y ha sido reasignada\n",nombre);
        errores++;
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
    printf(".text\n");
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
    printf("\n\n -------------HA HABIDO %d ERRORES-----------------\n\n", errores);
    if (errores == 0){
        printf("\n\n ----------- SEGMENTO DE DATOS --------------\n\n");
        imprimirTablaSimbolos();
        printf("\n\n ----------- INSTRUCCIONES MIPS --------------\n\n");
        imprimirLC(l);
    }
    liberaListaSimbolos(tablaSimb);
    
}
