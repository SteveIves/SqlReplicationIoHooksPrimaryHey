using Confluent.Kafka;

namespace NetKafkaConsumer
{
    public partial class Form1 : Form
    {
        KafkaConsumer _consumer;

        public Form1()
        {
            InitializeComponent();
            _consumer = new KafkaConsumer(txtKafkaServers.Text, txtConsumerGroup.Text, txtTopic.Text, 5);
        }

        private void btnClearLog_Click(object sender, EventArgs e)
        {
            log.Items.Clear();
        }

        private void btnClose_Click(object sender, EventArgs e)
        {
            //Clean up the consumer and terminate the application
            _consumer.Dispose();
            Application.Exit();
        }

        private void btnStart_Click(object sender, EventArgs e)
        {
            txtKafkaServers.Enabled = false;
            txtTopic.Enabled = false;
            txtConsumerGroup.Enabled = false;
            btnClearLog.Enabled = true;

            _consumer.ProcessMessages();
        }
    }
}
