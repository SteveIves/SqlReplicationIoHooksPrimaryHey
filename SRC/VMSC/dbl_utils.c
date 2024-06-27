#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "dbl_utils.h"

int write_int_desc(DESC* desc, int value)
{
    //printf("write_int_desc: info desc->dsc$w_length %d, desc->dsc$b_dtype %d, desc->dsc$b_class %d, desc->dsc$a_pointer %p\n", desc->dsc$w_length, desc->dsc$b_dtype, desc->dsc$b_class, desc->dsc$a_pointer);
    if(desc->dsc$w_length < sizeof(int) || desc->dsc$a_pointer == NULL)
    {
        printf("write_int_desc: desc->dsc$w_length %d, desc->dsc$b_dtype %d, desc->dsc$b_class %d, desc->dsc$a_pointer %p\n", desc->dsc$w_length, desc->dsc$b_dtype, desc->dsc$b_class, desc->dsc$a_pointer);
        return -1;
    }
    else if(desc->dsc$b_dtype != DSC$K_DTYPE_Q && desc->dsc$b_dtype != DSC$K_DTYPE_L)
    {
        printf("write_int_desc: desc was not a 4/8 byte signed integer type %d", desc->dsc$b_dtype);
        return -1;
    }
    else
    {
        if(desc->dsc$w_length == sizeof(int))
        {
            memcpy(desc->dsc$a_pointer, &value, sizeof(int));
            return 0;
        }
        else if(desc->dsc$w_length == sizeof(long long int))
        {
            long long int bigVal = value;
            memcpy(desc->dsc$a_pointer, &bigVal, sizeof(long long int));
            return 0;
        }
        else
        {
            printf("write_int_desc: desc->dsc$w_length %d, desc->dsc$b_dtype %d, desc->dsc$b_class %d, desc->dsc$a_pointer %p\n", desc->dsc$w_length, desc->dsc$b_dtype, desc->dsc$b_class, desc->dsc$a_pointer);
            return -1;
        }
    }
}

int write_i8_desc(DESC* desc, long long int value)
{
    if(desc->dsc$w_length != sizeof(long long int) || desc->dsc$a_pointer == NULL)
    {
        printf("write_i8_desc: desc->dsc$w_length %d, desc->dsc$b_dtype %d, desc->dsc$b_class %d, desc->dsc$a_pointer %p\n", desc->dsc$w_length, desc->dsc$b_dtype, desc->dsc$b_class, desc->dsc$a_pointer);
        return -1;
    }
    else if(desc->dsc$b_dtype != DSC$K_DTYPE_Q)
    {
        printf("write_i8_desc: desc was not an 8 byte signed integer type %d", desc->dsc$b_dtype);
        return -1;
    }
    else
    {
        memcpy(desc->dsc$a_pointer, &value, sizeof(long long int));
        return 0;
    }
}

int validate_alpha_desc(DESC* desc)
{  
    if(desc == NULL)
    {
        //descriptor was null
        return -1;
    }
    else if(desc->dsc$b_dtype != DSC$K_DTYPE_T || desc->dsc$b_class != DSC$K_CLASS_S || desc->dsc$a_pointer == NULL)
    {
        printf("validate_alpha_desc: desc->dsc$w_length %d, desc->dsc$b_dtype %d, desc->dsc$b_class %d, desc->dsc$a_pointer %p\n", desc->dsc$w_length, desc->dsc$b_dtype, desc->dsc$b_class, desc->dsc$a_pointer);
        return -1;
    }
    else
    {
        return 0;
    }
}

int write_alpha_desc(DESC* desc, char* value)
{
    if(validate_alpha_desc(desc) != 0)
    {
        printf("writing alpha desc failed validation %s\n", value);
        return -1;
    }
    else
    {
        int length = strlen(value);
        if(length > desc->dsc$w_length)
        {
            printf("writing alpha desc failed length check %d\n", desc->dsc$w_length);
            return -1;
        }
        else
        {
            //printf("writing alpha desc %s\n", value);
            memcpy(desc->dsc$a_pointer, value, length);
            memset(desc->dsc$a_pointer + length, ' ', desc->dsc$w_length - length);
            return 0;
        }
    }
}

int read_int_desc(DESC* desc, int* value)
{
    //printf("read_int_desc: info desc->dsc$w_length %d, desc->dsc$b_dtype %d, desc->dsc$b_class %d, desc->dsc$a_pointer %p\n", desc->dsc$w_length, desc->dsc$b_dtype, desc->dsc$b_class, desc->dsc$a_pointer);
    if(desc->dsc$a_pointer == NULL)
    {
        printf("read_int_desc: desc was null");
        return -1;
    }
    else if(desc->dsc$b_dtype == 20)
    {
        char* end;
        char temp[28];
        memset(temp, 0, 28);
        memcpy(temp, desc->dsc$a_pointer, desc->dsc$w_length);
        *value = strtol(temp, &end, 10);
        return end != temp ? 0 : -1;
    }
    else if(desc->dsc$b_dtype > DSC$K_DTYPE_O || desc->dsc$b_dtype < DSC$K_DTYPE_B)
    {
        printf("read_int_desc: desc was not a signed integer type");
        return -1;
    }
    else
    {
        switch (desc->dsc$w_length) 
        {
        case 1: 
        {
            // Assuming data is unsigned
            unsigned char temp;
            memcpy(&temp, desc->dsc$a_pointer, 1);
            *value = (int)temp;
            break;
        }
        case 2: 
        {
            // Assuming data is unsigned
            unsigned short temp;
            memcpy(&temp, desc->dsc$a_pointer, 2);
            *value = (int)temp;
            break;
        }
        case 4: 
        {
            // Assuming data is a 4-byte integer
            memcpy(value, desc->dsc$a_pointer, 4);
            break;
        }
        case 8: 
        {
            // Assuming data is an 8-byte integer, but we only take the lower 4 bytes
            // This might lead to data loss if the value doesn't fit in a 4-byte int
            long long temp;
            memcpy(&temp, desc->dsc$a_pointer, 8);
            *value = (int)(temp & 0xFFFFFFFF);
            break;
        }
        default:
            printf("Unsupported length: %d\n", desc->dsc$w_length);
            return -1;
        }
        return 0;
    }
}

int read_i8_desc(DESC* desc, long long int* value)
{
    if(desc->dsc$a_pointer == NULL)
    {
        printf("read_i8_desc: desc was null");
        return -1;
    }
    else if(desc->dsc$b_dtype == 20)
    {
        char* end;
        char temp[28];
        memset(temp, 0, 28);
        memcpy(temp, desc->dsc$a_pointer, desc->dsc$w_length);
        *value = strtol(temp, &end, 10);
        return end != temp ? 0 : -1;
    }
    else if(desc->dsc$b_dtype > DSC$K_DTYPE_O || desc->dsc$b_dtype < DSC$K_DTYPE_B)
    {
        printf("read_int_desc: desc was not a signed integer type");
        return -1;
    }
    else
    {
        switch (desc->dsc$w_length) 
        {
        case 1: 
        {
            // Assuming data is unsigned
            unsigned char temp;
            memcpy(&temp, desc->dsc$a_pointer, 1);
            *value = (long long int)temp;
            break;
        }
        case 2: 
        {
            // Assuming data is unsigned
            unsigned short temp;
            memcpy(&temp, desc->dsc$a_pointer, 2);
            *value = (long long int)temp;
            break;
        }
        case 4: 
        {
            // Assuming data is a 4-byte integer
            int temp;
            memcpy(&temp, desc->dsc$a_pointer, 4);
            *value = (long long int)temp;
            break;
        }
        case 8: 
        {
            long long temp;
            memcpy(&temp, desc->dsc$a_pointer, 8);
            *value = temp;
            break;
        }
        default:
            printf("Unsupported length: %d\n", desc->dsc$w_length);
            return -1;
        }
        return 0;
    }
}


int write_dbl_error(char** error_state, int max_errors, int max_error_length, char* error, DESC* ret_code)
{
    char* errorText = NULL;
    int errorTextLength = 0;
    int errorIndex = 0;

    //printf("writing hook error\n");

    if(reserve_dbl_error(error_state, &errorText, &errorTextLength, &errorIndex, max_errors, max_error_length) != 0)
    {
        printf("writing index %d into ret_code\n", errorIndex);
        write_int_desc(ret_code, -1);
        printf("failed to reserve error space\n");
        return -1;
    }
    else
    {
        int errorLength = strlen(error) + 1;
        if(errorTextLength > errorLength)
            errorTextLength = errorLength;

        
        strncpy(errorText, error, errorTextLength - 1);
        errorText[errorTextLength - 1] = '\0'; /* ensure null termination */
        /*set error index into ret_code*/
        //printf("wrote error text into index %d with length %d and contents %s\n", errorIndex, errorTextLength, errorText);
        //printf("writing index into ret_code\n");
        write_int_desc(ret_code, errorIndex);
        //printf("wrote error text into index %d\n", errorIndex);
        return 0;
    }
}

void report_unchecked_error(const char* error)
{
    /*TODO: log this to a system log of some sort*/
    printf("unchecked replicator hook error: %s\n", error);
}

int reserve_dbl_error(char** error_state, char** error, int* errorLength, int* errorIndex, int max_errors, int max_error_length)
{
    int slot_error = 0;
    int i;
    for(i = 0; i < max_errors - 1; i++)
    {
        if(error_state[i][0] == '\0')
        {
            break;
        }
    }

    if(error_state[i][0] != '\0')
    {
        /*no empty slots, overwrite oldest TODO: log the failure*/
        report_unchecked_error(error_state[i]);
        slot_error = -1;
    }

    *error = error_state[i];
    *errorLength = max_error_length;
    *errorIndex = i + 1;
    error_state[i][max_error_length - 1] = '\0'; /* ensure null termination */

    return slot_error;
}
