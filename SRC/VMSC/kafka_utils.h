#ifndef KAFKA_UTILS_H
#define KAFKA_UTILS_H

typedef struct rd_kafka_s rd_kafka_t;
typedef struct rd_kafka_message_s rd_kafka_message_t;

typedef struct message_node {
    char topic[256];
    char *buffer;
    int buffer_size;
    int partition;
    int offset;
    struct message_node *next;
} message_node;

typedef struct completion_queue {
    message_node *head;
    message_node *tail;
    message_node *free_list;
    int buffer_size;
} completion_queue;

typedef void (*kafka_callback)(rd_kafka_t *rk, const rd_kafka_message_t *rkmessage, void *opaque);
typedef void (*kafka_offline_callback)(void *opaque, message_node* node);

typedef struct kafka_state {
    rd_kafka_t *producer;
    rd_kafka_t *consumer;
    completion_queue queue;
    void* opaque;
    kafka_offline_callback offline_callback;
    int error_state;
    int running;
} kafka_state;

int kafka_connect(kafka_state* state, const char *brokers, void* opaque, kafka_offline_callback offline_callback, const char* consumer_group_name, char* error_message, int error_message_length);
int kafka_send(kafka_state* state, const char *topic, const char *message, int message_length, char* error_message, int error_message_length);
int kafka_cleanup(kafka_state* state, char* error_message, int error_message_length);
int kafka_poll(kafka_state* state, int timeout_ms, char* error_message, int error_message_length);
int kafka_receive(kafka_state* state, char *out_topic, char *buffer, int* buffer_size, int timeout_ms, int* out_partition, long long int* out_offset, char* error_message, int error_message_length);
int kafka_commit(kafka_state* state, const char *topic, int partition, long long int offset, char* error_message, int error_message_length);
int kafka_subscribe(kafka_state* state, const char *topic, char* error_message, int error_message_length);
long long int kafka_latest_offset(kafka_state *state, const char *topic, int partition, char *error_message, int error_message_length);
void kafka_default_msg_cb(rd_kafka_t *rk, const rd_kafka_message_t *rkmessage, void *opaque);
#endif