#ifndef DBL_UTILS_H
#define DBL_UTILS_H

#include <descrip.h>

typedef struct dsc$descriptor DESC;

int write_int_desc(DESC* desc, int value);
int write_i8_desc(DESC* desc, long long int value);
int validate_alpha_desc(DESC* desc);
int write_alpha_desc(DESC* desc, char* value);
int read_int_desc(DESC* desc, int* value);
int read_i8_desc(DESC* desc, long long int* value);
int write_dbl_error(char** error_state, int max_errors, int max_error_length, char* error, DESC* ret_code);
int reserve_dbl_error(char** error_state, char** error, int* errorLength, int* errorIndex, int max_errors, int max_error_length);

#endif