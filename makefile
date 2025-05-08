ProyectoCompiladores: main.c lex.yy.c sintaxis.tab.c listaCodigo.c listaSimbolos.c
	gcc -g main.c lex.yy.c sintaxis.tab.c listaSimbolos.c listaCodigo.c -lfl -o ProyectoCompiladores

lex.yy.c : lexico.l sintaxis.tab.h
	flex lexico.l

sintaxis.tab.h sintaxis.tab.c : sintaxis.y
	bison -d -v sintaxis.y

clean :
	rm -f ProyectoCompiladores sintaxis.tab.* lex.yy.c sintaxis.output

run : ProyectoCompiladores prueba.txt
	./ProyectoCompiladores prueba.txt

exec : prueba.txt ProyectoCompiladores
	./ProyectoCompiladores prueba.txt && java -jar Mars.jar output.asm
