
using Confluent.Kafka;
using Microsoft.VisualBasic.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace NetKafkaConsumer
{
    internal class KafkaConsumer : IDisposable
    {
        IConsumer<string, string> _consumer;
        int timeoutSec = 5;

        public KafkaConsumer(string Servers, string ConsumerGroup, string Topic, int TimeoutSec)
        {
            timeoutSec = TimeoutSec;

            //Connect to the Kafka server as a consumer
            var consumerConfig = new ConsumerConfig();
            consumerConfig.BootstrapServers = Servers;
            consumerConfig.ClientId = Topic;
            consumerConfig.GroupId = ConsumerGroup;
            consumerConfig.AutoOffsetReset = AutoOffsetReset.Earliest;

            //Disable auto commit so that we can control when kafka messages are committed
            consumerConfig.EnableAutoCommit = false;

            consumerConfig.AllowAutoCreateTopics = false;

            // Note: The AutoOffsetReset property determines the start offset in the event
            // there are not yet any committed offsets for the consumer group for the
            // topic/partitions of interest. By default, offsets are committed
            // automatically, so in this example, consumption will only start from the
            // earliest message in the topic the first time you run the program.

            _consumer = new ConsumerBuilder<string, string>(consumerConfig).Build();
            _consumer.Subscribe(Topic);

        }

        public void Dispose()
        {
            _consumer.Close();
        }

        public void ProcessMessages()
        {
            while (true)
            {
                try
                {
                    var msg = _consumer.Consume(TimeSpan.FromSeconds(5));

                    // Did our sleep timer fire ?
                    if (msg == null)
                    {
                        continue;
                    }

                    OnMessageReceived(new MessageReceivedEventArgs { Message = msg.Message.Value });

                    _consumer.Commit(msg);

                }
                catch (Exception e)
                {
                    OnMessageReceived(new MessageReceivedEventArgs { Message = e.Message });
                }
            }
        }

        public delegate void MessageReceivedEventHandler(object sender, MessageReceivedEventArgs e);

        public event MessageReceivedEventHandler? MessageReceived;

        protected virtual void OnMessageReceived(MessageReceivedEventArgs e)
        {
            // Ensure there are subscribers before raising the event
            MessageReceived?.Invoke(this, e);
        }
    }

    internal class MessageReceivedEventArgs
    {
        public string Message { get; set; } = "";
    }

}
