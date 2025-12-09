# EGMS - System Setup Script for Linux Mint
# Author: Siyabulela Shabangu
# Date:9-12 November 2025

echo "Starting EGMS System Setup on Linux Mint..."
echo "============================================"

# Check if running with sudo privileges
if [ "$EUID" -ne 0 ]; then
    echo "This script requires sudo privileges. Please enter your password if prompted."
fi

# TASK 1: File and Directory Management
echo ""
echo "1. CREATING DIRECTORY STRUCTURE..."
mkdir -p -v grants_project/citizens grants_project/deceased grants_project/grants
echo "✓ Directory structure created successfully"

echo ""
echo "   CREATING SAMPLE CITIZEN FILES..."
# Create more realistic sample data
cat > grants_project/citizens/citizen1.txt << 'EOFCIT1'
NID:7910151234081
LastName:Dlamini
FirstName:Goodwill
DoB:1950-05-15
Residence:Mbabane
Region:Hhohho
Country:Eswatini
EOFCIT1

cat > grants_project/citizens/citizen2.txt << 'EOFCIT2'
NID:7506181234082
LastName:Simelane
FirstName:Thandeka
DoB:1948-11-22
Residence:Manzini
Region:Manzini
Country:Eswatini
EOFCIT2

cat > grants_project/citizens/citizen3.txt << 'EOFCIT3'
NID:4203041234083
LastName:Mamba
FirstName:Sipho
DoB:1945-03-04
Residence:Nhlangano
Region:Shiselweni
Country:Eswatini
EOFCIT3

cat > grants_project/citizens/citizen4.txt << 'EOFCIT4'
NID:9507301234084
LastName:Kunene
FirstName:Lindiwe
DoB:1995-07-30
Residence:Siteki
Region:Lubombo
Country:Eswatini
EOFCIT4

echo "✓ Sample citizen files created with realistic Eswatini data"

# Create main data files for dashboard
touch grants_project/citizens.txt
touch grants_project/deceased.txt
touch grants_project/grants.txt
echo "✓ Main data files created for dashboard"

# TASK 2: User and Group Management
echo ""
echo "2. CONFIGURING USERS AND GROUPS..."

# Create group if it doesn't exist
if ! getent group socialdev > /dev/null; then
    sudo groupadd socialdev
    echo "✓ Created 'socialdev' group"
else
    echo "⚠ Group 'socialdev' already exists"
fi

# Create users if they don't exist
create_user() {
    local username=$1
    if ! id "$username" &>/dev/null; then
        sudo useradd -m -s /bin/bash -G socialdev "$username"
        # Set simple password (for educational purposes only)
        echo "$username:password123" | sudo chpasswd
        echo "✓ Created user '$username'"
    else
        echo "⚠ User '$username' already exists"
    fi
}

create_user "officer1"
create_user "officer2" 
create_user "admin1"

# Set admin1 as group administrator
sudo gpasswd -A admin1 socialdev
echo "✓ 'admin1' assigned as group administrator for 'socialdev'"

# TASK 3: File Permissions and Security
echo ""
echo "3. CONFIGURING FILE PERMISSIONS AND SECURITY..."

# Set ownership
sudo chown -R admin1:socialdev grants_project/
echo "✓ Set ownership to admin1:socialdev"

# Set specific permissions for each directory
sudo chmod -R 750 grants_project/grants/    # admin:rwx, group:r-x, others:---
sudo chmod -R 774 grants_project/citizens/  # admin:rwx, group:rwx, others:r--
sudo chmod -R 774 grants_project/deceased/  # admin:rwx, group:rwx, others:r--

echo "✓ Permissions set according to security requirements"

# Verification
echo ""
echo "   VERIFYING PERMISSIONS:"
echo "   Grants directory:"
ls -ld grants_project/grants/
echo "   Citizens directory:"
ls -ld grants_project/citizens/

# TASK 4: Process and Job Control
echo ""
echo "4. DEMONSTRATING PROCESS AND JOB CONTROL..."

echo "   Starting a simulated grant report generation (sleep 60) in background..."
sleep 60 &
REPORT_PID=$!
echo "   ✓ Background process started with PID: $REPORT_PID"

echo ""
echo "   Listing current jobs:"
jobs -l

echo ""
echo "   Process tree view:"
ps -o pid,ppid,cmd -p $REPORT_PID

echo ""
echo "   Bringing job to foreground (waiting 3 seconds to show it's running)..."
# We'll simulate this without actually blocking the script
echo "   Command to use: fg %1"
echo "   To terminate: Ctrl+C"

echo ""
echo "   Now terminating the background process..."
kill $REPORT_PID 2>/dev/null
if [ $? -eq 0 ]; then
    echo "   ✓ Background process terminated successfully"
else
    echo "   ⚠ Process already completed or couldn't be terminated"
fi

# TASK 5: Archiving and Compression
echo ""
echo "5. CREATING ARCHIVES AND BACKUPS..."

# Create timestamped backup
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
tar -czf "citizens_backup_$TIMESTAMP.tar.gz" grants_project/citizens/
echo "✓ Created archive: citizens_backup_$TIMESTAMP.tar.gz"

# Also create the required citizens.tar.gz
tar -czf citizens.tar.gz grants_project/citizens/
echo "✓ Created required archive: citizens.tar.gz"

# Verify the archive
echo ""
echo "   VERIFYING ARCHIVE CONTENTS:"
tar -tzf citizens.tar.gz | head -5

echo ""
echo "============================================"
echo "EGMS SYSTEM SETUP COMPLETED SUCCESSFULLY!"
echo "============================================"
echo ""
echo "Next steps:"
echo "1. Run the main dashboard: ./egms_dashboard.sh"
echo "2. Test all menu options"
echo "3. Take screenshots for your report"
echo ""



