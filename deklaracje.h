#ifndef DEKL_H
#define DEKL_H

/* rekord w tablicy symboli */
typedef struct Record
{
    bool is_initialized; // wartosc wczytywana w kodzie programu
    bool type; // typ zmiennej: 0 - zmienna, 1 - tablica
    long long int size; // wielkosc zadeklarowanej tablicy
    bool is_alive; // czy zmienna jest zywa, czy nie
    bool is_iterator; // jezeli zmienna > 0 to znaczy ze jest iteratorem i nie mozna jej modyfikowac
    long long int mem_addr; // adres pamieci w maszynie rejestrowej
    bool is_used; // true jezeli zmienna to iterator i jest dodany do tablicy rekordow i aktualnie wykorzystywany
}Record;

/* porownywanie w std::map */
    struct cmp_str
    {
       bool operator()(char *a, char *b)
       {
          return strcmp(a, b) < 0;
       }
    };

#endif
