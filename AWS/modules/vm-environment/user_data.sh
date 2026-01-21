#!/bin/bash
# ============================================================================
# AWS EC2 Instance Initialization Script
# ============================================================================
# This script is executed on instance startup to:
# - Install CloudWatch agent
# - Configure logging
# - Install and start the application
# ============================================================================

set -e

# ============================================================================
# VARIABLES FROM TERRAFORM
# ============================================================================
LOG_GROUP_NAME="${log_group_name}"
APPLICATION_PORT="${application_port}"
ENVIRONMENT="${environment}"
PROJECT_NAME="${project_name}"

# ============================================================================
# SYSTEM UPDATE
# ============================================================================
echo "Updating system packages..."
yum update -y

# ============================================================================
# INSTALL CLOUDWATCH AGENT
# ============================================================================
if [ -n "$LOG_GROUP_NAME" ]; then
    echo "Installing CloudWatch agent..."
    wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
    rpm -U ./amazon-cloudwatch-agent.rpm
    rm -f ./amazon-cloudwatch-agent.rpm

    # Configure CloudWatch agent
    cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<EOF
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "$LOG_GROUP_NAME",
            "log_stream_name": "{instance_id}/messages",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/secure",
            "log_group_name": "$LOG_GROUP_NAME",
            "log_stream_name": "{instance_id}/secure",
            "timezone": "UTC"
          },
          {
            "file_path": "/var/log/application.log",
            "log_group_name": "$LOG_GROUP_NAME",
            "log_stream_name": "{instance_id}/application",
            "timezone": "UTC"
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "$PROJECT_NAME-$ENVIRONMENT",
    "metrics_collected": {
      "mem": {
        "measurement": [
          {
            "name": "mem_used_percent",
            "rename": "MemoryUtilization",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          {
            "name": "used_percent",
            "rename": "DiskUtilization",
            "unit": "Percent"
          }
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "/"
        ]
      }
    }
  }
}
EOF

    # Start CloudWatch agent
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
        -a fetch-config \
        -m ec2 \
        -s \
        -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

    systemctl enable amazon-cloudwatch-agent
    systemctl start amazon-cloudwatch-agent
    
    echo "CloudWatch agent installed and configured"
fi

# ============================================================================
# INSTALL DOCKER (Example Application Runtime)
# ============================================================================
echo "Installing Docker..."
yum install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# ============================================================================
# INSTALL NGINX (Example Web Server)
# ============================================================================
echo "Installing Nginx..."
amazon-linux-extras install -y nginx1
systemctl enable nginx
systemctl start nginx

# Configure Nginx to proxy to application
cat > /etc/nginx/conf.d/app.conf <<EOF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:$APPLICATION_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

systemctl restart nginx

# ============================================================================
# CREATE APPLICATION DIRECTORY
# ============================================================================
mkdir -p /opt/application
chown -R ec2-user:ec2-user /opt/application

# # Create sample application (replace with actual deployment)
# cat > /opt/application/app.py <<'EOF'
# from http.server import HTTPServer, BaseHTTPRequestHandler
# import json
# import os

# class SimpleHandler(BaseHTTPRequestHandler):
#     def do_GET(self):
#         if self.path == '/health':
#             self.send_response(200)
#             self.send_header('Content-type', 'application/json')
#             self.end_headers()
#             response = {'status': 'healthy'}
#             self.wfile.write(json.dumps(response).encode())
#         else:
#             self.send_response(200)
#             self.send_header('Content-type', 'application/json')
#             self.end_headers()
#             response = {
#                 'message': 'Hello from VM!',
#                 'environment': os.getenv('ENVIRONMENT', 'unknown'),
#                 'project': os.getenv('PROJECT_NAME', 'unknown')
#             }
#             self.wfile.write(json.dumps(response).encode())
    
#     def log_message(self, format, *args):
#         with open('/var/log/application.log', 'a') as f:
#             f.write("%s - - [%s] %s\n" % (
#                 self.address_string(),
#                 self.log_date_time_string(),
#                 format % args
#             ))

# if __name__ == '__main__':
#     port = int(os.getenv('APPLICATION_PORT', 8080))
#     server = HTTPServer(('0.0.0.0', port), SimpleHandler)
#     print(f'Starting server on port {port}')
#     server.serve_forever()
# EOF

# Install Python if needed
yum install -y python3

# Create systemd service for application
cat > /etc/systemd/system/application.service <<EOF
[Unit]
Description=Sample Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/application
Environment="APPLICATION_PORT=$APPLICATION_PORT"
Environment="ENVIRONMENT=$ENVIRONMENT"
Environment="PROJECT_NAME=$PROJECT_NAME"
ExecStart=/usr/bin/python3 /opt/application/app.py
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable application
systemctl start application

# ============================================================================
# CUSTOM USER DATA SCRIPT
# ============================================================================
${custom_script}

# ============================================================================
# FINAL STATUS
# ============================================================================
echo "Instance initialization completed successfully"
echo "Environment: $ENVIRONMENT"
echo "Project: $PROJECT_NAME"
echo "Application Port: $APPLICATION_PORT"

# Send completion signal
touch /var/log/user-data-completed