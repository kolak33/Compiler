

/* poprawia etykiety aby zmniejszyc/wyeliminowac skoki do skokow w kodzie posrednim */
void correct_jumps_to_jumps_labels(std::vector<std::string> &code);

/* generuje kod na maszyne rejestrowa */
std::list<std::string> convert_to_assembler(std::vector<std::string> &code, std::map<char*, Record *, cmp_str> &tab_sym);

/* wytwarza liczbe w odpowiednim rejestrze */
void create_number_in_register(std::list<std::string> &assembler, long long int number, int reg);

/* poprawia etykiety skokow */
void correct_assembler_labels(std::list<std::string> &assembler);
