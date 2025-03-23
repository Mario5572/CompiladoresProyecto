ProyectoCompiladores: main.c lex.yy.c sintaxis.tab.c
	gcc main.c lex.yy.c sintaxis.tab.c listaSimbolos.c -lfl -o ProyectoCompiladores

lex.yy.c : lexico.l sintaxis.tab.h
	flex lexico.l

sintaxis.tab.h sintaxis.tab.c : sintaxis.y
	bison -d -v sintaxis.y

clean :
	rm -f ProyectoCompiladores sintaxis.tab.* lex.yy.c sintaxis.output

run : ProyectoCompiladores entrada.txt
	./ProyectoCompiladores entrada.txt