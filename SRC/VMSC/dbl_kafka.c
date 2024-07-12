#include <stdlib.h>
#include "dbl_utils.h"
#include "kafka_utils.h"
#include <descrip.h>
#include <string.h>

typedef struct dsc$descriptor DESC;

kafka_state* g_kafka_state;

int KAFKA_INIT(DESC* ret_code, DESC* brokers, DESC* consumer_group_name, DESC* error_message)
{
    if(validate_alpha_desc(error_message) == -1)
    {
        return -1;
    }
    memset(error_message->dsc$a_pointer, ' ', error_message->dsc$w_length);
    g_kafka_state = malloc(sizeof(kafka_state));
    int result = kafka_connect(g_kafka_state, brokers->dsc$a_pointer, NULL, NULL, consumer_group_name->dsc$a_pointer, error_message->dsc$a_pointer, error_message->dsc$w_length);
    write_int_desc(ret_code, result);
    return result;
}

int KAFKA_SHUTDOWN(DESC* ret_code, DESC* error_message)
{
    if(validate_alpha_desc(error_message) == -1)
    {
        return -1;
    }
    memset(error_message->dsc$a_pointer, ' ', error_message->dsc$w_length);
    int result = kafka_cleanup(g_kafka_state, error_message->dsc$a_pointer, error_message->dsc$w_length);
    write_int_desc(ret_code, result);
    free(g_kafka_state);
    return result;
}

int KAFKA_SEND(DESC* ret_code, DESC* topic, DESC* message, DESC* error_message)
{
    if(validate_alpha_desc(error_message) == -1)
    {
        return -1;
    }
    memset(error_message->dsc$a_pointer, ' ', error_message->dsc$w_length);
    int result = kafka_send(g_kafka_state, topic->dsc$a_pointer, message->dsc$a_pointer, message->dsc$w_length, error_message->dsc$a_pointer, error_message->dsc$w_length);
    write_int_desc(ret_code, result);
    return result;
}

int KAFKA_POLL(DESC* ret_code, DESC* timeout_ms, DESC* error_message)
{
    if(validate_alpha_desc(error_message) == -1)
    {
        return -1;
    }
    memset(error_message->dsc$a_pointer, ' ', error_message->dsc$w_length);
    int timeout;
    read_int_desc(timeout_ms, &timeout);
    int result = kafka_poll(g_kafka_state, timeout, error_message->dsc$a_pointer, error_message->dsc$w_length);
    write_int_desc(ret_code, result);
    return result;
}

int KAFKA_SEND_BLOCKING(DESC* ret_code, DESC* topic, DESC* message, DESC* timeout_ms, DESC* error_message)
{
    int timeout;
    if(validate_alpha_desc(error_message) == -1)
    {
        return -1;
    }
    memset(error_message->dsc$a_pointer, ' ', error_message->dsc$w_length);
    read_int_desc(timeout_ms, &timeout);
    int result = kafka_send(g_kafka_state, topic->dsc$a_pointer, message->dsc$a_pointer, message->dsc$w_length, error_message->dsc$a_pointer, error_message->dsc$w_length);
    if(result == -1)
    {
        write_int_desc(ret_code, result);
        return result;
    }
    else
    {
        // Poll to process the messages
        result = kafka_poll(g_kafka_state, timeout, error_message->dsc$a_pointer, error_message->dsc$w_length);
        if(result == -1)
        {
            write_int_desc(ret_code, result);
            return result;
        }
        else if(g_kafka_state->queue.head == NULL)
        {
            write_int_desc(ret_code, -2);
            return -1;
        }
    }
    return result;
}

int KAFKA_RECEIVE(DESC* ret_code, DESC* timeout_ms, DESC* topic, DESC* buffer, DESC* buffer_size, DESC* partition, DESC* offset, DESC* error_message)
{
    int timeout;
    int buf_size;
    read_int_desc(timeout_ms, &timeout);
    read_int_desc(buffer_size, &buf_size);
    int part;
    long long int off;
    if(validate_alpha_desc(error_message) == -1)
    {
        return -1;
    }
    memset(error_message->dsc$a_pointer, ' ', error_message->dsc$w_length);
    int result = kafka_receive(g_kafka_state, topic->dsc$a_pointer, buffer->dsc$a_pointer, &buf_size, timeout, &part, &off, error_message->dsc$a_pointer, error_message->dsc$w_length);
    write_int_desc(buffer_size, buf_size);
    write_int_desc(partition, part);
    write_i8_desc(offset, off);
    write_int_desc(ret_code, result);
    return result;
}

int KAFKA_COMMIT(DESC* ret_code, DESC* topic, DESC* partition, DESC* offset, DESC* error_message)
{
    int part;
    long long int off;
    read_int_desc(partition, &part);
    read_i8_desc(offset, &off);
    if(validate_alpha_desc(error_message) == -1)
    {
        return -1;
    }
    memset(error_message->dsc$a_pointer, ' ', error_message->dsc$w_length);
    int result = kafka_commit(g_kafka_state, topic->dsc$a_pointer, part, off, error_message->dsc$a_pointer, error_message->dsc$w_length);
    write_int_desc(ret_code, result);
    return result;
}

int KAFKA_SUBSCRIBE(DESC* ret_code, DESC* topic, DESC* error_message)
{
    if(validate_alpha_desc(error_message) == -1)
    {
        return -1;
    }
    memset(error_message->dsc$a_pointer, ' ', error_message->dsc$w_length);
    int result = kafka_subscribe(g_kafka_state, topic->dsc$a_pointer, error_message->dsc$a_pointer, error_message->dsc$w_length);
    write_int_desc(ret_code, result);
    return result;
}

int KAFKA_LATEST_OFFSET(DESC* ret_code, DESC* topic, DESC* partition, DESC* error_message)
{
    int part;
    read_int_desc(partition, &part);
    if(validate_alpha_desc(error_message) == -1)
    {
        return -1;
    }
    memset(error_message->dsc$a_pointer, ' ', error_message->dsc$w_length);
    long long int result = kafka_latest_offset(g_kafka_state, topic->dsc$a_pointer, part, error_message->dsc$a_pointer, error_message->dsc$w_length);
    write_i8_desc(ret_code, result);
    return result;
}