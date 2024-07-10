#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <rdkafka.h>
#include "kafka_utils.h"

int enqueue(kafka_state *state, const char* topic, const char *message, int buffer_size);
void init_queue(completion_queue *queue, int buffer_size);

int kafka_connect(kafka_state* state, const char *brokers, void* opaque, kafka_offline_callback offline_callback, const char* group_name, char* error_message, int error_message_length)
{
    char errstr[512];
    rd_kafka_conf_t *conf;

    // Create Kafka client configuration
    conf = rd_kafka_conf_new();

    // Set the broker list
    if (rd_kafka_conf_set(conf, "bootstrap.servers", brokers, errstr, sizeof(errstr)) != RD_KAFKA_CONF_OK) 
    {
        snprintf(error_message, error_message_length, "Error setting brokers: %s\n", errstr);
        return -1;
    }

    // Set debug logging
    //if (rd_kafka_conf_set(conf, "debug", "all", errstr, sizeof(errstr)) != RD_KAFKA_CONF_OK) {
    //    snprintf(error_message, error_message_length, "Error setting debug: %s\n", errstr);
    //    return -1;
    //}

    state->opaque = opaque;
    state->offline_callback = offline_callback;
    init_queue(&state->queue, 65535); // Initialize the completion queue (buffer size 65535
    rd_kafka_conf_set_dr_msg_cb(conf, kafka_default_msg_cb);
    rd_kafka_conf_set_opaque(conf, state);

    // Create Kafka producer instance
    state->producer = rd_kafka_new(RD_KAFKA_PRODUCER, conf, errstr, sizeof(errstr));
    if (!state->producer) 
    {
        snprintf(error_message, error_message_length, "Failed to create producer: %s\n", errstr);
        return -1;
    }

    // Set the group id
    if(group_name) 
    {
        rd_kafka_conf_t *consumer_conf;

        // Create Kafka client configuration
        consumer_conf = rd_kafka_conf_new();

        // Set the broker list
        if (rd_kafka_conf_set(consumer_conf, "bootstrap.servers", brokers, errstr, sizeof(errstr)) != RD_KAFKA_CONF_OK) 
        {
            snprintf(error_message, error_message_length, "Error setting brokers: %s\n", errstr);
            return -1;
        }

        if (rd_kafka_conf_set(consumer_conf, "group.id", group_name, errstr, sizeof(errstr)) != RD_KAFKA_CONF_OK) 
        {
            snprintf(error_message, error_message_length, "Error setting group id: %s\n", errstr);
            return -1;
        }

        // Set enable.auto.commit to false
        if (rd_kafka_conf_set(consumer_conf, "enable.auto.commit", "false", errstr, sizeof(errstr)) != RD_KAFKA_CONF_OK) {
            snprintf(error_message, error_message_length, "Error setting enable.auto.commit: %s\n", errstr);
            return -1;
        }

        // Set enable.auto.offset.store to false
        if (rd_kafka_conf_set(consumer_conf, "enable.auto.offset.store", "false", errstr, sizeof(errstr)) != RD_KAFKA_CONF_OK) {
            snprintf(error_message, error_message_length, "Error setting enable.auto.offset.store: %s\n", errstr);
            return -1;
        }


        // Set debug logging
        //if (rd_kafka_conf_set(consumer_conf, "debug", "all", errstr, sizeof(errstr)) != RD_KAFKA_CONF_OK) {
        //    snprintf(error_message, error_message_length, "Error setting debug: %s\n", errstr);
        //    return -1;
        //}
        
        state->consumer = rd_kafka_new(RD_KAFKA_CONSUMER, consumer_conf, errstr, sizeof(errstr));
        if (!state->consumer) 
        {
            snprintf(error_message, error_message_length, "Failed to create consumer: %s\n", errstr);
            return -1;
        }
    }

    state->running = 1;
    return 0;
}

int kafka_send(kafka_state* state, const char *topic, const char *message, int message_length, char* error_message, int error_message_length)
{
    if (!state->producer) 
    {
        snprintf(error_message, error_message_length, "Producer not initialized\n");
        return -1;
    }

    int cq_result = enqueue(state, topic, message, message_length);
    if (cq_result == -1) 
    {
        snprintf(error_message, error_message_length, "Failed to enqueue message\n");
        return -1;
    }

    // Send message to Kafka
    if (rd_kafka_produce(rd_kafka_topic_new(state->producer, topic, NULL), 
                         RD_KAFKA_PARTITION_UA, RD_KAFKA_MSG_F_COPY,
                         (void *)message, message_length, NULL, 0, NULL) == -1) 
    {
        snprintf(error_message, error_message_length, "Failed to produce to topic %s: %s\n", 
                topic, rd_kafka_err2str(rd_kafka_last_error()));
        return -1;
    }
    return 0;
}

int kafka_cleanup(kafka_state* state, char* error_message, int error_message_length)
{
    if (!state->producer) 
        return -1;

    //TODO: need to do better tracking here around unflushed messages
    rd_kafka_flush(state->producer, 10*1000); // Wait for max 10 seconds
    rd_kafka_destroy(state->producer);

    if (state->consumer) 
    {
        rd_kafka_consumer_close(state->consumer);
        rd_kafka_destroy(state->consumer);
    }

    state->consumer = NULL;
    state->producer = NULL;
    return 0;
}

int kafka_poll(kafka_state* state, int timeout_ms, char* error_message, int error_message_length)
{
    if (!state->producer) 
    {
        snprintf(error_message, error_message_length, "Producer not initialized\n");
        return -1;
    }

    if (rd_kafka_poll(state->producer, timeout_ms) == -1)
    {
        snprintf(error_message, error_message_length, "Failed to poll: %s\n", rd_kafka_err2str(rd_kafka_last_error()));
        return -1;
    }
    return 0;
}

//out_topic needs to be a buffer of size 256 or null
int kafka_receive(kafka_state* state, char *out_topic, char *buffer, int* buffer_size, int timeout_ms, int* out_partition, long long int* out_offset, char* error_message, int error_message_length)
{
    if (!state->consumer) 
    {
        snprintf(error_message, error_message_length, "Consumer not initialized\n");
        return -1;
    }

    rd_kafka_message_t *rkmessage;
    rkmessage = rd_kafka_consumer_poll(state->consumer, timeout_ms);
    if (!rkmessage) 
    {
        snprintf(error_message, error_message_length, "No message received\n");
        return -1;
    }

    if (rkmessage->err) 
    {
        snprintf(error_message, error_message_length, "Error receiving message: %s\n", rd_kafka_message_errstr(rkmessage));
        rd_kafka_message_destroy(rkmessage);
        return -1;
    }

    if (rkmessage->len > *buffer_size) 
    {
        snprintf(error_message, error_message_length, "Message too large for buffer\n");
        rd_kafka_message_destroy(rkmessage);
        return -1;
    }

    memcpy(buffer, rkmessage->payload, rkmessage->len);
    //buffer[rkmessage->len] = '\0';
    
    *buffer_size = rkmessage->len;
    if (out_topic && rkmessage->rkt) {
        const char *topic_name = rd_kafka_topic_name(rkmessage->rkt);
        strcpy(out_topic, topic_name);
    }

    if (out_partition) {
        *out_partition = rkmessage->partition;
    }

    if (out_offset) {
        *out_offset = rkmessage->offset;
    }
    
    rd_kafka_message_destroy(rkmessage);
    return 0;

}

int kafka_commit(kafka_state* state, const char *topic, int partition, long long int offset, char* error_message, int error_message_length)
{
    if (!state->consumer) 
    {
        snprintf(error_message, error_message_length, "Consumer not initialized\n");
        return -1;
    }

    rd_kafka_topic_partition_list_t *offsets = rd_kafka_topic_partition_list_new(1);
    rd_kafka_topic_partition_list_add(offsets, topic, partition)->offset = offset;

    rd_kafka_resp_err_t err = rd_kafka_commit(state->consumer, offsets, 0);
    rd_kafka_topic_partition_list_destroy(offsets);
    if (err) {
        snprintf(error_message, error_message_length, "Failed to commit: %s\n", rd_kafka_err2str(err));
        return -1;
    } else {
        return 0;
    }
}

int kafka_subscribe(kafka_state* state, const char *topic, char* error_message, int error_message_length)
{
    if (!state->consumer) 
    {
        snprintf(error_message, error_message_length, "Consumer not initialized\n");
        return -1;
    }

    rd_kafka_topic_partition_list_t *topics;
    topics = rd_kafka_topic_partition_list_new(1);
    rd_kafka_topic_partition_list_add(topics, topic, RD_KAFKA_PARTITION_UA);

    rd_kafka_resp_err_t err;
    err = rd_kafka_subscribe(state->consumer, topics);
    rd_kafka_topic_partition_list_destroy(topics);
    rd_kafka_poll(state->consumer, 0);
    
    topics = NULL;
    if (rd_kafka_assignment(state->consumer, &topics) != RD_KAFKA_RESP_ERR_NO_ERROR) {
        fprintf(stderr, "Failed to get current assignment\n");
        return -1;
    }
    rd_kafka_topic_partition_list_destroy(topics);
    
    if (err) 
    {
        snprintf(error_message, error_message_length, "Failed to subscribe: %s\n", rd_kafka_err2str(err));
        return -1;
    }
    return 0;
}

long long int kafka_latest_offset(kafka_state *state, const char *topic, int partition, char *error_message, int error_message_length) {
    long long int low, high;
    rd_kafka_resp_err_t err;

    // Query watermark offsets
    err = rd_kafka_query_watermark_offsets(state->consumer, topic, partition, &low, &high, 10000);
    if (err) {
        snprintf(error_message, error_message_length, "Failed to query watermark offsets: %s\n", rd_kafka_err2str(err));
        return -1;
    }

    return high;
}

// Initialize the completion queue
void init_queue(completion_queue *queue, int buffer_size) {
    queue->head = NULL;
    queue->tail = NULL;
    queue->free_list = NULL;
    queue->buffer_size = buffer_size;
}

int enqueue(kafka_state *state, const char* topic, const char *message, int buffer_size) {
    message_node *newNode;
    
    if(buffer_size > state->queue.buffer_size) {
        fprintf(stderr, "Message too large for queue\n");
        return -1;
    }

    if(state->queue.free_list) {
        newNode = state->queue.free_list;
        state->queue.free_list = state->queue.free_list->next;
    } else {
        // Allocate memory for the message node (including the buffer
        char* buffer = malloc(sizeof(message_node) + state->queue.buffer_size);
        newNode = (message_node *)buffer;
        newNode->buffer = buffer + sizeof(message_node);
    }
    
    memcpy(newNode->buffer, message, buffer_size);
    newNode->buffer_size = buffer_size;
    newNode->next = NULL;
    strcpy(newNode->topic, topic);

    if (!state->queue.head) {
        state->queue.head = newNode;
        state->queue.tail = newNode;
    } else {
        state->queue.tail->next = newNode;
        state->queue.tail = newNode;
    }

    return 0;
}

// Remove a message from the completion queue (from the head)
message_node* dequeue(kafka_state *state) 
{
    if (!state->queue.head) return NULL;

    message_node *temp = state->queue.head;
    state->queue.head = state->queue.head->next;
    
    if (!state->queue.head) 
    {
        state->queue.tail = NULL;
    }
    return temp;
}

void free_node(kafka_state* state, message_node* node) 
{
    node->next = state->queue.free_list;
    state->queue.free_list = node;
}

void kafka_default_msg_cb(rd_kafka_t *rk, const rd_kafka_message_t *rkmessage, void *opaque) 
{
    kafka_state* state = (kafka_state*)opaque;
    if (rkmessage->err) {
        fprintf(stderr, "Message delivery failed: %s\n", rd_kafka_message_errstr(rkmessage));
        // If connection error, save to local file
        if (rkmessage->err == RD_KAFKA_RESP_ERR__TRANSPORT) {
            state->error_state = 1;
            while (state->queue.head) {
                message_node *message = dequeue(state);
                if(state->offline_callback) {
                    state->offline_callback(state->opaque, message);
                } else {
                    fprintf(stderr, "No offline callback defined\n");
                    fprintf(stderr, "Message: %s\n", message->buffer);
                }
                free_node(state, message);
            }
        } else if(rkmessage->err != 0) {
            fprintf(stderr, "Message delivery failed: %s\n", rd_kafka_message_errstr(rkmessage));
            message_node *message = dequeue(state);
            if(state->offline_callback) {
                    state->offline_callback(state->opaque, message);
            } else {
                fprintf(stderr, "No offline callback defined\n");
                fprintf(stderr, "Message: %s\n", message->buffer);
            }
            free_node(state, message);
        }
    } else {
        //fprintf(stdout, "Message delivered to topic %s\n", rkmessage->topic_name);
        // Remove from completion queue
        free_node(state, dequeue(state));
    }
}
