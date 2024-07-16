namespace NetUnloadAgentTest
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
            label1 = new Label();
            txtKafkaServers = new TextBox();
            txtRequestTopic = new TextBox();
            label2 = new Label();
            btnClose = new Button();
            btnSendTables = new Button();
            btnSendUnload = new Button();
            btnSendStop = new Button();
            groupBoxRequest = new GroupBox();
            groupBoxServer = new GroupBox();
            btnAttach = new Button();
            groupBoxRequest.SuspendLayout();
            groupBoxServer.SuspendLayout();
            SuspendLayout();
            // 
            // label1
            // 
            label1.AutoSize = true;
            label1.Location = new Point(22, 39);
            label1.Name = "label1";
            label1.Size = new Size(119, 20);
            label1.TabIndex = 0;
            label1.Text = "Server addresses";
            // 
            // txtKafkaServers
            // 
            txtKafkaServers.Location = new Point(147, 36);
            txtKafkaServers.Name = "txtKafkaServers";
            txtKafkaServers.Size = new Size(394, 27);
            txtKafkaServers.TabIndex = 1;
            txtKafkaServers.Text = "10.1.10.21:9092";
            // 
            // txtRequestTopic
            // 
            txtRequestTopic.Location = new Point(147, 69);
            txtRequestTopic.Name = "txtRequestTopic";
            txtRequestTopic.Size = new Size(394, 27);
            txtRequestTopic.TabIndex = 2;
            txtRequestTopic.Text = "UNLOAD_REQUEST";
            // 
            // label2
            // 
            label2.AutoSize = true;
            label2.Location = new Point(55, 72);
            label2.Name = "label2";
            label2.Size = new Size(86, 20);
            label2.TabIndex = 5;
            label2.Text = "Topic name";
            // 
            // btnClose
            // 
            btnClose.Location = new Point(585, 38);
            btnClose.Name = "btnClose";
            btnClose.Size = new Size(94, 29);
            btnClose.TabIndex = 8;
            btnClose.Text = "&Close";
            btnClose.UseVisualStyleBackColor = true;
            btnClose.Click += btnClose_Click;
            // 
            // btnSendTables
            // 
            btnSendTables.Enabled = false;
            btnSendTables.Location = new Point(22, 38);
            btnSendTables.Name = "btnSendTables";
            btnSendTables.Size = new Size(169, 29);
            btnSendTables.TabIndex = 10;
            btnSendTables.Text = "Send &Tables Request";
            btnSendTables.UseVisualStyleBackColor = true;
            btnSendTables.Click += btnSendTables_Click;
            // 
            // btnSendUnload
            // 
            btnSendUnload.Enabled = false;
            btnSendUnload.Location = new Point(197, 38);
            btnSendUnload.Name = "btnSendUnload";
            btnSendUnload.Size = new Size(169, 29);
            btnSendUnload.TabIndex = 11;
            btnSendUnload.Text = "Send &Unload Request";
            btnSendUnload.UseVisualStyleBackColor = true;
            btnSendUnload.Click += btnSendUnload_Click;
            // 
            // btnSendStop
            // 
            btnSendStop.Enabled = false;
            btnSendStop.Location = new Point(372, 38);
            btnSendStop.Name = "btnSendStop";
            btnSendStop.Size = new Size(169, 29);
            btnSendStop.TabIndex = 12;
            btnSendStop.Text = "Send &Stop Request";
            btnSendStop.UseVisualStyleBackColor = true;
            btnSendStop.Click += btnSendStop_Click;
            // 
            // groupBoxRequest
            // 
            groupBoxRequest.Controls.Add(btnSendTables);
            groupBoxRequest.Controls.Add(btnSendStop);
            groupBoxRequest.Controls.Add(btnClose);
            groupBoxRequest.Controls.Add(btnSendUnload);
            groupBoxRequest.Location = new Point(12, 133);
            groupBoxRequest.Name = "groupBoxRequest";
            groupBoxRequest.Size = new Size(699, 94);
            groupBoxRequest.TabIndex = 13;
            groupBoxRequest.TabStop = false;
            groupBoxRequest.Text = "Operations";
            // 
            // groupBoxServer
            // 
            groupBoxServer.Controls.Add(btnAttach);
            groupBoxServer.Controls.Add(txtRequestTopic);
            groupBoxServer.Controls.Add(label2);
            groupBoxServer.Controls.Add(txtKafkaServers);
            groupBoxServer.Controls.Add(label1);
            groupBoxServer.Location = new Point(12, 12);
            groupBoxServer.Name = "groupBoxServer";
            groupBoxServer.Size = new Size(699, 115);
            groupBoxServer.TabIndex = 15;
            groupBoxServer.TabStop = false;
            groupBoxServer.Text = "Kafka Server(s)";
            // 
            // btnAttach
            // 
            btnAttach.Location = new Point(585, 42);
            btnAttach.Name = "btnAttach";
            btnAttach.Size = new Size(94, 29);
            btnAttach.TabIndex = 6;
            btnAttach.Text = "&Attach";
            btnAttach.UseVisualStyleBackColor = true;
            btnAttach.Click += btnConnect_Click;
            // 
            // Form1
            // 
            AutoScaleDimensions = new SizeF(8F, 20F);
            AutoScaleMode = AutoScaleMode.Font;
            ClientSize = new Size(724, 240);
            ControlBox = false;
            Controls.Add(groupBoxServer);
            Controls.Add(groupBoxRequest);
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            MinimizeBox = false;
            Name = "Form1";
            StartPosition = FormStartPosition.CenterScreen;
            Text = "Unload Agent Test";
            groupBoxRequest.ResumeLayout(false);
            groupBoxServer.ResumeLayout(false);
            groupBoxServer.PerformLayout();
            ResumeLayout(false);
        }

        #endregion

        private Label label1;
        private TextBox txtKafkaServers;
        private TextBox txtRequestTopic;
        private Label label2;
        private Button btnClose;
        private Button btnSendTables;
        private Button btnSendUnload;
        private Button btnSendStop;
        private GroupBox groupBoxRequest;
        private GroupBox groupBoxServer;
        private Button btnAttach;
    }
}
