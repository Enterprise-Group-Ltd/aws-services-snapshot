#! /bin/bash
#
#
# ------------------------------------------------------------------------------------
#
# MIT License
# 
# Copyright (c) 2017 Enterprise Group, Ltd.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# ------------------------------------------------------------------------------------
# 
# File: aws-services-snapshot.sh
#
script_version=1.3.22   
#
#  Dependencies:
#  - 'aws-services-snapshot-driver.txt' or custom driver file containing AWS describe/list commands 
#  - 'aws-services-snapshot-driver-global.txt' containing AWS global services (not limited to an AWS region) 
#  - bash shell
#  - jq - JSON wrangler https://stedolan.github.io/jq/
#  - AWS CLI tools (pre-installed on AWS AMIs) 
#  - AWS CLI profile with IAM permissions for the AWS CLI command:
#    - aws ec2 describe-instances (used to test for valid -r region )
#    - aws sts get-caller-identity (used to pull account number )
#    - aws iam list-account-aliases (used to pull account alias )
#  - AWS CLI profile with IAM permissions for the AWS CLI 'service describe'
#    'service list' commands included in the aws-snapshot-services-driver.txt file
#
# Tested on: 
#   Windows Subsystem for Linux (WSL) 
#     OS Build: 15063.540
#     bash.exe version: 10.0.15063.0
#     Ubuntu 16.04
#     GNU bash, version 4.3.48(1)
#     jq 1.5-1-a5b5cbe
#     aws-cli/1.11.134 Python/2.7.12 Linux/4.4.0-43-Microsoft botocore/1.6.1
#   
#   AWS EC2
#     Amazon Linux AMI release 2017.03 
#     Linux 4.9.43-17.38.amzn1.x86_64 
#     GNU bash, version 4.2.46(2)
#     jq-1.5
#     aws-cli/1.11.133 Python/2.7.12 Linux/4.9.43-17.38.amzn1.x86_64 botocore/1.6.0
#
#
# By: Douglas Hackney
#     https://github.com/dhackney   
# 
# Type: AWS utility
# Description: 
#   This shell script snapshots the current state of AWS resources and writes it to JSON files
#
#
# Roadmap:
# - support multiple qualifiers
# - auto-support --account-id qualifier
# - validate driver file prior to run
# - driver line parameter "$" suffix to tag services with fixed/regular costs, e.g. load balancers  
# 
#
###############################################################################
# 
# set the environmental variables 
#
set -o pipefail 
#
###############################################################################
# 
#
# initialize the script variables
#
aws_account=""
aws_account_alias=""
aws_command=""
aws_query_parameter_supplemental_01=""
aws_query_parameter_supplemental_01_value=""
aws_region=""
aws_region_fn_AWS_pull_snapshots=""
aws_region_fn_create_merged_services_json_file=""
aws_region_list=""
aws_service=""
aws_service_1st_char=""
aws_service_key_colon=""
aws_service_key_list=""
aws_service_key_list_sort=""
aws_service_snapshot_name=""
aws_service_snapshot_name_underscore=""
aws_service_strip=""
aws_snapshot_name=""
choices=""
cli_profile=""
count_array_service_snapshot_recursive=0
count_aws_region_check=0
count_aws_region_list=0
count_aws_service_key_list=0
count_cli_profile=0
count_cli_profile_regions=0
count_driver_services=0
count_error_aws_no_endpoint=0
count_error_lines=0
count_files_snapshots=0
count_files_snapshots_all=0
count_global_services_names=0
count_global_services_names_check=0
count_global_services_names_file=0
count_lines_service_snapshot_recursive=0
count_not_found_error=0
count_services_driver_list=0
count_script_version_length=0
count_text_header_length=0
count_text_block_length=0
count_text_width_menu=0
count_text_width_header=0
count_text_side_length_menu=0
count_text_side_length_header=0
count_text_bar_menu=0
count_text_bar_header=0
count_this_file_tasks=0
counter_aws_region_list=0
counter_aws_service_key_list=0
counter_driver_services=0
counter_files_snapshots=0
counter_files_snapshots_all=0
counter_snapshots=0
counter_this_file_tasks=0
count_this_file_tasks_end=0
count_this_file_tasks_increment=0
date_file="$(date +"%Y-%m-%d-%H%M%S")"
date_now="$(date +"%Y-%m-%d-%H%M%S")"
_empty=""
_empty_task=""
_empty_task_sub=""
error_line_aws=""
error_line_jq=""
error_line_pipeline=""
feed_write_log=""
file_driver=""
file_driver_global=""
file_target_initialize_region=""
file_target_initialize_file=""
files_snapshots=""
files_snapshots_source=""
files_snapshots_source_merge=""
files_snapshots_target=""
files_snapshots_all=""
files_snapshots_all_source=""
files_snapshots_all_source_merge=""
files_snapshots_all_target=""
_fill=""
_fill_task=""
_fill_task_sub=""
find_name=""
find_name_fn_create_merged_services_json_file=""
flag_recursive_command=""
full_path=""
let_done=""
let_done_task=""
let_done_task_sub=""
let_left=""
let_left_task=""
let_left_task_sub=""
let_progress=""
let_progress_task=""
let_progress_task_sub=""
logging=""
log_suffix=""
merge_service_recursive_files_snapshots_source="" 
merge_service_recursive_files_snapshots_target="" 
merge_service_recursive=""
merge_service_recursive_key_name=""
parameter1=""
paramter2=""
pattern_load_feed=""
pattern_load_value=""
service_snapshot=""
service_snapshot_build_01=""
service_snapshot_build_02=""
service_snapshot_recursive=""
service_snapshot_recursive_object_key=""
service_snapshot_recursive_service_key=""
services_driver_list=""
snapshot_source_recursive_command=""
snapshot_target_recursive_command=""
text_bar_menu_build=""
text_bar_header_build=""
text_side_menu=""
text_side_header=""
text_menu=""
text_menu_bar=""
text_header=""
text_header_bar=""
this_file=""
this_file_account_services_all=""
this_file_account_region_services_all=""
this_file_account_region_services_all_global=""
this_file_account_region_services_all_target=""
this_log=""
thislogdate=""
this_log_file=""
this_log_file_errors=""
this_log_file_errors_full_path=""
this_log_file_full_path=""
this_log_temp_file_full_path=""
this_path=""
this_path_temp=""
this_summary_report=""
this_summary_report_full_path=""
this_user=""
this_utility_acronym=""
this_utility_filename_plug=""
verbose=""
write_file=""
write_file_clean=""
write_file_full_path=""
write_file_raw=""
write_file_service_names=""
write_file_service_names_unique=""
write_path=""
write_path_snapshots=""
#
###############################################################################
# 
#
# initialize the baseline variables
#
this_utility_acronym="sps"
this_utility_filename_plug="snapshot"
date_file="$(date +"%Y-%m-%d-%H%M%S")"
this_path="$(pwd)"
this_file="$(basename "$0")"
full_path="${this_path}"/"$this_file"
this_log_temp_file_full_path="$this_path"/"$this_utility_filename_plug"-log-temp.log 
this_user="$(whoami)"
count_this_file_tasks="$(cat "$full_path" | grep -c "\-\-\- begin\: " )"
count_this_file_tasks_end="$(cat "$full_path" | grep -c "\-\-\- end\: " )"
count_this_file_tasks_increment="$(cat "$full_path" | grep -c "fnCounterIncrementTask" )"
count_this_file_tasks_increment=$((count_this_file_tasks_increment-3))
counter_this_file_tasks=0
logging="x"
counter_snapshots=0
file_driver_global='aws-services-snapshot-driver-global.txt'
#
###############################################################################
# 
# initialize the temp log file
#
echo "" > "$this_log_temp_file_full_path"
#
#
##############################################################################################################33
#                           Function definition begin
##############################################################################################################33
#
#
# Functions definitions
#
#######################################################################
#
#
#
#######################################################################
#
#
# function to display the Usage  
#
#
function fnUsage()
{
    echo ""
    echo " ---------------------------------------- AWS Service Snapshot utility usage -----------------------------------------"
    echo ""
    echo " This utility snapshots the current state of AWS Services  "  
    echo ""
    echo " This script will: "
    echo " * Capture the current state of AWS Services "
    echo " * Write the current state to JSON files  "
    echo ""
    echo "----------------------------------------------------------------------------------------------------------------------"
    echo ""
    echo " Usage:"
    echo "         aws-services-snapshot.sh -p AWS_CLI_profile "
    echo ""
    echo "         Optional parameters: -d MyDriverFile -r AWS_region -b y -g y "
    echo ""
    echo " Where: "
    echo "  -p - Name of the AWS CLI cli_profile (i.e. what you would pass to the --profile parameter in an AWS CLI command)"
    echo "         Example: -p myAWSCLIprofile "
    echo ""    
    echo "  -d - Driver file name. If no name is provided, the utility defaults to: aws-services-snapshot-driver.txt "
    echo "         Example: -d aws-services-snapshot-driver-prod.txt "
    echo ""    
    echo "  -r - AWS region to snapshot. Default is the AWS CLI profile's region. Enter 'all' for all regions. "
    echo "       A list of available AWS regions is here: "
    echo "       http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html#concepts-available-regions"
    echo "         Example: -r us-east-2 "
    echo "         Example: -r all "
    echo ""        
    echo "  -b - Verbose console output. Set to 'y' for verbose console output. Temp files are not deleted. "
    echo "         Example: -b y "
    echo ""
    echo "  -g - Logging on / off. Default is off. Set to 'y' to create an info log. Set to 'z' to create a debug log. "
    echo "       Note: logging mode is slower and debug log mode will be very slow and resource intensive on large jobs. "
    echo "         Example: -g y "
    echo ""
    echo "  -h - Display this message"
    echo "         Example: -h "
    echo ""
    echo "  ---version - Display the script version"
    echo "         Example: --version "
    echo ""
    echo ""
    exit 1
}
#
#######################################################################
#
#
# function to echo the progress bar to the console  
#
# source: https://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script
#
# 1. Create ProgressBar function
# 1.1 Input is currentState($1) and totalState($2)
function fnProgressBar() 
{
    #
    # Process data
            let _progress=(${1}*100/"${2}"*100)/100
            let _done=(${_progress}*4)/10
            let _left=40-"$_done"
    # Build progressbar string lengths
            _fill="$(printf "%${_done}s")"
            _empty="$(printf "%${_left}s")"
    #
    # 1.2 Build progressbar strings and print the ProgressBar line
    # 1.2.1 Output example:
    # 1.2.1.1  Progress : [########################################] 100%
    printf "\r          Overall Progress : [${_fill// /#}${_empty// /-}] ${_progress}%%"
}
#
#######################################################################
#
#
# function to update the task progress bar   
#
# source: https://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script
#
# 1. Create ProgressBar function
# 1.1 Input is currentState($1) and totalState($2)
function fnProgressBarTask() 
{
    #    
    # Process data
            let _progress_task=(${1}*100/"${2}"*100)/100
            let _done_task=(${_progress_task}*4)/10
            let _left_task=40-"$_done_task"
    # Build progressbar string lengths
            _fill_task="$(printf "%${_done_task}s")"
            _empty_task="$(printf "%${_left_task}s")"
    #
    # 1.2 Build progressbar strings and print the ProgressBar line
    # 1.2.1 Output example:
    # 1.2.1.1  Progress : [########################################] 100%
    printf "\r             Task Progress : [${_fill_task// /#}${_empty_task// /-}] ${_progress_task}%%"
}
#
#######################################################################
#
#
# function to update the subtask progress bar   
#
# source: https://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script
#
# 1. Create ProgressBar function
# 1.1 Input is currentState($1) and totalState($2)
function fnProgressBarTaskSub() 
{
    #    
    # Process data
            let _progress_task_sub=(${1}*100/"${2}"*100)/100
            let _done_task_sub=(${_progress_task_sub}*4)/10
            let _left_task_sub=40-"$_done_task_sub"
    # Build progressbar string lengths
            _fill_task_sub="$(printf "%${_done_task_sub}s")"
            _empty_task_sub="$(printf "%${_left_task_sub}s")"
    #
    # 1.2 Build progressbar strings and print the ProgressBar line
    # 1.2.1 Output example:
    # 1.2.1.1  Progress : [########################################] 100%
    printf "\r         Sub-Task Progress : [${_fill_task_sub// /#}${_empty_task_sub// /-}] ${_progress_task_sub}%%"
}
#
#######################################################################
#
#
# function to display the task progress bar on the console  
#
# parameter 1 = counter
# paramter 2 = count
# 
function fnProgressBarTaskDisplay() 
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnProgressBarTaskDisplay' "
    fnWriteLog ${LINENO} ""
    #    
    fnWriteLog ${LINENO} level_0 " ---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 "" 
    fnProgressBarTask "$1" "$2"
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} level_0 " ---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
}
#
#######################################################################
#
#
# function to display the task progress bar on the console  
#
# parameter 1 = counter
# paramter 2 = count
# 
function fnProgressBarTaskSubDisplay() 
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnProgressBarTaskSubDisplay' "
    fnWriteLog ${LINENO} ""
    #    
    fnWriteLog ${LINENO} level_0 " ---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 "" 
    fnProgressBarTaskSub "$1" "$2"
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} level_0 " ---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
}
#
#######################################################################
#
#
# function to echo the header to the console  
#
function fnHeader()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnHeader' "
    fnWriteLog ${LINENO} ""
    #    
    clear
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} "--------------------------------------------------------------------------------------------------------------------"    
    fnWriteLog ${LINENO} "--------------------------------------------------------------------------------------------------------------------" 
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "$text_header"    
    fnWriteLog ${LINENO} level_0 "" 
    fnProgressBar ${counter_this_file_tasks} ${count_this_file_tasks}
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} level_0 "$text_header_bar"
    fnWriteLog ${LINENO} level_0 ""
}
#
#######################################################################
#
#
# function to echo to the console and write to the log file 
#
function fnWriteLog()
{
    # clear IFS parser
    IFS=
    # write the output to the console
    fnOutputConsole "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
    # if logging is enabled, then write to the log
    if [[ ("$logging" = "y") || ("$logging" = "z") || ("$logging" = "x")   ]] 
        then
            # write the output to the log
            fnOutputLog "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
    fi 
    # reset IFS parser to default values 
    unset IFS
}
#
#######################################################################
#
#
# function to echo to the console  
#
function fnOutputConsole()
{
   #
    # console output section
    #
    # test for verbose
    if [ "$verbose" = "y" ] ;  
        then
            # if verbose console output then
            # echo everything to the console
            #
            # strip the leading 'level_0'
                if [ "$2" = "level_0" ] ;
                    then
                        # if the line is tagged for display in non-verbose mode
                        # then echo the line to the console without the leading 'level_0'     
                        echo " Line: "$1" "$3" "$4" "$5" "$6" "$7" "$8" "$9""
                    else
                        # if a normal line echo all to the console
                        echo " Line: "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9""
                fi
    else
        # test for minimum console output
        if [ "$2" = "level_0" ] ;
            then
                # echo ""
                # echo "console output no -v: the logic test for level_0 was true"
                # echo ""
                # if the line is tagged for display in non-verbose mode
                # then echo the line to the console without the leading 'level_0'     
                echo " "$3" "$4" "$5" "$6" "$7" "$8" "$9""
        fi
    fi
    #
    #

}  

#
#######################################################################
#
#
# function to write to the log file 
#
function fnOutputLog()
{
    # log output section
    #
    # load the timestamp
    thislogdate="$(date +"%Y-%m-%d-%H:%M:%S")"
    #
    # ----------------------------------------------------------
    #
    # normal logging
    # 
    # append the line to the log variable
    # the variable is written to the log file on exit by function fnWriteLogFile
    #
    #
    if [ "$2" = "level_0" ] ;
        then
            # if the line is tagged for logging in non-verbose mode
            # then write the line to the log without the leading 'level_0'     
            this_log+="$(echo "${thislogdate} Line: "$1" "$3" "$4" "$5" "$6" "$7" "$8" "$9"" 2>&1)" 
        else
            # if a normal line write the entire set to the log
            this_log+="$(echo "${thislogdate} Line: "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"" 2>&1)" 
    fi
    #
    # append the new line  
    # do not quote this variable
    this_log+=$'\n'
    #
    #  
    # ---------------------------------------------------------
    #
    # 'use this for debugging' - debug logging
    #
    # if the script is crashing and you cannot debug it from the 'info' mode log produced by -g y, 
    # then enable 'verbose' console output and 'debug' logging mode
    #
    # note that the 'debug' form of logging is VERY slow on big jobs
    # 
    # use parameters: -b y -g z 
    #
    # if the script crashes before writing out the log you can scroll back in the console to 
    # identify the line number where the problem is located 
    #
    # 
}
#
#######################################################################
#
#
# function to append the log variable to the temp log file 
#
function fnWriteLogTempFile()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnWriteLogTempFile' "
    fnWriteLog ${LINENO} ""
    # 
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "Appending the log variable to the temp log file"
    fnWriteLog ${LINENO} "" 
    echo "$this_log" >> "$this_log_temp_file_full_path"
    # empty the temp log variable
    this_log=""
}
#
#######################################################################
#
#
# function to write log variable to the log file 
#
function fnWriteLogFile()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnWriteLogFile' "
    fnWriteLog ${LINENO} ""
    #     
    # append the temp log file onto the log file
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} "Writing temp log to log file"
    fnWriteLog ${LINENO} "Value of variable 'this_log_temp_file_full_path': "
    fnWriteLog ${LINENO} "$this_log_temp_file_full_path"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "Value of variable 'this_log_file_full_path': "
    fnWriteLog ${LINENO} "$this_log_file_full_path"
    fnWriteLog ${LINENO} level_0 ""   
    # write the contents of the variable to the temp log file
    fnWriteLogTempFile
    cat "$this_log_temp_file_full_path" >> "$this_log_file_full_path"
    echo "" >> "$this_log_file_full_path"
    echo "Log end" >> "$this_log_file_full_path"
    # delete the temp log file
    rm -f "$this_log_temp_file_full_path"
}
#
##########################################################################
#
#
# function to delete the work files 
#
function fnDeleteWorkFiles()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnDeleteWorkFiles' "
    fnWriteLog ${LINENO} ""
    #   
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in delete work files "
    fnWriteLog ${LINENO} "value of variable 'verbose': "$verbose" "
    fnWriteLog ${LINENO} ""
        if [ "$verbose" != "y" ] ;  
            then
                # if not verbose console output then delete the work files
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "In non-verbose mode: Deleting work files"
                fnWriteLog ${LINENO} ""
                feed_write_log="$(rm -f "$this_path_temp"/"$this_utility_acronym"-* 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                feed_write_log="$(rm -f "$this_path_temp"/"$this_utility_acronym"_* 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "value of variable 'this_log_file_full_path' "$this_log_file_full_path" "
                fnWriteLog ${LINENO} "$feed_write_log"
                fnWriteLog ${LINENO} ""
                feed_write_log="$(rm -f "$write_path_snapshots"/"$this_utility_acronym"* 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                feed_write_log="$(rm -f "$write_path_snapshots"/"$this_utility_acronym"* 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                fnWriteLog ${LINENO} ""
                feed_write_log="$(rm -r -f "$this_path_temp" 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                #
                # if no errors, then delete the error log file
                count_error_lines="$(cat "$this_log_file_errors_full_path" | wc -l)"
                if (( "$count_error_lines" < 3 ))
                    then
                        rm -f "$this_log_file_errors_full_path"
                fi  
            else
                # in verbose mode so preserve the work files 
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "In verbose mode: Preserving work files "
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "work files are here: "$this_path" "
                fnWriteLog ${LINENO} level_0 ""                
        fi       
}
#
##########################################################################
#
#
# function to load the pattern with the built-up service    
#
function fnPatternLoad()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnPatternLoad' "
    fnWriteLog ${LINENO} ""
    #       
    #
    # check for debug log 
    if [[ "$logging" = 'z' ]] 
        then 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "--------------------------------------------------------------"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "--------------------------------------------------------------"
            fnWriteLog ${LINENO} "" 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of variable 'pattern_load_feed':"
            feed_write_log="$(echo "$pattern_load_feed" )"
            fnWriteLog ${LINENO} "$feed_write_log"
            fnWriteLog ${LINENO} ""
    #
    fi  # end check for debug log 
    #
    #
    fnWriteLog ${LINENO} "loading variable 'pattern_load_value' with JSON pattern and inserted service snapshot " 
    fnWriteLog ${LINENO} "using variables: 'pattern_load_feed' / "aws_account" / "aws_region_fn_AWS_pull_snapshots" / "aws_service" / "aws_service_snapshot_name_underscore" "       
    fnWriteLog ${LINENO} "using variables: 'pattern_load_feed' / "$aws_account" / "$aws_region_fn_AWS_pull_snapshots" / "$aws_service" / "$aws_service_snapshot_name_underscore" "
    # the built-up AWS service is put into the following structure as an array at the position of the '.' 
    pattern_load_value="$(echo "$pattern_load_feed" \
    | jq -s --arg aws_account_jq "$aws_account" --arg aws_region_fn_AWS_pull_snapshots_jq "$aws_region_fn_AWS_pull_snapshots" --arg aws_service_jq "$aws_service" --arg aws_service_snapshot_name_underscore_jq "$aws_service_snapshot_name_underscore" '{ account: $aws_account_jq, regions: [ { regionName: $aws_region_fn_AWS_pull_snapshots_jq, regionServices: [ { serviceType: $aws_service_jq, service: [ { ($aws_service_snapshot_name_underscore_jq): . } ] } ] } ] }' 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "value of variable 'pattern_load_value':"
            fnWriteLog ${LINENO} level_0 "$pattern_load_value"
            fnWriteLog ${LINENO} level_0 ""
            #
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi
    #
    #
    # check for debug log 
    if [[ "$logging" = 'z' ]] 
        then 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "--------------------------------------------------------------"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "--------------------------------------------------------------"
            fnWriteLog ${LINENO} "" 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of variable 'pattern_load_value':"
            feed_write_log="$(echo "$pattern_load_value" )"
            fnWriteLog ${LINENO} "$feed_write_log"
            fnWriteLog ${LINENO} ""
    #     
    fi  # end check for debug log 
    #
    #
}
#
##########################################################################
#
#
# function to initialze the output file with the load pattern    
#
function fnInitializeWriteFileBuildPattern()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnInitializeWriteFileBuildPattern' "
    fnWriteLog ${LINENO} ""
    #       
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "Function-specific variables: "  
    fnWriteLog ${LINENO} "------------------------------------------------"  
    fnWriteLog ${LINENO} "value of variable 'file_target_initialize_region':"
    fnWriteLog ${LINENO} "$file_target_initialize_region"
    fnWriteLog ${LINENO} ""
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'file_target_initialize_file':"
    fnWriteLog ${LINENO} "$file_target_initialize_file"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "------------------------------------------------"  
    fnWriteLog ${LINENO} ""
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "Non-function specific variables: "    
    fnWriteLog ${LINENO} "------------------------------------------------"  
    fnWriteLog ${LINENO} "value of variable 'aws_account':"
    fnWriteLog ${LINENO} "$aws_account"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'aws_service':"
    fnWriteLog ${LINENO} "$aws_service"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'aws_service_snapshot_name_underscore':"
    fnWriteLog ${LINENO} "$aws_service_snapshot_name_underscore"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "------------------------------------------------"  
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "loading the pattern"
    feed_write_log="$(echo "{ \"account\": \"$aws_account\",\"regions\": [ { \"regionName\": \"$file_target_initialize_region\",\"regionServices\": [ { \"serviceType\": \"$aws_service\",\"service\": [ { \"$aws_service_snapshot_name_underscore\": [ ] } ] } ] } ] }" > "$this_path_temp"/"$file_target_initialize_file" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #                                                                                                
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi  # end check for pipeline error(s)        
    #
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    #
}
#
##########################################################################
#
#
# function to initialze the target region / service write file    
#
function fnInitializeWriteFileBuild()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnInitializeWriteFileBuild' "
    fnWriteLog ${LINENO} ""
    #       
    fnWriteLog ${LINENO} ""  
    fnWriteLog ${LINENO} "in the function: 'fnInitializeWriteFileBuild' - initialize target data file for service writes  "  
    fnWriteLog ${LINENO} "initializing the data file "   
    #
    file_target_initialize_region="$aws_region_fn_AWS_pull_snapshots"
    file_target_initialize_file="$this_utility_acronym"-write-file-build.json
    #
    # calling function to initialize the output file 
    fnInitializeWriteFileBuildPattern
    # 

    # feed_write_log="$(echo "{ \"account\": \"$aws_account\",\"regions\": [ { \"regionName\": \"$aws_region_fn_AWS_pull_snapshots\",\"regionServices\": [ { \"serviceType\": \"$aws_service\",\"service\": [ ] } ] } ] }" > "$this_path_temp"/"$this_utility_acronym"-write-file-build.json  2>&1)"

    #
    fnWriteLog ${LINENO} "Contents of file: sps-write-file-build.json"
    fnWriteLog ${LINENO} ""  
    feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-build.json  2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"-write-file-build.json:"
            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-build.json)"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #                                                                                                            
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
}
#
##########################################################################
#
#
# function to append the recursive command service snapshot  
#
function fnWriteCommandFileRecursive()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnWriteCommandFileRecursive' "
    fnWriteLog ${LINENO} ""
    #        
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "Appending the recursive-command JSON snapshot for: "$aws_service" "$aws_command" "$aws_query_parameter" "$aws_service_key_list_line" "
    #
    #
    # load the source and target JSON files
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "loading file: "$this_utility_acronym"-snapshot_recursive_source.json from variable 'service_snapshot' "
    echo "$service_snapshot" > "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_source.json
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"-snapshot_recursive_source.json :"
            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_source.json)"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #                                         
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    fnWriteLog ${LINENO} ""
    #

    #
    # check for debug log 
    if [[ "$logging" = 'z' ]] 
        then 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "--------------------------------------------------------------"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "--------------------------------------------------------------"
            fnWriteLog ${LINENO} "" 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "contents of file "$this_utility_acronym"-snapshot_recursive_source.json :"
            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_source.json)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"-snapshot_recursive_source.json :"
                    feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_source.json)"
                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                    fnWriteLog ${LINENO} level_0 ""
                    #                                         
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
                    #
            fi
            #
            fnWriteLog ${LINENO} "$feed_write_log"
            fnWriteLog ${LINENO} ""              
        #     
    fi  # end check for debug log 
    #                                    
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "loading file: "$this_utility_acronym"-snapshot_recursive_target_build.json from variable 'snapshot_source_recursive_command' "
    echo "$snapshot_source_recursive_command" > "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_target_build.json 
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"-snapshot_recursive_target_build.json :"
            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_target_build.json)"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #                                         
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    fnWriteLog ${LINENO} ""
    #
    #
    # check for debug log 
    if [[ "$logging" = 'z' ]] 
        then 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "--------------------------------------------------------------"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "--------------------------------------------------------------"
            fnWriteLog ${LINENO} "" 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "contents of file "$this_utility_acronym"-snapshot_recursive_target_build.json :"
            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_target_build.json)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"-snapshot_recursive_target_build.json :"
                    feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_target_build.json)"
                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                    fnWriteLog ${LINENO} level_0 ""
                    #                                         
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
                    #
            fi
            #
            fnWriteLog ${LINENO} "$feed_write_log"
            fnWriteLog ${LINENO} ""
    #     
    fi  # end check for debug log 
    #                                       
    fnWriteLog ${LINENO} ""
    #
    #
    # call the array merge recursive command function  
    # parameters are: source target 
    # output file name of the function is: "$this_utility_acronym"-merge-services-file-build-temp.json
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "calling function: 'fnMergeArraysServicesRecursiveJsonFile' with parameters: "
    fnWriteLog ${LINENO} "source:"
    fnWriteLog ${LINENO} ""$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_source.json"
    fnWriteLog ${LINENO} ""      
    fnWriteLog ${LINENO} "target:"
    fnWriteLog ${LINENO} ""$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_target_build.json"
    fnWriteLog ${LINENO} ""
    fnMergeArraysServicesRecursiveJsonFile "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_source.json "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_target_build.json
    #
    #    
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "Copying contents of file: "$this_utility_acronym"-merge-services-recursive-file-build-temp.json to file: "$this_utility_acronym"-snapshot_recursive_target.json  "
    fnWriteLog ${LINENO} ""  
    cp -f "$this_path_temp"/"$this_utility_acronym"-merge-services-recursive-file-build-temp.json "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_target.json
    fnWriteLog ${LINENO} ""  
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    # check for debug log 
    if [[ "$logging" = 'z' ]] 
        then 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "--------------------------------------------------------------"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "--------------------------------------------------------------"
            fnWriteLog ${LINENO} "" 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "Contents of file: "$this_utility_acronym"-snapshot_recursive_target.json "
            fnWriteLog ${LINENO} ""  
            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_target.json  2>&1)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                    fnWriteLog ${LINENO} level_0 ""
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"-snapshot_recursive_target.json:"
                    feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_target.json)"
                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                    fnWriteLog ${LINENO} level_0 ""
                    #                                         
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
                    #
            fi
            #
            fnWriteLog ${LINENO} "$feed_write_log"
            fnWriteLog ${LINENO} ""
    #     
    fi  # end check for debug log 
    #                                         
    fnWriteLog ${LINENO} ""

    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "loading variable 'snapshot_target_recursive_command' with the contents of file: "$this_utility_acronym"-snapshot_recursive_target.json "
    snapshot_target_recursive_command="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_target.json)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "value of variable 'snapshot_target_recursive_command':"
            fnWriteLog ${LINENO} level_0 "$snapshot_target_recursive_command"
            fnWriteLog ${LINENO} level_0 ""
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"-snapshot_recursive_target.json :"
            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_target.json)"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #                                         
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
            fi
            #
            #
            # check for debug log 
            if [[ "$logging" = 'z' ]] 
                then 
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "--------------------------------------------------------------"
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "--------------------------------------------------------------"
                    fnWriteLog ${LINENO} "" 
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "value of variable 'snapshot_target_recursive_command':"
                    fnWriteLog ${LINENO} "$snapshot_target_recursive_command"
                    fnWriteLog ${LINENO} ""
                #     
            fi  # end check for debug log 
            #                                         
}
#
##########################################################################
#
#
# function to log non-fatal errors 
#
function fnErrorLog()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnErrorLog' "
    fnWriteLog ${LINENO} ""
    #       
    fnWriteLog ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------"       
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Error message: "
    fnWriteLog ${LINENO} level_0 " "$feed_write_log""
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------" 
    echo "-----------------------------------------------------------------------------------------------------" >> "$this_log_file_errors_full_path"         
    echo "" >> "$this_log_file_errors_full_path" 
    echo " Error message: " >> "$this_log_file_errors_full_path" 
    echo " "$feed_write_log"" >> "$this_log_file_errors_full_path" 
    echo "" >> "$this_log_file_errors_full_path"
    echo "-----------------------------------------------------------------------------------------------------" >> "$this_log_file_errors_full_path" 
}
#
##########################################################################
#
#
# function to handle command or pipeline errors 
#
function fnErrorPipeline()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnErrorPipeline' "
    fnWriteLog ${LINENO} ""
    #       
    fnWriteLog ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------"       
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Command or Command Pipeline Error "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " System Error while running the previous command or pipeline "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Please check the error message above "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Error at script line number: "$error_line_pipeline" "
    fnWriteLog ${LINENO} level_0 ""
    if [[ ("$logging" = "y") || ("$logging" = "z") ]] 
        then 
            fnWriteLog ${LINENO} level_0 " The log will also show the error message and other environment, variable and diagnostic information "
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 " The log is located here: "
            fnWriteLog ${LINENO} level_0 " "$this_log_file_full_path" "
    fi
    fnWriteLog ${LINENO} level_0 ""        
    fnWriteLog ${LINENO} level_0 " Exiting the script"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    # append the temp log onto the log file
    fnWriteLogTempFile
    # write the log variable to the log file
    fnWriteLogFile
    exit 1
}
#
##########################################################################
#
#
# function for AWS CLI errors 
#
function fnErrorAws()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnErrorAws' "
    fnWriteLog ${LINENO} ""
    #       
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " AWS Error while executing AWS CLI command"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Please check the AWS error message above "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Error at script line number: "$error_line_aws" "
    fnWriteLog ${LINENO} level_0 ""
    if [[ ("$logging" = "y") || ("$logging" = "z") ]]
        then 
            fnWriteLog ${LINENO} level_0 " The log will also show the AWS error message and other diagnostic information "
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 " The log is located here: "
            fnWriteLog ${LINENO} level_0 " "$write_path"/ "
            fnWriteLog ${LINENO} level_0 " "$this_log_file" "
    fi 
    fnWriteLog ${LINENO} level_0 ""        
    fnWriteLog ${LINENO} level_0 " Exiting the script"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    # append the temp log onto the log file
    fnWriteLogTempFile
    # write the log variable to the log file
    fnWriteLogFile
    exit 1
}
#
##########################################################################
#
#
# function for jq errors 
#
function fnErrorJq()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnErrorJq' "
    fnWriteLog ${LINENO} ""
    #    
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Error at script line number: "$error_line_jq" "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " There was a jq error while processing JSON "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Please check the jq error message above "
    fnWriteLog ${LINENO} level_0 ""
    if [[ ("$logging" = "y") || ("$logging" = "z") ]]
        then 
            fnWriteLog ${LINENO} level_0 " The log will also show the AWS error message and other diagnostic information "
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 " The log is located here: "
            fnWriteLog ${LINENO} level_0 " "$write_path"/ "
            fnWriteLog ${LINENO} level_0 " "$this_log_file" "
    fi
    fnWriteLog ${LINENO} level_0 " The log will also show the jq error message and other diagnostic information "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " The log is located here: "
    fnWriteLog ${LINENO} level_0 " "$this_log_file_full_path" "
    fnWriteLog ${LINENO} level_0 ""        
    fnWriteLog ${LINENO} level_0 " Exiting the script"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    # append the temp log onto the log file
    fnWriteLogTempFile
    # write the log variable to the log file
    fnWriteLogFile
    exit 1
}
#
##########################################################################
#
#
# function to increment the snapshot counter 
#
function fnCounterIncrementSnapshots()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnCounterIncrementSnapshots' "
    fnWriteLog ${LINENO} ""
    #      
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "increment the snapshots counter: 'counter_snapshots'"
    counter_snapshots="$((counter_snapshots+1))"
    fnWriteLog ${LINENO} "post-increment value of variable 'counter_snapshots': "$counter_snapshots" "
    fnWriteLog ${LINENO} ""
    #
}
#
##########################################################################
#
#
# function to increment the task counter 
#
function fnCounterIncrementTask()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnCounterIncrementTask' "
    fnWriteLog ${LINENO} ""
    #      
    fnWriteLog ${LINENO} ""  
    fnWriteLog ${LINENO} "incrementing the task counter"
    counter_this_file_tasks="$((counter_this_file_tasks+1))" 
    fnWriteLog ${LINENO} "value of variable 'counter_this_file_tasks': "$counter_this_file_tasks" "
    fnWriteLog ${LINENO} "value of variable 'count_this_file_tasks': "$count_this_file_tasks" "
    fnWriteLog ${LINENO} ""
}
#
##########################################################################
#
#
# function to increment the region counter 
#
function fnCounterIncrementRegions()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnCounterIncrementRegions' "
    fnWriteLog ${LINENO} ""
    #      
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "increment the regions counter: 'counter_aws_region_list'"
    counter_aws_region_list="$((counter_aws_region_list+1))"
    fnWriteLog ${LINENO} "post-increment value of variable 'counter_aws_region_list': "$counter_aws_region_list" "
    fnWriteLog ${LINENO} "value of variable 'count_aws_region_list': "$count_aws_region_list" "
    fnWriteLog ${LINENO} ""
    #
}
#
##########################################################################
#
#
#  function to remove duplicates from the services snapshotted file 
#
function fnDuplicateRemoveSnapshottedServices()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnDuplicateRemoveSnapshottedServices' "
    fnWriteLog ${LINENO} ""
    #     
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'write_file_service_names': "
    fnWriteLog ${LINENO} "$write_file_service_names"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "contents of file "$write_file_service_names" prior to unique: " 
    feed_write_log="$(cat "$write_file_service_names" 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "loading variable 'write_file_service_names_unique' "
    write_file_service_names_unique="$(cat "$write_file_service_names" | sort -u)"
    fnWriteLog ${LINENO} "value of variable 'write_file_service_names_unique': "
    fnWriteLog ${LINENO} "$write_file_service_names_unique"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "writing unique list to file: ${!write_file_service_names} " 
    feed_write_log="$(echo "$write_file_service_names_unique" > "$write_file_service_names" 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "contents of file "$write_file_service_names" after unique: " 
    feed_write_log="$(cat "$write_file_service_names" 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                fnWriteLog ${LINENO} level_0 "$feed_write_log"
                fnWriteLog ${LINENO} level_0 ""
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "contents of file "$write_file_service_names":"
                feed_write_log="$(cat "$write_file_service_names")"
                fnWriteLog ${LINENO} level_0 "$feed_write_log"
                fnWriteLog ${LINENO} level_0 ""
                #                                                                                                                            
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
    fnWriteLog ${LINENO} "$feed_write_log"
}
#
##########################################################################
#
#
# function to pull the snapshots from AWS    
#
function fnAwsPullSnapshots()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnAwsPullSnapshots' "
    fnWriteLog ${LINENO} ""
    #       
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "---------------------------------------- begin pull the snapshots ---------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    # display the header
    fnHeader
    #
    #
    fnWriteLog ${LINENO} "reset the task counter variable 'counter_driver_services' "
    counter_driver_services=0
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "loading the variable 'region_fn_AWS_pull_snapshots' from the function parameter 1: "$1" "  
    aws_region_fn_AWS_pull_snapshots=$1
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'region_fn_AWS_pull_snapshots': "$aws_region_fn_AWS_pull_snapshots" "  
    fnWriteLog ${LINENO} "" 
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} " in section: begin pull the snapshots"
    fnWriteLog ${LINENO} "------------------------------------------------"  
    fnWriteLog ${LINENO} "value of variable 'aws_account':"
    fnWriteLog ${LINENO} "$aws_account"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'aws_service':"
    fnWriteLog ${LINENO} "$aws_service"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'aws_service_snapshot_name_underscore':"
    fnWriteLog ${LINENO} "$aws_service_snapshot_name_underscore"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "------------------------------------------------"  
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "check for global region "  
    if [[ "$aws_region_fn_AWS_pull_snapshots" = 'global' ]] 
        then 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "region is global so setting the read loop to source from the global services names list file "  
            fnWriteLog ${LINENO} "loading variable 'services_driver_list' from the file: " 
            fnWriteLog ${LINENO} ""$this_path_temp"/"$this_utility_acronym"-global-services-names.txt " 
            fnWriteLog ${LINENO} "command: cat "$this_path_temp"/"$this_utility_acronym"-global-services-names.txt "
            # remove empty lines via grep
            # remove duplicate lines while retaining line order via awk
            # awk command: https://unix.stackexchange.com/questions/30173/how-to-remove-duplicate-lines-inside-a-text-file
            # awk command explanation: print the current line if it hasn't been seen yet, then increment the seen counter for this line 
            # (uninitialized variables or array elements have the numerical value 0)
            services_driver_list="$(cat "$this_path_temp"/"$this_utility_acronym"-global-services-names.txt | grep -v -e '^$' | awk '!seen[$0] {print} {seen[$0] += 1}' )"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "value of variable 'services_driver_list':"
                    fnWriteLog ${LINENO} level_0 "$services_driver_list"
                    fnWriteLog ${LINENO} level_0 ""
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "contents of file "$this_path_temp"/"$this_utility_acronym"-global-services-names.txt :"
                    feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-global-services-names.txt)"
                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                    fnWriteLog ${LINENO} level_0 ""
                    #                                                                                                                                            
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
                    #
            fi  # end check for pipeline error 
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of variable 'services_driver_list':"
            fnWriteLog ${LINENO} " "$services_driver_list" "  
            # test for zero global services 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "checking for zero global services to snapshot "  
            count_services_driver_list="$(echo $services_driver_list | grep -v -e '^$' | wc -l)"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of variable 'count_services_driver_list':"
            fnWriteLog ${LINENO} " "$count_services_driver_list" "  
            if [[ "$count_services_driver_list" -eq 0 ]] 
                then 
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "there are zero global services to snapshot; skipping via the 'continue' command "  
                    #
                    continue 
                    # 
            fi  # end test for zero global services 
            #
        else 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "region is not global so using default read of services to snapshot "  
            services_driver_list="$(cat "$this_path_temp"/"$this_utility_acronym"-aws-services-snapshot-driver-stripped.txt)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "value of variable 'services_driver_list':"
                    fnWriteLog ${LINENO} level_0 "$services_driver_list"
                    fnWriteLog ${LINENO} level_0 ""
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "contents of file "$this_path_temp"/"$this_utility_acronym"-aws-services-snapshot-driver-stripped.txt :"
                    feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-aws-services-snapshot-driver-stripped.txt)"
                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                    fnWriteLog ${LINENO} level_0 ""
                    #                                                                                                                                            
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
                    #
            fi  # end check for pipeline error 
            #
    fi  # end test for global region 
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'services_driver_list':"
    feed_write_log="$(echo "$services_driver_list" 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "value of variable 'services_driver_list':"
                fnWriteLog ${LINENO} level_0 "$services_driver_list"
                fnWriteLog ${LINENO} level_0 ""
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
    fnWriteLog ${LINENO} "$feed_write_log"
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "entering the loop: 'read sps-aws-services-snapshot-driver-stripped.txt' "  
    while read -r aws_service aws_command aws_query_parameter aws_service_key 
    do
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "----------------------- loop head: read sps-aws-services-snapshot-driver-stripped.txt -----------------------  "
        fnWriteLog ${LINENO} ""
        # display the header    
        fnHeader
        # display the task progress bar
        fnProgressBarTaskDisplay "$counter_aws_region_list" "$count_aws_region_list"
        #
        # display the sub task progress bar
        fnProgressBarTaskSubDisplay "$counter_driver_services" "$count_driver_services"
        #
        #
        # debug
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'services_driver_list':"
        feed_write_log="$(echo "$services_driver_list" 2>&1)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "value of variable 'services_driver_list':"
                    fnWriteLog ${LINENO} level_0 "$services_driver_list"
                    fnWriteLog ${LINENO} level_0 ""
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
        fnWriteLog ${LINENO} "$feed_write_log"
        #
        #
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "loading the variable 'count_global_services_names' "  
        count_global_services_names="$(cat "$this_path_temp"/"$this_utility_acronym"-global-services-names.txt | grep -v -e '^$' | wc -l)"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'count_global_services_names': "$count_global_services_names" "  
        fnWriteLog ${LINENO} "" 
        #
        fnWriteLog ${LINENO} "stripping trailing 'new line' from inputs "
        # do not quote the $'\n' variable 
        aws_service="${aws_service//$'\n'/}"
        aws_command="${aws_command//$'\n'/}"
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "setting the snapshot name "
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'aws_command': "$aws_command" "
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "parsing the snapshot name from the aws_command"
        fnWriteLog ${LINENO} "loading variable 'aws_snapshot_name'"    
        aws_snapshot_name="$(echo "$aws_command" | grep -o '\-.*' | cut -f2- -d\- 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "value of variable 'aws_snapshot_name':"
                fnWriteLog ${LINENO} level_0 "$aws_snapshot_name"
                fnWriteLog ${LINENO} level_0 ""
                #                                                                                                                                            
                # call the command / pipeline error function
                fnErrorPipeline
                #
                #
        fi
        #
        # check for global services
        # if a global service, append it to the global services run file
        #
        if [[ "$aws_region_fn_AWS_pull_snapshots" != 'global' ]] 
            then 
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "checking for global service for AWS service: "$aws_service" "
                while read -r global_service_line 
                    do 
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "value of variable 'aws_service': "$aws_service" "
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "value of variable 'global_service_line': "$global_service_line" "
                        fnWriteLog ${LINENO} ""
                        #
                        # check if the service is global
                        if [[ "$aws_service" = "$global_service_line" ]] 
                            then 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "this 'aws_service' is a global service: "$aws_service" "
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "appending the 'aws_service' to the global services run file: "$this_utility_acronym"-global-services-names.txt"
                                feed_write_log="$(echo ""$aws_service"" ""$aws_command"" ""$aws_query_parameter"" ""$aws_service_key"" >> "$this_path_temp"/"$this_utility_acronym"-global-services-names.txt 2>&1)"
                                fnWriteLog ${LINENO} "$feed_write_log"
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "contents of file: "$this_utility_acronym"-global-services-names.txt "
                                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-global-services-names.txt 2>&1)"
                                #
                                # check for command / pipeline error(s)
                                if [ "$?" -ne 0 ]
                                    then
                                        #
                                        # set the command/pipeline error line number
                                        error_line_pipeline="$((${LINENO}-7))"
                                        #
                                        #
                                        fnWriteLog ${LINENO} level_0 ""
                                        fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                                        fnWriteLog ${LINENO} level_0 "$feed_write_log"
                                        fnWriteLog ${LINENO} level_0 ""
                                        #
                                        fnWriteLog ${LINENO} level_0 ""
                                        fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"-global-services-names.txt:"
                                        feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-global-services-names.txt)"
                                        fnWriteLog ${LINENO} level_0 "$feed_write_log"
                                        fnWriteLog ${LINENO} level_0 ""
                                        #                                                                                                                                            
                                        # call the command / pipeline error function
                                        fnErrorPipeline
                                        #
                                        #
                                fi  # end check for pipeline error 
                                #
                                fnWriteLog ${LINENO} "$feed_write_log"
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} ""
                                #
                                fnWriteLog ${LINENO} "breaking out of the loop via the 'break' command "
                                #
                                break 
                                #
                        fi  # end check for global service 
                # 
                done< <(echo "$driver_global_services")
                #
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "loading the variable 'count_global_services_names_check' "  
                count_global_services_names_check="$(cat "$this_path_temp"/"$this_utility_acronym"-global-services-names.txt | grep -v -e '^$' | wc -l)"
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "value of variable 'count_global_services_names_check': "$count_global_services_names_check" "  
                fnWriteLog ${LINENO} "value of variable 'count_global_services_names': "$count_global_services_names" "  
                fnWriteLog ${LINENO} "" 
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "checking to see if the service name was added to the global list "  
                if [[ "$count_global_services_names" -lt "$count_global_services_names_check" ]] 
                    then 
                        #
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "resetting the variable 'count_global_services_names_check' "
                        count_global_services_names_check=0
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "value of variable 'count_global_services_names_check': "$count_global_services_names_check" "  
                        #  
                        fnWriteLog ${LINENO} "skipping to the next service via the 'continue' command "
                        #
                        continue
                        #
                fi  # end check for global service 
                #
        fi  # end check for global region 
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'aws_service': "$aws_service" "             
        fnWriteLog ${LINENO} "value of variable 'aws_snapshot_name': "$aws_snapshot_name" "  
        aws_service_snapshot_name="$(echo "$aws_service"---"$aws_snapshot_name")"   
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'aws_service_snapshot_name': "$aws_service_snapshot_name" "  
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "loading variable 'aws_service_snapshot_name_underscore' "
        aws_service_snapshot_name_underscore="$(echo "$aws_service_snapshot_name" | sed s/-/_/g | tr -d '@')"   
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'aws_service_snapshot_name_underscore': "$aws_service_snapshot_name_underscore" "  
        fnWriteLog ${LINENO} ""
        #
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "loading variable 'aws_snapshot_name_underscore' "
        aws_snapshot_name_underscore="$(echo "$aws_snapshot_name" | sed s/-/_/g )"   
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'aws_snapshot_name_underscore': "$aws_snapshot_name_underscore" "  
        fnWriteLog ${LINENO} ""
        #
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "resetting the recursive run flag"
        flag_recursive_command="n" 
        fnWriteLog ${LINENO} "value of variable 'flag_recursive_command':"
        feed_write_log="$(echo "$flag_recursive_command" 2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} "testing for recursive command "
        aws_service_1st_char="$(echo "$aws_service" | cut -c1)"
        #
        # --------------------------------------------- test for recursive command ---------------------------------------------
        #
        if [[ "$aws_service_1st_char" == "@" ]] ;
            then 
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "this is a recursive command: "$aws_service" "               
                #
                # strip the leading @
                aws_service_strip="$(echo "$aws_service" | cut -c 2- )"
                #
                # if region is not global, then check for global services 
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "checking if region is 'global' "
                fnWriteLog ${LINENO} "value of variable 'aws_region_fn_AWS_pull_snapshots': "$aws_region_fn_AWS_pull_snapshots" "
                if [[ "$aws_region_fn_AWS_pull_snapshots" != 'global' ]] 
                    then 
                        # check for global services
                        # if a global service, append it to the global services run file
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "checking for global service for AWS service: "$aws_service_strip" "
                        while read -r global_service_line 
                            do 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "value of variable 'aws_service_strip': "$aws_service_strip" "
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "value of variable 'global_service_line': "$global_service_line" "
                                fnWriteLog ${LINENO} ""
                                #
                                # check if the service is global
                                if [[ "$aws_service_strip" = "$global_service_line" ]] 
                                    then 
                                        fnWriteLog ${LINENO} ""
                                        fnWriteLog ${LINENO} "this 'aws_service_strip' is a global service: "$aws_service_strip" "
                                        fnWriteLog ${LINENO} ""
                                        fnWriteLog ${LINENO} "appending the 'aws_service_strip' to the global services run file: "$this_utility_acronym"-global-services-names.txt"
                                        feed_write_log="$(echo "@"$aws_service_strip"" ""$aws_command"" ""$aws_query_parameter"" ""$aws_service_key"" >> "$this_path_temp"/"$this_utility_acronym"-global-services-names.txt 2>&1)"
                                        fnWriteLog ${LINENO} "$feed_write_log"
                                        fnWriteLog ${LINENO} ""
                                        fnWriteLog ${LINENO} "contents of file: "$this_utility_acronym"-global-services-names.txt "
                                        feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-global-services-names.txt 2>&1)"
                                        #
                                        # check for command / pipeline error(s)
                                        if [ "$?" -ne 0 ]
                                            then
                                                #
                                                # set the command/pipeline error line number
                                                error_line_pipeline="$((${LINENO}-7))"
                                                #
                                                #
                                                fnWriteLog ${LINENO} level_0 ""
                                                fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                                                fnWriteLog ${LINENO} level_0 "$feed_write_log"
                                                fnWriteLog ${LINENO} level_0 ""
                                                #
                                                fnWriteLog ${LINENO} level_0 ""
                                                fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"-global-services-names.txt:"
                                                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-global-services-names.txt)"
                                                fnWriteLog ${LINENO} level_0 "$feed_write_log"
                                                fnWriteLog ${LINENO} level_0 ""
                                                #                                                                                                                                            
                                                # call the command / pipeline error function
                                                fnErrorPipeline
                                                #
                                                #
                                        fi  # end check for pipeline error 
                                        #
                                        fnWriteLog ${LINENO} "$feed_write_log"
                                        fnWriteLog ${LINENO} ""
                                        fnWriteLog ${LINENO} "breaking out of the loop via the 'break' command "
                                        #
                                        break 
                                        #
                                fi  # end check for global service 
                        # 
                        done< <(echo "$driver_global_services")
                        #
                        #
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "loading the variable 'count_global_services_names_check' "  
                        count_global_services_names_check="$(cat "$this_path_temp"/"$this_utility_acronym"-global-services-names.txt | grep -v -e '^$' | wc -l)"
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "value of variable 'count_global_services_names_check': "$count_global_services_names_check" "  
                        fnWriteLog ${LINENO} "value of variable 'count_global_services_names': "$count_global_services_names" "  
                        fnWriteLog ${LINENO} "" 
                        #
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "checking to see if the service name was added to the global list "  
                        if [[ "$count_global_services_names" -lt "$count_global_services_names_check" ]] 
                            then 
                                #
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "resetting the variable 'count_global_services_names_check' "
                                count_global_services_names_check=0
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "value of variable 'count_global_services_names_check': "$count_global_services_names_check" "  
                                #  
                                fnWriteLog ${LINENO} "skipping to the next service via the 'continue' command "
                                #
                                continue
                                #
                        fi  # end check for global service 
                        #
                fi  # end check for global region 
                #
                #
                # test for no endpoint results from the parent service 
                #
                # following disabled for speed, enable for debugging
                # fnWriteLog ${LINENO} ""
                # fnWriteLog ${LINENO} "value of variable 'service_snapshot_recursive':"
                # feed_write_log="$(echo "$service_snapshot_recursive" 2>&1)"
                # fnWriteLog ${LINENO} "$feed_write_log"
                # fnWriteLog ${LINENO} ""
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "loading variable 'count_lines_service_snapshot_recursive' "               
                count_lines_service_snapshot_recursive="$(echo "$service_snapshot_recursive" | wc -l)" 
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "value of variable 'count_lines_service_snapshot_recursive': "$count_lines_service_snapshot_recursive" "               
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "testing for empty results from no endpoint or no return for the parent service "               
                if [[ "$count_lines_service_snapshot_recursive" -le 1 ]] 
                    then 
                        # if no endpoint, then skip and continue 
                        #
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "no endpoint found for the parent service so resetting the variable 'service_snapshot' " 
                        fnWriteLog ${LINENO} "and 'service_snapshot_recursive' and skipping to the next via the 'continue' command "
                        service_snapshot=""
                        service_snapshot_recursive=""
                        #
                        continue 
                        #
                        #
                fi  # end check for no endpoint parent service results                         
                #
                #
                # test for null results from the parent service 
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "loading variable 'service_snapshot_recursive_object_key' "    
                service_snapshot_recursive_object_key="$(echo "$service_snapshot_recursive" | jq 'keys' | tr -d '",][ ' | grep -v -e '^$' 2>&1)"
                fnWriteLog ${LINENO} "value of variable: 'service_snapshot_recursive_object_key': "$service_snapshot_recursive_object_key"  "                              
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "loading variable 'count_array_service_snapshot_recursive' "                                
                count_array_service_snapshot_recursive="$(echo "$service_snapshot_recursive" | jq --arg service_snapshot_recursive_object_key_jq "$service_snapshot_recursive_object_key" '.[$service_snapshot_recursive_object_key_jq] | length ' 2>&1)" 
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "value of variable 'count_array_service_snapshot_recursive': "$count_array_service_snapshot_recursive" "               
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "testing for empty results from no endpoint or no return for the parent service "               
                if [[ "$count_array_service_snapshot_recursive" -eq 0 ]] 
                    then 
                        # if null results for parent service, then skip and continue 
                        #
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "null retults for the parent service so resetting the variable 'service_snapshot' " 
                        fnWriteLog ${LINENO} "and 'service_snapshot_recursive' and skipping to the next via the 'continue' command "
                        service_snapshot=""
                        service_snapshot_recursive=""
                        #
                        continue 
                        #
                        #
                fi  # end check for null parent service results                         
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "setting the recursive run flag"
                flag_recursive_command="y" 
                fnWriteLog ${LINENO} "value of variable 'flag_recursive_command':"
                feed_write_log="$(echo "$flag_recursive_command" 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                fnWriteLog ${LINENO} ""
                #
                aws_service="$(echo "$aws_service_strip")"
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "value of variable 'aws_service_strip':"
                feed_write_log="$(echo "$aws_service_strip" 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                fnWriteLog ${LINENO} ""
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "value of variable 'aws_service':"
                feed_write_log="$(echo "$aws_service" 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                fnWriteLog ${LINENO} ""
                #
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "loading variable 'aws_service_snapshot_name' "
                fnWriteLog ${LINENO} "value of variable 'aws_service': "$aws_service" "             
                fnWriteLog ${LINENO} "value of variable 'aws_snapshot_name': "$aws_snapshot_name" "  
                aws_service_snapshot_name="$(echo "$aws_service"---"$aws_snapshot_name")"   
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "value of variable 'aws_service_key' :"
                feed_write_log="$(echo "$aws_service_key" 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                fnWriteLog ${LINENO} ""
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "in recursive command:  aws_service / aws_command / aws_query_parameter / aws_service_key "
                fnWriteLog ${LINENO} "in recursive command: "$aws_service" / "$aws_command" / "$aws_query_parameter" / "$aws_service_key" "
                fnWriteLog ${LINENO} ""
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "value of variable 'aws_service_key':  "
                feed_write_log="$(echo "$aws_service_key" 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                fnWriteLog ${LINENO} ""
                #
                #
                # check for debug log 
                if [[ "$logging" = 'z' ]] 
                    then 
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "--------------------------------------------------------------"
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "--------------------------------------------------------------"
                        fnWriteLog ${LINENO} "" 
                        fnWriteLog ${LINENO} ""               
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "value of variable 'service_snapshot_recursive':"
                        feed_write_log="$(echo "$service_snapshot_recursive" 2>&1)"
                        fnWriteLog ${LINENO} "$feed_write_log"
                        fnWriteLog ${LINENO} ""               
                #     
                fi  # end check for debug log 
                #                                         
                fnWriteLog ${LINENO} "loading the list of keys from variable 'service_snapshot_recursive' "
                fnWriteLog ${LINENO} "to drive the AWS queries to variable : 'aws_service_key_list' " 
                #
                # test for S3 and SQS JSON structure
                if [[ ("$aws_service" = "s3api" ) && ( "$aws_service_key" = "Name")  ]] ;
                    then 
                        # S3 JSON structure
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "in s3 JSON structure "
                        aws_service_key_list="$(echo "$service_snapshot_recursive" | jq -r '.Buckets[].Name' 2>&1 )"
                        #
                    elif [[ ("$aws_service" = "sqs" ) && ( "$aws_service_key" = "QueueUrls")  ]] ;
                        then
                        # SQS JSON structure
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "in SQS JSON structure "
                        aws_service_key_list="$(echo "$service_snapshot_recursive" | jq -r '.QueueUrls' | jq -r '.[]' 2>&1 )"
                        #
                    else 
                        # normal JSON structure
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "in normal JSON structure "
                        aws_service_key_list="$(echo "$service_snapshot_recursive" | jq -r --arg aws_service_key_jq "$aws_service_key" '.[] | .[] | .[$aws_service_key_jq]' 2>&1 )"
                fi
                # check for jq error
                if [ "$?" -ne 0 ]
                    then
                        # jq error 
                        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
                        fnWriteLog ${LINENO} level_0 ""
                        fnWriteLog ${LINENO} level_0 "jq error message: "
                        fnWriteLog ${LINENO} level_0 "$aws_service_key_list"
                        fnWriteLog ${LINENO} level_0 ""
                        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
                        #
                        # set the jqerror line number
                        error_line_jq="$((${LINENO}-13))"
                        #
                        # call the jq error handler
                        fnErrorJq
                        #
                fi # end jq error
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "value of variable 'aws_service_key_list':"
                feed_write_log="$(echo "$aws_service_key_list" 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                fnWriteLog ${LINENO} ""
                #   
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "sorting variable: 'aws_service_key_list'; loading variable: 'aws_service_key_list_sort' "     
                aws_service_key_list_sort="$(echo "$aws_service_key_list" | sort )"
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "value of variable 'aws_service_key_list_sort':"
                feed_write_log="$(echo "$aws_service_key_list_sort" 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                fnWriteLog ${LINENO} ""
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "loading variable: 'aws_service_key_list' "     
                aws_service_key_list="$(echo "$aws_service_key_list_sort" )"
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "value of variable 'aws_service_key_list':"
                feed_write_log="$(echo "$aws_service_key_list" 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} ""
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "set the counters for the subtask progress bar "
                count_aws_service_key_list="$(echo "$aws_service_key_list" | wc -l )"
                counter_aws_service_key_list=0
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "value of variable 'count_aws_service_key_list': "$count_aws_service_key_list""
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "value of variable 'counter_aws_service_key_list': "$counter_aws_service_key_list""
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} ""
                #            
                # read the list of service keys and query the service for the JSON values
                while read -r aws_service_key_list_line
                    do
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "----------------------- loop head: read variable 'aws_service_key_list' -----------------------  "
                        fnWriteLog ${LINENO} ""
                        # display the header    
                        fnHeader
                        # display the task progress bar
                        fnProgressBarTaskDisplay "$counter_aws_region_list" "$count_aws_region_list"
                        # display the sub-task progress bar
                        fnProgressBarTaskSubDisplay "$counter_aws_service_key_list" "$count_aws_service_key_list"
                        #
                        fnWriteLog ${LINENO} level_0 ""
                        fnWriteLog ${LINENO} level_0 "This sub-task takes a while. Please wait..."
                        fnWriteLog ${LINENO} level_0 ""
                        fnWriteLog ${LINENO} level_0 ""
                        fnWriteLog ${LINENO} level_0 "Pulling the AWS Services from AWS for region: "$aws_region_fn_AWS_pull_snapshots"..."
                        fnWriteLog ${LINENO} level_0 ""   
                        fnWriteLog ${LINENO} level_0 ""                                                 
                        fnWriteLog ${LINENO} level_0 "Creating a snapshot for: "$aws_service" "$aws_snapshot_name" "$aws_service_key_list_line"  " 
                        fnWriteLog ${LINENO} ""   
                        fnWriteLog ${LINENO} "using recursive command: aws "aws_service" / "aws_command" / "aws_query_parameter" / "aws_service_key_list_line" / --profile "$cli_profile" "                     
                        fnWriteLog ${LINENO} "using recursive command: aws "$aws_service" / "$aws_command" / "$aws_query_parameter" / "$aws_service_key_list_line" / --profile "$cli_profile" "      
                        fnWriteLog ${LINENO} ""    
                        #
                        # test for first time through loop
                        if [[ "$counter_aws_service_key_list" -eq 0 ]] ;
                            then 
                                #
                                fnWriteLog ${LINENO} "value of variable 'counter_aws_service_key_list': "$counter_aws_service_key_list" "
                                fnWriteLog ${LINENO} "first time through the loop - initializing the data file"   
                                write_file_raw="$(echo "aws-""$aws_account"-"$aws_region_fn_AWS_pull_snapshots"-snapshot-"$date_file"-"$aws_service"-"$aws_snapshot_name"-"$aws_command".json)" 
                                fnWriteLog ${LINENO} "value of variable 'write_file_raw': "$write_file_raw" "
                                write_file_clean="$(echo "$write_file_raw" | tr "/%\\<>:" "_" )"
                                fnWriteLog ${LINENO} ""    
                                fnWriteLog ${LINENO} "value of variable 'write_file_clean': "$write_file_clean" "
                                write_file="$(echo "$write_file_clean")"
                                fnWriteLog ${LINENO} ""    
                                write_file_full_path="$write_path_snapshots"/"$write_file"
                                fnWriteLog ${LINENO} "value of variable 'write_file': "$write_file" "
                                fnWriteLog ${LINENO} ""    
                                fnWriteLog ${LINENO} "value of variable 'write_file_full_path': "$write_file_full_path" "
                                #
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "Initialize the JSON file for "$aws_service"-"$aws_snapshot_name"-"$aws_command" "
                                fnWriteLog ${LINENO} "Creating file: "$write_file_full_path""
                                fnWriteLog ${LINENO} ""  
                                #
                                ##########################################################################
                                #
                                #
                                # initialze the target region / service write file    
                                #
                                fnWriteLog ${LINENO} ""  
                                #
                                fnInitializeWriteFileBuild
                                #
                                fnWriteLog ${LINENO} ""    
                                fnWriteLog ${LINENO} "first time through the loop"
                                fnWriteLog ${LINENO} "load the variable 'snapshot_source_recursive_command' with the contents of the file:"
                                fnWriteLog ${LINENO} ""$this_path_temp"/"$this_utility_acronym"-write-file-build.json :"
                                snapshot_source_recursive_command="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-build.json  2>&1)"
                                #
                                # check for command / pipeline error(s)
                                if [ "$?" -ne 0 ]
                                    then
                                        #
                                        # set the command/pipeline error line number
                                        error_line_pipeline="$((${LINENO}-7))"
                                        #
                                        #
                                        fnWriteLog ${LINENO} level_0 ""
                                        fnWriteLog ${LINENO} level_0 "value of variable 'snapshot_source_recursive_command':"
                                        fnWriteLog ${LINENO} level_0 "$snapshot_source_recursive_command"
                                        fnWriteLog ${LINENO} level_0 ""
                                        #
                                        fnWriteLog ${LINENO} level_0 ""
                                        fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"-write-file-build.json:"
                                        feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-build.json)"
                                        fnWriteLog ${LINENO} level_0 "$feed_write_log"
                                        fnWriteLog ${LINENO} level_0 ""
                                        #                                                                                                                                            
                                        # call the command / pipeline error function
                                        fnErrorPipeline
                                        #
                                        #
                                fi  # end check for pipeline error 
                                #
                                fnWriteLog ${LINENO} ""    
                                fnWriteLog ${LINENO} "value of variable 'snapshot_source_recursive_command':"
                                feed_write_log="$(echo "$snapshot_source_recursive_command" 2>&1)"
                                fnWriteLog ${LINENO} "$feed_write_log"
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} ""    
                                fnWriteLog ${LINENO} ""

                        fi  # end test for first time through loop 
                        # 
                        # query AWS for the service values 
                        #
                        fnWriteLog ${LINENO} "------------------------------------------------------------------------------------------------"   
                        fnWriteLog ${LINENO} "          querying AWS for the sub-task service values "   
                        fnWriteLog ${LINENO} "------------------------------------------------------------------------------------------------"   
                        fnWriteLog ${LINENO} ""   
                        fnWriteLog ${LINENO} ""    
                        fnWriteLog ${LINENO} "value of variable 'aws_service': "$aws_service" "
                        fnWriteLog ${LINENO} ""    
                        fnWriteLog ${LINENO} "value of variable 'aws_command': "$aws_command" "     
                        #              
                        # check for special sub-tasks that require additional query qualifiers
                        #
                        fnWriteLog ${LINENO} ""   
                        fnWriteLog ${LINENO} "testing for required supplemental fixed query parameters"    
                        if [[ ("$aws_service" = "sqs") && ("$aws_command" = "get-queue-attributes") ]] ;
                            then 
                                aws_query_parameter_supplemental_01="--attribute-names"
                                aws_query_parameter_supplemental_01_value="All"
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "in AWS query for: 'SQS' 'queue-attributes' recursive command"
                                fnWriteLog ${LINENO} "using fixed supplemental parameters "
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "Querying AWS for the resources in: "aws_service" / "aws_command" / "aws_query_parameter" / "aws_service_key_list_line" / "aws_query_parameter_supplemental_01" / "aws_query_parameter_supplemental_01_value" "
                                fnWriteLog ${LINENO} "Querying AWS for the resources in: "$aws_service" / "$aws_command" / "$aws_query_parameter" / "$aws_service_key_list_line" / "$aws_query_parameter_supplemental_01" / "$aws_query_parameter_supplemental_01_value" " 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "testing for global region "
                                #
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "checking for global region " 
                                if [[ "$aws_region_fn_AWS_pull_snapshots" = 'global' ]] 
                                    then 
                                        fnWriteLog ${LINENO} ""
                                        fnWriteLog ${LINENO} "loading variable 'service_snapshot_build_01' via AWS CLI API "
                                        fnWriteLog ${LINENO} "region is global so us-east-1 AWS region parameter " 
                                        fnWriteLog ${LINENO} "CLI debug command: aws "$aws_service" "$aws_command" "$aws_query_parameter" "$aws_service_key_list_line" "$aws_query_parameter_supplemental_01" "$aws_query_parameter_supplemental_01_value" --profile "$cli_profile" --region us-east-1 " 
                                        fnWriteLog ${LINENO} ""   
                                        service_snapshot_build_01="$(aws "$aws_service" "$aws_command" "$aws_query_parameter" "$aws_service_key_list_line" "$aws_query_parameter_supplemental_01" "$aws_query_parameter_supplemental_01_value" --profile "$cli_profile" --region us-east-1 2>&1)" 
                                    else 
                                        fnWriteLog ${LINENO} ""
                                        fnWriteLog ${LINENO} "loading variable 'service_snapshot_build_01' via AWS CLI API "
                                        fnWriteLog ${LINENO} "region is not global so using AWS region parameter " 
                                        fnWriteLog ${LINENO} "CLI debug command: aws "$aws_service" "$aws_command" "$aws_query_parameter" "$aws_service_key_list_line" "$aws_query_parameter_supplemental_01" "$aws_query_parameter_supplemental_01_value" --profile "$cli_profile" --region "$aws_region_fn_AWS_pull_snapshots"  " 
                                        fnWriteLog ${LINENO} ""   
                                        service_snapshot_build_01="$(aws "$aws_service" "$aws_command" "$aws_query_parameter" "$aws_service_key_list_line" "$aws_query_parameter_supplemental_01" "$aws_query_parameter_supplemental_01_value" --profile "$cli_profile" --region "$aws_region_fn_AWS_pull_snapshots" 2>&1)" 
                                fi  # end test for global region 
                                #
                                #
                            else
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "in AWS query for: normal recursive command "
                                fnWriteLog ${LINENO} "using no supplemental parameters "
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "Querying AWS for the resources in: "aws_service" / "aws_command" / "aws_query_parameter" / "aws_service_key_list_line" " 
                                fnWriteLog ${LINENO} "Querying AWS for the resources in: "$aws_service" / "$aws_command" / "$aws_query_parameter" / "$aws_service_key_list_line" " 


                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "testing for global region "
                                #
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "checking for global region " 
                                if [[ "$aws_region_fn_AWS_pull_snapshots" = 'global' ]] 
                                    then 
                                        fnWriteLog ${LINENO} ""
                                        fnWriteLog ${LINENO} "region is global so us-east-1 AWS region parameter " 
                                        fnWriteLog ${LINENO} "CLI debug command: aws "$aws_service" "$aws_command" "$aws_query_parameter" "$aws_service_key_list_line" --profile "$cli_profile" --region us-east-1 " 
                                        fnWriteLog ${LINENO} ""   
                                        service_snapshot_build_01="$(aws "$aws_service" "$aws_command" "$aws_query_parameter" "$aws_service_key_list_line" --profile "$cli_profile" --region us-east-1  2>&1)" 
                                    else 
                                        fnWriteLog ${LINENO} ""
                                        fnWriteLog ${LINENO} "region is not global so using AWS region parameter " 
                                        fnWriteLog ${LINENO} "CLI debug command: aws "$aws_service" "$aws_command" "$aws_query_parameter" "$aws_service_key_list_line" --profile "$cli_profile" --region "$aws_region_fn_AWS_pull_snapshots" " 
                                        fnWriteLog ${LINENO} ""   
                                        service_snapshot_build_01="$(aws "$aws_service" "$aws_command" "$aws_query_parameter" "$aws_service_key_list_line" --profile "$cli_profile" --region "$aws_region_fn_AWS_pull_snapshots"  2>&1)" 
                                fi  # end test for global region 
                                #
                                #
                        fi  # end check for fixed supplemental parameters  
                        #
                        # check for errors from the AWS API  
                        if [ "$?" -ne 0 ]
                            then
                                # test for s3
                                if [[ "$aws_service" = "s3api" ]] ;
                                    then
                                        # check for "not found" error to handle s3 APIs that return an error instead of an empty set
                                        fnWriteLog ${LINENO} ""   
                                        fnWriteLog ${LINENO} "testing for '...not found' AWS error"    
                                        count_not_found_error=0
                                        count_not_found_error="$(echo "$service_snapshot_build_01" | egrep 'not exist|not found' | wc -l)"
                                        fnWriteLog ${LINENO} "value of variable 'count_not_found_error': "$count_not_found_error" "
                                        fnWriteLog ${LINENO} ""   
                                        if [[ "$count_not_found_error" > 0 ]] ;
                                            then 
                                                fnWriteLog ${LINENO} ""
                                                fnWriteLog ${LINENO} "increment the aws_service_key_list counter"
                                                counter_aws_service_key_list="$((counter_aws_service_key_list+1))" 
                                                fnWriteLog ${LINENO} "value of variable 'counter_aws_service_key_list': "$counter_aws_service_key_list" "
                                                fnWriteLog ${LINENO} "value of variable 'count_aws_service_key_list': "$count_aws_service_key_list" "
                                                fnWriteLog ${LINENO} ""
                                                continue
                                        fi  # end count not found error check 
                                fi # end check for s3 
                                #
                                # check for no endpoint error
                                count_error_aws_no_endpoint="$(echo "$service_snapshot" | grep -c 'Could not connect to the endpoint' )" 
                                if [[ "$count_error_aws_no_endpoint" -ne 0 ]] 
                                    then 
                                        # if no endpoint, then skip and continue 
                                        #
                                        fnWriteLog ${LINENO} ""
                                        fnWriteLog ${LINENO} "no endpoint found for this service so resetting the variable 'service_snapshot' " 
                                        fnWriteLog ${LINENO} "and skipping to the next via the 'continue' command "
                                        service_snapshot=""
                                        #
                                        continue 
                                        #
                                        #
                                    else 
                                        #
                                        # AWS Error while pulling the AWS Services
                                        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
                                        fnWriteLog ${LINENO} level_0 ""
                                        fnWriteLog ${LINENO} level_0 "AWS error message: "
                                        fnWriteLog ${LINENO} level_0 "$service_snapshot_build_01"
                                        fnWriteLog ${LINENO} level_0 ""
                                        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
                                        fnWriteLog ${LINENO} level_0 ""
                                        fnWriteLog ${LINENO} level_0 " AWS Error while pulling the AWS Services for: "
                                        fnWriteLog ${LINENO} level_0 "   "aws_service" / "aws_command" / "aws_query_parameter" / "aws_service_key_list_line" " 
                                        fnWriteLog ${LINENO} level_0 "   "$aws_service" / "$aws_command" / "$aws_query_parameter" / "$aws_service_key_list_line" " 
                                        fnWriteLog ${LINENO} level_0 ""
                                        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
                                        #
                                        # set the awserror line number
                                        error_line_aws="$((${LINENO}-44))"
                                        #
                                        # call the AWS error handler
                                        fnErrorAws
                                        #
                                fi  # end check for no endpoint error             
                                #
                        fi # end recursive AWS error
                        #
                        fnWriteLog ${LINENO} ""
                        #
                        # check for debug log 
                        if [[ "$logging" = 'z' ]] 
                            then 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                                fnWriteLog ${LINENO} "" 
                                fnWriteLog ${LINENO} ""               
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "value of variable 'service_snapshot_build_01': "
                                feed_write_log="$(echo "$service_snapshot_build_01" 2>&1)"
                                fnWriteLog ${LINENO} "$feed_write_log"
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} ""
                        #     
                        fi  # end check for debug log 
                        #                                         
                        #
                        # if empty result set, then continue to the next list value
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "testing for empty result set "
                        if [[ "$service_snapshot_build_01" = "" ]] ;
                            then 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "increment the service_key_list counter"
                                counter_aws_service_key_list="$((counter_aws_service_key_list+1))" 
                                fnWriteLog ${LINENO} "value of variable 'counter_aws_service_key_list': "$counter_aws_service_key_list" "
                                fnWriteLog ${LINENO} "value of variable 'count_aws_service_key_list': "$count_aws_service_key_list" "
                                fnWriteLog ${LINENO} ""
                                #
                                continue
                                #
                        fi  # end check for empty result set
                        #
                        fnWriteLog ${LINENO} ""
                        #
                        fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------------"
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "adding keys and values to the recursive command results set  "
                        fnWriteLog ${LINENO} ""
                        #
                        fnWriteLog ${LINENO} ""
                        #
                        # check for debug log 
                        if [[ "$logging" = 'z' ]] 
                            then 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                                fnWriteLog ${LINENO} "" 
                                fnWriteLog ${LINENO} ""               
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "value of variable 'service_snapshot_build_01':"
                                feed_write_log="$(echo "$service_snapshot_build_01")"
                                fnWriteLog ${LINENO} "$feed_write_log"
                        #     
                        fi  # end check for debug log 
                        #                                         
                        #
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "adding the aws_service_key and the aws_service_key_list_line: "$aws_service_key" "$aws_service_key_list_line" "
                        service_snapshot_build_02="$(echo "$service_snapshot_build_01" \
                        | jq --arg aws_service_key_jq "$aws_service_key" --arg aws_service_key_list_line_jq "$aws_service_key_list_line" ' {($aws_service_key_jq): $aws_service_key_list_line_jq} + .  ' )"
                        #
                        # check for command / pipeline error(s)
                        if [ "$?" -ne 0 ]
                            then
                                #
                                # set the command/pipeline error line number
                                error_line_pipeline="$((${LINENO}-7))"
                                #
                                #
                                fnWriteLog ${LINENO} level_0 ""
                                fnWriteLog ${LINENO} level_0 "value of variable 'service_snapshot_build_02':"
                                fnWriteLog ${LINENO} level_0 "$service_snapshot_build_02"
                                fnWriteLog ${LINENO} level_0 ""
                                #                                                                                                                                                                                                    
                                # call the command / pipeline error function
                                fnErrorPipeline
                                #
                        #
                        fi
                        #
                        fnWriteLog ${LINENO} ""
                        #
                        # check for debug log 
                        if [[ "$logging" = 'z' ]] 
                            then 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                                fnWriteLog ${LINENO} "" 
                                fnWriteLog ${LINENO} ""               
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "value of variable 'service_snapshot_build_02':"
                                feed_write_log="$(echo "$service_snapshot_build_02")"
                                fnWriteLog ${LINENO} "$feed_write_log"
                        #     
                        fi  # end check for debug log 
                        #                                         
                        #
                        #
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "in recursive command section "
                        fnWriteLog ${LINENO} "adding the JSON template keys and values: "$aws_account" "$aws_region_fn_AWS_pull_snapshots" "$aws_service" "$aws_service_snapshot_name_underscore" "
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "loading variable 'pattern_load_feed' with variable 'service_snapshot_build_02'   "
                        pattern_load_feed="$service_snapshot_build_02"
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "calling function 'fnPatternLoad'   "
                        #
                        fnPatternLoad
                        #
                        # the built-up AWS service is put into the following structure as an array at the position of the '.'  
                        # service_snapshot_build_03="$(echo "$service_snapshot_build_02" \
                        # | jq -s --arg aws_account_jq "$aws_account" --arg aws_region_fn_AWS_pull_snapshots_jq "$aws_region_fn_AWS_pull_snapshots" --arg aws_service_jq "$aws_service" --arg aws_service_snapshot_name_underscore_jq "$aws_service_snapshot_name_underscore" '{ account: $aws_account_jq, regions: [ { regionName: $aws_region_fn_AWS_pull_snapshots_jq, regionServices: [ { serviceType: $aws_service_jq, service: [ { ($aws_service_snapshot_name_underscore_jq): . } ] } ] } ] }' 2>&1)"
                        #
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "loading variable 'service_snapshot_build_03' with function return variable 'pattern_load_value'   "
                        service_snapshot_build_03="$pattern_load_value"
                        fnWriteLog ${LINENO} ""
                        #
                        fnWriteLog ${LINENO} ""
                        #
                        # check for debug log 
                        if [[ "$logging" = 'z' ]] 
                            then 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                                fnWriteLog ${LINENO} "" 
                                fnWriteLog ${LINENO} ""               
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "value of variable 'service_snapshot_build_03':"
                                feed_write_log="$(echo "$service_snapshot_build_03")"
                                fnWriteLog ${LINENO} "$feed_write_log"
                        #     
                        fi  # end check for debug log 
                        #
                        # 
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "Writing the recursive service snapshot to the build JSON file: "$this_utility_acronym"-write-file-services-recursive-load.json to enable merge "
                        fnWriteLog ${LINENO} "using variables: "$aws_account" "$aws_region_fn_AWS_pull_snapshots" "$aws_service" "$aws_service_key" "$aws_service_key_line" "
                        feed_write_log="$(echo "$service_snapshot_build_03">"$this_path_temp"/"$this_utility_acronym"-write-file-services-recursive-load.json 2>&1)"
                        #
                        # check for command / pipeline error(s)
                        if [ "$?" -ne 0 ]
                            then
                                #
                                # set the command/pipeline error line number
                                error_line_pipeline="$((${LINENO}-7))"
                                #
                                #
                                fnWriteLog ${LINENO} level_0 ""
                                fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                                fnWriteLog ${LINENO} level_0 "$feed_write_log"
                                fnWriteLog ${LINENO} level_0 ""
                                #
                                fnWriteLog ${LINENO} level_0 ""
                                fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"-write-file-services-recursive-load.json:"
                                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-services-recursive-load.json)"
                                fnWriteLog ${LINENO} level_0 "$feed_write_log"
                                fnWriteLog ${LINENO} level_0 ""
                                #                                                                                                                                                                                                    
                                # call the command / pipeline error function
                                fnErrorPipeline
                                #
                        #
                        fi
                        #
                        fnWriteLog ${LINENO} "$feed_write_log"
                        fnWriteLog ${LINENO} ""
                        #
                        fnWriteLog ${LINENO} ""
                        #
                        # check for debug log 
                        if [[ "$logging" = 'z' ]] 
                            then 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                                fnWriteLog ${LINENO} "" 
                                fnWriteLog ${LINENO} ""               
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "contents of file "$this_utility_acronym"-write-file-services-recursive-load.json:"
                                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-services-recursive-load.json)"
                                fnWriteLog ${LINENO} "$feed_write_log"
                                fnWriteLog ${LINENO} ""
                        #     
                        fi  # end check for debug log 
                        #
                        #                                                                                                                                                                                                                            
                        #
                        fnWriteLog ${LINENO} "loading variable 'service_snapshot' with contents of file "$this_utility_acronym"-write-file-services-recursive-load.json "
                        service_snapshot="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-services-recursive-load.json)"
                        #
                        # check for command / pipeline error(s)
                        if [ "$?" -ne 0 ]
                            then
                                #
                                # set the command/pipeline error line number
                                error_line_pipeline="$((${LINENO}-7))"
                                #
                                #
                                fnWriteLog ${LINENO} level_0 ""
                                fnWriteLog ${LINENO} level_0 "value of variable 'service_snapshot':"
                                fnWriteLog ${LINENO} level_0 "$service_snapshot"
                                fnWriteLog ${LINENO} level_0 ""
                                #
                                fnWriteLog ${LINENO} level_0 ""
                                fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"-write-file-services-recursive-load.json:"
                                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-services-recursive-load.json)"
                                fnWriteLog ${LINENO} level_0 "$feed_write_log"
                                fnWriteLog ${LINENO} level_0 ""
                                #                                                                                                                                                                                                    
                                # call the command / pipeline error function
                                fnErrorPipeline
                                #
                        #
                        fi
                        #
                        fnWriteLog ${LINENO} "$feed_write_log"
                        #
                        fnWriteLog ${LINENO} ""
                        #
                        # check for debug log 
                        if [[ "$logging" = 'z' ]] 
                            then 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                                fnWriteLog ${LINENO} "" 
                                fnWriteLog ${LINENO} ""               
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "value of variable 'service_snapshot': "
                                feed_write_log="$(echo "$service_snapshot" 2>&1)"
                                fnWriteLog ${LINENO} "$feed_write_log"
                        #     
                        fi  # end check for debug log 
                        #
                        #
                        # check for debug log 
                        if [[ "$logging" = 'z' ]] 
                            then 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                                fnWriteLog ${LINENO} "" 
                                fnWriteLog ${LINENO} ""               
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "value of variable 'service_snapshot' piped through 'jq .': "
                                feed_write_log="$(echo "$service_snapshot" | jq . 2>&1)"
                                # check for jq error
                                if [ "$?" -ne 0 ]
                                    then
                                        # jq error 
                                        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
                                        fnWriteLog ${LINENO} level_0 ""
                                        fnWriteLog ${LINENO} level_0 "jq error message: "
                                        fnWriteLog ${LINENO} level_0 "$feed_write_log"
                                        fnWriteLog ${LINENO} level_0 ""
                                        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
                                        #
                                        # set the jqerror line number
                                        error_line_jq="$((${LINENO}-13))"
                                        #
                                        # call the jq error handler
                                        fnErrorJq
                                        #
                                fi # end jq error
                                #
                                fnWriteLog ${LINENO} "$feed_write_log"
                                fnWriteLog ${LINENO} ""
                        #     
                        fi  # end check for debug log 
                        #                       
                        fnWriteLog ${LINENO} "---------------------------------------"
                        #         
                        # if the first time through, then add the services name and the empty services array
                        if [[ "$counter_aws_service_key_list" -eq 0 ]] ;
                            then 
                            #
                            # get the recursive service key name 
                            fnWriteLog ${LINENO} ""
                            fnWriteLog ${LINENO} "pulling the service key from the variable 'service_snapshot' "
                            service_snapshot_recursive_service_key="$(echo "$service_snapshot_build_01" | jq 'keys' | tr -d '[]", ' | grep -v -e '^$' | grep -v "$aws_service_key" 2>&1)"
                            fnWriteLog ${LINENO} ""
                            fnWriteLog ${LINENO} "value of variable 'service_snapshot_recursive_service_key': "$service_snapshot_recursive_service_key" "
                            fnWriteLog ${LINENO} ""
                            #
                            # swap the variables
                            snapshot_source_recursive_command_02="$snapshot_source_recursive_command"
                            #   
                            fnWriteLog ${LINENO} ""
                            fnWriteLog ${LINENO} "calling the write file initialize function: 'fnInitializeWriteFileBuild' "
                            fnInitializeWriteFileBuild
                            #
                            fnWriteLog ${LINENO} ""
                            fnWriteLog ${LINENO} "initializing the variable 'snapshot_source_recursive_command' with the contents of the file "$this_utility_acronym"-write-file-build.json "
                            snapshot_source_recursive_command="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-build.json)"
                            #
                            # check for command / pipeline error(s)
                            if [ "$?" -ne 0 ]
                                then
                                    #
                                    # set the command/pipeline error line number
                                    error_line_pipeline="$((${LINENO}-7))"
                                    #
                                    #
                                    fnWriteLog ${LINENO} level_0 ""
                                    fnWriteLog ${LINENO} level_0 "value of variable 'snapshot_source_recursive_command':"
                                    fnWriteLog ${LINENO} level_0 "$snapshot_source_recursive_command"
                                    fnWriteLog ${LINENO} level_0 ""
                                    #
                                    fnWriteLog ${LINENO} level_0 ""
                                    fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"-write-file-build.json:"
                                    feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-build.json)"
                                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                                    fnWriteLog ${LINENO} level_0 ""
                                    #                                                                                                                                                                                                    
                                    # call the command / pipeline error function
                                    fnErrorPipeline
                                    #
                            #
                            fi
                            #
                            fnWriteLog ${LINENO} "$feed_write_log"
                            #
                            #
                            fnWriteLog ${LINENO} ""
                            fnWriteLog ${LINENO} "value of variable 'snapshot_source_recursive_command': "
                            feed_write_log="$(echo "$snapshot_source_recursive_command" 2>&1)"
                            fnWriteLog ${LINENO} "$feed_write_log"
                            fnWriteLog ${LINENO} ""
                            #  
                            fnWriteLog ${LINENO} ""
                            #
                        fi # end first time through 
                        #
                        #
                        # normally disabled for speed
                        fnWriteLog ${LINENO} ""
                        #
                        # check for debug log 
                        if [[ "$logging" = 'z' ]] 
                            then 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                                fnWriteLog ${LINENO} "" 
                                fnWriteLog ${LINENO} ""               
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "value of variable: "snapshot_source_recursive_command":"  
                                feed_write_log="$(echo "$snapshot_source_recursive_command" 2>&1)"
                                fnWriteLog ${LINENO} "$feed_write_log"                    
                        #     
                        fi  # end check for debug log 
                        #                       
                        #
                        #
                        # write the recursive command file
                        fnWriteLog ${LINENO} "" 
                        fnWriteLog ${LINENO} "calling the recursive command file write function" 
                        #
                        fnWriteCommandFileRecursive
                        #
                        #  
                        fnWriteLog ${LINENO} ""
                        # normally disabled for speed
                        fnWriteLog ${LINENO} ""
                        #
                        # check for debug log 
                        if [[ "$logging" = 'z' ]] 
                            then 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                                fnWriteLog ${LINENO} "" 
                                fnWriteLog ${LINENO} ""               
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "value of variable: 'snapshot_target_recursive_command':"
                                feed_write_log="$(echo "$snapshot_target_recursive_command" 2>&1)"
                                fnWriteLog ${LINENO} "$feed_write_log"
                                fnWriteLog ${LINENO} ""
                        #     
                        fi  # end check for debug log 
                        #                       
                        #
                        #  
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "loading variable: "snapshot_source_recursive_command" from variable "snapshot_target_recursive_command" "
                        snapshot_source_recursive_command="$(echo "$snapshot_target_recursive_command" 2>&1)"
                        #
                        # check for command / pipeline error(s)
                        if [ "$?" -ne 0 ]
                            then
                                #
                                # set the command/pipeline error line number
                                error_line_pipeline="$((${LINENO}-7))"
                                #
                                #
                                fnWriteLog ${LINENO} level_0 ""
                                fnWriteLog ${LINENO} level_0 "value of variable 'snapshot_source_recursive_command':"
                                fnWriteLog ${LINENO} level_0 "$snapshot_source_recursive_command"
                                fnWriteLog ${LINENO} level_0 ""
                                #                                                                                                                                            
                                # call the command / pipeline error function
                                fnErrorPipeline
                                #
                        #
                        fi
                        #
                        fnWriteLog ${LINENO} ""
                        #
                        #  
                        fnWriteLog ${LINENO} ""
                        # normally disabled for speed
                        fnWriteLog ${LINENO} ""
                        #
                        # check for debug log 
                        if [[ "$logging" = 'z' ]] 
                            then 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                                fnWriteLog ${LINENO} "" 
                                fnWriteLog ${LINENO} ""               
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "value of variable: "snapshot_source_recursive_command":"  
                                feed_write_log="$(echo "$snapshot_source_recursive_command" 2>&1)"
                                fnWriteLog ${LINENO} "$feed_write_log"
                        #     
                        fi  # end check for debug log 
                        #                       
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} ""
                        #
                        #
                        fnWriteLog ${LINENO} "add the snapshot service and name to the snapshot names file "   
                        feed_write_log="$(echo ""$aws_service_snapshot_name"---"$aws_service_key_list_line"" >> "$write_file_service_names"  2>&1)"
                        fnWriteLog ${LINENO} "$feed_write_log"
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} ""
                        #
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "contents of file: '$write_file_service_names':"
                        feed_write_log="$(cat "$write_file_service_names" 2>&1)"
                        #
                        # check for command / pipeline error(s)
                        if [ "$?" -ne 0 ]
                            then
                                #
                                # set the command/pipeline error line number
                                error_line_pipeline="$((${LINENO}-7))"
                                #
                                #
                                fnWriteLog ${LINENO} level_0 ""
                                fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                                fnWriteLog ${LINENO} level_0 "$feed_write_log"
                                fnWriteLog ${LINENO} level_0 ""
                                #
                                fnWriteLog ${LINENO} level_0 ""
                                fnWriteLog ${LINENO} level_0 "contents of file "$write_file_service_names":"
                                feed_write_log="$(cat "$write_file_service_names")"
                                fnWriteLog ${LINENO} level_0 "$feed_write_log"
                                fnWriteLog ${LINENO} level_0 ""
                                #                                                                                                                                                                            
                                # call the command / pipeline error function
                                fnErrorPipeline
                                #
                        #
                        fi
                        #
                        fnWriteLog ${LINENO} "$feed_write_log"
                        fnWriteLog ${LINENO} ""
                        #
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "increment the service_key_list counter"
                        counter_aws_service_key_list="$((counter_aws_service_key_list+1))" 
                        fnWriteLog ${LINENO} "value of variable 'counter_aws_service_key_list': "$counter_aws_service_key_list" "
                        fnWriteLog ${LINENO} "value of variable 'count_aws_service_key_list': "$count_aws_service_key_list" "
                        fnWriteLog ${LINENO} ""
                        #
                        #
                        # check for overrun; exit if recursive snapshot loop is not stopping properly
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "checking for overrun of the recursive-command snapshot counter: 'counter_aws_service_key_list'"
                        if [[ "$counter_aws_service_key_list" -gt "$count_aws_service_key_list" ]] 
                            then
                                #
                                # set the command/pipeline error line number
                                error_line_pipeline="$((${LINENO}-5))"
                                #
                                fnWriteLog ${LINENO} level_0 ""
                                fnWriteLog ${LINENO} level_0 "service key list counter overrun error "
                                #
                                fnWriteLog ${LINENO} level_0 ""
                                fnWriteLog ${LINENO} level_0 "value of variable 'counter_aws_service_key_list':"
                                fnWriteLog ${LINENO} level_0 "$counter_aws_service_key_list"
                                fnWriteLog ${LINENO} level_0 ""
                                #
                                fnWriteLog ${LINENO} level_0 ""
                                fnWriteLog ${LINENO} level_0 "value of variable 'count_aws_service_key_list':"
                                fnWriteLog ${LINENO} level_0 "$count_aws_service_key_list"
                                fnWriteLog ${LINENO} level_0 ""
                                #
                                # call the command / pipeline error function
                                fnErrorPipeline
                                #
                        #
                        fi  # end check for aws_service_key_list loop overrun 
                        #
                        #
                        # increment the snapshot counter
                        fnCounterIncrementSnapshots
                        #
                        #
                        # write out the temp log and empty the log variable
                        fnWriteLogTempFile
                        #
                        #
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "----------------------- loop tail: read variable 'aws_service_key_list' -----------------------  "
                        fnWriteLog ${LINENO} ""
                        #
                done< <(echo "$aws_service_key_list")
                #
                #
                # write the recursive command variable to the snapshot file
                # display the header    
                fnHeader
                # display the task progress bar
                fnProgressBarTaskDisplay "$counter_aws_region_list" "$count_aws_region_list"
                # display the sub-task progress bar
                fnProgressBarTaskSubDisplay "$counter_aws_service_key_list" "$count_aws_service_key_list"
                #
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "This sub-task takes a while. Please wait..."
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "Creating a snapshot for: "$aws_service" "$aws_snapshot_name" "$aws_service_key_list_line"  " 
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "Writing the data file. Please wait..."
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "writing the final state of the snapshot variable 'snapshot_target_recursive_command' to the snapshot file: "
                feed_write_log="$(echo "$write_file_full_path" 2>&1 )"
                fnWriteLog ${LINENO} "$feed_write_log"
                fnWriteLog ${LINENO} "" 
                #
                # write the recursive command file
                fnWriteLog ${LINENO} "" 
                fnWriteLog ${LINENO} "calling the recursive command file write function" 
                #
                fnWriteCommandFileRecursive
                #
                #
                fnWriteLog ${LINENO} "" 
                fnWriteLog ${LINENO} "writing the variable 'snapshot_target_recursive_command' to the output file 'write_file_full_path' " 
                feed_write_log="$(echo "$snapshot_target_recursive_command" > "$write_file_full_path"  2>&1 )"
                #
                # check for command / pipeline error(s)
                if [ "$?" -ne 0 ]
                    then
                        #
                        # set the command/pipeline error line number
                        error_line_pipeline="$((${LINENO}-7))"
                        #
                        #
                        fnWriteLog ${LINENO} level_0 ""
                        fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                        fnWriteLog ${LINENO} level_0 "$feed_write_log"
                        fnWriteLog ${LINENO} level_0 ""
                        #                                                                                                                                                                            
                        # call the command / pipeline error function
                        fnErrorPipeline
                        #
                #
                fi
                #
                fnWriteLog ${LINENO} "$feed_write_log"
                fnWriteLog ${LINENO} ""
                #
                fnWriteLog ${LINENO} ""
                #
                # check for debug log 
                if [[ "$logging" = 'z' ]] 
                    then 
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "--------------------------------------------------------------"
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "--------------------------------------------------------------"
                        fnWriteLog ${LINENO} "" 
                        fnWriteLog ${LINENO} ""                             
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "contents of file: 'write_file_full_path':"
                        feed_write_log="$(echo "$write_file_full_path" 2>&1 )"
                        fnWriteLog ${LINENO} "$feed_write_log"
                        fnWriteLog ${LINENO} ""           
                        feed_write_log="$(cat "$write_file_full_path" 2>&1)"
                        #
                        # check for command / pipeline error(s)
                        if [ "$?" -ne 0 ]
                            then
                                #
                                # set the command/pipeline error line number
                                error_line_pipeline="$((${LINENO}-7))"
                                #
                                #
                                fnWriteLog ${LINENO} level_0 ""
                                fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                                fnWriteLog ${LINENO} level_0 "$feed_write_log"
                                fnWriteLog ${LINENO} level_0 ""
                                #
                                fnWriteLog ${LINENO} level_0 ""
                                fnWriteLog ${LINENO} level_0 "contents of file "$write_file_full_path":"
                                feed_write_log="$(cat "$write_file_full_path")"
                                fnWriteLog ${LINENO} level_0 "$feed_write_log"
                                fnWriteLog ${LINENO} level_0 ""
                                #                                                                                                                                                                                                    
                                # call the command / pipeline error function
                                fnErrorPipeline
                                #
                        #
                        fi
                        #
                        fnWriteLog ${LINENO} "$feed_write_log"
                        fnWriteLog ${LINENO} ""
                #     
                fi  # end check for debug log 
                #                       
                #
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "----------------------- done with section: read variable 'aws_service_key_list' -----------------------  "
                fnWriteLog ${LINENO} ""
                #
                #
            #
            else
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "--------------------------------- begin section: non-recursive command --------------------------------  "
                fnWriteLog ${LINENO} ""
                # if non-recursive command 
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "in non-recursive command"
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "value of variable 'aws_command': "$aws_command" "
                fnWriteLog ${LINENO} ""
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "This task takes a while. Please wait..."
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0""
                fnWriteLog ${LINENO} level_0 "Pulling the AWS Services from AWS for region: "$aws_region_fn_AWS_pull_snapshots"..."
                fnWriteLog ${LINENO} level_0"" 
                fnWriteLog ${LINENO} level_0""                
                fnWriteLog ${LINENO} level_0 "Creating a snapshot for: "$aws_service" "$aws_snapshot_name" " 
                fnWriteLog ${LINENO} ""    
                fnWriteLog ${LINENO} "using command: aws "$aws_service" "$aws_command" --profile "$cli_profile" --region "$aws_region_list_line" "   
                #
                write_file_raw="aws-""$aws_account"-"$aws_region_fn_AWS_pull_snapshots"-snapshot-"$date_file"-"$aws_service"-"$aws_snapshot_name".json
                fnWriteLog ${LINENO} "value of variable 'write_file_raw': "$write_file_raw" "
                write_file_clean="$(echo "$write_file_raw" | tr "/%\\<>:" "_" )"
                fnWriteLog ${LINENO} "value of variable 'write_file_clean': "$write_file_clean" "
                write_file="$(echo "$write_file_clean")"
                write_file_full_path="$write_path_snapshots"/"$write_file"
                fnWriteLog ${LINENO} "value of variable 'write_file': "$write_file" "
                fnWriteLog ${LINENO} "value of variable 'write_file_full_path': "$write_file_full_path" "
                fnWriteLog ${LINENO} ""
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "Creating file: "$write_file""
                #
                ##########################################################################
                #
                #
                # initialze the target region / service write file    
                #
                fnWriteLog ${LINENO} ""  
                #
                fnInitializeWriteFileBuild
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} ""    
                fnWriteLog ${LINENO} "loading the variable 'snapshot_source_recursive_command':"
                snapshot_source_recursive_command="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-build.json  2>&1)"
                #
                # check for command / pipeline error(s)
                if [ "$?" -ne 0 ]
                    then
                        #
                        # set the command/pipeline error line number
                        error_line_pipeline="$((${LINENO}-7))"
                        #
                        #
                        fnWriteLog ${LINENO} level_0 ""
                        fnWriteLog ${LINENO} level_0 "value of variable 'snapshot_source_recursive_command':"
                        fnWriteLog ${LINENO} level_0 "$snapshot_source_recursive_command"
                        fnWriteLog ${LINENO} level_0 ""
                        #
                        fnWriteLog ${LINENO} level_0 ""
                        fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"-write-file-build.json:"
                        feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-build.json)"
                        fnWriteLog ${LINENO} level_0 "$feed_write_log"
                        fnWriteLog ${LINENO} level_0 ""
                        #                                                                                                                                                                                                                            
                        # call the command / pipeline error function
                        fnErrorPipeline
                        #
                        #
                fi
                #
                fnWriteLog ${LINENO} ""    
                #
                ##########################################################################
                #
                #
                # query AWS for the service   
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "Querying AWS for the resources in: "$aws_service" "$aws_command" "$aws_region_fn_AWS_pull_snapshots" " 
                fnWriteLog ${LINENO} "non-recursive command - loading the variable 'service_snapshot' "
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "checking for global region " 
                if [[ "$aws_region_fn_AWS_pull_snapshots" = 'global' ]] 
                    then 
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "region is global so us-east-1 AWS region parameter " 
                        fnWriteLog ${LINENO} "command: aws "$aws_service" "$aws_command" --profile "$cli_profile"  "    
                        service_snapshot="$(aws "$aws_service" "$aws_command" --profile "$cli_profile" --region us-east-1 2>&1)"    
                    else 
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "region is not global so using AWS region parameter " 
                        fnWriteLog ${LINENO} "command: aws "$aws_service" "$aws_command" --profile "$cli_profile" --region "$aws_region_fn_AWS_pull_snapshots" "    
                        service_snapshot="$(aws "$aws_service" "$aws_command" --profile "$cli_profile" --region "$aws_region_fn_AWS_pull_snapshots" 2>&1)"    
                fi  # end test for global region 
                #
                # check for errors from the AWS API  
                if [ "$?" -ne 0 ]
                    then
                        # check for no endpoint error
                        count_error_aws_no_endpoint="$(echo "$service_snapshot" | grep -c 'Could not connect to the endpoint' )" 
                        if [[ "$count_error_aws_no_endpoint" -ne 0 ]] 
                            then 
                                # if no endpoint, then skip and continue 
                                #
                                fnWriteLog ${LINENO} ""
                                fnWriteLog ${LINENO} "no endpoint found for this service so resetting the variable 'service_snapshot' " 
                                fnWriteLog ${LINENO} "and 'service_snapshot_recursive' and skipping to the next via the 'continue' command "
                                service_snapshot=""
                                service_snapshot_recursive=""
                                #
                                continue 
                                #
                                #
                            else 
                                # AWS Error while pulling the AWS Services
                                fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
                                fnWriteLog ${LINENO} level_0 ""
                                fnWriteLog ${LINENO} level_0 "AWS error message: "
                                fnWriteLog ${LINENO} level_0 "$service_snapshot"
                                fnWriteLog ${LINENO} level_0 ""
                                fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
                                fnWriteLog ${LINENO} level_0 ""
                                fnWriteLog ${LINENO} level_0 " AWS Error while pulling the AWS Services for "$aws_service" "$aws_snapshot_name" "
                                fnWriteLog ${LINENO} level_0 ""
                                fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
                                #
                                # set the awserror line number
                                error_line_aws="$((${LINENO}-35))"
                                #
                                # call the AWS error handler
                                fnErrorAws
                                #
                        fi  # end check for no endpoint error             
                        #
                fi # end check for non-recursive AWS error
                #
                fnWriteLog ${LINENO} ""
                #
                # check for debug log 
                if [[ "$logging" = 'z' ]] 
                    then 
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "--------------------------------------------------------------"
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "--------------------------------------------------------------"
                        fnWriteLog ${LINENO} "" 
                        fnWriteLog ${LINENO} ""                             
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "--------------------------------------------------------------------------------------------------"
                        fnWriteLog ${LINENO} "value of variable 'service_snapshot':"
                        fnWriteLog ${LINENO} "$service_snapshot"
                        fnWriteLog ${LINENO} "--------------------------------------------------------------------------------------------------"
                        fnWriteLog ${LINENO} ""
                #     
                fi  # end check for debug log 
                #                       
                #
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "value of variable 'aws_account':"
                fnWriteLog ${LINENO} "$aws_account"
                fnWriteLog ${LINENO} ""
                #
                # 
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "in non-recursive section "     
                fnWriteLog ${LINENO} "loading JSON pattern with service snapshot "
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "loading variable 'pattern_load_feed' with variable 'service_snapshot_build_02'   "
                pattern_load_feed="$service_snapshot"
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "calling function 'fnPatternLoad'   "
                #
                fnPatternLoad
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "loading variable 'service_snapshot_build_03' with function return variable 'pattern_load_value'   "
                service_snapshot_build_03="$pattern_load_value"
                fnWriteLog ${LINENO} ""
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "Writing the service snapshot to the build JSON file: "$this_utility_acronym"-write-file-services-load.json to enable merge "
                feed_write_log="$(echo "$pattern_load_value">"$this_path_temp"/"$this_utility_acronym"-write-file-services-load.json 2>&1)"
                #
                # check for command / pipeline error(s)
                if [ "$?" -ne 0 ]
                    then
                        #
                        # set the command/pipeline error line number
                        error_line_pipeline="$((${LINENO}-7))"
                        #
                        #
                        fnWriteLog ${LINENO} level_0 ""
                        fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                        fnWriteLog ${LINENO} level_0 "$feed_write_log"
                        fnWriteLog ${LINENO} level_0 ""
                        #
                        fnWriteLog ${LINENO} level_0 ""
                        fnWriteLog ${LINENO} level_0 "contents of file "$this_path_temp"/"$this_utility_acronym"-write-file-services-load.json:"
                        feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-services-load.json)"
                        fnWriteLog ${LINENO} level_0 "$feed_write_log"
                        fnWriteLog ${LINENO} level_0 ""
                        #                                                                                                                                                                                                    
                        # call the command / pipeline error function
                        fnErrorPipeline
                        #
                #
                fi
                #
                fnWriteLog ${LINENO} "$feed_write_log"
                fnWriteLog ${LINENO} ""
                #
                # feed_write_log="$(echo "$service_snapshot" | jq -s --arg aws_account_jq "$aws_account" --arg aws_region_fn_AWS_pull_snapshots_jq "$aws_region_fn_AWS_pull_snapshots" --arg aws_service_jq "$aws_service" '{ account: $aws_account_jq, regions: [ { regionName: $aws_region_fn_AWS_pull_snapshots_jq, regionServices: [ { serviceType: $aws_service_jq, service: . } ] } ] }' > "$this_path_temp"/"$this_utility_acronym"-write-file-services-load.json 2>&1)"
                #
                fnWriteLog ${LINENO} ""
                #
                # check for debug log 
                if [[ "$logging" = 'z' ]] 
                    then 
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "--------------------------------------------------------------"
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "--------------------------------------------------------------"
                        fnWriteLog ${LINENO} "" 
                        fnWriteLog ${LINENO} ""                             
                        fnWriteLog ${LINENO} ""                
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "contents of file "$this_utility_acronym"-write-file-services-load.json:"
                        feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-services-load.json)"
                        fnWriteLog ${LINENO} "$feed_write_log"
                        fnWriteLog ${LINENO} ""
                #     
                fi  # end check for debug log 
                #                       
                #                                                                                                                                                                                                                            
                # write the non-recursive command file
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "Writing the non-recursive command JSON snapshot file for: "$aws_service" "$aws_command" to file: "
                #
                # call the array merge function  
                # parameters are: source target 
                # output file name of the function is: "$this_utility_acronym"-merge-services-file-build-temp.json
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "calling function: 'fnMergeArraysServicesJsonFile' with parameters: "$this_utility_acronym"-write-file-services-load.json "$this_utility_acronym"-write-file-build.json "               
                #
                fnMergeArraysServicesJsonFile "$this_path_temp"/"$this_utility_acronym"-write-file-services-load.json "$this_path_temp"/"$this_utility_acronym"-write-file-build.json
                #
                #    
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "Copying contents of file: "$this_utility_acronym"-merge-services-file-build-temp.json to file: "$write_file_full_path"  "
                fnWriteLog ${LINENO} ""  
                cp -f "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build-temp.json "$write_file_full_path"
                fnWriteLog ${LINENO} ""  
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} ""
                #
                # check for debug log 
                if [[ "$logging" = 'z' ]] 
                    then 
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "--------------------------------------------------------------"
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
                        fnWriteLog ${LINENO} ""
                        fnWriteLog ${LINENO} "--------------------------------------------------------------"
                        fnWriteLog ${LINENO} "" 
                        fnWriteLog ${LINENO} ""                             
                        fnWriteLog ${LINENO} ""                
                        fnWriteLog ${LINENO} "Contents of file: "$write_file_full_path" "
                        fnWriteLog ${LINENO} ""  
                        feed_write_log="$(cat "$write_file_full_path"  2>&1)"
                        #  check for command / pipeline error(s)
                        if [ "$?" -ne 0 ]
                            then
                                #
                                # set the command/pipeline error line number
                                error_line_pipeline="$((${LINENO}-7))"
                                #
                                #
                                fnWriteLog ${LINENO} level_0 ""
                                fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                                fnWriteLog ${LINENO} level_0 "$feed_write_log"
                                fnWriteLog ${LINENO} level_0 ""
                                #
                                fnWriteLog ${LINENO} level_0 ""
                                fnWriteLog ${LINENO} level_0 "contents of file "$write_file_full_path":"
                                feed_write_log="$(cat "$write_file_full_path")"
                                fnWriteLog ${LINENO} level_0 "$feed_write_log"
                                fnWriteLog ${LINENO} level_0 ""
                                #                                         
                                # call the command / pipeline error function
                                fnErrorPipeline
                                #
                                #
                        fi  # end pipeline error check 
                #
                fnWriteLog ${LINENO} "$feed_write_log"
                #     
                fi  # end check for debug log 
                #                       
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} ""
                #
                #
            #
            # end non-recursive command 
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "---------------------------------- end section: non-recursive command ---------------------------------  "
            fnWriteLog ${LINENO} ""
        #
        #            
        fi # end test for recursive command 
        #
        fnWriteLog ${LINENO} ""
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                fnWriteLog ${LINENO} "" 
                fnWriteLog ${LINENO} ""                             
                fnWriteLog ${LINENO} ""                
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "value of variable 'service_snapshot':"
                feed_write_log="$(echo "$service_snapshot" 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                fnWriteLog ${LINENO} ""
        #     
        fi  # end check for debug log 
        #                       
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} ""
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "--------------------------------------------------------------"
                fnWriteLog ${LINENO} "" 
                fnWriteLog ${LINENO} ""                             
                fnWriteLog ${LINENO} ""                
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "contents of file: '$write_file_full_path':"
                feed_write_log="$(cat "$write_file_full_path" 2>&1)"
                # check for command / pipeline error(s)
                if [ "$?" -ne 0 ]
                    then
                        #
                        # set the command/pipeline error line number
                        error_line_pipeline="$((${LINENO}-7))"
                        #
                        #
                        fnWriteLog ${LINENO} level_0 ""
                        fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                        fnWriteLog ${LINENO} level_0 "$feed_write_log"
                        fnWriteLog ${LINENO} level_0 ""
                        #
                        fnWriteLog ${LINENO} level_0 ""
                        fnWriteLog ${LINENO} level_0 "contents of file "$write_file_full_path":"
                        feed_write_log="$(cat "$write_file_full_path")"
                        fnWriteLog ${LINENO} level_0 "$feed_write_log"
                        fnWriteLog ${LINENO} level_0 ""
                        #    
                        # call the command / pipeline error function
                        fnErrorPipeline
                        #
                #
                fi
                #
                fnWriteLog ${LINENO} "$feed_write_log"
                fnWriteLog ${LINENO} ""
                #
        #     
        fi  # end check for debug log 
        #                       
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'flag_recursive_command':"
        feed_write_log="$(echo "$flag_recursive_command" 2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""
        #
        # checking for non-recursive run
        if [[ "$flag_recursive_command" == "n" ]] ;
            then
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "store the results for use by recursive commands':"
                service_snapshot_recursive="$(echo "$service_snapshot" 2>&1)"
                fnWriteLog ${LINENO} ""
                #
                fnWriteLog ${LINENO} "add the snapshot service and name to the snapshot names file "   
                feed_write_log="$(echo "$aws_service_snapshot_name" >> "$write_file_service_names"  2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} ""
                #
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "contents of file: '$write_file_service_names':"
                feed_write_log="$(cat "$write_file_service_names" 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                fnWriteLog ${LINENO} ""
                #
        fi
        #
        # enable for debug
        # fnWriteLog ${LINENO} ""
        # fnWriteLog ${LINENO} "value of variable 'service_snapshot_recursive':"
        # feed_write_log="$(echo "$service_snapshot_recursive" 2>&1)"
        # fnWriteLog ${LINENO} "$feed_write_log"
        # fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'counter_driver_services':"
        feed_write_log="$(echo "$counter_driver_services" 2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "increment the write counter: 'counter_driver_services'"
        counter_driver_services="$((counter_driver_services+1))"
        fnWriteLog ${LINENO} "post-increment value of variable 'counter_driver_services': "$counter_driver_services" "
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'count_driver_services':"
        feed_write_log="$(echo "$count_driver_services" 2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""
        #
        #
        # check for overrun; exit if loop is not stopping properly
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "checking for overrun of the write counter: 'counter_driver_services'"
        if [[ "$counter_driver_services" -gt "$count_driver_services" ]]  
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-5))"
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "service counter overrun error "
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "value of variable 'counter_driver_services':"
                fnWriteLog ${LINENO} level_0 "$counter_driver_services"
                fnWriteLog ${LINENO} level_0 ""
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "value of variable 'count_driver_services':"
                fnWriteLog ${LINENO} level_0 "$count_driver_services"
                fnWriteLog ${LINENO} level_0 ""
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi  # end check for services_driver_list loop overrun 
        #
        #
        # increment the snapshot counter
        fnCounterIncrementSnapshots
        #
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "----------------------- loop tail: read sps-aws-services-snapshot-driver-stripped.txt -----------------------  "
        fnWriteLog ${LINENO} ""
        #
        # write out the temp log and empty the log variable
        fnWriteLogTempFile
        #
    #
    done< <(echo "$services_driver_list")
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} " in section: end pull the snapshots"
    fnWriteLog ${LINENO} "------------------------------------------------"  
    fnWriteLog ${LINENO} "value of variable 'aws_account':"
    fnWriteLog ${LINENO} "$aws_account"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'aws_service':"
    fnWriteLog ${LINENO} "$aws_service"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'aws_service_snapshot_name_underscore':"
    fnWriteLog ${LINENO} "$aws_service_snapshot_name_underscore"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "------------------------------------------------"  
    fnWriteLog ${LINENO} ""
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------------------------- end pull the snapshots ----------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    #
    # write out the temp log and empty the log variable
    fnWriteLogTempFile
    #
}
#
##########################################################################
#
#
# function to merge recursive services arrays in two JSON files 
#
function fnMergeArraysServicesRecursiveJsonFile()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnMergeArraysServicesRecursiveJsonFile' "
    fnWriteLog ${LINENO} ""
    #        
    # set the source file
    merge_service_recursive_files_snapshots_source="$1"
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'merge_service_recursive_files_snapshots_source': "
    fnWriteLog ${LINENO} "$merge_service_recursive_files_snapshots_source"
    fnWriteLog ${LINENO} ""
    #
    # set the source file
    merge_service_recursive_files_snapshots_target="$2"
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'merge_service_recursive_files_snapshots_target': "
    fnWriteLog ${LINENO} "$merge_service_recursive_files_snapshots_target"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
    #
    # check for debug log 
    if [[ "$logging" = 'z' ]] 
        then 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "--------------------------------------------------------------"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "--------------------------------------------------------------"
            fnWriteLog ${LINENO} "" 
            fnWriteLog ${LINENO} ""                             
            fnWriteLog ${LINENO} ""                
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "contents of source file: "$merge_service_recursive_files_snapshots_source": "
            feed_write_log="$(cat "$merge_service_recursive_files_snapshots_source" 2>&1)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                    fnWriteLog ${LINENO} level_0 ""
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "contents of file "$merge_service_recursive_files_snapshots_source":"
                    feed_write_log="$(cat "$merge_service_recursive_files_snapshots_source")"
                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                    fnWriteLog ${LINENO} level_0 ""
                    #    
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnWriteLog ${LINENO} "$feed_write_log"
            fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "contents of target file: "$merge_service_recursive_files_snapshots_target": "
            feed_write_log="$(cat "$merge_service_recursive_files_snapshots_target" 2>&1)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                    fnWriteLog ${LINENO} level_0 ""
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "contents of file "$merge_service_recursive_files_snapshots_target":"
                    feed_write_log="$(cat "$files_snapshots_target")"
                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                    fnWriteLog ${LINENO} level_0 ""
                    #    
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnWriteLog ${LINENO} "$feed_write_log"
            fnWriteLog ${LINENO} ""
    #     
    fi  # end check for debug log 
    #                       
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "loading variable 'merge_service_recursive' "
    merge_service_recursive="$(cat "$merge_service_recursive_files_snapshots_source" | jq -r '.regions[0].regionServices[0].service[0] | keys_unsorted' | tr -d '"][, ' | grep -v '^$' 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "value of variable 'merge_service_recursive':"
            fnWriteLog ${LINENO} level_0 "$merge_service_recursive"
            fnWriteLog ${LINENO} level_0 ""
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "contents of file "$merge_service_recursive_files_snapshots_source":"
            feed_write_log="$(cat "$merge_service_recursive_files_snapshots_source")"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi  # end check for pipeline errors 
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'merge_service_recursive':"
    fnWriteLog ${LINENO} "$merge_service_recursive"
    fnWriteLog ${LINENO} ""
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "loading variable 'merge_service_recursive_key_name' "   
    merge_service_recursive_key_name="$(cat "$merge_service_recursive_files_snapshots_source" \
    | jq -r --arg merge_service_recursive_jq "$merge_service_recursive" '.regions[0].regionServices[0].service[0][$merge_service_recursive_jq][0] | keys_unsorted' | tr -d '"][, ' | grep -v '^$' | head -n 1 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "value of variable 'merge_service_recursive_key_name':"
            fnWriteLog ${LINENO} level_0 "$merge_service_recursive_key_name"
            fnWriteLog ${LINENO} level_0 ""
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "contents of file "$merge_service_recursive_files_snapshots_source":"
            feed_write_log="$(cat "$merge_service_recursive_files_snapshots_source")"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi  # end check for pipeline errors 
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'merge_service_recursive_key_name':"
    fnWriteLog ${LINENO} "$merge_service_recursive_key_name"
    fnWriteLog ${LINENO} ""
    #   
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "merging recursive services JSON files:"
    fnWriteLog ${LINENO} "$merge_service_recursive_files_snapshots_source" 
    fnWriteLog ${LINENO} "and"
    fnWriteLog ${LINENO} "$merge_service_recursive_files_snapshots_target"
    fnWriteLog ${LINENO} "into file:"
    fnWriteLog ${LINENO} "$this_path_temp"/"$this_utility_acronym"-merge-services-recursive-file-build-temp.json
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "command:" 
    fnWriteLog ${LINENO} "jq -Mn "
    fnWriteLog ${LINENO} "--argfile merge_service_recursive_file_merge_services_target_jq" 
    fnWriteLog ${LINENO} "$merge_service_recursive_files_snapshots_target"
    fnWriteLog ${LINENO} "--argfile merge_service_recursive_file_merge_services_source_jq" 
    fnWriteLog ${LINENO} "$merge_service_recursive_files_snapshots_source"
    fnWriteLog ${LINENO} ""
    # this solution from: https://stackoverflow.com/questions/46282648/how-to-merge-identically-structured-nested-json-files-using-jq   
    jq -Mn \
      --argfile merge_service_recursive_file_merge_services_target_jq "$merge_service_recursive_files_snapshots_target" \
      --argfile merge_service_recursive_file_merge_services_source_jq "$merge_service_recursive_files_snapshots_source"  \
      --arg merge_service_recursive_jq "$merge_service_recursive"  \
      --arg merge_service_recursive_key_name_jq "$merge_service_recursive_key_name" \
    '
      def merge:                         # merge function
          # process $merge_service_recursive_file_merge_services_target_jq then $merge_service_recursive_file_merge_services_source_jq
          ($merge_service_recursive_file_merge_services_target_jq, $merge_service_recursive_file_merge_services_source_jq)         
          | .account as $a                 # save .account in $a
          | .regions[]                     # for each element of .regions
          | .regionName as $r              # save .regionName in $r
          | .regionServices[]              # for each element of regionServices 
          | .serviceType as $t             # save .serviceType in $t 
          | .service[] as $s               # save each element of .service in $s
          | (
             $s[$merge_service_recursive_jq][]? as $rs 
           | {($a): {($r): {($t): {($merge_service_recursive_jq): {($rs[$merge_service_recursive_key_name_jq]): $rs}}}}}
           )
          # | debug                        # enable to see streams 
      ;

      reduce merge as $x ({}; . * $x)  # use '*' to recombine all the objects from merge

      # | debug                            # enable to see merged streams 


      | keys[] as $a                                # for each key (account) of combined object
      | {account:$a, regions:[                      #  construct object with {account, regions array}
          .[$a]                                     #   for each account
        | keys[] as $r                              #    for each key (regionName) of account object 
        | {regionName:$r, regionServices:[          #     constuct object with {regionName, regionServices array}
             .[$r]                                  #      for each region
          | keys[] as $t                            #       for each key (service type) of region object        
          | {serviceType:$t, service:[              #        construct object with {serviceType, service array}
                .[$t]                               #         for each serviceType
            |   {($merge_service_recursive_jq): [.[$merge_service_recursive_jq][]]}             # add recursive service to service
          ]}                                        #        add service objects to service array
        ]}                                          #     add service objects to regionServices array       
      ]}'>"$this_path_temp"/"$this_utility_acronym"-merge-services-recursive-file-build-temp.json          # #  add service objects to regions array and write merged JSON to temp build file 
    #      
    #
    # check for debug log 
    if [[ "$logging" = 'z' ]] 
        then 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "--------------------------------------------------------------"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "--------------------------------------------------------------"
            fnWriteLog ${LINENO} "" 
            fnWriteLog ${LINENO} ""                             
            fnWriteLog ${LINENO} ""                
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "Contents of file: '"$this_path_temp"/"$this_utility_acronym"-merge-services-recursive-file-build-temp.json' "
            fnWriteLog ${LINENO} ""  
                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-merge-services-recursive-file-build-temp.json  2>&1)"
                #
                # check for command / pipeline error(s)
                if [ "$?" -ne 0 ]
                    then
                        #
                        # set the command/pipeline error line number
                        error_line_pipeline="$((${LINENO}-7))"
                        #
                        #
                        fnWriteLog ${LINENO} level_0 ""
                        fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                        fnWriteLog ${LINENO} level_0 "$feed_write_log"
                        fnWriteLog ${LINENO} level_0 ""
                        #
                        fnWriteLog ${LINENO} level_0 ""
                        fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"-merge-services-recursive-file-build-temp.json:"
                        feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-merge-services-recursive-file-build-temp.json)"
                        fnWriteLog ${LINENO} level_0 "$feed_write_log"
                        fnWriteLog ${LINENO} level_0 ""
                        #                     
                        # call the command / pipeline error function
                        fnErrorPipeline
                        #
                        #
                fi
                #
                fnWriteLog ${LINENO} "$feed_write_log"
                #
    #     
    fi  # end check for debug log 
    #                       
}
#
##########################################################################
#
#
# function to merge services arrays in two JSON files 
#
function fnMergeArraysServicesJsonFile ()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnMergeArraysServicesJsonFile' "
    fnWriteLog ${LINENO} ""
    #        
    # set the source file
    files_snapshots_source="$1"
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'files_snapshots_source': "
    fnWriteLog ${LINENO} "$files_snapshots_source"
    fnWriteLog ${LINENO} ""
    #
    # set the source file
    files_snapshots_target="$2"
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'files_snapshots_target': "
    fnWriteLog ${LINENO} "$files_snapshots_target"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
    #
    # check for debug log 
    if [[ "$logging" = 'z' ]] 
        then 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "--------------------------------------------------------------"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "--------------------------------------------------------------"
            fnWriteLog ${LINENO} "" 
            fnWriteLog ${LINENO} ""                             
            fnWriteLog ${LINENO} ""                    
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "contents of source file: "$files_snapshots_source": "
            feed_write_log="$(cat "$files_snapshots_source" 2>&1)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                    fnWriteLog ${LINENO} level_0 ""
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "contents of file "$files_snapshots_source":"
                    feed_write_log="$(cat "$files_snapshots_source")"
                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                    fnWriteLog ${LINENO} level_0 ""
                    #    
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnWriteLog ${LINENO} "$feed_write_log"
            fnWriteLog ${LINENO} ""
        #     
    fi  # end check for debug log 
    #                       
    #
    # check for debug log 
    if [[ "$logging" = 'z' ]] 
        then 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "--------------------------------------------------------------"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "--------------------------------------------------------------"
            fnWriteLog ${LINENO} "" 
            fnWriteLog ${LINENO} ""                             
            fnWriteLog ${LINENO} ""                    
            fnWriteLog ${LINENO} ""    
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "contents of target file: "$files_snapshots_target": "
            feed_write_log="$(cat "$files_snapshots_target" 2>&1)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                    fnWriteLog ${LINENO} level_0 ""
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "contents of file "$files_snapshots_target":"
                    feed_write_log="$(cat "$files_snapshots_target")"
                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                    fnWriteLog ${LINENO} level_0 ""
                    #    
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnWriteLog ${LINENO} "$feed_write_log"
            fnWriteLog ${LINENO} ""
        #     
    fi  # end check for debug log 
    #                       
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "merging services JSON files:"
    fnWriteLog ${LINENO} "$files_snapshots_source" 
    fnWriteLog ${LINENO} "and"
    fnWriteLog ${LINENO} "$files_snapshots_target"
    fnWriteLog ${LINENO} "into file:"
    fnWriteLog ${LINENO} "$this_utility_acronym""-merge-services-file-build-temp.json"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "command:" 
    fnWriteLog ${LINENO} "jq -Mn --argfile file_merge_services_target_jq" 
    fnWriteLog ${LINENO} "$files_snapshots_target"
    fnWriteLog ${LINENO} "--argfile file_merge_services_source_jq" 
    fnWriteLog ${LINENO} "$files_snapshots_source"
    fnWriteLog ${LINENO} ""
    # this solution from: https://stackoverflow.com/questions/46282648/how-to-merge-identically-structured-nested-json-files-using-jq   
    jq -Mn --argfile file_merge_services_target_jq "$files_snapshots_target" --argfile file_merge_services_source_jq "$files_snapshots_source" '
       def merge:                         # merge function
           ($file_merge_services_target_jq, $file_merge_services_source_jq)         # process $file_merge_services_target_jq then $file_merge_services_source_jq
     | .account as $a                 # save .account in $a
     | .regions[]                     # for each element of .regions
     | .regionName as $r              # save .regionName in $r
     | .regionServices[]              # for each element of regionServices 
     | .serviceType as $t             # save .serviceType in $t 
     | .service[] as $s               # save each element of .service in $s
     | {($a): {($r): {($t): $s}}}     # generate object for each account, region, serviceType, service
     # | debug                          # uncomment debug here to see stream                                   
   ;
     reduce merge as $x ({}; . * $x)  # use '*' to recombine all the objects from merge

   # | debug                          # uncomment debug here to see combined object

    | keys[] as $a                              # for each key (account) of combined object
    | {account:$a, regions:[                    #  construct object with {account, regions array}
        .[$a]                                   #   for each account
      | keys[] as $r                            #    for each key (regionName) of account object
      | {regionName:$r, regionServices:[        #     constuct object with {regionName, regionServices array}
           .[$r]                                #      for each region
        | keys[] as $t                          #       for each key (service type) of region object        
        | {serviceType:$t, service:[            #        construct object with {serviceType, service array}
              .[$t]                             #         for each serviceType
             | keys[] as $s                     #          for each service
             | {($s): .[$s]}                    #           generate service object
        ]}                                      #        add service objects to service array
      ]}                                        #     add service objects to regionServices array       
    ]}'>"$this_path_temp"/"$this_utility_acronym"-merge-services-file-build-temp.json  #  add service objects to regions array and write merged JSON to temp build file 
    #      
    #
    # check for debug log 
    if [[ "$logging" = 'z' ]] 
        then 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "--------------------------------------------------------------"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "--------------------------------------------------------------"
            fnWriteLog ${LINENO} "" 
            fnWriteLog ${LINENO} ""                             
            fnWriteLog ${LINENO} ""                    
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "Contents of file: "$this_utility_acronym"-merge-services-file-build-temp.json "
            fnWriteLog ${LINENO} ""  
            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build-temp.json  2>&1)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                    fnWriteLog ${LINENO} level_0 ""
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"-merge-services-file-build.json:"
                    feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build-temp.json)"
                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                    fnWriteLog ${LINENO} level_0 ""
                    #                     
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
                    #
            fi
            #
            fnWriteLog ${LINENO} "$feed_write_log"
            #
    #     
    fi  # end check for debug log 
    #                       
}
#
##########################################################################
#
#
# function to create the merged services JSON file 
#
function fnCreateMergedServicesJsonFile ()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnCreateMergedServicesJsonFile' "
    fnWriteLog ${LINENO} ""
    #       
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "loading the variable 'aws_region_fn_create_merged_services_json_file' from the function parameter 1: "$ 1" "  
    aws_region_fn_create_merged_services_json_file=$1
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "loading the variable 'find_name_fn_create_merged_services_json_file' from the function parameter 1: "$ 2" "  
    find_name_fn_create_merged_services_json_file=$2
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'aws_region_fn_create_merged_services_json_file': "$aws_region_fn_create_merged_services_json_file" "  
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'find_name_fn_create_merged_services_json_file': "$find_name_fn_create_merged_services_json_file" "  
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} level_0 "Merging the AWS services snapshot JSON files for region: "$aws_region_fn_create_merged_services_json_file"..."
    fnWriteLog ${LINENO} ""   
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} " in section: begin create merged services JSON file"
    fnWriteLog ${LINENO} "------------------------------------------------"  
    fnWriteLog ${LINENO} "value of variable 'aws_account':"
    fnWriteLog ${LINENO} "$aws_account"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'aws_service':"
    fnWriteLog ${LINENO} "$aws_service"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'aws_service_snapshot_name_underscore':"
    fnWriteLog ${LINENO} "$aws_service_snapshot_name_underscore"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "------------------------------------------------"  
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "------------------------------ begin create merged services JSON file -----------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnHeader
    # load the variables
    #
    # initialize the counters
    #
    #
    fnWriteLog ${LINENO} ""
    fnHeader
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "Creating merged services JSON file "
    fnWriteLog ${LINENO} level_0 ""
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "creating snapshot file list file: "$this_utility_acronym"-snapshot-file-list.txt "
    feed_write_log="$(find "$write_path_snapshots" -name "$find_name_fn_create_merged_services_json_file" -printf '%f\n' | sort > "$this_path_temp"/"$this_utility_acronym"'-snapshot-file-list.txt' 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                fnWriteLog ${LINENO} level_0 "$feed_write_log"
                fnWriteLog ${LINENO} level_0 ""
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"'-snapshot-file-list.txt':"
                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot-file-list.txt )"
                fnWriteLog ${LINENO} level_0 "$feed_write_log"
                fnWriteLog ${LINENO} level_0 ""
                #                     
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "loading variable: 'files_snapshots' "
    files_snapshots="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot-file-list.txt 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "value of variable 'files_snapshots':"
                fnWriteLog ${LINENO} level_0 "$files_snapshots"
                fnWriteLog ${LINENO} level_0 ""
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"'-snapshot-file-list.txt':"
                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot-file-list.txt )"
                fnWriteLog ${LINENO} level_0 "$feed_write_log"
                fnWriteLog ${LINENO} level_0 ""
                #                     
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'files_snapshots': "
    feed_write_log="$(echo "$files_snapshots" 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "loading variable: 'count_files_snapshots' "
    count_files_snapshots="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot-file-list.txt | wc -l 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "value of variable 'count_files_snapshots':"
                fnWriteLog ${LINENO} level_0 "$count_files_snapshots"
                fnWriteLog ${LINENO} level_0 ""
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"'-snapshot-file-list.txt':"
                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot-file-list.txt )"
                fnWriteLog ${LINENO} level_0 "$feed_write_log"
                fnWriteLog ${LINENO} level_0 ""
                #                     
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'count_files_snapshots': "
    feed_write_log="$(echo "$count_files_snapshots" 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    #
    # check for no files to merge
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "checking for no region services files to merge "
    if [[ "$count_files_snapshots" -eq 0 ]] 
        then 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "there are no region services files to merge "
            fnWriteLog ${LINENO} "skipping to next via the 'continue' command "
            #
            continue
            #
    fi  # end check for no files to merge 
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "loading variable: 'counter_files_snapshots' "
    counter_files_snapshots=0
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'counter_files_snapshots': "
    feed_write_log="$(echo "$counter_files_snapshots" 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "read the list of snapshot files and merge the services"
    fnWriteLog ${LINENO} ""  
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------- entering loop: read variable 'files_snapshots' -----------------------  "
    fnWriteLog ${LINENO} ""
    #
    while read -r files_snapshots_line
        do
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "----------------------- loop head: read variable 'files_snapshots' -----------------------  "
            fnWriteLog ${LINENO} ""
            #
            # display the header    
            fnHeader
            # display the task progress bar
            fnProgressBarTaskDisplay "$counter_aws_region_list" "$count_aws_region_list"
            # display the sub-task progress bar
            fnProgressBarTaskSubDisplay "$counter_files_snapshots" "$count_files_snapshots"
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "Creating merged 'all services' JSON file for region: "$aws_region_fn_create_merged_services_json_file" "
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "Merging JSON file: "$files_snapshots_line" "
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "pulling the service key values from the file "  
            fnWriteLog ${LINENO} "loading variable 'aws_service' "
            aws_service="$(cat "$write_path_snapshots"/"$files_snapshots_line" | jq '.regions[0].regionServices[0].serviceType' | tr -d '"][, ' | grep -v '^$' 2>&1)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "value of variable 'aws_service':"
                    fnWriteLog ${LINENO} level_0 "$aws_service"
                    fnWriteLog ${LINENO} level_0 ""
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "contents of file "$write_path_snapshots"/"$files_snapshots_line":"
                    feed_write_log="$(cat "$write_path_snapshots"/"$files_snapshots_line" )"
                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                    fnWriteLog ${LINENO} level_0 ""
                    #                     
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of variable 'aws_service':"
            fnWriteLog ${LINENO} "$aws_service"
            fnWriteLog ${LINENO} ""
            #
            fnWriteLog ${LINENO} "loading variable 'aws_service_snapshot_name_underscore' "
            aws_service_snapshot_name_underscore="$(cat "$write_path_snapshots"/"$files_snapshots_line" | jq -r '.regions[0].regionServices[0].service[0] | keys' | tr -d '"][, ' | grep -v '^$' 2>&1)"
            #
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "value of variable 'aws_service_snapshot_name_underscore':"
                    fnWriteLog ${LINENO} level_0 "$aws_service_snapshot_name_underscore"
                    fnWriteLog ${LINENO} level_0 ""
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "contents of file "$write_path_snapshots"/"$files_snapshots_line":"
                    feed_write_log="$(cat "$write_path_snapshots"/"$files_snapshots_line" )"
                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                    fnWriteLog ${LINENO} level_0 ""
                    #                     
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of variable 'aws_service_snapshot_name_underscore':"
            fnWriteLog ${LINENO} "$aws_service_snapshot_name_underscore"
            fnWriteLog ${LINENO} ""
            #
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "test for first time through; if so, then initialize the file "  
            if [[ "$counter_files_snapshots" = 0 ]] 
                then 
                    #
                    fnWriteLog ${LINENO} ""  
                    fnWriteLog ${LINENO} "this is the first time through the loop"  
                    fnWriteLog ${LINENO} "in the 'create merged services JSON file' section "    
                    fnWriteLog ${LINENO} "initializing the region 'merge services' data file "
                    #
                    file_target_initialize_region="$aws_region_fn_create_merged_services_json_file"
                    file_target_initialize_file="$this_utility_acronym"-merge-services-file-build.json
                    #
                    # calling function to initialize the output file 
                    fnInitializeWriteFileBuildPattern
                    # 
                    # feed_write_log="$(echo "{ \"account\": \"$aws_account\",\"regions\": [ { \"regionName\": \"$aws_region_fn_create_merged_services_json_file\",\"regionServices\": [ { \"serviceType\": \"$aws_service\",\"service\": [ ] } ] } ] }" > "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build.json  2>&1)"
                    #
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "Contents of file: "$this_utility_acronym"-merge-services-file-build.json "
                    fnWriteLog ${LINENO} ""  
                    feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build.json  2>&1)"
                    #
                    # check for command / pipeline error(s)
                    if [ "$?" -ne 0 ]
                        then
                            #
                            # set the command/pipeline error line number
                            error_line_pipeline="$((${LINENO}-7))"
                            #
                            #
                            fnWriteLog ${LINENO} level_0 ""
                            fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                            fnWriteLog ${LINENO} level_0 "$feed_write_log"
                            fnWriteLog ${LINENO} level_0 ""
                            #
                            fnWriteLog ${LINENO} level_0 ""
                            fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"-merge-services-file-build.json:"
                            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build.json)"
                            fnWriteLog ${LINENO} level_0 "$feed_write_log"
                            fnWriteLog ${LINENO} level_0 ""
                            #                                 
                            # call the command / pipeline error function
                            fnErrorPipeline
                            #
                            #
                    fi
                    #
                    fnWriteLog ${LINENO} "$feed_write_log"
                    #
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "load the target variable with the contents of the file: "$this_utility_acronym"-merge-services-file-build.json "
                    fnWriteLog ${LINENO} ""  
                    files_snapshots_target="$this_path_temp"/"$this_utility_acronym"-merge-services-file-build.json
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "value of variable 'files_snapshots_target': "
                    fnWriteLog ${LINENO} "$files_snapshots_target"
                    fnWriteLog ${LINENO} ""
                    #
                else 
                    fnWriteLog ${LINENO} ""  
                    fnWriteLog ${LINENO} "this is not the first time through the loop"  
                    fnWriteLog ${LINENO} ""  
            fi  # end check for first time through and initialize file 
            #
            # load the source variable with the path
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "loading variable 'files_snapshots_source_merge' with full source file path "
            files_snapshots_source_merge="$write_path_snapshots"/"$files_snapshots_line"
            #
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of variable 'files_snapshots_source_merge':"
            fnWriteLog ${LINENO} "$files_snapshots_source_merge"
            fnWriteLog ${LINENO} ""
            #
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of variable 'files_snapshots_target':"
            fnWriteLog ${LINENO} "$files_snapshots_target"
            fnWriteLog ${LINENO} ""
            #            
            #
            # call the array merge function  
            # parameters are: source target 
            # output file name of the function is: "$this_utility_acronym"-merge-services-file-build-temp.json
            fnMergeArraysServicesJsonFile "$files_snapshots_source_merge" "$files_snapshots_target"
            #
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "Copying contents of file: "$this_utility_acronym"-merge-services-file-build-temp.json to file: "$this_utility_acronym"-merge-services-file-build.json  "
            fnWriteLog ${LINENO} ""  
            cp -f "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build-temp.json "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build.json
            fnWriteLog ${LINENO} ""  
            #
            #
            # check for debug log 
            if [[ "$logging" = 'z' ]] 
                then 
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "--------------------------------------------------------------"
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "--------------------------------------------------------------"
                    fnWriteLog ${LINENO} "" 
                    fnWriteLog ${LINENO} ""                             
                    fnWriteLog ${LINENO} ""                    
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "Contents of file: "$this_utility_acronym"-merge-services-file-build.json "
                    fnWriteLog ${LINENO} ""  
                    feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build.json  2>&1)"
                    #
                    # check for command / pipeline error(s)
                    if [ "$?" -ne 0 ]
                        then
                            #
                            # set the command/pipeline error line number
                            error_line_pipeline="$((${LINENO}-7))"
                            #
                            #
                            fnWriteLog ${LINENO} level_0 ""
                            fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                            fnWriteLog ${LINENO} level_0 "$feed_write_log"
                            fnWriteLog ${LINENO} level_0 ""
                            #
                            fnWriteLog ${LINENO} level_0 ""
                            fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"-merge-services-file-build.json:"
                            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build.json)"
                            fnWriteLog ${LINENO} level_0 "$feed_write_log"
                            fnWriteLog ${LINENO} level_0 ""
                            #                                         
                            # call the command / pipeline error function
                            fnErrorPipeline
                            #
                            #
                    fi
                    #
                    fnWriteLog ${LINENO} "$feed_write_log"
                        #     
            fi  # end check for debug log 
            #                       
            fnWriteLog ${LINENO} ""  
            fnWriteLog ${LINENO} ""  
            fnWriteLog ${LINENO} "increment the files_snapshots counter"
            counter_files_snapshots="$((counter_files_snapshots+1))" 
            fnWriteLog ${LINENO} "value of variable 'counter_files_snapshots': "$counter_files_snapshots" "
            fnWriteLog ${LINENO} "value of variable 'count_files_snapshots': "$count_files_snapshots" "
            fnWriteLog ${LINENO} ""
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "----------------------- loop tail: read variable 'files_snapshots' -----------------------  "
            fnWriteLog ${LINENO} ""
            #
    done< <(echo "$files_snapshots")
    #
    #
    # display the header    
    fnHeader
    # display the task progress bar
    fnProgressBarTaskDisplay "$counter_aws_region_list" "$count_aws_region_list"
    # display the sub-task progress bar
    fnProgressBarTaskSubDisplay "$counter_files_snapshots" "$count_files_snapshots"
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------- done with loop: read variable 'files_snapshots' -----------------------  "
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} level_0 ""    
    fnWriteLog ${LINENO} level_0 "Copying the data file..."    
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "loading the variable 'this_file_account_region_services_all_target' based on the region value: "$aws_region_list_line" "
    # if not global, use the normal file name, if global, use the global file name 
    if [[ "$aws_region_list_line" != 'global' ]] 
        then 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "region is not global so setting file name to variable 'this_file_account_region_services_all': "$this_file_account_region_services_all" "
            this_file_account_region_services_all_target="$this_file_account_region_services_all"
        else 
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "region is global so setting file name to to variable 'this_file_account_region_services_all_global': "$this_file_account_region_services_all_global" "
            this_file_account_region_services_all_target="$this_file_account_region_services_all_global"
    fi  # end check for region = 'global' to set the file name for the write  
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'this_file_account_region_services_all_target': "
    fnWriteLog ${LINENO} " "$this_file_account_region_services_all_target"  "
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "Copying contents of file: "$this_utility_acronym"-merge-services-file-build-temp.json to file: "$this_file_account_region_services_all_target"  "
    fnWriteLog ${LINENO} ""  
    cp -f "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build-temp.json "$this_file_account_region_services_all_target"
    fnWriteLog ${LINENO} ""  
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
            #
            # check for debug log 
            if [[ "$logging" = 'z' ]] 
                then 
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "--------------------------------------------------------------"
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "parameter -g z enables the following log section for debugging" 
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "--------------------------------------------------------------"
                    fnWriteLog ${LINENO} "" 
                    fnWriteLog ${LINENO} ""                             
                    fnWriteLog ${LINENO} ""                       
                    fnWriteLog ${LINENO} "Contents of file: "$this_file_account_region_services_all_target" "
                    fnWriteLog ${LINENO} ""  
                    feed_write_log="$(cat "$this_file_account_region_services_all_target"  2>&1)"
                    #
                    # check for command / pipeline error(s)
                    if [ "$?" -ne 0 ]
                        then
                            #
                            # set the command/pipeline error line number
                            error_line_pipeline="$((${LINENO}-7))"
                            #
                            #
                            fnWriteLog ${LINENO} level_0 ""
                            fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                            fnWriteLog ${LINENO} level_0 "$feed_write_log"
                            fnWriteLog ${LINENO} level_0 ""
                            #
                            fnWriteLog ${LINENO} level_0 ""
                            fnWriteLog ${LINENO} level_0 "contents of file "$this_file_account_region_services_all_target":"
                            feed_write_log="$(cat "$this_file_account_region_services_all_target")"
                            fnWriteLog ${LINENO} level_0 "$feed_write_log"
                            fnWriteLog ${LINENO} level_0 ""
                            #                                                    
                            # call the command / pipeline error function
                            fnErrorPipeline
                            #
                            #
                    fi
                    #
                    fnWriteLog ${LINENO} "$feed_write_log"
                    fnWriteLog ${LINENO} ""  
            #     
            fi  # end check for debug log 
            #                       
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "------------------------------ end create merged services JSON file -----------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
}
#
##########################################################################
#
#
# ---begin: function to create the merged 'all services' JSON file for all regions in the account
#
function fnCreateMergedServicesAllJsonFile ()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnCreateMergedServicesAllJsonFile' "
    fnWriteLog ${LINENO} ""
    #       
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "loading the variable 'aws_region_fn_create_merged_services_json_file' from the function parameter 1: "$ 1" "  
    aws_region_fn_create_merged_services_all_json_file=$1
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "loading the variable 'find_name_fn_create_merged_services_json_file' from the function parameter 1: "$ 2" "  
    find_name_fn_create_merged_services_all_json_file=$2
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'aws_region_fn_create_merged_services_all_json_file': "$aws_region_fn_create_merged_services_all_json_file" "  
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'find_name_fn_create_merged_services_all_json_file': "$find_name_fn_create_merged_services_all_json_file" "  
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} level_0 "Pulling the AWS Services from AWS for region: "$aws_region_fn_create_merged_services_all_json_file"..."
    fnWriteLog ${LINENO} ""   
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "-------------------- begin: create merged 'all services - all regions' JSON file -------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnHeader
    # load the variables
    #
    # initialize the counters
    #
    #
    fnWriteLog ${LINENO} ""
    fnHeader
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "Creating merged 'all services' JSON file for account: "$aws_account" "
    fnWriteLog ${LINENO} level_0 ""
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "creating snapshot file list file: "$this_utility_acronym"'-snapshot-file-all-list.txt' "
    fnWriteLog ${LINENO} "command: find "$write_path_snapshots" -name "$find_name_fn_create_merged_services_all_json_file" -printf '%f\n' | sort > "$this_path_temp"/"$this_utility_acronym"'-snapshot-file-all-list.txt' "
    feed_write_log="$(find "$write_path_snapshots" -name "$find_name_fn_create_merged_services_all_json_file" -printf '%f\n' | sort > "$this_path_temp"/"$this_utility_acronym"'-snapshot-file-all-list.txt' 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                fnWriteLog ${LINENO} level_0 "$feed_write_log"
                fnWriteLog ${LINENO} level_0 ""
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"'-snapshot-file-all-list.txt':"
                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot-file-all-list.txt )"
                fnWriteLog ${LINENO} level_0 "$feed_write_log"
                fnWriteLog ${LINENO} level_0 ""
                #                     
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "loading variable: 'files_snapshots_all' "
    files_snapshots_all="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot-file-all-list.txt 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "value of variable 'files_snapshots_all':"
                fnWriteLog ${LINENO} level_0 "$files_snapshots_all"
                fnWriteLog ${LINENO} level_0 ""
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"'-snapshot-file-all-list.txt':"
                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot-file-list.txt )"
                fnWriteLog ${LINENO} level_0 "$feed_write_log"
                fnWriteLog ${LINENO} level_0 ""
                #                     
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'files_snapshots_all': "
    feed_write_log="$(echo "$files_snapshots_all" 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "loading variable: 'count_files_snapshots_all' "
    count_files_snapshots_all="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot-file-all-list.txt | wc -l 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "value of variable 'count_files_snapshots_all':"
                fnWriteLog ${LINENO} level_0 "$count_files_snapshots_all"
                fnWriteLog ${LINENO} level_0 ""
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"'-snapshot-file-all-list.txt':"
                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot-file-list.txt )"
                fnWriteLog ${LINENO} level_0 "$feed_write_log"
                fnWriteLog ${LINENO} level_0 ""
                #                     
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'count_files_snapshots_all': "
    feed_write_log="$(echo "$count_files_snapshots_all" 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "loading variable: 'counter_files_snapshots_all' "
    counter_files_snapshots_all=0
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'counter_files_snapshots_all': "
    feed_write_log="$(echo "$counter_files_snapshots_all" 2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} ""  
    # this initialization string also used to create the snapshot build target file via function fnInitializeWriteFileBuild
    fnWriteLog ${LINENO} "in the section: 'create merged 'all services - all regions' JSON file' "  
    fnWriteLog ${LINENO} "initializing the 'all services - all regions' merge services data file "
    #
    file_target_initialize_region="$aws_region_fn_create_merged_services_json_file"
    file_target_initialize_file="$this_utility_acronym"-merge-services-all-file-build.json
    #
    # calling function to initialize the output file 
    fnInitializeWriteFileBuildPattern
    # 
    # feed_write_log="$(echo "{ \"account\": \"$aws_account\",\"regions\": [ { \"regionName\": \"$aws_region_fn_create_merged_services_json_file\",\"regionServices\": [ { \"serviceType\": \"$aws_service\",\"service\": [ ] } ] } ] }" > "$this_path_temp"/"$this_utility_acronym"-merge-services-all-file-build.json  2>&1)"
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "Contents of file: sps-merge-services-all-file-build.json"
    fnWriteLog ${LINENO} ""  
    feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-merge-services-all-file-build.json  2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"-merge-services-all-file-build.json:"
            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-merge-services-all-file-build.json)"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #                                 
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    fnWriteLog ${LINENO} "$feed_write_log"
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "first time through the loop, so load the target variable with the contents of the file: "$this_utility_acronym"-merge-services-file-build.json "
    fnWriteLog ${LINENO} ""  
    files_snapshots_all_target="$this_path_temp"/"$this_utility_acronym"-merge-services-all-file-build.json
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'files_snapshots_all_target': "
    fnWriteLog ${LINENO} "$files_snapshots_all_target"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "read the list of snapshot files and merge the services"
    fnWriteLog ${LINENO} ""  
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------- entering loop: read variable 'files_snapshots_all' -----------------------  "
    fnWriteLog ${LINENO} ""
    #
    while read -r files_snapshots_all_line
        do
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "----------------------- loop head: read variable 'files_snapshots_all' -----------------------  "
            fnWriteLog ${LINENO} ""
            #
            # display the header    
            fnHeader
            # display the task progress bar
            fnProgressBarTaskDisplay "$counter_aws_region_list" "$count_aws_region_list"
            # display the sub-task progress bar
            fnProgressBarTaskSubDisplay "$counter_files_snapshots_all" "$count_files_snapshots_all"
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "Creating merged 'all services' JSON file for account: "$aws_account" "
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "Merging JSON file: "$files_snapshots_all_line" "
            #
            # load the source variable with the path
            fnWriteLog ${LINENO} "loading variable 'files_snapshots_all_source_merge' with full source file path "
            files_snapshots_all_source_merge="$write_path_snapshots"/"$files_snapshots_all_line"
            #
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of variable 'files_snapshots_all_source_merge':"
            fnWriteLog ${LINENO} "$files_snapshots_all_source_merge"
            fnWriteLog ${LINENO} ""
            #
            #
            # call the array merge function  
            # parameters are: source target 
            # output file name of the function is: "$this_utility_acronym"-merge-services-file-build-temp.json
            fnMergeArraysServicesJsonFile "$files_snapshots_all_source_merge" "$files_snapshots_all_target"
            #
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "Copying contents of file: "$this_utility_acronym"-merge-services-file-build-temp.json to file: "$this_utility_acronym"-merge-services-file-build.json  "
            fnWriteLog ${LINENO} ""  
            cp -f "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build-temp.json "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build.json
            fnWriteLog ${LINENO} ""  
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "Contents of file: "$this_utility_acronym"-merge-services-file-build.json "
            fnWriteLog ${LINENO} ""  
            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build.json  2>&1)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                    fnWriteLog ${LINENO} level_0 ""
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "contents of file "$this_utility_acronym"-merge-services-file-build.json:"
                    feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build.json)"
                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                    fnWriteLog ${LINENO} level_0 ""
                    #                                         
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
                    #
            fi
            #
            fnWriteLog ${LINENO} "$feed_write_log"
            #
            fnWriteLog ${LINENO} ""  
            #
            fnWriteLog ${LINENO} ""  
            fnWriteLog ${LINENO} "set the target variable 'files_snapshots_all_target' to "$this_utility_acronym"-merge-services-file-build.json "
            files_snapshots_all_target="$this_path_temp"/"$this_utility_acronym"-merge-services-file-build.json
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of variable 'files_snapshots_all_target':"
            fnWriteLog ${LINENO} "$files_snapshots_all_target"
            fnWriteLog ${LINENO} ""
            #
            fnWriteLog ${LINENO} ""  
            fnWriteLog ${LINENO} "increment the files_snapshots_all counter"
            counter_files_snapshots_all="$((counter_files_snapshots_all+1))" 
            fnWriteLog ${LINENO} "value of variable 'counter_files_snapshots_all': "$counter_files_snapshots_all" "
            fnWriteLog ${LINENO} "value of variable 'count_files_snapshots_all': "$count_files_snapshots_all" "
            fnWriteLog ${LINENO} ""
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "----------------------- loop tail: read variable 'files_snapshots_all' -----------------------  "
            fnWriteLog ${LINENO} ""
            #
    done< <(echo "$files_snapshots_all")
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------- done with loop: read variable 'files_snapshots_all' -----------------------  "
    fnWriteLog ${LINENO} ""
    #
    #
    # display the header    
    fnHeader
    # display the task progress bar
    fnProgressBarTaskDisplay "$counter_aws_region_list" "$count_aws_region_list"
    # display the sub-task progress bar
    fnProgressBarTaskSubDisplay "$counter_files_snapshots_all" "$count_files_snapshots_all"
    #
    fnWriteLog ${LINENO} level_0 ""    
    fnWriteLog ${LINENO} level_0 "Copying the data file..."    
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "Copying contents of file: "$this_utility_acronym"-merge-services-file-build-temp.json to file: "$this_file_account_services_all"  "
    fnWriteLog ${LINENO} ""  
    cp -f "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build-temp.json "$this_file_account_services_all"
    fnWriteLog ${LINENO} ""  
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "Contents of file: "$this_file_account_services_all" "
    fnWriteLog ${LINENO} ""  
    feed_write_log="$(cat "$this_file_account_services_all"  2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "contents of file "$this_file_account_services_all":"
            feed_write_log="$(cat "$this_file_account_services_all")"
            fnWriteLog ${LINENO} level_0 "$feed_write_log"
            fnWriteLog ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""  
    #
    #
    fnWriteLog ${LINENO} "increment the task counter"
    fnCounterIncrementTask
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "--------------------- end: create merged 'all services - all regions' JSON file --------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} ""
}
#
#
##############################################################################################################33
#                           Function definition end
##############################################################################################################33
#
# 
###########################################################################################################################
#
#
# enable logging to capture initial segments
#
logging="x"
# 
###########################################################################################################################
#
#
# build the menu and header text line and bars 
#
text_header='AWS Services Snapshot Utility v'
count_script_version_length=${#script_version}
count_text_header_length=${#text_header}
count_text_block_length=$(( count_script_version_length + count_text_header_length ))
count_text_width_menu=104
count_text_width_header=83
count_text_side_length_menu=$(( (count_text_width_menu - count_text_block_length) / 2 ))
count_text_side_length_header=$(( (count_text_width_header - count_text_block_length) / 2 ))
count_text_bar_menu=$(( (count_text_side_length_menu * 2) + count_text_block_length + 2 ))
count_text_bar_header=$(( (count_text_side_length_header * 2) + count_text_block_length + 2 ))
# source and explanation for the following use of printf is here: https://stackoverflow.com/questions/5799303/print-a-character-repeatedly-in-bash
text_bar_menu_build="$(printf '%0.s-' $(seq 1 "$count_text_bar_menu")  )"
text_bar_header_build="$(printf '%0.s-' $(seq 1 "$count_text_bar_header")  )"
text_side_menu="$(printf '%0.s-' $(seq 1 "$count_text_side_length_menu")  )"
text_side_header="$(printf '%0.s-' $(seq 1 "$count_text_side_length_header")  )"
text_menu="$(echo "$text_side_menu"" ""$text_header""$script_version"" ""$text_side_menu")"
text_menu_bar="$(echo "$text_bar_menu_build")"
text_header="$(echo " ""$text_side_header"" ""$text_header""$script_version"" ""$text_side_header")"
text_header_bar="$(echo " ""$text_bar_header_build")"
# 
###########################################################################################################################
#
#
# display initializing message
#
clear
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_header"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " This utility snapshots AWS Services and writes the data to JSON files "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " This script will: "
fnWriteLog ${LINENO} level_0 " - Capture the current state of AWS Services in the driver file "
fnWriteLog ${LINENO} level_0 " - Write the current state of each service to a JSON file "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_header_bar"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "                            Please wait  "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "  Checking the input parameters and initializing the app " 
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "  Depending on connection speed and AWS API response, this can take " 
fnWriteLog ${LINENO} level_0 "  from a few seconds to a few minutes "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "  Status messages and opening menu will appear below"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_header_bar"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
# 
#
###################################################
#
#
# log the task counts  
# 
fnWriteLog ${LINENO} "value of variable 'count_this_file_tasks': "$count_this_file_tasks" "
fnWriteLog ${LINENO} "value of variable 'count_this_file_tasks_end': "$count_this_file_tasks_end" "
fnWriteLog ${LINENO} "value of variable 'count_this_file_tasks_increment': "$count_this_file_tasks_increment" "
#
###################################################
#
#
# check command line parameters 
# check for -h
#
if [[ "$1" = "-h" ]] 
    then
        clear
        fnUsage
fi
#
###################################################
#
#
# check command line parameters 
# check for --version
#
if [[ "$1" = "--version" ]]  
    then
        clear 
        echo ""
        echo "'AWS Services Snapshot' script version: "$script_version" "
        echo ""
        exit 
fi
#
###################################################
#
#
# check command line parameters 
# if less than 2, then display the Usage
#
if [[ "$#" -lt 2 ]] ; then
    clear
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "-------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  ERROR: You did not enter all of the required parameters " 
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  You must provide a profile name for the profile parameter: -p  "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  Example: "$0" -p MyProfileName  "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "-------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    fnUsage
fi
#
###################################################
#
#
# check command line parameters 
# if too many parameters, then display the error message and useage
#
if [[ "$#" -gt 10 ]] ; then
    clear
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "-------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  ERROR: You entered too many parameters" 
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  You must provide only one value for all parameters: -p -d -r -b -g  "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  Example: "$0" -p MyProfileName -d MyDriverFile.txt -r us-east-1 -b y -g y"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "-------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    fnUsage
fi
#
###################################################
#
#
# parameter values 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable '@': "$@" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of parameter '1' "$1" "
fnWriteLog ${LINENO} "value of parameter '2' "$2" "
fnWriteLog ${LINENO} "value of parameter '3' "$3" "
fnWriteLog ${LINENO} "value of parameter '4' "$4" "
fnWriteLog ${LINENO} "value of parameter '5' "$5" "
fnWriteLog ${LINENO} "value of parameter '6' "$6" "
#
###################################################
#
#
# load the main loop variables from the command line parameters 
#
while getopts "p:d:r:b:g:h" opt; 
    do
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable '@': "$@" "
        fnWriteLog ${LINENO} "value of variable 'opt': "$opt" "
        fnWriteLog ${LINENO} "value of variable 'OPTIND': "$OPTIND" "
        fnWriteLog ${LINENO} ""   
        #     
        case "$opt" in
        p)
            cli_profile="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -p 'cli_profile': "$cli_profile" "
        ;;
        d)
            file_driver="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -d 'file_driver': "$file_driver" "
        ;;
        r)
            aws_region="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -r 'aws_region': "$aws_region" "
        ;;      
        b)
            verbose="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -b 'verbose': "$verbose" "
        ;;  
        g)
            logging="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -g 'logging': "$logging" "
        ;;  
        z)
            logging="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -g 'logging': "$logging" "
        ;;  
        h)
            fnUsage
        ;;   
        \?)
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "invalid parameter entry "
            fnWriteLog ${LINENO} "value of variable 'OPTARG': "$OPTARG" "
            clear
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "  ERROR: You entered an invalid parameter." 
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "  Parameters entered: "$@""
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
            fnWriteLog ${LINENO} level_0 ""
            fnUsage
        ;;
    esac
done
#
###################################################
#
#
# check logging variable 
#
#
###################################################
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable '@': "$@" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'logging': "$logging" "
fnWriteLog ${LINENO} ""
#
###################################################
#
#
# disable logging if not set by the -g parameter 
#
fnWriteLog ${LINENO} "if logging not enabled by parameter, then disabling logging "
if [[ ("$logging" != "y") ]] 
    then 
        if [[ ("$logging" != "z") ]]  
            then
                logging="n"
        fi  # end test for logging = z
fi  # end test for logging = y
#
###################################################
#
#
# set the log suffix parameter 
#
if [[ "$logging" = 'y' ]] 
    then 
        log_suffix='info'
elif [[ "$logging" = 'z' ]] 
    then 
        log_suffix='debug'
fi  # end test logging variable and set log suffix 
#
###################################################
#
#
# log the parameter values 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'cli_profile' "$cli_profile" "
fnWriteLog ${LINENO} "value of variable 'verbose' "$verbose" "
fnWriteLog ${LINENO} "value of variable 'logging' "$logging" "
fnWriteLog ${LINENO} "value of variable 'log_suffix' "$log_suffix" "
fnWriteLog ${LINENO} "value of -r 'aws_region': "$aws_region" "
#
###################################################
#
#
# check command line parameters 
# check for valid AWS CLI profile 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "count the available AWS CLI profiles that match the -p parameter profile name "
count_cli_profile="$(cat /home/"$this_user"/.aws/config | grep -c "$cli_profile")"
# if no match, then display the error message and the available AWS CLI profiles 
if [[ "$count_cli_profile" -ne 1 ]]
    then
        clear
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  ERROR: You entered an invalid AWS CLI profile: "$cli_profile" " 
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  Available cli_profiles are:"
        cli_profile_available="$(cat /home/"$this_user"/.aws/config | grep "\[profile" 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "value of variable 'cli_profile_available':"
                fnWriteLog ${LINENO} level_0 "$cli_profile_available"
                fnWriteLog ${LINENO} level_0 ""
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "contents of file '/home/'"$this_user"'/.aws/config':"
                feed_write_log="$(cat /home/"$this_user"/.aws/config)"
                fnWriteLog ${LINENO} level_0 "$feed_write_log"
                fnWriteLog ${LINENO} level_0 ""
                #                                                    
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnWriteLog ${LINENO} "value of variable 'cli_profile_available': "$cli_profile_available ""
        feed_write_log="$(echo "  "$cli_profile_available"" 2>&1)"
        fnWriteLog ${LINENO} level_0 "$feed_write_log"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  To set up an AWS CLI profile enter: aws configure --profile profileName "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  Example: aws configure --profile MyProfileName "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnUsage
fi  # end test of count of matching AWS CLI profiles  
#
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'count_cli_profile':"
fnWriteLog ${LINENO} "$count_cli_profile"
fnWriteLog ${LINENO} ""
#
###################################################
#
#
# check command line parameters 
# check for driver file variable 
#
# if no driver file name provided, then default to aws-services-snapshot-driver.txt
if [[ "$file_driver" == "" ]] ;
    then 
        file_driver=aws-services-snapshot-driver.txt
fi
#
##########################################################################
#
#
# test for driver file 
#
if [ ! -f "$this_path"/"$file_driver" ]; 
    then
        fnHeader
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 " Error reading the file: "$file_driver" "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 " Please confirm that the file exists in this directory and has at least one valid AWS service  "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 ""        
        fnWriteLog ${LINENO} level_0 " Exiting the script"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        exit 1
fi
#
##########################################################################
#
#
# test for global driver file 
#
if [ ! -f "$this_path"/"$file_driver_global" ]; 
    then
        fnHeader
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 " Error reading the file: "$file_driver_global" "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 " Please confirm that the file exists in this directory "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 ""        
        fnWriteLog ${LINENO} level_0 " Exiting the script"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        exit 1
fi
#
###################################################
#
#
# pull the AWS account number
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "pulling AWS account"
aws_account="$(aws sts get-caller-identity --profile "$cli_profile" --output text --query 'Account' )"
fnWriteLog ${LINENO} "value of variable 'aws_account': "$aws_account" "
fnWriteLog ${LINENO} ""
#
###################################################
#
#
# set the aws account dependent variables
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "setting the AWS account dependent variables"
#
#
# check for 'all' regions
if [[ "$aws_region" != 'all' ]]
    then
        write_path="$this_path"/aws-"$aws_account"-"$aws_region"-"$this_utility_filename_plug"-"$date_file"
        write_path_snapshots="$write_path"/"$this_utility_filename_plug"-files
        this_path_temp="$write_path"/"$this_utility_acronym"-temp-"$date_file"
        this_file_account_region_services_all="$write_path_snapshots"/"aws-""$aws_account"-"$aws_region"-"$this_utility_filename_plug"-"$date_file"-all-services.json 
        this_file_account_services_all="$write_path_snapshots"/"aws-""$aws_account"-"$this_utility_filename_plug"-"$date_file"-all-services.json         
        this_log_file="aws-""$aws_account"-"$aws_region"-"$this_utility_filename_plug"-"$date_file"-"$log_suffix".log 
        this_log_file_errors=aws-"$aws_account"-"$aws_region"-"$this_utility_filename_plug"-"$date_file"-errors.log 
        this_log_file_full_path="$write_path"/"$this_log_file"
        this_log_file_errors_full_path="$write_path"/"$this_log_file_errors"
        this_summary_report="aws-""$aws_account"-"$aws_region"-"$this_utility_filename_plug"-"$date_file"-summary-report.txt
        this_summary_report_full_path="$write_path"/"$this_summary_report"
    else 
        write_path="$this_path"/aws-"$aws_account"-all-regions-"$this_utility_filename_plug"-"$date_file"
        write_path_snapshots="$write_path"/"$this_utility_filename_plug"-files
        this_path_temp="$write_path"/"$this_utility_acronym"-temp-"$date_file"
        this_file_account_region_services_all="$write_path_snapshots"/"aws-""$aws_account"-all-regions-"$this_utility_filename_plug"-"$date_file"-all-services.json 
        this_file_account_services_all="$write_path_snapshots"/"aws-""$aws_account"-all-regions-"$this_utility_filename_plug"-"$date_file"-all-services.json         
        this_log_file="aws-""$aws_account"-"$this_utility_filename_plug"-"$date_file"-"$log_suffix".log 
        this_log_file_errors=aws-"$aws_account"-"$this_utility_filename_plug"-"$date_file"-errors.log 
        this_log_file_full_path="$write_path"/"$this_log_file"
        this_log_file_errors_full_path="$write_path"/"$this_log_file_errors"
        this_summary_report="aws-""$aws_account"-"$this_utility_filename_plug"-"$date_file"-summary-report.txt
        this_summary_report_full_path="$write_path"/"$this_summary_report"
fi  # end test for all regions       
#
write_file_service_names="$this_path_temp"/"$this_utility_acronym"'-write-file-service-names.txt'
#
fnWriteLog ${LINENO} "value of variable 'aws_region':"
fnWriteLog ${LINENO} " "$aws_region" "
fnWriteLog ${LINENO} "value of variable 'write_path': "
fnWriteLog ${LINENO} ""$write_path" "
fnWriteLog ${LINENO} "value of variable 'write_path_snapshots':"
fnWriteLog ${LINENO} ""$write_path_snapshots" "
fnWriteLog ${LINENO} "value of variable 'this_path_temp':"
fnWriteLog ${LINENO} " "$this_path_temp" "
fnWriteLog ${LINENO} "value of variable 'this_file_account_region_services_all':"
fnWriteLog ${LINENO} " "$this_file_account_region_services_all" "
fnWriteLog ${LINENO} "value of variable 'this_log_file': "$this_log_file" "
fnWriteLog ${LINENO} "value of variable 'this_log_file_errors':"
fnWriteLog ${LINENO} " "$this_log_file_errors" "
fnWriteLog ${LINENO} "value of variable 'this_log_file_full_path':"
fnWriteLog ${LINENO} " "$this_log_file_full_path" "
fnWriteLog ${LINENO} "value of variable 'this_log_file_errors_full_path':"
fnWriteLog ${LINENO} " "$this_log_file_errors_full_path" "
fnWriteLog ${LINENO} "value of variable 'this_summary_report': "$this_summary_report" "
fnWriteLog ${LINENO} "value of variable 'this_summary_report_full_path':"
fnWriteLog ${LINENO} " "$this_summary_report_full_path" "
fnWriteLog ${LINENO} "value of variable 'write_file_service_names':"
fnWriteLog ${LINENO} " "$write_file_service_names" "
fnWriteLog ${LINENO} ""
#
###################################################
#
#
# set the task count based on all regions
#
# if not all regions, subtract one task for the 'all regions merge' task
if [[ "$aws_region" != 'all' ]] 
    then 
        count_this_file_tasks=$((count_this_file_tasks-1))
fi
#
###################################################
#
#
# create the directories
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "creating write path directories "
feed_write_log="$(mkdir -p "$write_path_snapshots" 2>&1)"
#
# check for command error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        #
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
        fnWriteLog ${LINENO} level_0 "$feed_write_log"
        fnWriteLog ${LINENO} level_0 ""
        #                                                            
        # call the command / pipeline error function
        fnErrorPipeline
        #
fi
#
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "status of write path directories "
feed_write_log="$(ls -ld */ "$this_path" 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "creating temp path directory "
feed_write_log="$(mkdir -p "$this_path_temp" 2>&1)"
#
# check for command error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        #
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
        fnWriteLog ${LINENO} level_0 "$feed_write_log"
        fnWriteLog ${LINENO} level_0 ""
        #                                                            
        # call the command / pipeline error function
        fnErrorPipeline
        #
fi
#
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "status of temp path directories "
feed_write_log="$(ls -ld */ "$this_path_temp" 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
#
###################################################
#
#
# pull the AWS account alias
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "pulling AWS account alias"
aws_account_alias="$(aws iam list-account-aliases --profile "$cli_profile" --output text --query 'AccountAliases' )"
fnWriteLog ${LINENO} "value of variable 'aws_account_alias': "$aws_account_alias" "
fnWriteLog ${LINENO} ""
#
###############################################################################
# 
#
# Initialize the log file
#
if [[ ("$logging" = "y") || ("$logging" = "z") ]] ;
    then
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "initializing the log file "
        fnWriteLog ${LINENO} ""
        echo "Log start" > "$this_log_file_full_path"
        echo "" >> "$this_log_file_full_path"
        echo "This log file name: "$this_log_file"" >> "$this_log_file_full_path"
        echo "" >> "$this_log_file_full_path"
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "contents of file:'$this_log_file_full_path' "
        feed_write_log="$(cat "$this_log_file_full_path"  2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""
#
fi 
#
###############################################################################
# 
#
# Initialize the error log file
#
echo "  Errors:" > "$this_log_file_errors_full_path"
echo "" >> "$this_log_file_errors_full_path"
#
###################################################
#
#
# ---- begin: set the region
#
fnWriteLog ${LINENO} "test for -p profile parameter value "
fnWriteLog ${LINENO} "value of parameter 'aws_region': "$aws_region""
if [[ "$aws_region" = "" ]] 
    then
        fnWriteLog ${LINENO} "count the number of AWS profiles on the system "    
        count_cli_profile_regions="$(cat /home/"$this_user"/.aws/config | grep 'region' | wc -l )"
        fnWriteLog ${LINENO} "value of variable 'count_cli_profile_regions': "$count_cli_profile_regions ""
        if [[ "$count_cli_profile_regions" -lt 2 ]] ;
            then
                fnWriteLog ${LINENO} "one cli profile - setting region from "$cli_profile""           
                aws_region="$(cat /home/"$this_user"/.aws/config | grep 'region' | sed 's/region =//' | tr -d ' ')"
                #
                # check for command / pipeline error(s)
                if [ "$?" -ne 0 ]
                    then
                        #
                        # set the command/pipeline error line number
                        error_line_pipeline="$((${LINENO}-7))"
                        #
                        #
                        fnWriteLog ${LINENO} level_0 ""
                        fnWriteLog ${LINENO} level_0 "value of variable 'aws_region':"
                        fnWriteLog ${LINENO} level_0 "$aws_region"
                        fnWriteLog ${LINENO} level_0 ""
                        #                                                                            
                        # call the command / pipeline error function
                        fnErrorPipeline
                        #
                #
                fi        
                #
            else 
                fnWriteLog ${LINENO} "multiple cli profiles - setting region from "$cli_profile""           
                aws_region="$(cat /home/"$this_user"/.aws/config | sed -n "/dev01/, /profile/p" | grep 'region' | sed 's/region =//' | tr -d ' ')"
                if [ "$?" -ne 0 ]
                    then
                        #
                        # set the command/pipeline error line number
                        error_line_pipeline="$((${LINENO}-7))"
                        #
                        #
                        fnWriteLog ${LINENO} level_0 ""
                        fnWriteLog ${LINENO} level_0 "value of variable 'aws_region':"
                        fnWriteLog ${LINENO} level_0 "$aws_region"
                        fnWriteLog ${LINENO} level_0 ""
                        #                                                                                                    
                        # call the command / pipeline error function
                        fnErrorPipeline
                        #
                #
                fi # command / pipeline error check        
                #
        fi # end set region from -p profile parameter file  
fi # end test of no -p profile parameter 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of parameter 'aws_region': "$aws_region""
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
# ---- end: set the region
#
#
#
###################################################
#
#
# check command line parameters 
# check for valid -r region parameter 
#
if [[ "$aws_region" != 'all' ]]
    then
        fnWriteLog ${LINENO} "testing for valid -r region parameter "
        fnWriteLog ${LINENO} "command: aws ec2 describe-instances --profile "$cli_profile" --region "$aws_region" "
        feed_write_log="$(aws ec2 describe-instances --profile "$cli_profile" --region "$aws_region" 2>&1)"
                    #
                    # check for errors from the AWS API  
                    if [ "$?" -ne 0 ]
                        then
                            clear 
                            # AWS Error while testing the -r region parameter
                            fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
                            fnWriteLog ${LINENO} level_0 ""
                            fnWriteLog ${LINENO} level_0 "AWS error message: "
                            fnWriteLog ${LINENO} level_0 "$feed_write_log"
                            fnWriteLog ${LINENO} level_0 ""
                            fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
                            count_aws_region_check="$(echo "$feed_write_log" | grep 'Could not connect to the endpoint' | wc -l)"
                            if [[ "$count_aws_region_check" > 0 ]]
                                then 
                                    fnWriteLog ${LINENO} level_0 ""
                                    fnWriteLog ${LINENO} level_0 " AWS Error while testing your -r aws_region parameter entry: "$aws_region" "
                                    fnWriteLog ${LINENO} level_0 ""
                                    fnWriteLog ${LINENO} level_0 " Please correct your entry for the -r parameter "
                                    fnWriteLog ${LINENO} level_0 ""
                                    fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
                            fi
                            #
                            # set the awserror line number
                            error_line_aws="$((${LINENO}-25))"
                            #
                            # call the AWS error handler
                            fnErrorAws
                            #
                    fi # end test -r region aws error
                    #
        # disabled for speed, enable for debugging                    
        # fnWriteLog ${LINENO} "$feed_write_log"
fi  # end test for valid region if not all
#
#
###############################################################################
# 
#
# Initialize the write_file_service_names file
#
#
#
#
###########################################################################################################################
#
#
# Begin checks and setup 
#
#
#
###################################################
#
#
# create the stripped driver file 
# pull the count of AWS services to snapshot
#
#
# create the clean driver file
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "creating clean driver file: "$this_utility_acronym"-aws-services-snapshot-driver-stripped.txt "
feed_write_log="$(cat "$file_driver" | grep "^[^#]" | sed 's/\r$//' | grep . | grep -v ^$ | grep -v '^ $' > "$this_path_temp"/"$this_utility_acronym"-aws-services-snapshot-driver-stripped.txt 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
#
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "contents of file "$this_utility_acronym"-aws-services-snapshot-driver-stripped.txt: "
feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-aws-services-snapshot-driver-stripped.txt 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "loading variable 'count_driver_services' "
count_driver_services="$(cat "$this_path_temp"/"$this_utility_acronym"-aws-services-snapshot-driver-stripped.txt | grep "^[^#]" | wc -l)"
if [[ "$count_driver_services" -le 0 ]] ;
    then 
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 " Error reading the file: "$file_driver" "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 " Please confirm that the file has at least one AWS service enabled for snapshot  "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 " The log will also show the AWS error message and other diagnostic information "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 " The log is located here: "
        fnWriteLog ${LINENO} level_0 " "$this_log_file_full_path""
        fnWriteLog ${LINENO} level_0 ""        
        fnWriteLog ${LINENO} level_0 " Exiting the script"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        # delete the work files
        # fnDeleteWorkFiles
        # append the temp log onto the log file
        fnWriteLogTempFile
        # write the log variable to the log file
        fnWriteLogFile
        exit 1
fi 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'count_driver_services': "$count_driver_services" "
fnWriteLog ${LINENO} ""
#
###################################################
#
#
# create the stripped global driver file 
# pull the count of AWS global services to snapshot
#
#
# create the clean global driver file
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "creating clean driver file: "$this_utility_acronym"'-aws-services-snapshot-driver-global-stripped.txt' "
feed_write_log="$(cat "$this_path"/"$file_driver_global" | grep "^[^#]" | sed 's/\r$//' | grep . | grep -v ^$ | grep -v '^ $' > "$this_path_temp"/"$this_utility_acronym"-aws-services-snapshot-driver-global-stripped.txt 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
#
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "contents of file "$this_utility_acronym"'-aws-services-snapshot-driver-global-stripped.txt': "
feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-aws-services-snapshot-driver-global-stripped.txt 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "loading variable 'driver_global_services' "
driver_global_services="$(cat "$this_path_temp"/"$this_utility_acronym"-aws-services-snapshot-driver-global-stripped.txt | grep "^[^#]" )"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        #
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "value of variable 'driver_global_services':"
        fnWriteLog ${LINENO} level_0 "$driver_global_services"
        fnWriteLog ${LINENO} level_0 ""
        #
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "contents of file "$this_path_temp"/"$this_utility_acronym"-aws-services-snapshot-driver-global-stripped.txt :"
        feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-aws-services-snapshot-driver-global-stripped.txt)"
        fnWriteLog ${LINENO} level_0 "$feed_write_log"
        fnWriteLog ${LINENO} level_0 ""
        #                                                                                                            
        # call the command / pipeline error function
        fnErrorPipeline
        #
        #
fi
#
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'driver_global_services': "$driver_global_services" "
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "loading variable 'count_driver_global_services' "
count_driver_global_services="$(cat "$this_path_temp"/"$this_utility_acronym"-aws-services-snapshot-driver-global-stripped.txt | grep "^[^#]" | wc -l)"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        #
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "value of variable 'count_driver_global_services':"
        fnWriteLog ${LINENO} level_0 "$count_driver_global_services"
        fnWriteLog ${LINENO} level_0 ""
        #
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "contents of file "$this_path_temp"/"$this_utility_acronym"-aws-services-snapshot-driver-global-stripped.txt :"
        feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-aws-services-snapshot-driver-global-stripped.txt)"
        fnWriteLog ${LINENO} level_0 "$feed_write_log"
        fnWriteLog ${LINENO} level_0 ""
        #                                                                                                            
        # call the command / pipeline error function
        fnErrorPipeline
        #
        #
fi
#
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'count_driver_global_services': "$count_driver_global_services" "
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# if all regions, then pull the AWS regions available for this account
#
if [[ "$aws_region" = 'all' ]]
    then
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} level_0 "Pulling the list of available regions from AWS"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "This task can take a while. Please wait..."
        fnWriteLog ${LINENO} "pulling a list of current AWS regions and loading variable 'aws_region_list' "
        fnWriteLog ${LINENO} "command: aws ec2 describe-regions --output text --profile "$cli_profile" "
        aws_region_list="$(aws ec2 describe-regions --output text --profile "$cli_profile" | cut -f3 | sort 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "value of variable 'aws_region_list':"
                fnWriteLog ${LINENO} level_0 "$aws_region_list"
                fnWriteLog ${LINENO} level_0 ""
                #                                                    
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        # append the global region
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "appending 'global' to variable 'aws_region_list':  "
        aws_region_list+=$'\n'"global"
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'aws_region_list':  "
        feed_write_log="$(echo "$aws_region_list" 2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "counting the list of current AWS regions"
        count_aws_region_list="$(echo "$aws_region_list" | wc -l )"
        # add 1 for the merge operation for all regions  
        count_aws_region_list=$((count_aws_region_list+1))
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'count_aws_region_list': "$count_aws_region_list" "
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "initializing the region counter"
        counter_aws_region_list=0
        #
    else 
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "in a single region run "
        fnWriteLog ${LINENO} "setting the variable 'count_aws_region_list' to 2 ( 1 the for region, 1 for merge-all task ) "
        count_aws_region_list=2
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'count_aws_region_list': "$count_aws_region_list" "
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "initializing the region counter"
        counter_aws_region_list=0
        #
fi  # end test of 'all' regions -r parameter
#
#
###################################################
#
#
# clear the console
#
clear
# 
######################################################################################################################################################################
#
#
# Opening menu
#
#
######################################################################################################################################################################
#
#
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_menu"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " Snapshot AWS Services status to JSON files   "  
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_menu_bar"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "AWS account:............"$aws_account"  "$aws_account_alias" "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "AWS region:............"$aws_region" "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "Driver file name: "$file_driver" "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "Count of AWS Services to snapshot: "$count_driver_services" "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_menu_bar"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "The AWS Services will be snapshotted and the current status will be written to JSON files"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " ###############################################"
fnWriteLog ${LINENO} level_0 " >> Note: There is no undo for this operation << "
fnWriteLog ${LINENO} level_0 " ###############################################"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " By running this utility script you are taking full responsibility for any and all outcomes"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "AWS Service Snapshot utility"
fnWriteLog ${LINENO} level_0 "Run Utility Y/N Menu"
#
# Present a menu to allow the user to exit the utility and do the preliminary steps
#
# Menu code source: https://stackoverflow.com/questions/30182086/how-to-use-goto-statement-in-shell-script
#
# Define the choices to present to the user, which will be
# presented line by line, prefixed by a sequential number
# (E.g., '1) copy', ...)
choices=( 'Run' 'Exit' )
#
# Present the choices.
# The user chooses by entering the *number* before the desired choice.
select choice in "${choices[@]}"; do
#   
    # If an invalid number was chosen, "$choice" will be empty.
    # Report an error and prompt again.
    [[ -n "$choice" ]] || { fnWriteLog ${LINENO} level_0 "Invalid choice." >&2; continue; }
    #
    # Examine the choice.
    # Note that it is the choice string itself, not its number
    # that is reported in "$choice".
    case "$choice" in
        Run)
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "Running AWS Service Snapshot utility"
                fnWriteLog ${LINENO} level_0 ""
                # Set flag here, or call function, ...
            ;;
        Exit)
        #
        #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "Exiting the utility..."
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 ""
                # delete the work files
                fnDeleteWorkFiles
                # append the temp log onto the log file
                fnWriteLogTempFile
                # write the log variable to the log file
                fnWriteLogFile
                exit 1
    esac
    #
    # Getting here means that a valid choice was made,
    # so break out of the select statement and continue below,
    # if desired.
    # Note that without an explicit break (or exit) statement, 
    # bash will continue to prompt.
    break
    #
    # end select - menu 
    # echo "at done"
done
#
##########################################################################
#
#      *********************  begin script *********************
#
##########################################################################
#
##########################################################################
#
#
# ---- begin: write the start timestamp to the log 
#
fnHeader
#
date_now="$(date +"%Y-%m-%d-%H%M%S")"
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "run start timestamp: "$date_now" " 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
#
# ---- end: write the start timestamp to the log 
#
#
##########################################################################
#
#
# clear the console for the run 
#
fnHeader
#
##########################################################################
#
#
# ---- begin: display the log location 
#
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "Run log: "$this_log_file_full_path" " 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
#
#
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
#
# ---- end: display the log location 
#
#
##########################################################################
#
#
# pull the services  
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------------- begin: pull services for each region ----------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnHeader
#
fnWriteLog ${LINENO} "reset the task counter variable 'counter_driver_services' "
counter_driver_services=0
#
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'count_driver_services': " 
feed_write_log="$(echo "$count_driver_services" 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
# if not all regions, then set the list to the region -r parameter and append 'global'
if [[ "$aws_region" != 'all' ]]
    then 
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "not an all regions run so set variable 'aws_region_list' to -r parameter and append 'global': " 
        aws_region_list+="$aws_region"$'\n'"global"        
fi # end check for not all regions
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'aws_region_list': " 
feed_write_log="$(echo "$aws_region_list" 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "initializing the global services run file: "$this_utility_acronym"-global-services-names.txt"
feed_write_log="$(echo "" > "$this_path_temp"/"$this_utility_acronym"-global-services-names.txt 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
# 
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "entering the 'read aws_region_list' loop"
while read -r aws_region_list_line 
do
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------- loop head: read aws_region_list -----------------------  "
    fnWriteLog ${LINENO} ""
    #
    # display the header    
    fnHeader
    #
    # display the task progress bar
    fnProgressBarTaskDisplay "$counter_aws_region_list" "$count_aws_region_list"
    #
    #
    ##########################################################################
    #
    #
    #  begin create the write directory 
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "loading the region dependent variables  "
    fnWriteLog ${LINENO} "value of variable 'aws_region_list_line': "$aws_region_list_line" "
    #
    if [[ "$aws_region_list_line" = 'global' ]] 
        then 
            # check for global region with empty global services 
            # 'global' is appended to the region file for every run
            # if there are no global services in the driver file, then this section will skip processing the empty file  
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "loading the variable: 'count_global_services_names_file'  "   
            count_global_services_names_file="$(cat "$this_path_temp"/sps-global-services-names.txt | grep -v '^$' | wc -l  2>&1)"
            #
            # this error check was catching a pipeline error although manual tests of the command line were OK 
            # 
            # check for command / pipeline error(s)
            # if [ "$?" -ne 0 ]
            #     then
            #         #
            #         # set the command/pipeline error line number
            #         error_line_pipeline="$((${LINENO}-7))"
            #         #
            #         #
            #         fnWriteLog ${LINENO} level_0 ""
            #         fnWriteLog ${LINENO} level_0 "value of variable 'count_global_services_names_file':"
            #         fnWriteLog ${LINENO} level_0 "$count_global_services_names_file"
            #         fnWriteLog ${LINENO} level_0 ""
            #         #
            #         fnWriteLog ${LINENO} level_0 ""
            #         fnWriteLog ${LINENO} level_0 "contents of file "$this_path_temp"/sps-global-services-names.txt :"
            #         feed_write_log="$(cat "$this_path_temp"/sps-global-services-names.txt)"
            #         fnWriteLog ${LINENO} level_0 "$feed_write_log"
            #         fnWriteLog ${LINENO} level_0 ""
            #         #                                                                                                            
            #         # call the command / pipeline error function
            #         fnErrorPipeline
            #         #
            #         #
            # fi
            #
            #
            fnWriteLog ${LINENO} "value of variable 'count_global_services_names_file': "$count_global_services_names_file" "
            fnWriteLog ${LINENO} ""
            #
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "checking for empty file: "$this_path_temp"/sps-global-services-names.txt  "   
            if [[ "$count_global_services_names_file" = 0 ]] 
                then 
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "there are no global services to process  "
                    fnWriteLog ${LINENO} "skipping to next task via the 'break' command  "   
                    #
                    break 
                    #
            fi  # end check for no global services to process 
            #
    fi  # end check for global region and empty global region names file 
    #
    # check for 'all' regions
    if [[ "$aws_region" != 'all' ]]
        then
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "this is a non-all-regions run  "
            fnWriteLog ${LINENO} "testing for global region in variable 'aws_region_list_line'  "
            if [[ "$aws_region_list_line" != 'global' ]] 
                then 
                    # if the region is not 'global' then set the path to the region list line  
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "region is not global so setting region from variable 'aws_region_list_line': "$aws_region_list_line"  "
                    write_path="$this_path"/aws-"$aws_account"-"$aws_region_list_line"-"$this_utility_filename_plug"-"$date_file"
                    write_path_snapshots="$write_path"/"$this_utility_filename_plug"-files
                    this_file_account_region_services_all="$write_path_snapshots"/"aws-""$aws_account"-"$aws_region_list_line"-"$this_utility_filename_plug"-"$date_file"-all-services.json 
                else 
                    # if the region is 'global' then use the aws_region value for the path to keep the global services snapshots in the same folder as the rest of the results 
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "region is global so setting region from variable 'aws_region': "$aws_region"  "
                    write_path="$this_path"/aws-"$aws_account"-"$aws_region"-"$this_utility_filename_plug"-"$date_file"
                    write_path_snapshots="$write_path"/"$this_utility_filename_plug"-files
                    # use the aws_region_list_line value here so that the file name is correct: global
                    this_file_account_region_services_all_global="$write_path_snapshots"/"aws-""$aws_account"-"$aws_region_list_line"-"$this_utility_filename_plug"-"$date_file"-all-services.json 
            fi  # end check for global region in a non-all-regions run                    
            #
        else 
           fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "this is an all-regions run  "
            fnWriteLog ${LINENO} "testing for global region in variable 'aws_region_list_line'  "
            if [[ "$aws_region_list_line" != 'global' ]] 
                then 
                    # if an all-regions run then set the paths to 'all-regions' to group all of the results in one folder
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "all-regions run so setting path to 'all-regions'  "
                    write_path="$this_path"/aws-"$aws_account"-all-regions-"$this_utility_filename_plug"-"$date_file"
                    write_path_snapshots="$write_path"/"$this_utility_filename_plug"-files
                    # if the region is not 'global' then set the path for the all-services non-global file   
                    this_file_account_region_services_all="$write_path_snapshots"/"aws-""$aws_account"-"$aws_region_list_line"-"$this_utility_filename_plug"-"$date_file"-all-services.json 
                else 
                    # if an all-regions run then set the paths to 'all-regions' to group all of the results in one folder
                    fnWriteLog ${LINENO} ""
                    fnWriteLog ${LINENO} "all-regions run so setting path to 'all-regions'  "
                    write_path="$this_path"/aws-"$aws_account"-all-regions-"$this_utility_filename_plug"-"$date_file"
                    write_path_snapshots="$write_path"/"$this_utility_filename_plug"-files
                    # if the region is 'global' then set the path for the all-services global file   
                    this_file_account_region_services_all_global="$write_path_snapshots"/"aws-""$aws_account"-"$aws_region_list_line"-"$this_utility_filename_plug"-"$date_file"-all-services.json 
            fi  # end test for global region in an all-regions run 
    fi  # end test for all regions       
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'aws_region': "$aws_region" "    
    fnWriteLog ${LINENO} "value of variable 'aws_region_list_line': "$aws_region_list_line" "
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "values of the region dependent variables:  "   
    fnWriteLog ${LINENO} "value of variable 'write_path': "$write_path" "
    fnWriteLog ${LINENO} "value of variable 'write_path_snapshots': "$write_path_snapshots" "
    fnWriteLog ${LINENO} "value of variable 'this_file_account_region_services_all': "$this_file_account_region_services_all" "
    fnWriteLog ${LINENO} "value of variable 'this_file_account_region_services_all_global': "$this_file_account_region_services_all_global" "
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "creating the directory for the job files "
    fnWriteLog ${LINENO} "job files located in: "$write_path" "  
    fnWriteLog ${LINENO} ""
    # if the write directory does not exist, then create it
    if [[ ! -d "$write_path" ]] ;
        then 
            feed_write_log="$(mkdir "$write_path" 2>&1)"
            #
            # check for command error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                    fnWriteLog ${LINENO} level_0 ""
                    #                                                                                                
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            fi
            #
    fi
    #
    fnWriteLog ${LINENO} ""
    #
    fnWriteLog ${LINENO} "creating the directory for the snapshot output files "
    fnWriteLog ${LINENO} "snapshot files located in: "$write_path" "  
    fnWriteLog ${LINENO} ""
    if [[ ! -d "$write_path_snapshots" ]] ;
        then 
            feed_write_log="$(mkdir "$write_path_snapshots" 2>&1)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "value of variable 'feed_write_log':"
                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                    fnWriteLog ${LINENO} level_0 ""
                    #
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi  # end check for error        
            #
    fi # end check for existing path 
    #
    fnWriteLog ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    #     end: create the write directory 
    #
    #
    ##########################################################################
    #
    #
    #  begin pull the snapshots for the region 
    #
    # 
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "calling function: fnAwsPullSnapshots for region: "$aws_region_list_line" "
    fnWriteLog ${LINENO} ""
    #
    fnAwsPullSnapshots "$aws_region_list_line"
    #
    fnWriteLog ${LINENO} ""
    #
    # remove any duplicates from the list of snapshotted services
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "calling function: fnDuplicateRemoveSnapshottedServices for region: "$aws_region_list_line" "
    fnWriteLog ${LINENO} ""
    #
    fnDuplicateRemoveSnapshottedServices "$aws_region_list_line"
    #
    #
    # set the file find variable for the merge file run 
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "loading variable 'find_name' "
    find_name="$(echo "aws-"$aws_account"-"$aws_region_list_line""-snapshot-""$date_file"-*" 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #   
                #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "value of variable 'find_name':"
                fnWriteLog ${LINENO} level_0 "$find_name"
                fnWriteLog ${LINENO} level_0 ""
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'find_name': "
    fnWriteLog ${LINENO} "$find_name"
    fnWriteLog ${LINENO} ""
    #
    # create the merged all services JSON file for the region
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "calling function: fnCreateMergedServicesJsonFile for region: "$aws_region_list_line" "
    fnWriteLog ${LINENO} ""
    #
    fnCreateMergedServicesJsonFile "$aws_region_list_line" "$find_name"
    #
    #
    fnWriteLog ${LINENO} "increment the region counter" 
    fnCounterIncrementRegions
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------- loop tail: read aws_region_list -----------------------  "
    fnWriteLog ${LINENO} ""
done< <(echo "$aws_region_list")
#
#
# display the header    
fnHeader
#
# display the task progress bar
fnProgressBarTaskDisplay "$counter_aws_region_list" "$count_aws_region_list"
#
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------- done with read aws_region_list -----------------------  "
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} ""  
#
#
#
# write out the temp log and empty the log variable
fnWriteLogTempFile
#
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------- end: pull services for each region -----------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
#
##########################################################################
#
#
# merge the region 'all services' json files into a master 'all services' file 
#
if [[ "$aws_region" = 'all' ]] 
    then 
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "---------------------- begin: create account 'all regions - all services' JSON file ----------------------"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} ""
        #
        # display the header    
        fnHeader
        #
        #
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "Merging 'all services' files for account: "$aws_account" "
        fnWriteLog ${LINENO} level_0 ""                                                                                              
        #
        # set the file find variable for the merge file run 
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "loading variable 'find_name' "
        find_name="$(echo "aws-"$aws_account"-*-snapshot-""$date_file""-all-services.json" 2>&1)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #   
                    #
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "value of variable 'find_name':"
                    fnWriteLog ${LINENO} level_0 "$find_name"
                    fnWriteLog ${LINENO} level_0 ""
                    #
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'find_name': "
        fnWriteLog ${LINENO} "$find_name"
        fnWriteLog ${LINENO} ""
        #
        # create the merged all services JSON file for the region
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "calling function: fnCreateMergedServicesJsonFile for account: "$aws_account" "
        fnWriteLog ${LINENO} ""
        #
        fnCreateMergedServicesAllJsonFile 'all' "$find_name"
        #
        #
fi  # end check for all regions
#
#
# write out the temp log and empty the log variable
fnWriteLogTempFile
#
#
fnWriteLog ${LINENO} "increment the region counter" 
fnCounterIncrementRegions
#
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------- end: create account 'all regions - all services' JSON file -----------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
#
#
##########################################################################
#
#
# create the summary report 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------- begin: print summary report for each LC name --------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
# display the header    
fnHeader
#
# load the report variables
#
# initialize the counters
#
#
fnWriteLog ${LINENO} ""
fnHeader
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "Creating job summary report file "
fnWriteLog ${LINENO} level_0 ""
# initialize the report file and append the report lines to the file
echo "">"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  AWS Services Snapshot Summary Report">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  Script Version: "$script_version"">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  Date: "$date_file"">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  AWS Account: "$aws_account"  "$aws_account_alias"">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  AWS region: "$aws_region"">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  Driver file name: "$file_driver" ">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  Number of regions snapshotted: "$count_aws_region_list" ">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  Number of services snapshotted: "$counter_snapshots" ">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  AWS Services Snapshot JSON files location: ">>"$this_summary_report_full_path"
echo "  "$write_path_snapshots"/ ">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
if [[ ("$logging" = "y") || ("$logging" = "z") ]] ;
    then
        echo "  AWS Services Snapshot job log file: ">>"$this_summary_report_full_path"
        echo "  "$write_path"/ ">>"$this_summary_report_full_path"
        echo "  "$this_log_file" ">>"$this_summary_report_full_path"
        echo "">>"$this_summary_report_full_path"
        echo "">>"$this_summary_report_full_path"
fi
echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
count_error_lines="$(cat "$this_log_file_errors_full_path" | wc -l)"
if (( "$count_error_lines" > 2 ))
    then
        echo "">>"$this_summary_report_full_path"
        echo "">>"$this_summary_report_full_path"
        # add the errors to the report
        feed_write_log="$(cat "$this_log_file_errors_full_path">>"$this_summary_report_full_path" 2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        echo "">>"$this_summary_report_full_path"
        echo "">>"$this_summary_report_full_path"
        echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
fi
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
#
# write the names of the snapshotted services to the report
fnWriteLog ${LINENO} "writing contents of variable: 'aws_region_list' to the report " 
echo "  Snapshots created for regions:">>"$this_summary_report_full_path"
echo "  -----------------------------------------------------------------------">>"$this_summary_report_full_path"
#
# add leading 5 characters to match report margin
echo "$aws_region_list" | sed -e 's/^/     /'>>"$this_summary_report_full_path"
#
#
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  -----------------------------------------------------------------------">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
#
# write the names of the snapshotted services to the report
fnWriteLog ${LINENO} "writing contents of file: "${!write_file_service_names}" to the report " 
echo "  Snapshots created for services:">>"$this_summary_report_full_path"
echo "  -----------------------------------------------------------------------">>"$this_summary_report_full_path"
#
# add leading 5 characters to match report margin
cat "$write_file_service_names" | sed -e 's/^/     /'>>"$this_summary_report_full_path"
#
#
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
#
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "Summary report complete. "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "Report is located here: "
fnWriteLog ${LINENO} level_0 "$this_summary_report_full_path"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------- end: print summary report for each LC name ---------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# delete the work files 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------------------- begin: delete work files ----------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
# display the header    
fnHeader
#
fnDeleteWorkFiles
#
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------- end: delete work files -----------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# done 
#
fnHeader
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "                            Job Complete "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " Summary report location: "
fnWriteLog ${LINENO} level_0 " "$write_path"/ "
fnWriteLog ${LINENO} level_0 " "$this_summary_report" "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " Snapshots location: "
fnWriteLog ${LINENO} level_0 " "$write_path_snapshots"/"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
if [[ ("$logging" = "y") || ("$logging" = "z") ]] ;
    then
        fnWriteLog ${LINENO} level_0 " Log location: "
        fnWriteLog ${LINENO} level_0 " "$write_path"/ "
        fnWriteLog ${LINENO} level_0 " "$this_log_file" "
        fnWriteLog ${LINENO} level_0 ""
fi 
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "----------------------------------------------------------------------"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
if (( "$count_error_lines" > 2 ))
    then
    fnWriteLog ${LINENO} level_0 ""
    feed_write_log="$(cat "$this_log_file_errors_full_path" 2>&1)" 
    fnWriteLog ${LINENO} level_0 "$feed_write_log"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "----------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
fi
#
##########################################################################
#
#
# write the stop timestamp to the log 
#
#
date_now="$(date +"%Y-%m-%d-%H%M%S")"
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "run end timestamp: "$date_now" " 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "" 
#
##########################################################################
#
#
# write the log file 
#
if [[ ("$logging" = "y") || ("$logging" = "z") ]] 
    then 
        # append the temp log onto the log file
        fnWriteLogTempFile
        # write the log variable to the log file
        fnWriteLogFile
    else 
        # delete the temp log file
        rm -f "$this_log_temp_file_full_path"        
fi
#
# exit with success 
exit 0
#
#
# ------------------ end script ----------------------


