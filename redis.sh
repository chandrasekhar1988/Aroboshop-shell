new
#!/bin/bash

# Get the script name without paths for the log file
SCRIPT_NAME=$(basename "$0")

ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

TIMESTAMP=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/${SCRIPT_NAME}-${TIMESTAMP}.log"

echo "Script started executing at $TIMESTAMP" &>> $LOGFILE

# Function to validate previous command execution
VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILED $N"
        echo -e "$R Check the logs at $LOGFILE for details. $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

# Ensure script is run as root
if [ $ID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N"
    exit 1 
else
    echo "You are root user"
fi 

# Reset any previous redis modules to avoid conflicts
dnf module reset redis -y &>> $LOGFILE
VALIDATE $? "Resetting default Redis modules"

# Enable Redis 6 module
dnf module enable redis:6 -y &>> $LOGFILE
VALIDATE $? "Enabling Redis 6 module"

# Install Redis
dnf install redis -y &>> $LOGFILE
VALIDATE $? "Installing Redis"

# Allow remote connections (Changing bind address)
# Note: Using a more specific sed command to avoid breaking other lines
sed -i 's/^bind 127.0.0.1/bind 0.0.0.0/' /etc/redis.conf &>> $LOGFILE
VALIDATE $? "Configuring Redis to allow remote connections"

# Enable Redis to start on boot
systemctl enable redis &>> $LOGFILE
VALIDATE $? "Enabling Redis service"

# Start the Redis service
systemctl start redis &>> $LOGFILE
VALIDATE $? "Starting Redis service"

echo -e "$G Redis has been successfully installed and started! $N"