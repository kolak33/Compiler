


%{
  #include <stdio.h>
  #include <iostream>
  #include <string.h>
  #include <string>
  //#include <cstring> // strtok
  #include <math.h>
  #include <ctype.h>
  #include <stdbool.h>
  #include <stdlib.h>
  #include <map>    // tablica symboli
  #include <algorithm> // max(a, b)
  #include <vector> // string code
  #include <sstream>
  #include <list> // lista etykiet
  #include "deklaracje.h"
  #include "przebiegi.cpp"
  // #include "lex.yy.c"
  #define DEBUG 0
  #define WYPISZ 0

  #define DEC_TRESHOLD_SAME_VAR 30 // np. a := a - 10;
  #define DEC_TRESHOLD_DIFF_VAR 5  // np. a := b - 10;

  // definicje roznych mozliwosci dla identyfikatora
  #define I_VARIABLE 0     // zmienna
  #define I_ARR_NUM  1     // tablica[numer]
  #define I_ARR_VAR  2     // tablica[zmienna]
  #define I_NUM      3     // numer

  // definicje typu zmiennej, czy zwykla, czy typu tablicowego
  #define TYPE_VAR 0 // zmienna
  #define TYPE_ARR 1 // tablica

  bool declare_var;
  extern bool error_zlyznak;
  bool error_divzero = false;
  bool uniq_variable = false; // czy zmienna jest unikalna (tablica symboli)

  void yyerror (char const *);
  extern int num_lines;
  extern int yylex();
  extern int yyparse();
  extern FILE *yyin;

 static long long int label_count = 0; // do tworzenia nazw etykiet
 static long long int temp_name_count = 0; // do tworzenia nazw zmiennych tymczasowych
 static long long int address_count = 0; // licznik dostepnych adresow w maszynie rejestrowej
 std::vector<std::string> code;
 std::vector<std::string> label_list;
 std::vector<std::string> warnings;
 std::vector<std::string> errors;
 std::string str;
 std::stringstream ss;

/* rekord w tablicy symboli */
/* typedef struct Record
{
    bool is_initialized; // wartosc wczytywana w kodzie programu
    bool type; // typ zmiennej: 0 - zmienna, 1 - tablica
    long long int size; // wielkosc zadeklarowanej tablicy
    bool is_alive; // czy zmienna jest zywa, czy nie
    bool is_iterator; // jezeli zmienna > 0 to znaczy ze jest iteratorem i nie mozna jej modyfikowac
    long long int mem_addr; // adres pamieci w maszynie rejestrowej
}Record; */

  /* struktura na zmienne tymczasowe dla petli for */
  /* typedef struct Temp_var
  {
      std::string name;
      long long int ival;
  }Temp_var;

  std::vector< Temp_var > temp_var_list; */

  // sprawdz czy zmienna jest zainicjalizowana


  /* tworzy zmienna tymczasowa */
   char* create_temp_var()
  {
      ss.clear();
      ss.str("");
      ss << temp_name_count;
      temp_name_count++;
      std::string temp = std::string("T") + ss.str();
      char *name = strdup(temp.c_str());
      return name;
  }

/* defaultowe tworzenie rekordu */
Record* create_record(long long int size, bool type)
{
    Record *record = (Record*)malloc(sizeof(Record));

    record->is_initialized = false;
    record->is_iterator = false;
    record->is_alive = false;
    record->type = type;
    record->size = size;
    record->mem_addr = 2;
    record->is_used = true;
    return record;
}

/* porownywanie w std::map */
/*    struct cmp_str
    {
       bool operator()(char *a, char *b)
       {
          return strcmp(a, b) < 0;
       }
    }; */

  std::map<char*, Record *, cmp_str> tab_sym;
  std::map<char*, Record *, cmp_str>::iterator it;

/* dodaje rekord do tablicy symboli */
  void add_tab_sym(char *name, Record *record)
  {
        tab_sym[name] = record;
  }

/* usuwa zmienna z tablicy symboli */
  void rem_tab_sym(char *name)
  {
        tab_sym.erase(name);
  }

/* tworzy zmienna tymczasowa i dodaje do tablicy symboli */
  char* create_add_temp_var()
  {
      char *temp_iter = create_temp_var();
      Record *record2 = create_record(1, TYPE_VAR);
      record2->is_initialized = true;
      tab_sym[temp_iter] = record2;
      return temp_iter;
  }

/* sprawdza czy nie ma juz jakiejs zmiennej w tablicy symboli */
/* return: true - zmienna istnieje, false - brak zmiennej w tablicy symboli */
  bool check_tab_sym(char *name)
  {
      it = tab_sym.find(name);
      if(it == tab_sym.end()) // zmienna nie istnieje
        return false;
      else
        return true;
  }

  /* sprawdza czy nie ma juz jakiejs zmiennej w tablicy symboli */
  /* return: true - brak zmiennej w tablicy symboli, false - zmienna istnieje */
  bool check_uniq_tab_sym(char *name)
  {
          it = tab_sym.find(name);
          if(it == tab_sym.end()) // zmienna nie istnieje
            return true;
          else
            return false;
  }

  bool check_used_tab_sym(char *name)
  {
      it = tab_sym.find(name);
      if(it != tab_sym.end()) // istnieje
        return it->second->is_used; // jest aktualnie uzywany jako iterator
  }

/* dodawanie do tablicy symboli i sprawdzanie redeklaracji */
/* type: false - zmienna, true - tablica */
/* token = nazwa zmiennej */
  void proc_add_tab_sym(char *token, bool type, long long int size)
  {
      uniq_variable = check_uniq_tab_sym(token);
      if(!uniq_variable)
      {
          ss.clear();
          ss.str("");
          ss << num_lines;
          std::string comm;

          if(!type) comm = std::string("linia ") + ss.str() + std::string(": redeklaracja zmiennej ") + std::string(token);
          else
          {
              comm = std::string("linia ") + ss.str() + std::string(": redeklaracja tablicy ") + std::string(token);
              ss.clear();
              ss.str("");
              ss << size;
              comm += std::string("[") + ss.str() + std::string("]");
          }
          warnings.push_back(comm);
      }
      else
      {
          if(DEBUG && !type) printf("poprawna deklaracja zmiennej %s\n", token);
          if(DEBUG && type) printf("poprawna deklaracja tablicy %s[%lld]\n", token, size);
          Record *record = create_record(size, type);
          add_tab_sym(token, record);
      }
  }


  /* tworzy string z podanego identyfikatora, np tab[c] */
    std::string create_name_string(int identifier_type, char *name, long long int ival, char *name_pos)
    {
        std::string comm;
        switch(identifier_type)
        {
            case I_VARIABLE:
                comm = std::string(name);
                break;
            case I_ARR_NUM:
            ss.clear();
                ss.str("");
                ss << ival;
                comm = std::string(name) + std::string("[") + ss.str() + std::string("]");
                break;
            case I_ARR_VAR:
                comm = std::string(name) + std::string("[") + std::string(name_pos) + std::string("]");
                break;
            case I_NUM:
                ss.clear();
                ss.str("");
                ss << ival;
                comm = ss.str();
                break;
        }
        return comm;
    }

   /* tworzy nowa etykiete i dodaje ja do listy aktualnie uzywanych etykiet */
    std::string gen_label()
    {
        std::string comm = std::string("E");
        ss.clear();
        ss.str("");
        ss << label_count;
        label_count++;
        comm += ss.str();
        label_list.push_back(comm);
        return comm;
    }

    /* neguje operator porownywania */
    std::string negate_operator(std::string op)
    {

            if(op == ">") return std::string("<=");
            else if(op == "<") return std::string(">=");
            else if(op == ">=") return std::string("<");
            else if(op == "<=") return std::string(">");
            else if(op == "=") return std::string("<>");
            else if(op == "<>") return std::string("=");
            else if(DEBUG) printf("Blad. zly operator w funkcji negate_operator\n");
    }

    void check_var_init(char *name)
    {
        if(check_tab_sym(name)) // jezeli zmienna istnieje w tablicy symboli
        {
            Record *variable = tab_sym[name]; // bierze info o zmiennej
            if(!variable->is_initialized) // zmienna niezainicjalizowana
            {
                std::string comm;
                ss.clear();
                ss.str("");
                ss << num_lines;
                comm = std::string("linia ") + ss.str() + std::string(": zmienna ") + std::string(name) + std::string(" nie jest zainicjalizowana");
                errors.push_back(comm);
            }
        }
    }

    // sprawdz czy zmienna istnieje
    bool check_var_exists(char *name)
    {
        if(!check_tab_sym(name)) // jezeli zmienna nie istnieje w tablicy symboli
        {
            std::string comm;
            ss.clear();
            ss.str("");
            ss << num_lines;
            comm = std::string("linia ") + ss.str() + std::string(": brak zmiennej ") + std::string(name) + std::string(" w tablicy symboli");
            errors.push_back(comm);
            return false;
        }
        return true;
    }

    // sprawdz czy poprawne odwolanie do typu tablica/zmienna
    void check_var_correct_use(char *name, int identifier_type)
    {
        Record *identifier = tab_sym[name];
        if( (identifier->type == TYPE_VAR && identifier_type != I_VARIABLE) ||
            (identifier->type == TYPE_ARR && identifier_type == I_VARIABLE) )
            // jezeli typy zmienna i tablicowa sie nie zgadzaja
        {
            std::string comm;
            ss.clear();
            ss.str("");
            ss << num_lines;
            comm = std::string("linia ") + ss.str() + std::string(": zly zapis zmiennnej ") + std::string(name);
            errors.push_back(comm);
        }
    }

    // sprawdza czy odwolanie do tablicy miesci sie w zakresie tablicy
    void check_var_size(char *name, long long int ival)
    {
        Record *identifier = tab_sym[name];
        if(identifier->size <= ival) // niepoprawne odwolanie do tablicy
        {
            std::string comm;
            ss.clear();
            ss.str("");
            ss << num_lines;
            comm = std::string("linia ") + ss.str() + std::string(": zly zakres w zmiennej ") + std::string(name);
            ss.clear();
            ss.str("");
            ss << ival;
            comm += std::string("[") + ss.str() + std::string("]");
            errors.push_back(comm);
        }
    }

    /* przydziela odpowiednie komorki pamieci w maszynie rejestrowej */
    void assign_memory()
    {
        // zwykle przydzialnie pamieci
        /*
        std::map<char*, Record *, cmp_str>::iterator it = tab_sym.begin();
        for(; it != tab_sym.end(); it++)
        {
            it->second->mem_addr = address_count;
            address_count += it->second->size; // zwiekszamy dostepny adres o zajmowana pamiec przez dana zmienna
        } */

        // troche lepsze przydzielanie pamieci, najpierw specjalne komorki pamieci, potem zmienne, potem tymczasowe a na koncu tablice
        std::map<char*, Record *, cmp_str>::iterator it = tab_sym.begin();
        for(; it != tab_sym.end(); it++)
        {
            if(it->first[0] >= 'A' && it->first[0] <= 'Z' && it->first[0] != 'T')
            {
                it->second->mem_addr = address_count;
                address_count += it->second->size; // zwiekszamy dostepny adres o zajmowana pamiec przez dana zmienna
            }
        }
        it = tab_sym.begin();
        for(; it != tab_sym.end(); it++)
        {
            if(it->first[0] == 'T')
            {
                it->second->mem_addr = address_count;
                address_count += it->second->size; // zwiekszamy dostepny adres o zajmowana pamiec przez dana zmienna
            }
        }
        it = tab_sym.begin();
        for(; it != tab_sym.end(); it++)
        {
            if(it->first[0] >= 'a' && it->first[0] <= 'z' && it->second->size == 1)
            {
                it->second->mem_addr = address_count;
                address_count += it->second->size; // zwiekszamy dostepny adres o zajmowana pamiec przez dana zmienna
            }
        }
        it = tab_sym.begin();
        for(; it != tab_sym.end(); it++)
        {
            if(it->first[0] >= 'a' && it->first[0] <= 'z' && it->second->size != 1)
            {
                it->second->mem_addr = address_count;
                address_count += it->second->size; // zwiekszamy dostepny adres o zajmowana pamiec przez dana zmienna
            }
        }


/*
        it = tab_sym.begin();
        for(; it != tab_sym.end(); it++)
        {
            std::cout << it->first << std::endl;
        }

        it = tab_sym.begin();
        for(; it != tab_sym.end(); it++)
        {
            std::cout << it->first << "  " << it->second->mem_addr << std::endl;
        } */
    }

%}

%code requires
{
    typedef struct Token
    {
        char *name; // nazwa zmiennej
        long long int ival; // wartosc
        char *name_pos; // zmienna numeru komorki pamieci do ktorej sie odwolujemy poprzez 'zmienna' np. tablica[zmienna];
        int identifier_type; // typ identyfikatora: VARIABLE - zmienna, ARR_NUM - tablica[numer], ARR_VAR - tablica[zmienna]
        bool second_value; // true, gdy potrzebna druga zmienna np. value + value, false w p.p.

        // atrybuty dla produkcji z dwiema wartosciami
        char *value2_name;
        long long int value2_ival;
        char *value2_name_pos;
        int value2_iden_type;

        char *op; // rodzaj operacji, np ADD, SUB lub rodzaj warunku np EQ, NE
    }Token;
}


%union {
  Token token;
}





%token <token> NUM
%token <token> PIDENTIFIER
%token <token> ADD SUB MULT DIV MOD
%token L_BRACKET R_BRACKET
%token <token> EQ NE LT GT LE GE
%token ASSIGN
%token SEM /* semicolon */

%token VAR _BEGIN END
%token IF THEN ELSE ENDIF
%token WHILE DO ENDWHILE
%token FOR FROM TO DOWNTO ENDFOR
%token READ WRITE SKIP

%type <token> identifier expression value condition

%left '-' '+'
%left '*' '/' '%'

%%


program:
%empty
| VAR
{   num_lines--;
    declare_var = true; // czas deklaracji zmiennych

    char *special_mult = (char*)malloc(sizeof(special_mult)); // przydzielenie pamieci na specjalny rejestr pomocniczy do mnozenia
    *special_mult = 'M';
    Record *record = create_record(1, TYPE_VAR);
    tab_sym[special_mult] = record;

    char *special_D = (char*)malloc(sizeof(special_D)); //(dzielna) przydzielenie pamieci na specjalny rejestr pomocniczy do dzielenia
    *special_D = 'D';
    Record *record2 = create_record(1, TYPE_VAR);
    tab_sym[special_D] = record2;

    char *special_N = (char*)malloc(sizeof(special_N)); //(dzielnik) przydzielenie pamieci na specjalny rejestr pomocniczy do dzielenia
    *special_N = 'N';
    Record *record3 = create_record(1, TYPE_VAR);
    tab_sym[special_N] = record3;
}
vdeclarations _BEGIN
{ num_lines++;
    declare_var = false; // koniec deklaracji zmiennych
}
commands END {  }
;

vdeclarations:
%empty
| vdeclarations PIDENTIFIER
                        {
                            proc_add_tab_sym($2.name, TYPE_VAR, 1); // dodaj rekord, sprawdz redeklaracje
                        }
| vdeclarations PIDENTIFIER L_BRACKET NUM R_BRACKET
                        {
                            proc_add_tab_sym($2.name, TYPE_ARR, $4.ival);
                        }
;

commands:
commands command
| command
| error SEM
;

command:
identifier ASSIGN expression SEM
                        {
                            if(check_tab_sym($1.name)) // czyli identifier istnieje w tablicy symboli
                            {
                                Record *record = tab_sym[$1.name];
                                if(record->is_iterator)
                                {
                                    ss.clear();
                                    ss.str("");
                                    ss << num_lines;
                                    std::string er = std::string("linia ") + ss.str() + std::string(": proba zmiany wartosci iteratora.");
                                    errors.push_back(er);
                                }
                                record->is_initialized = true;
                            }


                            std::string comm;
                            char *temp_name;
                            if($3.second_value)
                            {
                                if( (*$3.op) == '-' && $3.value2_iden_type == I_NUM)
                                {

                                    if(strcmp($3.name, $3.value2_name) == 0 && $3.value2_ival < DEC_TRESHOLD_SAME_VAR) // result == a, DEC, - res a liczba
                                    {
                                        comm = std::string("- ") + create_name_string($1.identifier_type, $1.name, $1.ival, $1.name_pos) +\
                                        std::string(" ") + create_name_string($3.identifier_type, $3.name, $3.ival, $3.name_pos) + std::string(" ") +\
                                        create_name_string($3.value2_iden_type, $3.value2_name, $3.value2_ival, $3.value2_name_pos);
                                        code.push_back(comm);
                                    }
                                    else if(strcmp($3.name, $3.value2_name) != 0 && $3.value2_ival < DEC_TRESHOLD_DIFF_VAR) // result != a, DEC
                                    {
                                        comm = std::string("- ") + create_name_string($1.identifier_type, $1.name, $1.ival, $1.name_pos) +\
                                        std::string(" ") + create_name_string($3.identifier_type, $3.name, $3.ival, $3.name_pos) + std::string(" ") +\
                                        create_name_string($3.value2_iden_type, $3.value2_name, $3.value2_ival, $3.value2_name_pos);
                                        code.push_back(comm);
                                    }
                                    else // nie DEC, dodajemy zmienna pomocnicza
                                    {
                                        temp_name = create_add_temp_var();
                                        comm = std::string(":= ") + std::string(temp_name) + std::string(" ") +\
                                        create_name_string($3.value2_iden_type, $3.value2_name, $3.value2_ival, $3.value2_name_pos);
                                        code.push_back(comm);

                                        comm = std::string("- ") + create_name_string($1.identifier_type, $1.name, $1.ival, $1.name_pos) +\
                                        std::string(" ") + create_name_string($3.identifier_type, $3.name, $3.ival, $3.name_pos) + std::string(" ") +\
                                        std::string(temp_name);
                                        code.push_back(comm);
                                    }
                                }

                                else if( (*$3.op) == '*' )
                                {
                                    if($3.value2_iden_type == I_NUM) // przestawiamy liczbe na 1 pozycje
                                    {
                                        comm = std::string("* ") + create_name_string($1.identifier_type, $1.name, $1.ival, $1.name_pos) + std::string(" ") +\
                                        create_name_string($3.value2_iden_type, $3.value2_name, $3.value2_ival, $3.value2_name_pos) + std::string(" ") +\
                                        create_name_string($3.identifier_type, $3.name, $3.ival, $3.name_pos);
                                        code.push_back(comm);
                                    }
                                    else // wstawiamy zwyczajnie
                                    {
                                        comm = std::string("* ") + create_name_string($1.identifier_type, $1.name, $1.ival, $1.name_pos) + std::string(" ") +\
                                        create_name_string($3.identifier_type, $3.name, $3.ival, $3.name_pos) + std::string(" ") +\
                                        create_name_string($3.value2_iden_type, $3.value2_name, $3.value2_ival, $3.value2_name_pos);
                                        code.push_back(comm);
                                    }

                                }
                                comm = std::string($3.op) + std::string(" ");
                            }
                            else
                                comm = std::string(":= ");

                            if( ($3.second_value && (*$3.op) != '*') && (*$3.op) != '-' || !$3.second_value ) // mnozenie,odejmowanie zalatwione wczesniej
                            {
                                // dodajemy indentifier
                                comm += create_name_string($1.identifier_type, $1.name, $1.ival, $1.name_pos) + std::string(" ");
                                // dodajemy value
                                comm += create_name_string($3.identifier_type, $3.name, $3.ival, $3.name_pos);
                                if($3.second_value && (*$3.op) != '+' && (*$3.op) != '/' && (*$3.op) != '%' && $3.value2_iden_type == I_NUM)
                                   comm += std::string(" ") + std::string(temp_name);
                                else if($3.second_value)
                                    comm += std::string(" ") + create_name_string($3.value2_iden_type, $3.value2_name, $3.value2_ival, $3.value2_name_pos);
                                code.push_back(comm);
                                //std::cout << "udalo sie: " << comm << std::endl;
                            }
                        }
| IF condition
                        {
                            std::string comm = std::string("IF ");
                            if($2.second_value == false) // czyli warunek jest true lub false
                                if($2.ival) // jezeli warunek true
                                    comm += std::string("TRUE ");
                                else
                                    comm += std::string("FALSE ");
                            else // warunek nieobliczony
                            {
                                std::string cond_str;
                                char *temp_name;
                                if($2.identifier_type == I_NUM) // jezeli liczba to tworzymy zmienna tymczasowa
                                {
                                    temp_name = create_add_temp_var();
                                    cond_str = std::string(":= ") + std::string(temp_name) + std::string(" ") +\
                                    create_name_string($2.identifier_type, $2.name, $2.ival, $2.name_pos);
                                    code.push_back(cond_str);
                                    $2.identifier_type = I_VARIABLE;
                                    $2.name = temp_name;

                                }
                                if($2.value2_iden_type == I_NUM) // jezeli liczba to tworzymy zmienna tymczasowa
                                {
                                    temp_name = create_add_temp_var();
                                    cond_str = std::string(":= ") + std::string(temp_name) + std::string(" ") +\
                                    create_name_string($2.value2_iden_type, $2.value2_name, $2.value2_ival, $2.value2_name_pos);
                                    code.push_back(cond_str);
                                    $2.value2_iden_type = I_VARIABLE;
                                    $2.value2_name = temp_name;
                                }
                                comm += negate_operator($2.op) + std::string(" "); // dodawanie operatora
                                comm += create_name_string($2.identifier_type, $2.name, $2.ival, $2.name_pos) + std::string(" ");
                                comm += create_name_string($2.value2_iden_type, $2.value2_name, $2.value2_ival, $2.value2_name_pos);
                            }
                            //code.push_back(comm);

                            comm += std::string(" GOTO ") + gen_label();
                            code.push_back(comm);
                        }
THEN commands
                        {
                            // tu wejdzie dopiero po przetworzeniu commands
                            // zdejmujemy etykiete skoku do komend po ELSE, wstawiamy skok goto na koniec ifa
                            std::string comm = label_list.back();
                            label_list.pop_back();

                            std::string comm2 = std::string("GOTO ") + gen_label();
                            code.push_back(comm2);
                            // mamy goto koniec, etykieta: commands, koniec:

                            code.push_back(comm);

                        }
ELSE commands ENDIF
                        {
                                std::string comm = label_list.back();
                                label_list.pop_back();
                                code.push_back(comm);
                        }

| WHILE condition
                        {

                            if($2.second_value == false) // czyli warunek jest true lub false
                            {
                                std::string comm = std::string("IF ");
                                if($2.ival) // jezeli warunek true to wpadamy w nieskonczona petle, bo nie ma
                                            // w tym jezyku instrukcji break
                                {   ss.clear();
                                    ss.str("");
                                    ss << num_lines;
                                    std::string er = std::string("linia ") + ss.str() + std::string(": wejscie w nieskoczona petle.");
                                    errors.push_back(er);
                                    comm += std::string("TRUE ");
                                }
                                // kod jest nieosiagalny
                                else
                                {   ss.clear();
                                    ss.str("");
                                    ss << num_lines;
                                    std::string er = std::string("linia ") + ss.str() + std::string(": kod w petli while nieosiagalny, warunek zawsze falszywy.");
                                    warnings.push_back(er);
                                    comm += std::string("FALSE ");
                                }
                                std::string label_start = gen_label();
                                label_list.pop_back();

                                code.push_back(label_start); // etykieta poczatku petli
                                //code.push_back(comm);        // warunek
                                comm += std::string("GOTO ") + gen_label(); // najpierw pushujemy skok poza petle
                                label_list.push_back(label_start);         // potem skok wewnatrz petli
                                code.push_back(comm);        // skok warunku
                            }
                            else // warunek nieobliczony
                            {
                                std::string cond_str;
                                char *temp_name;
                                // IF a < 3 ---> Temp := 3; IF a < Temp ...
                                if($2.identifier_type == I_NUM) // jezeli liczba to tworzymy zmienna tymczasowa
                                {
                                    temp_name = create_add_temp_var();
                                    cond_str = std::string(":= ") + std::string(temp_name) + std::string(" ") +\
                                    create_name_string($2.identifier_type, $2.name, $2.ival, $2.name_pos);
                                    code.push_back(cond_str);
                                    $2.identifier_type = I_VARIABLE;
                                    $2.name = temp_name;

                                }
                                if($2.value2_iden_type == I_NUM) // jezeli liczba to tworzymy zmienna tymczasowa
                                {
                                    temp_name = create_add_temp_var();
                                    cond_str = std::string(":= ") + std::string(temp_name) + std::string(" ") +\
                                    create_name_string($2.value2_iden_type, $2.value2_name, $2.value2_ival, $2.value2_name_pos);
                                    code.push_back(cond_str);
                                    $2.value2_iden_type = I_VARIABLE;
                                    $2.value2_name = temp_name;
                                }

                                std::string comm = std::string("IF ");
                                comm += negate_operator($2.op) + std::string(" "); // dodawanie operatora
                                comm += create_name_string($2.identifier_type, $2.name, $2.ival, $2.name_pos) + std::string(" ");
                                comm += create_name_string($2.value2_iden_type, $2.value2_name, $2.value2_ival, $2.value2_name_pos);

                                // najpierw dodajemy etykiete poczatku petli
                                std::string label_start = gen_label();
                                label_list.pop_back();

                                code.push_back(label_start); // etykieta poczatku petli
                                //code.push_back(comm);        // warunek
                                comm += std::string(" GOTO ") + gen_label(); // najpierw pushujemy skok poza petle
                                label_list.push_back(label_start);         // potem skok wewnatrz petli
                                code.push_back(comm);        // skok warunku
                            }

                        }
DO commands ENDWHILE
                        {
                            std::string comm = std::string("GOTO ") + label_list.back(); // skok do warunku petli
                            label_list.pop_back();
                            code.push_back(comm);

                            comm = label_list.back();   // etykieta za petla
                            label_list.pop_back();
                            code.push_back(comm);

                        }

| FOR PIDENTIFIER FROM value TO value
                        {
                            if(check_uniq_tab_sym($2.name)) // jezeli PID nie istnieje, dodajemy,
                            {
                                Record *record = create_record(1, TYPE_VAR);
                                record->is_iterator = true;
                                record->is_initialized = true;
                                tab_sym[$2.name] = record;
                            }
                            else if(!check_used_tab_sym($2.name)) // lub jesli istnieje, ale nie jest uzywany, tzn. ze byl kiedys iteratorem ale skonczyl sie jego zakres waznosci
                            {
                                Record *record = tab_sym[$2.name];
                                record->is_used = true;
                                record->is_initialized = true;
                            }
                            else // redeklaracja, blad
                            {   ss.clear();
                                ss.str("");
                                ss << num_lines;
                                std::string er = std::string("linia ") + ss.str() + std::string(": redeklaracja iteratora.");
                                errors.push_back(er);
                            }
                            // for i from a to b, potrzebujemy tylko zmiennej tymczasowej b
                            // := pid value1

                            std::string comm = std::string(":= ");
                            comm += std::string($2.name) + std::string(" ") + create_name_string($4.identifier_type, $4.name, $4.ival, $4.name_pos);
                            code.push_back(comm);


                            // drugi iterator - licznik wykonan petli, iter_pom := a - b; potem iter_pom += 1; wiec bedzie mozna zamienic na INC iter_pom
                            char *temp_iter = create_add_temp_var();
                            char *temp_sub_b;


                             if($4.identifier_type == I_NUM && $6.identifier_type != I_NUM) // a:liczba, b:zmienna, sprowadza sie do iter_pom := iter_pom - liczba;
                             // jak za duza liczba to nie warto robic decrease'a potem w odejmowaniu
                            {   // temp := a; temp_iter := b - a;
                                if($4.ival > DEC_TRESHOLD_SAME_VAR) // powyzej tego nie warto DEC robic
                                {
                                    temp_sub_b = create_add_temp_var();
                                    comm = std::string(":= ") + std::string(temp_sub_b) + std::string(" ") + create_name_string($4.identifier_type, $4.name, $4.ival, $4.name_pos);
                                    code.push_back(comm); // temp := a;

                                    comm = std::string("+ "); // iter_pom := b + 1;
                                    comm += std::string(temp_iter) + std::string(" ") + create_name_string($6.identifier_type, $6.name, $6.ival, $6.name_pos) + std::string(" 1");
                                    code.push_back(comm);

                                    comm = std::string("- "); // iter_pom := iter_pom - temp;
                                    comm += std::string(temp_iter) + std::string(" ") + std::string(temp_iter) + std::string(" ") + std::string(temp_sub_b);
                                    code.push_back(comm);
                                }
                                else // tu sie oplaca robic DEC
                                {
                                    comm = std::string("+ "); // iter_pom := b + 1;
                                    comm += std::string(temp_iter) + std::string(" ") + create_name_string($6.identifier_type, $6.name, $6.ival, $6.name_pos) + std::string(" 1");
                                    code.push_back(comm);

                                    comm = std::string("- "); // iter_pom := iter_pom - a(liczba);
                                    comm += std::string(temp_iter) + std::string(" ") + std::string(temp_iter) + std::string(" ") +\
                                    create_name_string($4.identifier_type, $4.name, $4.ival, $4.name_pos);
                                    code.push_back(comm);
                                }
                            }
                            else if($4.identifier_type == I_NUM && $6.identifier_type == I_NUM) // a:liczba b:liczba
                            {
                                long long int number = std::max((long long int)0, $6.ival - $4.ival + 1);
                                ss.clear();
                                ss.str("");
                                ss << number;
                                comm = std::string(":= ") + std::string(temp_iter) + std::string(" ") + ss.str();
                                code.push_back(comm);
                            }
                            else if($6.identifier_type == I_NUM) // b:liczba a:zmienna
                            {
                                long long int number = $6.ival + 1;
                                ss.clear();
                                ss.str("");
                                ss << number;
                                comm = std::string("- ");
                                comm += std::string(temp_iter) + std::string(" ") + ss.str() + std::string(" ") +\
                                create_name_string($4.identifier_type, $4.name, $4.ival, $4.name_pos);
                                code.push_back(comm);
                            }
                            else // a:zmienna b:zmienna
                            { // iter_pom := b + 1; iter_pom := iter_pom - a;
                                comm = std::string("+ ");
                                comm += std::string(temp_iter) + std::string(" ") + create_name_string($6.identifier_type, $6.name, $6.ival, $6.name_pos) + std::string(" 1");
                                code.push_back(comm);
                                comm = std::string("- ");
                                comm += std::string(temp_iter) + std::string(" ") + std::string(temp_iter) + std::string(" ") +\
                                create_name_string($4.identifier_type, $4.name, $4.ival, $4.name_pos);
                                code.push_back(comm);
                            }

                            // label poczatek
                            std::string label_finish = gen_label(); // generuje + wstawia na liste etykiet
                            std::string label_start = gen_label(); // generuje + wstawia na liste etykiet

                            code.push_back(std::string("Z ") + std::string(temp_iter)); // ETYKIETA ZALADUJ, ladujemy adres iteratora pomocniczego do rejestru przed petla,
                            //bo na koncu dekrementujemy iterator wiec dalej bedzie w rejestrze, wiec nie oplaca sie go znowu tam ladowac
                            code.push_back(label_start); // etykieta poczatku petli

                            // IC iter_pom GOTO label_finish
                            comm = std::string("IC ") + std::string(temp_iter) + std::string(" GOTO ") + label_finish;
                            code.push_back(comm);
                            //label_list.push_back(std::string(temp_name)); // wstawia tymczasowa value2 na liste etykiet
                            label_list.push_back(std::string($2.name)); // wstawiamy na liste etykiet nazwe PIDENTIFIER,
                            // bo bedzie potem potrzebna do inkrementacji pid := pid + 1
                            label_list.push_back(std::string(temp_iter)); // pomocniczy iterator
                        }
DO commands ENDFOR
                        {
                            std::string iter_pom = label_list.back();
                            label_list.pop_back(); // pop iter_pom




                            // iter_zwykly -= 1;
                            std::string comm = std::string("+ ");
                            comm += label_list.back() + std::string(" ") + label_list.back() + std::string(" 1");
                            code.push_back(comm);

                            comm = std::string("- ");
                            comm += iter_pom + std::string(" ") + iter_pom + std::string(" 1");
                            code.push_back(comm);

                            Record *rec = tab_sym[strdup(label_list.back().c_str())];
                            rec->is_used = false;
                            rec->is_initialized = false;
                            label_list.pop_back(); // pop PID

                            // jump label_start, na poczatek petli
                            comm = std::string("JUMP ") + label_list.back();
                            code.push_back(comm);
                            label_list.pop_back(); // pop label_start

                            comm = label_list.back();
                            label_list.pop_back();
                            code.push_back(comm);
                        }

| FOR PIDENTIFIER FROM value DOWNTO value
                        {
                            if(check_uniq_tab_sym($2.name)) // jezeli PID nie istnieje, dodajemy
                            {
                                Record *record = create_record(1, TYPE_VAR);
                                record->is_iterator = true;
                                record->is_initialized = true;
                                tab_sym[$2.name] = record;
                            }
                            else if(!check_used_tab_sym($2.name)) // lub jesli istnieje, ale nie jest uzywany, tzn. ze byl kiedys iteratorem ale skonczyl sie jego zakres waznosci
                            {
                                Record *record = tab_sym[$2.name];
                                record->is_used = true;
                                record->is_initialized = true;
                            }
                            else // redeklaracja, blad
                            {   ss.clear();
                                ss.str("");
                                ss << num_lines;
                                std::string er = std::string("linia ") + ss.str() + std::string(": redeklaracja iteratora.");
                                errors.push_back(er);
                            }
                            // for i from a to b, potrzebujemy tylko zmiennej tymczasowej b

                            // := pid value1
                            std::string comm = std::string(":= ");
                            comm += std::string($2.name) + std::string(" ") + create_name_string($4.identifier_type, $4.name, $4.ival, $4.name_pos);
                            code.push_back(comm);

                            // drugi iterator - licznik wykonan petli, iter_pom := a - b; potem iter_pom += 1; wiec bedzie mozna zamienic na INC iter_pom
                            char *temp_iter = create_add_temp_var();
                            char *temp_sub_b;


                             if($6.identifier_type == I_NUM && $4.identifier_type != I_NUM) // a:liczba, b:zmienna, sprowadza sie do iter_pom := iter_pom - liczba;
                             // jak za duza liczba to nie warto robic decrease'a potem w odejmowaniu
                            {   // temp := a; temp_iter := b - a;
                                if($6.ival > DEC_TRESHOLD_SAME_VAR) // powyzej tego nie warto DEC robic
                                {
                                    temp_sub_b = create_add_temp_var();
                                    comm = std::string(":= ") + std::string(temp_sub_b) + std::string(" ") + create_name_string($6.identifier_type, $6.name, $6.ival, $6.name_pos);
                                    code.push_back(comm); // temp := a;

                                    comm = std::string("+ "); // iter_pom := b + 1;
                                    comm += std::string(temp_iter) + std::string(" ") + create_name_string($4.identifier_type, $4.name, $4.ival, $4.name_pos) + std::string(" 1");
                                    code.push_back(comm);

                                    comm = std::string("- "); // iter_pom := iter_pom - temp;
                                    comm += std::string(temp_iter) + std::string(" ") + std::string(temp_iter) + std::string(" ") + std::string(temp_sub_b);
                                    code.push_back(comm);
                                }
                                else // tu sie oplaca robic DEC
                                {
                                    comm = std::string("+ "); // iter_pom := b + 1;
                                    comm += std::string(temp_iter) + std::string(" ") + create_name_string($4.identifier_type, $4.name, $4.ival, $4.name_pos) + std::string(" 1");
                                    code.push_back(comm);

                                    comm = std::string("- "); // iter_pom := iter_pom - a(liczba);
                                    comm += std::string(temp_iter) + std::string(" ") + std::string(temp_iter) + std::string(" ") +\
                                    create_name_string($6.identifier_type, $6.name, $6.ival, $6.name_pos);
                                    code.push_back(comm);
                                }
                            }
                            else if($4.identifier_type == I_NUM && $6.identifier_type == I_NUM) // a:liczba b:liczba
                            {
                                long long int number = std::max((long long int)0, $4.ival - $6.ival + 1);
                                ss.clear();
                                ss.str("");
                                ss << number;
                                comm = std::string(":= ") + std::string(temp_iter) + std::string(" ") + ss.str();
                                code.push_back(comm);
                            }
                            else if($4.identifier_type == I_NUM) // b:liczba a:zmienna
                            {
                                long long int number = $4.ival + 1;
                                ss.clear();
                                ss.str("");
                                ss << number;
                                comm = std::string("- ");
                                comm += std::string(temp_iter) + std::string(" ") + ss.str() + std::string(" ") +\
                                create_name_string($6.identifier_type, $6.name, $6.ival, $6.name_pos);
                                code.push_back(comm);
                            }
                            else // a:zmienna b:zmienna
                            { // iter_pom := b + 1; iter_pom := iter_pom - a;
                                comm = std::string("+ ");
                                comm += std::string(temp_iter) + std::string(" ") + create_name_string($4.identifier_type, $4.name, $4.ival, $4.name_pos) + std::string(" 1");
                                code.push_back(comm);
                                comm = std::string("- ");
                                comm += std::string(temp_iter) + std::string(" ") + std::string(temp_iter) + std::string(" ") +\
                                create_name_string($6.identifier_type, $6.name, $6.ival, $6.name_pos);
                                code.push_back(comm);
                            }

                            // label poczatek
                            std::string label_finish = gen_label(); // generuje + wstawia na liste etykiet
                            std::string label_start = gen_label(); // generuje + wstawia na liste etykiet

                            code.push_back(std::string("Z ") + std::string(temp_iter)); // ETYKIETA ZALADUJ, ladujemy adres iteratora pomocniczego do rejestru przed petla,
                            //bo na koncu dekrementujemy iterator wiec dalej bedzie w rejestrze, wiec nie oplaca sie go znowu tam ladowac
                            code.push_back(label_start); // etykieta poczatku petli

                            // IC iter_pom GOTO label_finish
                            comm = std::string("IC ") + std::string(temp_iter) + std::string(" GOTO ") + label_finish;
                            code.push_back(comm);
                            //label_list.push_back(std::string(temp_name)); // wstawia tymczasowa value2 na liste etykiet
                            label_list.push_back(std::string($2.name)); // wstawiamy na liste etykiet nazwe PIDENTIFIER,
                            // bo bedzie potem potrzebna do inkrementacji pid := pid + 1
                            label_list.push_back(std::string(temp_iter)); // pomocniczy iterator
                        }
DO commands ENDFOR
                        {   /*
                            char *temp_name = create_temp_var();
                            Record *record = create_record(1, TYPE_VAR);
                            record->is_initialized = true;
                            tab_sym[temp_name] = record;
                            std::string comm = std::string(":= ");
                            comm += create_name_string(I_VARIABLE, temp_name, 0, NULL) + std::string(" 1"); // temp := 1
                            code.push_back(comm); */

                            // pobieramy nazwe pomocniczego iteratora, iter_pom -= 1;

                            std::string iter_pom = label_list.back();
                            label_list.pop_back(); // pop iter_pom

                            // iter_zwykly -= 1;
                            std::string comm = std::string("- ");
                            comm += label_list.back() + std::string(" ") + label_list.back() + std::string(" 1");
                            code.push_back(comm);

                            comm = std::string("- ");
                            comm += iter_pom + std::string(" ") + iter_pom + std::string(" 1");
                            code.push_back(comm);

                            Record *rec = tab_sym[strdup(label_list.back().c_str())];
                            rec->is_used = false;
                            rec->is_initialized = false;
                            label_list.pop_back(); // pop PID

                            // jump label_start, na poczatek petli
                            comm = std::string("JUMP ") + label_list.back();
                            code.push_back(comm);
                            label_list.pop_back(); // pop label_start

                            comm = label_list.back();
                            label_list.pop_back();
                            code.push_back(comm);
                        }
| READ identifier SEM
                        {
                            std::string comm = std::string("READ ") + create_name_string($2.identifier_type, $2.name, $2.ival, $2.name_pos);
                            code.push_back(comm);

                            if(check_tab_sym($2.name)) // zmienna istnieje
                            {
                                Record *record = tab_sym[$2.name];
                                record->is_initialized = true;
                            }
                        }
| WRITE value SEM
                        {
                            check_var_init($2.name);
                            std::string comm = std::string("WRITE ") + create_name_string($2.identifier_type, $2.name, $2.ival, $2.name_pos);
                            code.push_back(comm);
                        }
| SKIP SEM
                        {
                            code.push_back(std::string("SKIP"));
                        }
;

expression:
value
                        {
                            $$.name = $1.name;
                            $$.ival = $1.ival;
                            $$.name_pos = $1.name_pos;
                            $$.identifier_type = $1.identifier_type;

                            $$.second_value = false;
                            check_var_init($1.name);

                        }
| value ADD value
                        {
                            $$.name = $1.name;
                            $$.ival = $1.ival;
                            $$.name_pos = $1.name_pos;
                            $$.identifier_type = $1.identifier_type;

                            $$.second_value = true;
                            $$.value2_name = $3.name;
                            $$.value2_ival = $3.ival;
                            $$.value2_name_pos = $3.name_pos;
                            $$.value2_iden_type = $3.identifier_type;
                            $$.op = $2.name;

                            check_var_init($1.name);
                            check_var_init($3.name);

                            if($1.identifier_type == I_NUM && $3.identifier_type == I_NUM)
                            {
                                $$.second_value = false;
                                $$.ival = $$.ival + $$.value2_ival; // liczymy nowa wartosc
                                $$.identifier_type = I_NUM;
                            }

                        }
| value SUB value
                        {
                            $$.name = $1.name;
                            $$.ival = $1.ival;
                            $$.name_pos = $1.name_pos;
                            $$.identifier_type = $1.identifier_type;

                            $$.second_value = true;
                            $$.value2_name = $3.name;
                            $$.value2_ival = $3.ival;
                            $$.value2_name_pos = $3.name_pos;
                            $$.value2_iden_type = $3.identifier_type;
                            $$.op = $2.name;

                            check_var_init($1.name);
                            check_var_init($3.name);

                            if($1.identifier_type == I_NUM && $3.identifier_type == I_NUM)
                            {
                                $$.second_value = false;
                                $$.ival = std::max((long long int)0, $$.ival - $$.value2_ival); // liczymy nowa wartosc
                                $$.identifier_type = I_NUM;
                            }

                        }
| value MULT value
                        {
                            $$.name = $1.name;
                            $$.ival = $1.ival;
                            $$.name_pos = $1.name_pos;
                            $$.identifier_type = $1.identifier_type;

                            $$.second_value = true;
                            $$.value2_name = $3.name;
                            $$.value2_ival = $3.ival;
                            $$.value2_name_pos = $3.name_pos;
                            $$.value2_iden_type = $3.identifier_type;
                            $$.op = $2.name;

                            check_var_init($1.name);
                            check_var_init($3.name);

                            if($1.identifier_type == I_NUM && $3.identifier_type == I_NUM)
                            {
                                $$.second_value = false;
                                $$.ival = $$.ival * $$.value2_ival; // liczymy nowa wartosc
                                $$.identifier_type = I_NUM;
                            }

                        }
| value DIV value
                        {
                                $$.name = $1.name;
                                $$.ival = $1.ival;
                                $$.name_pos = $1.name_pos;
                                $$.identifier_type = $1.identifier_type;

                                $$.second_value = true;
                                $$.value2_name = $3.name;
                                $$.value2_ival = $3.ival;
                                $$.value2_name_pos = $3.name_pos;
                                $$.value2_iden_type = $3.identifier_type;
                                $$.op = $2.name;

                                check_var_init($1.name);
                                check_var_init($3.name);

                                if($1.identifier_type == I_NUM && $3.identifier_type == I_NUM)
                                {
                                    $$.second_value = false;
                                    if($$.value2_ival == 0)
                                        $$.ival = 0;
                                    else
                                        $$.ival = $$.ival / $$.value2_ival; // liczymy nowa wartosc

                                    $$.identifier_type = I_NUM;
                                }

                        }
| value MOD value
                        {
                                $$.name = $1.name;
                                $$.ival = $1.ival;
                                $$.name_pos = $1.name_pos;
                                $$.identifier_type = $1.identifier_type;

                                $$.second_value = true;
                                $$.value2_name = $3.name;
                                $$.value2_ival = $3.ival;
                                $$.value2_name_pos = $3.name_pos;
                                $$.value2_iden_type = $3.identifier_type;
                                $$.op = $2.name;

                                check_var_init($1.name);
                                check_var_init($3.name);

                                if($1.identifier_type == I_NUM && $3.identifier_type == I_NUM)
                                {
                                    $$.second_value = false;
                                    if($$.value2_ival == 0)
                                        $$.ival = 0;
                                    else
                                        $$.ival = $$.ival % $$.value2_ival; // liczymy nowa wartosc
                                    $$.identifier_type = I_NUM;
                                }
                        }
;

condition:
value EQ value
                        {
                            $$.name = $1.name;
                            $$.ival = $1.ival;
                            $$.name_pos = $1.name_pos;
                            $$.identifier_type = $1.identifier_type;

                            $$.second_value = true;
                            $$.value2_name = $3.name;
                            $$.value2_ival = $3.ival;
                            $$.value2_name_pos = $3.name_pos;
                            $$.value2_iden_type = $3.identifier_type;
                            $$.op = $2.name;

                            check_var_init($1.name);
                            check_var_init($3.name);

                            if($1.identifier_type == I_NUM && $3.identifier_type == I_NUM)
                            {
                                $$.second_value = false;
                                if($$.ival == $$.value2_ival)
                                    $$.ival = 1;
                                else
                                    $$.ival = 0;

                                $$.identifier_type = I_NUM;
                            }
                        }
| value NE value
                        {
                            $$.name = $1.name;
                            $$.ival = $1.ival;
                            $$.name_pos = $1.name_pos;
                            $$.identifier_type = $1.identifier_type;

                            $$.second_value = true;
                            $$.value2_name = $3.name;
                            $$.value2_ival = $3.ival;
                            $$.value2_name_pos = $3.name_pos;
                            $$.value2_iden_type = $3.identifier_type;
                            $$.op = $2.name;

                            check_var_init($1.name);
                            check_var_init($3.name);

                            if($1.identifier_type == I_NUM && $3.identifier_type == I_NUM)
                            {
                                $$.second_value = false;
                                if($$.ival != $$.value2_ival)
                                    $$.ival = 1;
                                else
                                    $$.ival = 0;

                                $$.identifier_type = I_NUM;
                            }

                        }
| value LT value
                        {
                            $$.name = $1.name;
                            $$.ival = $1.ival;
                            $$.name_pos = $1.name_pos;
                            $$.identifier_type = $1.identifier_type;

                            $$.second_value = true;
                            $$.value2_name = $3.name;
                            $$.value2_ival = $3.ival;
                            $$.value2_name_pos = $3.name_pos;
                            $$.value2_iden_type = $3.identifier_type;
                            $$.op = $2.name;

                            check_var_init($1.name);
                            check_var_init($3.name);

                            if($1.identifier_type == I_NUM && $3.identifier_type == I_NUM)
                            {
                                $$.second_value = false;
                                if($$.ival < $$.value2_ival)
                                    $$.ival = 1;
                                else
                                    $$.ival = 0;

                                $$.identifier_type = I_NUM;
                            }

                        }
| value GT value
                        {
                            $$.name = $1.name;
                            $$.ival = $1.ival;
                            $$.name_pos = $1.name_pos;
                            $$.identifier_type = $1.identifier_type;

                            $$.second_value = true;
                            $$.value2_name = $3.name;
                            $$.value2_ival = $3.ival;
                            $$.value2_name_pos = $3.name_pos;
                            $$.value2_iden_type = $3.identifier_type;
                            $$.op = $2.name;

                            check_var_init($1.name);
                            check_var_init($3.name);

                            if($1.identifier_type == I_NUM && $3.identifier_type == I_NUM)
                            {
                                $$.second_value = false;
                                if($$.ival > $$.value2_ival)
                                    $$.ival = 1;
                                else
                                    $$.ival = 0;

                                $$.identifier_type = I_NUM;
                            }

                        }
| value LE value
                        {
                            $$.name = $1.name;
                            $$.ival = $1.ival;
                            $$.name_pos = $1.name_pos;
                            $$.identifier_type = $1.identifier_type;

                            $$.second_value = true;
                            $$.value2_name = $3.name;
                            $$.value2_ival = $3.ival;
                            $$.value2_name_pos = $3.name_pos;
                            $$.value2_iden_type = $3.identifier_type;
                            $$.op = $2.name;

                            check_var_init($1.name);
                            check_var_init($3.name);

                            if($1.identifier_type == I_NUM && $3.identifier_type == I_NUM)
                            {
                                $$.second_value = false;
                                if($$.ival <= $$.value2_ival)
                                    $$.ival = 1;
                                else
                                    $$.ival = 0;

                                $$.identifier_type = I_NUM;
                            }

                        }
| value GE value
                        {
                            $$.name = $1.name;
                            $$.ival = $1.ival;
                            $$.name_pos = $1.name_pos;
                            $$.identifier_type = $1.identifier_type;

                            $$.second_value = true;
                            $$.value2_name = $3.name;
                            $$.value2_ival = $3.ival;
                            $$.value2_name_pos = $3.name_pos;
                            $$.value2_iden_type = $3.identifier_type;
                            $$.op = $2.name;

                            check_var_init($1.name);
                            check_var_init($3.name);

                            if($1.identifier_type == I_NUM && $3.identifier_type == I_NUM)
                            {
                                $$.second_value = false;
                                if($$.ival >= $$.value2_ival)
                                    $$.ival = 1;
                                else
                                    $$.ival = 0;

                                $$.identifier_type = I_NUM;
                            }
                        }
;

value:
NUM                     {

                             $$.ival = $1.ival;
                             $$.identifier_type = I_NUM;

                        }
| identifier
                        {
                             $$.name = $1.name;
                             $$.name_pos = $1.name_pos;
                             $$.ival = $1.ival;
                             $$.identifier_type = $1.identifier_type;
                        }
;

identifier:
PIDENTIFIER
                        {
                            $$.name = $1.name;
                            $$.identifier_type = I_VARIABLE;

                            if(!declare_var) // jezeli minal czas deklaracji zmiennych
                            {
                                if(check_var_exists($1.name)) // sprawdz czy zmienna istnieje
                                    check_var_correct_use($1.name, $$.identifier_type);
                            }


                        }
| PIDENTIFIER L_BRACKET PIDENTIFIER R_BRACKET
                        {
                             $$.name = $1.name;
                             $$.name_pos = $3.name;
                             $$.identifier_type = I_ARR_VAR;

                             if(!declare_var) // jezeli minal czas deklaracji zmiennych
                             {
                                 if(check_var_exists($1.name)) // sprawdz czy zmienna istnieje
                                     check_var_correct_use($1.name, $$.identifier_type);
                                 if(check_var_exists($3.name)) // sprawdz czy zmienna istnieje
                                 {
                                     check_var_correct_use($3.name, I_VARIABLE);
                                     check_var_init($3.name);
                                 }
                             }

                        }
| PIDENTIFIER L_BRACKET NUM R_BRACKET
                        {
                             $$.name = $1.name;
                             $$.ival = $3.ival;
                             $$.identifier_type = I_ARR_NUM;

                             if(!declare_var) // jezeli minal czas deklaracji zmiennych
                             {
                                 if(check_var_exists($1.name)) // sprawdz czy zmienna istnieje
                                 {
                                     check_var_correct_use($1.name, $$.identifier_type);
                                     check_var_size($1.name, $3.ival);
                                 }
                             }
                        }
;


%%




/* Called by yyparse on error.  */
void yyerror (char const *s)
{
      std::string comm;
      ss.clear();
      ss.str("");
      if(declare_var)
        ss << num_lines + 2;
      else
        ss << num_lines;
      if(error_zlyznak)
        comm = std::string("linia ") + ss.str() + std::string(": nierozpoznany napis");
      else
        comm = std::string("linia ") + ss.str() + std::string(": blad gramatyczny");
      errors.push_back(comm);
}


int main( int argc, char **argv )
{
        ++argv, --argc;  /* skip over program name */
        if ( argc > 0 )
        {
                yyin = fopen( argv[0], "r" );
        }
        else
        {
                yyin = stdin;
        }

        // parse through the input until there is no more:
    	  //do {
    		yyparse();
    	 // } while (!feof(yyin));
         bool error = false;

         std::vector<std::string>::iterator it;
         if(!warnings.empty())
         {  error = true;
             std::cout << "WARNINGS:" << std::endl;
             it = warnings.begin();
             while(it != warnings.end() )
             {
                 std::cout << *it << std::endl;
                 it++;
             }
         }

         if(!errors.empty())
         {  error = true;
             std::cout << "ERRORS:" << std::endl;
             it = errors.begin();
             while(it != errors.end())
             {
                 std::cout << *it << std::endl;
                 it++;
             }
         }
/*
         std::cout << "CODE before:" << std::endl;
         it = code.begin();
         while(it != code.end())
         {
             std::cout << *it << std::endl;
             it++;
         }
*/
        // assign_memory();

        if(!error)
        {
             //correct_jumps_to_jumps_labels(code);

             if(WYPISZ)
             {
                 std::cout << "CODE:" << std::endl;
                 it = code.begin();
                 while(it != code.end())
                 {
                     std::cout << *it << std::endl;
                     it++;
                 }
             }
             assign_memory();

             std::list<std::string> ass = convert_to_assembler(code, tab_sym);
             ass.push_back(std::string("HALT"));

             correct_assembler_labels(ass);

             std::list<std::string>::iterator it_ass;
             it_ass = ass.begin();
             while(it_ass != ass.end())
             {
                 std::cout << *it_ass << std::endl;
                 it_ass++;
             }

         }


    //    printf("\nliczba linijek %d", num_lines);
}
