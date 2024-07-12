#include "message_utils.h"

string_array* create_string_array(int initial_capacity) 
{
    string_array *array = (string_array *)malloc(sizeof(string_array));
    array->items = (string_type *)malloc(sizeof(string_type) * initial_capacity);
    array->free_indexes = (int*)malloc(sizeof(int) * initial_capacity);
    array->capacity = initial_capacity;
    array->size = 0;
    array->free_count = 0;
    return array;
}

void trim_end(char* str) 
{
    char* end = str + strlen(str) - 1;
    while (end >= str && (unsigned char)*end == 0x20) 
    {
        *end = '\0';
        end--;
    }
}

int split_string(const char *str, int str_length, char** tokens, int max_tokens, int max_token_len) 
{
    int token_count = 0;
    int token_len = 0;

    const char *initial = str;
    const char *start = str;
    while (*str && str < initial + str_length) 
    {
        if (*str == ';')
        {
            if (token_count < max_tokens - 1)
            {
                //printf("splitting string found \n");
                strncpy(tokens[token_count], start, token_len);
                tokens[token_count][token_len] = '\0'; // Null-terminate the token
                trim_end(tokens[token_count]);
                token_count++;
                token_len = 0;
                start = str + 1;
            } else 
            {
                // Reached the maximum number of tokens
                break;
            }
        } 
        else 
        {
            if (token_len < max_token_len - 1) 
            {
                token_len++;
            } 
            else 
            {
                //printf("finishing splitting string found \n");
                // Token is too long, truncate it
                strncpy(tokens[token_count], start, max_token_len - 1);
                tokens[token_count][max_token_len - 1] = '\0'; // Null-terminate the token
                trim_end(tokens[token_count]);
                token_count++;
                token_len = 0;
                start = str + 1;
            }
        }
        str++;
    }

    // Add the last token
    if (token_len > 0 && token_count < max_tokens) 
    {
        strncpy(tokens[token_count], start, token_len);
        tokens[token_count][token_len] = '\0';
        trim_end(tokens[token_count]);
        printf("splitting string found %d\n", token_count + 1);
    }
    else
    {
        printf("splitting string found %d\n", token_count);
    }
    
    return token_count;
}


void resize_string_array(string_array *array, int new_capacity) 
{
    string_type *new_items = (string_type*)realloc(array->items, sizeof(string_type) * new_capacity);
    int *new_free_indexes = (int*)realloc(array->free_indexes, sizeof(int) * new_capacity);

    if (!new_items || !new_free_indexes) 
    {
        /* Handle allocation failure */
        free(new_items);
        free(new_free_indexes);
        return;
    }

    array->items = new_items;
    array->free_indexes = new_free_indexes;
    array->capacity = new_capacity;
}

int add_item_cstr(string_array *array, const char *item) 
{
    return add_item(array, item, strlen(item));
}

int add_item(string_array *array, const char *item, int item_length) 
{
    if (array->free_count > 0) 
    {
        int index = array->free_indexes[--array->free_count];
        set_item(array, array->size, item, item_length);
        return index;
    } 
    else 
    {
        if (array->size == array->capacity) {
            resize_string_array(array, array->capacity * 2);
        }
        set_item(array, array->size, item, item_length);
        return array->size++;
    }
}

void set_item(string_array *array, int index, const char *item, int item_length) 
{
    if(array->items[array->size].data == NULL) 
    {
        array->items[array->size].data = (char*)malloc(item_length + 1);
        array->items[array->size].allocated = item_length + 1;
    }
    else if(array->items[array->size].allocated < item_length) 
    {
        int new_size = (item_length * 2) + 1;
        array->items[array->size].data = (char*)realloc(array->items[array->size].data, new_size);
        array->items[array->size].allocated = new_size;
    }
    memcpy(array->items[index].data, item, item_length);
    array->items[index].length = item_length;
}

int remove_item(string_array *array, int index) 
{
    if (index < 0 || index >= array->size) 
    {
        /* Invalid index or item already removed */
        return -1;
    }
    if(array->items[index].data[0] == '\0' || array->items[index].length == 0) 
    {
        /* Item already removed */
        return -1;
    }

    memset(array->items[index].data, 0, array->items[index].allocated);
    array->items[index].length = 0;
    array->free_indexes[array->free_count++] = index;
    return 0;
}

void free_string_array(string_array *array) 
{
    for(int i = 0; i < array->size; i++) 
    {
        if(array->items[i].data != NULL)
        {
            free(array->items[i].data);
            array->items[i].data = NULL;
        }
    }
    free(array->items);
    array->items = NULL;
    free(array->free_indexes);
    array->free_indexes = NULL;
    free(array);
}