#ifndef ZMQ_HOOKS_H
#define ZMQ_HOOKS_H

#include "packet_utils.h"

#define MAX_HOOK_ERRORS 10
#define MAX_HOOK_ERROR_LENGTH 1024
#define MAX_NODE_ADDRESSES 5
#define SEND_MESSAGE_TIMEOUT 5000
#define CONNECT_TIMEOUT_MS 5000
#define CONNECT_ATTEMPTS 3
#define RESEND_ATTEMPTS 3

typedef struct node_state {
    char address[MAX_NODE_ADDRESS_LENGTH];
    void* active_socket;
    int active_leader;
} node_state;

typedef struct hook_state hook_state;
typedef int (*ConnectFunc)(hook_state* state, char* errorText, int errorTextLength);
typedef int (*SendPacketFunc)(hook_state* state, void* message, replication_ack*, char* errorText, int errorTextLength);
typedef int (*AllocateMessage)(hook_state* state, void** message, char** buffer, int bufferLength);

typedef struct hook_state {
    void* context;
    node_state nodes[MAX_NODE_ADDRESSES];
    string_array* open_files;
    char errors[MAX_HOOK_ERRORS][MAX_HOOK_ERROR_LENGTH];
    int request_id;
    int response_timeout_ms;
    long long int last_txn_id;
    ConnectFunc connect;
    SendPacketFunc send_packet;
    AllocateMessage allocate;
} hook_state;


int connect_internal_zmq(hook_state* state, char* errorText, int errorTextLength);
int send_packet_zmq(hook_state* state, void* message, replication_ack* ack, char* errorText, int errorTextLength);
int write_op(hook_state* state, int file_id, int op_type, const char* key_data, const char* record_data, 
    const char* original_record_data, long long int txn_id, char** errorText, int* errorTextLength, int* errorIndex);
void init_hook_state(hook_state* state, char** address_location, int address_count, ConnectFunc connect, SendPacketFunc send_packet, AllocateMessage allocate);
void destroy_hook_state(hook_state* state);
int allocate_message_zmq(hook_state* state, void** message, char** buffer, int bufferLength);

#endif // ZMQ_HOOKS_H