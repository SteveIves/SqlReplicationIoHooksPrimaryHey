#include "packet_utils.h"

#include <descrip.h>
#include <stsdef.h>
#include <jpidef.h>
#include <starlet.h>
#include <lib$routines.h>

static unsigned long current_process_id;

unsigned long pid_helper()
{
    if(current_process_id != 0)
    {
        return current_process_id;
    }
    else
    {
        unsigned long pid;
        lib$getjpi(&JPI$_PID, 0, 0, &pid, 0, 0);
        current_process_id = pid;
        return pid;
    }
}

int op_type_from_packet(char* buffer, int buffer_size)
{
    if(buffer_size < sizeof(min_message))
        return -1;

    return ((min_message*)buffer)->op_type;
}

void make_replication_ack(char* buffer, int request_id, int op_type, long long int txn_id, int error_number)
{
    replication_ack* message = (replication_ack*)buffer;
    message->process_id = pid_helper();
    message->req_id = request_id;
    message->op_type = op_type;
    message->txn_id = txn_id;
    message->error_number = error_number;
}

int replication_packet_length(int op_type, int record_length)
{
    switch(op_type)
    {
        case OP_TYPE_INSERT:
        case OP_TYPE_INSERT_AC:
        {
            return (sizeof(replication_message) - 32000) + record_length;
        }
        case OP_TYPE_UPDATE:
        case OP_TYPE_UPDATE_AC:
        {
            /*these packets arent fixed size, we need to subtract what isnt actually consumed in record length*/
            return (sizeof(replication_delta_message) - 64000) + (record_length * 2);
        }
        case OP_TYPE_DELETE:
        case OP_TYPE_DELETE_AC:
        {
            return (sizeof(replication_message) - 32000) + record_length;
        }
        case OP_TYPE_START_TXN:
        case OP_TYPE_COMMIT:
        {
            return sizeof(txn_message);
        }
        default:
        {
            return -1;
        }
    }
}

void make_txn_packet(char* buffer, int request_id, int op_type, long long int txn_id)
{
    txn_message* message = (txn_message*)buffer;
    message->process_id = pid_helper();
    message->req_id = request_id;
    message->op_type = op_type;
    message->txn_id = txn_id;
}

void make_replication_packet(string_array* files, char* buffer, int request_id, int op_type, int file_id, long long int txn_id, int record_length, const char* key_data, const char* record_data, const char* record_data_original)
{
    if(op_type == OP_TYPE_UPDATE || op_type == OP_TYPE_UPDATE_AC)
    {
        replication_delta_message* message = (replication_delta_message*)buffer;
        message->process_id = pid_helper();
        message->req_id = request_id;
        memcpy(message->file_id, files->items[file_id - 1].data, files->items[file_id - 1].length);
        message->op_type = op_type;
        message->txn_id = txn_id;
        message->record_length = record_length;
        message->original_record_length = record_length;
        memcpy(message->key_data, key_data, 64);
        if(record_length > 0 && record_data != NULL)
            memcpy(message->record_data, record_data, record_length);
        if(record_length > 0 && record_data_original != NULL)
            memcpy(message->record_data + record_length, record_data_original, record_length);
    }
    else
    {
        replication_message* message = (replication_message*)buffer;
        message->process_id = pid_helper();
        message->req_id = request_id;
        memcpy(message->file_id, files->items[file_id - 1].data, files->items[file_id - 1].length);
        message->op_type = op_type;
        message->txn_id = txn_id;
        message->record_length = record_length;
        memcpy(message->key_data, key_data, 64);
        if(record_length > 0 && record_data != NULL)
            memcpy(message->record_data, record_data, record_length);
    }
}

void make_leader_packet(char* buffer, int request_id)
{
    leader_check_message* message = (leader_check_message*)buffer;
    message->process_id = pid_helper();
    message->req_id = request_id;
    message->op_type = OP_TYPE_LEADER;
}

void make_leader_response(char* buffer, int request_id, int leader, const char* leader_address)
{
    leader_response_message* message = (leader_response_message*)buffer;
    message->process_id = pid_helper();
    message->req_id = request_id;
    message->op_type = OP_TYPE_LEADER;
    message->leader = leader;
    memcpy(message->leader_address, leader_address, strlen(leader_address));
    if(strlen(leader_address) < MAX_NODE_ADDRESS_LENGTH)
        memset(message->leader_address + strlen(leader_address), 0, MAX_NODE_ADDRESS_LENGTH - strlen(leader_address));
}

int read_txn(char* buffer, txn_message** txn)
{
    min_message* message = (min_message*)buffer;
    if(message->op_type != OP_TYPE_START_TXN && message->op_type != OP_TYPE_COMMIT)
        return -1;
    else
        *txn = (txn_message*)buffer;

    return 0;

}
int read_replication(char* buffer, replication_message** replication)
{
    min_message* message = (min_message*)buffer;
    if(message->op_type != OP_TYPE_INSERT && message->op_type != OP_TYPE_INSERT_AC && message->op_type != OP_TYPE_UPDATE && message->op_type != OP_TYPE_UPDATE_AC && message->op_type != OP_TYPE_DELETE && message->op_type != OP_TYPE_DELETE_AC)
        return -1;
    else
        *replication = (replication_message*)buffer;

    return 0;

}
int read_replication_delta(char* buffer, replication_delta_message** replication)
{
    min_message* message = (min_message*)buffer;
    if(message->op_type != OP_TYPE_UPDATE && message->op_type != OP_TYPE_UPDATE_AC)
        return -1;
    else
        *replication = (replication_delta_message*)buffer;

    return 0;

}