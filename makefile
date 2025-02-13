lexico: main.c lex.yy.c lexico.h
	gcc main.c lex.yy.c -lfl -o lexico

lex.yy.c: lexico.l
	flex lexico.l

test: lexico entrada.txt
	./lexico entrada.txt

supertest: lexico pruebaExhaustiva.txt
	./lexico pruebaExhaustiva.txt

clean: 
	rm lex.yy.c lexico