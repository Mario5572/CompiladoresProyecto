#include <stdio.h>
#include <stdlib.h>

extern int yyparse();
extern FILE *yyin;

int main(int argc, char* argv[]) {
    if (argc != 2) {
        printf("Uso: %s fichero\n", argv[0]);
        exit(1);
    }
    yyin = fopen(argv[1],"r");
    if (yyin == NULL) {
        printf("Error abriendo %s\n", argv[1]);
        exit(2);
    }
    yyparse();
    fclose(yyin);
}