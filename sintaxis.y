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
    void finalizarYGenerarCodigo();
    bool validarNoConstanteIdentificador(Lista l, char *nombre);
    bool validarExistenciaDeIdentificador(Lista lista, char *nombre);
    void anade_operacion_lista_codigo(ListaC lc,char* op,char* reg,char* arg1,char* arg2);
    ListaC expresion_binop(ListaC l1,ListaC l2,char *op);
    ListaC expresion_unop(ListaC l1,char *op);
    ListaC statement_asig(char* iden, ListaC l1);
    void imprimirLC(ListaC codigo);
    ListaC imprimirExpresion(ListaC l1);
    ListaC imprimirFromMemoria(ListaC l1, char* ident);
    void leerIdentificador(ListaC l1,char* iden);
    void statementIf(ListaC l,ListaC expresion,ListaC statement);
    void statementIfElse(ListaC l,ListaC expresion,ListaC ltrue,ListaC lfalse);
    void statementWhile(ListaC l, ListaC condicion, ListaC codigo);
    void statementDoWhile(ListaC l, ListaC condicion, ListaC codigo);
    ListaC statementFor(ListaC codigo_inicio,ListaC codigo_limite,ListaC codigo_actualizacion,ListaC codigo_bucle);
    ListaC expresion_relop(ListaC l1, ListaC l2, const char *op) ;
    char* obtenerReg();
    char* obtenerEtiq();
    Operacion creaOp(char* op, char* res,char* arg1,char*arg2 );
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
%token VAR "var"
%token CONST "const"
%token INT "int"
%token IF "if"
%token ELSE "else"
%token WHILE "while"
%token DO "do"
%token READ "read"
%token LT " < "
%token GT " > "
%token LE "<="
%token GE ">="
%token EQ "=="
%token NE "!="
%token FOR "for"
%token <cadena> STRING "string"

%type <codigo> expresion statement statement_list declarations const_list print_item print_list read_list asignation

%define parse.error verbose

// Precedencia y asociatividad
// Asociatividad izquierda %left MAS
// Asociatividad izquierda %right MAS
// No tiene asociatividad %nonassoc MAS
// Los operadores cuya asociatividad se define primero tienen menos precedencia

%nonassoc LT GT LE GE EQ NE
%left "+" "-" 
%left "*" "/"

%expect 1

%%
  
program   : { inicializar(); } ID "(" ")" "{" declarations statement_list "}"  {if (errores == 0) concatenaLC($6,$7); finalizarYGenerarCodigo($6);}
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
                                  $$ = statement_asig($1,$3);}
              | const_list "," ID "=" expresion {printf("const_list -> const_list , ID(%s) = e\n",$3);
                                                 insertaSimboloEnLista(tablaSimb,$3,CONSTANTE,0);
                                                 if (errores == 0) concatenaLC($1,statement_asig($3,$5));
                                                 $$ = $1;}
              ;

statement_list: statement_list statement {printf("statement_list -> statement_list statement\n");
                                          if (errores == 0) concatenaLC($1,$2);
                                          $$ = $1;}
              | {$$ = creaLC();}
              ;

statement     : asignation ";"

              | "{" statement_list "}" { printf("statement -> { statement_list }\n"); 
                                         $$ = $2; }
              | IF "(" expresion ")" statement ELSE statement 
                  { printf("statement -> IF ( e ) statement ELSE statement\n"); 
                    $$ = creaLC();
                    statementIfElse($$,$3,$5,$7);
                    printf("ATENCIONNNN");
                    imprimirLC($$);
                  }
              | IF "(" expresion ")" statement 
                  { printf("statement -> IF ( e ) statement\n");
                    $$ = creaLC();
                    statementIf($$,$3,$5); }
              | WHILE "(" expresion ")" statement 
                  { printf("statement -> WHILE ( e ) statement\n"); 
                    $$ = creaLC();
                    statementWhile($$,$3,$5);
                  }
              | DO statement WHILE "(" expresion ")"  
                  { 
                    $$ = creaLC();
                    statementDoWhile($$,$5,$2);
                  }
              | PRINT "(" print_list ")" ";" 
                  { printf("statement -> PRINT ( print_list ) ;\n"); $$ = $3; } 
              | READ "(" read_list ")" ";" 
                  { printf("statement -> READ ( read_list ) ;\n"); $$ = $3; }
              
              | FOR "(" asignation ";"  expresion ";" asignation ")" statement
                {
                    $$ = statementFor($3,$5,$7,$9);
                }
              ;

asignation        :
                ID "=" expresion 
                  { printf("statement -> ID = e ;\n"); 
                    validarNoConstanteIdentificador(tablaSimb,$1);
                     $$ = statement_asig($1,$3);
                    }

print_list    : print_item {printf("print_list -> print_item\n"); $$ = $1;}
              | print_list "," print_item {printf("print_list -> print_list , print_item\n"); if (errores == 0) concatenaLC($1,$3); $$ = $1;}
              ;

print_item    : expresion  {printf("print_item -> e\n"); $$ = imprimirExpresion($1);
                                                                          liberarReg(recuperaResLC($1));
                                                                          }
              | STRING     {printf("print_item -> %s\n",$1);
                            Simbolo s = insertaSimboloEnLista(tablaSimb,$1,CADENA,strIdentifier++);
                            char* ident;
                            asprintf(&ident,"$str%d",s.valor);
                            $$ = imprimirFromMemoria($$,ident);
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

          | expresion LT  expresion  { $$ = expresion_relop($1,$3,"<");  }
          | expresion GT  expresion  { $$ = expresion_relop($1,$3,">");  }
          | expresion LE  expresion  { $$ = expresion_relop($1,$3,"<="); }
          | expresion GE  expresion  { $$ = expresion_relop($1,$3,">="); }
          | expresion EQ  expresion  { $$ = expresion_relop($1,$3,"=="); }
          | expresion NE  expresion  { $$ = expresion_relop($1,$3,"!="); }
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
    Operacion oper = creaOp(op,reg,arg1,arg2);
    insertaLC(lc, finalLC(lc),oper);
}
ListaC expresion_binop(ListaC l1,ListaC l2,char *op){
    if(errores > 0) return NULL;
    Operacion oper = creaOp(op,recuperaResLC(l1),recuperaResLC(l1),recuperaResLC(l2));
    concatenaLC(l1,l2);
    insertaLC(l1,finalLC(l1),oper);
    liberarReg(oper.arg2); // Puedo liberar el registro de la expresion 2
    return l1;
}
ListaC expresion_unop(ListaC l1,char *op){
    if(errores > 0) return NULL;
    Operacion oper = creaOp(op,recuperaResLC(l1),recuperaResLC(l1),0);
    insertaLC(l1,finalLC(l1),oper);
    return l1;
}
ListaC statement_asig(char* iden, ListaC l1){
    if(errores > 0) return NULL;
    Operacion oper;
    oper.op = "sw";
    asprintf(&oper.res,"%s",recuperaResLC(l1)); //En el primer parametro del sw va el registro donde se encuentran los datos a cargar
    asprintf(&oper.arg1,"_%s",iden); //En el segundo paraemtro del sw ira el _identificador 
    // usado para cargar la dir de nuestra variable
    oper.arg2 = 0;
    insertaLC(l1,finalLC(l1),oper);
    liberarReg(recuperaResLC(l1)); // Creo que tambien puedo liberar este registro que el que almacena el valor de la expresion
    return l1;
}
ListaC imprimirFromMemoria(ListaC l1, char* ident){
    l1 = creaLC();
    //Movemos el valor de memoria a $a0
    Operacion op1 = creaOp("la","$a0",0,0);
    asprintf(&op1.arg1,"%s",ident);
    insertaLC(l1,finalLC(l1),op1);
    //Movemos el valor 4 al registro $v0
    Operacion op2 = creaOp("li","$v0","4",0);
    insertaLC(l1,finalLC(l1),op2);
    //Finalmente hacemos un syscall
    Operacion op3 = creaOp("syscall",0,0,0);
    insertaLC(l1,finalLC(l1),op3);
    return l1;
}
ListaC imprimirExpresion(ListaC l1){
    //Movemos el valor del registro a $a0
    Operacion op1 = creaOp("move","$a0",0,0);
    asprintf(&op1.arg1,"%s",recuperaResLC(l1));
    insertaLC(l1,finalLC(l1),op1);
    //Movemos el valor 4 al registro $v0
    Operacion op2 = creaOp("li","$v0","1",0);
    insertaLC(l1,finalLC(l1),op2);
    //Finalmente hacemos un syscall
    Operacion op3 = creaOp("syscall",0,0,0);
    insertaLC(l1,finalLC(l1),op3);
    return l1;
}
void leerIdentificador(ListaC l1,char* iden){
    Operacion op1 = creaOp("li","$v0","5",0);
    insertaLC(l1,finalLC(l1),op1);
    Operacion op2 = creaOp("syscall",0,0,0);
    insertaLC(l1,finalLC(l1),op2);
    Operacion op3 = creaOp("sw","$v0",0,0);
    asprintf(&op3.arg1,"_%s",iden);
    insertaLC(l1,finalLC(l1),op3);
}
void statementIf(ListaC l, ListaC expresion, ListaC statement){
    char *etiq = obtenerEtiq();
    //Codigo para calcular la expresion
    liberarReg(recuperaResLC(expresion));
    Operacion op1 = creaOp("beqz",recuperaResLC(expresion),etiq,0);
    //Codigo del dentro del if
    Operacion op2 = creaOp("etiq",etiq,0,0);
    concatenaLC(l,expresion);
    insertaLC(l,finalLC(l),op1);
    concatenaLC(l,statement);
    insertaLC(l,finalLC(l),op2);
    
}
void statementIfElse(ListaC l,ListaC expresion,ListaC ltrue,ListaC lfalse){
    char *eti1 = obtenerEtiq();
    char *eti2 = obtenerEtiq();
    //Ahora vendria el codigo para calcular la expresion
    Operacion op1 = creaOp("beqz",recuperaResLC(expresion),eti1,0); // Saltar al else si es 0
    //Codigo de dentro del if
    Operacion op2 = creaOp("j",eti2,0,0);   //Salto al final para no entrar en el else
    Operacion op3 = creaOp("etiq",eti1,0,0); // Empieza el else
    //Ahora va el codigo del else
    Operacion op4 = creaOp("etiq",eti2,0,0);
    concatenaLC(l,expresion);
    liberarReg(recuperaResLC(expresion));
    insertaLC(l,finalLC(l),op1);
    concatenaLC(l,ltrue);
    insertaLC(l,finalLC(l),op2);
    insertaLC(l,finalLC(l),op3);
    concatenaLC(l,lfalse);
    insertaLC(l,finalLC(l),op4);
}
void statementWhile(ListaC l, ListaC condicion, ListaC codigo){
    char *eti1 = obtenerEtiq(); // Etiqueta previa a la comprobacion de la condicion
    char *eti2 = obtenerEtiq(); // Etiqueta de salida del bucle while
    Operacion op1 = creaOp("etiq",eti1,0,0);
    //Ahora vendria el codigo para calcular la condicion
    Operacion op2 = creaOp("beqz",recuperaResLC(condicion),eti2,0);
    //Ahora vendria el codigo de dentro del while
    Operacion op3 = creaOp("j",eti1,0,0);
    Operacion op4 = creaOp("etiq",eti2,0,0);
    insertaLC(l,finalLC(l),op1);
    concatenaLC(l,condicion);
    liberarReg(recuperaResLC(condicion));
    insertaLC(l,finalLC(l),op2);
    concatenaLC(l,codigo);
    insertaLC(l,finalLC(l),op3);
    insertaLC(l,finalLC(l),op4);
}
void statementDoWhile(ListaC l, ListaC condicion, ListaC codigo){
    char *eti1 = obtenerEtiq();
    Operacion op1 = creaOp("etiq",eti1,0,0);
    //Ahora iria el codigo del do
    //Ahora calculariamos la expresion de la condicion
    Operacion op2 = creaOp("bnez",recuperaResLC(condicion),eti1,0); // Saltamos si la condicion es != 0 
    insertaLC(l,finalLC(l),op1);
    concatenaLC(l,codigo);
    concatenaLC(l,condicion);
    insertaLC(l,finalLC(l),op2);
    liberarReg(recuperaResLC(condicion));
}
ListaC statementFor(ListaC codigo_inicio,ListaC codigo_limite,ListaC codigo_actualizacion,ListaC codigo_bucle){
    ListaC l = creaLC();
    char* eti1 = obtenerEtiq(); // Etiqueta para iterar otra vez el bucle
    char* eti2 = obtenerEtiq(); //Etiqueta para salir del bucle
    //Codigo de inicializacion del indice
    concatenaLC(l,codigo_inicio);
    //Etiqueta
    anade_operacion_lista_codigo(l,"etiq",eti1,0,0);
    //Ahora viene la compbrobacion 
    concatenaLC(l,codigo_limite);
    liberarReg(recuperaResLC(codigo_limite));
    anade_operacion_lista_codigo(l,"beqz",recuperaResLC(codigo_limite),eti2,0);
    //Ahora viene lo de dentro del for 
    concatenaLC(l,codigo_bucle);
    //Ahora vienel la actualizacion
    concatenaLC(l,codigo_actualizacion);
    anade_operacion_lista_codigo(l,"j",eti1,0,0);
    anade_operacion_lista_codigo(l,"etiq",eti2,0,0);

    return l;
}
ListaC expresion_relop(ListaC l1, ListaC l2, const char *op) {
    if (errores > 0) return NULL;

    /* 1) combinar código de los dos operandos */
    char *r1 = recuperaResLC(l1);
    char *r2 = recuperaResLC(l2);
    concatenaLC(l1, l2);

    char *dest = obtenerReg();

    if (strcmp(op, "<") == 0) {
        anade_operacion_lista_codigo(l1,"slt",dest, r1,r2);
    }
    else if (strcmp(op, ">") == 0) {
        anade_operacion_lista_codigo(l1,"slt",dest,r2,r1);
    }
    else if (strcmp(op, "<=") == 0) {
        char *tmp = obtenerReg();
        // aqui hacemos un > y luego con el xori le damos la vuelta para que sea <=
        anade_operacion_lista_codigo(l1,"slt",tmp,r2,r1);
        anade_operacion_lista_codigo(l1,"xori", dest,tmp,"1");
        liberarReg(tmp);
    }
    else if (strcmp(op, ">=") == 0) {
        //lo mismo que el apartado anterior
        char *tmp = obtenerReg();
        anade_operacion_lista_codigo(l1,"slt",tmp, r1,r2);
        anade_operacion_lista_codigo(l1,"xori",dest,tmp,"1");
        liberarReg(tmp);
    }
    else if (strcmp(op, "==") == 0) {
        // hacemos un xor y luego le damos la vuelta
        anade_operacion_lista_codigo(l1,"xor",dest, r1,r2); // dest Valdra 0 si son iguales y distinto de 0 si son distintos
        anade_operacion_lista_codigo(l1, "sltiu", dest, dest, "1"); //si dest vale 0 entonces 0<1 => el nuevo dest=1
        //si dest !=0 entonces dest !< 1 luego en dest quedara 0 como queriamos
    }
    else if (strcmp(op, "!=") == 0) {
        anade_operacion_lista_codigo(l1, "xor", dest, r1, r2);
    }
    else {
        yyerror("operador relacional desconocido");
    }

    /* liberamos los regs originales y guardamos el resultado */
    //Podiamos haber usado r1 como registro destino pero para mejorar la legibilidad lo haremos asi
    liberarReg(r1);
    liberarReg(r2);
    guardaResLC(l1, dest);
    return l1;
}

char* obtenerReg(){
    for(int i=0;i<n_registros;i++){
        if(!registros_en_uso[i]) {
            char* buff;
            asprintf(&buff,"$t%d",i);
            registros_en_uso[i] = true;
            printf("Te quito el t%d\n",i);
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
    printf("Voy a liberar el reg %s",i_str);
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
    s.valor = valor;
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
    printf(".globl main\n");
    printf("main:\n");
    while (p != finalLC(codigo)) {
    oper = recuperaLC(codigo,p);
    if(!strcmp(oper.op,"etiq")){
        printf("%s:\n",oper.res);
    }else{ 
    printf("%s",oper.op);
    if (oper.res) printf(" %s",oper.res);
    if (oper.arg1) printf(", %s",oper.arg1);
    if (oper.arg2) printf(", %s",oper.arg2);
    printf("\n");
    }
    p = siguienteLC(codigo,p);
  }
  printf("li $v0, 10\n");
  printf("syscall");
}
void finalizarYGenerarCodigo(ListaC l){
    mostrarListaSimbolos(tablaSimb);
    printf("\n\n -------------HA HABIDO %d ERRORES-----------------\n\n", errores);
    if (errores == 0){
        if (!freopen("output.asm","w", stdout)) {
            perror("No pudo volcar el codigo mips en output.asm");
            exit(1);
        }
        //printf("\n\n ----------- SEGMENTO DE DATOS --------------\n\n");
        imprimirTablaSimbolos();
        //printf("\n\n ----------- INSTRUCCIONES MIPS --------------\n\n");
        imprimirLC(l);
    }
    liberaListaSimbolos(tablaSimb);
    
}
Operacion creaOp(char* op, char* res,char* arg1,char*arg2 ){
    Operacion oper;
    oper.op = op;
    oper.res = res;
    oper.arg1 = arg1;
    oper.arg2 = arg2;
    return oper;
}