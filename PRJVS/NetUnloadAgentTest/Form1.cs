using Confluent.Kafka;
using System;
using System.Drawing;
using System.Linq;
using System.Security.Cryptography;
using System.Windows.Forms;
using static Confluent.Kafka.ConfigPropertyNames;
using static System.Runtime.InteropServices.JavaScript.JSType;

namespace NetUnloadAgentTest
{
    public partial class Form1 : Form
    {
        IProducer<string, string>? _producer;
        bool _connected = false;

        public Form1()
        {
            InitializeComponent();
        }

        private void btnConnect_Click(object sender, EventArgs e)
        {
            txtKafkaServers.Enabled = false;
            txtRequestTopic.Enabled = false;
            btnAttach.Enabled = false;

            //Connect to the Kafka server as a producer
            var producerConfig = new ProducerConfig();
            producerConfig.BootstrapServers = txtKafkaServers.Text;
            producerConfig.EnableIdempotence = true; //ensure delivery of messages in the order specified
            _producer = new ProducerBuilder<string, string>(producerConfig).Build();

            btnSendTables.Enabled = true;
            btnSendUnload.Enabled = true;
            btnSendStop.Enabled = true;

            _connected = true;
        }

        private void btnSendTables_Click(object sender, EventArgs e)
        {
            sendRequest("TABLES DEPARTMENT,EMPLOYEE");
        }
        private void btnSendUnload_Click(object sender, EventArgs e)
        {
            sendRequest("UNLOAD EMPLOYEE");
        }

        private void btnSendStop_Click(object sender, EventArgs e)
        {
            sendRequest("STOP");
        }

        private void sendRequest(string requestMessage)
        {
            var request = new Message<string, string>() { Key = "", Value = requestMessage };
            var deliveryResult = _producer?.ProduceAsync(txtRequestTopic.Text, request).Result;
        }

        private void btnClose_Click(object sender, EventArgs e)
        {
            //Clean up the producer
            if (_connected)
            {
                _producer?.Dispose();
            }

            Application.Exit();
        }

    }
}
