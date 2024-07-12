#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <descrip.h>
#include <stsdef.h>
#include <jpidef.h>
#include <starlet.h>
#include <lib$routines.h>
#include <zmq.h>

#include "message_utils.h"
#include "dbl_utils.h"
#include "zmq_hooks.h"

/* array of error info, circular buffer of errors, 
flag if get_error isnt called when the allocator comes around or stop_txn/stop_file/shutdown are called*/


/*check known replicator health, if its bad 
    if its been longer than x config time since last attempt to connect to a new replicator
        attempt to connect to next replicator

*/
hook_state* g_hook_state;

int reserve_hook_error(char** error, int* errorLength, int* errorIndex)
{
    char* error_buffer[MAX_HOOK_ERROR_LENGTH];
    for(int i = 0; i < MAX_HOOK_ERRORS; i++)
    {
        error_buffer[i] = g_hook_state->errors[i];
    }
    return reserve_dbl_error(error_buffer, error, errorLength, errorIndex, MAX_HOOK_ERRORS, MAX_HOOK_ERROR_LENGTH);
}

int write_hook_error(char* error, DESC* ret_code)
{
    char* error_buffer[MAX_HOOK_ERROR_LENGTH];
    for(int i = 0; i < MAX_HOOK_ERRORS; i++)
    {
        error_buffer[i] = g_hook_state->errors[i];
    }
    return write_dbl_error(error_buffer, MAX_HOOK_ERRORS, MAX_HOOK_ERROR_LENGTH, error, ret_code);
}

int connect_to_replicator(DESC* ret_code)
{
    char* errorText = NULL;
    int errorTextLength = 0;
    int errorIndex = 0;
    if(reserve_hook_error(&errorText, &errorTextLength, &errorIndex) != 0)
    {
        return -1;
    }
    else
    {
        if(g_hook_state->connect(g_hook_state, errorText, errorTextLength) != 0)
        {
            return write_hook_error(errorText, ret_code);
        }
        else
        {
            return 0;
        }
    }
}

int allocate_message_zmq(hook_state* state, void** message, char** buffer, int bufferLength)
{
    zmq_msg_t* msg = (zmq_msg_t*)malloc(sizeof(zmq_msg_t));
    if(msg == NULL)
    {
        return -1;
    }
    else
    {
        zmq_msg_init_size(msg, bufferLength);
        *message = msg;
        *buffer = zmq_msg_data(msg);
        return 0;
    }
}

int connect_internal_zmq(hook_state* state, char* errorText, int errorTextLength)
{
    int attempts = 0;
    int leader_found = 0;
    while(attempts < CONNECT_ATTEMPTS)
    {
        int actual_nodes = 0;
        attempts++;
        if (errorTextLength < 1 || errorText == NULL) {
            return -1;
        }

        leader_check_message check_msg; 
        check_msg.process_id = pid_helper();
        check_msg.req_id = state->request_id++;
        check_msg.op_type = OP_TYPE_LEADER;

        zmq_pollitem_t items[MAX_NODE_ADDRESSES];

        memset((void*)items, 0, sizeof(items));

        /* Connect and send the message to all nodes */ 
        for (int i = 0; i < MAX_NODE_ADDRESSES; i++) 
        {
            if (strlen(state->nodes[i].address) > 0) 
            {
                int hr = 0;
                void* socket = zmq_socket(state->context, ZMQ_REQ);
                printf("connecting to index %d at %s\n", i, state->nodes[i].address);
                if(state->nodes[i].active_socket != NULL)
                {
                    int linger = 0; // Immediate return
                    zmq_setsockopt(state->nodes[i].active_socket, ZMQ_LINGER, &linger, sizeof(linger));
                    zmq_disconnect (state->nodes[i].active_socket, state->nodes[i].address);
                    zmq_close(state->nodes[i].active_socket);
                }

                state->nodes[i].active_socket = socket;

                if (socket == NULL || zmq_connect(socket, state->nodes[i].address) != 0) {
                    snprintf(errorText, errorTextLength, "Failed to setup ZMQ REQ socket %p at %s with error %s", socket, state->nodes[i].address, zmq_strerror(zmq_errno()));
                    printf("*****\n\n\n\n\n********\nfailed setup %s", errorText);
                    return -1;
                }

                printf("connected to index %d at %s\n", i, state->nodes[i].address);

                if ((hr = zmq_send(socket, &check_msg, sizeof(check_msg), 0)) == -1) 
                {
                    snprintf(errorText, errorTextLength, "Failed to send message to %s", state->nodes[i].address);
                    printf("*****\n\n\n\n\n********\nfailed send %s", errorText);
                    return -1;
                }
                else
                {
                    printf("sent leader message with result %d\n", hr);
                }

                items[i].socket = socket;
                items[i].events = ZMQ_POLLIN;
                actual_nodes++;
            }
        }
        //this cant poll forever, eventually it needs to exit and return an error

        // Poll the sockets for a response
        
        printf("polling\n");
        int rc = zmq_poll(items, actual_nodes, CONNECT_TIMEOUT_MS);
        printf("polling done with %d\n", rc);
        if (rc == -1) 
        {
            /*shut all the extra sockets and return the error*/
            for (int i = 0; i < MAX_NODE_ADDRESSES; i++) 
            {
                if(state->nodes[i].active_socket != 0)
                {
                    int linger = 0; // Immediate return
                    zmq_setsockopt(state->nodes[i].active_socket, ZMQ_LINGER, &linger, sizeof(linger));
                    zmq_disconnect (state->nodes[i].active_socket, state->nodes[i].address);
                    zmq_close(state->nodes[i].active_socket);
                }

                state->nodes[i].active_socket = 0;
            }

            snprintf(errorText, errorTextLength, "Polling error");
            return -1;
        }
        else if(rc != 0)
        {
            for (int i = 0; i < actual_nodes; i++) 
            {
                if (items[i].revents & ZMQ_POLLIN) 
                {
                    printf("trying to receive\n");
                    leader_response_message response;
                    if (zmq_recv(items[i].socket, &response, sizeof(response), 0) != -1) 
                    {
                        printf("received message\n");
                        if (response.leader) 
                        {
                            printf("leader found\n");
                            // Mark this node as the leader
                            leader_found = 1;
                            state->nodes[i].active_leader = 1;
                            break;
                        }
                        else
                        {
                            printf("not leader\n");
                        }
                    }
                    else
                    {
                        printf("failed to receive\n");
                    }
                }
            }
        } //drop through and try again from scratch

        // Clean up: close all but the leader socket
        for (int i = 0; i < actual_nodes; i++) 
        {
            if (items[i].socket && state->nodes[i].active_leader != 1) 
            {
                printf("closing socket %d because it was not elected leader\n", i);
                int linger = 0; // Immediate return
                zmq_setsockopt(state->nodes[i].active_socket, ZMQ_LINGER, &linger, sizeof(linger));
                zmq_disconnect (items[i].socket, state->nodes[i].address);
                zmq_close(items[i].socket);
                state->nodes[i].active_socket = 0;
            }
        }
    }

    return leader_found ? 0 : -1;
}

int send_packet_zmq(hook_state* state, void* message, replication_ack* ack, char* errorText, int errorTextLength)
{
    int hr = 0;
    int attempts = 0;
    void* active_socket = NULL;
    /*blocking send with a timeout, ask the local node who the leader is and try again*/
    zmq_msg_t* msg = (zmq_msg_t*)message;
    void* watch = zmq_stopwatch_start ();
    while(attempts < RESEND_ATTEMPTS)
    {
        for(int i = 0; i < MAX_NODE_ADDRESSES; i++)
        {
            if(state->nodes[i].active_leader == 1)
            {
                //printf("sending to leader at index %d\n", i);
                active_socket = state->nodes[i].active_socket;
                break;
            }
        }

        if(active_socket == NULL)
        {
            //printf("no leader found, attempting to reconnect\n");
            if(state->connect(state, errorText, errorTextLength) != 0)
            {
                return -1;
            }
            else
                continue;
        } 

        if((hr = zmq_sendmsg(active_socket,msg, 0)) == -1)
        {
            if(state->connect(state, errorText, errorTextLength) != 0)
                return -1;
            else
                continue;
        }

        // Set up poll item
        zmq_pollitem_t items[1];
        items[0].socket = active_socket;
        items[0].events = ZMQ_POLLIN;
        items[0].revents = 0;
        items[0].fd = 0;

        /* Poll the socket for a reply with a 5-second timeout */
        int rc = zmq_poll(items, 1, state->response_timeout_ms);

        if (rc == -1 || rc == 0) 
        {
            /* Polling failed due to an error or timeout
            run reconnect logic and retry */
            printf("polling failed with retval %d error %d: %s, attempting to reconnect\n", rc, zmq_errno(), zmq_strerror(zmq_errno()));
            if(state->connect(state, errorText, errorTextLength) != 0)
            {
                return -1;
            }
            else
                continue; // drop out to the surrounding retry loop that will resend the request
        } 
        else 
        {
            /* Message has been received */
            //zmq_msg_t reply;
            //zmq_msg_init(&reply);
            if(zmq_recvmsg(active_socket,msg, ZMQ_DONTWAIT) > 0)
            {
                //printf("received message\n");
                /* Deserialize reply_data from zmq_msg_data(&reply) */
                if(zmq_msg_size(msg) == sizeof(replication_ack))
                {
                    memcpy(ack, zmq_msg_data(msg), sizeof(replication_ack));
                }
            }
            else
            {
                printf("failed to get ack\n");
                if(state->connect(state, errorText, errorTextLength) != 0)
                {
                    return -1;
                }
                else
                    continue; // drop out to the surrounding retry loop that will resend the request
            }
            zmq_msg_close(msg);
            free(msg);
            //printf("%d microseconds round trip w/connect\n", zmq_stopwatch_stop(watch));
            return 0;
        }
    }

    zmq_msg_close(msg);
    free(msg);
    snprintf(errorText, errorTextLength, "Failed to send message to leader after attempting to reconnect");
    return -1;
}

int write_op(hook_state* state, int file_id, int op_type, const char* key_data, const char* record_data, const char* original_record_data, long long int txn_id, char** errorText, int* errorTextLength, int* errorIndex) {
    int packet_length;
    char* packet_buffer;
    void* packet;

    packet_length = replication_packet_length(op_type, record_data ? strlen(record_data) : 0);
    if (state->allocate(state, &packet, &packet_buffer, packet_length) != 0 || packet_buffer == NULL) {
        *errorText = "write_op: failed to allocate packet buffer";
        return -1;
    }

    switch (op_type) {
        case OP_TYPE_INSERT:
        case OP_TYPE_INSERT_AC:
            if (!record_data) {
                *errorText = "write_op: record_data is not passed or not an alpha descriptor";
                return -1;
            }
            make_replication_packet(state->open_files, packet_buffer, state->request_id, op_type, file_id, txn_id, strlen(record_data), key_data, record_data, NULL);
            break;

        case OP_TYPE_UPDATE:
        case OP_TYPE_UPDATE_AC:
            if (!record_data) {
                *errorText = "write_op: record_data is not passed or not an alpha descriptor";
                return -1;
            }
            if (!original_record_data) {
                *errorText = "write_op: original_record_data is not passed or not an alpha descriptor";
                return -1;
            }
            make_replication_packet(state->open_files, packet_buffer, state->request_id, op_type, file_id, txn_id, strlen(record_data), key_data, record_data, original_record_data);
            break;

        case OP_TYPE_DELETE:
        case OP_TYPE_DELETE_AC:
            if (original_record_data)
                make_replication_packet(state->open_files, packet_buffer, state->request_id, op_type, file_id, txn_id, strlen(original_record_data), key_data, original_record_data, NULL);
            else
                make_replication_packet(state->open_files, packet_buffer, state->request_id, op_type, file_id, txn_id, 0, key_data, NULL, NULL);
            break;

        default:
            *errorText = "write_op: op_type is not a valid value";
            return -1;
    }

    if (reserve_hook_error(errorText, errorTextLength, errorIndex) != 0) {
        return -1; 
    } else {
        replication_ack ack;
        if (state->send_packet(state, packet, &ack, *errorText, *errorTextLength) != 0) {
            return -1; 
        } else {
            state->last_txn_id = ack.txn_id;
            return 0; 
        }
    }
}

int REP_WRITE_OP(DESC* ret_code, DESC* handle, DESC* op_type, DESC* key_data, DESC* record_data, DESC* original_record_data, DESC* txn_id) {
    int op_type_value;
    int file_id;
    long long int txn_id_value = 0;

    if (read_int_desc(op_type, &op_type_value) != 0)
        return write_hook_error("rep_write_op: op_type is not an integer", ret_code);

    if (read_int_desc(handle, &file_id) != 0 || file_id < 0)
        return write_hook_error("rep_write_op: handle is not an integer", ret_code);

    if (op_type_value == OP_TYPE_DELETE || op_type_value == OP_TYPE_INSERT || op_type_value == OP_TYPE_UPDATE) {
        if (read_i8_desc(txn_id, &txn_id_value) != 0)
            return write_hook_error("rep_write_op: transaction id was not passed or not an i8", ret_code);
    }

    const char* key_data_ptr = key_data ? key_data->dsc$a_pointer : NULL;
    const char* record_data_ptr = record_data ? record_data->dsc$a_pointer : NULL;
    const char* original_record_data_ptr = original_record_data ? original_record_data->dsc$a_pointer : NULL;

    char* errorText = NULL;
    int errorTextLength = 0;
    int errorIndex = 0;

    int result = write_op(g_hook_state, file_id, op_type_value, key_data_ptr, record_data_ptr, original_record_data_ptr, txn_id_value, &errorText, &errorTextLength, &errorIndex);
    
    if (result != 0) {
        return write_hook_error(errorText, ret_code);
    }

    return write_int_desc(ret_code, result);
}

/*function rep_start_file(in A, out DHANDLE), int*/
int REP_START_FILE(DESC* ret_code, DESC* filename, DESC* out_handle)
{
    if(filename->dsc$w_length > 128)
        return write_hook_error("rep_start_file: filename is longer than 128", ret_code);

    if(write_int_desc(out_handle, add_item(g_hook_state->open_files, filename->dsc$a_pointer, filename->dsc$w_length) + 1) != 0)
        return write_hook_error("rep_start_file: out_handle was an invalid destination", ret_code);
    
    return write_int_desc(ret_code, 0);
}

/*function rep_stop_file(in DHANDLE), int*/
int REP_STOP_FILE(DESC* ret_code, DESC* handle)
{
    int handle_value = 0;
    if(read_int_desc(handle, &handle_value) != 0)
        return write_hook_error("rep_stop_file: op_type is not an integer", ret_code);

    if(handle_value <= 0 || handle_value >= g_hook_state->open_files->capacity)
        return write_hook_error("rep_stop_file: handle is not a valid handle", ret_code);

    if(remove_item(g_hook_state->open_files, handle_value - 1) != 0)
    {
        printf("rep_stop_file: handle was not found in open files table %d:%d:%d\n", handle_value, handle->dsc$w_length, handle->dsc$b_dtype);
        return write_hook_error("rep_stop_file: handle was not found in open files table", ret_code);
    }

    return write_int_desc(ret_code, 0);
}

int send_txn_packet(int op_type, DESC* ret_code, DESC* txn_id)
{
    void* packet;
    char* packet_buffer;
    int packet_length;
    long long int txn_id_value;
    char* errorText;
    int errorTextLength;
    int errorIndex;

    if(reserve_hook_error(&errorText, &errorTextLength, &errorIndex) != 0)
    {
        return write_int_desc(ret_code, -1); 
    }

    packet_length = replication_packet_length(OP_TYPE_START_TXN, 0);
    if(g_hook_state->allocate(g_hook_state, &packet, &packet_buffer, packet_length) != 0 || packet_buffer == NULL)
        return write_hook_error("rep_start_txn: failed to allocate packet buffer", ret_code);

    if(read_i8_desc(txn_id, &txn_id_value) != 0)
        return write_hook_error("rep_start_txn: transaction id was not passed or not an i8", ret_code);

    make_txn_packet(packet_buffer, g_hook_state->request_id++, op_type, op_type == OP_TYPE_START_TXN ? 0 : txn_id_value);

    replication_ack ack;
    if(g_hook_state->send_packet(g_hook_state, packet,  
        &ack, errorText, errorTextLength) != 0)
    {
        return write_hook_error(errorText, ret_code);
    }
    else
    {
        g_hook_state->last_txn_id = ack.txn_id;
        if(op_type == OP_TYPE_START_TXN)
            write_i8_desc(txn_id, ack.txn_id);

        return write_int_desc(ret_code, 0); 
    }
}

int REP_START_TXN(DESC* ret_code, DESC* txn_id)
{
    return send_txn_packet(OP_TYPE_START_TXN, ret_code, txn_id);
}

int REP_STOP_TXN(DESC* ret_code, DESC* txn_id)
{
    return send_txn_packet(OP_TYPE_COMMIT, ret_code, txn_id);
}

void destroy_hook_state(hook_state* state)
{
    for(int i = 0; i < MAX_NODE_ADDRESSES; i++)
    {
        if(state->nodes[i].active_socket != NULL)
        {
            int linger = 0; // Immediate return
            zmq_setsockopt(state->nodes[i].active_socket, ZMQ_LINGER, &linger, sizeof(linger));
            zmq_disconnect (state->nodes[i].active_socket, state->nodes[i].address);
            zmq_close(state->nodes[i].active_socket);
        }
    }

    if(state->context != NULL)
    {
        zmq_ctx_destroy(state->context);
    }
    if(state->open_files != NULL)
    {
        for(int i = 0; i < state->open_files->size; i++)
        {
            if(state->open_files->items[i].length > 0)
            {
                printf("open file was not closed");
            }
        }
        free_string_array(state->open_files);
    }
}

/*function rep_shutdown(), int*/
int REP_SHUTDOWN(DESC* ret_code)
{
    if(g_hook_state == NULL)
    {
        printf("rep_shutdown: hook is not running\n");
        return -1;
    }
    else
    {
        destroy_hook_state(g_hook_state);
    }

    for(int i = 0; i < MAX_HOOK_ERRORS; i++)
    {
        if(g_hook_state->errors[i][0] != '\0')
        {
            write_int_desc(ret_code, -1);
            printf("rep_shutdown: unobserved error found during shutdown");
        }
    }

    free(g_hook_state);
    g_hook_state = NULL;
    write_int_desc(ret_code, 0);
    return 0;
}

int REP_STARTUP_UT(DESC* ret_code)
{
    /*run unit test specific startup and configure the ut variants for connect and send_packet*/
    if(g_hook_state != NULL)
    {
        return write_hook_error("rep_startup called when hook is already running", ret_code) != 0;
    }
    else
    {
        g_hook_state = malloc(sizeof(hook_state));
    }
}

void init_hook_state(hook_state* state, char** address_location, int address_count, ConnectFunc connect, SendPacketFunc send_packet, AllocateMessage allocate)
{
    state->context = zmq_ctx_new();
    state->open_files = create_string_array(2);
    state->request_id = 0;
    state->response_timeout_ms = SEND_MESSAGE_TIMEOUT;
    state->last_txn_id = 0;
    state->connect = connect;
    state->send_packet = send_packet;
    state->allocate = allocate;

    for(int i = 0; i < address_count; i++)
    {
        address_location[i] = state->nodes[i].address;
        memset(state->nodes[i].address, 0, MAX_NODE_ADDRESS_LENGTH);
    }
}

int REP_STARTUP(DESC* ret_code, DESC* node_addresses)
{
    //printf("calling startup\n");
    char* target_node_addresses[MAX_NODE_ADDRESSES];
    int node_addresses_length = 0;
    if(validate_alpha_desc(node_addresses) != 0)
        return write_hook_error("rep_startup: node_addresses is not passed or not an alpha descriptor", ret_code);
    
    /*run zmq specific startup and configure the zmq variants for connect and send_packet*/
    if(g_hook_state != NULL)
    {
        return write_hook_error("rep_startup called when hook is already running", ret_code) != 0;
    }
    else
    {
        g_hook_state = malloc(sizeof(hook_state));
        memset(g_hook_state, 0, sizeof(hook_state));
    }

    //printf("initializing zmq\n");
    init_hook_state(g_hook_state, target_node_addresses, MAX_NODE_ADDRESSES, &connect_internal_zmq, &send_packet_zmq, &allocate_message_zmq);
    node_addresses_length = split_string(node_addresses->dsc$a_pointer, node_addresses->dsc$w_length, target_node_addresses, MAX_NODE_ADDRESSES, MAX_NODE_ADDRESS_LENGTH);
    return write_int_desc(ret_code, 0);
}

/*function rep_get_error(in I4, out A), int*/
int REP_GET_ERROR(DESC* ret_code, DESC* error_number, DESC* error_text)
{
    if(g_hook_state == NULL)
    {
        write_int_desc(ret_code, -1);
        write_alpha_desc(error_text, "rep_get_error: hook is not running");
        return -1;
    }

    /*index is 1 based because 0 is success and -1 is fatal*/
    int error_number_value = 0;
    if(read_int_desc(error_number, &error_number_value) != 0)
        return write_hook_error("rep_get_error: error_number is not an integer", ret_code);
    
    if(error_number_value <= 0 || error_number_value > MAX_HOOK_ERRORS)
    {
        return write_hook_error("rep_get_error: error_number is not a valid error number", ret_code);
    }
    else
    {
        if(write_alpha_desc(error_text, g_hook_state->errors[error_number_value - 1]) != 0)
            return write_hook_error("rep_get_error: error_text was an invalid destination", ret_code);
        else
            return write_int_desc(ret_code, 0);
    }
}


/*internal functions

connect_to_replicator
process_ack
process_config

report_unchecked_error
report_mismatched_txn
report_unclosed_file

log_offline_mode_entered
log_offline_mode_exit*/