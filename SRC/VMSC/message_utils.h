#ifndef MESSAGE_UTILS_H
#define MESSAGE_UTILS_H

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

typedef struct string_type {
    char *data;
    int allocated;
    int length;
} string_type;

typedef struct string_array {
    string_type *items;
    int *free_indexes;
    int capacity;
    int size;
    int free_count;
} string_array;

string_array* create_string_array(int initial_capacity);
void trim_end(char* str);
int split_string(const char *str, int str_length, char** tokens, int max_tokens, int max_token_len);
void resize_string_array(string_array *array, int new_capacity);
int add_item_cstr(string_array *array, const char *item);
int add_item(string_array *array, const char *item, int item_length);
void set_item(string_array *array, int index, const char *item, int item_length);
int remove_item(string_array *array, int index);
void free_string_array(string_array *array);

#endif