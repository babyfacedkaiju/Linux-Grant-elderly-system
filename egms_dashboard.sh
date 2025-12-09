# EGMS - Elderly Grant Management System
# Main Dashboard Script
# Creator: Siyabulela Shabangu
# Date: 15-19 November 2025

# VirtualBox compatibility - set proper terminal
export TERM=xterm-256color

# Check if running in correct environment
if [ ! -t 0 ]; then
    echo "Error: This script must be run in a terminal."
    exit 1
fi

# Define data file paths
CITIZENS_FILE="grants_project/citizens.txt"
DECEASED_FILE="grants_project/deceased.txt"
GRANTS_FILE="grants_project/grants.txt"

# Ensure data files exist
touch "$CITIZENS_FILE" "$DECEASED_FILE" "$GRANTS_FILE"

# Function to display the main menu
show_main_menu() {
    clear
    echo "========================================="
    echo "   ELDERLY GRANT MANAGEMENT SYSTEM"
    echo "         Government of Eswatini"
    echo "========================================="
    echo "1. Register a New Citizen"
    echo "2. Search Citizens"
    echo "3. Register a Death"
    echo "4. Retrieve Deceased Information"
    echo "5. Extract Eligible Elders (70+ Years)"
    echo "6. Capture Grant Payment Status"
    echo "7. Retrieve Grant Details"
    echo "8. Generate System Report"
    echo "9. Exit"
    echo "========================================="
    echo -n "Please enter your choice [1-9]: "
}

# Function to pause and wait for user input
pause() {
    echo
    echo -n "Press [Enter] key to continue..."
    read -r
}

# Function to calculate age from date of birth
calculate_age() {
    birthdate=$1
    today=$(date +%Y-%m-%d)
    # Convert dates to seconds since epoch, calculate difference, convert to years
    birth_seconds=$(date -d "$birthdate" +%s 2>/dev/null)
    today_seconds=$(date -d "$today" +%s)
    if [[ -z "$birth_seconds" ]]; then
        echo "0"
        return
    fi
    age_seconds=$((today_seconds - birth_seconds))
    echo $((age_seconds / 60 / 60 / 24 / 365))
}

# Function to validate date format
validate_date() {
    date -d "$1" "+%Y-%m-%d" >/dev/null 2>&1
    return $?
}

# Register citizens 
register_citizen() {
    echo
    echo "--- Citizen Registration ---"
    echo -n "Enter National ID (NID): "
    read -r nid
    
    # Validate NID format (simple check for 13 digits)
    if [[ ! $nid =~ ^[0-9]{13}$ ]]; then
        echo "Error: NID must be 13 digits."
        pause
        return
    fi
    
    # Check if NID already exists
    if grep -q "^$nid:" "$CITIZENS_FILE"; then
        echo "Error: A citizen with NID $nid is already registered."
        pause
        return
    fi

    echo -n "Enter Last Name: "
    read -r lastname
    echo -n "Enter First Name: "
    read -r firstname
    
    # Date of Birth with validation
    while true; do
        echo -n "Enter Date of Birth (YYYY-MM-DD): "
        read -r dob
        if validate_date "$dob"; then
            break
        else
            echo "Error: Invalid date format. Please use YYYY-MM-DD."
        fi
    done
    
    echo -n "Enter Place of Residence: "
    read -r residence
    
    # Region selection
    echo "Select Region:"
    echo "1. Hhohho"
    echo "2. Manzini" 
    echo "3. Shiselweni"
    echo "4. Lubombo"
    echo -n "Enter choice [1-4]: "
    read -r region_choice
    
    case $region_choice in
        1) region="Hhohho" ;;
        2) region="Manzini" ;;
        3) region="Shiselweni" ;;
        4) region="Lubombo" ;;
        *) echo "Invalid choice. Defaulting to Hhohho."; region="Hhohho" ;;
    esac
    
    country="Eswatini"

    # Append the new citizen to the file
    echo "$nid:$lastname:$firstname:$dob:$residence:$region:$country" >> "$CITIZENS_FILE"
    echo "✓ Citizen registered successfully!"
    
    # Show age information
    age=$(calculate_age "$dob")
    echo "✓ Citizen age: $age years"
    if [ $age -ge 70 ]; then
        echo "✓ This citizen is ELIGIBLE for elderly grant"
    else
        echo "⚠ This citizen is NOT eligible for elderly grant (requires 70+ years)"
    fi
    
    pause
}

# Search citizens by NID, LastName, Residence, Region 
search_citizens() {
    echo
    echo "--- Search Citizens ---"
    echo "1. Search by National ID"
    echo "2. Search by Last Name" 
    echo "3. Search by Residence"
    echo "4. Search by Region"
    echo -n "Enter your search choice [1-4]: "
    read -r search_choice

    case $search_choice in
        1) echo -n "Enter National ID: "; read -r term; field=1 ;;
        2) echo -n "Enter Last Name: "; read -r term; field=2 ;;
        3) echo -n "Enter Residence: "; read -r term; field=5 ;;
        4) echo -n "Enter Region: "; read -r term; field=6 ;;
        *) echo "Invalid choice."; pause; return ;;
    esac

    echo
    echo "Search Results:"
    echo "---------------"
    
    found=0
    while IFS=: read -r nid lname fname dob res reg country; do
        # Check if this citizen is deceased
        deceased=""
        if grep -q "^$nid:" "$DECEASED_FILE"; then
            deceased=" [DECEASED]"
        fi
        
        # Search in the specific field
        case $field in
            1) if [[ "$nid" == "$term" ]]; then found=1; fi ;;
            2) if [[ "${lname,,}" == *"${term,,}"* ]]; then found=1; fi ;;
            5) if [[ "${res,,}" == *"${term,,}"* ]]; then found=1; fi ;;
            6) if [[ "${reg,,}" == *"${term,,}"* ]]; then found=1; fi ;;
        esac
        
        if [ $found -eq 1 ]; then
            age=$(calculate_age "$dob")
            echo "NID: $nid | Name: $fname $lname | Age: $age | DOB: $dob"
            echo "Residence: $res, Region: $reg$deceased"
            echo "---"
            found=0
        fi
    done < "$CITIZENS_FILE"
    
    if ! grep -q ":" <<< "$(grep -i "$term" "$CITIZENS_FILE")"; then
        echo "No matching citizens found."
    fi
    pause
}

# Register death
register_death() {
    echo
    echo "--- Death Registration ---"
    echo -n "Enter National ID of the deceased: "
    read -r nid
    
    # Check if citizen exists
    citizen_info=$(grep "^$nid:" "$CITIZENS_FILE")
    if [[ -z "$citizen_info" ]]; then
        echo "Error: No citizen found with NID $nid."
        pause
        return
    fi
    
    # Check if already deceased
    if grep -q "^$nid:" "$DECEASED_FILE"; then
        echo "Error: This citizen is already registered as deceased."
        pause
        return
    fi

    # Show citizen info
    IFS=':' read -r nid lname fname dob res reg country <<< "$citizen_info"
    age=$(calculate_age "$dob")
    echo "Citizen: $fname $lname (Age: $age, NID: $nid)"
    
    echo -n "Enter Cause of Death: "
    read -r cause
    
    # Date of Death with validation
    while true; do
        echo -n "Enter Date of Death (YYYY-MM-DD): "
        read -r dod
        if validate_date "$dod"; then
            break
        else
            echo "Error: Invalid date format. Please use YYYY-MM-DD."
        fi
    done
    
    echo -n "Enter Place of Death: "
    read -r pod

    # Append to the deceased file
    echo "$nid:$cause:$dod:$pod" >> "$DECEASED_FILE"
    echo "✓ Death registered successfully."
    echo "✓ Grant payments for NID $nid have been halted."
    pause
}

#  Retrieve deceased info 
retrieve_deceased() {
    echo
    echo "--- Deceased Information ---"
    if [[ ! -s "$DECEASED_FILE" ]]; then
        echo "No deceased records found."
    else
        # Print a header
        printf "%-15s %-20s %-12s %-10s %-20s\n" "NID" "Name" "Age at Death" "DoD" "Cause of Death"
        echo "--------------------------------------------------------------------------------"
        while IFS=: read -r nid cause dod pod; do
            # Get citizen details
            citizen_info=$(grep "^$nid:" "$CITIZENS_FILE")
            if [[ -n "$citizen_info" ]]; then
                IFS=':' read -r nid lname fname dob res reg country <<< "$citizen_info"
                age_at_death=$(calculate_age "$dob")
                name="$fname $lname"
                printf "%-15s %-20s %-12s %-10s %-20s\n" "$nid" "$name" "$age_at_death" "$dod" "$cause"
            fi
        done < "$DECEASED_FILE"
    fi
    pause
}

# Extract eligible elders (70+ years) on the 25th monthly
extract_eligible_elders() {
    echo
    echo "--- Extracting Eligible Elders (70+ Years) ---"
    
    # Check if today is the 25th (for automation)
    current_day=$(date +%d)
    if [[ $current_day -eq 25 ]]; then
        echo "✓ Automated extraction running on the 25th of the month."
    else
        echo "⚠ Manual extraction (today is not the 25th)."
    fi

    echo
    echo "Eligible Citizens for Grant:"
    echo "============================"
    eligible_found=0

    while IFS=: read -r nid lname fname dob res reg country; do
        # Skip if this citizen is deceased
        if grep -q "^$nid:" "$DECEASED_FILE"; then
            continue
        fi
        
        age=$(calculate_age "$dob")
        if [[ $age -ge 70 ]]; then
            echo "✓ NID: $nid"
            echo "  Name: $fname $lname"
            echo "  Age: $age years"
            echo "  Residence: $res, Region: $reg"
            echo "  ---"
            eligible_found=1
        fi
    done < "$CITIZENS_FILE"

    if [[ $eligible_found -eq 0 ]]; then
        echo "No eligible elders found."
    else
        total_eligible=$(grep -c ":" "$CITIZENS_FILE" | while read -r nid lname fname dob res reg country; do
            if ! grep -q "^$nid:" "$DECEASED_FILE"; then
                age=$(calculate_age "$dob")
                if [[ $age -ge 70 ]]; then
                    echo "1"
                fi
            fi
        done | wc -l)
        echo "Total eligible elders: $total_eligible"
    fi
    pause
}

#  Capture paid/unpaid status
capture_grant_status() {
    echo
    echo "--- Capture Grant Payment Status ---"
    echo -n "Enter National ID of the beneficiary: "
    read -r nid
    
    # Check if citizen exists
    citizen_info=$(grep "^$nid:" "$CITIZENS_FILE")
    if [[ -z "$citizen_info" ]]; then
        echo "Error: No citizen found with NID $nid."
        pause
        return
    fi
    
    # Check if deceased
    if grep -q "^$nid:" "$DECEASED_FILE"; then
        echo "Error: This citizen is deceased and cannot receive payments."
        pause
        return
    fi
    
    IFS=':' read -r nid lname fname dob res reg country <<< "$citizen_info"
    age=$(calculate_age "$dob")
    
    # Check eligibility
    if [[ $age -lt 70 ]]; then
        echo "Error: This citizen is only $age years old and is not eligible (requires 70+)."
        pause
        return
    fi

    echo "Citizen: $fname $lname (Age: $age, Region: $reg)"
    echo -n "Enter Payment Month (YYYY-MM): "
    read -r payment_month
    
    # Validate month format
    if [[ ! $payment_month =~ ^[0-9]{4}-[0-9]{2}$ ]]; then
        echo "Error: Invalid month format. Use YYYY-MM."
        pause
        return
    fi
    
    echo "Payment Status:"
    echo "1. Paid"
    echo "2. Unpaid"
    echo "3. Pending"
    echo -n "Select status [1-3]: "
    read -r status_choice

    case $status_choice in
        1) status="Paid" ;;
        2) status="Unpaid" ;;
        3) status="Pending" ;;
        *) echo "Invalid choice."; pause; return ;;
    esac

    # Remove old entry if exists and add new one
    grep -v "^$nid:$payment_month:" "$GRANTS_FILE" > "${GRANTS_FILE}.tmp" 2>/dev/null
    mv "${GRANTS_FILE}.tmp" "$GRANTS_FILE" 2>/dev/null
    echo "$nid:$payment_month:$status" >> "$GRANTS_FILE"
    
    echo "✓ Payment status for $fname $lname for $payment_month set to: $status"
    pause
}

#  Retrieve grant details (paid/unpaid) 
retrieve_grant_details() {
    echo
    echo "--- Retrieve Grant Details ---"
    echo "1. For a specific beneficiary"
    echo "2. All beneficiaries for a specific month"
    echo "3. All payment records"
    echo -n "Enter your choice [1-3]: "
    read -r detail_choice

    case $detail_choice in
        1)
            echo -n "Enter National ID: "
            read -r nid
            
            # Check if citizen exists
            citizen_info=$(grep "^$nid:" "$CITIZENS_FILE")
            if [[ -z "$citizen_info" ]]; then
                echo "Error: No citizen found with NID $nid."
                pause
                return
            fi
            
            IFS=':' read -r nid lname fname dob res reg country <<< "$citizen_info"
            echo "Grant details for: $fname $lname (NID: $nid)"
            echo "--------------------------------------------"
            
            records_found=0
            grep "^$nid:" "$GRANTS_FILE" | while IFS= read -r line; do
                IFS=':' read -r nid month status <<< "$line"
                echo "Month: $month, Status: $status"
                records_found=1
            done
            
            if [[ $records_found -eq 0 ]]; then
                echo "No grant records found for this beneficiary."
            fi
            ;;
            
        2)
            echo -n "Enter Payment Month (YYYY-MM): "
            read -r month
            echo "Grant details for Month: $month"
            echo "--------------------------------"
            
            records_found=0
            grep ":$month:" "$GRANTS_FILE" | while IFS= read -r line; do
                IFS=':' read -r nid month status <<< "$line"
                citizen_info=$(grep "^$nid:" "$CITIZENS_FILE")
                if [[ -n "$citizen_info" ]]; then
                    IFS=':' read -r nid lname fname dob res reg country <<< "$citizen_info"
                    echo "NID: $nid, Name: $fname $lname, Status: $status"
                    records_found=1
                fi
            done
            
            if [[ $records_found -eq 0 ]]; then
                echo "No records found for month $month."
            fi
            ;;
            
        3)
            echo "All Grant Payment Records:"
            echo "=========================="
            if [[ ! -s "$GRANTS_FILE" ]]; then
                echo "No grant records found."
            else
                printf "%-15s %-20s %-10s %-10s\n" "NID" "Name" "Month" "Status"
                echo "--------------------------------------------------"
                while IFS=: read -r nid month status; do
                    citizen_info=$(grep "^$nid:" "$CITIZENS_FILE")
                    if [[ -n "$citizen_info" ]]; then
                        IFS=':' read -r nid lname fname dob res reg country <<< "$citizen_info"
                        printf "%-15s %-20s %-10s %-10s\n" "$nid" "$fname $lname" "$month" "$status"
                    fi
                done < "$GRANTS_FILE"
            fi
            ;;
        *)
            echo "Invalid choice."
            ;;
    esac
    pause
}

#  Menu/Dashboard implementation & Creativity
# This is the main loop that drives the menu.
while true; do
    show_main_menu
    read -r choice
    case $choice in
        1) register_citizen ;;
        2) search_citizens ;;
        3) register_death ;;
        4) retrieve_deceased ;;
        5) extract_eligible_elders ;;
        6) capture_grant_status ;;
        7) retrieve_grant_details ;;
        8) 
            echo "Generating System Report..."
            echo "==========================="
            total_citizens=$(wc -l < "$CITIZENS_FILE" 2>/dev/null || echo 0)
            total_deceased=$(wc -l < "$DECEASED_FILE" 2>/dev/null || echo 0)
            total_grants=$(wc -l < "$GRANTS_FILE" 2>/dev/null || echo 0)
            
            echo "--- System Statistics ---"
            echo "Total Registered Citizens: $total_citizens"
            echo "Total Deceased Citizens: $total_deceased"
            echo "Total Grant Records: $total_grants"
            echo "Live Citizens: $((total_citizens - total_deceased))"
            
            # Count eligible elders
            eligible_count=0
            while IFS=: read -r nid lname fname dob res reg country; do
                if ! grep -q "^$nid:" "$DECEASED_FILE"; then
                    age=$(calculate_age "$dob")
                    if [[ $age -ge 70 ]]; then
                        ((eligible_count++))
                    fi
                fi
            done < "$CITIZENS_FILE"
            
            echo "Eligible Elders (70+): $eligible_count"
            echo "Report generated on: $(date)"
            pause 
            ;;
        9) 
            echo "Exiting EGMS. Thank you for serving the people of Eswatini!"
            exit 0 
            ;;
        *) 
            echo "Invalid option. Please select a number between 1 and 9."
            pause 
            ;;
    esac
done


