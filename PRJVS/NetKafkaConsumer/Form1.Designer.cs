namespace NetKafkaConsumer
{
    partial class Form1
    {
        /// <summary>
        ///  Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        ///  Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        ///  Required method for Designer support - do not modify
        ///  the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            btnClearLog = new Button();
            log = new ListBox();
            txtConsumerGroup = new TextBox();
            label4 = new Label();
            txtTopic = new TextBox();
            label3 = new Label();
            btnClose = new Button();
            txtKafkaServers = new TextBox();
            label1 = new Label();
            btnStart = new Button();
            SuspendLayout();
            // 
            // btnClearLog
            // 
            btnClearLog.Enabled = false;
            btnClearLog.Location = new Point(1071, 45);
            btnClearLog.Name = "btnClearLog";
            btnClearLog.Size = new Size(94, 29);
            btnClearLog.TabIndex = 10;
            btnClearLog.Text = "Clear &Log";
            btnClearLog.UseVisualStyleBackColor = true;
            btnClearLog.Click += btnClearLog_Click;
            // 
            // log
            // 
            log.FormattingEnabled = true;
            log.Location = new Point(25, 90);
            log.Name = "log";
            log.Size = new Size(1140, 444);
            log.TabIndex = 9;
            // 
            // txtConsumerGroup
            // 
            txtConsumerGroup.Location = new Point(452, 52);
            txtConsumerGroup.Name = "txtConsumerGroup";
            txtConsumerGroup.Size = new Size(172, 27);
            txtConsumerGroup.TabIndex = 4;
            txtConsumerGroup.Text = "UnloadTestApp";
            // 
            // label4
            // 
            label4.AutoSize = true;
            label4.Location = new Point(327, 55);
            label4.Name = "label4";
            label4.Size = new Size(119, 20);
            label4.TabIndex = 7;
            label4.Text = "Consumer group";
            // 
            // txtTopic
            // 
            txtTopic.Location = new Point(139, 52);
            txtTopic.Name = "txtTopic";
            txtTopic.Size = new Size(172, 27);
            txtTopic.TabIndex = 3;
            txtTopic.Text = "UnloadResponse";
            // 
            // label3
            // 
            label3.AutoSize = true;
            label3.Location = new Point(47, 55);
            label3.Name = "label3";
            label3.Size = new Size(86, 20);
            label3.TabIndex = 6;
            label3.Text = "Topic name";
            // 
            // btnClose
            // 
            btnClose.Location = new Point(1071, 540);
            btnClose.Name = "btnClose";
            btnClose.Size = new Size(94, 29);
            btnClose.TabIndex = 11;
            btnClose.Text = "&Close";
            btnClose.UseVisualStyleBackColor = true;
            btnClose.Click += btnClose_Click;
            // 
            // txtKafkaServers
            // 
            txtKafkaServers.Location = new Point(139, 12);
            txtKafkaServers.Name = "txtKafkaServers";
            txtKafkaServers.Size = new Size(1026, 27);
            txtKafkaServers.TabIndex = 13;
            txtKafkaServers.Text = "10.1.10.21:9092";
            // 
            // label1
            // 
            label1.AutoSize = true;
            label1.Location = new Point(14, 15);
            label1.Name = "label1";
            label1.Size = new Size(119, 20);
            label1.TabIndex = 12;
            label1.Text = "Server addresses";
            // 
            // btnStart
            // 
            btnStart.Location = new Point(630, 51);
            btnStart.Name = "btnStart";
            btnStart.Size = new Size(94, 29);
            btnStart.TabIndex = 14;
            btnStart.Text = "&Start";
            btnStart.UseVisualStyleBackColor = true;
            btnStart.Click += btnStart_Click;
            // 
            // Form1
            // 
            AutoScaleDimensions = new SizeF(8F, 20F);
            AutoScaleMode = AutoScaleMode.Font;
            ClientSize = new Size(1178, 579);
            ControlBox = false;
            Controls.Add(btnStart);
            Controls.Add(txtKafkaServers);
            Controls.Add(label1);
            Controls.Add(btnClose);
            Controls.Add(btnClearLog);
            Controls.Add(log);
            Controls.Add(txtConsumerGroup);
            Controls.Add(label3);
            Controls.Add(label4);
            Controls.Add(txtTopic);
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            MinimizeBox = false;
            Name = "Form1";
            Text = "Form1";
            ResumeLayout(false);
            PerformLayout();
        }

        #endregion

        private Button btnClearLog;
        private ListBox log;
        private TextBox txtConsumerGroup;
        private Label label4;
        private TextBox txtTopic;
        private Label label3;
        private Button btnClose;
        private TextBox txtKafkaServers;
        private Label label1;
        private Button btnStart;
    }
}
