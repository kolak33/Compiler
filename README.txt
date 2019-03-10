pliki:
lexer.lex - analizator leksykalny
ostatniparser.y - glowny plik kompilatora, wraz z analiza skladniowa i zamiana na kod posredni
przebiegi.h, przebiegi.cpp - translacja z kodu posredniego na kod assemblerowy i kilka optymalizacji
Makefile



Kompilacja
poprzez wywolanie w terminalu:
make all



Uruchomienie
Przyklad kompilacji kodu z pliku program2.imp:
./kompilator program2.imp > output.txt

a nastepnie przyklad interpretacji powstalego kodu assemblerowego, znajdujacego sie w pliku output.txt:
./interpreter-cln output.txt
