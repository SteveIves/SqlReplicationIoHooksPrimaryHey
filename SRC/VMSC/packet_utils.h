#ifndef PACKET_UTILS_H
#define PACKET_UTILS_H

#include "message_utils.h"

#define MAX_NODE_ADDRESS_LENGTH 1024
#define OP_TYPE_INSERT 1
#define OP_TYPE_INSERT_AC 2
#define OP_TYPE_UPDATE 3
#define OP_TYPE_UPDATE_AC 4
#define OP_TYPE_DELETE 5
#define OP_TYPE_DELETE_AC 6
#define OP_TYPE_START_TXN 7
#define OP_TYPE_COMMIT 8
#define OP_TYPE_LEADER 9
#define OP_TYPE_LEADER_RESPONSE 10
#define OP_TYPE_REPLICATION_ACK 11
#define OP_TYPE_ERROR 12

#define ERROR_NO_ERROR 0
#define ERROR_INVALID_PACKET 1

typedef struct min_message {
    int process_id;
    int req_id;
    int op_type;
} min_message;

typedef struct leader_check_message {
    int process_id;
    int req_id;
    int op_type;
} leader_check_message;

typedef struct leader_response_message {
    int process_id;
    int req_id;
    int op_type;
    int leader;
    char leader_address[MAX_NODE_ADDRESS_LENGTH];
} leader_response_message;

typedef struct txn_message {
    int process_id;
    int req_id;
    int op_type;
    long long int txn_id;
} txn_message;

typedef struct replication_message {
    int process_id;
    int req_id;
    int op_type;
    char file_id[128];
    long long int txn_id;
    int record_length;
    char key_data[64];
    char record_data[32000];
} replication_message;

typedef struct replication_delta_message {
    int process_id;
    int req_id;
    int op_type;
    char file_id[128];
    long long int txn_id;
    int record_length;
    int original_record_length;
    char key_data[64];
    char record_data[32000];
    char original_data[32000];
} replication_delta_message;

typedef struct replication_ack {
    int process_id;
    int req_id;
    int op_type;
    long long int txn_id;
    int error_number;
} replication_ack;

unsigned long pid_helper();
int op_type_from_packet(char* buffer, int buffer_size);
void make_replication_ack(char* buffer, int request_id, int op_type, long long int txn_id, int error_number);
int replication_packet_length(int op_type, int record_length);
void make_txn_packet(char* buffer, int request_id, int op_type, long long int txn_id);
void make_replication_packet(string_array* files, char* buffer, int request_id, int op_type, int file_id, long long int txn_id, int record_length, const char* key_data, const char* record_data, const char* record_data_original);
void make_leader_packet(char* buffer, int request_id);
void make_leader_response(char* buffer, int request_id, int leader, const char* leader_address);
int read_txn(char* buffer, txn_message** txn);
int read_replication(char* buffer, replication_message** replication);
int read_replication_delta(char* buffer, replication_delta_message** replication);


#endif // PACKET_UTILS_H