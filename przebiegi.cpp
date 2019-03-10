
#include "przebiegi.h"
#include "deklaracje.h"
#define DEB 0
static long long int label_count_cond = 0;

/* generuje etykiete w kodzie instrukcji porownywania, nazwa labela: C + label_count_cond */
std::string gen_label_in_cond()
{
    std::stringstream ss;
    std::string comm = std::string("F");
    ss.clear();
    ss.str("");
    ss << label_count_cond;
    label_count_cond++;
    comm += ss.str();
    return comm;
}

void correct_jumps_to_jumps_labels(std::vector<std::string> &code)
{
    std::map<std::string, long long int> reference; // liczba odniesien do danej etykiety
    std::map<std::string, long long int>::iterator ref_it;
    std::map<std::string, std::list<long long int> > label_line_number; // lista numerow komorek z dana etykieta goto
    std::map<std::string, std::list<long long int> >::iterator label_line_number_it;
    std::map<std::string, std::list<long long int> >::iterator label_line_number_it_pom;

    std::stringstream ss;
    std::string buffer;
    std::list<long long int> lista;
    std::list<long long int>::iterator lista_it;

    std::vector<std::string>::iterator it = code.begin();
    long long int line_num = 0;
    // etap 1. inicjalizacja map
    while(it != code.end())
    {
        if((*it)[0] == 'G' || (*it)[0] == 'I') // instrukcja GOTO lub IF (condition) GOTO
        {
            //ss.str("");
            ss.clear();
            ss.str(*it); // wstaw string do stringstreama
            while(ss >> buffer) // szukamy nazwy etykiety
            {
                if(buffer[0] == 'E') // etykieta
                {
                    reference[buffer] = 1;
                    if(!lista.empty()) // czyszczenie listy pomocniczej
                        lista.pop_back(); // moze byc maksymalnie jeden element, bo najpierw etykiety sa unikalne
                    lista.push_back(line_num);
                    label_line_number[buffer] = lista;
                    break;
                }
            }
        }
        it++;
        line_num++;
    }

    // etap 2. algorytm podmiany etykiet
    std::list<std::string> labels;
    std::list<std::string>::iterator lab_it; // iterator do labels
    long long int num_of_ref;
    it = code.begin();
    while(it != code.end())
    {
        while(it != code.end() && (*it)[0] == 'E')
        {
            ss.clear();
            ss.str(*it);
            ss >> buffer; // wstawiamy nazwe etykiety do stringstream
            if(reference[buffer] > 0)
            {
                labels.push_back(buffer); // zachowujemy ta etykiete
                it++;
            }
            else // szukamy dalej dobrych etykiet
                it++;
        }
        if(it == code.end()) break;
        else if( (*it)[0] == 'G' ) // czyli po kolejnych etykietach mamy od razu skok gdzie indziej
        {
            ss.clear();
            ss.str(*it);
            ss >> buffer; // usuwamy GOTO
            ss >> buffer; // wstawiamy nazwe etykiety
            lab_it = labels.begin();
            while(lab_it != labels.end())
            {


                label_line_number_it = label_line_number.find( (*lab_it) );

                while(!label_line_number_it->second.empty())
                {
                    ref_it = reference.find( (*lab_it) ); // zmniejszamy ilosc odwolan do danej etykiety
                    ref_it->second--;

                    ref_it = reference.find(buffer); // znajdujemy nowa etykiete
                    ref_it->second++;



                    long long int n = label_line_number_it->second.back(); //
                    std::string s = std::string("GOTO ") + buffer;
                    std::string old_str = code[n];
                    if(old_str[0] == 'G') code[n] = s; // zamieniamy GOTO stare_etyk na GOTO nowa_etyk
                    else // zaczyna sie IF
                    {
                        ss.clear();
                        ss.str(old_str);
                        std::string pom = "";
                        std::string new_code = "";
                        while(ss >> pom)
                        {
                            new_code += pom + std::string(" ");
                            if(pom[0] == 'G') break; // juz prawie cala linie mamy
                        }
                        new_code += buffer;
                        code[n] = new_code;
                    }
                    code[n] = s; // zamieniamy GOTO stare_etyk na GOTO nowa_etyk
                    label_line_number_it->second.pop_back(); // zmniejszamy wiec wyjdziemy kiedys z petli
                    label_line_number_it_pom = label_line_number.find(buffer);
                    label_line_number_it_pom->second.push_back(n);
                }

                lab_it++;
            }
            it++;
        }
        else // inny kod, nie skok
        {
            while(!labels.empty()) labels.pop_back(); // czyscimy liste etykiet
            it++;
        }



        //it++;
    }



/*

    std::map<std::string, long long int>::iterator it2 = reference.begin();
    std::map<std::string, std::list<long long int> >::iterator it3 = label_line_number.begin();
    std::list<long long int>::iterator lit;
    std::cout << "TESTTTTTTTTTTTTTT" << std::endl;
    while(it3 != label_line_number.end())
    {
        lit = it3->second.begin();
        std::cout << it3->first << " ";
        while(lit != it3->second.end())
        {
            std::cout << (*lit) << " ";
            lit++;
        }
        std::cout << std::endl;
        it3++;
    }
    std::cout << "KOOOOOOOOOOOOONIEC" << std::endl;

    while(it2 != reference.end())
    {
        std::cout << it2->first << " " << it2->second << std::endl;
        it2++;
    }
*/
}


void create_number_in_register(std::list<std::string> &assembler, long long int number, int reg)
{
    std::list<long long int> binary;
    std::string buffer;
    std::stringstream ss;

    ss.clear();
    ss.str("");
    ss << reg;
    ss >> buffer;
    std::string shl = std::string("SHL " + buffer);
    std::string inc = std::string("INC " + buffer);

    assembler.push_back(std::string("ZERO ") + buffer);
    if(number == 1) // 1 instukcja mniej, a mianowiscie SHL
        assembler.push_back(inc);
    else
    {
        while(number > 0)
        {
            if(number & 1)
                binary.push_back(1);
            else
                binary.push_back(0);
            number /= 2;
        }

        while(!binary.empty())
        {
            if(binary.back() == 1)
            {
                assembler.push_back(shl);
                assembler.push_back(inc);
            }
            else
                assembler.push_back(shl);

            binary.pop_back();
        }
    }
}

/* tworzy liczbe/adres zmiennej/adres tablicy w podanym rejestrze */
void create_addres_num_in_register(std::list<std::string> &assembler,\
    std::map<char*, Record *, cmp_str> &tab_sym, std::string zmienna, int reg)
{
    std::stringstream ss;
    std::string result;
    long long int number;
    if(zmienna[0] >= '0' && zmienna [0] <= '9') assembler.push_back(std::string("blad create_addres_num_in_register, dodaj stala jako zmienna tymczasowa"));
    /*if(zmienna[0] >= '0' && zmienna [0] <= '9') // czyli liczba
    {
        ss.clear();
        ss.str(zmienna);
        ss >> number;
        create_number_in_register(assembler, number, reg);
    }*/
    //else // zmienna lub tablica
    //{
        ss.clear();
        ss.str(zmienna); // zmienna moze byc typu tablicowego
        std::getline(ss, result, '['); // bierze nazwe zmiennej az do ewentualnego [
        Record *record = tab_sym[strdup(result.c_str())];
        if( std::getline(ss, result, ']') ) // to tablica
        {
            if(result[0] >= '0' && result[0] <= '9') // np. tab[3]
            {
                ss.clear();
                ss.str(result);
                ss >> number;
                number += record->mem_addr;
                create_number_in_register(assembler, number, reg);
            }
            else // np. tab[c], wykorzystuje dodatkowy rejestr - rej. numer 4
            {
                if(reg != 0) // czyli chcemy wytworzyc adres w innym rejestrze niz 0
                {

                    create_number_in_register(assembler, record->mem_addr, reg); // wytworz adres tablicy w rej: reg
                    Record *zm = tab_sym[strdup(result.c_str())];
                    create_number_in_register(assembler, zm->mem_addr, 0); // wytworz adres zmiennej w rej: 0
                    ss.clear();
                    ss.str("");
                    ss << reg;
                    //std::string temp;
                    //ss >> temp;
                    assembler.push_back(std::string("ADD ") + ss.str()); // dodajemy i mamy adres tab[c] w rej: reg

                }
                else // chcemy adres w rejestrze 0
                {
                    create_number_in_register(assembler, record->mem_addr, 4); // wytworz adres tablicy w rej 4
                    Record *zm = tab_sym[strdup(result.c_str())];
                    create_number_in_register(assembler, zm->mem_addr, 0); // wytworz adres zmiennej w rej 0
                    assembler.push_back(std::string("ADD 4"));
                    assembler.push_back(std::string("COPY 4")); // skopiuj adres tab[c] do rej 0
                }
            }
        }
        else // to zmienna
            create_number_in_register(assembler, record->mem_addr, reg);

    //}
}

void code_add(std::list<std::string> &assembler,\
    std::map<char*, Record *, cmp_str> &tab_sym, std::string it)
    {
        std::stringstream ss;
        std::string buffer, result, a, b;
        long long int number;
        ss.clear();
        ss.str(it);
        ss >> buffer; // usuwamy +, zostaje: wynik a b
        ss >> result;
        ss >> a;
        ss >> b;
        if(result == a && b == "1") // czyli instrukcje typu iter := iter + 1;
        {
            create_addres_num_in_register(assembler, tab_sym, result, 0); // adr result w rej. 0
            assembler.push_back(std::string("LOAD 1"));
            assembler.push_back(std::string("INC 1"));
            assembler.push_back(std::string("STORE 1"));
        }
        else if(a[0] >= '0' && a[0] <= '9') // czyli liczba
        {
            ss.clear();
            ss.str(a);
            ss >> number;
            create_number_in_register(assembler, number, 1); // wytworzenie w rej. 1 liczby
            create_addres_num_in_register(assembler, tab_sym, b, 0); // wytworzenie adresu zmiennej b
            assembler.push_back(std::string("ADD 1")); // dodaj
            create_addres_num_in_register(assembler, tab_sym, result, 0); // adres wyniku
            assembler.push_back(std::string("STORE 1")); // zapisz do pamieci
        }
        else if(b[0] >= '0' && b[0] <= '9')
        {
            ss.clear();
            ss.str(b);
            ss >> number;
            create_number_in_register(assembler, number, 1); // wytworzenie w rej. 1 liczby
            create_addres_num_in_register(assembler, tab_sym, a, 0); // wytworzenie adresu zmiennej a
            assembler.push_back(std::string("ADD 1")); // dodaj
            create_addres_num_in_register(assembler, tab_sym, result, 0); // adres wyniku
            assembler.push_back(std::string("STORE 1")); // zapisz do pamieci
        }
        else // obie to zmienne/tablice
        {
            create_addres_num_in_register(assembler, tab_sym, a, 0); // wytworzenie adresu zmiennej a
            assembler.push_back(std::string("LOAD 1")); // zaladuj do rejestru
            create_addres_num_in_register(assembler, tab_sym, b, 0); // wytworzenie adresu zmiennej b
            assembler.push_back(std::string("ADD 1")); // dodaj
            create_addres_num_in_register(assembler, tab_sym, result, 0); // adres wyniku
            assembler.push_back(std::string("STORE 1")); // zapisz do pamieci
        }
    }

void code_sub(std::list<std::string> &assembler,\
    std::map<char*, Record *, cmp_str> &tab_sym, std::string it)
    {
        std::stringstream ss;
        std::string buffer, result, a, b;
        long long int number;
        ss.clear();
        ss.str(it);
        ss >> buffer; // usuwamy -, zostaje: wynik a b
        ss >> result;
        ss >> a;
        ss >> b;

        if(result == a && (b[0] >= '0' && b[0] <= '9') ) // np. a := a - 5;
        {
            ss.clear();
            ss.str(b);
            ss >> number;
            create_addres_num_in_register(assembler, tab_sym, result, 0); // adr result w rej. 0
            assembler.push_back(std::string("LOAD 1"));
            for(int j=number; j>0; --j)
            {
                assembler.push_back(std::string("DEC 1"));
            }
            assembler.push_back(std::string("STORE 1"));
        }
        else if(b[0] >= '0' && b[0] <= '9') // np. 8 - 5, a - 5,
        {
            if(a[0] >= '0' && a[0] <= '9')
            {
                assembler.push_back(std::string("odejmowanie liczba - liczba")); // potem usunac, bez sensu by bylo.
                /*
                long long int number2;
                ss.clear();
                ss.str(a);
                ss >> number;
                ss.clear();
                ss.str(b);
                ss >> number2;
                number2 = std::max((long long int)0, number - number2);
                create_number_in_register(assembler, number2, 1);
                create_addres_num_in_register(assembler, tab_sym, result, 0); // adres wyniku
                assembler.push_back(std::string("STORE 1")); */
            }
            else // result != a, np: b := a - 5, to DECREASE, bo jezeli sie nie oplaca to zostanie zamieniony w parserze na temp.
            {
                ss.clear();
                ss.str(b);
                ss >> number;
                create_addres_num_in_register(assembler, tab_sym, a, 0);
                assembler.push_back(std::string("LOAD 1"));
                for(int j=number; j>0; --j)
                {
                    assembler.push_back(std::string("DEC 1"));
                }
                create_addres_num_in_register(assembler, tab_sym, result, 0);
                assembler.push_back(std::string("STORE 1"));
            }
        }
        else if(a[0] >= '0' && a[0] <= '9') // czyli liczba; nie ma mozliwosci zeby b byla liczba,
        // bo jest zamieniana na zmienna tymczasowa, aby dalo sie zrobic SUB
        {
            ss.clear();
            ss.str(a);
            ss >> number;
            create_number_in_register(assembler, number, 1); // wytworzenie w rej. 1 liczby
            create_addres_num_in_register(assembler, tab_sym, b, 0); // wytworzenie adresu zmiennej b
            assembler.push_back(std::string("SUB 1")); // dodaj
            create_addres_num_in_register(assembler, tab_sym, result, 0); // adres wyniku
            assembler.push_back(std::string("STORE 1")); // zapisz do pamieci
        }
        else // obie to zmienne/tablice
        {
            create_addres_num_in_register(assembler, tab_sym, a, 0); // wytworzenie adresu zmiennej a
            assembler.push_back(std::string("LOAD 1")); // zaladuj do rejestru
            create_addres_num_in_register(assembler, tab_sym, b, 0); // wytworzenie adresu zmiennej b
            assembler.push_back(std::string("SUB 1")); // odejmij
            create_addres_num_in_register(assembler, tab_sym, result, 0); // adres wyniku
            assembler.push_back(std::string("STORE 1")); // zapisz do pamieci
        }
    }

void code_mult(std::list<std::string> &assembler,\
    std::map<char*, Record *, cmp_str> &tab_sym, std::string it)
    {
        std::stringstream ss;
        std::string result, a, b;
        std::string special_var = "M";

        std::string label_begin = gen_label_in_cond();
        std::string label_end = gen_label_in_cond();
        std::string label_odd = gen_label_in_cond();
        std::string label_b_wieksze = gen_label_in_cond();
        std::string label_koniec_b = gen_label_in_cond();
    //    std::string label_even = gen_label_in_cond();
        ss.clear();
        ss.str(it);
        ss >> result; // usuwamy *
        ss >> result;
        ss >> a; // w a moze byc liczba, bo tak ustawilismy specjalnie w parserze
        ss >> b;
        if(a[0] == '2')
        {
            create_addres_num_in_register(assembler, tab_sym, b, 0);
            assembler.push_back(std::string("LOAD 1"));
            assembler.push_back(std::string("SHL 1")); // * 2
            create_addres_num_in_register(assembler, tab_sym, result, 0);
            assembler.push_back(std::string("STORE 1"));
        }
        else
        {
            if(a[0] >= '0' && a[0] <= '9') // a to liczba
            {
                long long int number;
                ss.clear();
                ss.str(a);
                ss >> number;
                create_number_in_register(assembler, number, 1);
            }
            else // a to zmienna
            {
                create_addres_num_in_register(assembler, tab_sym, a, 0);
                assembler.push_back(std::string("LOAD 1"));
            }
            create_addres_num_in_register(assembler, tab_sym, b, 0); // W 0 REJESTRZE MAMY ADRES B, MOZNA TO WYKORZYSTAC PEWNIE
            assembler.push_back(std::string("SUB 1"));
            assembler.push_back(std::string("JZERO 1 ") + label_b_wieksze); // b_wieksze rowne

    // a wieksze: ladujemy b do dolnego, czyli do 1
            assembler.push_back(std::string("LOAD 1")); // tu mniejsza liczba, b
            assembler.push_back(std::string("ZERO 3"));
            if(a[0] >= '0' && a[0] <= '9') // a to liczba
            {
                long long int number;
                ss.clear();
                ss.str(a);
                ss >> number;
                create_number_in_register(assembler, number, 2);
            }
            else // a to zmienna
            {
                create_addres_num_in_register(assembler, tab_sym, a, 0);
                assembler.push_back(std::string("LOAD 2")); // MAMY W REJ 2 WIEKSZA LICZBE
            }
            create_addres_num_in_register(assembler, tab_sym, special_var, 0);
            assembler.push_back(std::string("STORE 2")); // MAMY W SPECJALNYM REJESTRZE WIEKSZA LICZBE
            assembler.push_back(std::string("JUMP ") + label_koniec_b);
            //mamy



            assembler.push_back(label_b_wieksze);
    // b wieksze: ladujemy wieksze do gornego, czyli do 2
            assembler.push_back(std::string("LOAD 2")); // MAMY W TEJ 2 WIEKSZA LICZBE
            create_addres_num_in_register(assembler, tab_sym, special_var, 0);
            assembler.push_back(std::string("STORE 2")); // MAMY W SPECJALNYM REJESTRZE WIEKSZA LICZBE
            assembler.push_back(std::string("ZERO 3"));
            if(a[0] >= '0' && a[0] <= '9') // a to liczba
            {
                long long int number;
                ss.clear();
                ss.str(a);
                ss >> number;
                create_number_in_register(assembler, number, 1);
            }
            else // a to zmienna
            {
                create_addres_num_in_register(assembler, tab_sym, a, 0);
                assembler.push_back(std::string("LOAD 1")); // MAMY W REJ 1 MNIEJSZA LICZBE
            }
            create_addres_num_in_register(assembler, tab_sym, special_var, 0);
            assembler.push_back(label_koniec_b);
    /*

            assembler.push_back(std::string("ZERO 3")); // WYNIK W 3
            create_addres_num_in_register(assembler, tab_sym, upper, 0); // GORNA W 2
            assembler.push_back(std::string("LOAD 2"));
            create_addres_num_in_register(assembler, tab_sym, lower, 0); // DOLNA W 1
            assembler.push_back(std::string("LOAD 1"));
            create_addres_num_in_register(assembler, tab_sym, special_var, 0); // POMOCNICZY W 0
    */
            assembler.push_back(label_begin);
            assembler.push_back(std::string("JZERO 1 ") + label_end);
            assembler.push_back(std::string("JODD 1 ") + label_odd);
            //assembler.push_back(label_even);
            assembler.push_back(std::string("SHL 2"));
            assembler.push_back(std::string("STORE 2"));
            assembler.push_back(std::string("SHR 1"));
            assembler.push_back(std::string("JUMP ") + label_begin);
            assembler.push_back(label_odd);
            assembler.push_back(std::string("ADD 3"));
            assembler.push_back(std::string("SHL 2"));
            assembler.push_back(std::string("STORE 2"));
            assembler.push_back(std::string("SHR 1"));
            assembler.push_back(std::string("JUMP ") + label_begin);
            assembler.push_back(label_end);
            create_addres_num_in_register(assembler, tab_sym, result, 0);
            assembler.push_back(std::string("STORE 3"));
        }
    }

void code_div(std::list<std::string> &assembler,\
    std::map<char*, Record *, cmp_str> &tab_sym, std::string it, bool zwroc_reszte)
    {
        // Q := N / D;
        // specjalne komorki pamieci dla N oraz D
        std::stringstream ss;
        std::string result, N = "N", D = "D", a, b;



        std::string label_result_0 = gen_label_in_cond();
        std::string label_przygotuj_pamiec = gen_label_in_cond();
        std::string label_koniec_dzielenia = gen_label_in_cond();
        std::string label_koniec = gen_label_in_cond();
    //    std::string label_even = gen_label_in_cond();
        ss.clear();
        ss.str(it);
        ss >> result; // usuwamy /
        ss >> result;
        ss >> a;
        ss >> b;
        if(b[0] == '2' && !zwroc_reszte) // dzielenie przez 2, wiec a musi byc zmienna, inaczej bysmy obliczyli juz wczesniej wynik
        {
            create_addres_num_in_register(assembler, tab_sym, a, 0);
            assembler.push_back(std::string("LOAD 1"));
            assembler.push_back(std::string("SHR 1")); //   dzielenie przez 2
            create_addres_num_in_register(assembler, tab_sym, result, 0);
            assembler.push_back(std::string("STORE 1"));
        }
        else if(b[0] == '2' && zwroc_reszte) // modulo 2, wiec a musi byc zmienna, inaczej bysmy obliczyli juz wczesniej wynik
        {
            std::string label_koniec_modulo = gen_label_in_cond();
            std::string label_skok_na_koniec = gen_label_in_cond();
            create_addres_num_in_register(assembler, tab_sym, a, 0);
            assembler.push_back(std::string("LOAD 1"));
            create_addres_num_in_register(assembler, tab_sym, result, 0);
            assembler.push_back(std::string("JODD 1 ") + label_koniec_modulo); // jezeli nieparzyste to skaczemy
            //jezeli parzyste to wynik to 0
            assembler.push_back(std::string("ZERO 1"));
            assembler.push_back(std::string("STORE 1"));
            assembler.push_back(std::string("JUMP ") + label_skok_na_koniec);
            assembler.push_back(label_koniec_modulo);
            // nieparzyste, wiec wynik to 1
            assembler.push_back(std::string("ZERO 1"));
            assembler.push_back(std::string("INC 1"));
            assembler.push_back(std::string("STORE 1"));
            assembler.push_back(label_skok_na_koniec);
        } 
        else
        {
            if(a[0] == '0' || b[0] == '0') // wynik to 0
            {
                create_addres_num_in_register(assembler, tab_sym, result, 0);
                assembler.push_back(std::string("ZERO 1"));
                assembler.push_back(std::string("STORE 1"));
                assembler.push_back(std::string("JUMP ") + label_koniec);
            }
            else if(a[0] >= '0' && a[0] <= '9')
            {
                create_addres_num_in_register(assembler, tab_sym, b, 0);
                assembler.push_back(std::string("LOAD 2")); // mamy D
                assembler.push_back(std::string("JZERO 2 ") + label_result_0);
                ss.clear();
                ss.str(a);
                long long int number;
                ss >> number;
                create_number_in_register(assembler, number, 1); // mamy N
                assembler.push_back(std::string("JUMP ") + label_przygotuj_pamiec);

                assembler.push_back(label_result_0);
                create_addres_num_in_register(assembler, tab_sym, result, 0);
                assembler.push_back(std::string("STORE 2")); //bylo w rej 2 ZERO wiec je zapisujemy

            }
            else if(b[0] >= '0' && b[0] <= '9')
            {
                create_addres_num_in_register(assembler, tab_sym, a, 0);
                assembler.push_back(std::string("LOAD 1")); // mamy N
                assembler.push_back(std::string("JZERO 1 ") + label_result_0);
                ss.clear();
                ss.str(b);
                long long int number;
                ss >> number;
                create_number_in_register(assembler, number, 2); // mamy D
                assembler.push_back(std::string("JUMP ") + label_przygotuj_pamiec);

                assembler.push_back(label_result_0);
                create_addres_num_in_register(assembler, tab_sym, result, 0);
                assembler.push_back(std::string("STORE 1")); //bylo w rej 1 ZERO wiec je zapisujemy
            }
            else // obie to zmienne
            {
                // sprawdz czy a to 0
                create_addres_num_in_register(assembler, tab_sym, a, 0);
                assembler.push_back(std::string("LOAD 1")); // mamy N
                assembler.push_back(std::string("JZERO 1 ") + label_result_0);
                // sprawdz czy b to 0
                create_addres_num_in_register(assembler, tab_sym, b, 0);
                assembler.push_back(std::string("LOAD 2")); // mamy D
                assembler.push_back(std::string("JZERO 2 ") + label_result_0);
                assembler.push_back(std::string("JUMP ") + label_przygotuj_pamiec);


                assembler.push_back(label_result_0);
                create_addres_num_in_register(assembler, tab_sym, result, 0);
                assembler.push_back(std::string("ZERO 1"));
                assembler.push_back(std::string("STORE 1"));
                assembler.push_back(std::string("JUMP ") + label_koniec);
            }
            // mamy przygotowane wartosci zmiennych w rejestrach 1 i 2, dodajemy je do specjalnych komorek pamieci
            assembler.push_back(label_przygotuj_pamiec);
            create_addres_num_in_register(assembler, tab_sym, N, 0);
            assembler.push_back(std::string("STORE 1"));
            create_addres_num_in_register(assembler, tab_sym, D, 0);
            assembler.push_back(std::string("STORE 2"));

            std::string label_oblicz_zera = gen_label_in_cond();
            std::string label_dopisz_zera = gen_label_in_cond();
            std::string label_zaladuj_D = gen_label_in_cond();
            std::string label_koniec_dopisywania = gen_label_in_cond();
            std::string label_licz_dalej = gen_label_in_cond();
            std::string label_D_wieksze = gen_label_in_cond();


            assembler.push_back(std::string("ZERO 3")); // tu wynik
            assembler.push_back(std::string("ZERO 4")); // tu licznik
            assembler.push_back(std::string("INC 4")); // ilosc shiftow + 1

            assembler.push_back(label_oblicz_zera);
            assembler.push_back(std::string("JZERO 2 ") + label_zaladuj_D);
            assembler.push_back(std::string("SHR 2"));
            assembler.push_back(std::string("SHR 1"));
            assembler.push_back(std::string("JUMP ") + label_oblicz_zera);

            assembler.push_back(label_zaladuj_D);
            //create_addres_num_in_register(assembler, tab_sym, D, 0);
            assembler.push_back(std::string("LOAD 2")); // nadal siedzi adres D w zerowym rejestrze wiec nie trzeba wytwarzac go

            assembler.push_back(label_dopisz_zera);
            assembler.push_back(std::string("JZERO 1 ") + label_koniec_dopisywania);
            assembler.push_back(std::string("SHR 1"));
            assembler.push_back(std::string("SHL 2"));
            assembler.push_back(std::string("INC 4")); // zwieksz licznik
            assembler.push_back(std::string("JUMP ") + label_dopisz_zera);

            assembler.push_back(label_koniec_dopisywania);
        //    create_addres_num_in_register(assembler, tab_sym, D, 0);
            assembler.push_back(std::string("STORE 2")); // uaktualnienie pamieci, // nadal siedzi adres D w zerowym rejestrze wiec nie trzeba wytwarzac go
            // wczytanie uaktualnionego rejestru N
            create_addres_num_in_register(assembler, tab_sym, N, 0);
            assembler.push_back(std::string("LOAD 1"));

            create_addres_num_in_register(assembler, tab_sym, D, 0); // do odejmowania
            assembler.push_back(label_licz_dalej);
            assembler.push_back(std::string("JZERO 4 ") + label_koniec_dzielenia);


            assembler.push_back(std::string("INC 1"));
            assembler.push_back(std::string("SUB 1"));
            assembler.push_back(std::string("JZERO 1 ") + label_D_wieksze);
            assembler.push_back(std::string("DEC 1")); // bo wczesniej byl INC
            assembler.push_back(std::string("DEC 4")); // DEC licznik
            assembler.push_back(std::string("SHL 3")); // wpakowanie 1 do wyniku
            assembler.push_back(std::string("INC 3"));
            // uaktualnienie N
            create_addres_num_in_register(assembler, tab_sym, N, 0);
            assembler.push_back(std::string("STORE 1"));
            // uaktualnienie D
            create_addres_num_in_register(assembler, tab_sym, D, 0);
            assembler.push_back(std::string("SHR 2"));
            assembler.push_back(std::string("STORE 2"));
            assembler.push_back(std::string("JUMP ") + label_licz_dalej);

            assembler.push_back(label_D_wieksze);
            // przywracamy N
            create_addres_num_in_register(assembler, tab_sym, N, 0);
            assembler.push_back(std::string("LOAD 1"));
            assembler.push_back(std::string("SHL 3")); // pakowanie 0 do wyniku
            assembler.push_back(std::string("DEC 4")); // DEC licznik
            create_addres_num_in_register(assembler, tab_sym, D, 0);
            assembler.push_back(std::string("SHR 2"));
            assembler.push_back(std::string("STORE 2"));
            assembler.push_back(std::string("JUMP ") + label_licz_dalej);

            assembler.push_back(label_koniec_dzielenia);
            if(zwroc_reszte)
            {
                create_addres_num_in_register(assembler, tab_sym, result, 0);
                assembler.push_back(std::string("STORE 1")); // reszta znajduje sie w 1 rejestrze
            }
            else
            {
                create_addres_num_in_register(assembler, tab_sym, result, 0);
                assembler.push_back(std::string("STORE 3"));
            }
            assembler.push_back(label_koniec);
        }
    }


void code_assign(std::list<std::string> &assembler,\
    std::map<char*, Record *, cmp_str> &tab_sym, std::string it)
    {
        std::stringstream ss;
        std::string buffer, result, a;
        long long int number;
        ss.clear();
        ss.str(it);
        ss >> buffer; // usuwamy :=, zostaje: wynik a
        ss >> result; // tu nazwa zmiennej(lub tablicy) wyniku
        ss >> a;      // tu liczba lub zmienna

        if(DEB)
            assembler.push_back(std::string("assign ") + result);

        if(a[0] >= '0' && a[0] <= '9') // czyli liczba
        {
            ss.clear();
            ss.str(a);
            ss >> number;
            create_number_in_register(assembler, number, 1); // wytworzenie w rej. nr 1 liczby
            create_addres_num_in_register(assembler, tab_sym, result, 0); // wytworzenie adresu result
            assembler.push_back(std::string("STORE 1")); // zapisz do pamieci
        }
        else // obie to zmienne/tablice
        {
            create_addres_num_in_register(assembler, tab_sym, a, 0); // wytworzenie adresu zmiennej a
            assembler.push_back(std::string("LOAD 1")); // zaladuj do rejestru 1
            create_addres_num_in_register(assembler, tab_sym, result, 0); // wytworzenie result w 0
            assembler.push_back(std::string("STORE 1")); // zapisz do pamieci
        }

    }

void code_cond_less(std::list<std::string> &assembler,\
    std::map<char*, Record *, cmp_str> &tab_sym, std::string a, std::string b, std::string label, bool increment)
    {
        create_addres_num_in_register(assembler, tab_sym, a, 0); // wytworzenie adresu zmiennej a
        assembler.push_back(std::string("LOAD 1")); // zaladuj do rejestru 1
        if(increment)
            assembler.push_back(std::string("INC 1"));
        create_addres_num_in_register(assembler, tab_sym, b, 0);
        assembler.push_back(std::string("SUB 1"));
        assembler.push_back(std::string("JZERO 1 ") + label);
    }

void code_cond_equal(std::list<std::string> &assembler,\
    std::map<char*, Record *, cmp_str> &tab_sym, std::string a, std::string b, std::string label)
    {
        /* equal jezeli a-b = 0 oraz b-a=0, pseudokod: a-b JZERO i C1; JUMP FALSZ; E1: b-a JZERO i SUKCES; FALSZ: */
        // najpierw a-b, w rejestrze number 1 zostaje wynik tej operacji
        std::string label_temp = gen_label_in_cond(); // label do skoku o 1 linijke
        std::string label_temp_false = gen_label_in_cond();
        create_addres_num_in_register(assembler, tab_sym, a, 0); // wytworzenie adresu zmiennej a
        assembler.push_back(std::string("LOAD 1")); // zaladuj do rejestru
        create_addres_num_in_register(assembler, tab_sym, b, 0); // wytworzenie adresu zmiennej b
        assembler.push_back(std::string("SUB 1")); // odejmij
        assembler.push_back(std::string("JZERO 1 ") + label_temp); // skok do etykiety C1

        //przeskocz 1 instrukcje za label, pozniej przy poprawianiu etykiet bedzie zamienione
        assembler.push_back(std::string("JUMP ") + label_temp_false);
        assembler.push_back(label_temp);
        create_addres_num_in_register(assembler, tab_sym, b, 0); // wytworzenie adresu zmiennej b
        assembler.push_back(std::string("LOAD 1")); // zaladuj do rejestru
        create_addres_num_in_register(assembler, tab_sym, a, 0); // wytworzenie adresu zmiennej a
        assembler.push_back(std::string("SUB 1")); // odejmij, w rej. 1: wynik operacji b-a
        assembler.push_back(std::string("JZERO 1 ") + label); // JUMP label_sukces
        assembler.push_back(label_temp_false); // jak nie skok do sukcesu to etykieta FALSE i kod dla FALSE
    }

void code_cond_not_equal(std::list<std::string> &assembler,\
    std::map<char*, Record *, cmp_str> &tab_sym, std::string a, std::string b, std::string label)
    {
        std::string label_temp = gen_label_in_cond();
        std::string label_temp_false = gen_label_in_cond();
        create_addres_num_in_register(assembler, tab_sym, a, 0); // wytworzenie adresu zmiennej a
        assembler.push_back(std::string("LOAD 1")); // zaladuj do rejestru
        create_addres_num_in_register(assembler, tab_sym, b, 0); // wytworzenie adresu zmiennej b
        assembler.push_back(std::string("SUB 1")); // odejmij
        assembler.push_back(std::string("JZERO 1 ") + label_temp); // skok do etykiety C1

        create_addres_num_in_register(assembler, tab_sym, b, 0); // wytworzenie adresu zmiennej b
        assembler.push_back(std::string("LOAD 1")); // zaladuj do rejestru
        create_addres_num_in_register(assembler, tab_sym, a, 0); // wytworzenie adresu zmiennej a
        assembler.push_back(std::string("SUB 1")); // odejmij
        assembler.push_back(std::string("JZERO 1 ") + label); // skok do etykiety SUKCES

        assembler.push_back(label_temp);
        create_addres_num_in_register(assembler, tab_sym, b, 0); // wytworzenie adresu zmiennej b
        assembler.push_back(std::string("LOAD 1")); // zaladuj do rejestru
        create_addres_num_in_register(assembler, tab_sym, a, 0); // wytworzenie adresu zmiennej a
        assembler.push_back(std::string("SUB 1")); // odejmij
        assembler.push_back(std::string("JZERO 1 ") + label_temp_false);
        assembler.push_back(std::string("JUMP ") + label); // JUMP SUKCES
        assembler.push_back(label_temp_false);
    }

void code_if(std::list<std::string> &assembler,\
    std::map<char*, Record *, cmp_str> &tab_sym, std::string it)
    {
        std::stringstream ss;
        std::string a, b, label, cond;
        if(it[1] == 'F') // czyli IF, to zwyczajnie
        {
            ss.clear();
            ss.str(it);
            ss >> cond; // usuwamy IF
            ss >> cond; // mamy warunek
            ss >> a;
            ss >> b;
            ss >> label; // usuwamy GOTO
            ss >> label;

            if(cond == "<")
                code_cond_less(assembler, tab_sym, a, b, label, true);
            else if(cond == ">")
                code_cond_less(assembler, tab_sym, b, a, label, true); // zamiana a,b miejscami
            else if(cond == "<=")
                code_cond_less(assembler, tab_sym, a, b, label, false); // False -> bez INC w kodzie
            else if(cond == ">=")
            {
                if(DEB)
                    assembler.push_back(std::string("cond ") );
                code_cond_less(assembler, tab_sym, b, a, label, false);

            }
            else if(cond == "=")
                code_cond_equal(assembler, tab_sym, a, b, label);
            else if(cond == "<>")
                code_cond_not_equal(assembler, tab_sym, a, b, label);
            else
                assembler.push_back(std::string("blad code_if"));
        }
        else // IC, czyli zliczanie wywolan, pelna instrukcja: IC iter_pom GOTO etykieta
        {
            std::string iter_pom;
            ss.clear();
            ss.str(it);
            ss >> label; // usuwamy IC
            ss >> iter_pom; // mamy iter_pom
            ss >> label; // usuwamy GOTO
            ss >> label; // mamy label
            //create_addres_num_in_register(assembler, tab_sym, iter_pom, 0); // wytworzenie adresu zmiennej iter_pom
            //assembler.push_back(std::string("LOAD 1")); // zaladuj do rej 1
            assembler.push_back(std::string("JZERO 1 ") + label); // jezeli 0 to skocz do etykiety
        }

    }

void code_write(std::list<std::string> &assembler,\
    std::map<char*, Record *, cmp_str> &tab_sym, std::string it)
    {
        std::stringstream ss;
        std::string a, buffer;
        long long int number;
        ss.clear();
        ss.str(it);
        ss >> a; // WRITE
        ss >> a; // value: liczba/zmienna/tablica
        if(a[0] >= '0' && a[0] <= '9') // liczba
        {
            ss.clear();
            ss.str(a);
            ss >> number;
            create_number_in_register(assembler, number, 1);
        }
        else
        {
            if(DEB)
                assembler.push_back(std::string("write ") + a);
            create_addres_num_in_register(assembler, tab_sym, a, 0);
            assembler.push_back(std::string("LOAD 1"));
        }
        assembler.push_back(std::string("PUT 1"));
    }

void code_read(std::list<std::string> &assembler,\
    std::map<char*, Record *, cmp_str> &tab_sym, std::string it)
    {
        std::stringstream ss;
        std::string a, buffer;
        long long int number;
        ss.clear();
        ss.str(it);
        ss >> a; // usuwanie READ
        ss >> a; // zmienna/tablica
        create_addres_num_in_register(assembler, tab_sym, a, 0);
        assembler.push_back(std::string("GET 1"));
        assembler.push_back(std::string("STORE 1"));
    }

std::list<std::string> convert_to_assembler(std::vector<std::string> &code,\
     std::map<char*, Record *, cmp_str> &tab_sym)
{
    std::list<std::string> assembler;
    std::string buffer, result, a, b;
    std::stringstream ss;
    long long int number;
    std::vector<std::string>::iterator it = code.begin();

    for(; it != code.end(); it++)
    {
        if((*it)[0] == 'G') // instrukcja GOTO label_name
        {
            ss.clear();
            ss.str(*it);
            ss >> buffer; // usuwamy GOTO
            ss >> buffer; // wstawiamy nazwe etykiety
            assembler.push_back(std::string("JUMP ") + buffer);
        }
        else if((*it)[0] == '+') // w stringu: + wynik a b
            code_add(assembler, tab_sym, *it);
        else if((*it)[0] == '-')
            code_sub(assembler, tab_sym, *it);
        else if((*it)[0] == '*')
            code_mult(assembler, tab_sym, *it);
        else if((*it)[0] == '/')
            code_div(assembler, tab_sym, *it, false); // flaga ze chcemy otrzymac wynik
        else if((*it)[0] == ':') // czyli przypisanie
            code_assign(assembler, tab_sym, *it);
        else if((*it)[0] == '%')
            code_div(assembler, tab_sym, *it, true); // flaga ze chcemy otrzymac reszte
        else if((*it)[0] == 'I') // instrukcja IF lub instrukcja IC, ktora zlicza liczbe wywolan petli
            code_if(assembler, tab_sym, *it);
        else if((*it)[0] == 'E') // etykieta E
            assembler.push_back(*it); // wrzuc po prostu nazwe etykiety
        else if((*it)[0] == 'Z') // etykieta ZALADUJ, tylko przed petla FOR, ladujemy iter_pom do rejestru przed petla
        //bo na koncu dekrementujemy iterator wiec dalej bedzie w rejestrze, wiec nie oplaca sie go znowu tam ladowac
        {
            ss.clear();
            ss.str(*it);
            ss >> buffer; // usuwamy Z
            ss >> buffer; // iter_pom
            create_addres_num_in_register(assembler, tab_sym, buffer, 0);
            assembler.push_back(std::string("LOAD 1"));
        }
        else if((*it)[0] == 'W') // WRITE value
            code_write(assembler, tab_sym, *it);
        else if((*it)[0] == 'J') // JUMP     |JODD, JZERO nie moga byc bo to dopiero kod posredni
            assembler.push_back(*it);
        else if((*it)[0] == 'R')
            code_read(assembler, tab_sym, *it);
    }





    return assembler;
}

void correct_assembler_labels(std::list<std::string> &assembler)
{
    std::stringstream ss;
    std::string buffer;
    std::map<std::string, long long int> jump_to_etyk;
    std::map<std::string, long long int> etyk;
    std::list<std::string> etyk_list; // lista aktualnych etykiet
    long long int przesuniecie = 0;
    long long int number;
    long long int line_num;
    std::list<std::string>::iterator it;
    std::map<std::string, long long int>::iterator pos;
    std::list<std::string>::iterator it_pocz;
    for(it = assembler.begin(), line_num = 0; it != assembler.end(); it++, line_num++)
    {

        if((*it)[0] == 'E' || (*it)[0] == 'F') // etykieta
        {
            przesuniecie++;
            etyk_list.push_back(*it);
            it = assembler.erase(it); // iterator przejdzie na kolejny element
            line_num++;

            while(it != assembler.end() && ( (*it)[0] == 'E' || (*it)[0] == 'F' ))
            {
                przesuniecie++;
                etyk_list.push_back(*it);
                it = assembler.erase(it);
                line_num++;
            }
            while(!etyk_list.empty())
            {
                etyk[etyk_list.back()] = line_num - przesuniecie;
                etyk_list.pop_back();
            }
            it--; line_num--;
        }
    }

    for(pos = etyk.begin(); pos != etyk.end(); pos++)
    {
    //    std::cout << pos->first << " " << pos->second << std::endl;
    }

    //it_pocz = assembler.begin();
    std::string przechowaj;
    for(it = assembler.begin(), line_num = 0; it != assembler.end(); it++, line_num++)
    {
        if((*it)[0] == 'J') // JUMP, JZERO, JODD
        {
            std::string comm = *it;
            ss.clear();
            ss.str(comm);
            ss >> buffer; // JUMP, JZERO, JODD
            if(buffer == "JUMP")
            {
                przechowaj = buffer + std::string(" "); // JUMP
                ss >> buffer; // nazwa etykiety
            }
            else
            {
                przechowaj = buffer + std::string(" "); // JZERO
                ss >> buffer; // wyrzucenie numeru rejestru
                przechowaj += buffer + std::string(" "); // JZERO i
                ss >> buffer; // nazwa etykiety
            }
            pos = etyk.find(buffer);
            number = pos->second;
            ss.clear();
            ss.str("");
            ss << number;
            przechowaj += ss.str(); // np. JZERO 1 55
            *it = przechowaj; // podmien gdzie ma byc skok
        }
    }


}
