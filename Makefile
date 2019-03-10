all:
	bison -d ostatniparser.y
	flex lexer.lex
	g++ -g -D_GNU_SOURCE ostatniparser.tab.c lex.yy.c -lfl -lm -o kompilator
