#! /bin/bash
#
#
##########################################
# 
# begin bash shell script 
#
##########################################
#
###############################################################################
#  
# >>>> begin documentation <<<< 
#
###############################################################################
#
#
##########################################################################################################
#
# Structure: 
# A) documentation (this section)
# B) initialize (initializes variables and tables)
# C) functionDefinition (defines functions)
# D) setup (loads files, tables, and variables )
# E) main (creates program output) 
#
# For quick access, search for 'begin' or 'end' and the section name 
# Example: 'begin setup'  
#
##########################################################################################################
#
# ------------------------------------------------------------------------------------
#
# MIT License
# 
# Copyright (c) 2018 Enterprise Group, Ltd.
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
# Source: https://github.com/Enterprise-Group-Ltd/aws-services-snapshot
#
script_version=2.1.36  
#
#  Dependencies:
#  - postgresql instance running on EC2 (setup steps here: https://github.com/Enterprise-Group-Ltd/aws-services-snapshot/blob/master/docs/postgresql-install.md )
#  - Microsoft Excel file: driver_aws_cli_commands-X-X-X.xlsx (this file is used to create the contents of the 
#    postgresql tables '_driver_aws_cli_commands' and '_driver_aws_cli_commands_recursive' )  
#  - bash shell
#  - jq - JSON wrangler https://stedolan.github.io/jq/
#  - AWS CLI tools (pre-installed on AWS AMIs) 
#  - AWS CLI profile with IAM permissions for the AWS CLI command:
#    - aws ec2 describe-instances (used to test for valid -r region )
#    - aws sts get-caller-identity (used to pull account number )
#    - aws iam list-account-aliases (used to pull account alias )
#  - AWS CLI profile with IAM permissions for the AWS CLI 'service describe', 'service get', and 
#    'service list' commands included in the postgresql tables '_driver_aws_cli_commands' and '_driver_aws_cli_commands_recursive'
#
#
#  Sample IAM policy JSON for "sts:GetCallerIdentity"
#
#       {
#       "Version": "2012-10-17",
#       "Statement": 
#           {
#           "Effect": "Allow",
#           "Action": "sts:GetCallerIdentity",
#           "Resource": "*"
#           }
#       }
#
#
# Sample IAM policy JSON for "iam:ListAccountAliases"
#
#       {
#       "Version": "2012-10-17",
#       "Statement": 
#           {
#           "Effect": "Allow",
#           "Action": "iam:ListAccountAliases",
#           "Resource": "*"
#           }
#       }
#
#
# Tested on: 
#   Windows Subsystem for Linux (WSL) 
#     Windows 10 Enterprise: 1709
#     Build: 16299.248
#     OS: Ubuntu 16.04 xenial
#     Kernel: x86_64 Linux 4.4.0-43-Microsoft
#     Shell: bash 4.3.48
#     jq 1.5-1-a5b5cbe
#     aws-cli/1.14.36 Python/2.7.12 Linux/4.4.0-43-Microsoft botocore/1.8.40
#   
#   AWS EC2
#     OS: Amazon Linux
#     AMI: amzn-ami-hvm-2017.09.1.20180115-x86_64-gp2 (ami-97785bed)
#     Kernel: x86_64 Linux 4.9.77-31.58.amzn1.x86_64
#     Shell: bash 4.2.46
#     jq: 1.5
#     aws-cli/1.14.32 Python/2.7.13 Linux/4.9.77-31.58.amzn1.x86_64 botocore/1.8.36
#
#
# By: Douglas Hackney
#     https://github.com/dhackney   
# 
# Type: AWS utility
# Description: 
#   This shell script snapshots the current state of AWS resources and writes it to JSON files and PostgreSQL tables
#
#
# Roadmap:
# - DB error check if table exists and is populated
# - recursive error check for existing and populated source JSON & table
# - multi-recursive
# - single_dependent-recursive
# - hardcoded parameter value
# - summary report: add list of commands with no response values 
# - auto-support --account-id qualifier
# - service attribute "$" to tag services with fixed/regular costs, e.g. load balancers  
# 
#
##########################################################################################################
#
# Overview: 
# This utility executes a series of shell, AWS CLI, jq, and psql commands that create local JSON files and 
# postgresql JSON tables populated with snapshots of AWS services.
# 
# The process to execute the utility is: 
# 1) create an EC2 instance (setup steps here: https://github.com/Enterprise-Group-Ltd/aws-services-snapshot/blob/master/docs/postgresql-install.md )
# 2) install postgresql 9.6 (setup steps here: https://github.com/Enterprise-Group-Ltd/aws-services-snapshot/blob/master/docs/postgresql-install.md )
# 3) edit or populate the Microsoft Excel file: 'driver_aws_cli_commands-X-X-X.xlsx' to set which services and AWS CLI commands are snapshotted
# 4) copy the contents of the Excel workbook 'driver-aws-services-X-X-X.xlsx' tab 'aws_services' into the empty postgresql table 'aws_snapshot.aws_sps__commands._driver_aws_services' and commit the transactions
# 5) copy the contents of the Excel workbook 'driver_aws_cli_commands-X-X-X.xlsx' tab 'aws_cli_commands' into the empty postgresql table 'aws_snapshot.aws_sps__commands._driver_aws_cli_commands' and commit the transactions
# 6) copy the contents of the Excel workbook 'driver_aws_cli_commands-X-X-X.xlsx' tab 'aws_cli_commands_recursive' into the empty postgresql table 'aws_snapshot.aws_sps__commands._driver_aws_cli_commands_recursive' and commit the transactions    
# 7) create AWS CLI profiles with required AWS IAM permissions for each AWS account that you want to snapshot
# 8) copy this script to the AWS EC2 instance running the PostgreSQL database
# 9) execute this script: bash ./aws-services-snapshot.sh -p AWS_CLI_profile -r AWS_region
# 10) download the summary report and JSON files from the EC2 instance if desired 
# 11) use the PostgreSQL database tables as a snapshot resource as desired 
#
# Detailed instructions are here: https://github.com/Enterprise-Group-Ltd/aws-services-snapshot/blob/master/docs/postgresql-install.md
#
#
##########################################################################################################
#
# Definitions: 
# * Snapshot types
#   - non-recursive: stand-alone AWS CLI list, describe, or get command that requires no parameter values from prior snapshot results
#   - recursive-single: AWS CLI list, describe, or get command that requires a single parameter's values from prior non-recursive snapshot results
#   - recursive-multi: AWS CLI list, describe, or get command that requires multiple parameters' values from multiple prior non-recursive snapshot results
#   - recursive-single-dependent: AWS CLI list, describe, or get command that requires a single parameter's values from prior recursive snapshot results
#   - recursive-multi-dependent: AWS CLI list, describe, or get command that requires multiple parameters' values from multiple prior recursive snapshot results
#   - recursive-hardcoded: AWS CLI list, describe, or get command that includes a parameter value that is hardcoded
#
#
###############################################################################
# 
#
# reference list of functions used in this script
#
# fnAwsCommandUnderscore()
# fnAwsPullSnapshots()
# fnAwsPullSnapshotsLoop()
# fnAwsPullSnapshotsNonRecursive()
# fnAwsPullSnapshotsRecursiveHardcoded()
# fnAwsPullSnapshotsRecursiveLoop()
# fnAwsPullSnapshotsRecursiveLoopTail()
# fnAwsPullSnapshotsRecursiveSingle()
# fnAwsPullSnapshotsRecursiveSingleDependent()
# fnAwsServiceTestValid()
# fnCommandCount()
# fnCommandListBuild()
# fnCommandNonRecursiveListBuild()
# fnCommandRecursiveSingleDependentListBuild()
# fnCommandRecursiveSingleListBuild()
# fnCountDriverServices()
# fnCounterIncrementAwsSnapshotCommands()
# fnCounterIncrementRegions()
# fnCounterIncrementSnapshots()
# fnCounterIncrementTask()
# fnCountGlobalServicesNames()
# fnCreateMergedServicesAllJsonFile()
# fnCreateMergedServicesJsonFile()
# fnDbLoadSnapshotFile()
# fnDbQueryCommandNonRecursiveList()
# fnDbQueryCommandRecursiveSingleDependentList()
# fnDbQueryCommandRecursiveSingleList()
# fnDbQueryCommandRecursiveSourceTables()
# fnDbQueryNonRecursiveCommandTest()
# fnDbQueryRecursiveCommandTest()
# fnDbQueryReservedWords()
# fnDbQueryServiceGlobalList()
# fnDbQueryServiceList()
# fnDbQueryTestTableExists()
# fnDbQueryTestTablePopulate()
# fnDbReservedWordsTest()
# fnDbSchemaCreate()
# fnDbSchemaDrop()
# fnDbTableCreate()
# fnDeleteWorkFiles()
# fnDisplayHeader()
# fnDisplayProgressBar()
# fnDisplayProgressBarTask()
# fnDisplayProgressBarTaskSub()
# fnDisplayProgressBarTaskSubUpdate()
# fnDisplayProgressBarTaskUpdate()
# fnDisplayTaskSubText()
# fnDuplicateRemoveSnapshottedServices()
# fnEcho()
# fnErrorAws()
# fnErrorJq()
# fnErrorLog()
# fnErrorPipeline()
# fnErrorPsql()
# fnFileAppendLog()
# fnFileAppendLogTemp()
# fnFileSnapshotUnneededDelete()
# fnInitializeWriteFileBuild()
# fnInitializeWriteFileBuildPattern()
# fnLoadServiceSnapshotVariables()
# fnLoadSnapshotNameVariable()
# fnMergeArraysServicesJsonFile()
# fnMergeArraysServicesRecursiveJsonFile()
# fnOutputConsole()
# fnOutputLog()
# fnPatternLoad()
# fnStrippedDriverFileCreate()
# fnUsage()
# fnVariableLoadCommandFileSource()
# fnVariableNamesCommandDisplay()
# fnVariableNamesCommandLoad()
# fnVariableNamesCommandRecursiveLoad()
# fnVariablePriorLoad()
# fnVariablePriorRestore()
# fnVariablePriorSet()
# fnWriteCommandFileRecursive()
# fnWriteDirectoryCreate()
# fnWriteFileVariablesSet()
###############################################################################
#  
# >>>> end documentation <<<< 
#
###############################################################################
# 
###############################################################################
#  
# >>>> begin initialize <<<< 
#
###############################################################################
#
# set the environmental variables 
#
# set to catch errors in a pipeling
set -o pipefail 
#
# set to suppress NOTICE console output from psql
PGOPTIONS='--client-min-messages=warning'
export PGOPTIONS
#
###############################################################################
# 
#
# initialize the script variables
#
aws_account=""
aws_account_alias=""
aws_command=""
aws_command_line=""
aws_command_line_service=""
aws_command_parameter_01=""  
aws_command_parameter_02=""  
aws_command_parameter_03=""  
aws_command_parameter_04=""  
aws_command_parameter_05=""  
aws_command_parameter_06=""  
aws_command_parameter_07=""  
aws_command_parameter_08="" 
aws_command_parameter_01_value=""
aws_command_parameter_02_value=""
aws_command_parameter_03_value=""
aws_command_parameter_04_value=""
aws_command_parameter_05_value=""
aws_command_parameter_06_value=""
aws_command_parameter_07_value=""
aws_command_parameter_08_value=""
aws_command_parameter_string=""
aws_command_parameter_string_build=""
aws_command_prior=""
aws_command_recursive=""
aws_command_underscore=""
aws_command_parameter_01_supplemental_01=""
aws_command_parameter_01_supplemental_01_value=""
aws_region=""
aws_region_backup=""
aws_region_fn_create_merged_services_json_file=""
aws_region_list=""
aws_region_list_line_parameter=""
aws_region_list_line_parameter_temp=""
aws_service=""
aws_service_underscore=""
parameter_01_source_key_colon=""
parameter_01_source_key_list=""
parameter_01_source_key_list_sort=""
aws_service_snapshot_name=""
aws_service_snapshot_name_table_underscore=""
aws_service_snapshot_name_table_underscore_backup=""
aws_service_snapshot_name_table_underscore_prior=""
aws_service_snapshot_name_table_underscore_load=""
aws_service_snapshot_name_table_underscore_load_backup=""
aws_service_snapshot_name_table_underscore_load_prior=""
aws_service_snapshot_name_table_underscore_load_long=""
aws_service_snapshot_name_underscore=""
aws_service_strip=""
aws_snapshot_commands_recursive_single_dedupe=""
aws_snapshot_name=""
break_global=""
choices=""
cli_profile=""
continue_global=""
count_aws_command_parameter_string=0
count_aws_snapshot_commands=0
count_aws_snapshot_commands_non_recursive=0
count_aws_snapshot_commands_recursive_single_dependent=0
count_aws_snapshot_commands_recursive_single=0
count_aws_snapshot_commands_recursive_multi=0
count_array_service_snapshot_recursive=0
count_aws_region_check=0
count_aws_region_list=0
count_aws_snapshot_commands=0
count_cli_profile=0
count_cli_profile_regions=0
count_db_snapshot_list_key=0
count_db_table_name=0
count_driver_services=0
count_error_aws_no_endpoint=0
count_error_lines=0
count_file_snapshot_driver_file_name_aws_cli_commands_all=0
count_file_snapshot_driver_file_name_aws_cli_commands_non_recursive_source=0
count_files_snapshots=0
count_files_snapshots_all=0
count_global_services_names=0
count_global_services_names_check=0
count_global_services_names_file=0
count_lines_service_snapshot_recursive=0
count_not_found_error=0
count_query_test_table_populate=0
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
counter_aws_snapshot_commands=0
counter_aws_region_set=0
counter_aws_snapshot_commands=0
counter_db_table_name=0
counter_driver_services=0
counter_files_snapshots=0
counter_files_snapshots_all=0
counter_snapshots=0
counter_this_file_tasks=0
count_this_file_tasks_end=0
count_this_file_tasks_increment=0
date_file="$(date +"%Y-%m-%d-%H%M%S")"
date_now="$(date +"%Y-%m-%d-%H%M%S")"
db_command=""
db_file_output=""
db_host=""
db_name=""
db_port=""
db_query_sql=""
db_schema=""
db_table_baseline_non_recursive_key_match=""
db_type=""
db_user=""
_empty=""
_empty_task=""
_empty_task_sub=""
error_line_aws=""
error_line_jq=""
error_line_pipeline=""
error_line_psql=""
execute_direct=""
feed_write_log=""
file_snapshot_driver_file_name=""
file_snapshot_driver_aws_cli_commands_all_file_name=""
file_snapshot_driver_aws_cli_commands_all_file_name_raw=""
file_snapshot_driver_aws_cli_commands_global_file_name=""
file_snapshot_driver_aws_cli_commands_global_file_name_raw=""
file_snapshot_driver_aws_cli_commands_non_global_file_name=""
file_snapshot_driver_aws_cli_commands_non_global_file_name_raw=""
file_snapshot_driver_aws_cli_commands_non_recursive_file_name=""
file_snapshot_driver_aws_cli_commands_non_recursive_file_name_raw=""
file_snapshot_driver_file_name_global=""
file_snapshot_driver_file_name_global_line=""
file_snapshot_driver_stripped_file_name=""
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
parameter_01_source_key="" 
parameter_02_source_key="" 
parameter_03_source_key="" 
parameter_04_source_key="" 
parameter_05_source_key="" 
parameter_06_source_key="" 
parameter_07_source_key="" 
parameter_08_source_key=""
parameter_01_source_table="" 
parameter_02_source_table="" 
parameter_03_source_table="" 
parameter_04_source_table="" 
parameter_05_source_table="" 
parameter_06_source_table="" 
parameter_07_source_table="" 
parameter_08_source_table="" 
pattern_load_feed=""
pattern_load_value=""
query_array_length=""
query_command_list=""
query_command_list_create=""
query_count_services="0"
query_extract_load_contents=""
query_list_recursive_single_dependent=""
query_list_recursive_single=""
query_load_snapshot_file=""
query_non_recursive_command_test=""
query_non_recursive_command_test_sql=""
query_recursive_command_test=""
query_recursive_command_test_sql=""
query_schema_drop=""
query_schema_create=""
query_service_list=""
query_service_list_create=""
query_service_global_list=""
query_service_global_list_create=""
query_table_create=""
query_test_table_populate=""
recursive_single_dependent_yn=""
recursive_multi_yn=""
recursive_single_yn=""
recursive_source=""
region_global_list_raw=""
service_snapshot=""
service_snapshot_build_01=""
service_snapshot_build_02=""
service_snapshot_build_03=""
service_snapshot_command=""
service_snapshot_recursive=""
service_snapshot_recursive_object_key=""
service_snapshot_recursive_service_key=""
services_driver_list=""
snapshot_source_recursive_command=""
snapshot_target_recursive_command=""
snapshot_type=""
string_replace=""
string_search=""
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
date_file_underscore="$(date +"%Y_%m_%d_%H%M%S")"
this_path="$(pwd)"
this_file="$(basename "$0")"
full_path="${this_path}"/"$this_file"
this_log_temp_file_full_path="$this_path"/"$this_utility_filename_plug"-log-temp.log 
this_user="$(whoami)"
count_this_file_tasks="$(cat "$full_path" | grep -c "\-\-\- begin\: " 2>&1)"
count_this_file_tasks_end="$(cat "$full_path" | grep -c "\-\-\- end\: " 2>&1)"
count_this_file_tasks_increment="$(cat "$full_path" | grep -c "# increment the task counter" 2>&1)"
count_this_file_tasks_increment=$((count_this_file_tasks_increment-3))
counter_this_file_tasks=0
logging="x"
counter_snapshots=0
db_host="localhost"
db_name="aws_snapshot"
db_port="5432"
db_type="postresql"
db_user="ec2-user"
#
###############################################################################
# 
# initialize the temp log file
#
echo "" > "$this_log_temp_file_full_path"
#
# 
###############################################################################
#  
# >>>> end initialize <<<< 
#
###############################################################################
#
# 
###############################################################################
#  
# >>>> begin functionDefinition <<<< 
#
###############################################################################
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
    echo " * Write the current state to JSON files and PostgreSQL tables "
    echo ""
    echo "----------------------------------------------------------------------------------------------------------------------"
    echo ""
    echo " Usage:"
    echo "         aws-services-snapshot.sh -p AWS_CLI_profile "
    echo ""
    echo "         Optional parameters: -r AWS_region -b y -g y -x y"
    echo ""
    echo " Where: "
    echo "  -p - Name of the AWS CLI cli_profile (i.e. what you would pass to the --profile parameter in an AWS CLI command)"
    echo "         Example: -p myAWSCLIprofile "
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
    echo "  -x - Execute with no operator prompt on / off. Default is off. Set to 'y' to automate, schedule, etc. "
    echo "         Example: -x y "
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
function fnDisplayProgressBar()
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
function fnDisplayProgressBarTaskUpdate()
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
    printf "\r           Region Progress : [${_fill_task// /#}${_empty_task// /-}] ${_progress_task}%%"

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
function fnDisplayProgressBarTaskSubUpdate()
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
    printf "\r         Snapshot Progress : [${_fill_task_sub// /#}${_empty_task_sub// /-}] ${_progress_task_sub}%%"
}
#
#######################################################################
#
#
# function to display the subtask text   
#
function fnDisplayTaskSubText()
{
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable: 'counter_aws_snapshot_commands': "$counter_aws_snapshot_commands" "
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable: 'count_aws_snapshot_commands': "$count_aws_snapshot_commands" "
    fnEcho ${LINENO} ""         
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable: 'counter_aws_region_list': "$counter_aws_region_list" "
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable: 'count_aws_region_list': "$count_aws_region_list" "
    fnEcho ${LINENO} ""         
    #       
    #
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 "This job takes a while. Please wait..."
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 ""
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable: 'snapshot_type': "$snapshot_type" "
    fnEcho ${LINENO} ""
    #
    if [[ "$snapshot_type" != 'source-recursive' ]]
    	then 
		    #
		    fnEcho ${LINENO} ""
		    fnEcho ${LINENO} ""$snapshot_type" != source-recursive  "
		    fnEcho ${LINENO} ""
		    #   	
		    fnEcho ${LINENO} level_0 "Snapshotting the AWS Services for region: "$aws_region_list_line_parameter" "
		    fnEcho ${LINENO} level_0 ""   
		    fnEcho ${LINENO} level_0 "Region "$counter_aws_region_list" of "$count_aws_region_list" "
		    fnEcho ${LINENO} level_0 "Note that the global region is included in the count"    
		    fnEcho ${LINENO} level_0 ""          
		    fnEcho ${LINENO} level_0 "Snapshot type "$snapshot_type": "$counter_aws_snapshot_commands" of "$count_aws_snapshot_commands" "
		    fnEcho ${LINENO} level_0 ""      
		    fnEcho ${LINENO} level_0 ""                                                         
		    fnEcho ${LINENO} level_0 "Pulling a snapshot for: "$aws_service" "$aws_command" "$aws_command_parameter_01" "$aws_command_parameter_01_value"  " 
		    fnEcho ${LINENO} level_0"" 
		    fnEcho ${LINENO} ""   
		    fnEcho ${LINENO} ""   
    	else 
		    #
		    fnEcho ${LINENO} ""
		    fnEcho ${LINENO} ""$snapshot_type" = 'source-recursive'  "
		    fnEcho ${LINENO} ""
		    #   	
		    fnEcho ${LINENO} level_0 "Creating and loading the source database tables for the recursive commands  "
		    fnEcho ${LINENO} level_0 ""   
		    fnEcho ${LINENO} level_0 ""          
		    fnEcho ${LINENO} level_0 "Snapshot type: "$snapshot_type" "
		    fnEcho ${LINENO} level_0 ""      
		    fnEcho ${LINENO} level_0 ""                                                         
		    fnEcho ${LINENO} level_0 "Pulling a snapshot for: "$aws_service" "$aws_command" "$aws_command_parameter_01" "$aws_command_parameter_01_value"  " 
		    fnEcho ${LINENO} level_0"" 
		    fnEcho ${LINENO} ""   
		    fnEcho ${LINENO} ""   
	fi # end test for recursive source table run 
	#
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
function fnDisplayProgressBarTask()
{
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnDisplayProgressBarTask' "
    fnEcho ${LINENO} ""
    #    
    fnEcho ${LINENO} level_0 " ---------------------------------------------------------------------------------"
    fnEcho ${LINENO} level_0 "" 
    fnDisplayProgressBarTaskUpdate "$1" "$2"
    fnEcho ${LINENO} level_0 "" 
    fnEcho ${LINENO} level_0 "" 
    fnEcho ${LINENO} level_0 " ---------------------------------------------------------------------------------"
    fnEcho ${LINENO} level_0 ""
}
#
#######################################################################
#
#
# function to display the subtask progress bar on the console  
#
# parameter 1 = counter
# paramter 2 = count
# 
function fnDisplayProgressBarTaskSub()
{
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnDisplayProgressBarTaskSub' "
    fnEcho ${LINENO} ""
    #    
    fnEcho ${LINENO} level_0 " ---------------------------------------------------------------------------------"
    fnEcho ${LINENO} level_0 "" 
    fnDisplayProgressBarTaskSubUpdate "$1" "$2"
    fnEcho ${LINENO} level_0 "" 
    fnEcho ${LINENO} level_0 "" 
    fnEcho ${LINENO} level_0 " ---------------------------------------------------------------------------------"
    fnEcho ${LINENO} level_0 ""
}
#
#######################################################################
#
#
# function to echo the header to the console  
#
function fnDisplayHeader()
{
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnDisplayHeader' "
    fnEcho ${LINENO} ""
    #    
    clear
    fnEcho ${LINENO} level_0 "" 
    fnEcho ${LINENO} "--------------------------------------------------------------------------------------------------------------------"    
    fnEcho ${LINENO} "--------------------------------------------------------------------------------------------------------------------" 
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 "$text_header"    
    fnEcho ${LINENO} level_0 "" 
    fnDisplayProgressBar ${counter_this_file_tasks} ${count_this_file_tasks}
    fnEcho ${LINENO} level_0 "" 
    fnEcho ${LINENO} level_0 "" 
    fnEcho ${LINENO} level_0 "$text_header_bar"
    fnEcho ${LINENO} level_0 ""
}
#
#######################################################################
#
#
# function to echo to the console and write to the log file 
#
function fnEcho()
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
    # the variable is written to the log file on exit by function fnFileAppendLog
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
function fnFileAppendLogTemp()
{
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnFileAppendLogTemp' "
    fnEcho ${LINENO} ""
    # 
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "Appending the log variable to the temp log file"
    fnEcho ${LINENO} "" 
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
function fnFileAppendLog()
{
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnFileAppendLog' "
    fnEcho ${LINENO} ""
    #     
    # append the temp log file onto the log file
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} "Writing temp log to log file"
    fnEcho ${LINENO} "Value of variable 'this_log_temp_file_full_path': "
    fnEcho ${LINENO} "$this_log_temp_file_full_path"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "Value of variable 'this_log_file_full_path': "
    fnEcho ${LINENO} "$this_log_file_full_path"
    fnEcho ${LINENO} level_0 ""   
    # write the contents of the variable to the temp log file
    fnFileAppendLogTemp
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
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnDeleteWorkFiles' "
    fnEcho ${LINENO} ""
    #   
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in delete work files "
    fnEcho ${LINENO} "value of variable 'verbose': "$verbose" "
    fnEcho ${LINENO} "value of variable 'logging': "$logging" "    
    fnEcho ${LINENO} ""
        if [[ ("$verbose" != "y") && ("$logging" != "z") ]] 
            then
                # if not verbose console output or debug logging, then delete the work files
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "In non-verbose or non-debug logging mode: Deleting work files"
                fnEcho ${LINENO} ""
                feed_write_log="$(rm -f "$this_path_temp"/"$this_utility_acronym"-* 2>&1)"
                fnEcho ${LINENO} "$feed_write_log"
                feed_write_log="$(rm -f "$this_path_temp"/"$this_utility_acronym"_* 2>&1)"
                fnEcho ${LINENO} "$feed_write_log"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "value of variable 'this_log_file_full_path' "$this_log_file_full_path" "
                fnEcho ${LINENO} "$feed_write_log"
                fnEcho ${LINENO} ""
                feed_write_log="$(rm -f "$write_path_snapshots"/"$this_utility_acronym"* 2>&1)"
                fnEcho ${LINENO} "$feed_write_log"
                feed_write_log="$(rm -f "$write_path_snapshots"/"$this_utility_acronym"* 2>&1)"
                fnEcho ${LINENO} "$feed_write_log"
                fnEcho ${LINENO} ""
                feed_write_log="$(rm -r -f "$this_path_temp" 2>&1)"
                fnEcho ${LINENO} "$feed_write_log"
                #
                # if no errors, then delete the error log file
                count_error_lines="$(cat "$this_log_file_errors_full_path" | wc -l)"
                if (( "$count_error_lines" < 3 ))
                    then
                        rm -f "$this_log_file_errors_full_path"
                fi  
            else
                # in verbose mode so preserve the work files 
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "In verbose or debug logging mode: Preserving work files "
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "work files are here: "$this_path" "
                fnEcho ${LINENO} level_0 ""                
        fi       
}
#
##########################################################################
#
#
# function to drop the account-timestamp schema if exists   
#
function fnDbSchemaDrop()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnDbSchemaDrop'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnDbSchemaDrop'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnDbSchemaDrop' "
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # drop the account-timestamp schema if exists
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " drop the account-timestamp schema if exists    "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #            
    query_schema_drop="$(psql \
    --host="$db_host" \
    --dbname="$db_name" \
    --username="$db_user" \
    --port="$db_port" \
    --set ON_ERROR_STOP=on \
    --echo-all \
    --echo-errors \
    --echo-queries \
    --tuples-only \
    --no-align \
    --field-separator ' ' \
    --command="DROP SCHEMA IF EXISTS "$db_schema" CASCADE;" 
    2>&1)"
    #
    # check for command error(s)
    if [ "$?" -eq 3 ]
        then
            #
            # set the command/pipeline error line number
            error_line_psql="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'query_schema_drop':"
            fnEcho ${LINENO} level_0 "$query_schema_drop"
            fnEcho ${LINENO} level_0 ""
            # call the psql error function
            fnErrorPsql
            #
    #
    fi
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'query_schema_drop': "
    feed_write_log="$(echo "$query_schema_drop"  2>&1)"
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # end function 'fnDbSchemaDrop'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnDbSchemaDrop'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
}
#
##########################################################################
#
#
# function to create the account-timestamp schema for the run   
#
function fnDbSchemaCreate()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnDbSchemaCreate'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnDbSchemaCreate'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnDbSchemaCreate' "
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # calling the drop schema function to drop schema if exists  
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " calling the drop schema function to drop schema if exists     "
    fnEcho ${LINENO} " calling function 'fnDbSchemaDrop'     "    
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #  
    fnDbSchemaDrop
    #          
    #
    ##########################################################################
    #
    #
    # create the account-timestamp schema
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " create the account-timestamp schema    "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #            
    query_schema_create="$(psql \
    --host="$db_host" \
    --dbname="$db_name" \
    --username="$db_user" \
    --port="$db_port" \
    --set ON_ERROR_STOP=on \
    --set client_min_messages=warning \
    --echo-errors \
    --echo-queries \
    --tuples-only \
    --no-align \
    --field-separator ' ' \
    --command="CREATE SCHEMA IF NOT EXISTS "$db_schema";" 
    2>&1)"
    #
    # check for command error(s)
    if [ "$?" -eq 3 ]
        then
            #
            # set the command/pipeline error line number
            error_line_psql="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'query_schema_create':"
            fnEcho ${LINENO} level_0 "$query_schema_create"
            fnEcho ${LINENO} level_0 ""
            # call the psql error function
            fnErrorPsql
            #
    #
    fi
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'query_schema_create': "
    feed_write_log="$(echo "$query_schema_create"  2>&1)"
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""  
    #   
    #
    #
    ##########################################################################
    #
    #
    # end function 'fnDbSchemaCreate'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnDbSchemaCreate'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
}
#
##########################################################################
#
#
# function to create the services and cli commands tables
#
function fnDbTableCreate()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnDbTableCreate'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnDbTableCreate'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnDbTableCreate' "
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # create the account-timestamp schema
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " create the services and cli commands tables    "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #            
    query_table_create="$(psql \
    --host="$db_host" \
    --dbname="$db_name" \
    --username="$db_user" \
    --port="$db_port" \
    --set ON_ERROR_STOP=on \
    --echo-all \
    --echo-errors \
    --echo-queries \
    --tuples-only \
    --no-align \
    --field-separator ' ' \
    --command="DROP TABLE IF EXISTS "$db_schema"._driver_aws_services;  CREATE TABLE "$db_schema"._driver_aws_services AS SELECT DISTINCT * FROM aws_sps__commands._driver_aws_services;  DROP TABLE IF EXISTS "$db_schema"._driver_aws_cli_commands;  CREATE TABLE "$db_schema"._driver_aws_cli_commands AS SELECT DISTINCT * FROM aws_sps__commands._driver_aws_cli_commands;  DROP TABLE IF EXISTS "$db_schema"._driver_aws_cli_commands_recursive; CREATE TABLE "$db_schema"._driver_aws_cli_commands_recursive AS SELECT DISTINCT * FROM aws_sps__commands._driver_aws_cli_commands_recursive;" 
    2>&1)"
    #
    # check for command error(s)
    if [ "$?" -eq 3 ]
        then
            #
            # set the command/pipeline error line number
            error_line_psql="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'query_table_create':"
            fnEcho ${LINENO} level_0 "$query_table_create"
            fnEcho ${LINENO} level_0 ""
            # call the psql error function
            fnErrorPsql
            #
    #
    fi
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'query_table_create': "
    feed_write_log="$(echo "$query_table_create"  2>&1)"
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""  
    #   
    #
    #
    ##########################################################################
    #
    #
    # end function 'fnDbTableCreate'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnDbTableCreate'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
}
#
##########################################################################
#
#
# function to query the list of services to process    
#
function fnDbQueryServiceList()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnDbQueryServiceList'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnDbQueryServiceList'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnDbQueryServiceList' "
    fnEcho ${LINENO} ""
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "initializing the output file: "$this_path_temp"/"$this_utility_acronym"-driver-aws-services.txt "
    feed_write_log="$(echo "" > "$this_path_temp"/"$this_utility_acronym"-driver-aws-services.txt  2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$this_utility_acronym"-driver-aws-services.txt:"
            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-driver-aws-services.txt)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""  
    #   
    #
    ##########################################################################
    #
    #
    # query the service list from the database
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " query the service list from the database   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #            
    query_service_list="$(psql \
    --host="$db_host" \
    --dbname="$db_name" \
    --username="$db_user" \
    --port="$db_port" \
    --set ON_ERROR_STOP=on \
    --echo-all \
    --echo-errors \
    --echo-queries \
    --tuples-only \
    --no-align \
    --field-separator ' ' \
    --command="SELECT DISTINCT aws_service::text FROM aws_snapshot."$db_schema"._driver_aws_services WHERE execute_yn = 'y';" \
    --output="$this_path_temp"/"$this_utility_acronym"-driver-aws-services.txt \
    2>&1)"
    #
    # check for command error(s)
    if [ "$?" -eq 3 ]
        then
            #
            # set the command/pipeline error line number
            error_line_psql="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'query_service_list':"
            fnEcho ${LINENO} level_0 "$query_service_list"
            fnEcho ${LINENO} level_0 ""
            # call the psql error function
            fnErrorPsql
            #
    #
    fi
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'query_service_list': "
    feed_write_log="$(echo "$query_service_list"  2>&1)"
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""  
    #   
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "Contents of file: "$this_path_temp"/"$this_utility_acronym"-driver-aws-services.txt "
    fnEcho ${LINENO} ""  
    feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-driver-aws-services.txt  2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$this_utility_acronym"-driver-aws-services.txt:"
            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-driver-aws-services.txt)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""  
    #
    #
    ##########################################################################
    #
    #
    # end function 'fnDbQueryServiceList'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnDbQueryServiceList'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
}
#
##########################################################################
#
#
# function to query the list of global services to process    
#
function fnDbQueryServiceGlobalList()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnDbQueryServiceGlobalList'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnDbQueryServiceGlobalList'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnDbQueryServiceGlobalList' "
    fnEcho ${LINENO} ""
    #    
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "initializing the output file: "$this_path_temp"/"$file_snapshot_driver_global_services_file_name" "
    feed_write_log="$(echo "" > "$this_path_temp"/"$file_snapshot_driver_global_services_file_name"  2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_global_services_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_global_services_file_name")"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""  
    # 
    #
    ##########################################################################
    #
    #
    # query the global service list from the database
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " query the global service list from the database   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #            
    query_service_global_list="$(psql \
    --host="$db_host" \
    --dbname="$db_name" \
    --username="$db_user" \
    --port="$db_port" \
    --set ON_ERROR_STOP=on \
    --echo-all \
    --echo-errors \
    --echo-queries \
    --tuples-only \
    --no-align \
    --field-separator ' ' \
    --command="SELECT DISTINCT aws_service::text FROM aws_snapshot."$db_schema"._driver_aws_services WHERE _driver_aws_services.execute_yn = 'y' AND _driver_aws_services.global_aws_service_yn = 'y';" \
    --output="$this_path_temp"/"$file_snapshot_driver_global_services_file_name" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -eq 3 ]
        then
            #
            # set the command/pipeline error line number
            error_line_psql="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'query_service_global_list':"
            fnEcho ${LINENO} level_0 "$query_service_global_list"
            fnEcho ${LINENO} level_0 ""
            # call the psql error function
            fnErrorPsql
            #
    #
    fi
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'query_service_global_list': "
    feed_write_log="$(echo "$query_service_global_list"  2>&1)"
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""  
    #   
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "Contents of file: '"$this_path_temp"/"$file_snapshot_driver_global_services_file_name"' "
    fnEcho ${LINENO} ""  
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_global_services_file_name"  2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file '"$this_path_temp"/"$file_snapshot_driver_global_services_file_name"':"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_global_services_file_name")"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""  
    #
    #
    ##########################################################################
    #
    #
    # end function 'fnDbQueryServiceGlobalList'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnDbQueryServiceGlobalList'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
}
#
##########################################################################
#
#
# function to query the list of commands to process    
#
function fnDbQueryCommandNonRecursiveList()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnDbQueryCommandNonRecursiveList'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnDbQueryCommandNonRecursiveList'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnDbQueryCommandNonRecursiveList' "
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "initializing the output file: "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name_raw" "
    feed_write_log="$(echo "" > "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name_raw"  2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name_raw":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name_raw")"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""  
    #    
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "querying the command list"
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # query the non-recursive cli commands from the database
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " query the non-recursive cli commands from the database   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                
    query_command_list="$(psql \
    --host="$db_host" \
    --dbname="$db_name" \
    --username="$db_user" \
    --port="$db_port" \
    --set ON_ERROR_STOP=on \
    --echo-all \
    --echo-errors \
    --echo-queries \
    --tuples-only \
    --no-align \
    --field-separator ' ' \
    --command="SELECT DISTINCT "$db_schema"._driver_aws_cli_commands.aws_service :: TEXT || ' ' || "$db_schema"._driver_aws_cli_commands.aws_cli_command :: TEXT FROM aws_snapshot."$db_schema"._driver_aws_cli_commands INNER JOIN aws_snapshot."$db_schema"._driver_aws_services ON _driver_aws_services.aws_service = "$db_schema"._driver_aws_cli_commands.aws_service WHERE _driver_aws_services.execute_yn = 'y'  AND  "$db_schema"._driver_aws_cli_commands.execute_yn = 'y' AND  "$db_schema"._driver_aws_cli_commands.recursive_yn = 'n' ;" \
    --output="$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name_raw" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -eq 3 ]
        then
            #
            # set the command/pipeline error line number
            error_line_psql="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'query_command_list':"
            fnEcho ${LINENO} level_0 "$query_command_list"
            fnEcho ${LINENO} level_0 ""
            # call the psql error function
            fnErrorPsql
            #
    #
    fi
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'query_command_list': "$query_command_list" "
    feed_write_log="$(echo "$query_command_list"  2>&1)"
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #      
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "Contents of file: '"$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name_raw" "
    fnEcho ${LINENO} ""  
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name_raw"  2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name_raw":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name_raw")"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""  
    #
    #
    ##########################################################################
    #
    #
    # count the non-recursive cli commands; load variable 'count_aws_snapshot_commands_non_recursive' 
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " count the non-recursive cli commands; load variable 'count_aws_snapshot_commands_non_recursive'   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                
    count_aws_snapshot_commands_non_recursive="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name_raw" | wc -l 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'count_aws_snapshot_commands_non_recursive': "$count_aws_snapshot_commands_non_recursive")"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name_raw":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name_raw")"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'count_aws_snapshot_commands_non_recursive': "$count_aws_snapshot_commands_non_recursive" "
    fnEcho ${LINENO} ""
    # 
    #
    ##########################################################################
    #
    #
    # end function 'fnDbQueryCommandNonRecursiveList'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnDbQueryCommandNonRecursiveList'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
}
#
##########################################################################
#
#
# function to query the list of recursive single parameter commands to process    
#
function fnDbQueryCommandRecursiveSingleList()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnDbQueryCommandRecursiveSingleList'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnDbQueryCommandRecursiveSingleList'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnDbQueryCommandRecursiveSingleList' "
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # display the header     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " display the header      "  
    fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
    fnDisplayHeader
    #
    # display the task progress bar
    #
    fnDisplayProgressBarTask "$counter_aws_region_list" "$count_aws_region_list"
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "initializing the query output file: "$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_queries" "
    feed_write_log="$(echo "" > "$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_queries"  2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_queries":"
            feed_write_log="$(cat "$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_queries" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""  
    #    
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "initializing the command line output file: "$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_results" "
    feed_write_log="$(echo "" > "$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_results"  2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_results":"
            feed_write_log="$(cat "$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_results" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""  
    #    
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "initializing the commands output file: "$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw" "
    feed_write_log="$(echo "" > "$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw"  2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw":"
            feed_write_log="$(cat "$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""  
    #    
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "pulling the recursive single queries list "
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # query the recursive-single query list from the database
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " query the recursive-single query list from the database   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                    
    query_list_recursive_single="$(psql \
    --host="$db_host" \
    --dbname="$db_name" \
    --username="$db_user" \
    --port="$db_port" \
    --set ON_ERROR_STOP=on \
    --echo-all \
    --echo-errors \
    --echo-queries \
    --tuples-only \
    --no-align \
    --field-separator ' ' \
    --command="/* recursive commands - single parameter - non-recursive-single-dependent - non-hardcoded */ SELECT DISTINCT  "$db_schema"._driver_aws_cli_commands_recursive.command_recursive_single_query FROM ""$db_schema"._driver_aws_cli_commands_recursive" INNER JOIN aws_snapshot."$db_schema"._driver_aws_services ON _driver_aws_services.aws_service = "$db_schema"._driver_aws_cli_commands_recursive.aws_service WHERE "$db_schema"._driver_aws_services.execute_yn = 'y'  AND "$db_schema"._driver_aws_cli_commands_recursive.execute_yn = 'y'  AND "$db_schema"._driver_aws_cli_commands_recursive.command_repeated_hardcoded_yn = 'n'  AND "$db_schema"._driver_aws_cli_commands_recursive.recursive_dependent_yn = 'n'  AND "$db_schema"._driver_aws_cli_commands_recursive.parameter_count = '1'  AND "$db_schema"._driver_aws_cli_commands_recursive.command_recursive IS NOT NULL  AND "$db_schema"._driver_aws_cli_commands_recursive.command_recursive != '' ORDER BY "$db_schema"._driver_aws_cli_commands_recursive.command_recursive_single_query;" \
    --output="$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_queries" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -eq 3 ]
        then
            #
            # set the command/pipeline error line number
            error_line_psql="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'query_list_recursive_single':"
            fnEcho ${LINENO} level_0 "$query_list_recursive_single"
            fnEcho ${LINENO} level_0 ""
            # call the psql error function
            fnErrorPsql
            #
    #
    fi
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'query_list_recursive_single': "$query_list_recursive_single" "
    feed_write_log="$(echo "$query_list_recursive_single"  2>&1)"
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #      
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "Contents of file: "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_queries" "
    fnEcho ${LINENO} ""  
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_queries"  2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_queries" "
            feed_write_log="$(cat "$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_queries" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""  
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "running the recursive_single queries to build the AWS command list "
    #
    #
    ##########################################################################
    #
    #
    # begin loop read: driver_query_recursive_single_list.txt
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin loop read: driver_query_recursive_single_list.txt   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    while read -r driver_query_recursive_single_list_line_no_schema 
    do 
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "-------------------------------------------------------------------------------------------------------------  "          
        fnEcho ${LINENO} "--------------------------- loop head: read driver_query_recursive_single_list.txt --------------------------  "
        fnEcho ${LINENO} "-------------------------------------------------------------------------------------------------------------  "          
        fnEcho ${LINENO} ""   
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of variable 'driver_query_recursive_single_list_line_no_schema':  "
        fnEcho ${LINENO} "$driver_query_recursive_single_list_line_no_schema"
        fnEcho ${LINENO} ""
        #   
        #
        ##########################################################################
        #
        #
        # extract the service name from the results 
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " extract the service name from the results    "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #
        aws_service="$(echo "$driver_query_recursive_single_list_line_no_schema" | sed -e 's/.*AS command_parameter, \(.*\)___.*/\1/' |tr -d "'" | awk '{print $1;}' | sed -e 's/\(.*\)___.*/\1/' 2>&1)"
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of variable 'aws_service': "$aws_service" "
        fnEcho ${LINENO} ""
        #
        aws_command="$(echo "$driver_query_recursive_single_list_line_no_schema" | sed -E 's/.*FROM(.*)AS aws_command.*/\1/' | tr -d "'(" | sed 's/  / /' | sed 's/^ //' | awk '{print $3;}' 2>&1)"
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of variable 'aws_command': "$aws_command" "
        fnEcho ${LINENO} ""     
	    #
	    ##########################################################################
	    #
	    #
	    # creating AWS Command underscore version     
	    #
	    fnEcho ${LINENO} ""  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} " creating AWS Command underscore version      "       
	    fnEcho ${LINENO} " calling function 'fnAwsCommandUnderscore'      "               
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} ""  
	    #          
	    fnAwsCommandUnderscore
	    #
	    ##########################################################################
	    #
	    #
	    # setting the AWS snapshot name variable and creating underscore version      
	    #
	    fnEcho ${LINENO} ""  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} " setting the AWS snapshot name variable and creating underscore version      "       
	    fnEcho ${LINENO} " calling function 'fnLoadSnapshotNameVariable'      "               
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} ""  
	    #          
	    fnLoadSnapshotNameVariable
	    #
	    ##########################################################################
	    #
	    #
	    # loading the service-snapshot variables    
	    #
	    fnEcho ${LINENO} ""  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} " loading the service-snapshot variables      "       
	    fnEcho ${LINENO} " calling function 'fnLoadServiceSnapshotVariables'      "               
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} ""  
	    #          
	    fnLoadServiceSnapshotVariables
	    #
	    ##########################################################################
	    #
	    #
	    # display the header     
	    #
	    fnEcho ${LINENO} ""  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} " display the header      "  
	    fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} ""  
	    #          
	    fnDisplayHeader
	    #
	    # display the task progress bar
	    #
	    fnDisplayProgressBarTask "$counter_aws_region_list" "$count_aws_region_list"
	    #
        ##########################################################################
        #
        #
        # insert the schema name into the query
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " insert the schema name into the query    "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #
		string_search='FROM '"$aws_service" 
		string_replace='FROM '"$db_schema"."$aws_service"
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} " value of variable 'aws_service': "$aws_service"   "
        fnEcho ${LINENO} " value of variable 'string_search': "$string_search"   "
        fnEcho ${LINENO} " value of variable 'string_replace': "$string_replace"   "
        fnEcho ${LINENO} ""  
        #
        driver_query_recursive_single_list_line="$(echo "${driver_query_recursive_single_list_line_no_schema/$string_search/$string_replace}" 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'driver_query_recursive_single_list_line':"
                fnEcho ${LINENO} level_0 "$driver_query_recursive_single_list_line"
                fnEcho ${LINENO} level_0 ""
                #                                                                                                                            
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnEcho ${LINENO} "$feed_write_log"
        #
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} " value of variable 'driver_query_recursive_single_list_line':    "
        feed_write_log="$(echo "$driver_query_recursive_single_list_line"  2>&1)"
        fnEcho ${LINENO} "$feed_write_log"
        #
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "pulling the recursive single queries"
        fnEcho ${LINENO} ""
        #
        #
        ##########################################################################
        #
        #
        # query the recursive-single results from the database
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " query the recursive-single results from the database   "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #                            
        query_recursive_single_results="$(psql \
        --host="$db_host" \
        --dbname="$db_name" \
        --username="$db_user" \
        --port="$db_port" \
        --set ON_ERROR_STOP=on \
        --echo-all \
        --echo-errors \
        --echo-queries \
        --tuples-only \
        --no-align \
        --field-separator ' ' \
        --command="$driver_query_recursive_single_list_line" \
        --output="$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_results" 2>&1)"
        #
        # check for psql command error(s)
        if [ "$?" -eq 3 ]
            then
                #
                # set the command/pipeline error line number
                error_line_psql="$((${LINENO}-7))"
                #
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'query_recursive_single_results':"
                fnEcho ${LINENO} level_0 "$query_recursive_single_results"
                fnEcho ${LINENO} level_0 ""
	            # call the psql error function
                fnErrorPsql
                #
        #
        fi
        #
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} " value of variable 'query_recursive_single_results':"
        feed_write_log="$(echo "$query_recursive_single_results" 2>&1)"
        fnEcho ${LINENO} "$feed_write_log"
        fnEcho ${LINENO} ""  
        #     
        ##########################################################################
        #
        #
        # append the query result command list to the command list file
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " append the query result command list to the command list file    "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "writing the query result recursive single parameter command list to the driver file: "$this_path_temp"/"$this_utility_acronym"-driver-aws-cli-commands-recursive-single.txt "
        feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_results" >> "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw" 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw" :"
                feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw" 2>&1)"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #                                                                                                                            
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnEcho ${LINENO} "$feed_write_log"
        #
        #
   #
    # check for debug log 
    if [[ "$logging" = 'z' ]] 
        then 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} "" 
            fnEcho ${LINENO} ""                             
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------------------------------------------"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} ""                
            fnEcho ${LINENO} "Contents of file: "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw" "
            fnEcho ${LINENO} ""  
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw"  2>&1)"
            #  check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    #
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw" "
                    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw" 2>&1)"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #                                         
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
                    #
            fi  # end pipeline error check 
            #
            fnEcho ${LINENO} "$feed_write_log"
            #
            fnEcho ${LINENO} "--------------------------------------------------------------------------------------------------"
            fnEcho ${LINENO} ""
    #     
    fi  # end check for debug log 
    #                       
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "-------------------------------------------------------------------------------------------------------------  "          
    fnEcho ${LINENO} "--------------------------- loop tail: read driver_query_recursive_single_list.txt --------------------------  "
    fnEcho ${LINENO} "-------------------------------------------------------------------------------------------------------------  "          
    fnEcho ${LINENO} ""   
    #
    #
    done< <(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_queries")
    #
    #
    ##########################################################################
    #
    #
    # done with loop read: driver_query_recursive_single_list.txt
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " done with loop read: driver_query_recursive_single_list.txt   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    ##########################################################################
    #
    #
    # contents of the output file: "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw"  
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw" "
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw" 2>&1)"
   #  check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw" "
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                         
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi  # end pipeline error check 
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #    
    ##########################################################################
    #
    #
    # count the recursive-single cli commands; load variable 'count_aws_snapshot_commands_recursive_single' 
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " count the recursive-single cli commands; load variable 'count_aws_snapshot_commands_recursive_single'   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                
    count_aws_snapshot_commands_recursive_single="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw" | wc -l 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'count_aws_snapshot_commands_recursive_single': "$count_aws_snapshot_commands_recursive_single")"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw" :"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'count_aws_snapshot_commands_recursive_single': "$count_aws_snapshot_commands_recursive_single" "
    fnEcho ${LINENO} ""
    #                                                    
    ##########################################################################
    #
    # end function 'fnDbQueryCommandRecursiveSingleList'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnDbQueryCommandRecursiveSingleList'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
}
#
##########################################################################
#
#
# function to query the list of recursive single dependent parameter commands to process    
#
function fnDbQueryCommandRecursiveSingleDependentList()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnDbQueryCommandRecursiveSingleDependentList'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnDbQueryCommandRecursiveSingleDependentList'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnDbQueryCommandRecursiveSingleDependentList' "
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "initializing the recursive-single-dependent queries output file: "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_queries" "
    feed_write_log="$(echo "" > "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_queries"  2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_queries":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_queries" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""  
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "initializing the recursive-single-dependent command line results output file: "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_results" "
    feed_write_log="$(echo "" > "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_results"  2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_results":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_results" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""  
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "initializing the recursive-single-dependent output file: "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_raw" "
    feed_write_log="$(echo "" > "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_raw"  2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_raw":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_raw" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""  
    #    
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "pulling the recursive single dependent queries list "
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # query the recursive-single-dependent query list from the database
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " query the recursive-single-dependent query list from the database   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                    
    query_list_recursive_single_dependent="$(psql \
    --host="$db_host" \
    --dbname="$db_name" \
    --username="$db_user" \
    --port="$db_port" \
    --set ON_ERROR_STOP=on \
    --echo-all \
    --echo-errors \
    --echo-queries \
    --tuples-only \
    --no-align \
    --field-separator ' ' \
    --command="/* recursive commands - single dependent parameter - non-hardcoded */  SELECT DISTINCT "$db_schema"._driver_aws_cli_commands_recursive.command_recursive_single_query  FROM  "$db_schema"._driver_aws_cli_commands_recursive     INNER JOIN aws_snapshot."$db_schema"._driver_aws_services ON _driver_aws_services.aws_service = "$db_schema"._driver_aws_cli_commands_recursive.aws_service  WHERE  "$db_schema"._driver_aws_services.execute_yn = 'y'   AND "$db_schema"._driver_aws_cli_commands_recursive.execute_yn = 'y'    AND "$db_schema"._driver_aws_cli_commands_recursive.command_repeated_hardcoded_yn = 'n'     AND "$db_schema"._driver_aws_cli_commands_recursive.recursive_dependent_yn = 'y'    AND "$db_schema"._driver_aws_cli_commands_recursive.parameter_count = '1'   AND "$db_schema"._driver_aws_cli_commands_recursive.command_recursive IS NOT NULL   AND "$db_schema"._driver_aws_cli_commands_recursive.command_recursive != ''  ORDER BY   "$db_schema"._driver_aws_cli_commands_recursive.command_recursive_single_query;" \
    --output="$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_queries" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -eq 3 ]
        then
            #
            # set the command/pipeline error line number
            error_line_psql="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'query_list_recursive_single_dependent':"
            fnEcho ${LINENO} level_0 "$query_list_recursive_single_dependent"
            fnEcho ${LINENO} level_0 ""
            # call the psql error function
            fnErrorPsql
            #
    #
    fi
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'query_list_recursive_single_dependent': "$query_list_recursive_single_dependent" "
    feed_write_log="$(echo "$query_list_recursive_single_dependent"  2>&1)"
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #      
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "Contents of file: "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_queries" "
    fnEcho ${LINENO} ""  
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_queries"  2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_queries":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_queries" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""  
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "running the recursive_single dependent queries to build the AWS command list "
    #
    #
    ##########################################################################
    #
    #
    # begin loop read: driver_query_recursive_single_dependent_list.txt
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin loop read: driver_query_recursive_single_dependent_list.txt   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    while read -r driver_query_recursive_single_dependent_list_line 
    do 
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "-------------------------------------------------------------------------------------------------------------  "          
        fnEcho ${LINENO} "--------------------------- loop head: read driver_query_recursive_single_dependent_list.txt --------------------------  "
        fnEcho ${LINENO} "-------------------------------------------------------------------------------------------------------------  "          
        fnEcho ${LINENO} ""   
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of variable 'driver_query_recursive_single_dependent_list_line':  "
        fnEcho ${LINENO} "$driver_query_recursive_single_dependent_list_line"
        fnEcho ${LINENO} ""
        #      
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "pulling the recursive single dependent queries"
        fnEcho ${LINENO} ""
        #
        #
        ##########################################################################
        #
        #
        # query the recursive-single-dependent results from the database
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " query the recursive-single-dependent results from the database   "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #                            
        query_recursive_single_dependent_results="$(psql \
        --host="$db_host" \
        --dbname="$db_name" \
        --username="$db_user" \
        --port="$db_port" \
        --set ON_ERROR_STOP=on \
        --echo-all \
        --echo-errors \
        --echo-queries \
        --tuples-only \
        --no-align \
        --field-separator ' ' \
        --command="$driver_query_recursive_single_dependent_list_line" \
        --output="$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_results" 2>&1)"
        #
        # check for psql command error(s)
        if [ "$?" -eq 3 ]
            then
                #
                # set the command/pipeline error line number
                error_line_psql="$((${LINENO}-7))"
                #
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'query_recursive_single_dependent_results':"
                fnEcho ${LINENO} level_0 "$query_recursive_single_dependent_results"
                fnEcho ${LINENO} level_0 ""
	            # call the psql error function
                fnErrorPsql
                #
        #
        fi
        #
        #
        #
        ##########################################################################
        #
        #
        # append the query result command list to the command list file
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " append the query result command list to the command list file    "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "writing the query result recursive single dependent parameter command list to the driver file: "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_raw" "
        feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_results" >> "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_raw" 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_results":"
                feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_results" 2>&1)"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #                                                                                                                            
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnEcho ${LINENO} "$feed_write_log"
        #
        #
    #
    # check for debug log 
    if [[ "$logging" = 'z' ]] 
        then 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} "" 
            fnEcho ${LINENO} ""                             
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------------------------------------------"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} ""                
            fnEcho ${LINENO} "Contents of file: "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_raw" "
            fnEcho ${LINENO} ""  
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_raw"  2>&1)"
            #
            #  check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    #
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_raw""
                    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_raw" 2>&1)"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #                                         
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
                    #
            fi  # end pipeline error check 
            #
            fnEcho ${LINENO} "$feed_write_log"
            #
            fnEcho ${LINENO} "--------------------------------------------------------------------------------------------------"
            fnEcho ${LINENO} ""
    #     
    fi  # end check for debug log 
    #                       
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "-------------------------------------------------------------------------------------------------------------  "          
    fnEcho ${LINENO} "--------------------------- loop tail: read driver_query_recursive_single_dependent_list.txt --------------------------  "
    fnEcho ${LINENO} "-------------------------------------------------------------------------------------------------------------  "          
    fnEcho ${LINENO} ""   
    #
    #
    done< <(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_queries")
    #
    #
    ##########################################################################
    #
    #
    # done with loop read: driver_query_recursive_single_dependent_list.txt
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " done with loop read: driver_query_recursive_single_dependent_list.txt   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    ##########################################################################
    #
    #
    # count the recursive-single-dependent cli commands; load variable 'count_aws_snapshot_commands_recursive_single_dependent' 
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " count the recursive cli commands; load variable 'count_aws_snapshot_commands_recursive_single_dependent'   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                
    count_aws_snapshot_commands_recursive_single_dependent="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_raw" | wc -l 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'count_aws_snapshot_commands_recursive_single_dependent': "$count_aws_snapshot_commands_recursive_single_dependent")"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_raw":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_raw" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'count_aws_snapshot_commands_recursive_single_dependent': "$count_aws_snapshot_commands_recursive_single_dependent" "
    fnEcho ${LINENO} ""
    #                                                    
    ##########################################################################
    #
    # end function 'fnDbQueryCommandRecursiveSingleDependentList'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnDbQueryCommandRecursiveSingleDependentList'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
}
#
#
#
# recursive multi is not built yet
# 
# #
# ##########################################################################
# #
# #
# # function to query the list of recursive multi-parameter commands to process    
# #
# function fnDbQueryCommandRecursiveMultiList()
# {
#     #
#     ##########################################################################
#     #
#     #
#     # begin function 'fnDbQueryCommandRecursiveMultiList'     
#     #
#     fnEcho ${LINENO} ""  
#     fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
#     fnEcho ${LINENO} " begin function 'fnDbQueryCommandRecursiveMultiList'      "       
#     fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
#     fnEcho ${LINENO} ""  
#     #       
#     #
#     fnEcho ${LINENO} ""
#     fnEcho ${LINENO} "in function: 'fnDbQueryCommandRecursiveMultiList' "
#     fnEcho ${LINENO} ""
#     #
#     fnEcho ${LINENO} ""
#     fnEcho ${LINENO} "initializing the output file: "$this_path_temp"/"$this_utility_acronym"-driver-aws-cli-commands-recursive-multi.txt "
#     feed_write_log="$(echo "" > "$this_path_temp"/"$this_utility_acronym"-driver-aws-cli-commands-recursive-multi.txt  2>&1)"
#     #
#     # check for command / pipeline error(s)
#     if [ "$?" -ne 0 ]
#         then
#             #
#             # set the command/pipeline error line number
#             error_line_pipeline="$((${LINENO}-7))"
#             #
#             #
#             fnEcho ${LINENO} level_0 ""
#             fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$this_utility_acronym"-driver-aws-cli-commands-recursive-multi.txt:"
#             feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-driver-aws-cli-commands-recursive-multi.txt)"
#             fnEcho ${LINENO} level_0 "$feed_write_log"
#             fnEcho ${LINENO} level_0 ""
#             #                                                    
#             # call the command / pipeline error function
#             fnErrorPipeline
#             #
#             #
#     fi
#     #
#     fnEcho ${LINENO} "$feed_write_log"
#     fnEcho ${LINENO} ""  
#     #    
#     fnEcho ${LINENO} ""
#     fnEcho ${LINENO} "querying the command recursive-multi list"
#     fnEcho ${LINENO} ""
#     #
#     #
#     ##########################################################################
#     #
#     #
#     # query the recursive-multi query list from the database
#     #
#     fnEcho ${LINENO} ""  
#     fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
#     fnEcho ${LINENO} " query the recursive-multi query list from the database   "
#     fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
#     fnEcho ${LINENO} ""  
#     #                                
#     query_list_recursive_multi="$(psql \
#     --host="$db_host" \
#     --dbname="$db_name" \
#     --username="$db_user" \
#     --port="$db_port" \
#     --set ON_ERROR_STOP=on \
#     --echo-all \
#     --echo-errors \
#     --echo-queries \
#     --tuples-only \
#     --no-align \
#     --field-separator ' ' \
#     --command="/* recursive commands and parameter source tables */ /* non-recursive single_dependent */ /* non-hardcoded */ SELECT DISTINCT "$db_schema"._driver_aws_cli_commands_recursive.command_recursive, "$db_schema"._driver_aws_cli_commands_recursive.parameter_source_table, "$db_schema"._driver_aws_cli_commands_recursive.parameter_source_attribute FROM "$db_schema"._driver_aws_cli_commands_recursive INNER JOIN aws_snapshot."$db_schema".driver_aws_services ON _driver_aws_services.aws_service = "$db_schema"._driver_aws_cli_commands_recursive.aws_service WHERE _driver_aws_services.execute_yn = 'y' AND "$db_schema"._driver_aws_cli_commands_recursive.execute_yn = 'y' AND "$db_schema"._driver_aws_cli_commands_recursive.recursive_single_dependent_yn = 'n' AND "$db_schema"._driver_aws_cli_commands_recursive.command_repeated_hardcoded_yn = 'n' AND "$db_schema"._driver_aws_cli_commands_recursive.command_recursive IS NOT NULL AND "$db_schema"._driver_aws_cli_commands_recursive.command_recursive != '' ORDER BY "$db_schema"._driver_aws_cli_commands_recursive.command_recursive;" \
#     --output="$this_path_temp"/"$this_utility_acronym"-driver-aws-cli-commands-recursive-multi.txt 2>&1)"
#     #
#     # check for command / pipeline error(s)
#     if [ "$?" -eq 3 ]
#         then
#             #
#             # set the command/pipeline error line number
#             error_line_psql="$((${LINENO}-7))"
#             #
#             #
#             fnEcho ${LINENO} level_0 ""
#             fnEcho ${LINENO} level_0 "value of variable 'query_command_list':"
#             fnEcho ${LINENO} level_0 "$query_command_list"
#             fnEcho ${LINENO} level_0 ""
#             # call the command / pipeline error function
#             fnErrorPsql
#             #
#     #
#     fi
#     #
#     #
#     fnEcho ${LINENO} ""
#     fnEcho ${LINENO} "value of variable 'query_list_recursive_multi': "$query_list_recursive_multi" "
#     feed_write_log="$(echo "$query_list_recursive_multi"  2>&1)"
#     fnEcho ${LINENO} "$feed_write_log"
#     fnEcho ${LINENO} ""
#     #      
#     #
#     fnEcho ${LINENO} ""
#     fnEcho ${LINENO} "Contents of file: "$this_path_temp"/"$this_utility_acronym"-driver-aws-cli-commands-recursive-multi.txt "
#     fnEcho ${LINENO} ""  
#     feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-driver-aws-cli-commands-recursive-multi.txt  2>&1)"
#     #
#     # check for command / pipeline error(s)
#     if [ "$?" -ne 0 ]
#         then
#             #
#             # set the command/pipeline error line number
#             error_line_pipeline="$((${LINENO}-7))"
#             #
#             #
#             fnEcho ${LINENO} level_0 ""
#             fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$this_utility_acronym"-driver-aws-cli-commands-recursive-multi.txt:"
#             feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-driver-aws-cli-commands-recursive-multi.txt)"
#             fnEcho ${LINENO} level_0 "$feed_write_log"
#             fnEcho ${LINENO} level_0 ""
#             #                                                    
#             # call the command / pipeline error function
#             fnErrorPipeline
#             #
#             #
#     fi
#     #
#     fnEcho ${LINENO} "$feed_write_log"
#     fnEcho ${LINENO} ""  
#     #
#     #   
#     ##########################################################################
#     #
#     #
#     # count the non-recursive cli commands; load variable 'count_aws_snapshot_commands_non_recursive' 
#     #
#     fnEcho ${LINENO} ""  
#     fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
#     fnEcho ${LINENO} " count the non-recursive cli commands; load variable 'count_aws_snapshot_commands_non_recursive'   "
#     fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
#     fnEcho ${LINENO} ""  
#     #                
#     count_aws_snapshot_commands_recursive_multi="$(cat "$this_path_temp"/"$this_utility_acronym"-driver-aws-cli-commands-recursive-multi.txt | wc -l 2>&1)"
#     #
#     # check for command / pipeline error(s)
#     if [ "$?" -ne 0 ]
#         then
#             #
#             # set the command/pipeline error line number
#             error_line_pipeline="$((${LINENO}-7))"
#             #
#             #
#             fnEcho ${LINENO} level_0 ""
#             fnEcho ${LINENO} level_0 "value of variable 'count_aws_snapshot_commands_recursive_multi': "$count_aws_snapshot_commands_recursive_multi")"
#             fnEcho ${LINENO} level_0 ""
#             #                                                    
#             fnEcho ${LINENO} level_0 ""
#             fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$this_utility_acronym"-driver-aws-cli-commands-recursive-multi.txt:"
#             feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-driver-aws-cli-commands-recursive-multi.txt)"
#             fnEcho ${LINENO} level_0 "$feed_write_log"
#             fnEcho ${LINENO} level_0 ""
#             #                                                    
#             # call the command / pipeline error function
#             fnErrorPipeline
#             #
#             #
#     fi
#     #
#     #
#     fnEcho ${LINENO} ""
#     fnEcho ${LINENO} "value of variable 'count_aws_snapshot_commands_recursive_multi': "$count_aws_snapshot_commands_recursive_multi")"
#     fnEcho ${LINENO} ""
# 
#     #
#     ##########################################################################
#     #
#     #
#     # end function 'fnDbQueryCommandRecursiveMultiList'     
#     #
#     fnEcho ${LINENO} ""  
#     fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
#     fnEcho ${LINENO} " end function 'fnDbQueryCommandRecursiveMultiList'      "       
#     fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
#     fnEcho ${LINENO} ""  
#     #       
# }
#
##########################################################################
#
#
# function to load the snapshot file to the database    
#
function fnDbLoadSnapshotFile()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnDbLoadSnapshotFile'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnDbLoadSnapshotFile'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #    
    # test if snapshot JSON file exists and table name is not null
    if [[ -f "$write_file_full_path" ]] && [[ "$aws_service_snapshot_name_table_underscore_load" != '' ]]
    	then 
		    #
		    ##########################################################################
		    #
		    #
		    # source snapshot JSON file exists; loading the file to the PostgreSQL database
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} " source snapshot JSON file exists and table name is not empty; loading the file to the PostgreSQL database   "
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} ""  
		    #   
		    #
		    ##########################################################################
		    #
		    #
		    # setting file source variable: 'write_file_no_lf_file_name'
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} " setting file name for source file stripped of line feeds - variable: 'write_file_no_lf_file_name'  "
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} ""  
		    #   
		    write_file_no_lf_file_name="$write_file"-no-lf 
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "AWS command - value of variable 'aws_command': "$aws_command" "  	    
		    fnEcho ${LINENO} "file to load: " 
		    fnEcho ${LINENO} "value of variable 'write_file_full_path': "$write_file_full_path" " 
		    fnEcho ${LINENO} "file name to load: "$write_file" " 
		    fnEcho ${LINENO} "value of variable 'write_file': "$write_file" " 
		    fnEcho ${LINENO} "write file no lf file name - used to load the table:  " 
		    fnEcho ${LINENO} "value of variable 'write_file_no_lf_file_name': "$write_file_no_lf_file_name" " 
		    fnEcho ${LINENO} "table name:  "
		    fnEcho ${LINENO} "value of variable 'aws_service_snapshot_name_table_underscore': "$aws_service_snapshot_name_table_underscore" " 
		    fnEcho ${LINENO} ""  
		    #
		    ##########################################################################
		    #
		    #
		    # testing for table exists
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} " testing for table exists      "
		    fnEcho ${LINENO} " calling function: 'fnDbQueryTestTableExists'      "	    
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} ""  
		    #        
		    fnDbQueryTestTableExists "$aws_service_snapshot_name_table_underscore"
		    #
		    #
		    # test for table exists
		    if [[ "$query_test_table_exists_results" = 't' ]]
		    	then 
				    #
				    fnEcho ${LINENO} ""  
				    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
				    fnEcho ${LINENO} " table already exists "
				    fnEcho ${LINENO} " table: "$db_schema"."$1" " 
				    fnEcho ${LINENO} " returning from function via the 'return' command " 				    
				    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
				    fnEcho ${LINENO} ""  
				    #          
		            return 
		            #
		        else 
				    #
				    fnEcho ${LINENO} ""
				    fnEcho ${LINENO} "table does not exist"
				    fnEcho ${LINENO} " table: "$db_schema"."$1" " 		    
				    fnEcho ${LINENO} ""
				    #       	
			fi # end check for table exists 
		    #
		    ##########################################################################
		    #
		    #
		    # display the header     
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} " display the header      "  
		    fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} ""  
		    #          
		    fnDisplayHeader
		    #
		    # display the task progress bar
		    #
		    fnDisplayProgressBarTask "$counter_aws_region_list" "$count_aws_region_list"
		    #
		    # display the sub-task progress bar
		    #
		    fnDisplayProgressBarTaskSub "$counter_aws_snapshot_commands" "$count_aws_snapshot_commands"
	        #
	        ##########################################################################
	        #
	        #
	        # display the subtask text      
	        #
	        fnEcho ${LINENO} ""  
	        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	        fnEcho ${LINENO} " display the subtask text       "  
	        fnEcho ${LINENO} " calling function 'fnDisplayTaskSubText'      "               
	        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	        fnEcho ${LINENO} ""  
	        #
	        fnDisplayTaskSubText
		    #
		    ##########################################################################
		    #
		    #
		    # display the AWS command variables       
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} " display the AWS command variables       "       
		    fnEcho ${LINENO} " calling function 'fnVariableNamesCommandDisplay'      "               
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} ""  
		    #          
			fnVariableNamesCommandDisplay
			#
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "value of variable 'aws_command_prior': "$aws_command_prior" " 
		    fnEcho ${LINENO} ""  
		    #
		    ##########################################################################
		    #
		    #
		    # begin load snapshot file into database
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} " begin load snapshot file into database   "
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} ""  
		    #   
		    #
		    # note: variable quoting is limited; not all psql variables can be full quoted 
		    #
		    # *********** begin load snapshot file into database **************
		    #
		    #
		    #
		    ##########################################################################
		    #
            #                                                                                                                            
		    ##########################################################################
		    #
		    #
		    # strip the line feeds from the snapshot json file 
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} " strip the line feeds from the snapshot json file     "
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} "debug command:"
   		    fnEcho ${LINENO} "cat "$write_file_full_path" | jq . | tr -d '\n' | tr -d '\\' | sed -e 's/\"\"/\"/g' > "$write_path_snapshots"/"$write_file_no_lf_file_name" "    
		    #      
		    feed_write_log="$(cat "$write_file_full_path" | jq . | tr -d '\n' | tr -d '\\' | sed -e 's/\"\"/\"/g' > "$write_path_snapshots"/"$write_file_no_lf_file_name" 2>&1)"
		        #
		        # check for command / pipeline error(s)
		        if [ "$?" -ne 0 ]
		            then
		                #
		                # set the command/pipeline error line number
		                error_line_pipeline="$((${LINENO}-7))"
		                #
		                #
		                fnEcho ${LINENO} level_0 ""
		                fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
		                fnEcho ${LINENO} level_0 "$feed_write_log"
		                fnEcho ${LINENO} level_0 ""
		                #
		                fnEcho ${LINENO} level_0 ""
		                fnEcho ${LINENO} level_0 "contents of file "$write_file_full_path":"
		                feed_write_log="$(cat "$write_file_full_path")"
		                fnEcho ${LINENO} level_0 "$feed_write_log"
		                fnEcho ${LINENO} level_0 ""                                                                                                                                          
		                #
		                fnEcho ${LINENO} level_0 ""
		                fnEcho ${LINENO} level_0 "$write_path_snapshots"/"$write_file_no_lf_file_name"":"
		                feed_write_log="$(cat "$write_path_snapshots"/"$write_file_no_lf_file_name")"
		                fnEcho ${LINENO} level_0 "$feed_write_log"
		                fnEcho ${LINENO} level_0 ""
		                #                                                                                                                            
		                # call the command / pipeline error function
		                fnErrorPipeline
		                #
		        #
		        fi
		        #
		    fnEcho ${LINENO} "$feed_write_log"
		    #
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "status of file "$write_path_snapshots"/"$write_file_no_lf_file_name":"
            feed_write_log="$(sudo ls -l "$write_path_snapshots"/"$write_file_no_lf_file_name")"
            fnEcho ${LINENO} "$feed_write_log"
            fnEcho ${LINENO} ""
            #
   		    # check for debug log 
		    if [[ "$logging" = 'z' ]] 
		        then 
		            fnEcho ${LINENO} ""
		            fnEcho ${LINENO} "--------------------------------------------------------------"
		            fnEcho ${LINENO} ""
		            fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
		            fnEcho ${LINENO} ""
		            fnEcho ${LINENO} "--------------------------------------------------------------"
		            fnEcho ${LINENO} "" 
		            fnEcho ${LINENO} ""
		            fnEcho ${LINENO} "value of variable 'pattern_load_feed':"
		            #                                                                                                                            	    
		            fnEcho ${LINENO} ""
		            fnEcho ${LINENO} "contents of file "$write_path_snapshots"/"$write_file_no_lf_file_name":"
		            feed_write_log="$(sudo cat "$write_path_snapshots"/"$write_file_no_lf_file_name")"
			        #
			        # check for command / pipeline error(s)
			        if [ "$?" -ne 0 ]
			            then
			                #
			                # set the command/pipeline error line number
			                error_line_pipeline="$((${LINENO}-7))"
			                #
			                #
			                fnEcho ${LINENO} level_0 ""
			                fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
			                fnEcho ${LINENO} level_0 "$feed_write_log"
			                fnEcho ${LINENO} level_0 ""
			                #
			                fnEcho ${LINENO} level_0 ""
				            fnEcho ${LINENO} level_0 ""
				            fnEcho ${LINENO} level_0 "contents of file "$write_path_snapshots"/"$write_file_no_lf_file_name":"
				            feed_write_log="$(sudo cat "$write_path_snapshots"/"$write_file_no_lf_file_name")"
			                fnEcho ${LINENO} level_0 ""
			                #                                                                                                                            
			                # call the command / pipeline error function
			                fnErrorPipeline
			                #
			        #
			        fi
			        #
		            fnEcho ${LINENO} "$feed_write_log"
		            fnEcho ${LINENO} ""
		    #
		    fi  # end check for debug log 
		    #

            #                                                                                                                            
		    ##########################################################################
		    #
		    #
		    # copy the snapshot json file to the postgresql directory 
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} " copy the snapshot json file to the postgresql directory    "
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} ""  
		    #
		    feed_write_log="$(sudo bash -c "cp "$write_path_snapshots"/"$write_file_no_lf_file_name" /pgdata/"$write_file_no_lf_file_name"" 2>&1)"
		        #
		        # check for command / pipeline error(s)
		        if [ "$?" -ne 0 ]
		            then
		                #
		                # set the command/pipeline error line number
		                error_line_pipeline="$((${LINENO}-7))"
		                #
		                #
		                fnEcho ${LINENO} level_0 ""
		                fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
		                fnEcho ${LINENO} level_0 "$feed_write_log"
		                fnEcho ${LINENO} level_0 ""
		                #
		                fnEcho ${LINENO} level_0 ""
		                fnEcho ${LINENO} level_0 ""$write_path_snapshots"/"$write_file_no_lf_file_name":"
		                feed_write_log="$(cat "$write_path_snapshots"/"$write_file_no_lf_file_name")"
		                fnEcho ${LINENO} level_0 "$feed_write_log"
		                fnEcho ${LINENO} level_0 ""
		                #                                                                                                                            
		                # call the command / pipeline error function
		                fnErrorPipeline
		                #
		        #
		        fi
		        #
		    fnEcho ${LINENO} "$feed_write_log"
		    #
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "status of file /pgdata/"$write_file_no_lf_file_name":"
            feed_write_log="$(sudo ls -l /pgdata/"$write_file_no_lf_file_name")"
            fnEcho ${LINENO} "$feed_write_log"
            fnEcho ${LINENO} ""
            #    
		    # check for debug log 
		    if [[ "$logging" = 'z' ]] 
		        then 
		            fnEcho ${LINENO} ""
		            fnEcho ${LINENO} "--------------------------------------------------------------"
		            fnEcho ${LINENO} ""
		            fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
		            fnEcho ${LINENO} ""
		            fnEcho ${LINENO} "--------------------------------------------------------------"
		            fnEcho ${LINENO} "" 
		            fnEcho ${LINENO} ""
		            fnEcho ${LINENO} "value of variable 'pattern_load_feed':"
		            #                                                                                                                            	    
		            fnEcho ${LINENO} ""
		            fnEcho ${LINENO} "contents of file /pgdata/"$write_file":"
		            feed_write_log="$(sudo cat /pgdata/"$write_file_no_lf_file_name")"
			        #
			        # check for command / pipeline error(s)
			        if [ "$?" -ne 0 ]
			            then
			                #
			                # set the command/pipeline error line number
			                error_line_pipeline="$((${LINENO}-7))"
			                #
			                #
			                fnEcho ${LINENO} level_0 ""
			                fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
			                fnEcho ${LINENO} level_0 "$feed_write_log"
			                fnEcho ${LINENO} level_0 ""
			                #
			                fnEcho ${LINENO} level_0 ""
			                fnEcho ${LINENO} level_0 "contents of file "$write_path_snapshots"/"$write_file_no_lf_file_name":"
			                feed_write_log="$(cat "$write_path_snapshots"/"$write_file_no_lf_file_name")"
			                fnEcho ${LINENO} level_0 "$feed_write_log"
			                fnEcho ${LINENO} level_0 ""
			                #                                                                                                                            
			                # call the command / pipeline error function
			                fnErrorPipeline
			                #
			        #
			        fi
			        #
		            fnEcho ${LINENO} "$feed_write_log"
		            fnEcho ${LINENO} ""
		    #
		    fi  # end check for debug log 
		    #
		    #
		    ##########################################################################
		    #
		    #
		    # set the file permissions to allow the database to read the file
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} " set the file permissions to allow the database to read the file     "
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} ""  
		    #      
		    feed_write_log="$(sudo bash -c "chmod 777 /pgdata/"$write_file_no_lf_file_name"" 2>&1)"
		        #
		        # check for command / pipeline error(s)
		        if [ "$?" -ne 0 ]
		            then
		                #
		                # set the command/pipeline error line number
		                error_line_pipeline="$((${LINENO}-7))"
		                #
		                #
		                fnEcho ${LINENO} level_0 ""
		                fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
		                fnEcho ${LINENO} level_0 "$feed_write_log"
		                fnEcho ${LINENO} level_0 ""
		                #
		                fnEcho ${LINENO} level_0 ""
		                fnEcho ${LINENO} level_0 "contents of file "$write_file_no_lf_file_name":"
		                feed_write_log="$(cat "$write_file_no_lf_file_name")"
		                fnEcho ${LINENO} level_0 "$feed_write_log"
		                fnEcho ${LINENO} level_0 ""
		                #                                                                                                                            
		                # call the command / pipeline error function
		                fnErrorPipeline
		                #
		        #
		        fi
		        #
		    fnEcho ${LINENO} "$feed_write_log"
		    #
		    #
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "status of file /pgdata/"$write_file_no_lf_file_name":"
            feed_write_log="$(sudo ls -l /pgdata/"$write_file_no_lf_file_name")"
            fnEcho ${LINENO} "$feed_write_log"
            fnEcho ${LINENO} ""
		    #
		    ##########################################################################
		    #
		    #
		    # create and load the table: "$db_schema"."$aws_service_snapshot_name_table_underscore_load" 
		    #
		    fnEcho ${LINENO} level_0 ""  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} level_0 " creating and loading the table: "$db_schema"."$aws_service_snapshot_name_table_underscore_load"      "
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} level_0 ""  
		    #        
		    # build the query variable
		    db_query_sql="psql \
		    --host="$db_host" \
		    --dbname="$db_name" \
		    --username="$db_user" \
		    --port="$db_port" \
		    --set ON_ERROR_STOP=on \
		    --echo-all \
		    --echo-errors \
		    --echo-queries \
		    --set AUTOCOMMIT=off" 
		    #
		    fnEcho ${LINENO} ""
		    fnEcho ${LINENO} "value of variable db_query_sql: "
		    fnEcho ${LINENO} "$db_query_sql"
		    fnEcho ${LINENO} ""
		    fnEcho ${LINENO} ""
		    #
		    #
		    # note: the following word "SQL" must stay left justified or it breaks the SQL feed   
		    # 
		    # execute the load query    
		    fnEcho ${LINENO} "running query: "
		    fnEcho ${LINENO} "DROP TABLE IF EXISTS "$db_schema"."$aws_service_snapshot_name_table_underscore_load";"
		    fnEcho ${LINENO} "CREATE TABLE "$db_schema"."$aws_service_snapshot_name_table_underscore_load"(id SERIAL PRIMARY KEY, data JSONB NOT NULL);"
		    fnEcho ${LINENO} "COPY "$db_schema".$aws_service_snapshot_name_table_underscore_load(data) FROM '/pgdata/$write_file_no_lf_file_name';"
		    fnEcho ${LINENO} "COMMIT;"
		    fnEcho ${LINENO} ""
		    #
		    query_load_snapshot_file="$($db_query_sql <<SQL
		    DROP TABLE IF EXISTS "$db_schema"."$aws_service_snapshot_name_table_underscore_load";
		    CREATE TABLE "$db_schema"."$aws_service_snapshot_name_table_underscore_load"(id SERIAL PRIMARY KEY, data JSONB NOT NULL);
		    COPY "$db_schema".$aws_service_snapshot_name_table_underscore_load(data) FROM '/pgdata/$write_file_no_lf_file_name';
		    COMMIT;
SQL
		    2>&1)"
		    #
		    #
		    # check for command / pipeline error(s)
		    if [ "$?" -eq 3 ]
		        then
		            #
		            # set the command/pipeline error line number
		            error_line_psql="$((${LINENO}-7))"
		            #
		            #
		            fnEcho ${LINENO} level_0 ""
		            fnEcho ${LINENO} level_0 "value of variable 'query_load_snapshot_file':"
		            fnEcho ${LINENO} level_0 "$query_load_snapshot_file"
		            fnEcho ${LINENO} level_0 ""
		            # call the psql error function
		            fnErrorPsql
		            #
		    #
		    fi
		    #
		    fnEcho ${LINENO} ""
		    fnEcho ${LINENO} "value of variable 'query_load_snapshot_file': "$query_load_snapshot_file" "
		    feed_write_log="$(echo "$query_load_snapshot_file"  2>&1)"
		    fnEcho ${LINENO} "$feed_write_log"
		    fnEcho ${LINENO} ""
		    #      
		    #
		    ##########################################################################
		    #
		    #
		    # testing for table create success
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} " testing for table create success      "
		    fnEcho ${LINENO} " calling function: 'fnDbQueryTestTableExists'      "	    
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} ""  
		    #        
		    fnDbQueryTestTableExists "$aws_service_snapshot_name_table_underscore_load"
		    #
		    # test for query create fail
		    if [[ "$query_test_table_exists_results" = 'f' ]]
		    	then 
				    #
				    fnEcho ${LINENO} level_0 ""  
				    fnEcho ${LINENO} level_0 "---------------------------------------------------------------------------------------------------------"  
				    fnEcho ${LINENO} level_0 " >> table create fail << "
				    fnEcho ${LINENO} level_0 " table: "$db_schema"."$1" " 
				    fnEcho ${LINENO} level_0 "---------------------------------------------------------------------------------------------------------"  
				    fnEcho ${LINENO} level_0 ""  
				    #          
		            # call the psql error function
		            fnErrorPsql
		            #
		        else 
				    #
				    fnEcho ${LINENO} ""
				    fnEcho ${LINENO} "table created successfully:"
				    fnEcho ${LINENO} " table: "$db_schema"."$1" " 		    
				    fnEcho ${LINENO} ""
				    #       	
			fi # end check for table create error 
		    #
		    ##########################################################################
		    #
		    #
		    # testing for table populate success
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} " testing for table populate success      "
		    fnEcho ${LINENO} " calling function: 'fnDbQueryTestTablePopulate'      "	    
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} ""  
		    #        
		    fnDbQueryTestTablePopulate "$aws_service_snapshot_name_table_underscore_load"
		    #
		    fnEcho ${LINENO} ""
		    fnEcho ${LINENO} "snapshot json file copy into load table "$db_schema"."$aws_service_snapshot_name_table_underscore_load" complete"
		    fnEcho ${LINENO} ""
		    # sudo bash -c "ls -l /pgdata/"$write_file"*"
		    #
		    #
		    ##########################################################################
		    #
		    #
		    # remove the 'no_lf' snapshot json files from the snapshot directory 
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} " remove the 'no_lf' snapshot json files from the snapshot directory     "
		    fnEcho ${LINENO} " deleting file: /"$write_path_snapshots"/"$write_file_no_lf_file_name"     "	    
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} ""  
		    #        
		    feed_write_log="$(rm -f /"$write_path_snapshots"/"$write_file_no_lf_file_name" 2>&1)"
		        #
		        # check for command / pipeline error(s)
		        if [ "$?" -ne 0 ]
		            then
		                #
		                # set the command/pipeline error line number
		                error_line_pipeline="$((${LINENO}-7))"
		                #
		                #
		                fnEcho ${LINENO} level_0 ""
		                fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
		                fnEcho ${LINENO} level_0 "$feed_write_log"
		                fnEcho ${LINENO} level_0 ""
		                # call the command / pipeline error function
		                fnErrorPipeline
		                #
		        #
		        fi
		        #
		    fnEcho ${LINENO} "$feed_write_log"
		    #
		    #
		    ##########################################################################
		    #
		    #
		    # create and load table "$db_schema"."$aws_service_snapshot_name_table_underscore_load" complete
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} " create and load table complete: "$db_schema"."$aws_service_snapshot_name_table_underscore_load"      "
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} ""  
		    #
		    ##########################################################################
		    #
		    #
		    # begin extract load table contents to snapshot table
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} " begin extract load table contents to snapshot table     "
		    fnEcho ${LINENO} " load table: "$db_schema"."$aws_service_snapshot_name_table_underscore_load"     "    
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} ""  
		    #        
		    # *********** begin extract load contents to snapshot table **************
		    #
		    fnEcho ${LINENO} ""
		    #
		    ##########################################################################
		    #
		    #
		    # test for recursive run; if recursive, skip to recursive load
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} " testing variable 'aws_command' for valid non-recursive command; if not, skip to recursive load     "
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} ""  
		    #        
		    #
		    fnEcho ${LINENO} ""
		    fnEcho ${LINENO} "value of variable aws_command: "$aws_command"  "
		    fnEcho ${LINENO} ""
		    fnEcho ${LINENO} ""
		    #
		    ##########################################################################
		    #
		    #
		    # test for valid non-recursive command      
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} " test for valid non-recursive command         "       
		    fnEcho ${LINENO} " calling function 'fnDbQueryNonRecursiveCommandTest'      "               
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} ""  
		    #          
		    fnDbQueryNonRecursiveCommandTest
		    #
		    # test query result
		    if [[ "$query_non_recursive_command_test" = "$aws_command"  ]]
		    	then 
	                fnEcho ${LINENO} ""
	                fnEcho ${LINENO} "command is a valid non-recursive command: "$aws_command"  "
	                fnEcho ${LINENO} ""
	                #
		            fnEcho ${LINENO} ""  
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} " this is a non-recursive run; loading non-recursive snapshot to table      "
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} ""     
					#
				    ##########################################################################
				    #
				    #
				    # test for a valid AWS service
				    #
				    fnEcho ${LINENO} ""  
				    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
				    fnEcho ${LINENO} " ' test for a valid AWS service    "
				    fnEcho ${LINENO} " ' calling function 'fnAwsServiceTestValid'    "			    
				    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
				    fnEcho ${LINENO} ""  
				    #        
				    fnAwsServiceTestValid
		            #
		            ##########################################################################
		            #
		            #
		            # build query variable 'db_query_sql' for extract the snapshot list key and execute the query
		            #
		            fnEcho ${LINENO} ""  
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} " build query variable 'db_query_sql' for extract the snapshot list key and execute the query    "
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} ""  
		            #        
		            # build the query variable
		            db_query_sql="psql \
		            --host="$db_host" \
		            --dbname="$db_name" \
		            --username="$db_user" \
		            --port="$db_port" \
		            --set ON_ERROR_STOP=on \
		            --echo-queries \
		            --set AUTOCOMMIT=off \
		            --tuples-only \
		            --no-align \
		            --quiet" 
		            #
		            fnEcho ${LINENO} ""
		            fnEcho ${LINENO} "value of variable db_query_sql: "
		            fnEcho ${LINENO} "$db_query_sql"
		            fnEcho ${LINENO} ""
		            fnEcho ${LINENO} ""
		            #
		            fnEcho ${LINENO} "extracting the snapshot list key"
		            #
		            fnEcho ${LINENO} "running the psql query: "
		            fnEcho ${LINENO} "psql --host=$db_host --dbname=$db_name --username=$db_user --port=$db_port --set ON_ERROR_STOP=on --set AUTOCOMMIT=off --tuples-only --no-align "
		            fnEcho ${LINENO} "SELECT jsonb_object_keys($aws_service_snapshot_name_table_underscore_load.data" 
		            fnEcho ${LINENO} "-> 'regions' -> 0 -> 'regionServices'-> 0 -> 'service' -> 0 "
		            fnEcho ${LINENO} "-> $aws_service_snapshot_name_underscore -> 0)"
		            fnEcho ${LINENO} "FROM $aws_service_snapshot_name_table_underscore_load;"
		            #
		            db_snapshot_list_key_return="$(psql \
		            --host="$db_host" \
		            --dbname="$db_name" \
		            --username="$db_user" \
		            --port="$db_port" \
		            --set ON_ERROR_STOP=on \
		            --echo-all \
		            --echo-errors \
		            --echo-queries \
		            --set AUTOCOMMIT=off \
		            --tuples-only \
		            --no-align \
		            --command="SELECT DISTINCT jsonb_object_keys("$db_schema"."$aws_service_snapshot_name_table_underscore_load".data -> 'regions' -> 0 -> 'regionServices'-> 0 -> 'service' -> 0 -> '$aws_service_snapshot_name_underscore' -> 0) FROM "$db_schema"."$aws_service_snapshot_name_table_underscore_load";" \
		            2>&1)"
		            #
		            #
		            # check for command / pipeline error(s)
		            if [ "$?" -eq 3 ]
		                then
		                    #
		                    # set the command/pipeline error line number
		                    error_line_psql="$((${LINENO}-7))"
		                    #
		                    #
		                    fnEcho ${LINENO} level_0 ""
		                    fnEcho ${LINENO} level_0 "value of variable 'db_snapshot_list_key_return':"
		                    fnEcho ${LINENO} level_0 "$db_snapshot_list_key_return"
		                    fnEcho ${LINENO} level_0 ""
				            # call the psql error function
		                    fnErrorPsql
		                    #
		            #
		            fi
		            #
		            fnEcho ${LINENO} ""
		            fnEcho ${LINENO} "value of variable 'db_snapshot_list_key_return': "$db_snapshot_list_key_return" "
		            feed_write_log="$(echo "$db_snapshot_list_key_return"  2>&1)"
		            fnEcho ${LINENO} "$feed_write_log"
		            fnEcho ${LINENO} ""
		            #      
		            # strip the query string
		            # use this if postgres option "--echo-query" is enabled
		            db_snapshot_list_key="$(echo "$db_snapshot_list_key_return" | tail -n +2 2>&1)"
		            #
		            # load the key
		            # use this if postgres option "--echo-query" is *not* enabled
		            # db_snapshot_list_key="$db_snapshot_list_key_return"
		            #
		            fnEcho ${LINENO} ""
		            fnEcho ${LINENO} "value of variable db_snapshot_list_key: "
		            fnEcho ${LINENO} "$db_snapshot_list_key"
		            fnEcho ${LINENO} ""
		            #
		            #
		            ##########################################################################
		            #
		            #
		            # write the query results to file: "$this_path_temp"/"$this_utility_acronym"-db_snapshot_list_key.txt
		            #
		            fnEcho ${LINENO} ""  
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} " write the query results to file: "$this_path_temp"/"$this_utility_acronym"-db_snapshot_list_key.txt    "
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} ""  
		            #          
		            feed_write_log="$(echo "$db_snapshot_list_key" > "$this_path_temp"/"$this_utility_acronym"-db_snapshot_list_key.txt 2>&1)"
		            #
		            # check for command / pipeline error(s)
		            if [ "$?" -ne 0 ]
		                then
		                    #
		                    # set the command/pipeline error line number
		                    error_line_pipeline="$((${LINENO}-7))"
		                    #
		                    #
		                    fnEcho ${LINENO} level_0 ""
		                    fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
		                    fnEcho ${LINENO} level_0 "$feed_write_log"
		                    fnEcho ${LINENO} level_0 ""
		                    #                                                                                                
		                    # call the command / pipeline error function
		                    fnErrorPipeline
		                    #
		            #
		            fi  # end check for pipeline error(s)        
		            #
		            fnEcho ${LINENO} "$feed_write_log"
		            fnEcho ${LINENO} ""
		            # 
		            #
		            fnEcho ${LINENO} ""
		            fnEcho ${LINENO} "counting variable db_snapshot_list_key "
		            count_db_snapshot_list_key="$(cat "$this_path_temp"/"$this_utility_acronym"-db_snapshot_list_key.txt | wc -l 2>&1)"
		            #
		            #
		            fnEcho ${LINENO} ""
		            fnEcho ${LINENO} "value of variable 'count_db_snapshot_list_key': "
		            fnEcho ${LINENO} "$count_db_snapshot_list_key"
		            fnEcho ${LINENO} ""
		            #
		            #
		            #
		            ##########################################################################
		            #
		            #
		            # running the single result test query
		            #
		            fnEcho ${LINENO} ""  
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} " running the single result test query for variable 'query_array_length'   "
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} ""  
		            #          
		            #
		            fnEcho ${LINENO} "SELECT jsonb_array_length(  "
		            fnEcho ${LINENO} "$aws_service_snapshot_name_table_underscore_load.data -> 'regions' -> 0 -> 'regionServices'-> 0 -> 'service'-> 0 -> $aws_service_snapshot_name_underscore -> 0 -> $db_snapshot_list_key   "
		            fnEcho ${LINENO} ") FROM $aws_service_snapshot_name_table_underscore_load ;" 
		            fnEcho ${LINENO} ""
		            #   
		            # empty the variable
		            query_array_length=""
		            #
		            # build the query variable
		            query_array_length="$(psql \
		            --host="$db_host" \
		            --dbname="$db_name" \
		            --username="$db_user" \
		            --port="$db_port" \
		            --set ON_ERROR_STOP=on \
		            --echo-errors \
		            --set AUTOCOMMIT=off \
		            --tuples-only \
		            --no-align \
		            --command="SELECT DISTINCT jsonb_array_length( "$db_schema"."$aws_service_snapshot_name_table_underscore_load".data -> 'regions' -> 0 -> 'regionServices'-> 0 -> 'service'-> 0 -> '$aws_service_snapshot_name_underscore' -> 0 -> '$db_snapshot_list_key' ) FROM "$db_schema"."$aws_service_snapshot_name_table_underscore_load" ;"    
		            2>&1)"
		            #
		            fnEcho ${LINENO} ""
		            fnEcho ${LINENO} "value of psql array length query exit code: "$?" "
		            fnEcho ${LINENO} ""
		            #
		            #
		            fnEcho ${LINENO} ""
		            fnEcho ${LINENO} "value of variable 'query_array_length':"
		            fnEcho ${LINENO} "$query_array_length" 
		            fnEcho ${LINENO} ""
		            #
		            #
		            ##########################################################################
		            #
		            #
		            # build query variable 'db_query_sql' to extract the snapshot values
		            #
		            fnEcho ${LINENO} ""  
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} " build query variable 'db_query_sql' to extract the snapshot values  "
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} ""  
		            #          
		            fnEcho ${LINENO} ""
		            # build the query variable
		            db_query_sql="psql \
		            --host="$db_host" \
		            --dbname="$db_name" \
		            --username="$db_user" \
		            --port="$db_port" \
		            --set ON_ERROR_STOP=on \
		            --echo-all \
		            --echo-queries \
		            --echo-errors \
		            --tuples-only \
		            --no-align \
		            --quiet" 
		            #
		            fnEcho ${LINENO} ""
		            fnEcho ${LINENO} "value of variable: 'db_query_sql': "
		            fnEcho ${LINENO} "$db_query_sql"
		            fnEcho ${LINENO} ""
		            #
		            #
		            ##########################################################################
		            #
		            #
		            # begin loop read: "$this_path_temp"/"$this_utility_acronym"-db_snapshot_list_key.txt
		            #
		            fnEcho ${LINENO} ""  
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} " begin loop read: "$this_path_temp"/"$this_utility_acronym"-db_snapshot_list_key.txt   "
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} ""  
		            #   
		            # clear match variable
					db_table_baseline_non_recursive_key_match='n' 
					#
		            fnEcho ${LINENO} "iterating through db_snapshot_list_key lines "
		            fnEcho ${LINENO} ""
		            while read -r db_snapshot_list_key_line 
		            do
		                #
		                fnEcho ${LINENO} ""
		                fnEcho ${LINENO} "-------------------------------------------------------------------------------------------------------------  "          
		                fnEcho ${LINENO} "--------------------------- loop head: "$this_path_temp"/"$this_utility_acronym"-db_snapshot_list_key.txt --------------------------  "
		                fnEcho ${LINENO} "-------------------------------------------------------------------------------------------------------------  "          
		                fnEcho ${LINENO} ""   
					    #
					    ##########################################################################
					    #
					    #
					    # value of variable 'db_snapshot_list_key_line' "$db_snapshot_list_key_line"    
					    #
					    fnEcho ${LINENO} ""  
					    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
					    fnEcho ${LINENO} " value of variable 'db_snapshot_list_key_line' "$db_snapshot_list_key_line"       "  
					    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
					    fnEcho ${LINENO} ""  
		                #
		                fnEcho ${LINENO} ""
		                fnEcho ${LINENO} "resetting target table name "
		                aws_service_snapshot_name_underscore="$aws_service_snapshot_name_underscore_base"
		                fnEcho ${LINENO} ""
		                # 
		                fnEcho ${LINENO} ""
		                fnEcho ${LINENO} "value of variable: 'db_snapshot_list_key_line': "
		                fnEcho ${LINENO} "$db_snapshot_list_key_line"
		                fnEcho ${LINENO} ""
		                # 
		                fnEcho ${LINENO} ""
		                fnEcho ${LINENO} "setting variable: 'db_snapshot_list_key_line_lower': "
		                db_snapshot_list_key_line_lower="$(echo "$db_snapshot_list_key_line" | tr '[:upper:]' '[:lower:]' 2>&1)"
		                fnEcho ${LINENO} "value of variable: 'db_snapshot_list_key_line_lower': "                
		                fnEcho ${LINENO} "$db_snapshot_list_key_line_lower"
		                fnEcho ${LINENO} ""
		                # 
		                fnEcho ${LINENO} ""
		                fnEcho ${LINENO} "value of variable: 'aws_snapshot_name': "
		                fnEcho ${LINENO} "$aws_snapshot_name"
		                fnEcho ${LINENO} ""
		                # 
		                fnEcho ${LINENO} ""
		                fnEcho ${LINENO} "testing for match on AWS CLI snapshot name and key; if match, create the baseline key table  "
		                if [[ "$aws_snapshot_name" = "$db_snapshot_list_key_line_lower"  ]]
		                	then 
					            #
					            ##########################################################################
					            #
					            #
					            # match on snapshot name and key:
					            # "$aws_snapshot_name" = "$db_snapshot_list_key_line_lower"
					            #
					            fnEcho ${LINENO} ""  
					            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
					            fnEcho ${LINENO} "match on snapshot name and key: "
					            fnEcho ${LINENO} ""$aws_snapshot_name" = "$db_snapshot_list_key_line_lower" " 
					            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
					            fnEcho ${LINENO} ""  
					            #    
					            # set match variable
					            db_table_baseline_non_recursive_key_match='y'      
					            #
					            ##########################################################################
					            #
					            #
					            # check for PostgreSQL reserved word for attribute name: "$aws_snapshot_name_underscore"
					            # calling function 'fnDbReservedWordsTest'
					            #
					            fnEcho ${LINENO} ""  
					            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
					            fnEcho ${LINENO} "check for PostgreSQL reserved word for attribute name: "$aws_snapshot_name_underscore" "
					            fnEcho ${LINENO} "calling function 'fnDbReservedWordsTest' " 
					            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
					            fnEcho ${LINENO} ""  
					            #    
					            fnDbReservedWordsTest   
								#
					            ##########################################################################
					            #
					            #
					            # creating and populating baseline key non-recursive table
					            #
					            fnEcho ${LINENO} level_0 ""  
					            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
					            fnEcho ${LINENO} " creating and populating baseline key non-recursive table "
					            fnEcho ${LINENO} level_0 " creating and loading table: "$db_schema"."$aws_service_snapshot_name_table_underscore" " 
					            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
					            fnEcho ${LINENO} level_0 ""  
					            #          
				                # execute the load query:
				                fnEcho ${LINENO} ""
				                fnEcho ${LINENO} "running the following query to extract the values from the load table "$db_schema"."$aws_service_snapshot_name_table_underscore_load": "
				                fnEcho ${LINENO} "DROP TABLE IF EXISTS "$db_schema"."$aws_service_snapshot_name_table_underscore";"
				                fnEcho ${LINENO} "CREATE TABLE "$db_schema"."$aws_service_snapshot_name_table_underscore"(id SERIAL PRIMARY KEY, "$aws_snapshot_name_underscore" JSONB NOT NULL);"
				                fnEcho ${LINENO} "INSERT INTO "$db_schema"."$aws_service_snapshot_name_table_underscore"("$aws_snapshot_name_underscore") "
				                fnEcho ${LINENO} "("
				                fnEcho ${LINENO} "	SELECT" 
				                fnEcho ${LINENO} "	  $aws_service_snapshot_name_underscore_base::jsonb" 
				                fnEcho ${LINENO} "	FROM" 
				                fnEcho ${LINENO} "	  $db_schema.$aws_service_snapshot_name_table_underscore_load t"
				                fnEcho ${LINENO} "	, jsonb_array_elements("
				                fnEcho ${LINENO} "	t.data -> 'regions' -> 0 -> 'regionServices' -> 0 -> 'service' -> 0 -> '$aws_service_snapshot_name_underscore_base' -> 0 -> '$db_snapshot_list_key_line"
				                # fnEcho ${LINENO} "	t.data -> 'regions' -> 0 -> 'regionServices' -> 0 -> 'service' -> 0 -> '$aws_service_snapshot_name_underscore_base' "
				                fnEcho ${LINENO} "	) as $aws_service_snapshot_name_underscore_base"
				                fnEcho ${LINENO} ")"
				                fnEcho ${LINENO} ";"
				                fnEcho ${LINENO} ""
				                #
				                #
				                # note: the following word "SQL" must stay left justified or it breaks the SQL feed    
				                #    
				                query_extract_load_contents="$($db_query_sql <<SQL
				                DROP TABLE IF EXISTS "$db_schema"."$aws_service_snapshot_name_table_underscore";
				                CREATE TABLE "$db_schema"."$aws_service_snapshot_name_table_underscore"(id SERIAL PRIMARY KEY, "$aws_snapshot_name_underscore" JSONB NOT NULL);
				                
				                /* 2018-03-13 this works for 'iam list users' and for 's3api list buckets' 
								*/				               
					                INSERT INTO "$db_schema"."$aws_service_snapshot_name_table_underscore"("$aws_snapshot_name_underscore") 
					                (
					                    SELECT 
					                      $aws_service_snapshot_name_underscore_base::jsonb 
					                    FROM 
					                      "$db_schema".$aws_service_snapshot_name_table_underscore_load t
					                    , jsonb_array_elements(
					                    t.data -> 'regions' -> 0 -> 'regionServices' -> 0 -> 'service' -> 0 -> '$aws_service_snapshot_name_underscore_base' -> 0 -> '$db_snapshot_list_key_line'
					                    ) as $aws_service_snapshot_name_underscore_base 
					                )
					                ;
				                /*
				                */
				                
				                /* 2018-03-13 this improperly loads the table (one row) for 'iam list users' and errors out for 's3api list buckets'

				                INSERT INTO "$db_schema"."$aws_service_snapshot_name_table_underscore"("$aws_snapshot_name_underscore") 
				                (
				                    SELECT 
				                      $aws_service_snapshot_name_underscore_base::jsonb 
				                    FROM 
				                      "$db_schema".$aws_service_snapshot_name_table_underscore_load t
				                    , jsonb_array_elements(
				                    t.data -> 'regions' -> 0 -> 'regionServices' -> 0 -> 'service' -> 0 -> '$aws_service_snapshot_name_underscore_base' 
				                    ) as $aws_service_snapshot_name_underscore_base 
				                )
				                ;
				                
				                */
SQL
				                2>&1)"
				                #
				                #
				                # check for command / pipeline error(s)
				                if [ "$?" -eq 3 ]
				                    then
				                        #
				                        # set the command/pipeline error line number
				                        error_line_psql="$((${LINENO}-7))"
				                        #
				                        #
				                        fnEcho ${LINENO} level_0 ""
				                        fnEcho ${LINENO} level_0 "value of variable 'query_extract_load_contents':"
				                        fnEcho ${LINENO} level_0 "$query_extract_load_contents"
				                        fnEcho ${LINENO} level_0 ""
							            # call the psql error function
				                        fnErrorPsql
				                        #
				                #
				                fi
				                #
				                #
				                fnEcho ${LINENO} ""
				                fnEcho ${LINENO} "value of variable 'query_extract_load_contents': "$query_extract_load_contents" "
				                feed_write_log="$(echo "$query_extract_load_contents"  2>&1)"
				                fnEcho ${LINENO} "$feed_write_log"
				                fnEcho ${LINENO} ""
				                #  
				                #   
							    ##########################################################################
							    #
							    #
							    # testing for table create success
							    #
							    fnEcho ${LINENO} ""  
							    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
							    fnEcho ${LINENO} " testing for table create success      "
							    fnEcho ${LINENO} " calling function: 'fnDbQueryTestTableExists'      "	    
							    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
							    fnEcho ${LINENO} ""  
							    #        
							    fnDbQueryTestTableExists "$aws_service_snapshot_name_table_underscore"
							    #
							    # test for query create fail
							    if [[ "$query_test_table_exists_results" = 'f' ]]
							    	then 
									    #
									    fnEcho ${LINENO} level_0 ""  
									    fnEcho ${LINENO} level_0 "---------------------------------------------------------------------------------------------------------"  
									    fnEcho ${LINENO} level_0 " >> table create fail << "
									    fnEcho ${LINENO} level_0 " table: "$db_schema"."$1" " 
									    fnEcho ${LINENO} level_0 "---------------------------------------------------------------------------------------------------------"  
									    fnEcho ${LINENO} level_0 ""  
									    #          
							            # call the psql error function
							            fnErrorPsql
							            #
							        else 
									    #
									    fnEcho ${LINENO} ""
									    fnEcho ${LINENO} "table created successfully:"
									    fnEcho ${LINENO} " table: "$db_schema"."$1" " 		    
									    fnEcho ${LINENO} ""
									    #       	
								fi # end check for table create error 
							    #
							    ##########################################################################
							    #
							    #
							    # testing for table populate success
							    #
							    fnEcho ${LINENO} ""  
							    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
							    fnEcho ${LINENO} " testing for table populate success      "
							    fnEcho ${LINENO} " calling function: 'fnDbQueryTestTablePopulate'      "	    
							    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
							    fnEcho ${LINENO} ""  
							    #        
							    fnDbQueryTestTablePopulate "$aws_service_snapshot_name_table_underscore"
							    #
			                else
					            fnEcho ${LINENO} ""  
					            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
					            fnEcho ${LINENO} "no match on snapshot name and key: "
					            fnEcho ${LINENO} ""$aws_snapshot_name" = "$db_snapshot_list_key_line_lower" " 
					            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
					            fnEcho ${LINENO} ""  
					            #
					    #
		                fi # end testing for match on AWS CLI snapshot name and key   
		                fnEcho ${LINENO} ""
		                fnEcho ${LINENO} "-------------------------------------------------------------------------------------------------------------  "          
		                fnEcho ${LINENO} "--------------------------- loop tail: "$this_path_temp"/"$this_utility_acronym"-db_snapshot_list_key.txt --------------------------  "
		                fnEcho ${LINENO} "-------------------------------------------------------------------------------------------------------------  "          
		                fnEcho ${LINENO} ""   
		                #       
		            #
		            done< <(cat "$this_path_temp"/"$this_utility_acronym"-db_snapshot_list_key.txt)
		            #
		            #
		            ##########################################################################
		            #
		            #
		            # end loop read: "$this_path_temp"/"$this_utility_acronym"-db_snapshot_list_key.txt 
		            #
		            fnEcho ${LINENO} ""  
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} " end loop read: "$this_path_temp"/"$this_utility_acronym"-db_snapshot_list_key.txt   "
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} ""  
		            #   
	                #
	                fnEcho ${LINENO} ""
	                fnEcho ${LINENO} "value of variable 'db_table_baseline_non_recursive_key_match': "$db_table_baseline_non_recursive_key_match" "
	                fnEcho ${LINENO} ""
	                #
		            if [[ "$db_table_baseline_non_recursive_key_match" != 'y'  ]]
		            	then 
				            #
				            ##########################################################################
				            #
				            #
				            # no match on snapshot name and key
				            #
				            fnEcho ${LINENO} ""  
				            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
				            fnEcho ${LINENO} "no match on snapshot name and key "
				            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
				            fnEcho ${LINENO} ""  
				            #
				            ##########################################################################
				            #
				            #
				            # creating and populating baseline non-recursive table
				            #
				            fnEcho ${LINENO} level_0 ""  
				            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
				            fnEcho ${LINENO} " creating and populating baseline non-recursive table "
				            fnEcho ${LINENO} level_0 " creating and loading table: "$db_schema"."$aws_service_snapshot_name_table_underscore" " 
				            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
				            fnEcho ${LINENO} level_0 ""  
				            #          
			                # execute the load query:
			                fnEcho ${LINENO} ""
			                fnEcho ${LINENO} "running the following query to extract the values from the load table "$db_schema"."$aws_service_snapshot_name_table_underscore_load": "
			                fnEcho ${LINENO} "DROP TABLE IF EXISTS "$db_schema"."$aws_service_snapshot_name_table_underscore";"
			                fnEcho ${LINENO} "CREATE TABLE "$db_schema"."$aws_service_snapshot_name_table_underscore"(id SERIAL PRIMARY KEY, "$aws_snapshot_name_underscore" JSONB NOT NULL);"
			                fnEcho ${LINENO} "INSERT INTO "$db_schema"."$aws_service_snapshot_name_table_underscore"("$aws_snapshot_name_underscore") "
			                fnEcho ${LINENO} "("
			                fnEcho ${LINENO} "SELECT" 
			                fnEcho ${LINENO} "$aws_service_snapshot_name_underscore_base::jsonb" 
			                fnEcho ${LINENO} "FROM" 
			                fnEcho ${LINENO} ""$db_schema".$aws_service_snapshot_name_table_underscore_load t"
			                fnEcho ${LINENO} ", jsonb_array_elements("
			                fnEcho ${LINENO} "t.data -> 'regions' -> 0 -> 'regionServices' -> 0 -> 'service' -> 0 -> '$aws_service_snapshot_name_underscore_base' -> 0 -> $db_snapshot_list_key_line"
			                fnEcho ${LINENO} ") as $aws_service_snapshot_name_underscore_base"
			                fnEcho ${LINENO} ")"
			                fnEcho ${LINENO} ";"
			                fnEcho ${LINENO} "COMMIT;"
			                fnEcho ${LINENO} ""
			                #
			                #
			                # note: the following word "SQL" must stay left justified or it breaks the SQL feed    
			                #    
			                query_extract_load_contents="$($db_query_sql <<SQL
			                DROP TABLE IF EXISTS "$db_schema"."$aws_service_snapshot_name_table_underscore";
			                CREATE TABLE "$db_schema"."$aws_service_snapshot_name_table_underscore"(id SERIAL PRIMARY KEY, "$aws_snapshot_name_underscore" JSONB NOT NULL);
			                INSERT INTO "$db_schema"."$aws_service_snapshot_name_table_underscore"("$aws_snapshot_name_underscore") 
			                (
			                    SELECT 
			                      $aws_service_snapshot_name_underscore_base::jsonb 
			                    FROM 
			                      "$db_schema".$aws_service_snapshot_name_table_underscore_load t
			                    , jsonb_array_elements(
			                    t.data -> 'regions' -> 0 -> 'regionServices' -> 0 -> 'service' -> 0 -> '$aws_service_snapshot_name_underscore_base' 
			                    ) as $aws_service_snapshot_name_underscore_base 
			                )
			                ;
			                COMMIT;
SQL
			                2>&1)"
			                #
			                #
			                # check for command / pipeline error(s)
			                if [ "$?" -eq 3 ]
			                    then
			                        #
			                        # set the command/pipeline error line number
			                        error_line_psql="$((${LINENO}-7))"
			                        #
			                        #
			                        fnEcho ${LINENO} level_0 ""
			                        fnEcho ${LINENO} level_0 "value of variable 'query_extract_load_contents':"
			                        fnEcho ${LINENO} level_0 "$query_extract_load_contents"
			                        fnEcho ${LINENO} level_0 ""
						            # call the psql error function
			                        fnErrorPsql
			                        #
			                #
			                fi
			                #
			                #
			                fnEcho ${LINENO} ""
			                fnEcho ${LINENO} "value of variable 'query_extract_load_contents': "$query_extract_load_contents" "
			                feed_write_log="$(echo "$query_extract_load_contents"  2>&1)"
			                fnEcho ${LINENO} "$feed_write_log"
			                fnEcho ${LINENO} ""
			                #
						    ##########################################################################
						    #
						    #
						    # testing for table create success
						    #
						    fnEcho ${LINENO} ""  
						    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
						    fnEcho ${LINENO} " testing for table create success      "
						    fnEcho ${LINENO} " calling function: 'fnDbQueryTestTableExists'      "	    
						    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
						    fnEcho ${LINENO} ""  
						    #        
						    fnDbQueryTestTableExists "$aws_service_snapshot_name_table_underscore"
						    #
						    # test for query create fail
						    if [[ "$query_test_table_exists_results" = 'f' ]]
						    	then 
								    #
								    fnEcho ${LINENO} level_0 ""  
								    fnEcho ${LINENO} level_0 "---------------------------------------------------------------------------------------------------------"  
								    fnEcho ${LINENO} level_0 " >> table create fail << "
								    fnEcho ${LINENO} level_0 " table: "$db_schema"."$1" " 
								    fnEcho ${LINENO} level_0 "---------------------------------------------------------------------------------------------------------"  
								    fnEcho ${LINENO} level_0 ""  
								    #          
						            # call the psql error function
						            fnErrorPsql
						            #
						        else 
								    #
								    fnEcho ${LINENO} ""
								    fnEcho ${LINENO} "table created successfully:"
								    fnEcho ${LINENO} " table: "$db_schema"."$1" " 		    
								    fnEcho ${LINENO} ""
								    #       	
							fi # end check for table create error 
						    #
						    ##########################################################################
						    #
						    #
						    # testing for table populate success
						    #
						    fnEcho ${LINENO} ""  
						    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
						    fnEcho ${LINENO} " testing for table populate success      "
						    fnEcho ${LINENO} " calling function: 'fnDbQueryTestTablePopulate'      "	    
						    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
						    fnEcho ${LINENO} ""  
						    #        
						    fnDbQueryTestTablePopulate "$aws_service_snapshot_name_table_underscore"
						    #
					#
				    fi # end check of no key match 
				    #
		            #
		            ##########################################################################
		            #
		            #
		            # end non-recursive baseline table section 
		            #
		            fnEcho ${LINENO} ""  
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} " end non-recursive baseline table section    "
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} ""  
			        #
	            else 
	                fnEcho ${LINENO} ""
	                fnEcho ${LINENO} "command is not a valid non-recursive command; processing as a recursive command "
	                fnEcho ${LINENO} ""
		        	#
		            fnEcho ${LINENO} ""  
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} " this is a recursive run; loading recursive snapshot to table      "
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} ""          
		            #
		            ##########################################################################
		            #
		            #
		            # begin recursive command snapshot load to table "$aws_service_snapshot_name_table_underscore" 
		            #
		            fnEcho ${LINENO} ""  
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} begin recursive command snapshot load to table "$aws_service_snapshot_name_table_underscore" 
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} ""  
		            #
		            #
		            ##########################################################################
		            #
		            #
		            # load recursive table: "$aws_service_snapshot_name_table_underscore"
		            #
		            fnEcho ${LINENO} level_0 ""  
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} level_0 " loading recursive table: "$aws_service_snapshot_name_table_underscore"  "
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} level_0 ""  
		            #   
		            fnEcho ${LINENO} ""  
		            fnEcho ${LINENO} "testing for recursive parameter  "
		            fnEcho ${LINENO} ""  
		            fnEcho ${LINENO} "testing for empty AWS CLI command parameter_01; if not empty, load the table "   
		            fnEcho ${LINENO} ""
		            fnEcho ${LINENO} "value of variable 'aws_command': "$aws_command" " 
		            fnEcho ${LINENO} "value of variable 'aws_command_underscore': "$aws_command_underscore" "      
		            fnEcho ${LINENO} "value of variable 'aws_command_parameter_01': "$aws_command_parameter_01" "  
		            fnEcho ${LINENO} "value of variable 'aws_command_parameter_01_value': "$aws_command_parameter_01_value" "  
		        	fnEcho ${LINENO} "value of variable 'aws_snapshot_name_underscore': "$aws_snapshot_name_underscore" "  
			        fnEcho ${LINENO} "value of variable 'db_schema': "$db_schema" "  
			        fnEcho ${LINENO} "value of variable 'aws_service_snapshot_name_table_underscore_load': "$aws_service_snapshot_name_table_underscore_load" "  
			        fnEcho ${LINENO} "value of variable 'aws_service_snapshot_name_table_underscore': "$aws_service_snapshot_name_table_underscore" "  
			       	fnEcho ${LINENO} "value of variable 'aws_service_snapshot_name_underscore_base': "$aws_service_snapshot_name_underscore_base" "  
		            fnEcho ${LINENO} ""
		            fnEcho ${LINENO} ""   
			        #
				    ##########################################################################
				    #
				    #
				    # test for valid recursive command      
				    #
				    fnEcho ${LINENO} ""  
				    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
				    fnEcho ${LINENO} " test for valid recursive command         "       
				    fnEcho ${LINENO} " calling function 'fnDbQueryRecursiveCommandTest'      "               
				    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
				    fnEcho ${LINENO} ""  
				    #          
				    fnDbQueryRecursiveCommandTest
				    #
				    #
				    fnEcho ${LINENO} ""  
				    fnEcho ${LINENO} " value of variable 'query_recursive_command_test': "$query_recursive_command_test"         "       
				    fnEcho ${LINENO} " value of variable 'aws_command': "$aws_command"         "       
				    fnEcho ${LINENO} ""  
				    #          
				    # test recursive command query test result
				    if [[ "$query_recursive_command_test" = "$aws_command" ]]
				    	then 
		                    fnEcho ${LINENO} ""
		                    fnEcho ${LINENO} ""$query_recursive_command_test" = "$aws_command""   		                    
		                    fnEcho ${LINENO} "this is a valid recursive command, loading the table "   
		                    fnEcho ${LINENO} ""
		                    # execute the load query:
		                    fnEcho ${LINENO} ""
		                    fnEcho ${LINENO} "running the following query to extract the values from the load table "$db_schema"."$aws_service_snapshot_name_table_underscore_load": "
		                    fnEcho ${LINENO} "DROP TABLE IF EXISTS "$db_schema"."$aws_service_snapshot_name_table_underscore";"
		                    fnEcho ${LINENO} "CREATE TABLE "$db_schema"."$aws_service_snapshot_name_table_underscore"(id SERIAL PRIMARY KEY, "$aws_snapshot_name_underscore" JSONB NOT NULL);"
		                    fnEcho ${LINENO} "INSERT INTO "$db_schema"."$aws_service_snapshot_name_table_underscore"("$aws_snapshot_name_underscore") "
		                    fnEcho ${LINENO} "("
		                    fnEcho ${LINENO} "SELECT" 
		                    fnEcho ${LINENO} "$aws_service_snapshot_name_underscore_base::jsonb" 
		                    fnEcho ${LINENO} "FROM" 
		                    fnEcho ${LINENO} ""$db_schema".$aws_service_snapshot_name_table_underscore_load t"
		                    fnEcho ${LINENO} ", jsonb_array_elements("
		                    fnEcho ${LINENO} "t.data -> 'regions' -> 0 -> 'regionServices' -> 0 -> 'service' -> 0 -> '$aws_service_snapshot_name_underscore_base'" 
		                    fnEcho ${LINENO} ") as $aws_service_snapshot_name_underscore_base"
		                    fnEcho ${LINENO} ")"
		                    fnEcho ${LINENO} ";"
		                    fnEcho ${LINENO} "COMMIT;"
		                    fnEcho ${LINENO} ""
		                    #
		                    #
		                    # note: the following word "SQL" must stay left justified or it breaks the SQL feed    
		                    #    
		                    query_extract_load_contents="$($db_query_sql <<SQL
		                    DROP TABLE IF EXISTS "$db_schema"."$aws_service_snapshot_name_table_underscore";
		                    CREATE TABLE "$db_schema"."$aws_service_snapshot_name_table_underscore"(id SERIAL PRIMARY KEY, "$aws_snapshot_name_underscore" JSONB NOT NULL);
		                    INSERT INTO "$db_schema"."$aws_service_snapshot_name_table_underscore"("$aws_snapshot_name_underscore") 
		                    (
		                        SELECT 
		                          $aws_service_snapshot_name_underscore_base::jsonb 
		                        FROM 
		                          "$db_schema".$aws_service_snapshot_name_table_underscore_load t
		                        , jsonb_array_elements(
		                        t.data -> 'regions' -> 0 -> 'regionServices' -> 0 -> 'service' -> 0 -> '$aws_service_snapshot_name_underscore_base' 
		                        ) as $aws_service_snapshot_name_underscore_base 
		                    )
		                    ;
		                    COMMIT;
SQL
		                    2>&1)"
		                    #
		                    #
		                    # check for command / pipeline error(s)
		                    if [ "$?" -eq 3 ]
		                        then
		                            #
		                            # set the command/pipeline error line number
		                            error_line_psql="$((${LINENO}-7))"
		                            #
		                            #
		                            fnEcho ${LINENO} level_0 ""
		                            fnEcho ${LINENO} level_0 "value of variable 'query_extract_load_contents':"
		                            fnEcho ${LINENO} level_0 "$query_extract_load_contents"
		                            fnEcho ${LINENO} level_0 ""
						            # call the psql error function
		                            fnErrorPsql
		                            #
		                    #
		                    fi
		                    #
		                    #
		                    fnEcho ${LINENO} ""
		                    fnEcho ${LINENO} "value of variable 'query_extract_load_contents': "$query_extract_load_contents" "
		                    feed_write_log="$(echo "$query_extract_load_contents"  2>&1)"
		                    fnEcho ${LINENO} "$feed_write_log"
		                    fnEcho ${LINENO} ""
			                #
						    ##########################################################################
						    #
						    #
						    # testing for table create success
						    #
						    fnEcho ${LINENO} ""  
						    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
						    fnEcho ${LINENO} " testing for table create success      "
						    fnEcho ${LINENO} " calling function: 'fnDbQueryTestTableExists'      "	    
						    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
						    fnEcho ${LINENO} ""  
						    #        
						    fnDbQueryTestTableExists "$aws_service_snapshot_name_table_underscore"
						    #
						    # test for query create fail
						    if [[ "$query_test_table_exists_results" = 'f' ]]
						    	then 
								    #
								    fnEcho ${LINENO} level_0 ""  
								    fnEcho ${LINENO} level_0 "---------------------------------------------------------------------------------------------------------"  
								    fnEcho ${LINENO} level_0 " >> table create fail << "
								    fnEcho ${LINENO} level_0 " table: "$db_schema"."$1" " 
								    fnEcho ${LINENO} level_0 "---------------------------------------------------------------------------------------------------------"  
								    fnEcho ${LINENO} level_0 ""  
								    #          
						            # call the psql error function
						            fnErrorPsql
						            #
						        else 
								    #
								    fnEcho ${LINENO} ""
								    fnEcho ${LINENO} "table created successfully:"
								    fnEcho ${LINENO} " table: "$db_schema"."$1" " 		    
								    fnEcho ${LINENO} ""
								    #       	
							fi # end check for table create error 
						    #
						    ##########################################################################
						    #
						    #
						    # testing for table populate success
						    #
						    fnEcho ${LINENO} ""  
						    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
						    fnEcho ${LINENO} " testing for table populate success      "
						    fnEcho ${LINENO} " calling function: 'fnDbQueryTestTablePopulate'      "	    
						    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
						    fnEcho ${LINENO} ""  
						    #        
						    fnDbQueryTestTablePopulate "$aws_service_snapshot_name_table_underscore"
						    #
			            else 
			                fnEcho ${LINENO} ""
		                    fnEcho ${LINENO} ""$query_recursive_command_test" != "$aws_command""  			                
			                fnEcho ${LINENO} "command is not a valid recursive command; not processing command "
			                fnEcho ${LINENO} ""
			        fi # end test of query results  
		            #
		            ##########################################################################
		            #
		            #
		            # end recursive command snapshot load to table "$aws_service_snapshot_name_table_underscore" 
		            #
		            fnEcho ${LINENO} ""  
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} "end recursive command snapshot load to table "$aws_service_snapshot_name_table_underscore" "
		            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		            fnEcho ${LINENO} ""  
		            #
		    fi # 
		else
            #
            ##########################################################################
            #
            #
            # source snapshot JSON file or table name does not exist; not loading the file to the PostgreSQL database " 
            #
		    fnEcho ${LINENO} ""  
            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} "source snapshot JSON file or table name does not exist; not loading the file to the PostgreSQL database   "
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "source snapshot JSON file: "$write_file_full_path" " 
		    fnEcho ${LINENO} "write file stripped - used to load the table: "$write_file_no_lf_file_name" " 
		    fnEcho ${LINENO} "table: "$aws_service_snapshot_name_table_underscore" "
		    fnEcho ${LINENO} "service: "$aws_service" "
		    fnEcho ${LINENO} "command: "$aws_command" "
		    fnEcho ${LINENO} "command prior: "$aws_command_prior" "
            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} ""  
            #
            ##########################################################################
            #
            #
            # deleting unused source file stripped of line feeds and special characters 
            #
            fnEcho ${LINENO} ""  
            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
            fnEcho ${LINENO} "deleting unused source file stripped of line feeds and special characters "
		    fnEcho ${LINENO} "deleting: "$write_file_no_lf_file_name" "            
            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
            fnEcho ${LINENO} ""  
            #
		    feed_write_log="$(rm -f "$write_path_snapshots"/"$write_file_no_lf_file_name" 2>&1)"
		    #
		    # check for command / pipeline error(s)
		    if [ "$?" -ne 0 ]
		        then
		            #
		            # set the command/pipeline error line number
		            error_line_pipeline="$((${LINENO}-7))"
		            #
		            #
		            fnEcho ${LINENO} level_0 ""
		            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
		            fnEcho ${LINENO} level_0 "$feed_write_log"
		            fnEcho ${LINENO} level_0 ""
		            #                                                                                                
		            # call the command / pipeline error function
		            fnErrorPipeline
		            #
		    #
		    fi  # end check for pipeline error(s)        
		    #
		    fnEcho ${LINENO} "$feed_write_log"
		    fnEcho ${LINENO} ""
		    #
		    #
		    feed_write_log="$(sudo rm -f /pgdata/"$write_file_no_lf_file_name" 2>&1)"
		        #
		        # check for command / pipeline error(s)
		        if [ "$?" -ne 0 ]
		            then
		                #
		                # set the command/pipeline error line number
		                error_line_pipeline="$((${LINENO}-7))"
		                #
		                #
		                fnEcho ${LINENO} level_0 ""
		                fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
		                fnEcho ${LINENO} level_0 "$feed_write_log"
		                fnEcho ${LINENO} level_0 ""
		                # call the command / pipeline error function
		                fnErrorPipeline
		                #
		        #
		        fi
		        #
		    fnEcho ${LINENO} "$feed_write_log"
		    #
		    #
		    #
		    fnEcho ${LINENO} ""
		    fnEcho ${LINENO} "load finished"
		    fnEcho ${LINENO} ""
		    #
	fi # end test for snapshot JSON file
	#
    ##########################################################################
    #
    #
    # display the header     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " display the header      "  
    fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
    fnDisplayHeader
    #
    # display the task progress bar
    #
    fnDisplayProgressBarTask "$counter_aws_region_list" "$count_aws_region_list"
    #
    # display the sub-task progress bar
    #
    fnDisplayProgressBarTaskSub "$counter_aws_snapshot_commands" "$count_aws_snapshot_commands"
    #
    ##########################################################################
    #
    #
    # display the subtask text      
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " display the subtask text       "  
    fnEcho ${LINENO} " calling function 'fnDisplayTaskSubText'      "               
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    fnDisplayTaskSubText
    #
    ##########################################################################
    #
    #
    # end load snapshot file into database
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end load snapshot file into database     "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #        
    ##########################################################################
    #
    #
    # end function 'fnDbLoadSnapshotFile'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnDbLoadSnapshotFile'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
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
    ##########################################################################
    #
    #
    # begin function 'fnPatternLoad'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnPatternLoad'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #              
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnPatternLoad' "
    fnEcho ${LINENO} ""
    #       
    #
    # check for debug log 
    if [[ "$logging" = 'z' ]] 
        then 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} "" 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "value of variable 'pattern_load_feed':"
            feed_write_log="$(echo "$pattern_load_feed" 2>&1)"
            fnEcho ${LINENO} "$feed_write_log"
            fnEcho ${LINENO} ""
    #
    fi  # end check for debug log 
    #
    #
    fnEcho ${LINENO} "loading variable 'pattern_load_value' with JSON pattern and inserted service snapshot " 
    fnEcho ${LINENO} "using variables: 'pattern_load_feed' / "aws_account" / "aws_region_list_line_parameter" / "aws_service" / "aws_service_snapshot_name_underscore" "       
    fnEcho ${LINENO} "using variables: 'pattern_load_feed' / "$aws_account" / "$aws_region_list_line_parameter" / "$aws_service" / "$aws_service_snapshot_name_underscore" "
    # the built-up AWS service is put into the following structure as an array at the position of the '.' 
    pattern_load_value="$(echo "$pattern_load_feed" \
    | jq -s --arg aws_account_jq "$aws_account" --arg aws_region_list_line_parameter_jq "$aws_region_list_line_parameter" --arg aws_service_jq "$aws_service" --arg aws_service_snapshot_name_underscore_jq "$aws_service_snapshot_name_underscore" '{ account: $aws_account_jq, regions: [ { regionName: $aws_region_list_line_parameter_jq, regionServices: [ { serviceType: $aws_service_jq, service: [ { ($aws_service_snapshot_name_underscore_jq): . } ] } ] } ] }' 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'pattern_load_value':"
            fnEcho ${LINENO} level_0 "$pattern_load_value"
            fnEcho ${LINENO} level_0 ""
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
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} "" 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "value of variable 'pattern_load_value':"
            feed_write_log="$(echo "$pattern_load_value" 2>&1)"
            fnEcho ${LINENO} "$feed_write_log"
            fnEcho ${LINENO} ""
    #     
    fi  # end check for debug log 
    #
    #
    #
    ##########################################################################
    #
    #
    # end function 'fnPatternLoad'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnPatternLoad'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
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
    ##########################################################################
    #
    #
    # begin function 'fnInitializeWriteFileBuildPattern'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnInitializeWriteFileBuildPattern'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #              
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnInitializeWriteFileBuildPattern' "
    fnEcho ${LINENO} ""
    #       
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "Function-specific variables: "  
    fnEcho ${LINENO} "------------------------------------------------"  
    fnEcho ${LINENO} "value of variable 'file_target_initialize_region':"
    fnEcho ${LINENO} "$file_target_initialize_region"
    fnEcho ${LINENO} ""
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'file_target_initialize_file':"
    fnEcho ${LINENO} "$file_target_initialize_file"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "------------------------------------------------"  
    fnEcho ${LINENO} ""
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "Non-function specific variables: "    
    fnEcho ${LINENO} "------------------------------------------------"  
    fnEcho ${LINENO} "value of variable 'aws_account':"
    fnEcho ${LINENO} "$aws_account"
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_service':"
    fnEcho ${LINENO} "$aws_service"
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_service_snapshot_name_underscore':"
    fnEcho ${LINENO} "$aws_service_snapshot_name_underscore"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "------------------------------------------------"  
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading the pattern"
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
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                                                                
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi  # end check for pipeline error(s)        
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # end function 'fnInitializeWriteFileBuildPattern'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnInitializeWriteFileBuildPattern'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
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
    ##########################################################################
    #
    #
    # begin function 'fnInitializeWriteFileBuild'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnInitializeWriteFileBuild'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                  
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnInitializeWriteFileBuild' "
    fnEcho ${LINENO} ""
    #       
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "in the function: 'fnInitializeWriteFileBuild' - initialize target data file for service writes  "  
    fnEcho ${LINENO} "initializing the data file "   
    #
    file_target_initialize_region="$aws_region_list_line_parameter"
    file_target_initialize_file="$this_utility_acronym"-write-file-build.json
    #
    # calling function to initialize the output file 
    fnInitializeWriteFileBuildPattern
    # 

    # feed_write_log="$(echo "{ \"account\": \"$aws_account\",\"regions\": [ { \"regionName\": \"$aws_region_list_line_parameter\",\"regionServices\": [ { \"serviceType\": \"$aws_service\",\"service\": [ ] } ] } ] }" > "$this_path_temp"/"$this_utility_acronym"-write-file-build.json  2>&1)"

    #
    fnEcho ${LINENO} "Contents of file: "$this_utility_acronym"-write-file-build.json"
    fnEcho ${LINENO} ""  
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
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"-write-file-build.json:"
            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-build.json)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                                                                            
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # end function 'fnInitializeWriteFileBuild'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnInitializeWriteFileBuild'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                      
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
    ##########################################################################
    #
    #
    # begin function 'fnWriteCommandFileRecursive'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnWriteCommandFileRecursive'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                      
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnWriteCommandFileRecursive' "
    fnEcho ${LINENO} ""
    #        
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "Appending the recursive-command JSON snapshot for: "$aws_service" "$aws_command" "$aws_command_parameter_01" "$aws_command_parameter_01_value" "
    #
    #
    #
    ##########################################################################
    #
    #
    # load the source and target JSON files
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " load the source and target JSON files "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading file: "$this_utility_acronym"-snapshot_recursive_source.json from variable 'service_snapshot' "
    #
    feed_write_log="$(echo "$service_snapshot" > "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_source.json 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #        
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"-snapshot_recursive_source.json :"
            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_source.json)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                                                                                                             
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi  # end check for pipeline error(s)        
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #
    #
    # check for debug log 
    if [[ "$logging" = 'z' ]] 
        then 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} "" 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "contents of file "$this_utility_acronym"-snapshot_recursive_source.json :"
            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_source.json)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"-snapshot_recursive_source.json :"
                    feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_source.json)"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #                                         
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
                    #
            fi
            #
            fnEcho ${LINENO} "$feed_write_log"
            fnEcho ${LINENO} ""              
        #     
    fi  # end check for debug log 
    #                                    
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""   
    fnEcho ${LINENO} "loading file: "$this_utility_acronym"-snapshot_recursive_target_build.json from variable 'snapshot_source_recursive_command' "
    feed_write_log="$(echo "$snapshot_source_recursive_command" > "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_target_build.json  2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #        
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"-snapshot_recursive_target_build.json :"
            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_target_build.json)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                         
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi  # end check for pipeline error(s)        
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #
    #
    # check for debug log 
    if [[ "$logging" = 'z' ]] 
        then 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} "" 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "contents of file "$this_utility_acronym"-snapshot_recursive_target_build.json :"
            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_target_build.json)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"-snapshot_recursive_target_build.json :"
                    feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_target_build.json)"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #                                         
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
                    #
            fi
            #
            fnEcho ${LINENO} "$feed_write_log"
            fnEcho ${LINENO} ""
    #     
    fi  # end check for debug log 
    #                                       
    fnEcho ${LINENO} ""
    #
    #
    #
    ##########################################################################
    #
    #
    # call the array merge recursive command function  
    # parameters are: source target 
    # output file name of the function is: "$this_utility_acronym"-merge-services-file-build-temp.json
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " call the array merge recursive command function "
    fnEcho ${LINENO} " parameters are: source target  "
    fnEcho ${LINENO} " output file name of the function is: "$this_utility_acronym"-merge-services-file-build-temp.json "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "calling function: 'fnMergeArraysServicesRecursiveJsonFile' with parameters: "
    fnEcho ${LINENO} "source:"
    fnEcho ${LINENO} ""$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_source.json"
    fnEcho ${LINENO} ""      
    fnEcho ${LINENO} "target:"
    fnEcho ${LINENO} ""$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_target_build.json"
    fnEcho ${LINENO} ""
    #
    fnMergeArraysServicesRecursiveJsonFile "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_source.json "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_target_build.json
    #
    #    
    #
    #
    ##########################################################################
    #
    #
    # Copying contents of file: "$this_utility_acronym"-merge-services-recursive-file-build-temp.json to file: "$this_utility_acronym"-snapshot_recursive_target.json
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " Copying contents of file: "$this_utility_acronym"-merge-services-recursive-file-build-temp.json to file: "$this_utility_acronym"-snapshot_recursive_target.json "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""  
    cp -f "$this_path_temp"/"$this_utility_acronym"-merge-services-recursive-file-build-temp.json "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_target.json
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    #
    # check for debug log 
    if [[ "$logging" = 'z' ]] 
        then 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} "" 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "Contents of file: "$this_utility_acronym"-snapshot_recursive_target.json "
            fnEcho ${LINENO} ""  
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
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"-snapshot_recursive_target.json:"
                    feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_target.json)"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #                                         
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
                    #
            fi
            #
            fnEcho ${LINENO} "$feed_write_log"
            fnEcho ${LINENO} ""
    #     
    fi  # end check for debug log 
    #                                         
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # loading variable 'snapshot_target_recursive_command' with the contents of file: "$this_utility_acronym"-snapshot_recursive_target.json
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " loading variable 'snapshot_target_recursive_command' with the contents of file: "$this_utility_acronym"-snapshot_recursive_target.json "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
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
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'snapshot_target_recursive_command':"
            fnEcho ${LINENO} level_0 "$snapshot_target_recursive_command"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"-snapshot_recursive_target.json :"
            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot_recursive_target.json)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
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
                    fnEcho ${LINENO} ""
                    fnEcho ${LINENO} "--------------------------------------------------------------"
                    fnEcho ${LINENO} ""
                    fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                    fnEcho ${LINENO} ""
                    fnEcho ${LINENO} "--------------------------------------------------------------"
                    fnEcho ${LINENO} "" 
                    fnEcho ${LINENO} ""
                    fnEcho ${LINENO} ""
                    fnEcho ${LINENO} ""
                    fnEcho ${LINENO} "value of variable 'snapshot_target_recursive_command':"
                    fnEcho ${LINENO} "$snapshot_target_recursive_command"
                    fnEcho ${LINENO} ""
                #     
            fi  # end check for debug log 
            #                                         
    #
    ##########################################################################
    #
    #
    # end function 'fnWriteCommandFileRecursive'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnWriteCommandFileRecursive'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
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
    ##########################################################################
    #
    #
    # begin function 'fnErrorLog'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnErrorLog'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                      
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnErrorLog' "
    fnEcho ${LINENO} ""
    #       
    fnEcho ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------"       
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 " Error message: "
    fnEcho ${LINENO} level_0 " "$1""
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------" 
    echo "-----------------------------------------------------------------------------------------------------" >> "$this_log_file_errors_full_path"         
    echo "" >> "$this_log_file_errors_full_path" 
    echo " Error message: " >> "$this_log_file_errors_full_path" 
    echo " "$1"" >> "$this_log_file_errors_full_path" 
    echo "" >> "$this_log_file_errors_full_path"
    echo "-----------------------------------------------------------------------------------------------------" >> "$this_log_file_errors_full_path" 
    #
    ##########################################################################
    #
    #
    # end function 'fnErrorLog'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnErrorLog'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                      
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
    ##########################################################################
    #
    #
    # begin function 'fnErrorPipeline'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnErrorPipeline'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                          
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnErrorPipeline' "
    fnEcho ${LINENO} ""
    #       
    fnEcho ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------"       
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 " Command or Command Pipeline Error "
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 " System Error while running the previous command or pipeline "
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 " Please check the error message above "
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 " Error at script line number: "$error_line_pipeline" "
    fnEcho ${LINENO} level_0 ""
    if [[ ("$logging" = "y") || ("$logging" = "z") ]] 
        then 
            fnEcho ${LINENO} level_0 " The log will also show the error message and other environment, variable and diagnostic information "
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 " The log is located here: "
            fnEcho ${LINENO} level_0 " "$this_log_file_full_path" "
    fi
    fnEcho ${LINENO} level_0 ""        
    fnEcho ${LINENO} level_0 " Exiting the script"
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} level_0 ""
    # append the temp log onto the log file
    fnFileAppendLogTemp
    # write the log variable to the log file
    fnFileAppendLog
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
    ##########################################################################
    #
    #
    # begin function 'fnErrorAws'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnErrorAws'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                          
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnErrorAws' "
    fnEcho ${LINENO} ""
    #       
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 " AWS Error while executing AWS CLI command"
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 " Please check the AWS error message above "
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 " Error at script line number: "$error_line_aws" "
    fnEcho ${LINENO} level_0 ""
    if [[ ("$logging" = "y") || ("$logging" = "z") ]]
        then 
            fnEcho ${LINENO} level_0 " The log will also show the AWS error message and other diagnostic information "
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 " The log is located here: "
            fnEcho ${LINENO} level_0 " "$write_path"/ "
            fnEcho ${LINENO} level_0 " "$this_log_file" "
    fi 
    fnEcho ${LINENO} level_0 ""        
    fnEcho ${LINENO} level_0 " Exiting the script"
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} level_0 ""
    # append the temp log onto the log file
    fnFileAppendLogTemp
    # write the log variable to the log file
    fnFileAppendLog
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
    ##########################################################################
    #
    #
    # begin function 'fnErrorJq'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnErrorJq'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                              
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnErrorJq' "
    fnEcho ${LINENO} ""
    #    
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 " Error at script line number: "$error_line_jq" "
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 " There was a jq error while processing JSON "
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 " Please check the jq error message above "
    fnEcho ${LINENO} level_0 ""
    if [[ ("$logging" = "y") || ("$logging" = "z") ]]
        then 
            fnEcho ${LINENO} level_0 " The log will also show the AWS error message and other diagnostic information "
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 " The log is located here: "
            fnEcho ${LINENO} level_0 " "$write_path"/ "
            fnEcho ${LINENO} level_0 " "$this_log_file" "
    fi
    fnEcho ${LINENO} level_0 " The log will also show the jq error message and other diagnostic information "
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 " The log is located here: "
    fnEcho ${LINENO} level_0 " "$this_log_file_full_path" "
    fnEcho ${LINENO} level_0 ""        
    fnEcho ${LINENO} level_0 " Exiting the script"
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} level_0 ""
    # append the temp log onto the log file
    fnFileAppendLogTemp
    # write the log variable to the log file
    fnFileAppendLog
    exit 1
}
#
##########################################################################
#
#
# function for psql errors 
#
function fnErrorPsql()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnErrorPsql'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnErrorPsql'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                              
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnErrorPsql' "
    fnEcho ${LINENO} ""
    #    
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 " Error at script line number: "$error_line_psql" "
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 " There was a psql error while querying the database "
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 " Please check the psql error message above "
    fnEcho ${LINENO} level_0 ""
    if [[ ("$logging" = "y") || ("$logging" = "z") ]]
        then 
            fnEcho ${LINENO} level_0 " The log will also show the AWS error message and other diagnostic information "
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 " The log is located here: "
            fnEcho ${LINENO} level_0 " "$write_path"/ "
            fnEcho ${LINENO} level_0 " "$this_log_file" "
    fi
    fnEcho ${LINENO} level_0 " The log will also show the psql error message and other diagnostic information "
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 " The log is located here: "
    fnEcho ${LINENO} level_0 " "$this_log_file_full_path" "
    fnEcho ${LINENO} level_0 ""        
    fnEcho ${LINENO} level_0 " Exiting the script"
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} level_0 ""
    # append the temp log onto the log file
    fnFileAppendLogTemp
    # write the log variable to the log file
    fnFileAppendLog
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
    ##########################################################################
    #
    #
    # begin function 'fnCounterIncrementSnapshots'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnCounterIncrementSnapshots'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                              
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnCounterIncrementSnapshots' "
    fnEcho ${LINENO} ""
    #      
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "increment the snapshots counter: 'counter_snapshots'"
    counter_snapshots="$((counter_snapshots+1))"
    fnEcho ${LINENO} "post-increment value of variable 'counter_snapshots': "$counter_snapshots" "
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # end function 'fnCounterIncrementSnapshots'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnCounterIncrementSnapshots'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                              
}
#
##########################################################################
#
#
# function to increment the AWS snapshot commands counter 
#
function fnCounterIncrementAwsSnapshotCommands()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnCounterIncrementAwsSnapshotCommands'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnCounterIncrementAwsSnapshotCommands'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                              
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnCounterIncrementAwsSnapshotCommands' "
    fnEcho ${LINENO} ""
    #      
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "increment the snapshots counter: 'counter_snapshots'"
    counter_aws_snapshot_commands="$((counter_aws_snapshot_commands+1))"
    fnEcho ${LINENO} ""    
    fnEcho ${LINENO} "post-increment value of variable 'counter_snapshots': "$counter_snapshots" "
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # end function 'fnCounterIncrementAwsSnapshotCommands'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnCounterIncrementAwsSnapshotCommands'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
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
    ##########################################################################
    #
    #
    # begin function 'fnCounterIncrementTask'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnCounterIncrementTask'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                              
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnCounterIncrementTask' "
    fnEcho ${LINENO} ""
    #      
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "incrementing the task counter"
    counter_this_file_tasks="$((counter_this_file_tasks+1))" 
    fnEcho ${LINENO} "value of variable 'counter_this_file_tasks': "$counter_this_file_tasks" "
    fnEcho ${LINENO} "value of variable 'count_this_file_tasks': "$count_this_file_tasks" "
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # end function 'fnCounterIncrementTask'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnCounterIncrementTask'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                              
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
    ##########################################################################
    #
    #
    # begin function 'fnCounterIncrementRegions'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnCounterIncrementRegions'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                              
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnCounterIncrementRegions' "
    fnEcho ${LINENO} ""
    #      
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "increment the regions counter: 'counter_aws_region_list'"
    # check to preven overrun due to initial value of 1
    if [[ "$counter_aws_region_list" -lt "$count_aws_region_list" ]]
    	then 
		    counter_aws_region_list="$((counter_aws_region_list+1))"
    fi # end check for region increment 
    fnEcho ${LINENO} "post-increment value of variable 'counter_aws_region_list': "$counter_aws_region_list" "
    fnEcho ${LINENO} "value of variable 'count_aws_region_list': "$count_aws_region_list" "
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # end function 'fnCounterIncrementRegions'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnCounterIncrementRegions'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
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
    ##########################################################################
    #
    #
    # begin function 'fnDuplicateRemoveSnapshottedServices'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnDuplicateRemoveSnapshottedServices'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                              
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnDuplicateRemoveSnapshottedServices' "
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'write_file_service_names': "
    fnEcho ${LINENO} "$this_path_temp"/"$write_file_service_names"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "contents of file "$this_path_temp"/"$write_file_service_names" prior to unique: " 
    feed_write_log="$(cat "$this_path_temp"/"$write_file_service_names" 2>&1)"
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading variable 'write_file_service_names_unique' "
    write_file_service_names_unique="$(cat "$this_path_temp"/"$write_file_service_names" | sort -u)"
    fnEcho ${LINENO} "value of variable 'write_file_service_names_unique': "
    fnEcho ${LINENO} "$write_file_service_names_unique"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "writing unique list to file: ${!write_file_service_names} " 
    feed_write_log="$(echo "$write_file_service_names_unique" > "$this_path_temp"/"$write_file_service_names" 2>&1)"
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "contents of file "$this_path_temp"/"$write_file_service_names" after unique: " 
    feed_write_log="$(cat "$this_path_temp"/"$write_file_service_names" 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$write_file_service_names":"
                feed_write_log="$(cat "$this_path_temp"/"$write_file_service_names")"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #                                                                                                                            
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
    fnEcho ${LINENO} "$feed_write_log"
    #
    ##########################################################################
    #
    #
    # end function 'fnDuplicateRemoveSnapshottedServices'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnDuplicateRemoveSnapshottedServices'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                              
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
    ##########################################################################
    #
    #
    # begin function 'fnAwsPullSnapshots'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnAwsPullSnapshots'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                                  
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnAwsPullSnapshots' "
    fnEcho ${LINENO} ""
    #       
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "---------------------------------------- begin pull the snapshots ---------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # display the header     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " display the header      "  
    fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
    fnDisplayHeader
    #
    #
    #
    fnEcho ${LINENO} "reset the task counter variable 'counter_driver_services' "
    counter_driver_services=0
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading the variable 'region_fn_AWS_pull_snapshots' from the function parameter 1: "$1" "  
    aws_region_list_line_parameter=$1
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'region_fn_AWS_pull_snapshots': "$aws_region_list_line_parameter" "  
    fnEcho ${LINENO} "" 
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} " in section: pull the snapshots"
    fnEcho ${LINENO} "------------------------------------------------"  
    fnEcho ${LINENO} "value of variable 'aws_account':"
    fnEcho ${LINENO} "$aws_account"
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_service':"
    fnEcho ${LINENO} "$aws_service"
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_service_snapshot_name_underscore':"
    fnEcho ${LINENO} "$aws_service_snapshot_name_underscore"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "------------------------------------------------"  
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # pulling the non-recursive snapshots 
    # calling function: 'fnAwsPullSnapshotsNonRecursive'    
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " pulling the non-recursive snapshots   "
    fnEcho ${LINENO} " calling function: 'fnAwsPullSnapshotsNonRecursive'  "   
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    fnAwsPullSnapshotsNonRecursive
    #
    ##########################################################################
    #
    #
    # setting variable 'driver_aws_cli_commands_recursive_single_file_name' to 'driver-aws-cli-commands-recursive-single.txt'
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " setting variable 'driver_aws_cli_commands_recursive_single_file_name' to "$file_snapshot_driver_aws_cli_commands_recursive_single_file_name" "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    driver_aws_cli_commands_recursive_single_file_name="$file_snapshot_driver_aws_cli_commands_recursive_single_file_name"
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " value of variable 'driver_aws_cli_commands_recursive_single_file_name': "$driver_aws_cli_commands_recursive_single_file_name"   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    ##########################################################################
    #
    #
    # pulling the recursive single snapshots
    # calling function: 'fnAwsPullSnapshotsRecursiveSingle'    
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " pulling the recursive single snapshots   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    # check for empty queries file; if empty, no run
    # count the queries
    count_queries_recursive_single="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name" | grep -v '^$' | wc -l 2>&1)"
    # 
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " value of variable 'count_queries_recursive_single': "$count_queries_recursive_single"   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    if [[ "$count_queries_recursive_single" -gt 0 ]]
    	then 
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} " available queries so pulling the recursive single snapshots    "
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} " calling function: 'fnAwsPullSnapshotsRecursiveSingle'  "   
		    fnEcho ${LINENO} ""  
		    #
		    fnAwsPullSnapshotsRecursiveSingle
		    #
    	else 
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} " no available queries so not pulling the recursive single snapshots    "
		    fnEcho ${LINENO} ""  
    fi # end check for empty queries file
    #
    #
    ##########################################################################
    #
    # placeholder for functions to pull snapshots for:
    # * recursive hardcoded
    # * recursive multi
    #
    ##########################################################################
    #
    #
    # pulling the recursive single dependent snapshots
    # calling function: 'fnAwsPullSnapshotsRecursiveSingleDependent'    
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " pulling the recursive single dependent snapshots   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
	# check for empty queries file; if empty, no run
    # count the queries
    count_queries_recursive_single_dependent="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name" | grep -v '^$' | wc -l 2>&1)"
    # 
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " value of variable 'count_queries_recursive_single_dependent': "$count_queries_recursive_single_dependent"   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    if [[ "$count_queries_recursive_single_dependent" -gt 0 ]]
    	then 
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} " available queries so pulling the recursive single dependent snapshots    "
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} " calling function: 'fnAwsPullSnapshotsRecursiveSingleDependent'  "   
		    fnEcho ${LINENO} ""  
		    #
		    fnAwsPullSnapshotsRecursiveSingleDependent
		else 
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} " no available queries so not pulling the recursive single dependent snapshots    "
		    fnEcho ${LINENO} ""  
    fi # end check for empty queries file
    #
    #
    #
    ##########################################################################
    #
    # placeholder for functions to pull snapshots for:
    # * recursive multi dependent
    #
    ##########################################################################
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "task 'pull the snapshots' complete "
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    #
    #       
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------- end pull the snapshots -----------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # end function 'fnAwsPullSnapshots'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnAwsPullSnapshots'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                                  
}
#
##########################################################################
#
#
# function to pull the non-recursive snapshots from AWS    
#
function fnAwsPullSnapshotsNonRecursive()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnAwsPullSnapshotsNonRecursive'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnAwsPullSnapshotsNonRecursive'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                                  
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnAwsPullSnapshotsNonRecursive' "
    fnEcho ${LINENO} ""
    #       
    #
    ##########################################################################
    ##########################################################################
    #
    #
    # entering the non-recursive section 
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " testing for source table run  " 
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
	#
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} " value of variable 'snapshot_type': "$snapshot_type"   " 
    fnEcho ${LINENO} ""  
    #
    # test for recursive source table run 
    if [[ "$snapshot_type" != 'source-recursive' ]]
    	then 
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} " variable 'snapshot_type' != 'source-recursive'   " 
		    fnEcho ${LINENO} " setting the snapshot type variable 'snapshot_type' to 'non-recursive'   " 
		    snapshot_type='non-recursive'
		    #
		else 
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} " variable 'snapshot_type' = 'source-recursive'   " 
			#				    
	fi # end test for recursive source table run 
	#
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} " value of variable 'snapshot_type': "$snapshot_type"   " 
    fnEcho ${LINENO} ""  
	#
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} " value of variable 'file_snapshot_driver_stripped_file_name':"
    fnEcho ${LINENO} ""$file_snapshot_driver_stripped_file_name"   " 
    fnEcho ${LINENO} ""    
    #
    fnEcho ${LINENO} ""                
    fnEcho ${LINENO} "Contents of file: "$this_path_temp"/"$file_snapshot_driver_stripped_file_name" "
    fnEcho ${LINENO} ""  
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_stripped_file_name"  2>&1)"
    #  check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_stripped_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_stripped_file_name")"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                         
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi  # end pipeline error check 
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""                
    #
    ##########################################################################
    #
    #
    # set the count of AWS snapshot commands variable 'count_aws_snapshot_commands' with variable 'count_driver_services'
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " set the count of AWS snapshot commands variable 'count_aws_snapshot_commands' with variable 'count_driver_services'  "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    count_aws_snapshot_commands="$count_driver_services"
    #
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} " value of variable 'count_aws_snapshot_commands': "$count_aws_snapshot_commands"   " 
    fnEcho ${LINENO} ""      
    #
    ##########################################################################
    #
    #
    # pulling the non-recursive snapshots
    # calling function: 'fnAwsPullSnapshotsLoop'    
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " pulling the non-recursive snapshots   "
    fnEcho ${LINENO} " calling function: 'fnAwsPullSnapshotsLoop'  "   
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    fnAwsPullSnapshotsLoop
    #
    #
    #
    ##########################################################################
    #
    #
    # end function 'fnAwsPullSnapshotsNonRecursive'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnAwsPullSnapshotsNonRecursive'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                                  
}
#
##########################################################################
#
#
# function to pull the recursive single snapshots from AWS    
#
function fnAwsPullSnapshotsRecursiveSingle()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnAwsPullSnapshotsRecursiveSingle'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnAwsPullSnapshotsRecursiveSingle'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                                  
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnAwsPullSnapshotsRecursiveSingle' "
    fnEcho ${LINENO} ""
    #       
    #
    ##########################################################################
    ##########################################################################
    #
    #
    # entering the recursive-single section 
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " entering the recursive-single section   " 
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} " setting the recursive run type variable 'recursive_single_yn' to 'y'   " 
    recursive_single_yn='y'
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} " value of variable 'recursive_single_yn': "$recursive_single_yn"   " 
    fnEcho ${LINENO} ""  
    #
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} " setting the snapshot type variable 'snapshot_type' to 'recursive-single'   " 
    snapshot_type='recursive-single'
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} " value of variable 'snapshot_type': "$snapshot_type"   " 
    fnEcho ${LINENO} ""  
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'file_snapshot_driver_stripped_file_name':"
    fnEcho ${LINENO} "$file_snapshot_driver_stripped_file_name"
    fnEcho ${LINENO} ""
    #
    #
    fnEcho ${LINENO} ""                
    fnEcho ${LINENO} "Contents of file: "$this_path_temp"/"$file_snapshot_driver_stripped_file_name" "
    fnEcho ${LINENO} ""  
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_stripped_file_name"  2>&1)"
    #  check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_stripped_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_stripped_file_name")"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                         
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi  # end pipeline error check 
    #
    fnEcho ${LINENO} "$feed_write_log" 
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # loading variable 'services_driver_list' from file "$file_snapshot_driver_stripped_file_name"
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " loading variable 'services_driver_list' from file "$file_snapshot_driver_stripped_file_name"   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    # 
    services_driver_list="$(cat "$this_path_temp"/"$file_snapshot_driver_stripped_file_name"  2>&1)"
    #  check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'services_driver_list':"
            fnEcho ${LINENO} level_0 "$services_driver_list"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_stripped_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_stripped_file_name")"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                         
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi  # end pipeline error check 
    #
    #
    # check for debug log 
    if [[ "$logging" = 'z' ]] 
        then 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} "" 
            fnEcho ${LINENO} ""                             
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------------------------------------------"
            fnEcho ${LINENO} "value of variable 'services_driver_list':"
            fnEcho ${LINENO} "$services_driver_list"
            fnEcho ${LINENO} "--------------------------------------------------------------------------------------------------"
            fnEcho ${LINENO} ""
    #     
    fi  # end check for debug log 
    #                           
    ##########################################################################
    #
    #
    # pulling the recursive single snapshots
    # calling function: 'fnAwsPullSnapshotsRecursiveLoop'    
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " pulling the recursive single snapshots   "
    fnEcho ${LINENO} " calling function: 'fnAwsPullSnapshotsRecursiveLoop'  "   
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    fnAwsPullSnapshotsRecursiveLoop
    #
    ##########################################################################
    #
    #
    # recursive single snapshots complete
    # resetting variable 'recursive_single_yn'   
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " recursive single snapshots complete   "
    fnEcho ${LINENO} " resetting variable 'recursive_single_yn'  "   
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} " setting the recursive run type variable 'recursive_single_yn' to 'n'   " 
    recursive_single_yn='n'
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} " value of variable 'recursive_single_yn': "$recursive_single_yn"   " 
    fnEcho ${LINENO} ""  
    #
    #
    #
    ##########################################################################
    #
    #
    # end function 'fnAwsPullSnapshotsRecursiveSingle'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnAwsPullSnapshotsRecursiveSingle'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                                  
}
#
##########################################################################
#
#
# function to pull the recursive single dependent snapshots from AWS    
#
function fnAwsPullSnapshotsRecursiveSingleDependent()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnAwsPullSnapshotsRecursiveSingleDependent'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnAwsPullSnapshotsRecursiveSingleDependent'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnAwsPullSnapshotsRecursiveSingleDependent' "
    fnEcho ${LINENO} ""
    #       
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "------------------------------ begin pull the recursive single dependent snapshots ------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # setting variable 'driver_aws_cli_commands_recursive_single_file_name' to 'driver-aws-cli-commands-recursive-single-dependent.txt'
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " setting variable 'driver_aws_cli_commands_recursive_single_file_name' to 'driver-aws-cli-commands-recursive-single-dependent.txt'"
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    driver_aws_cli_commands_recursive_single_file_name='driver-aws-cli-commands-recursive-single-dependent.txt'
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " value of variable 'driver_aws_cli_commands_recursive_single_file_name': "$driver_aws_cli_commands_recursive_single_file_name"   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    #
    ##########################################################################
    #
    #
    # pulling the recursive single snapshots
    # calling function: 'fnAwsPullSnapshotsRecursiveSingle'    
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " pulling the recursive single snapshots   "
    fnEcho ${LINENO} " calling function: 'fnAwsPullSnapshotsRecursiveSingle'  "   
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    fnAwsPullSnapshotsRecursiveSingle
    #       
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "------------------------------- end pull the recursive single dependent snapshots -------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # end function 'fnAwsPullSnapshotsRecursiveSingleDependent'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnAwsPullSnapshotsRecursiveSingleDependent'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                                  
}
#
##########################################################################
#
#
# function to pull the non-recursive snapshots from AWS    
#
function fnAwsPullSnapshotsLoop()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnAwsPullSnapshotsLoop'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnAwsPullSnapshotsLoop'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnAwsPullSnapshotsLoop' "
    fnEcho ${LINENO} ""
    #       
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "--------------------------------- begin pull the non-recursive snapshots ---------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # display the header     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " display the header      "  
    fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
    fnDisplayHeader
    #
    # display the task progress bar
    #
    fnDisplayProgressBarTask "$counter_aws_region_list" "$count_aws_region_list"
    #
    # display the sub task progress bar
    #
    fnDisplayProgressBarTaskSub "$counter_aws_snapshot_commands" "$count_aws_snapshot_commands"
    #
	fnEcho ${LINENO} level_0 ""  
	fnEcho ${LINENO} level_0 "Please wait..."  
	fnEcho ${LINENO} level_0 ""  
    #
    ##########################################################################
    #
    #
    # check for debug log
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " check for debug log  "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    # check for debug log 
    if [[ "$logging" = 'z' ]] 
        then 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} "" 
            fnEcho ${LINENO} ""                             
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------------------------------------------"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "value of variable 'services_driver_list':"
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
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 "value of variable 'services_driver_list':"
                        fnEcho ${LINENO} level_0 "$services_driver_list"
                        fnEcho ${LINENO} level_0 ""
                        # call the command / pipeline error function
                        fnErrorPipeline
                        #
                #
                fi
                #
            fnEcho ${LINENO} "$feed_write_log"
            fnEcho ${LINENO} "--------------------------------------------------------------------------------------------------"
            fnEcho ${LINENO} ""
    #     
    fi  # end check for debug log 
    #                       
    #
    #
    ##########################################################################
    #
    #
    # non-recursive
    # begin loop read: variable 'services_driver_list'
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " non-recursive   "    
    fnEcho ${LINENO} " begin loop read: variable 'services_driver_list'   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #      
    while read -r aws_service aws_command aws_command_parameter_01 aws_command_parameter_01_value aws_command_parameter_02 aws_command_parameter_02_value aws_command_parameter_03 aws_command_parameter_03_value aws_command_parameter_04 aws_command_parameter_04_value aws_command_parameter_05 aws_command_parameter_05_value aws_command_parameter_06 aws_command_parameter_06_value aws_command_parameter_07 aws_command_parameter_07_value aws_command_parameter_08 aws_command_parameter_08_value
    do
 	    #
	    ##########################################################################
	    #
	    #
	    # check for empty line or parameter_01; skip if empty      
	    #
	    fnEcho ${LINENO} ""  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} " check for empty line or parameter_01; skip if empty       "       
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} "" 
   	    #      
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of AWS command variables: 'aws_service' 'aws_command' 'aws_command_parameter_01' 'aws_command_parameter_01_value' "
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of AWS command variables: "$aws_service" "$aws_command" "$aws_command_parameter_01" "$aws_command_parameter_01_value" "
        fnEcho ${LINENO} ""         
	    #          
	    # check the command line 
        if [[ ("$aws_service" = '') || ("$aws_command_parameter_01" != '') ]]
            then
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "line is empty or non-empty parameter_01; getting next line via the 'continue' command "
                fnEcho ${LINENO} ""
                continue
            else 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "line is not empty and no parameter_01; processing command "
                fnEcho ${LINENO} ""
        fi # end command line check 
        #
	    #
	    ##########################################################################
	    #
	    #
	    # test for valid non-recursive command      
	    #
	    fnEcho ${LINENO} ""  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} " test for valid non-recursive command         "       
	    fnEcho ${LINENO} " calling function 'fnDbQueryNonRecursiveCommandTest'      "               
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} ""  
	    #          
	    fnDbQueryNonRecursiveCommandTest
	    #
	    # test query result
	    if [[ "$query_non_recursive_command_test" = ''  ]]
	    	then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "command is not a valid non-recursive command; getting next line via the 'continue' command "
                fnEcho ${LINENO} ""
                continue
            else 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "command is a valid non-recursive command; processing command "
                fnEcho ${LINENO} ""
        fi # end test of query results  
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "-------------------------------------------------------------------------------------------------------------  "          
        fnEcho ${LINENO} "----------------------- non-recursive loop head: read variable 'services_driver_list' -----------------------  "
        fnEcho ${LINENO} "-------------------------------------------------------------------------------------------------------------  "          
        fnEcho ${LINENO} ""
	    #
	    ##########################################################################
	    #
	    #
	    # display the header     
	    #
	    fnEcho ${LINENO} ""  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} " display the header      "  
	    fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} ""  
	    #          
	    fnDisplayHeader
	    #
	    # display the task progress bar
	    #
	    fnDisplayProgressBarTask "$counter_aws_region_list" "$count_aws_region_list"
	    #
	    # display the sub-task progress bar
	    #
	    fnDisplayProgressBarTaskSub "$counter_aws_snapshot_commands" "$count_aws_snapshot_commands"
        #
        ##########################################################################
        #
        #
        # display the subtask text      
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " display the subtask text       "  
        fnEcho ${LINENO} " calling function 'fnDisplayTaskSubText'      "               
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #
        fnDisplayTaskSubText
	    #
	    ##########################################################################
	    #
	    #
	    # display the AWS command variables       
	    #
	    fnEcho ${LINENO} ""  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} " display the AWS command variables       "       
	    fnEcho ${LINENO} " calling function 'fnVariableNamesCommandDisplay'      "               
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} ""  
	    #          
		fnVariableNamesCommandDisplay
		#        
	    ##########################################################################
	    #
	    #
	    # load AWS command-related variables 
	    # calling function'fnVariableNamesCommandLoad'     
	    #
	    fnEcho ${LINENO} ""  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} " load variable names     "  
	    fnEcho ${LINENO} " calling function 'fnVariableNamesCommandLoad'      "               
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} ""  
	    #          
	    fnVariableNamesCommandLoad
        #
        ##########################################################################
        #
        #
        # display the header     
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " display the header      "  
        fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #          
        fnDisplayHeader
        #
        # display the task progress bar
        #
        fnDisplayProgressBarTask "$counter_aws_region_list" "$count_aws_region_list"
        #
        # display the sub task progress bar
        #
        fnDisplayProgressBarTaskSub "$counter_aws_snapshot_commands" "$count_aws_snapshot_commands"
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of variable: 'counter_aws_snapshot_commands': "$counter_aws_snapshot_commands" "
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of variable: 'count_aws_snapshot_commands': "$count_aws_snapshot_commands" "
        fnEcho ${LINENO} ""         
        #
        # debug
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} "" 
                fnEcho ${LINENO} ""                             
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "value of variable 'services_driver_list':"
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
                            fnEcho ${LINENO} level_0 ""
                            fnEcho ${LINENO} level_0 "value of variable 'services_driver_list':"
                            fnEcho ${LINENO} level_0 "$services_driver_list"
                            fnEcho ${LINENO} level_0 ""
                            # call the command / pipeline error function
                            fnErrorPipeline
                            #
                    #
                    fi
                    #
                fnEcho ${LINENO} "$feed_write_log"
                fnEcho ${LINENO} "--------------------------------------------------------------------------------------------------"
                fnEcho ${LINENO} ""
        #     
        fi  # end check for debug log 
        #                       
        #
        #
        # 
        ##########################################################################
        #
        #
        # counting global service names      
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " counting global service names      "  
        fnEcho ${LINENO} " calling function 'fnCountGlobalServicesNames'      "               
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #          
        # test for source table run 
        if [[ "$snapshot_type" != 'source-recursive' ]]
    	then 
		    #
		    fnEcho ${LINENO} ""
		    fnEcho ${LINENO} ""$snapshot_type" != source-recursive  "
		    fnEcho ${LINENO} ""
		    #  
        	fnCountGlobalServicesNames
        fi # end test for source table run 
        #
		#
        ##########################################################################
        #
        #
        # load AWS command-related variables 
        # calling function'fnVariableNamesCommandLoad'     
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " load variable names     "  
        fnEcho ${LINENO} " calling function 'fnVariableNamesCommandLoad'      "               
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #          
        fnVariableNamesCommandLoad
	    #
	    ##########################################################################
	    #
	    #
	    # display the header     
	    #
	    fnEcho ${LINENO} ""  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} " display the header      "  
	    fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} ""  
	    #          
	    fnDisplayHeader
	    #
	    # display the task progress bar
	    #
	    fnDisplayProgressBarTask "$counter_aws_region_list" "$count_aws_region_list"
	    #
	    # display the sub task progress bar
	    #
	    fnDisplayProgressBarTaskSub "$counter_aws_snapshot_commands" "$count_aws_snapshot_commands"
	    #
		fnEcho ${LINENO} level_0 ""  
		fnEcho ${LINENO} level_0 "Please wait..."  
		fnEcho ${LINENO} level_0 ""  
        #
        ##########################################################################
        #
        #
        # resetting the recursive run flag variable 'flag_recursive_command' to 'n'
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " resetting the recursive run flag variable 'flag_recursive_command' to 'n' "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #           
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "resetting the recursive run flag"
        flag_recursive_command="n" 
        fnEcho ${LINENO} "value of variable 'flag_recursive_command':"
        feed_write_log="$(echo "$flag_recursive_command" 2>&1)"
        fnEcho ${LINENO} "$feed_write_log"
        fnEcho ${LINENO} ""
        #
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "this is a non-recursive command: "$aws_service" "$aws_command"  "                       
        #
        ##########################################################################
        #
        #
        # begin section: non-recursive command
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " begin section: non-recursive command "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #    
        # if non-recursive command 
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "in non-recursive command"
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of variable 'aws_command': "$aws_command" "
        fnEcho ${LINENO} ""
		#
	    ##########################################################################
	    #
	    #
	    # display the header     
	    #
	    fnEcho ${LINENO} ""  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} " display the header      "  
	    fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} ""  
	    #          
	    fnDisplayHeader
	    #
	    # display the task progress bar
	    #
	    fnDisplayProgressBarTask "$counter_aws_region_list" "$count_aws_region_list"
	    #
	    # display the sub-task progress bar
	    #
	    fnDisplayProgressBarTaskSub "$counter_aws_snapshot_commands" "$count_aws_snapshot_commands"
	    #
	    ##########################################################################
	    #
	    #
	    # display the subtask text      
	    #
	    fnEcho ${LINENO} ""  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} " display the subtask text       "  
	    fnEcho ${LINENO} " calling function 'fnDisplayTaskSubText'      "               
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} ""  
	    #
	    fnDisplayTaskSubText
        #
        ##########################################################################
        #
        #
        # set the write file variable: 'write_file_raw'      
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " set the write file variable: 'write_file_raw'       "  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #
        write_file_raw="aws-""$aws_account"-"$aws_region_list_line_parameter"-snapshot-"$date_file"-"$aws_service"-"$aws_snapshot_name".json
        #
        fnEcho ${LINENO} ""    
        fnEcho ${LINENO} "value of variable 'write_file_raw':  "
        fnEcho ${LINENO} ""$write_file_raw" "
        fnEcho ${LINENO} ""
        #
        ##########################################################################
        #
        #
        # set the write file variables 
        # calling function: fnWriteFileVariablesSet     
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " set the write file variables       "  
        fnEcho ${LINENO} " calling function: fnWriteFileVariablesSet         "  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #
		fnWriteFileVariablesSet  
		#
        ##########################################################################
        #
        #
        # loading the variable 'snapshot_source_recursive_command'  
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " loading the variable 'snapshot_source_recursive_command'    "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #           
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
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'snapshot_source_recursive_command':"
                fnEcho ${LINENO} level_0 "$snapshot_source_recursive_command"
                fnEcho ${LINENO} level_0 ""
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"-write-file-build.json:"
                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-build.json)"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #                                                                                                                                                                                                                            
                # call the command / pipeline error function
                fnErrorPipeline
                #
                #
        fi
        #
        fnEcho ${LINENO} ""    
        #
        ##########################################################################
        #
        #
        # query AWS for the service   
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " query AWS for the service     "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #           
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of variable 'aws_service':"
        fnEcho ${LINENO} "$aws_service"   
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of variable 'aws_command':"
        fnEcho ${LINENO} "$aws_command"   
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of variable 'aws_command_parameter_string':"
        fnEcho ${LINENO} "$aws_command_parameter_string"   
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of variable 'aws_region_list_line_parameter':"
        fnEcho ${LINENO} "$aws_region_list_line_parameter"   
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "Querying AWS for the resources in: "$aws_service" "$aws_command" "$aws_region_list_line_parameter" " 
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "non-recursive command - loading the variable 'service_snapshot' "
        fnEcho ${LINENO} ""
        #
        fnEcho ${LINENO} ""
        #
        ##########################################################################
        #
        #
        # checking for global region  
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " checking for global region     "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #                  
        if [[ "$aws_region_list_line_parameter" = 'global' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "region is global so us-east-1 AWS region parameter " 
                fnEcho ${LINENO} "command: aws "$aws_service" "$aws_command" --profile "$cli_profile" --region us-east-1"    
                service_snapshot_command="$(echo -n "aws "$aws_service" "$aws_command" --profile "$cli_profile" --region us-east-1" | tr --squeeze-repeats ' ' 2>&1)"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "value of variable 'service_snapshot_command':"
                fnEcho ${LINENO} "$service_snapshot_command"   
                fnEcho ${LINENO} ""
                # executing variable returns "command not found" but it runs OK from a file
                fnEcho ${LINENO} "writing variable 'service_snapshot_command' to file 'service_snapshot_command.txt':"
                echo "$service_snapshot_command" > ./service_snapshot_command.txt  
                service_snapshot="$(source ./service_snapshot_command.txt 2>&1)"  
            else 
			 	fnEcho ${LINENO} ""
                fnEcho ${LINENO} "region is not global so using AWS region parameter " 
                fnEcho ${LINENO} "value of variable 'aws_region_list_line_parameter':"
			 	fnEcho ${LINENO} ""
                fnEcho ${LINENO} "$aws_region_list_line_parameter"   
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "command: aws "$aws_service" "$aws_command" --profile "$cli_profile" --region "$aws_region_list_line_parameter" " 
                service_snapshot_command="$(echo -n "aws "$aws_service" "$aws_command" --profile "$cli_profile" --region "$aws_region_list_line_parameter"" | tr --squeeze-repeats ' ' 2>&1)"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "value of variable 'service_snapshot_command':"
                fnEcho ${LINENO} "$service_snapshot_command"   
                fnEcho ${LINENO} ""
                # executing variable returns "command not found" but it runs OK from a file
                fnEcho ${LINENO} "writing variable 'service_snapshot_command' to file 'service_snapshot_command.txt':"
                echo "$service_snapshot_command" > ./service_snapshot_command.txt  
                service_snapshot="$(source ./service_snapshot_command.txt 2>&1)"  
                #service_snapshot="$("$service_snapshot_command")"
        fi  # end test for global region 
        #
        # check for errors from the AWS API  
        if [ "$?" -ne 0 ]
            then
                # check for no endpoint error
                count_error_aws_no_endpoint="$(echo "$service_snapshot" | grep -c 'Could not connect to the endpoint' 2>&1)" 
                if [[ "$count_error_aws_no_endpoint" -ne 0 ]] 
                    then 
                        # if no endpoint, then skip and continue 
                        #
                        fnEcho ${LINENO} ""
                        fnEcho ${LINENO} "no endpoint found for this service so resetting the variable 'service_snapshot' " 
                        fnEcho ${LINENO} "and 'service_snapshot_recursive' and skipping to the next via the 'continue' command "
                        service_snapshot=""
                        service_snapshot_recursive=""
                        #
                        continue 
                        #
                        #
                    else 
                        # AWS Error while pulling the AWS Services
                        fnEcho ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 "AWS error message: "
                        fnEcho ${LINENO} level_0 "$service_snapshot"
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 " AWS Error while pulling the AWS Services for "$aws_service" "$aws_snapshot_name" "
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
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
        fnEcho ${LINENO} ""
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} "" 
                fnEcho ${LINENO} ""                             
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------------------------------------------"
                fnEcho ${LINENO} "value of variable 'service_snapshot':"
                fnEcho ${LINENO} "$service_snapshot"
                fnEcho ${LINENO} "--------------------------------------------------------------------------------------------------"
                fnEcho ${LINENO} ""
        #     
        fi  # end check for debug log 
        #                       
        #
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of variable 'aws_account':"
        fnEcho ${LINENO} "$aws_account"
        fnEcho ${LINENO} ""
        #
        # 
        #
        ##########################################################################
        #
        #
        # in non-recursive section        
        # loading JSON pattern with service snapshot
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " in non-recursive section     "       
        fnEcho ${LINENO} " loading JSON pattern with service snapshot     "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #                          
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "loading variable 'pattern_load_feed' with variable 'service_snapshot_build_02'   "
        pattern_load_feed="$service_snapshot"
        fnEcho ${LINENO} ""
        #
        ##########################################################################
        #
        #
        # calling function 'fnPatternLoad'       
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " calling function 'fnPatternLoad'     "       
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #
        fnPatternLoad
        #
        #
        ##########################################################################
        #
        #
        # writing the service snapshot to the build JSON file: "$this_utility_acronym"-write-file-services-load.json to enable merge       
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " writing the service snapshot to the build JSON file: "$this_utility_acronym"-write-file-services-load.json to enable merge     "       
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "loading variable 'service_snapshot_build_03' with function return variable 'pattern_load_value'   "
        service_snapshot_build_03="$pattern_load_value"
        fnEcho ${LINENO} ""
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "Writing the service snapshot to the build JSON file: "$this_utility_acronym"-write-file-services-load.json to enable merge "
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
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$this_utility_acronym"-write-file-services-load.json:"
                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-services-load.json)"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #                                                                                                                                                                                                    
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnEcho ${LINENO} "$feed_write_log"
        fnEcho ${LINENO} ""
        #
        # feed_write_log="$(echo "$service_snapshot" | jq -s --arg aws_account_jq "$aws_account" --arg aws_region_list_line_parameter_jq "$aws_region_list_line_parameter" --arg aws_service_jq "$aws_service" '{ account: $aws_account_jq, regions: [ { regionName: $aws_region_list_line_parameter_jq, regionServices: [ { serviceType: $aws_service_jq, service: . } ] } ] }' > "$this_path_temp"/"$this_utility_acronym"-write-file-services-load.json 2>&1)"
        #
        fnEcho ${LINENO} ""
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} "" 
                fnEcho ${LINENO} ""                             
                fnEcho ${LINENO} ""                
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "contents of file "$this_utility_acronym"-write-file-services-load.json:"
                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-services-load.json)"
                fnEcho ${LINENO} "$feed_write_log"
                fnEcho ${LINENO} ""
        #     
        fi  # end check for debug log 
        #                       
        #   
        #
        ##########################################################################
        #
        #
        # Writing the non-recursive command JSON snapshot file for: "$aws_service" "$aws_command" to file: "$write_file_full_path"      
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " Writing the non-recursive command JSON snapshot file for: "$aws_service" "$aws_command" to file: "$write_file_full_path"     "       
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #
        # write the non-recursive command file
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "Writing the non-recursive command JSON snapshot file for: "$aws_service" "$aws_command" to file: "
        #
        #
        ##########################################################################
        #
        #
        # calling the array merge function 'fnMergeArraysServicesJsonFile' 
        # parameters are: source target 
        # output file name of the function is: "$this_utility_acronym"-merge-services-file-build-temp.json
        #
        # calling function: 'fnMergeArraysServicesJsonFile' with parameters: "$this_utility_acronym"-write-file-services-load.json "$this_utility_acronym"-write-file-build.json 
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " calling the array merge function 'fnMergeArraysServicesJsonFile'     "       
        fnEcho ${LINENO} " parameters are: source target      "       
        fnEcho ${LINENO} " output file name of the function is: "$this_utility_acronym"-merge-services-file-build-temp.json     "      
        fnEcho ${LINENO} "" 
        fnEcho ${LINENO} " calling function: 'fnMergeArraysServicesJsonFile' with parameters: "$this_utility_acronym"-write-file-services-load.json "$this_utility_acronym"-write-file-build.json      "       
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #
        fnMergeArraysServicesJsonFile "$this_path_temp"/"$this_utility_acronym"-write-file-services-load.json "$this_path_temp"/"$this_utility_acronym"-write-file-build.json
        #
        #    
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "Copying contents of file: "$this_utility_acronym"-merge-services-file-build-temp.json to file: "$write_file_full_path"  "
        fnEcho ${LINENO} ""  
        cp -f "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build-temp.json "$write_file_full_path"
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} ""
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} "" 
                fnEcho ${LINENO} ""                             
                fnEcho ${LINENO} ""                
                fnEcho ${LINENO} "Contents of file: "$write_file_full_path" "
                fnEcho ${LINENO} ""  
                feed_write_log="$(cat "$write_file_full_path"  2>&1)"
                #  check for command / pipeline error(s)
                if [ "$?" -ne 0 ]
                    then
                        #
                        # set the command/pipeline error line number
                        error_line_pipeline="$((${LINENO}-7))"
                        #
                        #
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                        fnEcho ${LINENO} level_0 "$feed_write_log"
                        fnEcho ${LINENO} level_0 ""
                        #
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 "contents of file "$write_file_full_path":"
                        feed_write_log="$(cat "$write_file_full_path")"
                        fnEcho ${LINENO} level_0 "$feed_write_log"
                        fnEcho ${LINENO} level_0 ""
                        #                                         
                        # call the command / pipeline error function
                        fnErrorPipeline
                        #
                        #
                fi  # end pipeline error check 
        #
        fnEcho ${LINENO} "$feed_write_log"
        #     
        fi  # end check for debug log 
        #                       
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} ""
        #
        #
        #
        ##########################################################################
        #
        #
        # Loading the non-recursive command JSON snapshot file to the database
        # calling function 'fnDbLoadSnapshotFile'     
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " Loading the non-recursive command JSON snapshot file to the database     "       
        fnEcho ${LINENO} " calling function 'fnDbLoadSnapshotFile'      "       
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #
        fnDbLoadSnapshotFile
        #
        #
        #
        ##########################################################################
        #
        #
        # write out the temp log and empty the log variable
        # calling function 'fnFileAppendLogTemp'     
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " write out the temp log and empty the log variable     "       
        fnEcho ${LINENO} " calling function 'fnFileAppendLogTemp'      "       
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #
        fnFileAppendLogTemp
        #
        #
        # end non-recursive command 
        #
        ##########################################################################
        #
        #
        # end section: non-recursive command
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " end section: non-recursive command "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #    
        fnEcho ${LINENO} ""
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} "" 
                fnEcho ${LINENO} ""                             
                fnEcho ${LINENO} ""                
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "value of variable 'service_snapshot':"
                feed_write_log="$(echo "$service_snapshot" 2>&1)"
                fnEcho ${LINENO} "$feed_write_log"
                fnEcho ${LINENO} ""
        #     
        fi  # end check for debug log 
        #                       
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} ""
        #
        fnEcho ${LINENO} ""
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} "" 
                fnEcho ${LINENO} ""                             
                fnEcho ${LINENO} ""                
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "contents of file: '$write_file_full_path':"
                feed_write_log="$(cat "$write_file_full_path" 2>&1)"
                # check for command / pipeline error(s)
                if [ "$?" -ne 0 ]
                    then
                        #
                        # set the command/pipeline error line number
                        error_line_pipeline="$((${LINENO}-7))"
                        #
                        #
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                        fnEcho ${LINENO} level_0 "$feed_write_log"
                        fnEcho ${LINENO} level_0 ""
                        #
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 "contents of file "$write_file_full_path":"
                        feed_write_log="$(cat "$write_file_full_path")"
                        fnEcho ${LINENO} level_0 "$feed_write_log"
                        fnEcho ${LINENO} level_0 ""
                        #    
                        # call the command / pipeline error function
                        fnErrorPipeline
                        #
                #
                fi
                #
                fnEcho ${LINENO} "$feed_write_log"
                fnEcho ${LINENO} ""
                #
        #     
        fi  # end check for debug log 
        #                       
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of variable 'flag_recursive_command':"
        feed_write_log="$(echo "$flag_recursive_command" 2>&1)"
        fnEcho ${LINENO} "$feed_write_log"
        fnEcho ${LINENO} ""
        #
        # checking for non-recursive run
        if [[ "$flag_recursive_command" == "n" ]] 
            then
                #
                fnEcho ${LINENO} "add the snapshot service and name to the snapshot names file "   
                feed_write_log="$(echo "$aws_service_snapshot_name" >> "$this_path_temp"/"$write_file_service_names"  2>&1)"
                fnEcho ${LINENO} "$feed_write_log"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} ""
                #
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "contents of file: '$write_file_service_names':"
                feed_write_log="$(cat "$this_path_temp"/"$write_file_service_names" 2>&1)"
                fnEcho ${LINENO} "$feed_write_log"
                fnEcho ${LINENO} ""
                #
        fi
        #
        # enable for debug
        # fnEcho ${LINENO} ""
        # fnEcho ${LINENO} "value of variable 'service_snapshot_recursive':"
        # feed_write_log="$(echo "$service_snapshot_recursive" 2>&1)"
        # fnEcho ${LINENO} "$feed_write_log"
        # fnEcho ${LINENO} ""
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of variable 'counter_driver_services':"
        feed_write_log="$(echo "$counter_driver_services" 2>&1)"
        fnEcho ${LINENO} "$feed_write_log"
        fnEcho ${LINENO} ""
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "increment the write counter: 'counter_driver_services'"
        counter_driver_services="$((counter_driver_services+1))"
        fnEcho ${LINENO} "post-increment value of variable 'counter_driver_services': "$counter_driver_services" "
        fnEcho ${LINENO} ""
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of variable 'count_driver_services':"
        feed_write_log="$(echo "$count_driver_services" 2>&1)"
        fnEcho ${LINENO} "$feed_write_log"
        fnEcho ${LINENO} ""
        #
        #
        # check for overrun; exit if loop is not stopping properly
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "checking for overrun of the write counter: 'counter_driver_services'"
        if [[ "$counter_driver_services" -gt "$count_driver_services" ]]  
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-5))"
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "service counter overrun error "
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'counter_driver_services':"
                fnEcho ${LINENO} level_0 "$counter_driver_services"
                fnEcho ${LINENO} level_0 ""
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'count_driver_services':"
                fnEcho ${LINENO} level_0 "$count_driver_services"
                fnEcho ${LINENO} level_0 ""
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi  # end check for services_driver_list loop overrun 
        #
        #
	    # check for sourct table run 
	    if [[ "$snapshot_type" != 'source-recursive' ]]
	    	then 
			    #
			    fnEcho ${LINENO} ""
			    fnEcho ${LINENO} ""$snapshot_type" != source-recursive  "
			    fnEcho ${LINENO} ""
			    #   	
		        ##########################################################################
		        #
		        #
		        # increment the snapshot counter
		        # calling function: 'fnCounterIncrementSnapshots'
		        #
		        fnEcho ${LINENO} ""  
		        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		        fnEcho ${LINENO} "increment the snapshot counter "               
		        fnEcho ${LINENO} "calling function: 'fnCounterIncrementSnapshots' "
		        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		        fnEcho ${LINENO} ""  
		        #                  
		        fnCounterIncrementSnapshots
		        #
			    ##########################################################################
			    #
			    #
			    # increment the AWS snapshot command counter
			    # calling function: 'fnCounterIncrementAwsSnapshotCommands'
			    #
			    fnEcho ${LINENO} ""  
			    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
			    fnEcho ${LINENO} "increment the AWS snapshot command counter "               
			    fnEcho ${LINENO} "calling function: 'fnCounterIncrementAwsSnapshotCommands' "
			    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
			    fnEcho ${LINENO} ""  
			    #                  
			    fnCounterIncrementAwsSnapshotCommands
		        #
		fi # end check for sourct table run
		#
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "-------------------------------------------------------------------------------------------------------------  "            
        fnEcho ${LINENO} "----------------------- non-recursive loop tail: read variable 'services_driver_list' -----------------------  "
        fnEcho ${LINENO} "-------------------------------------------------------------------------------------------------------------  "            
        fnEcho ${LINENO} ""
        #
        # write out the temp log and empty the log variable
        fnFileAppendLogTemp
        #
    #
    done< <(cat "$this_path_temp"/"$file_snapshot_driver_stripped_file_name")
    #done< <(echo "$services_driver_list")
    #
    #
    ##########################################################################
    #
    #
    # end non-recursive loop read: variable 'services_driver_list'
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end non-recursive loop read: variable 'services_driver_list'   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #         
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} " in section: end pull the non-recursive snapshots"
    fnEcho ${LINENO} "------------------------------------------------"  
    fnEcho ${LINENO} "value of variable 'aws_account':"
    fnEcho ${LINENO} "$aws_account"
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_service':"
    fnEcho ${LINENO} "$aws_service"
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_service_snapshot_name_underscore':"
    fnEcho ${LINENO} "$aws_service_snapshot_name_underscore"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "------------------------------------------------"  
    fnEcho ${LINENO} ""
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "---------------------------------- end pull the non-recursive snapshots ----------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    #
    # write out the temp log and empty the log variable
    fnFileAppendLogTemp
    #
    #
    ##########################################################################
    #
    #
    # end function 'fnAwsPullSnapshotsLoop'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnAwsPullSnapshotsLoop'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to pull the recursive snapshots from AWS    
#
function fnAwsPullSnapshotsRecursiveLoop()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnAwsPullSnapshotsRecursiveLoop'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnAwsPullSnapshotsRecursiveLoop'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnAwsPullSnapshotsRecursiveLoop' "
    fnEcho ${LINENO} ""
    #       
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------- begin pull the recursive snapshots -----------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # display the header     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " display the header      "  
    fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
    fnDisplayHeader
    #
    # display the task progress bar
    #
    fnDisplayProgressBarTask "$counter_aws_region_list" "$count_aws_region_list"
    #
    # display the sub-task progress bar
    #
    fnDisplayProgressBarTaskSub "$counter_aws_snapshot_commands" "$count_aws_snapshot_commands"
    #
    ##########################################################################
    #
    #
    # reset the task counter variable 'counter_driver_services'    
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " reset the task counter variable 'counter_driver_services'      "  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    counter_driver_services=0
    #
    ##########################################################################
    #
    #
    # clear the loop prior AWS command variable 'aws_command_prior'
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " clear the loop prior AWS command variable 'aws_command_prior'    "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    aws_command_prior=""
    #
    ##########################################################################
    #
    #
    # read the AWS CLI commands from the file and process them 
    # begin loop: read "$file_snapshot_driver_stripped_file_name"     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------" 
    fnEcho ${LINENO} " recursive       "                
    fnEcho ${LINENO} " read the AWS CLI commands from the file and process them      "           
    fnEcho ${LINENO} " begin recursive loop: read "$file_snapshot_driver_stripped_file_name"      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    while read -r aws_service aws_command aws_command_parameter_01 aws_command_parameter_01_value aws_command_parameter_02 aws_command_parameter_02_value aws_command_parameter_03 aws_command_parameter_03_value aws_command_parameter_04 aws_command_parameter_04_value aws_command_parameter_05 aws_command_parameter_05_value aws_command_parameter_06 aws_command_parameter_06_value aws_command_parameter_07 aws_command_parameter_07_value aws_command_parameter_08 aws_command_parameter_08_value parameter_01_source_table parameter_02_source_table parameter_03_source_table parameter_04_source_table parameter_05_source_table parameter_06_source_table parameter_07_source_table parameter_08_source_table parameter_01_source_key parameter_02_source_key parameter_03_source_key parameter_04_source_key parameter_05_source_key parameter_06_source_key parameter_07_source_key parameter_08_source_key
    do
 	    #
	    ##########################################################################
	    #
	    #
	    # check for empty line or empty parameter_01; skip if empty      
	    #
	    fnEcho ${LINENO} ""  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} " check for empty line or empty parameter_01; skip if empty       "       
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} "" 
   	    #      
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of AWS command variables: 'aws_service' 'aws_command' 'aws_command_parameter_01' 'aws_command_parameter_01_value' "
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of AWS command variables: "$aws_service" "$aws_command" "$aws_command_parameter_01" "$aws_command_parameter_01_value" "
        fnEcho ${LINENO} ""         
	    #          
	    # check the command line 
        if [[ ("$aws_service" = '') || ("$aws_command_parameter_01" = '') ]]
            then
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "line is empty or empty parameter_01; getting next line via the 'continue' command "
                fnEcho ${LINENO} ""
                continue
            else 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "line is not empty or no parameter_01; processing command "
                fnEcho ${LINENO} ""
        fi # end command line check 
        #
	    ##########################################################################
	    #
	    #
	    # test for valid recursive command      
	    #
	    fnEcho ${LINENO} ""  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} " test for valid recursive command         "       
	    fnEcho ${LINENO} " calling function 'fnDbQueryRecursiveCommandTest'      "               
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} ""  
	    #          
	    fnDbQueryRecursiveCommandTest
	    #
	    # test query result
	    if [[ "$query_recursive_command_test" = ''  ]]
	    	then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "test results: "$query_recursive_command_test" != "$aws_command" "                
                fnEcho ${LINENO} "command is not a valid recursive command; getting next line via the 'continue' command "
                fnEcho ${LINENO} ""
                continue
            else 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "test results: "$query_recursive_command_test" = "$aws_command" "                               
                fnEcho ${LINENO} "command is a valid recursive command; processing command "
                fnEcho ${LINENO} ""
        fi # end test of query results  
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------  "  
        fnEcho ${LINENO} "----------------- recursive loop head: read "$file_snapshot_driver_stripped_file_name" -----------------  "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------  "                  
        fnEcho ${LINENO} ""
	    #
	    ##########################################################################
	    #
	    #
	    # display the header     
	    #
	    fnEcho ${LINENO} ""  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} " display the header      "  
	    fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} ""  
	    #          
	    fnDisplayHeader
	    #
	    # display the task progress bar
	    #
	    fnDisplayProgressBarTask "$counter_aws_region_list" "$count_aws_region_list"
	    #
	    # display the sub-task progress bar
	    #
	    fnDisplayProgressBarTaskSub "$counter_aws_snapshot_commands" "$count_aws_snapshot_commands"
	    #
	    ##########################################################################
	    #
	    #
	    # display the AWS command variables       
	    #
	    fnEcho ${LINENO} ""  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} " display the AWS command variables       "       
	    fnEcho ${LINENO} " calling function 'fnVariableNamesCommandDisplay'      "               
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} ""  
	    #          
		fnVariableNamesCommandDisplay
        #
        ##########################################################################
        #
        #
        # check for recursive run type and load the AWS recursive command   
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " check for recursive run type and load the AWS recursive command       "  
        fnEcho ${LINENO} " calling function 'fnVariableNamesCommandRecursiveLoad'      "               
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #          
		fnVariableNamesCommandRecursiveLoad
        #
        # debug
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} "" 
                fnEcho ${LINENO} ""                             
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "value of variable 'services_driver_list':"
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
                            fnEcho ${LINENO} level_0 ""
                            fnEcho ${LINENO} level_0 "value of variable 'services_driver_list':"
                            fnEcho ${LINENO} level_0 "$services_driver_list"
                            fnEcho ${LINENO} level_0 ""
                            # call the command / pipeline error function
                            fnErrorPipeline
                            #
                    #
                    fi
                    #
                fnEcho ${LINENO} "$feed_write_log"
                fnEcho ${LINENO} "--------------------------------------------------------------------------------------------------"
                fnEcho ${LINENO} ""
        #     
        fi  # end check for debug log 
        #                       
        #
        ##########################################################################
        #
        #
        # resetting the recursive run flag variable 'flag_recursive_command' to 'y'
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " resetting the recursive run flag variable 'flag_recursive_command' to 'y' "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #           
        flag_recursive_command="y" 
        fnEcho ${LINENO} "value of variable 'flag_recursive_command':"
        feed_write_log="$(echo "$flag_recursive_command" 2>&1)"
        fnEcho ${LINENO} "$feed_write_log"
        fnEcho ${LINENO} ""
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "this is a recursive command: "$aws_service" "$aws_command_parameter_01" "$aws_command_parameter_01_value"   "               
        #
        #        
        #
        ##########################################################################
        #
        #
        # counting global service names      
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " counting global service names      "  
        fnEcho ${LINENO} " calling function 'fnCountGlobalServicesNames'      "               
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #          
        fnCountGlobalServicesNames
        #
        ##########################################################################
        #
        #
        # load AWS command-related variables 
        # calling function'fnVariableNamesCommandLoad'     
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " load variable names     "  
        fnEcho ${LINENO} " calling function 'fnVariableNamesCommandLoad'      "               
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #          
        fnVariableNamesCommandLoad
        #
        ##########################################################################
        #
        #
        # check for recursive run type and load the AWS recursive command   
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " check for recursive run type and load the AWS recursive command       "  
        fnEcho ${LINENO} " calling function 'fnVariableNamesCommandRecursiveLoad'      "               
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #          
		fnVariableNamesCommandRecursiveLoad
        #
        ##########################################################################
        #
        #
        # display the command variables prior to first time through recursive loop test     
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " display the command variables prior to first time through recursive loop test           "  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #
        fnEcho ${LINENO} ""   
        fnEcho ${LINENO} ""   
        fnEcho ${LINENO} "recursive command variables       : aws "aws_service" / "aws_command" / "aws_command_parameter_01" / "aws_command_parameter_01_value" / --profile "cli_profile" "                     
        fnEcho ${LINENO} "recursive command variables values: aws "$aws_service" / "$aws_command" / "$aws_command_parameter_01" / "$aws_command_parameter_01_value" / --profile "$cli_profile" "      
        fnEcho ${LINENO} "recursive command                 : aws "$aws_service" "$aws_command" "$aws_command_parameter_01" "$aws_command_parameter_01_value" --profile "$cli_profile" "      
        fnEcho ${LINENO} ""    
        #
        #
        ##########################################################################
        #
        #
        # test for first time through loop
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " test for first time through the recursive loop   "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #              
        fnEcho ${LINENO} ""    
        fnEcho ${LINENO} "value of variable 'aws_command_prior':"
        feed_write_log="$(echo "$aws_command_prior" 2>&1)"
        fnEcho ${LINENO} "$feed_write_log"
        fnEcho ${LINENO} ""
        #
        fnEcho ${LINENO} ""    
        fnEcho ${LINENO} "value of variable 'aws_command':"
        feed_write_log="$(echo "$aws_command" 2>&1)"
        fnEcho ${LINENO} "$feed_write_log"
        fnEcho ${LINENO} ""
        #
        if [[ "$aws_command" != "$aws_command_prior" ]] && [[ "$aws_command_prior" != '' ]]
            then 
		        #
		        ##########################################################################
		        #
		        #
		        # AWS command does not match loop prior command and is not empty
		        # loading merged JSON file from prior command loop into database   
                #
			    fnEcho ${LINENO} ""  
			    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
			    fnEcho ${LINENO} "AWS command does not match loop prior command and is not empty" 
			    fnEcho ${LINENO} "loading merged JSON file from prior command loop into database  "        
			    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
			    fnEcho ${LINENO} ""  
			    #
		        ##########################################################################
		        #
		        #
		        # Loading the AWS command variables with prior values
		        # calling function: 'fnVariablePriorLoad'   
		        #			    
			    fnEcho ${LINENO} ""  
			    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
			    fnEcho ${LINENO} "Loading the variables with prior values " 
			    fnEcho ${LINENO} "calling function: 'fnVariablePriorLoad' "        
			    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
			    fnEcho ${LINENO} ""  
			    #                  
				fnVariablePriorLoad
				#
		        ##########################################################################
		        #
		        #
		        # load AWS command-related variables 
		        # calling function'fnVariableNamesCommandLoad'     
		        #
		        fnEcho ${LINENO} ""  
		        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		        fnEcho ${LINENO} " load variable names     "  
		        fnEcho ${LINENO} " calling function 'fnVariableNamesCommandLoad'      "               
		        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		        fnEcho ${LINENO} ""  
		        #          
		        fnVariableNamesCommandLoad
		        #
		        ##########################################################################
		        #
		        #
		        # check for recursive run type and load the AWS recursive command   
		        #
		        fnEcho ${LINENO} ""  
		        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		        fnEcho ${LINENO} " check for recursive run type and load the AWS recursive command       "  
		        fnEcho ${LINENO} " calling function 'fnVariableNamesCommandRecursiveLoad'      "               
		        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		        fnEcho ${LINENO} ""  
		        #          
				fnVariableNamesCommandRecursiveLoad
				#
		        ##########################################################################
		        #
		        #
		        # Loading the prior recursive command JSON snapshot file to the database
		        # calling function: 'fnDbLoadSnapshotFile'     
		        #
			    fnEcho ${LINENO} ""  
			    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
			    fnEcho ${LINENO} "Loading the prior recursive command JSON snapshot file to the database " 
			    fnEcho ${LINENO} "calling function: 'fnDbLoadSnapshotFile' "        
			    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
			    fnEcho ${LINENO} ""  
			    #                  
			    fnDbLoadSnapshotFile
				#
		        ##########################################################################
		        #
		        #
		        # Restoring the AWS command variables with backup values
		        # calling function: 'fnVariablePriorRestore'    
		        #			    
			    fnEcho ${LINENO} ""  
			    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
			    fnEcho ${LINENO} "Restoring the variables with backup values " 
			    fnEcho ${LINENO} "calling function: 'fnVariablePriorRestore' "        
			    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
			    fnEcho ${LINENO} ""  
			    #                  
				fnVariablePriorRestore
				#
		        ##########################################################################
		        #
		        #
		        # load AWS command-related variable names 
		        # calling function'fnVariableNamesCommandLoad'     
		        #
		        fnEcho ${LINENO} ""  
		        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		        fnEcho ${LINENO} " load variable names     "  
		        fnEcho ${LINENO} " calling function 'fnVariableNamesCommandLoad'      "               
		        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		        fnEcho ${LINENO} ""  
		        #          
		        fnVariableNamesCommandLoad	
		        #
		        ##########################################################################
		        #
		        #
		        # check for recursive run type and load the AWS recursive command   
		        #
		        fnEcho ${LINENO} ""  
		        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		        fnEcho ${LINENO} " check for recursive run type and load the AWS recursive command       "  
		        fnEcho ${LINENO} " calling function 'fnVariableNamesCommandRecursiveLoad'      "               
		        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		        fnEcho ${LINENO} ""  
		        #          
				fnVariableNamesCommandRecursiveLoad	        		
		        #
		        ##########################################################################
		        #
		        #
		        # new recursive command - initializing the data file    
			    #
			    fnEcho ${LINENO} ""  
			    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
			    fnEcho ${LINENO} "new recursive command - initializing the data file " 
			    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
			    fnEcho ${LINENO} ""  
		        #
		        ##########################################################################
		        #
		        #
		        # set the write file variable: 'write_file_raw'      
		        #
		        fnEcho ${LINENO} ""  
		        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		        fnEcho ${LINENO} " set the write file variable: 'write_file_raw'       "  
		        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		        fnEcho ${LINENO} ""  
		        #
                write_file_raw="$(echo "aws-""$aws_account"-"$aws_region_list_line_parameter"-snapshot-"$date_file"-"$aws_service"-"$aws_snapshot_name"-"$aws_command".json)" 
                #
                fnEcho ${LINENO} ""    
                fnEcho ${LINENO} "value of variable 'write_file_raw':  "
                fnEcho ${LINENO} ""$write_file_raw" "
                fnEcho ${LINENO} ""
		        #
		        ##########################################################################
		        #
		        #
		        # set the write file variables 
		        # calling function: fnWriteFileVariablesSet     
		        #
		        fnEcho ${LINENO} ""  
		        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		        fnEcho ${LINENO} " set the write file variables       "  
		        fnEcho ${LINENO} " calling function: fnWriteFileVariablesSet         "  
		        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		        fnEcho ${LINENO} ""  
		        #
				fnWriteFileVariablesSet  
				#
                ##########################################################################
                #
                #
                # first time through the loop with this command
                # load the variable 'snapshot_source_recursive_command' with the contents of the file    
                #
                fnEcho ${LINENO} ""  
                fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
                fnEcho ${LINENO} "first time through the loop with this command"
                fnEcho ${LINENO} "load the variable 'snapshot_source_recursive_command' with the contents of the file:"
                fnEcho ${LINENO} ""$this_path_temp"/"$this_utility_acronym"-write-file-build.json"
                fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
                fnEcho ${LINENO} ""  
                #                  
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
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 "value of variable 'snapshot_source_recursive_command':"
                        fnEcho ${LINENO} level_0 "$snapshot_source_recursive_command"
                        fnEcho ${LINENO} level_0 ""
                        #
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"-write-file-build.json:"
                        feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-build.json)"
                        fnEcho ${LINENO} level_0 "$feed_write_log"
                        fnEcho ${LINENO} level_0 ""
                        #                                                                                                                                            
                        # call the command / pipeline error function
                        fnErrorPipeline
                        #
                        #
                fi  # end check for pipeline error 
                #
                fnEcho ${LINENO} ""    
                fnEcho ${LINENO} "value of variable 'snapshot_source_recursive_command':"
                feed_write_log="$(echo "$snapshot_source_recursive_command" 2>&1)"
                fnEcho ${LINENO} "$feed_write_log"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} ""    
                fnEcho ${LINENO} ""

        fi  # end test for first time through loop 
		#
	    ##########################################################################
	    #
	    #
	    # display the header     
	    #
	    fnEcho ${LINENO} ""  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} " display the header      "  
	    fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} ""  
	    #          
	    fnDisplayHeader
	    #
	    # display the task progress bar
	    #
	    fnDisplayProgressBarTask "$counter_aws_region_list" "$count_aws_region_list"
	    #
	    # display the sub-task progress bar
	    #
	    fnDisplayProgressBarTaskSub "$counter_aws_snapshot_commands" "$count_aws_snapshot_commands"
	    #
	    ##########################################################################
	    #
	    #
	    # display the subtask text      
	    #
	    fnEcho ${LINENO} ""  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} " display the subtask text       "  
	    fnEcho ${LINENO} " calling function 'fnDisplayTaskSubText'      "               
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} ""  
	    #
	    fnDisplayTaskSubText
        # 
        ##########################################################################
        #
        #
        # display the command variables after the first time through recursive loop test     
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " display the command variables after the first time through recursive loop test           "  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #
        fnEcho ${LINENO} ""   
        fnEcho ${LINENO} ""   
        fnEcho ${LINENO} "recursive command variables       : aws "aws_service" / "aws_command" / "aws_command_parameter_01" / "aws_command_parameter_01_value" / --profile "cli_profile" "                     
        fnEcho ${LINENO} "recursive command variables values: aws "$aws_service" / "$aws_command" / "$aws_command_parameter_01" / "$aws_command_parameter_01_value" / --profile "$cli_profile" "      
        fnEcho ${LINENO} "recursive command                 : aws "$aws_service" "$aws_command" "$aws_command_parameter_01" "$aws_command_parameter_01_value" --profile "$cli_profile" "      
        fnEcho ${LINENO} ""    
        #
        ##########################################################################
        #
        #
        # querying AWS for the recursive service values     
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " querying AWS for the recursive service values      "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #                  
        fnEcho ${LINENO} ""    
        fnEcho ${LINENO} "value of variable 'aws_service': "$aws_service" "
        fnEcho ${LINENO} ""    
        fnEcho ${LINENO} "value of variable 'aws_command': "$aws_command" "     
        #              
        #
        ##########################################################################
        #
        #
        # in AWS query for: normal recursive command
        # using no supplemental parameters  
        # 
        # Querying AWS for the resources in: "aws_service" / "aws_command" / "aws_command_parameter_01" / "aws_command_parameter_01_value"
        # Querying AWS for the resources in: "$aws_service" / "$aws_command" / "$aws_command_parameter_01" / "$aws_command_parameter_01_value"
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} "in AWS query for: normal recursive command "
        fnEcho ${LINENO} "using no supplemental parameters "
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "Querying AWS for the resources in: "aws_service" / "aws_command" / "aws_command_parameter_01" / "aws_command_parameter_01_value" " 
        fnEcho ${LINENO} "Querying AWS for the resources in: "$aws_service" / "$aws_command" / "$aws_command_parameter_01" / "$aws_command_parameter_01_value" " 
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #
        fnEcho ${LINENO} ""
        #
        ##########################################################################
        #
        #
        # checking for global region    
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " checking for global region      "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #                  
        if [[ "$aws_region_list_line_parameter" = 'global' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} ""
                #
                ##########################################################################
                #
                #
                # region is global so us-east-1 AWS region parameter
                # >> Pulling snapshot from AWS <<
                #     
                #
                fnEcho ${LINENO} ""  
                fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
                fnEcho ${LINENO} " region is global so us-east-1 AWS region parameter      "
                fnEcho ${LINENO} ""  
                fnEcho ${LINENO} " >> Pulling snapshot from AWS <<      "
                fnEcho ${LINENO} ""  
                fnEcho ${LINENO} "CLI debug command: aws "$aws_service" "$aws_command" "$aws_command_parameter_01" "$aws_command_parameter_01_value" --profile "$cli_profile" --region us-east-1 " 
                fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
                fnEcho ${LINENO} ""  
                #                  
                service_snapshot_build_01="$(aws "$aws_service" "$aws_command" "$aws_command_parameter_01" "$aws_command_parameter_01_value" --profile "$cli_profile" --region us-east-1  2>&1)" 
            else 
                #
                ##########################################################################
                #
                #
                # region is global so us-east-1 AWS region parameter
                # >> Pulling snapshot from AWS <<
                #     
                #
                fnEcho ${LINENO} ""  
                fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
                fnEcho ${LINENO} "region is not global so using AWS region parameter " 
                fnEcho ${LINENO} ""  
                fnEcho ${LINENO} " >> Pulling snapshot from AWS <<      "
                fnEcho ${LINENO} ""  
                fnEcho ${LINENO} "CLI debug command: aws "$aws_service" "$aws_command" "$aws_command_parameter_01" "$aws_command_parameter_01_value" --profile "$cli_profile" --region "$aws_region_list_line_parameter" " 
                fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
                fnEcho ${LINENO} ""  
                #                  
                service_snapshot_build_01="$(aws "$aws_service" "$aws_command" "$aws_command_parameter_01" "$aws_command_parameter_01_value" --profile "$cli_profile" --region "$aws_region_list_line_parameter"  2>&1)" 
        fi  # end test for global region 
        #
        #
        #
        # check for errors from the AWS API  
        if [ "$?" -ne 0 ]
            then
                # test for s3
                if [[ "$aws_service" = "s3api" ]] 
                    then
                        # check for "not found" error to handle s3 APIs that return an error instead of an empty set
                        fnEcho ${LINENO} ""   
                        fnEcho ${LINENO} "testing for '...not found' AWS error"    
                        count_not_found_error=0
                        count_not_found_error="$(echo "$service_snapshot_build_01" | egrep 'not exist|not found|NoSuchBucketPolicy' | wc -l)"
                        fnEcho ${LINENO} "value of variable 'count_not_found_error': "$count_not_found_error" "
                        fnEcho ${LINENO} ""   
                        if [[ "$count_not_found_error" > 0 ]] 
                            then 
						        #
						        ##########################################################################
						        #
						        #
						        # s3api returned a "not found" error - this command has no results from this bucket   
						        #
						        fnEcho ${LINENO} ""  
						        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
						        fnEcho ${LINENO} " s3api returned a "not found" error - no results from this command:      "
						        fnEcho ${LINENO} " "$aws_service" "$aws_command" "$aws_command_parameter_01" "$aws_command_parameter_01_value" "
						        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
						        fnEcho ${LINENO} ""  
						        #                     
 						        ##########################################################################
						        #
						        #
						        # execute fnAwsPullSnapshotsRecursiveLoop tail tasks
						        # calling function: 'fnAwsPullSnapshotsRecursiveLoopTail'
						        #
						        fnEcho ${LINENO} ""  
						        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
						        fnEcho ${LINENO} "execute fnAwsPullSnapshotsRecursiveLoop tail tasks "               
						        fnEcho ${LINENO} "calling function: 'fnAwsPullSnapshotsRecursiveLoopTail' "
						        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
						        fnEcho ${LINENO} ""  
						        #                  
								fnAwsPullSnapshotsRecursiveLoopTail
								#
						        ##########################################################################
						        #
						        #
						        # skipping to next entry via the 'continue' command  
						        #
						        fnEcho ${LINENO} ""  
						        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
						        fnEcho ${LINENO} " skipping to next entry via the 'continue' command       "
						        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
						        fnEcho ${LINENO} ""  
						        #                     
                                continue
                                #
                        fi  # end count not found error - check for no return from s3api
                        #
                fi # end check for s3api 
                #
                # check for no endpoint error
                count_error_aws_no_endpoint="$(echo "$service_snapshot" | grep -c 'Could not connect to the endpoint' 2>&1)" 
                if [[ "$count_error_aws_no_endpoint" -ne 0 ]] 
                    then 
                        # if no endpoint, then skip and continue 
                        #
                        ##########################################################################
                        #
                        #
                        # skipping to next AWS command via the continue command
                        #
                        fnEcho ${LINENO} ""  
                        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
                        fnEcho ${LINENO} " no endpoint found for this service so resetting the variable 'service_snapshot'       "
                        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
                        fnEcho ${LINENO} ""  
                        #
                        service_snapshot=""
                        #
				        #
				        ##########################################################################
				        #
				        #
				        # execute fnAwsPullSnapshotsRecursiveLoop tail tasks
				        # calling function: 'fnAwsPullSnapshotsRecursiveLoopTail'
				        #
				        fnEcho ${LINENO} ""  
				        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
				        fnEcho ${LINENO} "execute fnAwsPullSnapshotsRecursiveLoop tail tasks "               
				        fnEcho ${LINENO} "calling function: 'fnAwsPullSnapshotsRecursiveLoopTail' "
				        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
				        fnEcho ${LINENO} ""  
				        #                  
						fnAwsPullSnapshotsRecursiveLoopTail
						#
                        #
                        ##########################################################################
                        #
                        #
                        # skipping to next AWS command via the continue command
                        #
                        fnEcho ${LINENO} ""  
                        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
                        fnEcho ${LINENO} " skipping to next line via the continue command      "
                        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
                        fnEcho ${LINENO} ""  
                        #
                        continue 
                        #
                        #
                    else 
                        #
                        # AWS Error while pulling the AWS Services
                        fnEcho ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 "AWS error message: "
                        fnEcho ${LINENO} level_0 "$service_snapshot_build_01"
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 " AWS Error while pulling the AWS Services for: "
                        fnEcho ${LINENO} level_0 "   "aws_service" / "aws_command" / "aws_command_parameter_01" / "aws_command_parameter_01_value" " 
                        fnEcho ${LINENO} level_0 "   "$aws_service" / "$aws_command" / "$aws_command_parameter_01" / "$aws_command_parameter_01_value" " 
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
                        #
                        # set the awserror line number
                        error_line_aws="$((${LINENO}-44))"
                        #
                        #
                        ##########################################################################
                        #
                        #
                        # calling the error log handler
                        # calling function 'fnErrorLog'
                        #
                        fnEcho ${LINENO} ""  
                        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
                        fnEcho ${LINENO} " calling the error log handler      "
                        fnEcho ${LINENO} " calling function 'fnErrorLog' with parameter:     "
                        fnEcho ${LINENO} "$service_snapshot_build_01"
                        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
                        fnEcho ${LINENO} ""  
                        #
                        fnErrorLog "$service_snapshot_build_01"
                        #
				        #
				        ##########################################################################
				        #
				        #
				        # execute fnAwsPullSnapshotsRecursiveLoop tail tasks
				        # calling function: 'fnAwsPullSnapshotsRecursiveLoopTail'
				        #
				        fnEcho ${LINENO} ""  
				        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
				        fnEcho ${LINENO} "execute fnAwsPullSnapshotsRecursiveLoop tail tasks "               
				        fnEcho ${LINENO} "calling function: 'fnAwsPullSnapshotsRecursiveLoopTail' "
				        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
				        fnEcho ${LINENO} ""  
				        #                  
						fnAwsPullSnapshotsRecursiveLoopTail
						#
                        ##########################################################################
                        #
                        #
                        # skipping to next AWS command via the continue command
                        #
                        fnEcho ${LINENO} ""  
                        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
                        fnEcho ${LINENO} " skipping to next line via the continue command      "
                        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
                        fnEcho ${LINENO} ""  
                        #
                        continue 
                        #
                fi  # end check for no endpoint error             
                #
        fi # end recursive AWS error
        #
        fnEcho ${LINENO} ""
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} "" 
                fnEcho ${LINENO} ""               
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "value of variable 'service_snapshot_build_01': "
                feed_write_log="$(echo "$service_snapshot_build_01" 2>&1)"
                fnEcho ${LINENO} "$feed_write_log"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} ""
        #     
        fi  # end check for debug log 
        #                                         
        ##########################################################################
        #
        #
        # checking for empty results
        # if empty result set, then continue to the next list value    
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " checking for empty results     "
        fnEcho ${LINENO} " if empty result set, then continue to the next list value      "               
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #                  
        # if empty result set, then continue to the next list value
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "testing for empty result set "
        if [[ "$service_snapshot_build_01" = "" ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "empty results set "
                fnEcho ${LINENO} "increment the service_key_list counter"
                #
                ##########################################################################
                #
                #
                # increment the AWS snapshot command counter
                # calling function: 'fnCounterIncrementAwsSnapshotCommands'
                #
                fnEcho ${LINENO} ""  
                fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
                fnEcho ${LINENO} "increment the AWS snapshot command counter "               
                fnEcho ${LINENO} "calling function: 'fnCounterIncrementAwsSnapshotCommands' "
                fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
                fnEcho ${LINENO} ""  
                #                  
                fnCounterIncrementAwsSnapshotCommands
                #
                fnEcho ${LINENO} "value of variable 'counter_aws_snapshot_commands': "$counter_aws_snapshot_commands" "
                fnEcho ${LINENO} "value of variable 'count_aws_snapshot_commands': "$count_aws_snapshot_commands" "
                fnEcho ${LINENO} ""
                #
                continue
                #
            else 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "non-empty results set "                        
                fnEcho ${LINENO} ""
        fi  # end check for empty result set
        #
        fnEcho ${LINENO} ""
        #
        ##########################################################################
        #
        #
        # stripping any escape \ characaters from results - PostgreSQL does not accept them 
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " stripping any escape \ characaters from results - PostgreSQL does not accept them     "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #   
        # strip \" ; need to run sed twice to get both head and tail instances of \"                   
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} " strip \\\" ; need to run sed twice to get both head and tail instances of \\\"      "
        service_snapshot_build_02="$(echo "$service_snapshot_build_01" | sed 's/\\""/"/g' |  sed 's/"\\"/"/g' | sed 's/\\"/"/g'  2>&1)"
		fnEcho ${LINENO} ""
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} "" 
                fnEcho ${LINENO} ""               
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "value of variable 'service_snapshot_build_02': "
                feed_write_log="$(echo "$service_snapshot_build_02" 2>&1)"
                fnEcho ${LINENO} "$feed_write_log"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} ""
        #     
        fi  # end check for debug log 
        #   
        # strip \, space, line feed 
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} " strip \, space, line feed       "
        service_snapshot_build_03="$(echo "$service_snapshot_build_02"  | tr -d '\\' | tr -d ' ' | tr -d '\n'  2>&1)"
		fnEcho ${LINENO} ""
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} "" 
                fnEcho ${LINENO} ""               
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "value of variable 'service_snapshot_build_03': "
                feed_write_log="$(echo "$service_snapshot_build_03" 2>&1)"
                fnEcho ${LINENO} "$feed_write_log"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} ""
        #     
        fi  # end check for debug log 
        #        
		fnEcho ${LINENO} ""
		fnEcho ${LINENO} "pulling quoted object begin  "
		service_snapshot_build_04="$(echo "$service_snapshot_build_03" | sed 's/^.*\(:"{\).*$/\1/' 2>&1)"
		fnEcho ${LINENO} ""
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} "" 
                fnEcho ${LINENO} ""               
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "value of variable 'service_snapshot_build_04': "
                feed_write_log="$(echo "$service_snapshot_build_04" 2>&1)"
                fnEcho ${LINENO} "$feed_write_log"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} ""
        #     
        fi  # end check for debug log 
        #                                         
		fnEcho ${LINENO} ""
		fnEcho ${LINENO} "testing results for quoted object JSON"
		if [[ "$service_snapshot_build_04" = ':"{' ]]
			then 
				fnEcho ${LINENO} "$service_snapshot_build_04" = ':"{'
				fnEcho ${LINENO} "the results include a quoted object "			
				fnEcho ${LINENO} "strip the double quotes around the object"
				fnEcho ${LINENO} "strip the leading double quotes "
				service_snapshot_build_05="$(echo "$service_snapshot_build_03" | sed 's/\(^.*\):"{\(.*$\)/\1:{\2/' 2>&1)"
				fnEcho ${LINENO} ""
		        #
		        # check for debug log 
		        if [[ "$logging" = 'z' ]] 
		            then 
		                fnEcho ${LINENO} ""
		                fnEcho ${LINENO} "--------------------------------------------------------------"
		                fnEcho ${LINENO} ""
		                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
		                fnEcho ${LINENO} ""
		                fnEcho ${LINENO} "--------------------------------------------------------------"
		                fnEcho ${LINENO} "" 
		                fnEcho ${LINENO} ""               
		                fnEcho ${LINENO} ""
		                fnEcho ${LINENO} "value of variable 'service_snapshot_build_05': "
		                feed_write_log="$(echo "$service_snapshot_build_05" 2>&1)"
		                fnEcho ${LINENO} "$feed_write_log"
		                fnEcho ${LINENO} ""
		                fnEcho ${LINENO} ""
		        #     
		        fi  # end check for debug log 
		        #                                         
				fnEcho ${LINENO} ""
				fnEcho ${LINENO} "strip the trailing double quotes "
				service_snapshot_build_06="$(echo "$service_snapshot_build_05" | sed 's/\(^.*\)}"}\(.*$\)/\1}}\2/' 2>&1)"
				fnEcho ${LINENO} ""
		        #
			else
				fnEcho ${LINENO} "$service_snapshot_build_04" != ':"{'				
				fnEcho ${LINENO} "the results do not include a quoted object "			
				fnEcho ${LINENO} "use the results as they are; load build_03 into build_06 "
				service_snapshot_build_06="$(echo "$service_snapshot_build_03" 2>&1)"
				fnEcho ${LINENO} ""
		fi 
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} "" 
                fnEcho ${LINENO} ""               
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "value of variable 'service_snapshot_build_06':"
                feed_write_log="$(echo "$service_snapshot_build_06")"
                fnEcho ${LINENO} "$feed_write_log"
        #     
        fi  # end check for debug log 
        #
        ##########################################################################
        #
        #
        # adding keys and values to the recursive command results set
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " adding keys and values to the recursive command results set     "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #
        ##########################################################################
        #
        #
        # adding the parameter_01_source_key and the aws_command_parameter_01_value: "$parameter_01_source_key" "$aws_command_parameter_01_value"
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " adding the parameter_01_source_key and the aws_command_parameter_01_value: "$parameter_01_source_key" "$aws_command_parameter_01_value"     "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #                  
        service_snapshot_build_07="$(echo "$service_snapshot_build_06" \
        | jq --arg parameter_01_source_key_jq "$parameter_01_source_key" --arg aws_command_parameter_01_value_jq "$aws_command_parameter_01_value" ' {($parameter_01_source_key_jq): $aws_command_parameter_01_value_jq} + .  ' 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'service_snapshot_build_06':"
                fnEcho ${LINENO} level_0 "$service_snapshot_build_06"
                fnEcho ${LINENO} level_0 ""
                #                                                                                                                                                                                                    
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnEcho ${LINENO} ""
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} "" 
                fnEcho ${LINENO} ""               
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "value of variable 'service_snapshot_build_07':"
                feed_write_log="$(echo "$service_snapshot_build_07")"
                fnEcho ${LINENO} "$feed_write_log"
        #     
        fi  # end check for debug log 
        #                                         
        #
        #
        #
        ##########################################################################
        #
        #
        # in recursive command section
        # adding the JSON template keys and values: "$aws_account" "$aws_region_list_line_parameter" "$aws_service" "$aws_service_snapshot_name_underscore"
        # loading variable 'pattern_load_feed' with variable 'service_snapshot_build_02' 
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " in recursive command section     "               
        fnEcho ${LINENO} " adding the JSON template keys and values: "$aws_account" "$aws_region_list_line_parameter" "$aws_service" "$aws_service_snapshot_name_underscore"     "
        fnEcho ${LINENO} " loading variable 'pattern_load_feed' with variable 'service_snapshot_build_07'      "                              
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        pattern_load_feed="$service_snapshot_build_07"
        fnEcho ${LINENO} ""
        #
        ##########################################################################
        #
        #
        # calling function 'fnPatternLoad'
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " calling function 'fnPatternLoad'     "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #                  
        fnPatternLoad
        #
        # the built-up AWS service is put into the following structure as an array at the position of the '.'  
        # service_snapshot_build_03="$(echo "$service_snapshot_build_02" \
        # | jq -s --arg aws_account_jq "$aws_account" --arg aws_region_list_line_parameter_jq "$aws_region_list_line_parameter" --arg aws_service_jq "$aws_service" --arg aws_service_snapshot_name_underscore_jq "$aws_service_snapshot_name_underscore" '{ account: $aws_account_jq, regions: [ { regionName: $aws_region_list_line_parameter_jq, regionServices: [ { serviceType: $aws_service_jq, service: [ { ($aws_service_snapshot_name_underscore_jq): . } ] } ] } ] }' 2>&1)"
        #
        #
        ##########################################################################
        #
        #
        # loading variable 'service_snapshot_build_03' with function return variable 'pattern_load_value' 
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " loading variable 'service_snapshot_build_08' with function return variable 'pattern_load_value'      "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #                  
        service_snapshot_build_08="$pattern_load_value"
        fnEcho ${LINENO} ""
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} "" 
                fnEcho ${LINENO} ""               
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "value of variable 'service_snapshot_build_08':"
                feed_write_log="$(echo "$service_snapshot_build_08")"
                fnEcho ${LINENO} "$feed_write_log"
        #     
        fi  # end check for debug log 
        #
        # 
        #
        ##########################################################################
        #
        #
        # Writing the recursive service snapshot to the build JSON file: "$this_utility_acronym"-write-file-services-recursive-load.json to enable merge 
        # using variables: "$aws_account" "$aws_region_list_line_parameter" "$aws_service" "$parameter_01_source_key" "$parameter_01_source_key_line"
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} "Writing the recursive service snapshot to the build JSON file: "$this_utility_acronym"-write-file-services-recursive-load.json to enable merge "
        fnEcho ${LINENO} "using variables: "$aws_account" "$aws_region_list_line_parameter" "$aws_service" "$parameter_01_source_key" "$parameter_01_source_key_line" "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #                  
        feed_write_log="$(echo "$service_snapshot_build_08">"$this_path_temp"/"$this_utility_acronym"-write-file-services-recursive-load.json 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"-write-file-services-recursive-load.json:"
                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-services-recursive-load.json)"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #                                                                                                                                                                                                    
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnEcho ${LINENO} "$feed_write_log"
        fnEcho ${LINENO} ""
        #
        fnEcho ${LINENO} ""
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} "" 
                fnEcho ${LINENO} ""               
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "contents of file "$this_utility_acronym"-write-file-services-recursive-load.json:"
                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-services-recursive-load.json)"
                fnEcho ${LINENO} "$feed_write_log"
                fnEcho ${LINENO} ""
        #     
        fi  # end check for debug log 
        #
        #                                                                                                                                                                                                                            
        #
        #
        ##########################################################################
        #
        #
        # loading variable 'service_snapshot' with contents of file "$this_utility_acronym"-write-file-services-recursive-load.json 
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} "loading variable 'service_snapshot' with contents of file "$this_utility_acronym"-write-file-services-recursive-load.json "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #                  
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
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'service_snapshot':"
                fnEcho ${LINENO} level_0 "$service_snapshot"
                fnEcho ${LINENO} level_0 ""
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"-write-file-services-recursive-load.json:"
                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-services-recursive-load.json)"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #                                                                                                                                                                                                    
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnEcho ${LINENO} "$feed_write_log"
        #
        fnEcho ${LINENO} ""
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} "" 
                fnEcho ${LINENO} ""               
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "value of variable 'service_snapshot': "
                feed_write_log="$(echo "$service_snapshot" 2>&1)"
                fnEcho ${LINENO} "$feed_write_log"
        #     
        fi  # end check for debug log 
        #
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} "" 
                fnEcho ${LINENO} ""               
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "value of variable 'service_snapshot' piped through 'jq .': "
                feed_write_log="$(echo "$service_snapshot" | jq . 2>&1)"
                # check for jq error
                if [ "$?" -ne 0 ]
                    then
                        # jq error 
                        fnEcho ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 "jq error message: "
                        fnEcho ${LINENO} level_0 "$feed_write_log"
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
                        #
                        # set the jqerror line number
                        error_line_jq="$((${LINENO}-13))"
                        #
                        # call the jq error handler
                        fnErrorJq
                        #
                fi # end jq error
                #
                fnEcho ${LINENO} "$feed_write_log"
                fnEcho ${LINENO} ""
        #     
        fi  # end check for debug log 
        #                       
        fnEcho ${LINENO} "---------------------------------------"
        #    
        #
        ##########################################################################
        #
        #
        # if the first time through with this command, then add the services name and the empty services array
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} "if the first time through with this command, then add the services name and the empty services array "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #                  
        if [[ "$aws_command" != "$aws_command_prior" ]] 
            then 
            #
            # get the recursive service key name 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "first time through with this command "
            #
            ##########################################################################
            #
            #
            # pulling the service key from the variable 'service_snapshot_build_01'
            #
            fnEcho ${LINENO} ""  
            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
            fnEcho ${LINENO} "pulling the service key from the variable 'service_snapshot_build_01' "
            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
            fnEcho ${LINENO} ""  
            #                  
            service_snapshot_recursive_service_key="$(echo "$service_snapshot_build_01" | jq 'keys' | tr -d '[]", ' | grep -v -e '^$' | grep -v "$parameter_01_source_key" 2>&1)"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "value of variable 'service_snapshot_recursive_service_key': "$service_snapshot_recursive_service_key" "
            fnEcho ${LINENO} ""
            #
            # swap the variables
            snapshot_source_recursive_command_02="$snapshot_source_recursive_command"
            #   
            fnEcho ${LINENO} ""
            #
            ##########################################################################
            #
            #
            # calling the write file initialize function: 'fnInitializeWriteFileBuild'
            #
            fnEcho ${LINENO} ""  
            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
            fnEcho ${LINENO} "calling the write file initialize function: 'fnInitializeWriteFileBuild' "
            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
            fnEcho ${LINENO} ""  
            #                  
            fnInitializeWriteFileBuild
            #
            fnEcho ${LINENO} ""
            #
            ##########################################################################
            #
            #
            # initializing the variable 'snapshot_source_recursive_command' with the contents of the file "$this_utility_acronym"-write-file-build.json "
            #
            fnEcho ${LINENO} ""  
            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
            fnEcho ${LINENO} "initializing the variable 'snapshot_source_recursive_command' with the contents of the file "$this_utility_acronym"-write-file-build.json "
            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
            fnEcho ${LINENO} ""  
            #                  
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
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "value of variable 'snapshot_source_recursive_command':"
                    fnEcho ${LINENO} level_0 "$snapshot_source_recursive_command"
                    fnEcho ${LINENO} level_0 ""
                    #
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"-write-file-build.json:"
                    feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-write-file-build.json)"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #                                                                                                                                                                                                    
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnEcho ${LINENO} "$feed_write_log"
            #
            #
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "value of variable 'snapshot_source_recursive_command': "
            feed_write_log="$(echo "$snapshot_source_recursive_command" 2>&1)"
            fnEcho ${LINENO} "$feed_write_log"
            fnEcho ${LINENO} ""
            #  
            fnEcho ${LINENO} ""
            #
        fi # end first time through 
        #
        #
        # normally disabled for speed
        fnEcho ${LINENO} ""
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} "" 
                fnEcho ${LINENO} ""               
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "value of variable: "snapshot_source_recursive_command":"  
                feed_write_log="$(echo "$snapshot_source_recursive_command" 2>&1)"
                fnEcho ${LINENO} "$feed_write_log"                    
        #     
        fi  # end check for debug log 
        #                       
        #
        #
        # write the recursive command file
        fnEcho ${LINENO} "" 
        #
        ##########################################################################
        #
        #
        # calling the recursive command file write function 'fnWriteCommandFileRecursive' "
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} "calling the recursive command file write function 'fnWriteCommandFileRecursive' "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #                  
        fnWriteCommandFileRecursive
        #
        #  
        fnEcho ${LINENO} ""
        # normally disabled for speed
        fnEcho ${LINENO} ""
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} "" 
                fnEcho ${LINENO} ""               
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "value of variable: 'snapshot_target_recursive_command':"
                feed_write_log="$(echo "$snapshot_target_recursive_command" 2>&1)"
                fnEcho ${LINENO} "$feed_write_log"
                fnEcho ${LINENO} ""
        #     
        fi  # end check for debug log 
        #                       
        #
        #  
        fnEcho ${LINENO} ""
        #
        ##########################################################################
        #
        #
        # loading variable: "snapshot_source_recursive_command" from variable "snapshot_target_recursive_command"
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} "loading variable: "snapshot_source_recursive_command" from variable "snapshot_target_recursive_command" "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #                  
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
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'snapshot_source_recursive_command':"
                fnEcho ${LINENO} level_0 "$snapshot_source_recursive_command"
                fnEcho ${LINENO} level_0 ""
                #                                                                                                                                            
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnEcho ${LINENO} ""
        #
        #  
        fnEcho ${LINENO} ""
        # normally disabled for speed
        fnEcho ${LINENO} ""
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} "" 
                fnEcho ${LINENO} ""               
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "value of variable: "snapshot_source_recursive_command":"  
                feed_write_log="$(echo "$snapshot_source_recursive_command" 2>&1)"
                fnEcho ${LINENO} "$feed_write_log"
        #     
        fi  # end check for debug log 
        #                       
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} ""
        #
        #
        #
        ##########################################################################
        #
        #
        # adding the snapshot service and name to the snapshot names file: "$this_path_temp"/"$write_file_service_names"
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} "adding the snapshot service and name to the snapshot names file: "$this_path_temp"/"$write_file_service_names" "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #                  
        fnEcho ${LINENO} "add the snapshot service and name to the snapshot names file "   
        feed_write_log="$(echo ""$aws_service"---"$aws_command"---"$aws_command_parameter_01_value"" >> "$this_path_temp"/"$write_file_service_names"  2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$write_file_service_names":"
                feed_write_log="$(cat "$this_path_temp"/"$write_file_service_names")"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #                                                                                                                                                                            
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnEcho ${LINENO} "$feed_write_log"
        fnEcho ${LINENO} ""
        #               
        fnEcho ${LINENO} "$feed_write_log"
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} ""
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "contents of file: '$write_file_service_names':"
        feed_write_log="$(cat "$this_path_temp"/"$write_file_service_names" 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$write_file_service_names":"
                feed_write_log="$(cat "$this_path_temp"/"$write_file_service_names")"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #                                                                                                                                                                            
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnEcho ${LINENO} "$feed_write_log"
        fnEcho ${LINENO} ""
        #
        ##########################################################################
        #
        #
        # write out the temp log and empty the log variable
        # calling function: 'fnFileAppendLogTemp'
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} "write out the temp log and empty the log variable "               
        fnEcho ${LINENO} "calling function: 'fnFileAppendLogTemp' "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #                  
        fnFileAppendLogTemp
        #
        ##########################################################################
        #
        #
        # display the header     
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " display the header      "  
        fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #          
        fnDisplayHeader
        #
        # display the task progress bar
        #
        fnDisplayProgressBarTask "$counter_aws_region_list" "$count_aws_region_list"
        #
        # display the sub-task progress bar
        #
        fnDisplayProgressBarTaskSub "$counter_aws_snapshot_commands" "$count_aws_snapshot_commands"
        #
        #
        #
        ##########################################################################
        #
        #
        # display the subtask text      
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " display the subtask text       "  
        fnEcho ${LINENO} " calling function 'fnDisplayTaskSubText'      "               
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #
        fnDisplayTaskSubText
        #
        #
        ##########################################################################
        #
        #
        # writing the final state of the snapshot variable 'snapshot_target_recursive_command' to the snapshot file
        # "$write_file_full_path"
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} "writing the final state of the snapshot variable 'snapshot_target_recursive_command' to the snapshot file: "
        feed_write_log="$(echo "$write_file_full_path" 2>&1)"
        fnEcho ${LINENO} "$feed_write_log"
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #                  
        #
        #
        ##########################################################################
        #
        #
        # calling the recursive command file write function: 'fnWriteCommandFileRecursive'
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} "calling the recursive command file write function: 'fnWriteCommandFileRecursive' "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #                  
        fnWriteCommandFileRecursive
        #
        ##########################################################################
        #
        #
        # set the write file variables 
        # calling function: fnWriteFileVariablesSet     
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " set the write file variables       "  
        fnEcho ${LINENO} " calling function: fnWriteFileVariablesSet         "  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #
		fnWriteFileVariablesSet  
        #
        ##########################################################################
        #
        #
        # writing the variable 'snapshot_target_recursive_command' to the output file 'write_file_full_path'
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} "writing the variable 'snapshot_target_recursive_command' to the output file 'write_file_full_path': "
        fnEcho ${LINENO} "$write_file_full_path"         
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #                  
        feed_write_log="$(echo "$snapshot_target_recursive_command" > "$write_file_full_path"  2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #                                                                                                                                                                            
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnEcho ${LINENO} "$feed_write_log"
        fnEcho ${LINENO} ""
        #
        fnEcho ${LINENO} ""
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} "" 
                fnEcho ${LINENO} ""                             
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "contents of file: 'write_file_full_path':"
                feed_write_log="$(echo "$write_file_full_path" 2>&1)"
                fnEcho ${LINENO} "$feed_write_log"
                fnEcho ${LINENO} ""           
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
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                        fnEcho ${LINENO} level_0 "$feed_write_log"
                        fnEcho ${LINENO} level_0 ""
                        #
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 "contents of file "$write_file_full_path":"
                        feed_write_log="$(cat "$write_file_full_path")"
                        fnEcho ${LINENO} level_0 "$feed_write_log"
                        fnEcho ${LINENO} level_0 ""
                        #                                                                                                                                                                                                    
                        # call the command / pipeline error function
                        fnErrorPipeline
                        #
                #
                fi
                #
                fnEcho ${LINENO} "$feed_write_log"
                fnEcho ${LINENO} ""
        #     
        fi  # end check for debug log 
        #                       
        #
        #                       
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} ""
        #
        #
        #
        ##########################################################################
        #
        #
        # write out the temp log and empty the log variable
        # calling function: 'fnFileAppendLogTemp'
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} "write out the temp log and empty the log variable " 
        fnEcho ${LINENO} "calling function: 'fnFileAppendLogTemp' "        
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #                  
        #
        # end recursive command 
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "---------------------------------- end section: recursive command ---------------------------------  "
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} ""
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} "" 
                fnEcho ${LINENO} ""                             
                fnEcho ${LINENO} ""                
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "value of variable 'service_snapshot_recursive':"
                feed_write_log="$(echo "$service_snapshot_recursive" 2>&1)"
                fnEcho ${LINENO} "$feed_write_log"
                fnEcho ${LINENO} ""
        #     
        fi  # end check for debug log 
        #                       
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} ""
        #
        fnEcho ${LINENO} ""
        #
        # check for debug log 
        if [[ "$logging" = 'z' ]] 
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "--------------------------------------------------------------"
                fnEcho ${LINENO} "" 
                fnEcho ${LINENO} ""                             
                fnEcho ${LINENO} ""                
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "contents of file: '$write_file_full_path':"
                feed_write_log="$(cat "$write_file_full_path" 2>&1)"
                # check for command / pipeline error(s)
                if [ "$?" -ne 0 ]
                    then
                        #
                        # set the command/pipeline error line number
                        error_line_pipeline="$((${LINENO}-7))"
                        #
                        #
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                        fnEcho ${LINENO} level_0 "$feed_write_log"
                        fnEcho ${LINENO} level_0 ""
                        #
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 "contents of file "$write_file_full_path":"
                        feed_write_log="$(cat "$write_file_full_path")"
                        fnEcho ${LINENO} level_0 "$feed_write_log"
                        fnEcho ${LINENO} level_0 ""
                        #    
                        # call the command / pipeline error function
                        fnErrorPipeline
                        #
                #
                fi
                #
                fnEcho ${LINENO} "$feed_write_log"
                fnEcho ${LINENO} ""
                #
        #     
        fi  # end check for debug log 
        #                       
        #
        # enable for debug
        # fnEcho ${LINENO} ""
        # fnEcho ${LINENO} "value of variable 'service_snapshot_recursive':"
        # feed_write_log="$(echo "$service_snapshot_recursive" 2>&1)"
        # fnEcho ${LINENO} "$feed_write_log"
        # fnEcho ${LINENO} ""
        #
        #
        ##########################################################################
        #
        #
        # execute fnAwsPullSnapshotsRecursiveLoop tail tasks
        # calling function: 'fnAwsPullSnapshotsRecursiveLoopTail'
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} "execute fnAwsPullSnapshotsRecursiveLoop tail tasks "               
        fnEcho ${LINENO} "calling function: 'fnAwsPullSnapshotsRecursiveLoopTail' "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #                  
		fnAwsPullSnapshotsRecursiveLoopTail
		#
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "-----------------------------------------------------------------------------------------------------------------------  "                            
        fnEcho ${LINENO} "----------------------- recursive loop tail: read "$file_snapshot_driver_stripped_file_name" -----------------------  "
        fnEcho ${LINENO} "-----------------------------------------------------------------------------------------------------------------------  "                            
        fnEcho ${LINENO} ""
        #
        #
        #
    #done< <(cat "$this_path_temp"/"$file_snapshot_driver_stripped_file_name")
    done< <(echo "$services_driver_list")
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} " in section: end pull the recursive snapshots"
    fnEcho ${LINENO} "------------------------------------------------"  
    fnEcho ${LINENO} "value of variable 'aws_account':"
    fnEcho ${LINENO} "$aws_account"
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_service':"
    fnEcho ${LINENO} "$aws_service"
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_service_snapshot_name_underscore':"
    fnEcho ${LINENO} "$aws_service_snapshot_name_underscore"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "------------------------------------------------"  
    fnEcho ${LINENO} ""
    #
    #
    #       
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------- end pull the recursive snapshots -------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # load the database table for the final command 
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} "load the database table for the final command  " 
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} "Loading the AWS command variables with prior values " 
    fnEcho ${LINENO} "calling function: 'fnVariablePriorLoad' "        
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                  
	fnVariablePriorLoad
	#
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} "Loading the prior recursive command JSON snapshot file to the database " 
    fnEcho ${LINENO} "calling function: 'fnDbLoadSnapshotFile' "        
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                  
    fnDbLoadSnapshotFile
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} "Restoring the AWS command variables with backup values " 
    fnEcho ${LINENO} "calling function: 'fnVariablePriorRestore' "        
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                  
	fnVariablePriorRestore
    #
    ##########################################################################
    #
    #
    # check for recursive run type and load the AWS recursive command   
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " check for recursive run type and load the AWS recursive command       "  
    fnEcho ${LINENO} " calling function 'fnVariableNamesCommandRecursiveLoad'      "               
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
	fnVariableNamesCommandRecursiveLoad
    #
    ##########################################################################
    #
    #
    # end function 'fnAwsPullSnapshotsRecursiveLoop'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnAwsPullSnapshotsRecursiveLoop'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
}
#
##########################################################################
#
#
# function to pull the recursive hardcoded snapshots from AWS    
#
function fnAwsPullSnapshotsRecursiveHardcoded()
{
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnAwsPullSnapshotsRecursiveHardcoded' "
    fnEcho ${LINENO} ""
    #       
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------- begin pull the recursive hardcoded snapshots -------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    #







    #       
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "------------------------------ end pull the recursive hardcoded snapshots --------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
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
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnMergeArraysServicesRecursiveJsonFile' "
    fnEcho ${LINENO} ""
    #        
    # set the source file
    merge_service_recursive_files_snapshots_source="$1"
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'merge_service_recursive_files_snapshots_source': "
    fnEcho ${LINENO} "$merge_service_recursive_files_snapshots_source"
    fnEcho ${LINENO} ""
    #
    # set the source file
    merge_service_recursive_files_snapshots_target="$2"
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'merge_service_recursive_files_snapshots_target': "
    fnEcho ${LINENO} "$merge_service_recursive_files_snapshots_target"
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    #
    # check for debug log 
    if [[ "$logging" = 'z' ]] 
        then 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} "" 
            fnEcho ${LINENO} ""                             
            fnEcho ${LINENO} ""                
            #
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "contents of source file: "$merge_service_recursive_files_snapshots_source": "
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
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "contents of file "$merge_service_recursive_files_snapshots_source":"
                    feed_write_log="$(cat "$merge_service_recursive_files_snapshots_source")"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #    
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnEcho ${LINENO} "$feed_write_log"
            fnEcho ${LINENO} ""
                    fnEcho ${LINENO} ""
            fnEcho ${LINENO} "contents of target file: "$merge_service_recursive_files_snapshots_target": "
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
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "contents of file "$merge_service_recursive_files_snapshots_target":"
                    feed_write_log="$(cat "$files_snapshots_target")"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #    
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnEcho ${LINENO} "$feed_write_log"
            fnEcho ${LINENO} ""
    #     
    fi  # end check for debug log 
    #                       
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading variable 'merge_service_recursive' "
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
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'merge_service_recursive':"
            fnEcho ${LINENO} level_0 "$merge_service_recursive"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$merge_service_recursive_files_snapshots_source":"
            feed_write_log="$(cat "$merge_service_recursive_files_snapshots_source")"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi  # end check for pipeline errors 
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'merge_service_recursive':"
    fnEcho ${LINENO} "$merge_service_recursive"
    fnEcho ${LINENO} ""
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading variable 'merge_service_recursive_key_name' "   
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
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'merge_service_recursive_key_name':"
            fnEcho ${LINENO} level_0 "$merge_service_recursive_key_name"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$merge_service_recursive_files_snapshots_source":"
            feed_write_log="$(cat "$merge_service_recursive_files_snapshots_source")"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi  # end check for pipeline errors 
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'merge_service_recursive_key_name':"
    fnEcho ${LINENO} "$merge_service_recursive_key_name"
    fnEcho ${LINENO} ""
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "merging recursive services JSON files:"
    fnEcho ${LINENO} "$merge_service_recursive_files_snapshots_source" 
    fnEcho ${LINENO} "and"
    fnEcho ${LINENO} "$merge_service_recursive_files_snapshots_target"
    fnEcho ${LINENO} "into file:"
    fnEcho ${LINENO} "$this_path_temp"/"$this_utility_acronym"-merge-services-recursive-file-build-temp.json
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "command:" 
    fnEcho ${LINENO} "jq -Mn "
    fnEcho ${LINENO} "--argfile merge_service_recursive_file_merge_services_target_jq" 
    fnEcho ${LINENO} "$merge_service_recursive_files_snapshots_target"
    fnEcho ${LINENO} "--argfile merge_service_recursive_file_merge_services_source_jq" 
    fnEcho ${LINENO} "$merge_service_recursive_files_snapshots_source"
    fnEcho ${LINENO} ""
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
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} "" 
            fnEcho ${LINENO} ""                             
            fnEcho ${LINENO} ""                
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "Contents of file: '"$this_path_temp"/"$this_utility_acronym"-merge-services-recursive-file-build-temp.json' "
            fnEcho ${LINENO} ""  
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
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                        fnEcho ${LINENO} level_0 "$feed_write_log"
                        fnEcho ${LINENO} level_0 ""
                        #
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"-merge-services-recursive-file-build-temp.json:"
                        feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-merge-services-recursive-file-build-temp.json)"
                        fnEcho ${LINENO} level_0 "$feed_write_log"
                        fnEcho ${LINENO} level_0 ""
                        #                     
                        # call the command / pipeline error function
                        fnErrorPipeline
                        #
                        #
                fi
                #
                fnEcho ${LINENO} "$feed_write_log"
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
function fnMergeArraysServicesJsonFile()
{
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnMergeArraysServicesJsonFile' "
    fnEcho ${LINENO} ""
    #        
    # set the source file
    files_snapshots_source="$1"
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'files_snapshots_source': "
    fnEcho ${LINENO} "$files_snapshots_source"
    fnEcho ${LINENO} ""
    #
    # set the source file
    files_snapshots_target="$2"
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'files_snapshots_target': "
    fnEcho ${LINENO} "$files_snapshots_target"
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    #
    # check for debug log 
    if [[ "$logging" = 'z' ]] 
        then 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} "" 
            fnEcho ${LINENO} ""                             
            fnEcho ${LINENO} ""                    
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "contents of source file: "$files_snapshots_source": "
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
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "contents of file "$files_snapshots_source":"
                    feed_write_log="$(cat "$files_snapshots_source")"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #    
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnEcho ${LINENO} "$feed_write_log"
            fnEcho ${LINENO} ""
        #     
    fi  # end check for debug log 
    #                       
    #
    # check for debug log 
    if [[ "$logging" = 'z' ]] 
        then 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} "" 
            fnEcho ${LINENO} ""                             
            fnEcho ${LINENO} ""                    
            fnEcho ${LINENO} ""    
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "contents of target file: "$files_snapshots_target": "
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
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "contents of file "$files_snapshots_target":"
                    feed_write_log="$(cat "$files_snapshots_target")"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #    
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnEcho ${LINENO} "$feed_write_log"
            fnEcho ${LINENO} ""
        #     
    fi  # end check for debug log 
    #                       
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "merging services JSON files:"
    fnEcho ${LINENO} "$files_snapshots_source" 
    fnEcho ${LINENO} "and"
    fnEcho ${LINENO} "$files_snapshots_target"
    fnEcho ${LINENO} "into file:"
    fnEcho ${LINENO} "$this_utility_acronym""-merge-services-file-build-temp.json"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "command:" 
    fnEcho ${LINENO} "jq -Mn --argfile file_merge_services_target_jq" 
    fnEcho ${LINENO} "$files_snapshots_target"
    fnEcho ${LINENO} "--argfile file_merge_services_source_jq" 
    fnEcho ${LINENO} "$files_snapshots_source"
    fnEcho ${LINENO} ""
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
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "--------------------------------------------------------------"
            fnEcho ${LINENO} "" 
            fnEcho ${LINENO} ""                             
            fnEcho ${LINENO} ""                    
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "Contents of file: "$this_utility_acronym"-merge-services-file-build-temp.json "
            fnEcho ${LINENO} ""  
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
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"-merge-services-file-build.json:"
                    feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build-temp.json)"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #                     
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
                    #
            fi
            #
            fnEcho ${LINENO} "$feed_write_log"
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
function fnCreateMergedServicesJsonFile()
{
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnCreateMergedServicesJsonFile' "
    fnEcho ${LINENO} ""
    #       
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading the variable 'aws_region_fn_create_merged_services_json_file' from the function parameter 1: "$ 1" "  
    aws_region_fn_create_merged_services_json_file=$1
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading the variable 'find_name_fn_create_merged_services_json_file' from the function parameter 1: "$ 2" "  
    find_name_fn_create_merged_services_json_file=$2
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_region_fn_create_merged_services_json_file': "$aws_region_fn_create_merged_services_json_file" "  
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'find_name_fn_create_merged_services_json_file': "$find_name_fn_create_merged_services_json_file" "  
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # display the header     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " display the header      "  
    fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
    fnDisplayHeader
    #
    # display the task progress bar
    #
    fnDisplayProgressBarTask "$counter_aws_region_list" "$count_aws_region_list"
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} level_0 "Merging the AWS services snapshot JSON files for region: "$aws_region_fn_create_merged_services_json_file"..."
    fnEcho ${LINENO} ""   
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} " in section: begin create merged services JSON file"
    fnEcho ${LINENO} "------------------------------------------------"  
    fnEcho ${LINENO} "value of variable 'aws_account':"
    fnEcho ${LINENO} "$aws_account"
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_service':"
    fnEcho ${LINENO} "$aws_service"
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_service_snapshot_name_underscore':"
    fnEcho ${LINENO} "$aws_service_snapshot_name_underscore"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "------------------------------------------------"  
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "------------------------------ begin create merged services JSON file -----------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # display the header     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " display the header      "  
    fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
    fnDisplayHeader
    #
    # load the variables
    #
    # initialize the counters
    #
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 "Creating merged services JSON file "
    fnEcho ${LINENO} level_0 ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "creating snapshot file list file: "$this_utility_acronym"-snapshot-file-list.txt "
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
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"'-snapshot-file-list.txt':"
                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot-file-list.txt 2>&1)"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #                     
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading variable: 'files_snapshots' "
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
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'files_snapshots':"
                fnEcho ${LINENO} level_0 "$files_snapshots"
                fnEcho ${LINENO} level_0 ""
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"'-snapshot-file-list.txt':"
                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot-file-list.txt 2>&1)"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #                     
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'files_snapshots': "
    feed_write_log="$(echo "$files_snapshots" 2>&1)"
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading variable: 'count_files_snapshots' "
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
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'count_files_snapshots':"
                fnEcho ${LINENO} level_0 "$count_files_snapshots"
                fnEcho ${LINENO} level_0 ""
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"'-snapshot-file-list.txt':"
                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot-file-list.txt 2>&1)"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #                     
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'count_files_snapshots': "
    feed_write_log="$(echo "$count_files_snapshots" 2>&1)"
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #
    # check for no files to merge
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "checking for no region services files to merge "
    if [[ "$count_files_snapshots" -eq 0 ]] 
        then 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "there are no region services files to merge "
            fnEcho ${LINENO} "skipping to next via the 'continue' command "
            #
            continue
            #
    fi  # end check for no files to merge 
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading variable: 'counter_files_snapshots' "
    counter_files_snapshots=0
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'counter_files_snapshots': "
    feed_write_log="$(echo "$counter_files_snapshots" 2>&1)"
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "read the list of snapshot files and merge the services"
    fnEcho ${LINENO} ""  
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------- entering loop: read variable 'files_snapshots' -----------------------  "
    fnEcho ${LINENO} ""
    #
    while read -r files_snapshots_line
        do
            #
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "------------------------------------------------------------------------------------------  "                                            
            fnEcho ${LINENO} "----------------------- loop head: read variable 'files_snapshots' -----------------------  "
            fnEcho ${LINENO} "------------------------------------------------------------------------------------------  "  
            fnEcho ${LINENO} ""
            #
		    ##########################################################################
		    #
		    #
		    # value of variable 'files_snapshots_line' "$files_snapshots_line"    
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} " value of variable 'files_snapshots_line' "$files_snapshots_line"       "  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} ""             
            #
            ##########################################################################
            #
            #
            # display the header     
            #
            fnEcho ${LINENO} ""  
            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
            fnEcho ${LINENO} " display the header      "  
            fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
            fnEcho ${LINENO} ""  
            #          
            fnDisplayHeader
            #
            # display the task progress bar
            #
            fnDisplayProgressBarTask "$counter_aws_region_list" "$count_aws_region_list"
            #
            ##########################################################################
            #
            #
            # Creating merged 'all services' JSON file for the region     
            #
            fnEcho ${LINENO} ""  
            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
            fnEcho ${LINENO} " Creating merged 'all services' JSON file for the region      "  
            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
            fnEcho ${LINENO} ""  
            #
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "value of variable: 'counter_aws_snapshot_commands': "$counter_aws_snapshot_commands" "
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "value of variable: 'count_aws_snapshot_commands': "$count_aws_snapshot_commands" "
            fnEcho ${LINENO} ""         
            #           
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "Creating merged 'all services' JSON file for region: "$aws_region_fn_create_merged_services_json_file" "
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "Merging JSON file: "$files_snapshots_line" "
            #
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "pulling the service key values from the file "  
            fnEcho ${LINENO} "loading variable 'aws_service' "
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
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "value of variable 'aws_service':"
                    fnEcho ${LINENO} level_0 "$aws_service"
                    fnEcho ${LINENO} level_0 ""
                    #
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "contents of file "$write_path_snapshots"/"$files_snapshots_line":"
                    feed_write_log="$(cat "$write_path_snapshots"/"$files_snapshots_line" 2>&1)"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #                     
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "value of variable 'aws_service':"
            fnEcho ${LINENO} "$aws_service"
            fnEcho ${LINENO} ""
            #
            fnEcho ${LINENO} "loading variable 'aws_service_snapshot_name_underscore' "
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
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "value of variable 'aws_service_snapshot_name_underscore':"
                    fnEcho ${LINENO} level_0 "$aws_service_snapshot_name_underscore"
                    fnEcho ${LINENO} level_0 ""
                    #
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "contents of file "$write_path_snapshots"/"$files_snapshots_line":"
                    feed_write_log="$(cat "$write_path_snapshots"/"$files_snapshots_line" 2>&1)"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #                     
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "value of variable 'aws_service_snapshot_name_underscore':"
            fnEcho ${LINENO} "$aws_service_snapshot_name_underscore"
            fnEcho ${LINENO} ""
            #
            #
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "test for first time through; if so, then initialize the file "  
            if [[ "$counter_files_snapshots" = 0 ]] 
                then 
                    #
                    fnEcho ${LINENO} ""  
                    fnEcho ${LINENO} "this is the first time through the loop"  
                    fnEcho ${LINENO} "in the 'create merged services JSON file' section "    
                    fnEcho ${LINENO} "initializing the region 'merge services' data file "
                    #
                    file_target_initialize_region="$aws_region_fn_create_merged_services_json_file"
                    file_target_initialize_file="$this_utility_acronym"-merge-services-file-build.json
                    #
                    # calling function to initialize the output file 
                    fnInitializeWriteFileBuildPattern
                    # 
                    # feed_write_log="$(echo "{ \"account\": \"$aws_account\",\"regions\": [ { \"regionName\": \"$aws_region_fn_create_merged_services_json_file\",\"regionServices\": [ { \"serviceType\": \"$aws_service\",\"service\": [ ] } ] } ] }" > "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build.json  2>&1)"
                    #
                    fnEcho ${LINENO} ""
                    fnEcho ${LINENO} "Contents of file: "$this_utility_acronym"-merge-services-file-build.json "
                    fnEcho ${LINENO} ""  
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
                            fnEcho ${LINENO} level_0 ""
                            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                            fnEcho ${LINENO} level_0 "$feed_write_log"
                            fnEcho ${LINENO} level_0 ""
                            #
                            fnEcho ${LINENO} level_0 ""
                            fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"-merge-services-file-build.json:"
                            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build.json)"
                            fnEcho ${LINENO} level_0 "$feed_write_log"
                            fnEcho ${LINENO} level_0 ""
                            #                                 
                            # call the command / pipeline error function
                            fnErrorPipeline
                            #
                            #
                    fi
                    #
                    fnEcho ${LINENO} "$feed_write_log"
                    #
                    fnEcho ${LINENO} ""
                    fnEcho ${LINENO} ""
                    fnEcho ${LINENO} "load the target variable with the contents of the file: "$this_utility_acronym"-merge-services-file-build.json "
                    fnEcho ${LINENO} ""  
                    files_snapshots_target="$this_path_temp"/"$this_utility_acronym"-merge-services-file-build.json
                    fnEcho ${LINENO} ""
                    fnEcho ${LINENO} "value of variable 'files_snapshots_target': "
                    fnEcho ${LINENO} "$files_snapshots_target"
                    fnEcho ${LINENO} ""
                    #
                else 
                    fnEcho ${LINENO} ""  
                    fnEcho ${LINENO} "this is not the first time through the loop"  
                    fnEcho ${LINENO} ""  
            fi  # end check for first time through and initialize file 
            #
            # load the source variable with the path
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "loading variable 'files_snapshots_source_merge' with full source file path "
            files_snapshots_source_merge="$write_path_snapshots"/"$files_snapshots_line"
            #
            #
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "value of variable 'files_snapshots_source_merge':"
            fnEcho ${LINENO} "$files_snapshots_source_merge"
            fnEcho ${LINENO} ""
            #
            #
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "value of variable 'files_snapshots_target':"
            fnEcho ${LINENO} "$files_snapshots_target"
            fnEcho ${LINENO} ""
            #            
            #
            # call the array merge function  
            # parameters are: source target 
            # output file name of the function is: "$this_utility_acronym"-merge-services-file-build-temp.json
            fnMergeArraysServicesJsonFile "$files_snapshots_source_merge" "$files_snapshots_target"
            #
            #
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "Copying contents of file: "$this_utility_acronym"-merge-services-file-build-temp.json to file: "$this_utility_acronym"-merge-services-file-build.json  "
            fnEcho ${LINENO} ""  
            cp -f "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build-temp.json "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build.json
            fnEcho ${LINENO} ""  
            #
            #
            # check for debug log 
            if [[ "$logging" = 'z' ]] 
                then 
                    fnEcho ${LINENO} ""
                    fnEcho ${LINENO} "--------------------------------------------------------------"
                    fnEcho ${LINENO} ""
                    fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                    fnEcho ${LINENO} ""
                    fnEcho ${LINENO} "--------------------------------------------------------------"
                    fnEcho ${LINENO} "" 
                    fnEcho ${LINENO} ""                             
                    fnEcho ${LINENO} ""                    
                    fnEcho ${LINENO} ""
                    fnEcho ${LINENO} "Contents of file: "$this_utility_acronym"-merge-services-file-build.json "
                    fnEcho ${LINENO} ""  
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
                            fnEcho ${LINENO} level_0 ""
                            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                            fnEcho ${LINENO} level_0 "$feed_write_log"
                            fnEcho ${LINENO} level_0 ""
                            #
                            fnEcho ${LINENO} level_0 ""
                            fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"-merge-services-file-build.json:"
                            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build.json)"
                            fnEcho ${LINENO} level_0 "$feed_write_log"
                            fnEcho ${LINENO} level_0 ""
                            #                                         
                            # call the command / pipeline error function
                            fnErrorPipeline
                            #
                            #
                    fi
                    #
                    fnEcho ${LINENO} "$feed_write_log"
                        #     
            fi  # end check for debug log 
            #                       
            fnEcho ${LINENO} ""  
            fnEcho ${LINENO} ""  
            fnEcho ${LINENO} "increment the files_snapshots counter"
            counter_files_snapshots="$((counter_files_snapshots+1))" 
            fnEcho ${LINENO} "value of variable 'counter_files_snapshots': "$counter_files_snapshots" "
            fnEcho ${LINENO} "value of variable 'count_files_snapshots': "$count_files_snapshots" "
            fnEcho ${LINENO} ""
            #
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "------------------------------------------------------------------------------------------  "                            
            fnEcho ${LINENO} "----------------------- loop tail: read variable 'files_snapshots' -----------------------  "
            fnEcho ${LINENO} "------------------------------------------------------------------------------------------  "                            
            fnEcho ${LINENO} ""
            #
    done< <(echo "$files_snapshots")
    #
    #
    ##########################################################################
    #
    #
    # display the header     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " display the header      "  
    fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
    fnDisplayHeader
    #
    # display the task progress bar
    #
    fnDisplayProgressBarTask "$counter_aws_region_list" "$count_aws_region_list"
    #
    # display the sub-task progress bar
    #
    fnDisplayProgressBarTaskSub "$counter_files_snapshots" "$count_files_snapshots"
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable: '': "$counter_aws_snapshot_commands" "
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable: '': "$count_aws_snapshot_commands" "
    fnEcho ${LINENO} ""            
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------- done with loop: read variable 'files_snapshots' -----------------------  "
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""    
    fnEcho ${LINENO} "Copying the data file..."    
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading the variable 'this_file_account_region_services_all_target' based on the region value: "$aws_region_list_line" "
    # if not global, use the normal file name, if global, use the global file name 
    if [[ "$aws_region_list_line" != 'global' ]] 
        then 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "region is not global so setting file name to variable 'this_file_account_region_services_all': "$this_file_account_region_services_all" "
            this_file_account_region_services_all_target="$this_file_account_region_services_all"
        else 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "region is global so setting file name to to variable 'this_file_account_region_services_all_global': "$this_file_account_region_services_all_global" "
            this_file_account_region_services_all_target="$this_file_account_region_services_all_global"
    fi  # end check for region = 'global' to set the file name for the write  
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'this_file_account_region_services_all_target': "
    fnEcho ${LINENO} " "$this_file_account_region_services_all_target"  "
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "Copying contents of file: "$this_utility_acronym"-merge-services-file-build-temp.json to file: "$this_file_account_region_services_all_target"  "
    fnEcho ${LINENO} ""  
    cp -f "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build-temp.json "$this_file_account_region_services_all_target"
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
            #
            # check for debug log 
            if [[ "$logging" = 'z' ]] 
                then 
                    fnEcho ${LINENO} ""
                    fnEcho ${LINENO} "--------------------------------------------------------------"
                    fnEcho ${LINENO} ""
                    fnEcho ${LINENO} "parameter -g z enables the following log section for debugging" 
                    fnEcho ${LINENO} ""
                    fnEcho ${LINENO} "--------------------------------------------------------------"
                    fnEcho ${LINENO} "" 
                    fnEcho ${LINENO} ""                             
                    fnEcho ${LINENO} ""                       
                    fnEcho ${LINENO} "Contents of file: "$this_file_account_region_services_all_target" "
                    fnEcho ${LINENO} ""  
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
                            fnEcho ${LINENO} level_0 ""
                            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                            fnEcho ${LINENO} level_0 "$feed_write_log"
                            fnEcho ${LINENO} level_0 ""
                            #
                            fnEcho ${LINENO} level_0 ""
                            fnEcho ${LINENO} level_0 "contents of file "$this_file_account_region_services_all_target":"
                            feed_write_log="$(cat "$this_file_account_region_services_all_target")"
                            fnEcho ${LINENO} level_0 "$feed_write_log"
                            fnEcho ${LINENO} level_0 ""
                            #                                                    
                            # call the command / pipeline error function
                            fnErrorPipeline
                            #
                            #
                    fi
                    #
                    fnEcho ${LINENO} "$feed_write_log"
                    fnEcho ${LINENO} ""  
            #     
            fi  # end check for debug log 
            #                       
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "------------------------------ end create merged services JSON file -----------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
}
#
##########################################################################
#
#
# ---begin: function to create the merged 'all services' JSON file for all regions in the account
#
function fnCreateMergedServicesAllJsonFile()
{
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnCreateMergedServicesAllJsonFile' "
    fnEcho ${LINENO} ""
    #       
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading the variable 'aws_region_fn_create_merged_services_json_file' from the function parameter 1: "$ 1" "  
    aws_region_fn_create_merged_services_all_json_file=$1
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading the variable 'find_name_fn_create_merged_services_json_file' from the function parameter 1: "$ 2" "  
    find_name_fn_create_merged_services_all_json_file=$2
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_region_fn_create_merged_services_all_json_file': "$aws_region_fn_create_merged_services_all_json_file" "  
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'find_name_fn_create_merged_services_all_json_file': "$find_name_fn_create_merged_services_all_json_file" "  
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} level_0 "Pulling the AWS Services from AWS for region: "$aws_region_fn_create_merged_services_all_json_file"..."
    fnEcho ${LINENO} ""   
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "-------------------- begin: create merged 'all services - all regions' JSON file -------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # display the header     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " display the header      "  
    fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
    fnDisplayHeader
    #
    # load the variables
    #
    # initialize the counters
    #
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 "Creating merged 'all services' JSON file for account: "$aws_account" "
    fnEcho ${LINENO} level_0 ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "creating snapshot file list file: "$this_utility_acronym"'-snapshot-file-all-list.txt' "
    fnEcho ${LINENO} "command: find "$write_path_snapshots" -name "$find_name_fn_create_merged_services_all_json_file" -printf '%f\n' | sort > "$this_path_temp"/"$this_utility_acronym"'-snapshot-file-all-list.txt' "
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
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"'-snapshot-file-all-list.txt':"
                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot-file-all-list.txt 2>&1)"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #                     
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading variable: 'files_snapshots_all' "
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
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'files_snapshots_all':"
                fnEcho ${LINENO} level_0 "$files_snapshots_all"
                fnEcho ${LINENO} level_0 ""
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"'-snapshot-file-all-list.txt':"
                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot-file-list.txt 2>&1)"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #                     
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'files_snapshots_all': "
    feed_write_log="$(echo "$files_snapshots_all" 2>&1)"
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading variable: 'count_files_snapshots_all' "
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
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'count_files_snapshots_all':"
                fnEcho ${LINENO} level_0 "$count_files_snapshots_all"
                fnEcho ${LINENO} level_0 ""
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"'-snapshot-file-all-list.txt':"
                feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-snapshot-file-list.txt 2>&1)"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #                     
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'count_files_snapshots_all': "
    feed_write_log="$(echo "$count_files_snapshots_all" 2>&1)"
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading variable: 'counter_files_snapshots_all' "
    counter_files_snapshots_all=0
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'counter_files_snapshots_all': "
    feed_write_log="$(echo "$counter_files_snapshots_all" 2>&1)"
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""  
    # this initialization string also used to create the snapshot build target file via function fnInitializeWriteFileBuild
    fnEcho ${LINENO} "in the section: 'create merged 'all services - all regions' JSON file' "  
    fnEcho ${LINENO} "initializing the 'all services - all regions' merge services data file "
    #
    file_target_initialize_region="$aws_region_fn_create_merged_services_json_file"
    file_target_initialize_file="$this_utility_acronym"-merge-services-all-file-build.json
    #
    # calling function to initialize the output file 
    fnInitializeWriteFileBuildPattern
    # 
    # feed_write_log="$(echo "{ \"account\": \"$aws_account\",\"regions\": [ { \"regionName\": \"$aws_region_fn_create_merged_services_json_file\",\"regionServices\": [ { \"serviceType\": \"$aws_service\",\"service\": [ ] } ] } ] }" > "$this_path_temp"/"$this_utility_acronym"-merge-services-all-file-build.json  2>&1)"
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "Contents of file: "$this_utility_acronym"-merge-services-all-file-build.json"
    fnEcho ${LINENO} ""  
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
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"-merge-services-all-file-build.json:"
            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-merge-services-all-file-build.json)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                 
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    fnEcho ${LINENO} "$feed_write_log"
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "first time through the loop, so load the target variable with the contents of the file: "$this_utility_acronym"-merge-services-file-build.json "
    fnEcho ${LINENO} ""  
    files_snapshots_all_target="$this_path_temp"/"$this_utility_acronym"-merge-services-all-file-build.json
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'files_snapshots_all_target': "
    fnEcho ${LINENO} "$files_snapshots_all_target"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "read the list of snapshot files and merge the services"
    fnEcho ${LINENO} ""  
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------- entering loop: read variable 'files_snapshots_all' -----------------------  "
    fnEcho ${LINENO} ""
    #
    while read -r files_snapshots_all_line
        do
            #
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "----------------------------------------------------------------------------------------------  "                                            
            fnEcho ${LINENO} "----------------------- loop head: read variable 'files_snapshots_all' -----------------------  "
            fnEcho ${LINENO} "----------------------------------------------------------------------------------------------  "                                
            fnEcho ${LINENO} ""
            #
		    ##########################################################################
		    #
		    #
		    # value of variable 'files_snapshots_all_line' "$files_snapshots_all_line"    
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} " value of variable 'files_snapshots_all_line' "$files_snapshots_all_line"       "  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} ""             
            #
            ##########################################################################
            #
            #
            # display the header     
            #
            fnEcho ${LINENO} ""  
            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
            fnEcho ${LINENO} " display the header      "  
            fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
            fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
            fnEcho ${LINENO} ""  
            #          
            fnDisplayHeader
            #
            # display the task progress bar
            #
            fnDisplayProgressBarTask "$counter_aws_region_list" "$count_aws_region_list"
            #
            # display the sub-task progress bar
            #
            fnDisplayProgressBarTaskSub "$counter_files_snapshots_all" "$count_files_snapshots_all"
            #
            #
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "value of variable: 'counter_aws_snapshot_commands': "$counter_aws_snapshot_commands" "
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "value of variable: 'count_aws_snapshot_commands': "$count_aws_snapshot_commands" "
            fnEcho ${LINENO} ""         
            #            
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "Creating merged 'all services' JSON file for account: "$aws_account" "
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "Merging JSON file: "$files_snapshots_all_line" "
            #
            # load the source variable with the path
            fnEcho ${LINENO} "loading variable 'files_snapshots_all_source_merge' with full source file path "
            files_snapshots_all_source_merge="$write_path_snapshots"/"$files_snapshots_all_line"
            #
            #
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "value of variable 'files_snapshots_all_source_merge':"
            fnEcho ${LINENO} "$files_snapshots_all_source_merge"
            fnEcho ${LINENO} ""
            #
            #
            # call the array merge function  
            # parameters are: source target 
            # output file name of the function is: "$this_utility_acronym"-merge-services-file-build-temp.json
            fnMergeArraysServicesJsonFile "$files_snapshots_all_source_merge" "$files_snapshots_all_target"
            #
            #
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "Copying contents of file: "$this_utility_acronym"-merge-services-file-build-temp.json to file: "$this_utility_acronym"-merge-services-file-build.json  "
            fnEcho ${LINENO} ""  
            cp -f "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build-temp.json "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build.json
            fnEcho ${LINENO} ""  
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "Contents of file: "$this_utility_acronym"-merge-services-file-build.json "
            fnEcho ${LINENO} ""  
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
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "contents of file "$this_utility_acronym"-merge-services-file-build.json:"
                    feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build.json)"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #                                         
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
                    #
            fi
            #
            fnEcho ${LINENO} "$feed_write_log"
            #
            fnEcho ${LINENO} ""  
            #
            fnEcho ${LINENO} ""  
            fnEcho ${LINENO} "set the target variable 'files_snapshots_all_target' to "$this_utility_acronym"-merge-services-file-build.json "
            files_snapshots_all_target="$this_path_temp"/"$this_utility_acronym"-merge-services-file-build.json
            #
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "value of variable 'files_snapshots_all_target':"
            fnEcho ${LINENO} "$files_snapshots_all_target"
            fnEcho ${LINENO} ""
            #
            fnEcho ${LINENO} ""  
            fnEcho ${LINENO} "increment the files_snapshots_all counter"
            counter_files_snapshots_all="$((counter_files_snapshots_all+1))" 
            fnEcho ${LINENO} "value of variable 'counter_files_snapshots_all': "$counter_files_snapshots_all" "
            fnEcho ${LINENO} "value of variable 'count_files_snapshots_all': "$count_files_snapshots_all" "
            fnEcho ${LINENO} ""
            #
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "----------------------------------------------------------------------------------------------  "                            
            fnEcho ${LINENO} "----------------------- loop tail: read variable 'files_snapshots_all' -----------------------  "
            fnEcho ${LINENO} "----------------------------------------------------------------------------------------------  "                            
            fnEcho ${LINENO} ""
            #
    done< <(echo "$files_snapshots_all")
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------- done with loop: read variable 'files_snapshots_all' -----------------------  "
    fnEcho ${LINENO} ""
    #
    #
    #
    ##########################################################################
    #
    #
    # display the header     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " display the header      "  
    fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
    fnDisplayHeader
    #
    # display the task progress bar
    #
    fnDisplayProgressBarTask "$counter_aws_region_list" "$count_aws_region_list"
    #
    # display the sub-task progress bar
    #
    fnDisplayProgressBarTaskSub "$counter_files_snapshots_all" "$count_files_snapshots_all"
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable: '': "$counter_aws_snapshot_commands" "
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable: '': "$count_aws_snapshot_commands" "
    fnEcho ${LINENO} ""         
    #   
    fnEcho ${LINENO} level_0 ""    
    fnEcho ${LINENO} level_0 "Copying the data file..."    
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "Copying contents of file: "$this_utility_acronym"-merge-services-file-build-temp.json to file: "$this_file_account_services_all"  "
    fnEcho ${LINENO} ""  
    cp -f "$this_path_temp"/"$this_utility_acronym"-merge-services-file-build-temp.json "$this_file_account_services_all"
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "Contents of file: "$this_file_account_services_all" "
    fnEcho ${LINENO} ""  
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
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_file_account_services_all":"
            feed_write_log="$(cat "$this_file_account_services_all")"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""  
    #
	##########################################################################
	#
	#
	# increment the task counter    
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " increment the task counter      "  
	fnEcho ${LINENO} " calling function 'fnCounterIncrementTask'      "               
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
	fnCounterIncrementTask
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "--------------------- end: create merged 'all services - all regions' JSON file --------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} ""
}
#
##########################################################################
#
#
# ---begin: function to count the AWS commands 
# call with: fnCountDriverServices "$file_snapshot_driver_stripped_file_name"
#
function fnCountDriverServices()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnCountDriverServices'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnCountDriverServices'      "   
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnCountDriverServices' "
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'file_snapshot_driver_stripped_file_name': "$file_snapshot_driver_stripped_file_name" "
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "counting this file':"
    fnEcho ${LINENO} ""$this_path_temp"/"$file_snapshot_driver_stripped_file_name" "
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading variable 'count_driver_services' "
    count_driver_services="$(cat "$this_path_temp"/"$file_snapshot_driver_stripped_file_name" | grep "^[^#]" | wc -l)"
    if [[ "$count_driver_services" -le 0 ]] 
        then 
            fnEcho ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 " Error reading the file: "
            fnEcho ${LINENO} level_0 " "$this_path_temp"/"$file_snapshot_driver_stripped_file_name" "
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 " Please confirm that at least one AWS service is enabled for snapshot  "
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 " The log will also show the AWS error message and other diagnostic information "
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 " The log is located here: "
            fnEcho ${LINENO} level_0 " "$this_log_file_full_path""
            fnEcho ${LINENO} level_0 ""        
            fnEcho ${LINENO} level_0 " Exiting the script"
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
            fnEcho ${LINENO} level_0 ""
            # delete the work files
            # fnDeleteWorkFiles
            # append the temp log onto the log file
            fnFileAppendLogTemp
            # write the log variable to the log file
            fnFileAppendLog
            exit 1
    fi 
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'count_driver_services': "$count_driver_services" "
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # end function 'fnCountDriverServices'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnCountDriverServices'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
}
#
##########################################################################
#
#
# afunction to create aws_command_underscore
#
function fnAwsCommandUnderscore()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnAwsCommandUnderscore'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnAwsCommandUnderscore'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnAwsCommandUnderscore' "
    fnEcho ${LINENO} ""
    #       
    #
    #
    ##########################################################################
    #
    #
    # stripping trailing 'new line' from inputs and creating underscore version     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " stripping trailing 'new line' from inputs and creating underscore version     "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
    # do not quote the $'\n' variable 
    aws_service="${aws_service//$'\n'/}"
    aws_command="${aws_command//$'\n'/}"
    # create underscore version
    aws_command_underscore="$(echo "$aws_command" | tr '-' '_')"
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_command_underscore': "$aws_command_underscore" "
    fnEcho ${LINENO} ""       
    #
    ##########################################################################
    #
    #
    # end function 'fnAwsCommandUnderscore'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnAwsCommandUnderscore'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to count_global_services_names
#
function fnCountGlobalServicesNames()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnCountGlobalServicesNames'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnCountGlobalServicesNames'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnCountGlobalServicesNames' "
    fnEcho ${LINENO} ""
    #       
    #
    ##########################################################################
    #
    #
    # loading the variable 'count_global_services_names     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " loading the variable 'count_global_services_names      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    # getting a pipeline error if the file is empty, so hard-coding the result here
    if [[ "$(cat "$this_path_temp"/"$file_snapshot_driver_global_services_file_name" | grep -v -e '^$' | wc -l 2>&1)" = 0 ]]
        then
            fnEcho ${LINENO} " file is empty; setting variable 'count_global_services_names' to 0     "       
            count_global_services_names=0
    elif [[ ! -f "$this_path_temp"/"$file_snapshot_driver_global_services_file_name" ]]
        then 
            fnEcho ${LINENO} " file does not exist; setting variable 'count_global_services_names' to 0     "                   
            count_global_services_names=0
        else 
            fnEcho ${LINENO} " file exists and is not empty; setting variable 'count_global_services_names' to non-empty line count "                       
            count_global_services_names="$(cat "$this_path_temp"/"$file_snapshot_driver_global_services_file_name" | grep -v -e '^$' | wc -l 2>&1)"
            #
            # check for command / pipeline error(s)
            if [ "$?" -ne 0 ]
                then
                    #
                    # set the command/pipeline error line number
                    error_line_pipeline="$((${LINENO}-7))"
                    #
                    #
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "value of variable 'count_global_services_names':"
                    fnEcho ${LINENO} level_0 "$count_global_services_names"
                    fnEcho ${LINENO} level_0 ""
                    #                                                                                                                                                                           #
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_global_services_file_name":"
                    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_global_services_file_name" 2>&1)"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #                                                                                                                                                                                                    
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
                    #
            fi
            #
    fi # end check for file
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'count_global_services_names': "$count_global_services_names" "  
    fnEcho ${LINENO} "" 
    #
    #
    ##########################################################################
    #
    #
    # end function 'fnCountGlobalServicesNames'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnCountGlobalServicesNames'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to set the snapshot name variable: 'aws_snapshot_name' and create underscore version
#
function fnLoadSnapshotNameVariable()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnLoadSnapshotNameVariable'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnLoadSnapshotNameVariable'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnLoadSnapshotNameVariable' "
    fnEcho ${LINENO} ""
    #       
    #
    ##########################################################################
    #
    #
    #
    # setting the snapshot name variable: 'aws_snapshot_name' and creating underscore version
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " setting the snapshot name variable: 'aws_snapshot_name' and creating underscore version "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #             
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_command': "$aws_command" "
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_command_underscore': "$aws_command_underscore" "
    fnEcho ${LINENO} ""       
    fnEcho ${LINENO} "parsing the snapshot name from the aws_command"
    fnEcho ${LINENO} "loading variable 'aws_snapshot_name'"    
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
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'aws_snapshot_name':"
            fnEcho ${LINENO} level_0 "$aws_snapshot_name"
            fnEcho ${LINENO} level_0 ""
            #                                                                                                                                            
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_snapshot_name': "$aws_snapshot_name" "
    fnEcho ${LINENO} ""  
    #
    # create underscore version
    aws_snapshot_name_underscore="$(echo "$aws_snapshot_name" | tr '-' '_')"
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_snapshot_name_underscore': "$aws_snapshot_name_underscore" "
    fnEcho ${LINENO} ""  
    #
    #
    ##########################################################################
    #
    #
    # end function 'fnLoadSnapshotNameVariable'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnLoadSnapshotNameVariable'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to load the service-snapshot variables
#
function fnLoadServiceSnapshotVariables()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnLoadServiceSnapshotVariables'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnLoadServiceSnapshotVariables'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnLoadServiceSnapshotVariables' "
    fnEcho ${LINENO} ""
    #       
    #
    ##########################################################################
    #
    #
    # loading the service-snapshot variables
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " loading the service-snapshot variables "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #           
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_service': "$aws_service" "     
    fnEcho ${LINENO} "value of variable 'aws_command': "$aws_command" "
    fnEcho ${LINENO} "value of variable 'aws_command_underscore': "$aws_command_underscore" "
	#                    
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading variable 'aws_service_underscore' "
    aws_service_underscore="$(echo "$aws_service" | sed s/-/_/g | tr -d '@')"   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_service_underscore': "$aws_service_underscore" "  
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} "value of variable 'aws_snapshot_name': "$aws_snapshot_name" "  
    aws_service_snapshot_name="$(echo "$aws_service"---"$aws_snapshot_name")"   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_service_snapshot_name': "$aws_service_snapshot_name" "  
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading variable 'aws_service_snapshot_name_underscore' "
    aws_service_snapshot_name_underscore="$(echo "$aws_service_snapshot_name" | sed s/-/_/g | tr -d '@')"   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_service_snapshot_name_underscore': "$aws_service_snapshot_name_underscore" "  
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading variable 'aws_service_snapshot_name_underscore_load' "
    aws_service_snapshot_name_underscore_load=${aws_service_snapshot_name_underscore}_load
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_service_snapshot_name_underscore_load': "$aws_service_snapshot_name_underscore_load" "  
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "setting base target table value: 'aws_service_snapshot_name_underscore_base'"
    aws_service_snapshot_name_underscore_base="$aws_service_snapshot_name_underscore"
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable: 'aws_service_snapshot_name_underscore_base': "
    fnEcho ${LINENO} "$aws_service_snapshot_name_underscore_base"
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading variable 'aws_service_snapshot_name_underscore_load' "
    aws_service_snapshot_name_underscore_load=${aws_service_snapshot_name_underscore}_load
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading variable 'aws_service_snapshot_name_table_underscore' "
    fnEcho ${LINENO} "testing for empty AWS CLI command parameter_01; if not empty, include parameter_01 in name' "   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_command_parameter_01': "$aws_command_parameter_01" "  
    fnEcho ${LINENO} ""    
    if [[ "$aws_command_parameter_01" = '' ]] 
        then 
            aws_service_snapshot_name_table_underscore_long="$(echo "$aws_service_snapshot_name" | sed s/-/_/g | tr -d '@')"   
        else 
        	aws_service_snapshot_name_table_underscore_long="$(echo "$aws_service_underscore"'__'"$aws_command_underscore" | sed s/-/_/g | tr -d '@')"
            # aws_service_snapshot_name_table_underscore_long="$(echo "$aws_service_snapshot_name"'_'"$aws_command_underscore"| sed s/-/_/g | tr -d '@')"   
    fi
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_service_snapshot_name_table_underscore_long': "$aws_service_snapshot_name_table_underscore_long" "  
    fnEcho ${LINENO} ""
    #
	fnEcho ${LINENO} ""
    fnEcho ${LINENO} "counting table name length - PostgreSQL limit is 63, need 3 for '_ld' and 4 for count '_000' "
    fnEcho ${LINENO} ""
	count_db_table_name="$(echo "$aws_service_snapshot_name_table_underscore_long" | wc -c 2>&1)"    
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'count_db_table_name': "$count_db_table_name" "  
    fnEcho ${LINENO} ""
    #
	fnEcho ${LINENO} ""
    fnEcho ${LINENO} "truncating name if longer than 60 to length 56, need 3 for '_ld' and 4 for count '_000' "
    fnEcho ${LINENO} ""
    if [[ "$count_db_table_name" -gt 60 ]] 
    	then
			fnEcho ${LINENO} ""
		    fnEcho ${LINENO} "table name is longer than 60 characters "
			fnEcho ${LINENO} ""	    
    		aws_service_snapshot_name_table_underscore_build="$(echo "$aws_service_snapshot_name_table_underscore_long" | cut -c -56 2>&1)"
    		#
    		aws_service_snapshot_name_table_underscore="$aws_service_snapshot_name_table_underscore_build"'_'"$counter_db_table_name"
    		#
		    fnEcho ${LINENO} ""
		    fnEcho ${LINENO} "value of variable 'aws_service_snapshot_name_table_underscore_build': "$aws_service_snapshot_name_table_underscore_build" "  	    
		    fnEcho ${LINENO} "value of variable 'aws_service_snapshot_name_table_underscore': "$aws_service_snapshot_name_table_underscore" "  
		    fnEcho ${LINENO} ""
			#
			fnEcho ${LINENO} ""
		    fnEcho ${LINENO} "incrementing table name counter "
		    counter_db_table_name="$((counter_db_table_name+1))"
		    #
    		#
		    fnEcho ${LINENO} ""
		    fnEcho ${LINENO} "value of variable 'counter_db_table_name': "$counter_db_table_name" "  
		    fnEcho ${LINENO} ""
			#
		else 
			fnEcho ${LINENO} ""
		    fnEcho ${LINENO} "table name is 60 or fewer characters "
			fnEcho ${LINENO} ""	    
			aws_service_snapshot_name_table_underscore="$aws_service_snapshot_name_table_underscore_long"
    		#
		    fnEcho ${LINENO} ""
		    fnEcho ${LINENO} "value of variable 'aws_service_snapshot_name_table_underscore': "$aws_service_snapshot_name_table_underscore" "  
		    fnEcho ${LINENO} ""
			#
	fi # end test of table name length			    
	#
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading variable 'aws_service_snapshot_name_table_underscore_load' "
    aws_service_snapshot_name_table_underscore_load=${aws_service_snapshot_name_table_underscore}_ld
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_service_snapshot_name_table_underscore_load': "$aws_service_snapshot_name_table_underscore_load" "  
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading variable 'aws_snapshot_name_underscore' "
    aws_snapshot_name_underscore="$(echo "$aws_snapshot_name" | sed s/-/_/g 2>&1)"   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_snapshot_name_underscore': "$aws_snapshot_name_underscore" "  
    fnEcho ${LINENO} ""
    #
    #        
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading variable 'aws_command_parameter_string' "
    aws_command_parameter_string_build="$aws_command_parameter_01"' '"$aws_command_parameter_01_value"' '"$aws_command_parameter_02"' '"$aws_command_parameter_02_value"' '"$aws_command_parameter_03"' '"$aws_command_parameter_03_value"' '"$aws_command_parameter_04"' '"$aws_command_parameter_04_value"' '"$aws_command_parameter_05"' '"$aws_command_parameter_05_value"' '"$aws_command_parameter_06"' '"$aws_command_parameter_06_value"' '"$aws_command_parameter_07"' '"$aws_command_parameter_07_value"' '"$aws_command_parameter_08"' '"$aws_command_parameter_08_value"
    aws_command_parameter_string="$(echo -e "${aws_command_parameter_string_build}" | sed -e 's/[[:space:]]*$//' | tr -d '\n')"
    count_aws_command_parameter_string_no_newline="$(echo -n "$aws_command_parameter_string" | wc --chars 2>&1)"
    count_aws_command_parameter_string_with_newline="$(echo "$aws_command_parameter_string" | wc --chars 2>&1)" 
    #
    # echo variable to a file
    feed_write_log="$(echo "$aws_command_parameter_string" > "$this_path_temp"/"$this_utility_acronym"-aws_command_parameter_string.txt 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$this_utility_acronym"-aws_command_parameter_string.txt:"
            feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-aws_command_parameter_string.txt)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                                                                                                                                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_command_parameter_string': "$aws_command_parameter_string" "  
    fnEcho ${LINENO} "value of variable 'count_aws_command_parameter_string_no_newline': "$count_aws_command_parameter_string_no_newline" " 
    fnEcho ${LINENO} "value of variable 'count_aws_command_parameter_string_with_newline': "$count_aws_command_parameter_string_with_newline" " 
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # end function 'fnLoadServiceSnapshotVariables'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnLoadServiceSnapshotVariables'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to create the stripped driver file 
# prior to call, set the variables 'file_snapshot_driver_file_name' and 'file_snapshot_driver_stripped_file_name' 
#
function fnStrippedDriverFileCreate()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnStrippedDriverFileCreate'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnStrippedDriverFileCreate'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #       
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnStrippedDriverFileCreate' "
    fnEcho ${LINENO} ""
    #       
    #
    ###################################################
    #
    #
    # create the stripped driver file 
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " create the stripped driver file     "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "contents of file "$this_path_temp"/"$file_snapshot_driver_file_name": "
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_file_name" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_file_name" "
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    fnEcho ${LINENO} "$feed_write_log"
    #
    #
    # create the clean driver file
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "creating clean driver file: "$this_path_temp"/"$file_snapshot_driver_stripped_file_name" "
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_file_name" | grep "^[^#]" | sed 's/\r$//' | grep . | grep -v ^$ | grep -v '^ $' > "$this_path_temp"/"$file_snapshot_driver_stripped_file_name" 2>&1)"
    fnEcho ${LINENO} "$feed_write_log"
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "contents of file "$this_path_temp"/"$file_snapshot_driver_stripped_file_name": "
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_stripped_file_name" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_stripped_file_name" "
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_stripped_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    fnEcho ${LINENO} "$feed_write_log"
    #
    ##########################################################################
    #
    #
    # end function 'fnStrippedDriverFileCreate'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnStrippedDriverFileCreate'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to create the stripped driver file 
# prior to call, set the variables 'file_snapshot_driver_file_name' and 'file_snapshot_driver_stripped_file_name' 
#
function fnAwsPullSnapshotsRecursiveLoopTail()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnAwsPullSnapshotsRecursiveLoopTail'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnAwsPullSnapshotsRecursiveLoopTail      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnStrippedDriverFileCreate' "
    fnEcho ${LINENO} ""
    #       
    #
    ##########################################################################
    #
    #
    # increment the variable 'counter_driver_services'
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} "increment the variable 'counter_driver_services' " 
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                  
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'counter_driver_services':"
    feed_write_log="$(echo "$counter_driver_services" 2>&1)"
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "increment the write counter: 'counter_driver_services'"
    counter_driver_services="$((counter_driver_services+1))"
    fnEcho ${LINENO} "post-increment value of variable 'counter_driver_services': "$counter_driver_services" "
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'count_driver_services':"
    feed_write_log="$(echo "$count_driver_services" 2>&1)"
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # check for overrun; exit if loop is not stopping properly
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} "check for overrun; exit if loop is not stopping properly " 
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                  
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "checking for overrun of the write counter: 'counter_driver_services'"
    if [[ "$counter_driver_services" -gt "$count_driver_services" ]]  
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-5))"
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "service counter overrun error "
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'counter_driver_services':"
            fnEcho ${LINENO} level_0 "$counter_driver_services"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'count_driver_services':"
            fnEcho ${LINENO} level_0 "$count_driver_services"
            fnEcho ${LINENO} level_0 ""
            #
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi  # end check for services_driver_list loop overrun 
    #
    #
    #
    ##########################################################################
    #
    #
    # resetting the recursive loop line variables
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} "resetting the recursive loop line variables "               
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                  
    aws_command_parameter_01=""  
    aws_command_parameter_02=""  
    aws_command_parameter_03=""  
    aws_command_parameter_04=""  
    aws_command_parameter_05=""  
    aws_command_parameter_06=""  
    aws_command_parameter_07=""  
    aws_command_parameter_08="" 
    aws_command_parameter_01_value=""
    aws_command_parameter_02_value=""
    aws_command_parameter_03_value=""
    aws_command_parameter_04_value=""
    aws_command_parameter_05_value=""
    aws_command_parameter_06_value=""
    aws_command_parameter_07_value=""
    aws_command_parameter_08_value=""
    #
    parameter_01_source_key="" 
    parameter_02_source_key="" 
    parameter_03_source_key="" 
    parameter_04_source_key="" 
    parameter_05_source_key="" 
    parameter_06_source_key="" 
    parameter_07_source_key="" 
    parameter_08_source_key=""
    parameter_01_source_table="" 
    parameter_02_source_table="" 
    parameter_03_source_table="" 
    parameter_04_source_table="" 
    parameter_05_source_table="" 
    parameter_06_source_table="" 
    parameter_07_source_table="" 
    parameter_08_source_table="" 
    #
    #
    ##########################################################################
    #
    #
    # set the AWS command prior variables
    # calling function: 'fnVariablePriorSet'
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} "set the prior variables   "  
    fnEcho ${LINENO} "calling function: 'fnVariablePriorSet' "         
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
	fnVariablePriorSet 
    #
    ##########################################################################
    #
    #
    # increment the snapshot counter
    # calling function: 'fnCounterIncrementSnapshots'
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} "increment the snapshot counter "               
    fnEcho ${LINENO} "calling function: 'fnCounterIncrementSnapshots' "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                  
    fnCounterIncrementSnapshots
    #
    ##########################################################################
    #
    #
    # increment the AWS snapshot command counter
    # calling function: 'fnCounterIncrementAwsSnapshotCommands'
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} "increment the AWS snapshot command counter "               
    fnEcho ${LINENO} "calling function: 'fnCounterIncrementAwsSnapshotCommands' "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                  
    fnCounterIncrementAwsSnapshotCommands
    #
    ##########################################################################
    #
    #
    # write out the temp log and empty the log variable
    # calling function: 'fnFileAppendLogTemp'
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} "write out the temp log and empty the log variable " 
    fnEcho ${LINENO} "calling function: 'fnFileAppendLogTemp' "        
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #           
    fnFileAppendLogTemp       
    #
    ##########################################################################
    #
    #
    # end function 'fnAwsPullSnapshotsRecursiveLoopTail'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnAwsPullSnapshotsRecursiveLoopTail      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to create the stripped driver file 
# prior to call, set the variables 'file_snapshot_driver_file_name' and 'file_snapshot_driver_stripped_file_name' 
#
function fnWriteFileVariablesSet()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnWriteFileVariablesSet'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnWriteFileVariablesSet      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnWriteFileVariablesSet' "
    fnEcho ${LINENO} ""
    #       
    #
    ##########################################################################
    #
    #
    # set the write file variables      
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " set the write file variables       "  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    write_file_raw="aws-""$aws_account"-"$aws_region_list_line_parameter"-snapshot-"$date_file"-"$aws_service"-"$aws_command".json
    # write_file_raw="aws-""$aws_account"-"$aws_region_list_line_parameter"-snapshot-"$date_file"-"$aws_service"-"$aws_snapshot_name".json
    fnEcho ${LINENO} "value of variable 'write_file_raw': "$write_file_raw" "
    write_file_clean="$(echo "$write_file_raw" | tr "/%\\<>:" "_" 2>&1)"
    fnEcho ${LINENO} "value of variable 'write_file_clean': "$write_file_clean" "
    write_file="$(echo "$write_file_clean")"
    write_file_full_path="$write_path_snapshots"/"$write_file"
    fnEcho ${LINENO} "value of variable 'write_file': "$write_file" "
    fnEcho ${LINENO} "value of variable 'write_file_full_path': "$write_file_full_path" "
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
	#
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} "Initialize the JSON file for "$aws_service"-"$aws_snapshot_name"-"$aws_command" "
	fnEcho ${LINENO} "Creating file: "$write_file_full_path""
	fnEcho ${LINENO} ""  
    #
    ##########################################################################
    #
    #
    # initialze the target region / service write file    
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " initialze the target region / service write file     "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                  
    #
    ##########################################################################
    #
    #
    # calling function 'fnInitializeWriteFileBuild'    
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " calling function 'fnInitializeWriteFileBuild'      "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                  
    fnInitializeWriteFileBuild
    #
    ##########################################################################
    #
    #
    # end function 'fnWriteFileVariablesSet'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnWriteFileVariablesSet'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to load the variables with prior values
#
function fnVariablePriorSet()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnVariablePriorSet'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnVariablePriorSet     "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnVariablePriorSet' "
    fnEcho ${LINENO} ""
    #
    # load prior from variables 
	aws_service_prior="$aws_service"  
	aws_command_prior="$aws_command" 
	aws_command_parameter_01_prior="$aws_command_parameter_01"            
	aws_command_parameter_01_value_prior="$aws_command_parameter_01_value" 
	aws_command_parameter_02_prior="$aws_command_parameter_02" 
	aws_command_parameter_02_value_prior="$aws_command_parameter_02_value"
	aws_command_parameter_03_prior="$aws_command_parameter_03"
	aws_command_parameter_03_value_prior="$aws_command_parameter_03_value"  
	aws_command_parameter_04_prior="$aws_command_parameter_04"
	aws_command_parameter_04_value_prior="$aws_command_parameter_04_value"     
	aws_command_parameter_05_prior="$aws_command_parameter_05"    
	aws_command_parameter_05_value_prior="$aws_command_parameter_05_value"     
	aws_command_parameter_06_prior="$aws_command_parameter_06"   
	aws_command_parameter_06_value_prior="$aws_command_parameter_06_value"     
	aws_command_parameter_07_prior="$aws_command_parameter_07"     
	aws_command_parameter_07_value_prior="$aws_command_parameter_07_value"         
	aws_command_parameter_08_prior="$aws_command_parameter_08"       
	aws_command_parameter_08_value_prior="$aws_command_parameter_08_value"       
    #
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "post-set values of variables: "	
    fnEcho ${LINENO} ""
    #
	fnEcho ${LINENO} "value of variable 'aws_service_prior' "$aws_service_prior" "
	fnEcho ${LINENO} "value of variable 'aws_command_prior' "$aws_command_prior" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_01_prior' "$aws_command_parameter_01_prior" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_01_value_prior' "$aws_command_parameter_01_value_prior" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_02_prior' "$aws_command_parameter_02_prior" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_02_value_prior' "$aws_command_parameter_02_value_prior" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_03_prior' "$aws_command_parameter_03_prior" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_03_value_prior' "$aws_command_parameter_03_value_prior" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_04_prior' "$aws_command_parameter_04_prior" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_04_value_prior' "$aws_command_parameter_04_value_prior" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_05_prior' "$aws_command_parameter_05_prior" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_05_value_prior' "$aws_command_parameter_05_value_prior" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_06_prior' "$aws_command_parameter_06_prior" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_06_value_prior' "$aws_command_parameter_06_value_prior" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_07_prior' "$aws_command_parameter_07_prior" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_07_value_prior' "$aws_command_parameter_07_value_prior" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_08_prior' "$aws_command_parameter_08_prior" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_08_value_prior' "$aws_command_parameter_08_value_prior" "
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # end function 'fnVariablePriorSet'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnVariablePriorSet'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to load the variables with prior values
#
function fnVariablePriorLoad()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnVariablePriorLoad'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnVariablePriorLoad     "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnVariablePriorLoad' "
    fnEcho ${LINENO} ""
    #       
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} "setting the variables: 'aws_service_snapshot_name_table_underscore' and "
    fnEcho ${LINENO} "'aws_service_snapshot_name_table_underscore_load' to prior versions "     
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #  empty the backup variables
	aws_service_backup=""
	aws_command_backup=""
	aws_command_parameter_01_backup=""
	aws_command_parameter_01_value_backup=""
	aws_command_parameter_02_backup=""
	aws_command_parameter_02_value_backup=""
	aws_command_parameter_03_backup=""
	aws_command_parameter_03_value_backup=""
	aws_command_parameter_04_backup=""
	aws_command_parameter_04_value_backup=""
	aws_command_parameter_05_backup=""
	aws_command_parameter_05_value_backup=""
	aws_command_parameter_06_backup=""
	aws_command_parameter_06_value_backup=""
	aws_command_parameter_07_backup=""
	aws_command_parameter_07_value_backup=""
	aws_command_parameter_08_backup=""
	aws_command_parameter_08_value_backup=""
	#
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "pre-load values of variables: "	
    fnEcho ${LINENO} ""
    #
	fnEcho ${LINENO} "value of variable 'aws_service_backup': "$aws_service_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_backup': "$aws_command_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_01_backup': "$aws_command_parameter_01_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_01_value_backup': "$aws_command_parameter_01_value_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_02_backup': "$aws_command_parameter_02_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_02_value_backup': "$aws_command_parameter_02_value_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_03_backup': "$aws_command_parameter_03_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_03_value_backup': "$aws_command_parameter_03_value_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_04_backup': "$aws_command_parameter_04_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_04_value_backup': "$aws_command_parameter_04_value_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_05_backup': "$aws_command_parameter_05_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_05_value_backup': "$aws_command_parameter_05_value_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_06_backup': "$aws_command_parameter_06_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_06_value_backup': "$aws_command_parameter_06_value_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_07_backup': "$aws_command_parameter_07_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_07_value_backup': "$aws_command_parameter_07_value_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_08_backup': "$aws_command_parameter_08_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_08_value_backup': "$aws_command_parameter_08_value_backup" "
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # display the AWS command variables       
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " display the AWS command variables       "       
    fnEcho ${LINENO} " calling function 'fnVariableNamesCommandDisplay'      "               
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
	fnVariableNamesCommandDisplay
    #
    # load backups from variables 
	aws_service_backup="$aws_service"
	aws_command_backup="$aws_command"
	aws_command_parameter_01_backup="$aws_command_parameter_01"
	aws_command_parameter_01_value_backup="$aws_command_parameter_01_value"
	aws_command_parameter_02_backup="$aws_command_parameter_02"
	aws_command_parameter_02_value_backup="$aws_command_parameter_02_value"
	aws_command_parameter_03_backup="$aws_command_parameter_03"
	aws_command_parameter_03_value_backup="$aws_command_parameter_03_value"
	aws_command_parameter_04_backup="$aws_command_parameter_04"
	aws_command_parameter_04_value_backup="$aws_command_parameter_04_value"
	aws_command_parameter_05_backup="$aws_command_parameter_05"
	aws_command_parameter_05_value_backup="$aws_command_parameter_05_value"
	aws_command_parameter_06_backup="$aws_command_parameter_06"
	aws_command_parameter_06_value_backup="$aws_command_parameter_06_value"
	aws_command_parameter_07_backup="$aws_command_parameter_07"
	aws_command_parameter_07_value_backup="$aws_command_parameter_07_value"
	aws_command_parameter_08_backup="$aws_command_parameter_08"
	aws_command_parameter_08_value_backup="$aws_command_parameter_08_value"
	#
	# load variables from prior 
	aws_service="$aws_service_prior" 
	aws_command="$aws_command_prior" 
	aws_command_parameter_01="$aws_command_parameter_01_prior" 
	aws_command_parameter_01_value="$aws_command_parameter_01_value_prior" 
	aws_command_parameter_02="$aws_command_parameter_02_prior" 
	aws_command_parameter_02_value="$aws_command_parameter_02_value_prior" 
	aws_command_parameter_03="$aws_command_parameter_03_prior" 
	aws_command_parameter_03_value="$aws_command_parameter_03_value_prior" 
	aws_command_parameter_04="$aws_command_parameter_04_prior" 
	aws_command_parameter_04_value="$aws_command_parameter_04_value_prior" 
	aws_command_parameter_05="$aws_command_parameter_05_prior" 
	aws_command_parameter_05_value="$aws_command_parameter_05_value_prior" 
	aws_command_parameter_06="$aws_command_parameter_06_prior" 
	aws_command_parameter_06_value="$aws_command_parameter_06_value_prior" 
	aws_command_parameter_07="$aws_command_parameter_07_prior" 
	aws_command_parameter_07_value="$aws_command_parameter_07_value_prior" 
	aws_command_parameter_08="$aws_command_parameter_08_prior" 
	aws_command_parameter_08_value="$aws_command_parameter_08_value_prior" 
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "post-load values of variables: "	
    fnEcho ${LINENO} ""
	fnEcho ${LINENO} "value of variable 'aws_service_backup': "$aws_service_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_backup': "$aws_command_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_01_backup': "$aws_command_parameter_01_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_01_value_backup': "$aws_command_parameter_01_value_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_02_backup': "$aws_command_parameter_02_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_02_value_backup': "$aws_command_parameter_02_value_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_03_backup': "$aws_command_parameter_03_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_03_value_backup': "$aws_command_parameter_03_value_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_04_backup': "$aws_command_parameter_04_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_04_value_backup': "$aws_command_parameter_04_value_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_05_backup': "$aws_command_parameter_05_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_05_value_backup': "$aws_command_parameter_05_value_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_06_backup': "$aws_command_parameter_06_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_06_value_backup': "$aws_command_parameter_06_value_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_07_backup': "$aws_command_parameter_07_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_07_value_backup': "$aws_command_parameter_07_value_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_08_backup': "$aws_command_parameter_08_backup" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_08_value_backup': "$aws_command_parameter_08_value_backup" "
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # display the AWS command variables       
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " display the AWS command variables       "       
    fnEcho ${LINENO} " calling function 'fnVariableNamesCommandDisplay'      "               
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
	fnVariableNamesCommandDisplay
    #
    ##########################################################################
    #
    #
    # end function 'fnVariablePriorLoad'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnVariablePriorLoad'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to restore the variables with backup values
#
function fnVariablePriorRestore()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnVariablePriorRestore'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnVariablePriorRestore'     "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnVariablePriorRestore' "
    fnEcho ${LINENO} ""
    #       
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} "restoring the variables: 'aws_service_snapshot_name_table_underscore' and "
    fnEcho ${LINENO} "'aws_service_snapshot_name_table_underscore_load' from backups "     
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "pre-restore values of variables: "				        
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # display the AWS command variables       
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " display the AWS command variables       "       
    fnEcho ${LINENO} " calling function 'fnVariableNamesCommandDisplay'      "               
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
	fnVariableNamesCommandDisplay
    #
    # restore variables from backup
	aws_service="$aws_service_backup"
	aws_command="$aws_command_backup"
	aws_command_parameter_01="$aws_command_parameter_01_backup"
	aws_command_parameter_01_value="$aws_command_parameter_01_value_backup"
	aws_command_parameter_02="$aws_command_parameter_02_backup"
	aws_command_parameter_02_value="$aws_command_parameter_02_value_backup"
	aws_command_parameter_03="$aws_command_parameter_03_backup"
	aws_command_parameter_03_value="$aws_command_parameter_03_value_backup"
	aws_command_parameter_04="$aws_command_parameter_04_backup"
	aws_command_parameter_04_value="$aws_command_parameter_04_value_backup"
	aws_command_parameter_05="$aws_command_parameter_05_backup"
	aws_command_parameter_05_value="$aws_command_parameter_05_value_backup"
	aws_command_parameter_06="$aws_command_parameter_06_backup"
	aws_command_parameter_06_value="$aws_command_parameter_06_value_backup"
	aws_command_parameter_07="$aws_command_parameter_07_backup"
	aws_command_parameter_07_value="$aws_command_parameter_07_value_backup"
	aws_command_parameter_08="$aws_command_parameter_08_backup"
	aws_command_parameter_08_value="$aws_command_parameter_08_value_backup"
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "post-restore values of variables: "				        
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # display the AWS command variables       
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " display the AWS command variables       "       
    fnEcho ${LINENO} " calling function 'fnVariableNamesCommandDisplay'      "               
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
	fnVariableNamesCommandDisplay
    #
    ##########################################################################
    #
    #
    # end function 'fnVariablePriorRestore'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnVariablePriorRestore'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to load the AWS command-related variable names
#
function fnVariableNamesCommandLoad()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnVariableNamesCommandLoad'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnVariableNamesCommandLoad'     "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnVariableNamesCommandLoad' "
    fnEcho ${LINENO} ""
    #       
    #
    ##########################################################################
    #
    #
    # creating AWS Command underscore version     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " creating AWS Command underscore version      "       
    fnEcho ${LINENO} " calling function 'fnAwsCommandUnderscore'      "               
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
    fnAwsCommandUnderscore
    #
    ##########################################################################
    #
    #
    # setting the AWS snapshot name variable and creating underscore version      
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " setting the AWS snapshot name variable and creating underscore version      "       
    fnEcho ${LINENO} " calling function 'fnLoadSnapshotNameVariable'      "               
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
    fnLoadSnapshotNameVariable
    #
    ##########################################################################
    #
    #
    # loading the service-snapshot variables    
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " loading the service-snapshot variables      "       
    fnEcho ${LINENO} " calling function 'fnLoadServiceSnapshotVariables'      "               
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
    fnLoadServiceSnapshotVariables
    #
    ##########################################################################
    #
    #
    # end function 'fnVariableNamesCommandLoad'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnVariableNamesCommandLoad'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to load the AWS recursive-command-related variable names
#
function fnVariableNamesCommandRecursiveLoad()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnVariableNamesCommandRecursiveLoad'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnVariableNamesCommandRecursiveLoad'     "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnVariableNamesCommandRecursiveLoad' "
    fnEcho ${LINENO} ""
    #       
    # check for recursive run type
    if [[ "$recursive_single_yn" = 'y' ]] || [[ "$recursive_single_dependent_yn" = 'y' ]]
        then 
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "this is a recursive-single run so there is only one parameter set  "
            fnEcho ${LINENO} "setting variable 'parameter_01_source_table' to value of variable 'aws_command_parameter_02'  "
            parameter_01_source_table="$aws_command_parameter_02"
            fnEcho ${LINENO} "setting variable 'parameter_01_source_key' to value of variable 'aws_command_parameter_02_value'  "  
            parameter_01_source_key="$aws_command_parameter_02_value"              
            #
            fnEcho ${LINENO} "value of variables 'aws_command_parameter_01' and 'aws_command_parameter_01_value': "$aws_command_parameter_01" "$aws_command_parameter_01_value" "
            fnEcho ${LINENO} "value of variables 'parameter_01_source_table' and 'parameter_01_source_key': "$parameter_01_source_table" "$parameter_01_source_key" "
            fnEcho ${LINENO} ""  
            #
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "loading variable 'aws_command_recursive'  "
            #
            aws_command_recursive="$aws_service"' '"$aws_command"' '"$aws_command_parameter_01"' '"$aws_command_parameter_01_value"
            #
        elif [[ "$recursive_multi_yn" = 'y' ]]  
            then 
                fnEcho ${LINENO} ""
                fnEcho ${LINENO} "this is a recursive-multi run "
                # set multi parameters
        else 
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "no recursive type set for recursive run  "
            fnEcho ${LINENO} level_0 "fatal error  "
            fnEcho ${LINENO} level_0 "exiting script   "
            exit 
            #
    fi # end test for recursive run type
    #
    ##########################################################################
    #
    #
    # value of variable 'aws_command_recursive'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " value of variable 'aws_command_recursive'     "       
    feed_write_log="$(echo "$aws_command_recursive" 2>&1)"
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    ##########################################################################
    #
    #
    # display the AWS command variables       
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " display the AWS command variables       "       
    fnEcho ${LINENO} " calling function 'fnVariableNamesCommandDisplay'      "               
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
	fnVariableNamesCommandDisplay
    #
    ##########################################################################
    #
    #
    # end function 'fnVariableNamesCommandRecursiveLoad'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnVariableNamesCommandRecursiveLoad'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to load the AWS recursive-command-related variable names
#
function fnVariableNamesCommandDisplay()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnVariableNamesCommandRecursiveLoad'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnVariableNamesCommandDisplay'     "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnVariableNamesCommandDisplay' "
    fnEcho ${LINENO} ""
    #    
    fnEcho ${LINENO} ""
	fnEcho ${LINENO} "value of variable 'aws_service': "$aws_service" "
	fnEcho ${LINENO} "value of variable 'aws_command': "$aws_command" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_01': "$aws_command_parameter_01" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_01_value': "$aws_command_parameter_01_value" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_02': "$aws_command_parameter_02" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_02_value': "$aws_command_parameter_02_value" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_03': "$aws_command_parameter_03" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_03_value': "$aws_command_parameter_03_value" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_04': "$aws_command_parameter_04" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_04_value': "$aws_command_parameter_04_value" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_05': "$aws_command_parameter_05" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_05_value': "$aws_command_parameter_05_value" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_06': "$aws_command_parameter_06" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_06_value': "$aws_command_parameter_06_value" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_07': "$aws_command_parameter_07" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_07_value': "$aws_command_parameter_07_value" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_08': "$aws_command_parameter_08" "
	fnEcho ${LINENO} "value of variable 'aws_command_parameter_08_value': "$aws_command_parameter_08_value" "
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # end function 'fnVariableNamesCommandDisplay'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnVariableNamesCommandDisplay'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to build the non-global and global command lists
#
function fnCommandListBuild()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnVariableNamesCommandRecursiveLoad'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnCommandListBuild'     "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnCommandListBuild' "
    fnEcho ${LINENO} ""
    #    
	#
	###################################################
	#
	#
	# query the database for: 
	# * aws services
	# * aws global services
	# * non-recursive aws cli commands
    # * recursive-single aws cli commands
    # * this is not built yet --> recursive-multi aws cli commands
    # * recursive-single-dependent aws cli commands
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " query the database for:     "
	fnEcho ${LINENO} " * aws services  "
	fnEcho ${LINENO} " * aws global services "
	fnEcho ${LINENO} " * non-recursive aws cli commands  "
    fnEcho ${LINENO} " * recursive-single aws cli commands  "
    # fnEcho ${LINENO} " * recursive-multi aws cli commands  "
    fnEcho ${LINENO} " * recursive-single-dependent aws cli commands  "	
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#                          
	#
	##########################################################################
	#
	#
	# building the services list
	# calling function: 'fnDbQueryServiceList'    
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " building the services list   "
	fnEcho ${LINENO} " calling function: 'fnDbQueryServiceList'  "   
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} "querying the database for: aws services"
	fnEcho ${LINENO} ""
	#
	fnDbQueryServiceList
	#
	#
	##########################################################################
	#
	#
	# pull the non-recursive command list
	# calling function: 'fnDbQueryCommandNonRecursiveList'    
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " pull the non-recursive command list   "
	fnEcho ${LINENO} " calling function: 'fnDbQueryCommandNonRecursiveList'  "   
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} "querying the database for: aws cli non-recursive commands"
	fnEcho ${LINENO} ""
	#
	fnDbQueryCommandNonRecursiveList
	#
	#
	###################################################
	#
	#
	# build the AWS command list of non-recursive commands 
	# calling function 'fnCommandNonRecursiveListBuild'
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " build the AWS command list of non-recursive commands       "
	fnEcho ${LINENO} " calling function 'fnCommandNonRecursiveListBuild'     "
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#                          
	fnCommandNonRecursiveListBuild
	#
	###################################################
	#
	#
	# create the source database tables for the recursive commands 
	# calling function 'fnDbQueryCommandRecursiveSourceTables'
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " create the source database tables for the recursive commands         "
	fnEcho ${LINENO} " calling function 'fnDbQueryCommandRecursiveSourceTables'     "
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} " set the run snapshot type for the source run        "
	fnEcho ${LINENO} " setting variable 'snapshot_type' to 'source-recursive'        "
	fnEcho ${LINENO} ""  
	#
	snapshot_type="source-recursive"
	#
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} " value of variable 'snapshot_type': "$snapshot_type"   " 
    fnEcho ${LINENO} ""  
    #
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} " set the commands count for the source run        "
	fnEcho ${LINENO} " setting variable 'count_driver_services' to 'count_aws_snapshot_commands_non_recursive'        "
	fnEcho ${LINENO} ""  
	#
	count_driver_services="$count_aws_snapshot_commands_non_recursive"
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "value of variable 'count_driver_services': "$count_driver_services" "  
	fnEcho ${LINENO} ""  
	#
	fnDbQueryCommandRecursiveSourceTables
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} " reset the run snapshot type         "
	fnEcho ${LINENO} " setting variable 'snapshot_type' to ''        "
	fnEcho ${LINENO} ""  
	#
	snapshot_type=""
	#
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} " value of variable 'snapshot_type': "$snapshot_type"   " 
    fnEcho ${LINENO} ""  
    #          
    ##########################################################################
    #
    #
    # display the header     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " display the header      "  
    fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
    fnDisplayHeader
    #
    # display the task progress bar
    #
    fnDisplayProgressBarTask "$counter_aws_region_list" "$count_aws_region_list"
    #                          
    ##########################################################################
    #
    #
    # pull the recursive-single command list
    # calling function: 'fnDbQueryCommandRecursiveSingleList'    
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " pull the recursive-single command list   "
    fnEcho ${LINENO} " calling function: 'fnDbQueryCommandRecursiveSingleList'  "   
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "querying the database for: aws cli recursive-single commands"
    fnEcho ${LINENO} ""
    #
    fnDbQueryCommandRecursiveSingleList
    #
    #
	###################################################
	#
	#
	# build the AWS command list of recursive-single commands 
	# calling function 'fnCommandRecursiveSingleListBuild'
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " build the AWS command list of recursive-single commands     "
	fnEcho ${LINENO} " calling function 'fnCommandRecursiveSingleListBuild'     "
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#                          
	fnCommandRecursiveSingleListBuild
    #                          
    ##########################################################################
    #
    #
    # pull the recursive single dependent command list
    # calling function: 'fnDbQueryCommandRecursiveSingleDependentList'    
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " pull the recursive single dependent command list   "
    fnEcho ${LINENO} " calling function: 'fnDbQueryCommandRecursiveSingleDependentList'  "   
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "querying the database for: aws cli recursive-single-dependent commands"
    fnEcho ${LINENO} ""
    #
    fnDbQueryCommandRecursiveSingleDependentList
    #
	###################################################
	#
	#
	# build the AWS command list of recursive-single-dependent commands 
	# calling function 'fnCommandRecursiveSingleDependentListBuild'
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " build the AWS command list of recursive-single-dependent commands      "
	fnEcho ${LINENO} " calling function 'fnCommandRecursiveSingleDependentListBuild'     "
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#                          
	fnCommandRecursiveSingleDependentListBuild
    #
    ##########################################################################
    #
    #
    # multi support is not built yet
    # #
    # fnEcho ${LINENO} ""
    # fnEcho ${LINENO} "querying the database for: aws cli recursive-multi commands"
    # fnEcho ${LINENO} ""
    # #
    # fnDbQueryCommandRecursiveMultiList
    #
    #
    fnEcho ${LINENO} ""
    #
	#
	###################################################
	#
	#
	# initialze the files  
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " initialze the files   "
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
	file_snapshot_driver_file_initialze_list="$file_snapshot_driver_global_services_file_name"
	file_snapshot_driver_file_initialze_list+=$'\n'"$file_snapshot_driver_aws_cli_commands_all_file_name"
	file_snapshot_driver_file_initialze_list+=$'\n'"$file_snapshot_driver_aws_cli_commands_all_file_name_raw"
	file_snapshot_driver_file_initialze_list+=$'\n'"$file_snapshot_driver_aws_cli_commands_all_file_name_raw"	
	file_snapshot_driver_file_initialze_list+=$'\n'"$file_snapshot_driver_aws_cli_commands_global_file_name"
	file_snapshot_driver_file_initialze_list+=$'\n'"$file_snapshot_driver_aws_cli_commands_global_file_name_raw"
	file_snapshot_driver_file_initialze_list+=$'\n'"$file_snapshot_driver_aws_cli_commands_non_global_file_name"
	file_snapshot_driver_file_initialze_list+=$'\n'"$file_snapshot_driver_aws_cli_commands_non_global_file_name_raw"
	#
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} "value of variable 'file_snapshot_driver_file_initialze_list': "$file_snapshot_driver_file_initialze_list"  "
	fnEcho ${LINENO} ""
	#
	while read file_snapshot_driver_file_initialze_list_line 
	do 
        #
	    ##########################################################################
	    #
	    #
	    # value of variable 'file_snapshot_driver_file_initialze_list_line' "$file_snapshot_driver_file_initialze_list_line"    
	    #
	    fnEcho ${LINENO} ""  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} " value of variable 'file_snapshot_driver_file_initialze_list_line' "$file_snapshot_driver_file_initialze_list_line"       "  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} ""             
	    #
		fnEcho ${LINENO} ""  
		fnEcho ${LINENO} " initializing file:   "
		fnEcho ${LINENO} " "$file_snapshot_driver_file_initialze_list_line"   "	
		fnEcho ${LINENO} ""  
	    feed_write_log="$(echo "" > "$this_path_temp"/"$file_snapshot_driver_file_initialze_list_line" 2>&1)"
	    #
	    # check for command / pipeline error(s)
	    if [ "$?" -ne 0 ]
	        then
	            #
	            # set the command/pipeline error line number
	            error_line_pipeline="$((${LINENO}-7))"
	            #
	            #
	            fnEcho ${LINENO} level_0 ""
	            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
	            fnEcho ${LINENO} level_0 "$feed_write_log"
	            fnEcho ${LINENO} level_0 ""
	            #
	            fnEcho ${LINENO} level_0 ""
	            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_file_initialze_list_line" "
	            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_file_initialze_list_line" 2>&1)"
	            fnEcho ${LINENO} level_0 "$feed_write_log"
	            fnEcho ${LINENO} level_0 ""
	            #                                                    
	            # call the command / pipeline error function
	            fnErrorPipeline
	            #
	    #
	    fi # end check for command / pipeline error(s)
	    #
	done< <(echo "$file_snapshot_driver_file_initialze_list")
	#
	###################################################
	#
	#
	# build the all-types commands file  
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " build the all-types commands file   "
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variables: "
    fnEcho ${LINENO} "value of variable file_snapshot_driver_aws_cli_commands_all_file_name_raw'': "$file_snapshot_driver_aws_cli_commands_all_file_name_raw" "
    fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_non_recursive_file_name': "$file_snapshot_driver_aws_cli_commands_non_recursive_file_name" "
    fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_recursive_single_file_name': "$file_snapshot_driver_aws_cli_commands_recursive_single_file_name" "
    fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name': "$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name" "
	#
	###################################################
	#
	#
	# placeholder for add other command types
	#
	#
	###################################################
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " initialize the all-commands file   "
	fnEcho ${LINENO} " file: "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" "	
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
    feed_write_log="$(echo "" > "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of target file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    fnEcho ${LINENO} ""
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " add non-recursive AWS CLI commands   "
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} ""  
    #
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " contents of the non-recursive commands file     "
	fnEcho ${LINENO} " contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name" :"
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
	fnEcho ${LINENO} ""  
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
	fnEcho ${LINENO} ""$feed_write_log" "  
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} " add non-recursive AWS CLI commands   "
	fnEcho ${LINENO} ""  
	#
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name" >> "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of source file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name""
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of target file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    #
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " post non-recursive load contents of the all-types commands file raw     "
	fnEcho ${LINENO} " contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" :"
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
	fnEcho ${LINENO} ""  
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
	fnEcho ${LINENO} ""$feed_write_log" "  
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " add recursive-single AWS CLI commands   "
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} ""  
    #
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " contents of the recursive-single commands file     "
	fnEcho ${LINENO} " contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name" :"
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
	fnEcho ${LINENO} ""  
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
	fnEcho ${LINENO} ""$feed_write_log" "  
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} " add recursive-single AWS CLI commands   "
	fnEcho ${LINENO} ""  
	#
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name" >> "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of source file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name" "
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of target file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " post add recursive-single contents of the all-types commands file raw     "
	fnEcho ${LINENO} " contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" :"
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
	fnEcho ${LINENO} ""  
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
	fnEcho ${LINENO} ""$feed_write_log" "  
	#   
    #
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " add recursive-single-dependent AWS CLI commands   "
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} ""  
    #
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " contents of the recursive-single-dependent commands file     "
	fnEcho ${LINENO} " contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name" :"
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
	fnEcho ${LINENO} ""  
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
	fnEcho ${LINENO} ""$feed_write_log" "  
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} " add recursive-single-dependent AWS CLI commands   "
	fnEcho ${LINENO} ""  
	#
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name" >> "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of source file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name" "
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of target file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " post add recursive-single-dependent contents of the all-types commands file raw     "
	fnEcho ${LINENO} " contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" :"
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
	fnEcho ${LINENO} ""  
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
	fnEcho ${LINENO} ""$feed_write_log" "  
	#   
	#
	###################################################
	#
	#
	# placeholder for add other command types
	#
	#
	###################################################
	#
	#
	###################################################
	#
	#
	# contents of the all-types commands file raw
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " post add all-command-types contents of the all-types commands file raw     "
	fnEcho ${LINENO} " contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" :"
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
	fnEcho ${LINENO} ""  
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
	fnEcho ${LINENO} ""$feed_write_log" "  
	#

	#
	##########################################################################
	#
	#
	# build the global services list
	# calling function: 'fnDbQueryServiceGlobalList'    
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " build the global services list   "
	fnEcho ${LINENO} " calling function: 'fnDbQueryServiceGlobalList'  "   
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} "querying the database for: aws global services"
	fnEcho ${LINENO} ""
	#
	fnDbQueryServiceGlobalList
	#
	#
	##########################################################################
	#
	#
	# test for global driver file 
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " test for global driver file  "
	fnEcho ${LINENO} " file: "$this_path_temp"/"$file_snapshot_driver_global_services_file_name"  "
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#                          
	if [ ! -f "$this_path_temp"/"$file_snapshot_driver_global_services_file_name" ]; 
	    then
	        #
	        ##########################################################################
	        #
	        #
	        # display the header     
	        #
	        fnEcho ${LINENO} ""  
	        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	        fnEcho ${LINENO} " display the header      "  
	        fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
	        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	        fnEcho ${LINENO} ""  
	        #          
	        fnDisplayHeader
	        #
	        fnEcho ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
	        fnEcho ${LINENO} level_0 ""
	        fnEcho ${LINENO} level_0 " Error reading the file: "$this_path_temp"/"$file_snapshot_driver_global_services_file_name" "
	        fnEcho ${LINENO} level_0 ""
	        fnEcho ${LINENO} level_0 " Please confirm that the file exists in this directory "
	        fnEcho ${LINENO} level_0 ""
	        fnEcho ${LINENO} level_0 ""        
	        fnEcho ${LINENO} level_0 " Exiting the script"
	        fnEcho ${LINENO} level_0 ""
	        fnEcho ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
	        fnEcho ${LINENO} level_0 ""
	        exit 1
	fi # end test for global driver file 
	#
	###################################################
	#
	#
	# write commands to non-global and global commands files 
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " write commands to non-global and global commands files   "
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#     
    #   
    ##########################################################################
    #
    #
    # load the global commmands variables
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " load the global commmands variables   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    # load all of the AWS commands 
    #
    file_snapshot_driver_file_name_aws_cli_commands_all="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'file_snapshot_driver_file_name_aws_cli_commands_all':"
            fnEcho ${LINENO} level_0 "$file_snapshot_driver_file_name_aws_cli_commands_all"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'file_snapshot_driver_file_name_aws_cli_commands_all': "
    feed_write_log="$(echo "$file_snapshot_driver_file_name_aws_cli_commands_all" 2>&1)"
    fnEcho ${LINENO} "feed_write_log"
    # 
    # load the AWS global services  
    #
    file_snapshot_driver_file_name_global_services="$(cat "$this_path_temp"/"$file_snapshot_driver_global_services_file_name" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'file_snapshot_driver_file_name_global_services':"
            fnEcho ${LINENO} level_0 "$file_snapshot_driver_file_name_global_services"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_global_services_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_global_services_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'file_snapshot_driver_file_name_global_services':"
    feed_write_log="$(echo "$file_snapshot_driver_file_name_global_services" 2>&1)"
    fnEcho ${LINENO} "feed_write_log"
    #   
    ##########################################################################
    #
    #
    # begin loop read: "$this_path_temp"/"$this_utility_acronym"-driver-aws-cli-commands-all.txt
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin loop read: "$this_path_temp"/"$this_utility_acronym"-driver-aws-cli-commands-all.txt   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    while read -r  aws_command_line
    do 
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "-------------------------------------------------------------------------------------------------------------  "          
        fnEcho ${LINENO} "------------------------------- loop head: read driver-aws-cli-commands-all.txt -----------------------------  "
        fnEcho ${LINENO} "-------------------------------------------------------------------------------------------------------------  "          
        fnEcho ${LINENO} ""   
        #
	    ##########################################################################
	    #
	    #
	    # value of variable 'aws_command_line': "$aws_command_line"     
	    #
	    fnEcho ${LINENO} ""  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} " value of variable 'aws_command_line': "$aws_command_line"        "  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} ""             
        #   
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "parse aws service from command "
        fnEcho ${LINENO} ""
		aws_command_line_service="$(echo "$aws_command_line" | cut -d ' ' -f1  2>&1)"        
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of variable 'aws_command_line_service': "$aws_command_line_service" "
        fnEcho ${LINENO} ""
        #   
        while read -r file_snapshot_driver_file_name_global_line
        do 
	        #
	        fnEcho ${LINENO} ""
	        fnEcho ${LINENO} "-------------------------------------------------------------------------------------------------------------  "          
	        fnEcho ${LINENO} "------------------------------------- loop head: read file_snapshot_driver_file_name_global ------------------------------------  "
	        fnEcho ${LINENO} "-------------------------------------------------------------------------------------------------------------  "          
	        fnEcho ${LINENO} ""   
	        #
		    ##########################################################################
		    #
		    #
		    # value of variable 'file_snapshot_driver_file_name_global_line': "$file_snapshot_driver_file_name_global_line"    
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} " value of variable 'file_snapshot_driver_file_name_global_line': "$file_snapshot_driver_file_name_global_line"       "  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} ""             
		    #
		    ##########################################################################
		    #
		    #
		    # test for non-global or global service; write AWS command to appropriate file
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} " test for non-global or global service; write AWS command to appropriate file  "
		    fnEcho ${LINENO} " "$aws_command_line_service" and "$file_snapshot_driver_file_name_global_line" "
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} ""  
		    #   
		    # check for global service match 
		    if [[ "$aws_command_line_service" = "$file_snapshot_driver_file_name_global_line" ]]
		    	then 
				    fnEcho ${LINENO} ""  
				    fnEcho ${LINENO} " AWS command service: "$aws_command_line_service"   "							    
				    fnEcho ${LINENO} " this is a global service; writing AWS command to file:   "
				    fnEcho ${LINENO} " "$this_path_temp"/"$this_utility_acronym"-driver-aws-cli-commands-global.txt   "
				    feed_write_log="$(echo "$aws_command_line" >> "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_global_file_name_raw" 2>&1)"
				    #
				    # check for command / pipeline error(s)
				    if [ "$?" -ne 0 ]
				        then
				            #
				            # set the command/pipeline error line number
				            error_line_pipeline="$((${LINENO}-7))"
				            #
				            #
				            fnEcho ${LINENO} level_0 ""
				            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
				            fnEcho ${LINENO} level_0 "$feed_write_log"
				            fnEcho ${LINENO} level_0 ""
				            #
				            fnEcho ${LINENO} level_0 ""
				            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_global_file_name_raw":"
				            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_global_file_name_raw" 2>&1)"
				            fnEcho ${LINENO} level_0 "$feed_write_log"
				            fnEcho ${LINENO} level_0 ""
				            #                                                    
				            # call the command / pipeline error function
				            fnErrorPipeline
				            #
				    #
				    fi # end check for command / pipeline error(s)
				    #
				else 			    
				    fnEcho ${LINENO} ""  
				    fnEcho ${LINENO} " AWS command service: "$aws_command_line_service"   "							    
				    fnEcho ${LINENO} " this is a non-global service; writing AWS command to file:   "
				    fnEcho ${LINENO} " "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_global_file_name_raw"   "
				    feed_write_log="$(echo "$aws_command_line" >> "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_global_file_name_raw" 2>&1)"
				    #
				    # check for command / pipeline error(s)
				    if [ "$?" -ne 0 ]
				        then
				            #
				            # set the command/pipeline error line number
				            error_line_pipeline="$((${LINENO}-7))"
				            #
				            #
				            fnEcho ${LINENO} level_0 ""
				            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
				            fnEcho ${LINENO} level_0 "$feed_write_log"
				            fnEcho ${LINENO} level_0 ""
				            #
				            fnEcho ${LINENO} level_0 ""
				            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_global_file_name_raw":"
				            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_global_file_name_raw" 2>&1)"
				            fnEcho ${LINENO} level_0 "$feed_write_log"
				            fnEcho ${LINENO} level_0 ""
				            #                                                    
				            # call the command / pipeline error function
				            fnErrorPipeline
				            #
				    #
				    fi # end check for command / pipeline error(s)
				    #
			fi # end check for global service match 
			#
		done< <(echo "$file_snapshot_driver_file_name_global_services")
		#
	done< <(echo "$file_snapshot_driver_file_name_aws_cli_commands_all")
	#
    #   
    ##########################################################################
    #
    #
    # dedupe the non-global command files 
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " dedupe the non-global command files "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    # dedupe the non-global commands 
    # need the non-recursive commands to lead the list so cannot sort  
    # dedupe method from here: https://stackoverflow.com/questions/11532157/unix-removing-duplicate-lines-without-sorting 
    # remove empty lines 
    feed_write_log="$(cat -n "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_global_file_name_raw" | sort -uk2 | sort -nk1 | cut -f2- | grep -v '^$' > "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_global_file_name" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of source file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_global_file_name_raw" "
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of target file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_global_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name_raw" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "contents of file: "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_global_file_name" "
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_global_file_name" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_global_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_global_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #   
    # dedupe the global commands 
    # need the non-recursive commands to lead the list so cannot sort  
    # dedupe method from here: https://stackoverflow.com/questions/11532157/unix-removing-duplicate-lines-without-sorting 
    # remove empty lines 
    feed_write_log="$(cat -n "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_global_file_name_raw" | sort -uk2 | sort -nk1 | cut -f2- | grep -v '^$' > "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_global_file_name" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of source file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_global_file_name_raw" "
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_global_file_name_raw" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of target file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_global_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_global_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "contents of file: "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_global_file_name" "
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_global_file_name" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_global_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_global_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #   
    ##########################################################################
    #
    #
    # concatinate the 'all commands' file 
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " concatinate the 'all commands' file  "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_global_file_name" > "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of source file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_global_file_name" "
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_global_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of target file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "contents of file: "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name" "
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #   
   	#   
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_global_file_name" >> "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of source file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_global_file_name" "
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_global_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of target file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "contents of file: "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name" "
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""


    #
    ##########################################################################
    #
    #
    # end function 'fnCommandListBuild'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnCommandListBuild'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to count the AWS commands to process 
#
function fnCommandCount()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnVariableNamesCommandRecursiveLoad'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnCommandCount'     "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnCommandCount' "
    fnEcho ${LINENO} ""
    #    
    ##########################################################################
    #
    #
    # count the AWS commands; load variable 'count_file_snapshot_driver_file_name_aws_cli_commands_all' 
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " count the non-recursive cli commands; load variable 'count_aws_snapshot_commands_non_recursive'   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                
    count_file_snapshot_driver_file_name_aws_cli_commands_all="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name" | wc -l 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'count_file_snapshot_driver_file_name_aws_cli_commands_all': "$count_file_snapshot_driver_file_name_aws_cli_commands_all")"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_all_file_name")"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'count_file_snapshot_driver_file_name_aws_cli_commands_all': "$count_file_snapshot_driver_file_name_aws_cli_commands_all" "
    fnEcho ${LINENO} ""
    # 
    count_driver_services="$count_file_snapshot_driver_file_name_aws_cli_commands_all" 
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'count_driver_services': "$count_driver_services" "
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # end function 'fnCommandNonRecursiveListBuild'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnCommandCount'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to build the non-recursive command list for the recursive source run 
#
function fnCommandNonRecursiveListBuild()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnVariableNamesCommandRecursiveLoad'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnCommandNonRecursiveListBuild'     "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnCommandNonRecursiveListBuild' "
    fnEcho ${LINENO} ""
    #    
	#
	###################################################
	#
	#
	# build the non-recursive command list for the recursive source run  
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " build the non-recursive command list for the recursive source run   "
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
    #   
    # sort and dedupe the non-recursive commands for the recursive source run 
    # 
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name_raw" | sort -u > "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of source file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name_raw" "
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name_raw" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of target file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name" :"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "contents of file: "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name" "
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #   
    ##########################################################################
    #
    #
    # count the non-recursive AWS commands; load variable 'count_file_snapshot_driver_aws_cli_commands_non_recursive' 
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " count the non-recursive cli commands; load variable 'count_file_snapshot_driver_aws_cli_commands_non_recursive'   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                
    count_file_snapshot_driver_aws_cli_commands_non_recursive="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name" | wc -l 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'count_file_snapshot_driver_aws_cli_commands_non_recursive': "$count_file_snapshot_driver_aws_cli_commands_non_recursive")"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_non_recursive_file_name")"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'count_file_snapshot_driver_aws_cli_commands_non_recursive': "$count_file_snapshot_driver_aws_cli_commands_non_recursive" "
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # end function 'fnCommandNonRecursiveListBuild'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnCommandNonRecursiveListBuild'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to build the recursive-single command list for the recursive source run 
#
function fnCommandRecursiveSingleListBuild()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnVariableNamesCommandRecursiveLoad'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnCommandRecursiveSingleListBuild'     "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnCommandRecursiveSingleListBuild' "
    fnEcho ${LINENO} ""
    #    
	#
	###################################################
	#
	#
	# build the recursive-single command list  
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " build the recursive-single command list    "
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
    #   
    # sort and dedupe the recursive-single commands 
    # 
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw" | sort -u > "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of source file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw" "
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of target file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name" :"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "contents of file: "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name" "
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #   
    ##########################################################################
    #
    #
    # count the recursive-single AWS commands; load variable 'count_file_snapshot_driver_aws_cli_commands_recursive_single' 
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " count the recursive-single cli commands; load variable 'count_file_snapshot_driver_aws_cli_commands_recursive_single'   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                
    count_file_snapshot_driver_aws_cli_commands_recursive_single="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name" | wc -l 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'count_file_snapshot_driver_aws_cli_commands_recursive_single': "$count_file_snapshot_driver_aws_cli_commands_recursive_single" "
            fnEcho ${LINENO} level_0 ""
            #                                                    
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'count_file_snapshot_driver_aws_cli_commands_recursive_single': "$count_file_snapshot_driver_aws_cli_commands_recursive_single" "
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # end function 'fnCommandRecursiveSingleListBuild'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnCommandRecursiveSingleListBuild'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to build the recursive-single-dependent command list for the recursive source run 
#
function fnCommandRecursiveSingleDependentListBuild()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnCommandRecursiveSingleDependentListBuild'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnCommandRecursiveSingleDependentListBuild'     "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnCommandRecursiveSingleDependentListBuild' "
    fnEcho ${LINENO} ""
    #    
	#
	###################################################
	#
	#
	# build the recursive-single-dependent command list  
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " build the recursive-single-dependent command list    "
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
    #   
    # sort and dedupe the recursive-single-dependent commands 
    # 
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_raw" | sort -u > "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of source file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_raw" "
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_raw" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of target file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name" :"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "contents of file: "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name" "
    feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #   
    ##########################################################################
    #
    #
    # count the recursive-single AWS commands; load variable 'count_file_snapshot_driver_aws_cli_commands_recursive_single' 
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " count the recursive-single cli commands; load variable 'count_file_snapshot_driver_aws_cli_commands_recursive_single'   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                
    count_file_snapshot_driver_aws_cli_commands_recursive_single_dependent="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name" | wc -l 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'count_file_snapshot_driver_aws_cli_commands_recursive_single_dependent': "$count_file_snapshot_driver_aws_cli_commands_recursive_single_dependent" "
            fnEcho ${LINENO} level_0 ""
            #                                                    
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'count_file_snapshot_driver_aws_cli_commands_recursive_single_dependent': "$count_file_snapshot_driver_aws_cli_commands_recursive_single_dependent" "
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # end function 'fnCommandRecursiveSingleDependentListBuild'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnCommandRecursiveSingleDependentListBuild'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to create the write directories 
#
function fnWriteDirectoryCreate()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnVariableNamesCommandRecursiveLoad'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnWriteDirectoryCreate'     "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnWriteDirectoryCreate' "
    fnEcho ${LINENO} ""
    #    
    #
    ##########################################################################
    #
    #
    #  begin: create the write directory 
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " create the write directory    "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                          
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading the region dependent variables  "
    fnEcho ${LINENO} "value of variable 'aws_region_list_line': "$aws_region_list_line" "
    #
    if [[ ("$aws_region_list_line" = 'global') && ("$snapshot_type" != 'source-recursive') ]] 
        then 
            # check for global region with empty global services 
            # 'global' is appended to the region file for every run
            # if there are no global services in the driver file, then this section will skip processing the empty file  
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "variable 'aws_region_list_line' != global and variable 'snapshot_type' != 'source-recursive' "
            fnEcho ${LINENO} "loading the variable: 'count_global_services_names_file'  "   
            count_global_services_names_file="$(cat "$this_path_temp"/"$file_snapshot_driver_global_services_file_name" | grep -v '^$' | wc -l  2>&1)"
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
            #         fnEcho ${LINENO} level_0 ""
            #         fnEcho ${LINENO} level_0 "value of variable 'count_global_services_names_file':"
            #         fnEcho ${LINENO} level_0 "$count_global_services_names_file"
            #         fnEcho ${LINENO} level_0 ""
            #         #
            #         fnEcho ${LINENO} level_0 ""
            #         fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$this_utility_acronym"-global-services-names.txt :"
            #         feed_write_log="$(cat "$this_path_temp"/"$this_utility_acronym"-global-services-names.txt)"
            #         fnEcho ${LINENO} level_0 "$feed_write_log"
            #         fnEcho ${LINENO} level_0 ""
            #         #                                                                                                            
            #         # call the command / pipeline error function
            #         fnErrorPipeline
            #         #
            #         #
            # fi
            #
            #
            fnEcho ${LINENO} "value of variable 'count_global_services_names_file': "$count_global_services_names_file" "
            fnEcho ${LINENO} ""
            #
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "checking for empty file: "$this_path_temp"/"$file_snapshot_driver_global_services_file_name"  "   
            if [[ "$count_global_services_names_file" = 0 ]] 
                then 
                    fnEcho ${LINENO} ""
                    fnEcho ${LINENO} "there are no global services to process  "
                    fnEcho ${LINENO} "skipping to next task via the 'break' command  "   
                    #
                    break 
                    #
            fi  # end check for no global services to process 
            #
    fi  # end check for global region and empty global region names file 
    #
    #
    ##########################################################################
    #
    #
    # check for 'all' regions
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " check for 'all' regions    "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                          
    if [[ "$aws_region" != 'all' ]]
        then
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "this is a non-all-regions run  "
            fnEcho ${LINENO} "testing for global region in variable 'aws_region_list_line'  "
            if [[ "$aws_region_list_line" != 'global' ]] 
                then 
                    # if the region is not 'global' then set the path to the region list line  
                    fnEcho ${LINENO} ""
                    fnEcho ${LINENO} "region is not global so setting region from variable 'aws_region_list_line': "$aws_region_list_line"  "
                    write_path="$this_path"/aws-"$aws_account"-"$aws_region_list_line"-"$this_utility_filename_plug"-"$date_file"
                    write_path_snapshots="$write_path"/"$this_utility_filename_plug"-files
                    this_file_account_region_services_all="$write_path_snapshots"/"aws-""$aws_account"-"$aws_region_list_line"-"$this_utility_filename_plug"-"$date_file"-all-services.json 
                else 
                    # if the region is 'global' then use the aws_region value for the path to keep the global services snapshots in the same folder as the rest of the results 
                    fnEcho ${LINENO} ""
                    fnEcho ${LINENO} "region is global so setting region from variable 'aws_region': "$aws_region"  "
                    write_path="$this_path"/aws-"$aws_account"-"$aws_region"-"$this_utility_filename_plug"-"$date_file"
                    write_path_snapshots="$write_path"/"$this_utility_filename_plug"-files
                    # use the aws_region_list_line value here so that the file name is correct: global
                    this_file_account_region_services_all_global="$write_path_snapshots"/"aws-""$aws_account"-"$aws_region_list_line"-"$this_utility_filename_plug"-"$date_file"-all-services.json 
            fi  # end check for global region in a non-all-regions run                    
            #
        else 
           fnEcho ${LINENO} ""
            fnEcho ${LINENO} "this is an all-regions run  "
            fnEcho ${LINENO} "testing for global region in variable 'aws_region_list_line'  "
            if [[ "$aws_region_list_line" != 'global' ]] 
                then 
                    # if an all-regions run then set the paths to 'all-regions' to group all of the results in one folder
                    fnEcho ${LINENO} ""
                    fnEcho ${LINENO} "all-regions run so setting path to 'all-regions'  "
                    write_path="$this_path"/aws-"$aws_account"-all-regions-"$this_utility_filename_plug"-"$date_file"
                    write_path_snapshots="$write_path"/"$this_utility_filename_plug"-files
                    # if the region is not 'global' then set the path for the all-services non-global file   
                    this_file_account_region_services_all="$write_path_snapshots"/"aws-""$aws_account"-"$aws_region_list_line"-"$this_utility_filename_plug"-"$date_file"-all-services.json 
                else 
                    # if an all-regions run then set the paths to 'all-regions' to group all of the results in one folder
                    fnEcho ${LINENO} ""
                    fnEcho ${LINENO} "all-regions run so setting path to 'all-regions'  "
                    write_path="$this_path"/aws-"$aws_account"-all-regions-"$this_utility_filename_plug"-"$date_file"
                    write_path_snapshots="$write_path"/"$this_utility_filename_plug"-files
                    # if the region is 'global' then set the path for the all-services global file   
                    this_file_account_region_services_all_global="$write_path_snapshots"/"aws-""$aws_account"-"$aws_region_list_line"-"$this_utility_filename_plug"-"$date_file"-all-services.json 
            fi  # end test for global region in an all-regions run 
    fi  # end test for all regions       
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'aws_region': "$aws_region" "    
    fnEcho ${LINENO} "value of variable 'aws_region_list_line': "$aws_region_list_line" "
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "values of the region dependent variables:  "   
    fnEcho ${LINENO} "value of variable 'write_path': "$write_path" "
    fnEcho ${LINENO} "value of variable 'write_path_snapshots': "$write_path_snapshots" "
    fnEcho ${LINENO} "value of variable 'this_file_account_region_services_all': "$this_file_account_region_services_all" "
    fnEcho ${LINENO} "value of variable 'this_file_account_region_services_all_global': "$this_file_account_region_services_all_global" "
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "creating the directory for the job files "
    fnEcho ${LINENO} "job files located in: "$write_path" "  
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # check for the write directory
    # if the write directory does not exist, then create it
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " check for the write directory  "
    fnEcho ${LINENO} " if the write directory does not exist, then create it "    
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                          
    if [[ ! -d "$write_path" ]] 
        then 
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "the directory does not exist: "$write_path" "  
    		fnEcho ${LINENO} "creating the directory for the snapshot output files "		    
		    fnEcho ${LINENO} ""  
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
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #                                                                                                
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            fi
            #
        else 
       	    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "the directory exists: "$write_path" "  
		    fnEcho ${LINENO} ""  
    fi
    #
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} "snapshot files located in: "$write_path" "  
    fnEcho ${LINENO} ""
    if [[ ! -d "$write_path_snapshots" ]] 
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
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
                    fnEcho ${LINENO} level_0 "$feed_write_log"
                    fnEcho ${LINENO} level_0 ""
                    #
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi  # end check for error        
            #
    fi # end check for existing path 
    #
    fnEcho ${LINENO} ""
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
    ##########################################################################
    #
    #
    # end function 'fnWriteDirectoryCreate'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnWriteDirectoryCreate'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to delete unneeded snapshots created for the recursive source run 
#
function fnFileSnapshotUnneededDelete()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnVariableNamesCommandRecursiveLoad'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnFileSnapshotUnneededDelete'     "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnFileSnapshotUnneededDelete' "
    fnEcho ${LINENO} ""
    #    
    #
    ##########################################################################
	#
	#
	# delete the unneeded snapshot files created during recursive source table process    
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " delete the unneeded snapshot files created during recursive source table process      "  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""           
	fnEcho ${LINENO} "loading varaible 'region_global_list_raw' with "$this_path_temp"/"$file_snapshot_driver_global_services_file_name" "
	region_global_list_raw="$(cat "$this_path_temp"/"$file_snapshot_driver_global_services_file_name" 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'region_global_list_raw':"
            fnEcho ${LINENO} level_0 "$region_global_list_raw"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$file_snapshot_driver_global_services_file_name":"
            feed_write_log="$(cat "$this_path_temp"/"$file_snapshot_driver_global_services_file_name" 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
	fi # end check for command / pipeline error(s)
	#
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} "value of variable 'region_global_list_raw': "
	fnEcho ${LINENO} "$region_global_list_raw"
	#
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} "value of variable 'aws_region_list': "
	fnEcho ${LINENO} "$aws_region_list"
	fnEcho ${LINENO} ""
	#
	fnEcho ${LINENO} "extracting AWS service and deduping global service list: "
	region_global_list="$(echo "$region_global_list_raw" | cut -d' ' -f1 | sort -u 2>&1)"
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} "value of variable 'region_global_list': "
	fnEcho ${LINENO} "$region_global_list"
	fnEcho ${LINENO} ""
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} "deleting global json files with region filename created by recursive source run"
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""           
	#
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} "loading variable 'delete_files_snapshot' with contents of directory: "$write_path_snapshots" "
	delete_files_snapshot="$(ls "$write_path_snapshots" 2>&1)"
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} "value of variable 'delete_files_snapshot': "
	fnEcho ${LINENO} "$delete_files_snapshot"
	fnEcho ${LINENO} ""
	#
	fnEcho ${LINENO} "begin loop read: 'aws_region_list' "
	#
	while read aws_region_line
		do
	        #
		    ##########################################################################
		    #
		    #
		    # value of variable 'aws_region_line': "$aws_region_line"    
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} " value of variable 'aws_region_line': "$aws_region_line"       "  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} ""             
			#
			# test for global region
			if [[ "$aws_region_line" != global ]]
				then 
					fnEcho ${LINENO} ""
					fnEcho ${LINENO} "value of variable 'aws_region_line': "
					fnEcho ${LINENO} "$aws_region_line"
					fnEcho ${LINENO} ""			
					delete_files_region_name="$(echo "$delete_files_snapshot" | grep "$aws_region_line" 2>&1)"
					# test for empty result
					if [[ "$delete_files_region_name" != '' ]]
						then 
							fnEcho ${LINENO} ""
							fnEcho ${LINENO} "value of variable 'delete_files_region_name': "
							fnEcho ${LINENO} "$delete_files_region_name"
							fnEcho ${LINENO} ""
							fnEcho ${LINENO} "begin loop read: 'region_global_list' "
							while read region_global_list_line_service region_global_list_line_command region_global_list_line_parameter region_global_list_line_parameter_value 
								do 
							        #
								    ##########################################################################
								    #
								    #
								    # value of variable 'aws_region_line': "$aws_region_line"    
								    #
								    fnEcho ${LINENO} ""  
								    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
								    fnEcho ${LINENO} " value of variables  'region_global_list_line_service' 'region_global_list_line_command' 'region_global_list_line_parameter' 'region_global_list_line_parameter_value':       "  
								    fnEcho ${LINENO} " value of variables: "$region_global_list_line_service" "$region_global_list_line_command" "$region_global_list_line_parameter" "$region_global_list_line_parameter_value"       "  							    
								    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
								    fnEcho ${LINENO} ""             
									#
									# test for empty 'region_global_list_line_service'								
									if [[ "$region_global_list_line_service" != '' ]] 
										then 
											fnEcho ${LINENO} ""
											fnEcho ${LINENO} "value of variable 'region_global_list_line_service': "
											fnEcho ${LINENO} "$region_global_list_line_service"
											fnEcho ${LINENO} ""
											delete_files_acronym_name="$(echo "$delete_files_region_name" | grep "$region_global_list_line_service" 2>&1)"
											fnEcho ${LINENO} ""
											fnEcho ${LINENO} "value of variable 'delete_files_acronym_name': "
											fnEcho ${LINENO} "$delete_files_acronym_name"
											fnEcho ${LINENO} ""
											fnEcho ${LINENO} ""
											# test for file exists
											if [[ -f "$write_path_snapshots"/"$delete_files_acronym_name" ]]
												then 
													fnEcho ${LINENO} "pre-delete status of file 'delete_files_acronym_name': "
										            fnEcho ${LINENO} ""  
										            feed_write_log="$(ls -l "$write_path_snapshots"/"$delete_files_acronym_name"  2>&1)"
										            #
										            #  check for command / pipeline error(s)
										            if [ "$?" -ne 0 ]
										                then
										                    #
										                    # set the command/pipeline error line number
										                    error_line_pipeline="$((${LINENO}-7))"
										                    #
										                    #
										                    fnEcho ${LINENO} level_0 ""
										                    fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
										                    fnEcho ${LINENO} level_0 "$feed_write_log"
										                    fnEcho ${LINENO} level_0 ""
										                    #
										                    # call the command / pipeline error function
										                    fnErrorPipeline
										                    #
										                    #
										            fi  # end pipeline error check 
										            #
										            fnEcho ${LINENO} "$feed_write_log"
										            #							
													fnEcho ${LINENO} ""
													fnEcho ${LINENO} "deleting file 'delete_files_acronym_name': "
										            feed_write_log="$(rm -f "$write_path_snapshots"/"$delete_files_acronym_name"  2>&1)"
										            #
										            #  check for command / pipeline error(s)
										            if [ "$?" -ne 0 ]
										                then
										                    #
										                    # set the command/pipeline error line number
										                    error_line_pipeline="$((${LINENO}-7))"
										                    #
										                    #
										                    fnEcho ${LINENO} level_0 ""
										                    fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
										                    fnEcho ${LINENO} level_0 "$feed_write_log"
										                    fnEcho ${LINENO} level_0 ""
										                    #
										                    # call the command / pipeline error function
										                    fnErrorPipeline
										                    #
										                    #
										            fi  # end pipeline error check 
										            #
										            fnEcho ${LINENO} "$feed_write_log"
										            #
													fnEcho ${LINENO} ""
													fnEcho ${LINENO} "post-delete status of file 'delete_files_acronym_name': "
										            feed_write_log="$(ls -l "$write_path_snapshots"/"$delete_files_acronym_name"  2>&1)"
										            #
										            #  check for command / pipeline error(s)
										            if [ "$?" -ne 0 ]
										                then
										                    #
										                    # set the command/pipeline error line number
										                    error_line_pipeline="$((${LINENO}-7))"
										                    #
										                    #
										                    fnEcho ${LINENO} ""
										                    fnEcho ${LINENO} "value of variable 'feed_write_log':"
										                    fnEcho ${LINENO} "$feed_write_log"
										                    fnEcho ${LINENO} ""
										                    #
										                    # call the command / pipeline error function
										                    # no call, this error is expected 
										                    # fnErrorPipeline
										                    #
										                    #
										            fi  # end pipeline error check 
										            #
										            fnEcho ${LINENO} "$feed_write_log"
										            #
										    fi # end check for file exists
										    #
											fnEcho ${LINENO} ""
											fnEcho ${LINENO} ""
									fi # end check for empty line
									#
							done< <(echo "$region_global_list")
							#
						else 
							#
							fnEcho ${LINENO} ""
							fnEcho ${LINENO} "variable: 'delete_files_region_name' is empty; no file found to delete "
							fnEcho ${LINENO} ""						
					fi # end check for empty results: delete_files_region_name
					#
			fi # end check for global region 
	#
	done< <(echo "$aws_region_list")
	#
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} "loading varaible 'delete_files_snapshot_post_delete' with contents of directory: "$write_path_snapshots" "
	delete_files_snapshot_post_delete="$(ls "$write_path_snapshots" 2>&1)"
    #
    #  check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'delete_files_snapshot_post_delete':"
            fnEcho ${LINENO} level_0 "$delete_files_snapshot_post_delete"
            fnEcho ${LINENO} level_0 ""
            #
            # call the command / pipeline error function
            fnErrorPipeline
            #
            #
    fi  # end pipeline error check 
    #
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} "value of variable 'delete_files_snapshot_post_delete': "
	fnEcho ${LINENO} "$delete_files_snapshot_post_delete"
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # end function 'fnFileSnapshotUnneededDelete'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnFileSnapshotUnneededDelete'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to create the stripped command file and set the count 
# call with parameters: 'source_file_name' 'stripped_file_name'
# example:  "$file_snapshot_driver_aws_cli_commands_all_file_name" "$file_snapshot_driver_aws_cli_commands_all_file_name_stripped"
#
function fnVariableLoadCommandFileSource()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnVariableNamesCommandRecursiveLoad'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnVariableLoadCommandFileSource'     "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnVariableLoadCommandFileSource' "
    fnEcho ${LINENO} ""
	#
	###################################################
	#
	#
	# set the aws cli commands driver file variable 
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " set the aws cli commands driver file variable     "
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} "value of source file parameter '1' :"
	fnEcho ${LINENO} "$1"
	fnEcho ${LINENO} ""
	#                          
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} "setting variable 'file_snapshot_driver_file_name'"
	fnEcho ${LINENO} ""
	#
	file_snapshot_driver_file_name="$1"
	#
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} "value of variable 'file_snapshot_driver_file_name':"
	fnEcho ${LINENO} "$file_snapshot_driver_file_name"
	fnEcho ${LINENO} ""
	#
	###################################################
	#
	#
	# set the variable: 'file_snapshot_driver_stripped_file_name' for the strip create function 
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " set the variable: 'file_snapshot_driver_stripped_file_name'     "
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} "value of source file parameter '2' :"
	fnEcho ${LINENO} "$2"
	fnEcho ${LINENO} ""
	#                          
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} "setting variable 'file_snapshot_driver_stripped_file_name'"
	fnEcho ${LINENO} ""
	#                          
	file_snapshot_driver_stripped_file_name="$2" 
	#
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} "value of variable 'file_snapshot_driver_stripped_file_name':"
	fnEcho ${LINENO} "$file_snapshot_driver_stripped_file_name"
	fnEcho ${LINENO} ""
	#
	##########################################################################
	#
	#
	# create the stripped driver file
	# prior to call, set the variables 'file_snapshot_driver_file_name' and 'file_snapshot_driver_stripped_file_name' 
	# calling function: 'fnStrippedDriverFileCreate'    
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " create the stripped driver file   "
	fnEcho ${LINENO} " calling function: 'fnStrippedDriverFileCreate'  "   
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} "value of variable 'file_snapshot_driver_file_name': "$file_snapshot_driver_file_name" "
	fnEcho ${LINENO} ""
	#
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} "value of variable 'file_snapshot_driver_stripped_file_name': "$file_snapshot_driver_stripped_file_name" "
	fnEcho ${LINENO} ""
	#
	fnStrippedDriverFileCreate
    #
    ##########################################################################
    #
    #
    # end function 'fnVariableLoadCommandFileSource'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnVariableLoadCommandFileSource'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to create the source tables for the recursive commands 
#
function fnDbQueryCommandRecursiveSourceTables()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnVariableNamesCommandRecursiveLoad'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnDbQueryCommandRecursiveSourceTablese'     "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnDbQueryCommandRecursiveSourceTables' "
    fnEcho ${LINENO} ""
	#
	##########################################################################
	#
	# create the non-recursive tables for sources for the recursive commands
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} "create the non-recursive tables for sources for the recursive commands   "               
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#                  
	#
	#
	##########################################################################
	#
	#
	# set the source and stripped file names 
	# calling function: 'fnVariableLoadCommandFileSource'    
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " set the source and stripped file names    "
	fnEcho ${LINENO} " calling function: 'fnVariableLoadCommandFileSource'   "   
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
	fnVariableLoadCommandFileSource "$file_snapshot_driver_aws_cli_commands_non_recursive_file_name" "$file_snapshot_driver_aws_cli_commands_non_recursive_file_name_stripped"
	#
	##########################################################################
	#
	#
	# set variable 'counter_driver_services' to 0
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " set variable 'counter_driver_services' to 0  "
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	# 
	fnEcho ${LINENO} "reset the task counter variable 'counter_driver_services' to 0 "
	counter_driver_services=0
	#
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} "value of variable 'count_driver_services': "$counter_driver_services" " 
	fnEcho ${LINENO} ""
	#
	##########################################################################
	#
	#
	# create the write directory
	# calling function: 'fnWriteDirectoryCreate' 
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " create the write directory   "
	fnEcho ${LINENO} " setting variables and calling function: 'fnWriteDirectoryCreate'   "
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
	# set the variables for the recursive source run
	aws_region_list_line='us-east-1'
	aws_region_backup="$aws_region"
	aws_region='us-east-1'
	aws_region_list_line_parameter='us-east-1'
	#
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} "value of variable 'aws_region_list_line': "$aws_region_list_line" "
	fnEcho ${LINENO} "value of variable 'aws_region': "$aws_region" "
	fnEcho ${LINENO} ""
	#
	fnWriteDirectoryCreate
	#
	#
	##########################################################################
	#
	#
	# display message 'pulling recursive source tables'
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " display message 'pulling recursive source tables'  "
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
	fnEcho ${LINENO} level_0 ""
	fnEcho ${LINENO} level_0 "pulling recursive source tables " 
	fnEcho ${LINENO} level_0 ""
	#
	##########################################################################
	#
	##########################################################################
	#
	# 
	# pulling the non-recursive snapshots to create the recursive source tables  
	# calling function: fnAwsPullSnapshotsNonRecursive for region: "$aws_region_list_line" "
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------" 
	fnEcho ${LINENO} " pulling the non-recursive snapshots to create the recursive source tables     "    
	fnEcho ${LINENO} " calling function: fnAwsPullSnapshotsNonRecursive for region: "$aws_region_list_line"   "
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
	fnAwsPullSnapshotsNonRecursive
    #
    ##########################################################################
    #
    #
    # Loading the non-recursive command JSON snapshot file to the database
    # calling function 'fnDbLoadSnapshotFile'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " Loading the non-recursive command JSON snapshot file to the database     "       
    fnEcho ${LINENO} " calling function 'fnDbLoadSnapshotFile'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    fnDbLoadSnapshotFile
	#
	##########################################################################
	#
	#
	# restore the variables after the recursive source run
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " restore the variables after the recursive source run   "
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#
	aws_region_list_line=''
	aws_region="$aws_region_backup"
	#
	fnEcho ${LINENO} ""
	fnEcho ${LINENO} "value of variable 'aws_region_list_line': "$aws_region_list_line" "
	fnEcho ${LINENO} "value of variable 'aws_region': "$aws_region" "
	fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # end function 'fnDbQueryCommandRecursiveSourceTables'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnDbQueryCommandRecursiveSourceTables'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to test for table create success
#
function fnDbQueryTestTableExists()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnVariableNamesCommandRecursiveLoad'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnDbQueryTestTableExists'     "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnDbQueryTestTableExists' "
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # test for table create success 
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " test for table create success "
    fnEcho ${LINENO} " table: "$db_schema"."$1" " 
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "running the following query to test if the table was successfully created:  "
    fnEcho ${LINENO} "table: "$db_schema"."$1": "
    fnEcho ${LINENO} "SQL:  "       
    fnEcho ${LINENO} "  SELECT EXISTS ( "
    fnEcho ${LINENO} "	SELECT 1 "
    fnEcho ${LINENO} "	FROM   pg_tables "
    fnEcho ${LINENO} "	WHERE  schemaname = \'"$db_schema"\'' "
    fnEcho ${LINENO} "	AND    tablename = \'"$1"\'' "
    fnEcho ${LINENO} "	) "
    fnEcho ${LINENO} "  ; "
    fnEcho ${LINENO} "  COMMIT; "    
    fnEcho ${LINENO} ""
    #
    query_test_table_exists_sql='SELECT EXISTS (SELECT 1 FROM pg_tables WHERE schemaname = '\'"$db_schema"\'' AND tablename = '\'"$1"\'');'
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable: 'query_test_table_exists_sql': "
    feed_write_log="$(echo "$query_test_table_exists_sql" )"
    fnEcho ${LINENO} "$feed_write_log" 
    fnEcho ${LINENO} ""
    #        
    # build the query variable
    query_test_table_exists="$(psql \
    --host="$db_host" \
    --dbname="$db_name" \
    --username="$db_user" \
    --port="$db_port" \
    --set ON_ERROR_STOP=on \
    --echo-all \
    --echo-errors \
    --tuples-only \
    --no-align \
    --field-separator ' ' \
    --variable db_schema_psql=\'"$db_schema"\' \
    --variable tablename_psql=\'"$1"\' \
    --command="$query_test_table_exists_sql" \
    --output=""$this_path_temp"/query_test_table_exists.txt" 
    2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -eq 3 ]
        then
            #
            # set the command/pipeline error line number
            error_line_psql="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'query_test_table_exists':"
            fnEcho ${LINENO} level_0 "$query_test_table_exists"
            fnEcho ${LINENO} level_0 ""
            # call the psql error function
            fnErrorPsql
            #
    #
    fi
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "contents of file 'query_test_table_exists.txt':  "
    feed_write_log="$(cat  "$this_path_temp"/query_test_table_exists.txt 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/query_test_table_exists.txt:"
            feed_write_log="$(cat "$this_path_temp"/query_test_table_exists.txt 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #   
	query_test_table_exists_results="$(cat "$this_path_temp"/query_test_table_exists.txt | grep -v ^$)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/query_test_table_exists.txt:"
            feed_write_log="$(cat "$this_path_temp"/query_test_table_exists.txt 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'query_test_table_exists_results':""$query_test_table_exists_results"
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # end function 'fnDbQueryTestTableExists'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnDbQueryTestTableExists'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to test for table populate success
#
function fnDbQueryTestTablePopulate()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnVariableNamesCommandRecursiveLoad'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnDbQueryTestTablePopulate'     "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnDbQueryTestTablePopulate' "
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # test for table populate success
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " test for table populate success "
    fnEcho ${LINENO} " table: "$db_schema"."$1" " 
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "running the following query to test if the table was successfully populated: "
    fnEcho ${LINENO} "table: "$db_schema"."$1": "
    fnEcho ${LINENO} "SQL:  "    
    fnEcho ${LINENO} "  SELECT COUNT(*) "
    fnEcho ${LINENO} "	FROM "$db_schema"."$1" "
    fnEcho ${LINENO} "  ; "  
    fnEcho ${LINENO} ""
    #        
    # build the query variable
    query_test_table_populate="$(psql \
    --host="$db_host" \
    --dbname="$db_name" \
    --username="$db_user" \
    --port="$db_port" \
    --set ON_ERROR_STOP=on \
    --echo-all \
    --echo-errors \
    --tuples-only \
    --no-align \
    --field-separator ' ' \
    --command="SELECT COUNT(*) FROM $db_schema.$1;" 
    2>&1)" 
    # check for command / pipeline error(s)
    if [ "$?" -eq 3 ]
        then
            #
            # set the command/pipeline error line number
            error_line_psql="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'query_test_table_populate':"
            fnEcho ${LINENO} level_0 "$query_test_table_populate"
            fnEcho ${LINENO} level_0 ""
            # call the psql error function
            fnErrorPsql
            #
    #
    fi
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'query_test_table_populate': "
    feed_write_log="$(echo "$query_test_table_populate"  2>&1)"
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #   
    # test for query create fail
    count_query_test_table_populate="$(echo "$query_test_table_populate" | sed 's/://' 2>&1)"
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'count_query_test_table_populate':"
    fnEcho ${LINENO} "$count_query_test_table_populate"
    fnEcho ${LINENO} ""
    #
    if [[ "$count_query_test_table_populate" -eq 0 ]]
    	then 
		    #
		    fnEcho ${LINENO} ""  
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} " >> table populate fail << "
		    fnEcho ${LINENO} " table: "$db_schema"."$1" " 
		    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		    fnEcho ${LINENO} ""  
		    #          
            # call the psql error function
            fnErrorPsql
            #
	fi # end check for table create error 
    #
    ##########################################################################
    #
    #
    # end function 'fnDbQueryTestTablePopulate'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnDbQueryTestTablePopulate'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to query the PostgreSQL reserved words
#
function fnDbQueryReservedWords()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnDbQueryReservedWords'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnDbQueryReservedWords'     "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnDbQueryReservedWords' "
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # querying the PostgreSQL reserved words
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " querying the PostgreSQL reserved words "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "running the following query to query the PostgreSQL reserved words:  "
    fnEcho ${LINENO} "SQL:  "       
    fnEcho ${LINENO} "  SELECT aws_sps__commands._postgresql_reserved_words.reserved_words  "
    fnEcho ${LINENO} "	FROM aws_sps__commands._postgresql_reserved_words "
    fnEcho ${LINENO} "  WHERE _postgresql_reserved_words.reserved_words = '\'"$aws_snapshot_name_underscore"\' "
    fnEcho ${LINENO} "  ; "
    fnEcho ${LINENO} "  COMMIT; "    
    fnEcho ${LINENO} ""
	#
    query_postgresql_reserved_words_test_sql='SELECT aws_sps__commands._postgresql_reserved_words.reserved_words FROM aws_sps__commands._postgresql_reserved_words WHERE _postgresql_reserved_words.reserved_words = '\'"$aws_snapshot_name_underscore"\'';'
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable: 'query_postgresql_reserved_words_test_sql': "
    feed_write_log="$(echo "$query_postgresql_reserved_words_test_sql" )"
    fnEcho ${LINENO} "$feed_write_log" 
    fnEcho ${LINENO} ""
    #
    # build the query variable
    query_postgresql_reserved_words_test="$(psql \
    --host="$db_host" \
    --dbname="$db_name" \
    --username="$db_user" \
    --port="$db_port" \
    --set ON_ERROR_STOP=on \
    --echo-all \
    --echo-errors \
    --tuples-only \
    --no-align \
    --field-separator ' ' \
    --variable db_schema_psql=\'"$db_schema"\' \
    --variable tablename_psql=\'"$1"\' \
    --command="$query_postgresql_reserved_words_test_sql" \
    --output=""$this_path_temp"/query_postgresql_reserved_words_test.txt" 
    2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -eq 3 ]
        then
            #
            # set the command/pipeline error line number
            error_line_psql="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'query_postgresql_reserved_words_test':"
            fnEcho ${LINENO} level_0 "$query_postgresql_reserved_words_test"
            fnEcho ${LINENO} level_0 ""
            # call the psql error function
            fnErrorPsql
            #
    #
    fi # end check for command / pipeline errors 
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'query_postgresql_reserved_words_test':  "
    feed_write_log=" "$query_postgresql_reserved_words_test" "
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'query_postgresql_reserved_words_test' "
    fnEcho ${LINENO} "after load from file: '"$this_path_temp"/query_postgresql_reserved_words_test.txt'  "
    query_postgresql_reserved_words_test="$(cat  "$this_path_temp"/query_postgresql_reserved_words_test.txt | tr -d ' ' 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'query_postgresql_reserved_words_test':"
            fnEcho ${LINENO} level_0 "$query_postgresql_reserved_words_test"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/query_postgresql_reserved_words_test.txt:"
            feed_write_log="$(cat "$this_path_temp"/query_postgresql_reserved_words_test.txt 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "$query_postgresql_reserved_words_test"
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # end function 'fnDbQueryReservedWords'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnDbQueryReservedWords'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to test for PostgreSQL reserved words
#
function fnDbReservedWordsTest()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnDbReservedWordsTest'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnDbReservedWordsTest'     "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnDbReservedWordsTest' "
    fnEcho ${LINENO} ""
    #
	###################################################
	#
	#
	# query to test the attribute name against the PostgreSQL reserved words 
	# calling function 'fnDbQueryReservedWords'
	#
	fnEcho ${LINENO} ""  
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} " query to test the attribute name against the PostgreSQL reserved words       "
	fnEcho ${LINENO} " testing attribute name: "$aws_snapshot_name_underscore"       "
	fnEcho ${LINENO} " calling function 'fnDbQueryReservedWords'      "
	fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnEcho ${LINENO} ""  
	#                          
	fnDbQueryReservedWords
    #  
    ##########################################################################
    #
    #
    # checking for PostgreSQL reserved word exception; if so, appending with '_x' 
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} "checking for PostgreSQL reserved word exception; if so, appending with '_x'   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #    
    if [[ "$aws_snapshot_name_underscore" = "$query_postgresql_reserved_words_test" ]]
    	then
            fnEcho ${LINENO} ""  
            fnEcho ${LINENO} "This is a PosgreSQL reserved word - variable 'aws_snapshot_name_underscore' value: "$aws_snapshot_name_underscore"   "
            fnEcho ${LINENO} "appending '_x' to enable use   "
            aws_snapshot_name_underscore="$aws_snapshot_name_underscore"'_x'
	else
            fnEcho ${LINENO} ""  
            fnEcho ${LINENO} "This is not a PosgreSQL reserved word - variable 'aws_snapshot_name_underscore' value: "$aws_snapshot_name_underscore"   "
            fnEcho ${LINENO} ""  
    #
	fi # end check for PostgreSQL reserved word
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} " value of variable 'aws_snapshot_name_underscore': "    
    fnEcho ${LINENO} "$aws_snapshot_name_underscore"
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # end function 'fnDbReservedWordsTest'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnDbReservedWordsTest'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to test the AWS command for valid non-recursive command
#
function fnDbQueryNonRecursiveCommandTest()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnDbQueryNonRecursiveCommandTest'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnDbQueryNonRecursiveCommandTest'     "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnDbQueryNonRecursiveCommandTest' "
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # querying the non-recursive commands to test for valid AWS non-recursive command line
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " querying the non-recursive commands to test for valid AWS non-recursive command line "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "running the following query to test the non-recursive command:  "
    fnEcho ${LINENO} "SQL:  "       
    fnEcho ${LINENO} "SELECT "
    fnEcho ${LINENO} "	"$db_schema"._driver_aws_cli_commands.aws_cli_command "
    fnEcho ${LINENO} "FROM "
    fnEcho ${LINENO} " 	"$db_schema"._driver_aws_cli_commands "
    fnEcho ${LINENO} "WHERE "
    fnEcho ${LINENO} "	_driver_aws_cli_commands.aws_cli_command = "$aws_command" " 
    fnEcho ${LINENO} "	AND "$db_schema"._driver_aws_cli_commands.execute_yn = 'y' "
    fnEcho ${LINENO} "	AND "$db_schema"._driver_aws_cli_commands.recursive_yn = 'n' "
    fnEcho ${LINENO} ";"  
    fnEcho ${LINENO} ""
	#
	query_non_recursive_command_test_sql='SELECT '"$db_schema"'._driver_aws_cli_commands.aws_cli_command FROM '"$db_schema"'._driver_aws_cli_commands WHERE _driver_aws_cli_commands.aws_cli_command = '\'"$aws_command"\'' AND '"$db_schema"'._driver_aws_cli_commands.execute_yn = '\'y\'' AND '"$db_schema"'._driver_aws_cli_commands.recursive_yn = '\'n\'' ;'
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable: 'query_non_recursive_command_test_sql': "
    feed_write_log="$(echo "$query_non_recursive_command_test_sql" )"
    fnEcho ${LINENO} "$feed_write_log" 
    fnEcho ${LINENO} ""
    #
    # build the query variable
    query_non_recursive_command_test="$(psql \
    --host="$db_host" \
    --dbname="$db_name" \
    --username="$db_user" \
    --port="$db_port" \
    --set ON_ERROR_STOP=on \
    --echo-all \
    --echo-errors \
    --tuples-only \
    --no-align \
    --field-separator ' ' \
    --variable db_schema_psql=\'"$db_schema"\' \
    --variable tablename_psql=\'"$1"\' \
    --command="$query_non_recursive_command_test_sql" \
    --output=""$this_path_temp"/query_non_recursive_command_test.txt" 
    2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -eq 3 ]
        then
            #
            # set the command/pipeline error line number
            error_line_psql="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'query_non_recursive_command_test':"
            fnEcho ${LINENO} level_0 "$query_non_recursive_command_test"
            fnEcho ${LINENO} level_0 ""
            # call the psql error function
            fnErrorPsql
            #
    #
    fi # end check for command / pipeline errors 
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'query_non_recursive_command_test':  "
    feed_write_log=" "$query_non_recursive_command_test" "
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'query_non_recursive_command_test' "
    fnEcho ${LINENO} "after load from file: '"$this_path_temp"/query_non_recursive_command_test.txt'  "
    query_non_recursive_command_test="$(cat  "$this_path_temp"/query_non_recursive_command_test.txt | tr -d ' ' 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'query_non_recursive_command_test':"
            fnEcho ${LINENO} level_0 "$query_non_recursive_command_test"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/query_non_recursive_command_test.txt:"
            feed_write_log="$(cat "$this_path_temp"/query_non_recursive_command_test.txt 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "$query_non_recursive_command_test"
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # end function 'fnDbQueryNonRecursiveCommandTest'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnDbQueryNonRecursiveCommandTest'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to test the AWS command for valid recursive command
#
function fnDbQueryRecursiveCommandTest()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnDbQueryRecursiveCommandTest'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnDbQueryRecursiveCommandTest'     "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnDbQueryRecursiveCommandTest' "
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # querying the recursive commands to test for valid AWS non-recursive command line
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " querying the recursive commands to test for valid AWS recursive command line "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "running the following query to test the recursive command:  "
    fnEcho ${LINENO} "SQL:  "       
    fnEcho ${LINENO} "'SELECT '"
    fnEcho ${LINENO} "	"$db_schema"._driver_aws_cli_commands.aws_cli_command "
    fnEcho ${LINENO} "FROM "
    fnEcho ${LINENO} " 	"$db_schema"._driver_aws_cli_commands "
    fnEcho ${LINENO} "WHERE "
    fnEcho ${LINENO} "	_driver_aws_cli_commands.aws_cli_command = '\'"$aws_command"\' " 
    fnEcho ${LINENO} "	AND "$db_schema"._driver_aws_cli_commands.execute_yn = '\'y\' "
    fnEcho ${LINENO} "	AND "$db_schema"._driver_aws_cli_commands.recursive_yn = '\'y\' "
    fnEcho ${LINENO} "' ;'"  
    fnEcho ${LINENO} ""
	#
	query_recursive_command_test_sql='SELECT '"$db_schema"'._driver_aws_cli_commands.aws_cli_command FROM '"$db_schema"'._driver_aws_cli_commands WHERE _driver_aws_cli_commands.aws_cli_command = '\'"$aws_command"\'' AND '"$db_schema"'._driver_aws_cli_commands.execute_yn = '\'y\'' AND '"$db_schema"'._driver_aws_cli_commands.recursive_yn = '\'y\'' ;'
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable: 'query_recursive_command_test_sql': "
    feed_write_log="$(echo "$query_recursive_command_test_sql" )"
    fnEcho ${LINENO} "$feed_write_log" 
    fnEcho ${LINENO} ""
    #
    # build the query variable
    query_recursive_command_test="$(psql \
    --host="$db_host" \
    --dbname="$db_name" \
    --username="$db_user" \
    --port="$db_port" \
    --set ON_ERROR_STOP=on \
    --echo-all \
    --echo-errors \
    --tuples-only \
    --no-align \
    --field-separator ' ' \
    --variable db_schema_psql=\'"$db_schema"\' \
    --variable tablename_psql=\'"$1"\' \
    --command="$query_recursive_command_test_sql" \
    --output=""$this_path_temp"/query_recursive_command_test.txt" 
    2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -eq 3 ]
        then
            #
            # set the command/pipeline error line number
            error_line_psql="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'query_recursive_command_test':"
            fnEcho ${LINENO} level_0 "$query_recursive_command_test"
            fnEcho ${LINENO} level_0 ""
            # call the psql error function
            fnErrorPsql
            #
    #
    fi # end check for command / pipeline errors 
    #
    fnEcho ${LINENO} "value of variable 'query_recursive_command_test':  "
    feed_write_log=" "$query_recursive_command_test" "
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "contents of file: '"$this_path_temp"/query_recursive_command_test.txt'  "
    feed_write_log="$(cat "$this_path_temp"/query_recursive_command_test.txt | tr -d ' ' 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/query_recursive_command_test.txt:"
            feed_write_log="$(cat "$this_path_temp"/query_recursive_command_test.txt 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "$feed_write_log"
    fnEcho ${LINENO} ""
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'query_recursive_command_test' "
    fnEcho ${LINENO} "after load from file: '"$this_path_temp"/query_recursive_command_test.txt'  "
    query_recursive_command_test="$(cat "$this_path_temp"/query_recursive_command_test.txt | tr -d ' ' 2>&1)"
    #
    # check for command / pipeline error(s)
    if [ "$?" -ne 0 ]
        then
            #
            # set the command/pipeline error line number
            error_line_pipeline="$((${LINENO}-7))"
            #
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'query_recursive_command_test':"
            fnEcho ${LINENO} level_0 "$query_recursive_command_test"
            fnEcho ${LINENO} level_0 ""
            #
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/query_recursive_command_test.txt:"
            feed_write_log="$(cat "$this_path_temp"/query_recursive_command_test.txt 2>&1)"
            fnEcho ${LINENO} level_0 "$feed_write_log"
            fnEcho ${LINENO} level_0 ""
            #                                                    
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi # end check for command / pipeline error(s)
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "$query_recursive_command_test"
    fnEcho ${LINENO} ""
    #
    ##########################################################################
    #
    #
    # end function 'fnDbQueryRecursiveCommandTest'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnDbQueryRecursiveCommandTest'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
#
##########################################################################
#
#
# function to test for valid AWS service
#
function fnAwsServiceTestValid()
{
    #
    ##########################################################################
    #
    #
    # begin function 'fnAwsServiceTestValid'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " begin function 'fnAwsServiceTestValid'     "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "in function: 'fnAwsServiceTestValid' "
    fnEcho ${LINENO} ""
	#
    ##########################################################################
    #
    #
    # test for a valid AWS service
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " ' test for a valid AWS service    "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #        
 	aws_service_test_valid_list="$(cat "$this_path_temp"/sps-driver-aws-services.txt | tr -d ' ' 2>&1)"
     #
     # check for command / pipeline error(s)
     if [ "$?" -ne 0 ]
         then
             #
             # set the command/pipeline error line number
             error_line_pipeline="$((${LINENO}-7))"
             #
             #
             fnEcho ${LINENO} level_0 ""
             fnEcho ${LINENO} level_0 "value of variable 'aws_service_test_valid_list':"
             fnEcho ${LINENO} level_0 "$aws_service_test_valid_list"
             fnEcho ${LINENO} level_0 ""
             #
             fnEcho ${LINENO} level_0 ""
             fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/sps-driver-aws-services.txt:"
             feed_write_log="$(cat "$this_path_temp"/sps-driver-aws-services.txt 2>&1)"
             fnEcho ${LINENO} level_0 "$feed_write_log"
             fnEcho ${LINENO} level_0 ""
             #                                                    
             # call the command / pipeline error function
             fnErrorPipeline
             #
     #
     fi # end check for command / pipeline error(s)
     #
     fnEcho ${LINENO} ""
     fnEcho ${LINENO} "value of variable 'aws_service_test_valid_list': "    
     fnEcho ${LINENO} "$aws_service_test_valid_list"
     fnEcho ${LINENO} ""
     #
     while read aws_service_test_valid_list_line
     do
        #
	    ##########################################################################
	    #
	    #
	    # value of variable 'aws_service_test_valid_list_line': "$aws_service_test_valid_list_line"    
	    #
	    fnEcho ${LINENO} ""  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} " value of variable 'aws_service_test_valid_list_line': "$aws_service_test_valid_list_line"       "  
	    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	    fnEcho ${LINENO} ""                	
		#
		##########################################################################
		#
		#
		# checking for valid AWS service 
		#
		fnEcho ${LINENO} ""  
		fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		fnEcho ${LINENO} "checking for valid AWS service  "
		fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		fnEcho ${LINENO} ""  
 	    #
 	    fnEcho ${LINENO} ""
 	    fnEcho ${LINENO} " value of variable 'aws_service_test_valid_list_line': "    
 	    fnEcho ${LINENO} "$aws_service_test_valid_list_line"
 	    fnEcho ${LINENO} ""
        #    
        if [[ "$aws_service" = "$aws_service_test_valid_list_line" ]]
         	then
		 	    #
		 	    fnEcho ${LINENO} ""
		 	    fnEcho ${LINENO} ""$aws_service_test_valid_list_line" is a valid AWS service"
		 	    fnEcho ${LINENO} " returning from the function via the 'return' command "    
		 	    fnEcho ${LINENO} ""
		        #    
		        return 
		        #
	        else 
		 	    #
		 	    fnEcho ${LINENO} ""
		 	    fnEcho ${LINENO} "pull the next line via the 'continue' command" 
		 	    fnEcho ${LINENO} ""
		 	    #
		 	    continue
		        #    
 	    #
 		fi # end check for for valid AWS service 
		fnEcho ${LINENO} ""  
		fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		fnEcho ${LINENO} "no valid AWS service name found  "
		fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		fnEcho ${LINENO} ""  
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} ">> internal ERROR << variable 'aws_service' value "$aws_service" is not a valid AWS service for this run "
        fnEcho ${LINENO} ""  
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "exiting the utility "
        fnEcho ${LINENO} ""  
        #
        error_line_pipeline="$((${LINENO}-25))"
        #
        fnErrorPipeline
        #
 	done< <(echo "$aws_service_test_valid_list")
    #
    ##########################################################################
    #
    #
    # end function 'fnAwsServiceTestValid'     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " end function 'fnAwsServiceTestValid'      "       
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #   
}
# 
###############################################################################
#  
# >>>> end functionDefinition <<<< 
#
###############################################################################
#
###############################################################################
#  
# >>>> begin setup <<<< 
#
###############################################################################
#
# 
###########################################################################################################################
#
#
# enable logging to capture initial segments
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " enable logging to capture initial segments    "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
logging="x"
# 
###########################################################################################################################
#
#
# build the menu and header text line and bars 
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " build the menu and header text line and bars    "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
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
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " display initializing message    "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
clear
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 "$text_header"
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 " This utility snapshots AWS Services and writes the data to JSON files and database tables "
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 " This script will: "
fnEcho ${LINENO} level_0 " - Capture the current state of AWS Services  "
fnEcho ${LINENO} level_0 " - Write the current state of each service to a JSON file "
fnEcho ${LINENO} level_0 " - Write the current state of each service to a PostgreSQL database table "
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 "$text_header_bar"
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 "                            Please wait  "
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 "  Checking the input parameters and initializing the app " 
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 "  Depending on connection speed and AWS API response, this can take " 
fnEcho ${LINENO} level_0 "  from a few seconds to a few minutes "
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 "$text_header_bar"
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 ""
# 
#
###################################################
#
#
# log the task counts  
# 
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " log the task counts    "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
fnEcho ${LINENO} "value of variable 'count_this_file_tasks': "$count_this_file_tasks" "
fnEcho ${LINENO} "value of variable 'count_this_file_tasks_end': "$count_this_file_tasks_end" "
fnEcho ${LINENO} "value of variable 'count_this_file_tasks_increment': "$count_this_file_tasks_increment" "
#
###################################################
#
#
# check command line parameters 
# check for -h
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " check command line parameters     "
fnEcho ${LINENO} " check for -h    "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
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
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " check command line parameters     "
fnEcho ${LINENO} " check for --version     "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
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
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " check command line parameters     "
fnEcho ${LINENO} " if less than 2, then display the Usage     "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
if [[ "$#" -lt 2 ]]  
    then
        clear
        fnEcho ${LINENO} level_0 ""
        fnEcho ${LINENO} level_0 "-------------------------------------------------------------------------------"
        fnEcho ${LINENO} level_0 ""
        fnEcho ${LINENO} level_0 "  ERROR: You did not enter all of the required parameters " 
        fnEcho ${LINENO} level_0 ""
        fnEcho ${LINENO} level_0 "  You must provide a profile name for the profile parameter: -p  "
        fnEcho ${LINENO} level_0 ""
        fnEcho ${LINENO} level_0 "  Example: "$0" -p MyProfileName  "
        fnEcho ${LINENO} level_0 ""
        fnEcho ${LINENO} level_0 "-------------------------------------------------------------------------------"
        fnEcho ${LINENO} level_0 ""
        fnUsage
fi
#
###################################################
#
#
# check command line parameters 
# if too many parameters, then display the error message and useage
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " check command line parameters     "
fnEcho ${LINENO} " if too many parameters, then display the error message and useage     "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
if [[ "$#" -gt 12 ]]  
    then
        clear
        fnEcho ${LINENO} level_0 ""
        fnEcho ${LINENO} level_0 "-------------------------------------------------------------------------------"
        fnEcho ${LINENO} level_0 ""
        fnEcho ${LINENO} level_0 "  ERROR: You entered too many parameters" 
        fnEcho ${LINENO} level_0 ""
        fnEcho ${LINENO} level_0 "  You must provide only one value for all parameters: -p -d -r -b -g  "
        fnEcho ${LINENO} level_0 ""
        fnEcho ${LINENO} level_0 "  Example: "$0" -p MyProfileName -d MyDriverFile.txt -r us-east-1 -b y -g y"
        fnEcho ${LINENO} level_0 ""
        fnEcho ${LINENO} level_0 "-------------------------------------------------------------------------------"
        fnEcho ${LINENO} level_0 ""
        fnUsage
fi
#
###################################################
#
#
# command line parameter values 
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " command line parameter values     "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
fnEcho ${LINENO} ""
fnEcho ${LINENO} "value of variable '@': "$@" "
fnEcho ${LINENO} ""
fnEcho ${LINENO} "value of parameter '1' "$1" "
fnEcho ${LINENO} "value of parameter '2' "$2" "
fnEcho ${LINENO} "value of parameter '3' "$3" "
fnEcho ${LINENO} "value of parameter '4' "$4" "
fnEcho ${LINENO} "value of parameter '5' "$5" "
fnEcho ${LINENO} "value of parameter '6' "$6" "
fnEcho ${LINENO} "value of parameter '7' "$7" "
fnEcho ${LINENO} "value of parameter '8' "$8" "
fnEcho ${LINENO} "value of parameter '9' "$9" "
fnEcho ${LINENO} "value of parameter '10' "${10}" "
fnEcho ${LINENO} "value of parameter '11' "${11}" "
fnEcho ${LINENO} "value of parameter '12' "${12}" "
#
###################################################
#
#
# load the main loop variables from the command line parameters 
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " load the main loop variables from the command line parameters      "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
while getopts "p:d:r:b:g:x:h" opt; 
    do
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of variable '@': "$@" "
        fnEcho ${LINENO} "value of variable 'opt': "$opt" "
        fnEcho ${LINENO} "value of variable 'OPTIND': "$OPTIND" "
        fnEcho ${LINENO} ""   
        #     
        case "$opt" in
        p)
            cli_profile="$OPTARG"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "value of -p 'cli_profile': "$cli_profile" "
        ;;
        r)
            aws_region="$OPTARG"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "value of -r 'aws_region': "$aws_region" "
        ;;      
        b)
            verbose="$OPTARG"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "value of -b 'verbose': "$verbose" "
        ;;  
        g)
            logging="$OPTARG"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "value of -g 'logging': "$logging" "
        ;;  
        z)
            logging="$OPTARG"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "value of -g 'logging': "$logging" "
        ;;  
        x)
            execute_direct="$OPTARG"
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "value of -x 'execute_direct': "$logging" "
        ;;  
        h)
            fnUsage
        ;;   
        \?)
            fnEcho ${LINENO} ""
            fnEcho ${LINENO} "invalid parameter entry "
            fnEcho ${LINENO} "value of variable 'OPTARG': "$OPTARG" "
            clear
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "---------------------------------------------------------------------"
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "  ERROR: You entered an invalid parameter." 
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "  Parameters entered: "$@""
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "---------------------------------------------------------------------"
            fnEcho ${LINENO} level_0 ""
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
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " check logging variable      "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
fnEcho ${LINENO} ""
fnEcho ${LINENO} "value of variable '@': "$@" "
fnEcho ${LINENO} ""
fnEcho ${LINENO} "value of variable 'logging': "$logging" "
fnEcho ${LINENO} ""
#
###################################################
#
#
# disable logging if not set by the -g parameter 
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " disable logging if not set by the -g parameter       "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
fnEcho ${LINENO} "if logging not enabled by parameter, then disabling logging "
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
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " set the log suffix parameter       "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
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
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " log the parameter values      "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
fnEcho ${LINENO} ""
fnEcho ${LINENO} "value of variable 'cli_profile': "$cli_profile" "
fnEcho ${LINENO} "value of variable 'execute_direct': "$execute_direct" "
fnEcho ${LINENO} "value of variable 'verbose': "$verbose" "
fnEcho ${LINENO} "value of variable 'logging': "$logging" "
fnEcho ${LINENO} "value of variable 'log_suffix': "$log_suffix" "
fnEcho ${LINENO} "value of -r 'aws_region': "$aws_region" "
#
###################################################
#
#
# check command line parameters 
# check for valid AWS CLI profile 
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " check command line parameters      "
fnEcho ${LINENO} " check for valid AWS CLI profile "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
fnEcho ${LINENO} ""
fnEcho ${LINENO} "count the available AWS CLI profiles that match the -p parameter profile name "
count_cli_profile="$(cat /home/"$this_user"/.aws/config | grep -c "$cli_profile")"
# if no match, then display the error message and the available AWS CLI profiles 
if [[ "$count_cli_profile" -ne 1 ]]
    then
        clear
        fnEcho ${LINENO} level_0 ""
        fnEcho ${LINENO} level_0 "--------------------------------------------------------------------------"
        fnEcho ${LINENO} level_0 ""
        fnEcho ${LINENO} level_0 "  ERROR: You entered an invalid AWS CLI profile: "$cli_profile" " 
        fnEcho ${LINENO} level_0 ""
        fnEcho ${LINENO} level_0 "  Available cli_profiles are:"
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
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'cli_profile_available':"
                fnEcho ${LINENO} level_0 "$cli_profile_available"
                fnEcho ${LINENO} level_0 ""
                #
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "contents of file '/home/'"$this_user"'/.aws/config':"
                feed_write_log="$(cat /home/"$this_user"/.aws/config 2>&1)"
                fnEcho ${LINENO} level_0 "$feed_write_log"
                fnEcho ${LINENO} level_0 ""
                #                                                    
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi # end check for command / pipeline error(s)
        #
        fnEcho ${LINENO} "value of variable 'cli_profile_available': "$cli_profile_available ""
        feed_write_log="$(echo "  "$cli_profile_available"" 2>&1)"
        fnEcho ${LINENO} level_0 "$feed_write_log"
        fnEcho ${LINENO} level_0 ""
        fnEcho ${LINENO} level_0 "  To set up an AWS CLI profile enter: aws configure --profile profileName "
        fnEcho ${LINENO} level_0 ""
        fnEcho ${LINENO} level_0 "  Example: aws configure --profile MyProfileName "
        fnEcho ${LINENO} level_0 ""
        fnEcho ${LINENO} level_0 "--------------------------------------------------------------------------"
        fnEcho ${LINENO} level_0 ""
        fnUsage
fi  # end test of count of matching AWS CLI profiles  
#
#
fnEcho ${LINENO} ""
fnEcho ${LINENO} "value of variable 'count_cli_profile':"
fnEcho ${LINENO} "$count_cli_profile"
fnEcho ${LINENO} ""
#
###################################################
#
#
# pull the AWS account number
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " pull the AWS account number  "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
fnEcho ${LINENO} ""
fnEcho ${LINENO} "pulling AWS account"
aws_account="$(aws sts get-caller-identity --profile "$cli_profile" --output text --query 'Account' 2>&1)"
fnEcho ${LINENO} "value of variable 'aws_account': "$aws_account" "
fnEcho ${LINENO} ""
#
###################################################
#
#
# set the aws account dependent variables
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " set the aws account dependent variables  "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
fnEcho ${LINENO} ""
fnEcho ${LINENO} "setting the AWS account dependent variables"
#
#
# check for 'all' regions
if [[ "$aws_region" != 'all' ]]
    then
        write_path="$this_path"/aws-"$aws_account"-"$aws_region"-"$this_utility_filename_plug"-"$date_file"
        write_path_snapshots="$write_path"/"$this_utility_filename_plug"-files
        this_path_temp="$write_path"/"$this_utility_acronym"-temp
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
write_file_service_names="$this_utility_acronym"'-write-file-service-names.txt'
db_schema='aws_'"$this_utility_acronym"'_'"$aws_account"'_'"$date_file_underscore"
#
fnEcho ${LINENO} "value of variable 'aws_region':"
fnEcho ${LINENO} " "$aws_region" "
fnEcho ${LINENO} "value of variable 'write_path': "
fnEcho ${LINENO} ""$write_path" "
fnEcho ${LINENO} "value of variable 'write_path_snapshots':"
fnEcho ${LINENO} ""$write_path_snapshots" "
fnEcho ${LINENO} "value of variable 'this_path_temp':"
fnEcho ${LINENO} " "$this_path_temp" "
fnEcho ${LINENO} "value of variable 'this_file_account_region_services_all':"
fnEcho ${LINENO} " "$this_file_account_region_services_all" "
fnEcho ${LINENO} "value of variable 'this_log_file': "$this_log_file" "
fnEcho ${LINENO} "value of variable 'this_log_file_errors':"
fnEcho ${LINENO} " "$this_log_file_errors" "
fnEcho ${LINENO} "value of variable 'this_log_file_full_path':"
fnEcho ${LINENO} " "$this_log_file_full_path" "
fnEcho ${LINENO} "value of variable 'this_log_file_errors_full_path':"
fnEcho ${LINENO} " "$this_log_file_errors_full_path" "
fnEcho ${LINENO} "value of variable 'this_summary_report': "$this_summary_report" "
fnEcho ${LINENO} "value of variable 'this_summary_report_full_path':"
fnEcho ${LINENO} " "$this_summary_report_full_path" "
fnEcho ${LINENO} "value of variable 'write_file_service_names':"
fnEcho ${LINENO} " "$write_file_service_names" "
fnEcho ${LINENO} ""
#
###################################################
#
#
# set the task count based on all regions
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " set the task count based on all regions   "
fnEcho ${LINENO} " if not all regions, subtract one task for the 'all regions merge' task   "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
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
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " create the directories   "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
fnEcho ${LINENO} ""
fnEcho ${LINENO} "creating write path directories "
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
        fnEcho ${LINENO} level_0 ""
        fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
        fnEcho ${LINENO} level_0 "$feed_write_log"
        fnEcho ${LINENO} level_0 ""
        #                                                            
        # call the command / pipeline error function
        fnErrorPipeline
        #
fi
#
fnEcho ${LINENO} "$feed_write_log"
fnEcho ${LINENO} ""
fnEcho ${LINENO} "status of write path directories "
feed_write_log="$(ls -ld */ "$this_path" 2>&1)"
fnEcho ${LINENO} "$feed_write_log"
fnEcho ${LINENO} ""
#
fnEcho ${LINENO} ""
fnEcho ${LINENO} "creating temp path directory "
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
        fnEcho ${LINENO} level_0 ""
        fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
        fnEcho ${LINENO} level_0 "$feed_write_log"
        fnEcho ${LINENO} level_0 ""
        #                                                            
        # call the command / pipeline error function
        fnErrorPipeline
        #
fi
#
fnEcho ${LINENO} "$feed_write_log"
fnEcho ${LINENO} ""
fnEcho ${LINENO} "status of temp path directories "
feed_write_log="$(ls -ld */ "$this_path_temp" 2>&1)"
fnEcho ${LINENO} "$feed_write_log"
fnEcho ${LINENO} ""
#
#
###################################################
#
#
# pull the AWS account alias
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " pull the AWS account alias    "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
fnEcho ${LINENO} ""
fnEcho ${LINENO} "pulling AWS account alias"
aws_account_alias="$(aws iam list-account-aliases --profile "$cli_profile" --output text --query 'AccountAliases' 2>&1)"
fnEcho ${LINENO} "value of variable 'aws_account_alias': "$aws_account_alias" "
fnEcho ${LINENO} ""
#
###############################################################################
# 
#
# Initialize the log file
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " Initialize the log file    "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
if [[ ("$logging" = "y") || ("$logging" = "z") ]] 
    then
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "initializing the log file "
        fnEcho ${LINENO} ""
        echo "Log start" > "$this_log_file_full_path"
        echo "" >> "$this_log_file_full_path"
        echo "This log file name: "$this_log_file"" >> "$this_log_file_full_path"
        echo "" >> "$this_log_file_full_path"
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "contents of file:'$this_log_file_full_path' "
        feed_write_log="$(cat "$this_log_file_full_path"  2>&1)"
        fnEcho ${LINENO} "$feed_write_log"
        fnEcho ${LINENO} ""
#
fi 
#
###############################################################################
# 
#
# Initialize the error log file
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " Initialize the error log file    "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
echo "  Errors:" > "$this_log_file_errors_full_path"
echo "" >> "$this_log_file_errors_full_path"
#
###################################################
#
#
# initialize the write_file_service_names file 
#
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " initialize the write_file_service_names file: "$this_path_temp"/"$write_file_service_names"     "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#        
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "value of variable 'this_path_temp':"
fnEcho ${LINENO} " "$this_path_temp" "
fnEcho ${LINENO} ""  
#    
#        
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "value of variable 'write_file_service_names':"
fnEcho ${LINENO} " "$write_file_service_names" "
fnEcho ${LINENO} ""  
#    
#        
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "initializing file with command:"
fnEcho ${LINENO} " echo "" > "$this_path_temp"/"$write_file_service_names" "  
fnEcho ${LINENO} ""  
#    
feed_write_log="$(echo "" > "$this_path_temp"/"$write_file_service_names" 2>&1)"
#
# check for command / pipeline error(s)
if [ "$?" -ne 0 ]
    then
        #
        # set the command/pipeline error line number
        error_line_pipeline="$((${LINENO}-7))"
        #
        #
        fnEcho ${LINENO} level_0 ""
        fnEcho ${LINENO} level_0 "value of variable 'feed_write_log':"
        fnEcho ${LINENO} level_0 "$feed_write_log"
        fnEcho ${LINENO} level_0 ""
        #
        fnEcho ${LINENO} level_0 ""
        fnEcho ${LINENO} level_0 "contents of file "$this_path_temp"/"$write_file_service_names":"
        feed_write_log="$(cat "$this_path_temp"/"$write_file_service_names")"
        fnEcho ${LINENO} level_0 "$feed_write_log"
        fnEcho ${LINENO} level_0 ""
        #                                                                                                                                            
        # call the command / pipeline error function
        fnErrorPipeline
        #
        #
fi  # end check for pipeline error 
#
fnEcho ${LINENO} "$feed_write_log"
fnEcho ${LINENO} ""
fnEcho ${LINENO} ""
#
###################################################
#
#
# set the region
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " set the region     "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
fnEcho ${LINENO} "test for -p profile parameter value "
fnEcho ${LINENO} "value of parameter 'aws_region': "$aws_region""
if [[ "$aws_region" = "" ]] 
    then
        fnEcho ${LINENO} "count the number of AWS profiles on the system "    
        count_cli_profile_regions="$(cat /home/"$this_user"/.aws/config | grep 'region' | wc -l 2>&1)"
        fnEcho ${LINENO} "value of variable 'count_cli_profile_regions': "$count_cli_profile_regions ""
        if [[ "$count_cli_profile_regions" -lt 2 ]] 
            then
                fnEcho ${LINENO} "one cli profile - setting region from "$cli_profile""           
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
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 "value of variable 'aws_region':"
                        fnEcho ${LINENO} level_0 "$aws_region"
                        fnEcho ${LINENO} level_0 ""
                        #                                                                            
                        # call the command / pipeline error function
                        fnErrorPipeline
                        #
                #
                fi        
                #
            else 
                fnEcho ${LINENO} "multiple cli profiles - setting region from "$cli_profile""           
                aws_region="$(cat /home/"$this_user"/.aws/config | sed -n "/dev01/, /profile/p" | grep 'region' | sed 's/region =//' | tr -d ' ')"
                if [ "$?" -ne 0 ]
                    then
                        #
                        # set the command/pipeline error line number
                        error_line_pipeline="$((${LINENO}-7))"
                        #
                        #
                        fnEcho ${LINENO} level_0 ""
                        fnEcho ${LINENO} level_0 "value of variable 'aws_region':"
                        fnEcho ${LINENO} level_0 "$aws_region"
                        fnEcho ${LINENO} level_0 ""
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
fnEcho ${LINENO} ""
fnEcho ${LINENO} "value of parameter 'aws_region': "$aws_region""
fnEcho ${LINENO} ""
#
###################################################
#
#
# check command line parameters 
# check for valid -r region parameter 
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " check command line parameters     "
fnEcho ${LINENO} " check for valid -r region parameter     "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
if [[ "$aws_region" != 'all' ]]
    then
        fnEcho ${LINENO} "testing for valid -r region parameter "
        fnEcho ${LINENO} "command: aws ec2 describe-instances --profile "$cli_profile" --region "$aws_region" "
        feed_write_log="$(aws ec2 describe-instances --profile "$cli_profile" --region "$aws_region" 2>&1)"
                    #
                    # check for errors from the AWS API  
                    if [ "$?" -ne 0 ]
                        then
                            clear 
                            # AWS Error while testing the -r region parameter
                            fnEcho ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
                            fnEcho ${LINENO} level_0 ""
                            fnEcho ${LINENO} level_0 "AWS error message: "
                            fnEcho ${LINENO} level_0 "$feed_write_log"
                            fnEcho ${LINENO} level_0 ""
                            fnEcho ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
                            count_aws_region_check="$(echo "$feed_write_log" | grep 'Could not connect to the endpoint' | wc -l)"
                            if [[ "$count_aws_region_check" > 0 ]]
                                then 
                                    fnEcho ${LINENO} level_0 ""
                                    fnEcho ${LINENO} level_0 " AWS Error while testing your -r aws_region parameter entry: "$aws_region" "
                                    fnEcho ${LINENO} level_0 ""
                                    fnEcho ${LINENO} level_0 " Please correct your entry for the -r parameter "
                                    fnEcho ${LINENO} level_0 ""
                                    fnEcho ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
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
        # fnEcho ${LINENO} "$feed_write_log"
fi  # end test for valid region if not all
#
#
###########################################################################################################################
#
#
# Begin checks and setup 
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " Begin checks and setup     "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
#
#
##########################################################################
#
#
# if all regions, then pull the AWS regions available for this account
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " if all regions, then pull the AWS regions available for this account    "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
if [[ "$aws_region" = 'all' ]]
    then
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} level_0 "Pulling the list of available regions from AWS"
        fnEcho ${LINENO} level_0 ""
        fnEcho ${LINENO} level_0 "This task can take a while. Please wait..."
        fnEcho ${LINENO} ""       
        fnEcho ${LINENO} "pulling a list of current AWS regions and loading variable 'aws_region_list' "
        fnEcho ${LINENO} "command: aws ec2 describe-regions --output text --profile "$cli_profile" "
        fnEcho ${LINENO} ""
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
                fnEcho ${LINENO} level_0 ""
                fnEcho ${LINENO} level_0 "value of variable 'aws_region_list':"
                fnEcho ${LINENO} level_0 "$aws_region_list"
                fnEcho ${LINENO} level_0 ""
                #                                                    
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        # append the global region
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "appending 'global' to variable 'aws_region_list':  "
        aws_region_list+=$'\n'"global"
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of variable 'aws_region_list':  "
        feed_write_log="$(echo "$aws_region_list" 2>&1)"
        fnEcho ${LINENO} "$feed_write_log"
        fnEcho ${LINENO} ""
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "counting the list of current AWS regions"
        count_aws_region_list="$(echo "$aws_region_list" | wc -l 2>&1)"
        # add 1 for the merge operation for all regions  
        count_aws_region_list=$((count_aws_region_list+1))
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of variable 'count_aws_region_list': "$count_aws_region_list" "
        fnEcho ${LINENO} ""
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "initializing the region counter"
        counter_aws_region_list=0
        #
    else 
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "in a single region run "
        fnEcho ${LINENO} "setting the variable 'count_aws_region_list' to 2 ( 1 the for region, 1 for merge-all task ) "
        count_aws_region_list=2
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of variable 'count_aws_region_list': "$count_aws_region_list" "
        fnEcho ${LINENO} ""
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "initializing the region counter"
        counter_aws_region_list=0
        #
fi  # end test of 'all' regions -r parameter
#
#
##########################################################################
#
#
# creating the account-timestamp database schema for the run
# calling function: 'fnDbSchemaCreate'    
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " creating the account-timestamp database schema for the run   "
fnEcho ${LINENO} " calling function: 'fnDbSchemaCreate'  "   
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#
fnDbSchemaCreate
#
#
##########################################################################
#
#
# creating the services and AWS CLI commands tables for the run
# calling function: 'fnDbTableCreate'    
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " creating the services and AWS CLI commands tables for the run   "
fnEcho ${LINENO} " calling function: 'fnDbTableCreate'  "   
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#
fnDbTableCreate
#
#
fnEcho ${LINENO} ""
fnEcho ${LINENO} "value of variable 'count_aws_region_list': "$count_aws_region_list" "
fnEcho ${LINENO} ""
#
#
##########################################################################
#
#
# query the count of AWS services to snapshot
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " query the count of AWS services to snapshote   "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#   
#
fnEcho ${LINENO} ""
fnEcho ${LINENO} "value of variable 'db_host': "$db_host" "
fnEcho ${LINENO} "value of variable 'db_host': "$db_name" "
fnEcho ${LINENO} "value of variable 'db_host': "$db_user" "
fnEcho ${LINENO} "value of variable 'db_host': "$db_port" "
fnEcho ${LINENO} "value of variable 'db_host': "$db_schema" "
fnEcho ${LINENO} ""
#        
query_count_services="$(psql \
--host="$db_host" \
--dbname="$db_name" \
--username="$db_user" \
--port="$db_port" \
--set ON_ERROR_STOP=on \
--echo-all \
--echo-errors \
--tuples-only \
--no-align \
--field-separator ' ' \
--command="SELECT COUNT(*) FROM "$db_schema"._driver_aws_services where execute_yn = 'y';" 
2>&1)"
#
# check for command error(s)
if [ "$?" -eq 3 ]
    then
        #
        # set the command/pipeline error line number
        error_line_psql="$((${LINENO}-7))"
        #
        #
        fnEcho ${LINENO} level_0 ""
        fnEcho ${LINENO} level_0 "value of variable 'query_count_services':"
        fnEcho ${LINENO} level_0 "$query_count_services"
        fnEcho ${LINENO} level_0 ""
        # call the psql error function
        fnErrorPsql
        #
#
fi
#
#
fnEcho ${LINENO} ""
fnEcho ${LINENO} "value of variable 'query_count_services':"
feed_write_log="$(echo "$query_count_services"  2>&1)"
fnEcho ${LINENO} "$feed_write_log"
fnEcho ${LINENO} ""  
#
#
###################################################
#
#
# clear the console
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " clear the console    "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
clear
#
# 
#
###################################################
#
#
# check for direct execution; if not, display the opening menu
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " check for direct execution; if not, display the opening menu    "
fnEcho ${LINENO} " value of variable 'execute_direct': "$execute_direct"    "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
#
if [[ "$execute_direct" != 'y' ]] 
    then 
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} " not in direct execution mode, displaying menu   "
    fnEcho ${LINENO} ""  
    #
    ###################################################
    #
    #
    # display the opening menu
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " display the opening menu    "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                          
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
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " Opening menu     "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                          
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 "$text_menu"
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 " Snapshot AWS Services status to JSON files and PostgreSQL database tables   "  
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 "$text_menu_bar"
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 "AWS account:............"$aws_account"  "$aws_account_alias" "
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 "AWS region:............"$aws_region" "
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 "Count of AWS Services to snapshot: "$query_count_services" "
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 "$text_menu_bar"
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 "The AWS Services will be snapshotted and the current status will be written to "
    fnEcho ${LINENO} level_0 "JSON files and PostgreSQL database tables "
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 " ###############################################"
    fnEcho ${LINENO} level_0 " >> Note: There is no undo for this operation << "
    fnEcho ${LINENO} level_0 " ###############################################"
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 " By running this utility script you are taking full responsibility for any and all outcomes"
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 "AWS Service Snapshot utility"
    fnEcho ${LINENO} level_0 "Run Utility Y/N Menu"
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
        [[ -n "$choice" ]] || { fnEcho ${LINENO} level_0 "Invalid choice." >&2; continue; }
        #
        # Examine the choice.
        # Note that it is the choice string itself, not its number
        # that is reported in "$choice".
        case "$choice" in
            Run)
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "Running AWS Service Snapshot utility"
                    fnEcho ${LINENO} level_0 ""
                    # Set flag here, or call function, ...
                ;;
            Exit)
            #
            #
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "Exiting the utility..."
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 ""
                    # drop the database schema
                    fnDbSchemaDrop
                    # delete the work files
                    fnDeleteWorkFiles
                    # append the temp log onto the log file
                    fnFileAppendLogTemp
                    # write the log variable to the log file
                    fnFileAppendLog
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
fi # end check of direct execute
#
###############################################################################
#  
# >>>> end setup <<<< 
#
###############################################################################
#
###############################################################################
#  
# >>>> begin main <<<< 
#
###############################################################################
#
##########################################################################
#
#
# ---- begin: write the initial values to the log 
#
##########################################################################
#
# write the start timestamp to the log
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " write the start timestamp to the log     "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#
##########################################################################
#
#
# set the run timestamp 
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " setting the run timestamp       "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
date_now="$(date +"%Y-%m-%d-%H%M%S")"
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "-------------------------------------------------------------------------------------------" 
fnEcho ${LINENO} "-------------------------------------------------------------------------------------------" 
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "run start timestamp: "$date_now" " 
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "-------------------------------------------------------------------------------------------" 
fnEcho ${LINENO} "-------------------------------------------------------------------------------------------" 
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "" 
fnEcho ${LINENO} ""  
#
##########################################################################
#
#
# log the log location 
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " log the log location     "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "-------------------------------------------------------------------------------------------" 
fnEcho ${LINENO} "-------------------------------------------------------------------------------------------" 
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "Run log is here: "$this_log_file_full_path" " 
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "-------------------------------------------------------------------------------------------" 
fnEcho ${LINENO} "-------------------------------------------------------------------------------------------" 
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "" 
#
##########################################################################
#
#
# log the version  
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " log the version     "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "-------------------------------------------------------------------------------------------" 
fnEcho ${LINENO} "-------------------------------------------------------------------------------------------" 
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "Snapshot Utility Version: "$version" " 
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "-------------------------------------------------------------------------------------------" 
fnEcho ${LINENO} "-------------------------------------------------------------------------------------------" 
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "" 
#
##########################################################################
#
#
# ---- end: write the initial values to the log 
#
##########################################################################
#
##########################################################################
#
#
# increment the task counter    
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " increment the task counter      "  
fnEcho ${LINENO} " calling function 'fnCounterIncrementTask'      "               
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#
fnCounterIncrementTask
#
##########################################################################
#
#
# clear the console for the run 
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " clear the console for the run      "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#
##########################################################################
#
#
# display the header     
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " display the header      "  
fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#          
fnDisplayHeader
#
##########################################################################
#
#
# ---- begin: set the file variables  
#
##########################################################################
#
###################################################
#
#
# set the non-recursive driver file variables 
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " set the non-recursive driver file variables    "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
file_snapshot_driver_aws_cli_commands_non_recursive_file_name="$this_utility_acronym"-driver-aws-cli-commands-non-recursive.txt	
file_snapshot_driver_aws_cli_commands_non_recursive_file_name_raw="$this_utility_acronym"-driver-aws-cli-commands-non-recursive-raw.txt
file_snapshot_driver_aws_cli_commands_non_recursive_file_name_stripped="$this_utility_acronym"-driver-aws-cli-commands-non-recursive-stripped.txt		
#
fnEcho ${LINENO} ""
fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_non_recursive_file_name': "$file_snapshot_driver_aws_cli_commands_non_recursive_file_name"  "
fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_non_recursive_file_name_raw': "$file_snapshot_driver_aws_cli_commands_non_recursive_file_name_raw"  "
fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_non_recursive_file_name_stripped': "$file_snapshot_driver_aws_cli_commands_non_recursive_file_name_stripped"  "
fnEcho ${LINENO} ""
#
###################################################
#
#
# set the recursive single driver file variables 
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " set the recursive single driver file variables    "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
file_snapshot_driver_aws_cli_commands_recursive_single_file_name="$this_utility_acronym"-driver-aws-cli-commands-recursive-single.txt	
file_snapshot_driver_aws_cli_commands_recursive_single_file_name_queries="$this_utility_acronym"-driver-aws-cli-commands-recursive-single-queries.txt
file_snapshot_driver_aws_cli_commands_recursive_single_file_name_results="$this_utility_acronym"-driver-aws-cli-commands-recursive-single-results.txt
file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw="$this_utility_acronym"-driver-aws-cli-commands-recursive-single-raw.txt
file_snapshot_driver_aws_cli_commands_recursive_single_file_name_stripped="$this_utility_acronym"-driver-aws-cli-commands-recursive-single-stripped.txt		
#
fnEcho ${LINENO} ""
fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_recursive_single_file_name': "$file_snapshot_driver_aws_cli_commands_recursive_single_file_name"  "
fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_recursive_single_file_name_queries': "$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_queries"  "
fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_recursive_single_file_name_results': "$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_results"  "
fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw': "$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_raw"  "
fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_recursive_single_file_name_stripped': "$file_snapshot_driver_aws_cli_commands_recursive_single_file_name_stripped"  "
#
###################################################
#
#
# set the recursive single dependent driver file variables 
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " set the recursive single dependent driver file variables    "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name="$this_utility_acronym"-driver-aws-cli-commands-recursive-single-dependent.txt	
file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_queries="$this_utility_acronym"-driver-aws-cli-commands-recursive-single-dependent-queries.txt
file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_results="$this_utility_acronym"-driver-aws-cli-commands-recursive-single-dependent-results.txt
file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_raw="$this_utility_acronym"-driver-aws-cli-commands-recursive-single-dependent-raw.txt
file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_stripped="$this_utility_acronym"-driver-aws-cli-commands-recursive-single-dependent-stripped.txt		
#
fnEcho ${LINENO} ""
fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name': "$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name"  "
fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_queries': "$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_queries"  "
fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_results': "$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_results"  "
fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_raw': "$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_raw"  "
fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_stripped': "$file_snapshot_driver_aws_cli_commands_recursive_single_dependent_file_name_stripped"  "
fnEcho ${LINENO} ""
fnEcho ${LINENO} ""
#
###################################################
#
#
# set the aws global services driver file variables 
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " set the aws global services driver file variable   "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
file_snapshot_driver_global_services_file_name="$this_utility_acronym"-driver-aws-services-global.txt
file_snapshot_driver_aws_cli_commands_all_file_name="$this_utility_acronym"-driver-aws-cli-commands-all.txt	
file_snapshot_driver_aws_cli_commands_all_file_name_raw="$this_utility_acronym"-driver-aws-cli-commands-all-raw.txt	
file_snapshot_driver_aws_cli_commands_all_file_name_stripped="$this_utility_acronym"-driver-aws-cli-commands-all-stripped.txt	
file_snapshot_driver_aws_cli_commands_global_file_name="$this_utility_acronym"-driver-aws-cli-commands-global.txt
file_snapshot_driver_aws_cli_commands_global_file_name_raw="$this_utility_acronym"-driver-aws-cli-commands-global-raw.txt
file_snapshot_driver_aws_cli_commands_global_file_name_stripped="$this_utility_acronym"-driver-aws-cli-commands-global-stripped.txt
file_snapshot_driver_aws_cli_commands_non_global_file_name="$this_utility_acronym"-driver-aws-cli-commands-non-global.txt
file_snapshot_driver_aws_cli_commands_non_global_file_name_raw="$this_utility_acronym"-driver-aws-cli-commands-non-global-raw.txt	
file_snapshot_driver_aws_cli_commands_non_global_file_name_stripped="$this_utility_acronym"-driver-aws-cli-commands-non-global-stripped.txt	
#
fnEcho ${LINENO} ""
fnEcho ${LINENO} "value of variable 'file_snapshot_driver_global_services_file_name': "$file_snapshot_driver_global_services_file_name"  "
fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_all_file_name': "$file_snapshot_driver_aws_cli_commands_all_file_name"  "
fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_all_file_name_raw': "$file_snapshot_driver_aws_cli_commands_all_file_name_raw"  "
fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_all_file_name_stripped': "$file_snapshot_driver_aws_cli_commands_all_file_name_stripped"  "	
fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_global_file_name': "$file_snapshot_driver_aws_cli_commands_global_file_name"  "
fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_global_file_name_raw': "$file_snapshot_driver_aws_cli_commands_global_file_name_raw"  "
fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_global_file_name_stripped': "$file_snapshot_driver_aws_cli_commands_global_file_name_stripped"  "
fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_non_global_file_name': "$file_snapshot_driver_aws_cli_commands_non_global_file_name"  "
fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_non_global_file_name_raw': "$file_snapshot_driver_aws_cli_commands_non_global_file_name_raw"  "
fnEcho ${LINENO} "value of variable 'file_snapshot_driver_aws_cli_commands_non_global_file_name_stripped': "$file_snapshot_driver_aws_cli_commands_non_global_file_name_stripped"  "
fnEcho ${LINENO} ""
#
##########################################################################
#
#
# ---- end: set the file variables  
#
##########################################################################
#
##########################################################################
#
#
# increment the task counter    
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " increment the task counter      "  
fnEcho ${LINENO} " calling function 'fnCounterIncrementTask'      "               
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#
fnCounterIncrementTask
#
##########################################################################
#
#
# ---- begin: build the command lists  
#
##########################################################################
#
###################################################
#
#
# build the AWS command list
# calling function 'fnCommandListBuild'
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " build the AWS command list      "
fnEcho ${LINENO} " calling function 'fnCommandListBuild'      "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
fnCommandListBuild
#
###################################################
#
#
# count the commands to process 
# calling function 'fnCommandCount'
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " count the commands to process      "
fnEcho ${LINENO} " calling function 'fnCommandCount'      "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#
fnCommandCount
#    
###################################################
#
#
# set the count aws snapshot commands variable '' 
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " set the count aws snapshot commands variable 'count_aws_snapshot_commands'      "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                          
count_aws_snapshot_commands=0
count_aws_snapshot_commands="$count_file_snapshot_driver_file_name_aws_cli_commands_all"
#
#
fnEcho ${LINENO} ""
fnEcho ${LINENO} "value of variable 'count_aws_snapshot_commands': "$1"  "
fnEcho ${LINENO} ""
#
##########################################################################
#
#
# ---- end: build the command lists  
#
##########################################################################
#
##########################################################################
#
#
# increment the task counter    
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " increment the task counter      "  
fnEcho ${LINENO} " calling function 'fnCounterIncrementTask'      "               
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#
fnCounterIncrementTask
#
##########################################################################
#
#
# increment the AWS region counter to initial value of 1
# calling function: 'fnCounterIncrementAwsSnapshotCommands'
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} "increment the AWS region counter to initial value of 1 "               
fnEcho ${LINENO} "calling function: 'fnCounterIncrementRegions' "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                  
fnCounterIncrementRegions
#
fnEcho ${LINENO} ""
fnEcho ${LINENO} "value of variable 'counter_aws_region_list': "$counter_aws_region_list" "
fnEcho ${LINENO} "value of variable 'count_aws_region_list': "$count_aws_region_list" "
fnEcho ${LINENO} ""
#
##########################################################################
#
#
# increment the AWS snapshot command counter to initial value of 1
# calling function: 'fnCounterIncrementAwsSnapshotCommands'
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} "increment the AWS snapshot command counter to initial value of 1 "               
fnEcho ${LINENO} "calling function: 'fnCounterIncrementAwsSnapshotCommands' "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                  
fnCounterIncrementAwsSnapshotCommands
#
fnEcho ${LINENO} ""
fnEcho ${LINENO} "value of variable 'counter_aws_snapshot_commands': "$counter_aws_snapshot_commands" "
fnEcho ${LINENO} "value of variable 'count_aws_snapshot_commands': "$count_aws_snapshot_commands" "
fnEcho ${LINENO} ""
#
##########################################################################
#
##########################################################################
#
##########################################################################
#
# pull the services  
#
fnEcho ${LINENO} ""
fnEcho ${LINENO} ""
fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnEcho ${LINENO} ""
fnEcho ${LINENO} "---------------------------------- begin: pull services for each region ----------------------------------"
fnEcho ${LINENO} ""
fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnEcho ${LINENO} ""
fnEcho ${LINENO} ""
#
##########################################################################
#
#
# display the header     
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " display the header      "  
fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#          
fnDisplayHeader
#
##########################################################################
#
#
# set the source and stripped file names 
# calling function: 'fnVariableLoadCommandFileSource'    
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " set the source and stripped file names    "
fnEcho ${LINENO} " calling function: 'fnVariableLoadCommandFileSource'   "   
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#
fnVariableLoadCommandFileSource "$file_snapshot_driver_aws_cli_commands_non_global_file_name" "$file_snapshot_driver_aws_cli_commands_non_global_file_name_stripped"
#
##########################################################################
#
#
# set variable 'counter_driver_services' to 0
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " set variable 'counter_driver_services' to 0  "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
# 
fnEcho ${LINENO} "reset the task counter variable 'counter_driver_services' to 0 "
counter_driver_services=0
#
fnEcho ${LINENO} ""
fnEcho ${LINENO} "value of variable 'count_driver_services': "$counter_driver_services" " 
fnEcho ${LINENO} ""
#
#
##########################################################################
#
#
# if not all regions, then set the list to the region -r parameter and append 'global'
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " if not all regions, then set the list to the region -r parameter and append 'global'   "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
# 
if [[ "$aws_region" != 'all' ]]
    then 
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "not an all regions run so set variable 'aws_region_list' to -r parameter and append 'global': " 
        aws_region_list+="$aws_region"$'\n'"global"        
fi # end check for not all regions
#
fnEcho ${LINENO} ""
fnEcho ${LINENO} "value of variable 'aws_region_list': " 
feed_write_log="$(echo "$aws_region_list" 2>&1)"
fnEcho ${LINENO} "$feed_write_log"
fnEcho ${LINENO} ""
#
##########################################################################
#
#
# begin region loop     
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " begin region loop      "  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#          
# 
fnEcho ${LINENO} ""
fnEcho ${LINENO} "entering the 'read aws_region_list' loop"
#
while read -r aws_region_list_line 
do
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "-------------------------------------------------------------------------------  "                                
    fnEcho ${LINENO} "----------------------- loop head: read aws_region_list -----------------------  "
    fnEcho ${LINENO} "-------------------------------------------------------------------------------  "                                    
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # value of variable 'aws_region_list_line' "$aws_region_list_line"    
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " value of variable 'aws_region_list_line': "$aws_region_list_line"       "  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
    ##########################################################################
    #
    #
    # display the header     
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " display the header      "  
    fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #          
    fnDisplayHeader
    #
    # display the task progress bar
    #
    fnDisplayProgressBarTask "$counter_aws_region_list" "$count_aws_region_list"
    #
    #
    ##########################################################################
    #
    #
    # create the write directory
    # calling function: 'fnWriteDirectoryCreate' 
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " create the write directory   "
    fnEcho ${LINENO} " calling function: 'fnWriteDirectoryCreate'   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
	fnWriteDirectoryCreate
    #
    #
    ##########################################################################
    #
    #
    # check for global region; if global, set command file source to global 
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " check for global region; if global, set command file source to global   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'counter_aws_region_set': "$counter_aws_region_set" "
    fnEcho ${LINENO} ""
    #
    # test if the global source files have already been set on this run
    if [[ "$counter_aws_region_set" = 0 ]] 
    	then 
		    #
		    fnEcho ${LINENO} ""
		    fnEcho ${LINENO} "global source files have not yet been set on this run "
		    fnEcho ${LINENO} ""
		    #
		    fnEcho ${LINENO} ""
		    fnEcho ${LINENO} "value of variable 'aws_region_list_line': "$aws_region_list_line" "
		    fnEcho ${LINENO} ""
		    #
    		# test if the region is 'global'; if so, set the command file source to global 
			if [[ "$aws_region_list_line" = 'global' ]]
			    then 
				    #
				    fnEcho ${LINENO} ""
				    fnEcho ${LINENO} "region is global, so setting the command source file to global: "
				    fnEcho ${LINENO} "fnVariableLoadCommandFileSource "$file_snapshot_driver_aws_cli_commands_global_file_name" "$file_snapshot_driver_aws_cli_commands_global_file_name_stripped" "				    
				    fnEcho ${LINENO} ""
					#
					##########################################################################
					#
					#
					# set the load command file source to create the stripped command file  
					# calling function: 'fnVariableLoadCommandFileSource'    
					#
					fnEcho ${LINENO} ""  
					fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
					fnEcho ${LINENO} " set the source and stripped file names    "
					fnEcho ${LINENO} " calling function: 'fnVariableLoadCommandFileSource'   "   
					fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
					fnEcho ${LINENO} ""  
					#
					fnVariableLoadCommandFileSource "$file_snapshot_driver_aws_cli_commands_global_file_name" "$file_snapshot_driver_aws_cli_commands_global_file_name_stripped"
					#
					# increment the region set counter
					counter_aws_region_set=$((counter_aws_region_set+1))
				    #
				    fnEcho ${LINENO} ""
				    fnEcho ${LINENO} "value of variable 'counter_aws_region_set': "$counter_aws_region_set" "
				    fnEcho ${LINENO} ""
				    #
			#
			fi # end test for global region
	#
	fi # end test for prior region set
	# 
    ##########################################################################
    #
    #
    #  begin pull the snapshots for the region 
    #
    # 
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " pull the snapshots for the region    "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                       
    #
    ##########################################################################
    #
    ##########################################################################
    #
    # 
    # pulling the snapshots of the AWS services 
    # calling function: fnAwsPullSnapshots for region: "$aws_region_list_line" "
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------" 
    fnEcho ${LINENO} " pulling the snapshots of the AWS services    "    
    fnEcho ${LINENO} " calling function: fnAwsPullSnapshots for region: "$aws_region_list_line"   "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    fnAwsPullSnapshots "$aws_region_list_line"
    #
    ##########################################################################
    #
    ##########################################################################
    #
    #
    # remove the unneeded snapshot JSON files created for the recursive source run
    # calling function: fnFileSnapshotUnneededDelete
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " remove any duplicates from the list of snapshotted services  "
    fnEcho ${LINENO} " calling function: fnFileSnapshotUnneededDelete "   
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                          
	fnFileSnapshotUnneededDelete
    #
    ##########################################################################
    #
    #
    # remove any duplicates from the list of snapshotted services
    # calling function: fnDuplicateRemoveSnapshottedServices for region: "$aws_region_list_line" "
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " remove any duplicates from the list of snapshotted services  "
    fnEcho ${LINENO} " calling function: fnDuplicateRemoveSnapshottedServices for region: "$aws_region_list_line" "   
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                          
    fnDuplicateRemoveSnapshottedServices "$aws_region_list_line"
    #
    #
    #
    ##########################################################################
    #
    #
    # set the file find variable for the merge file run 
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " set the file find 'find_name' variable for the merge file run    "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "loading variable 'find_name' "
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
            fnEcho ${LINENO} level_0 ""
            fnEcho ${LINENO} level_0 "value of variable 'find_name':"
            fnEcho ${LINENO} level_0 "$find_name"
            fnEcho ${LINENO} level_0 ""
            #
            # call the command / pipeline error function
            fnErrorPipeline
            #
    #
    fi
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "value of variable 'find_name': "
    fnEcho ${LINENO} "$find_name"
    fnEcho ${LINENO} ""
    #
    #
    ##########################################################################
    #
    #
    # create the merged all services JSON file for the region
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} " create the merged all services JSON file for the region: "$aws_region_list_line"    "
    fnEcho ${LINENO} "calling function: 'fnCreateMergedServicesJsonFile' "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "calling function: fnCreateMergedServicesJsonFile for region: "$aws_region_list_line" "
    fnEcho ${LINENO} ""
    #
    fnCreateMergedServicesJsonFile "$aws_region_list_line" "$find_name"
    #
    ##########################################################################
    #
    #
    # increment the AWS region counter 
    # calling function: 'fnCounterIncrementAwsSnapshotCommands'
    #
    fnEcho ${LINENO} ""  
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} "increment the AWS region counter "               
    fnEcho ${LINENO} "calling function: 'fnCounterIncrementRegions' "
    fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnEcho ${LINENO} ""  
    #                  
    fnCounterIncrementRegions
    #
    #
    fnEcho ${LINENO} ""
    fnEcho ${LINENO} "-------------------------------------------------------------------------------  "                
    fnEcho ${LINENO} "----------------------- loop tail: read aws_region_list -----------------------  "
    fnEcho ${LINENO} "-------------------------------------------------------------------------------  "                
    fnEcho ${LINENO} ""
done< <(echo "$aws_region_list")
#
#
#
##########################################################################
#
#
# display the header     
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " display the header      "  
fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#          
fnDisplayHeader
#
#
# display the task progress bar
fnDisplayProgressBarTask "$counter_aws_region_list" "$count_aws_region_list"
#
#
fnEcho ${LINENO} ""
fnEcho ${LINENO} "----------------------- done with read aws_region_list -----------------------  "
fnEcho ${LINENO} ""
#
fnEcho ${LINENO} ""  
#
#
#
# write out the temp log and empty the log variable
fnFileAppendLogTemp
#
##########################################################################
#
#
# increment the task counter    
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " increment the task counter      "  
fnEcho ${LINENO} " calling function 'fnCounterIncrementTask'      "               
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#
fnCounterIncrementTask
#
fnEcho ${LINENO} ""
fnEcho ${LINENO} ""
fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnEcho ${LINENO} ""
fnEcho ${LINENO} "----------------------------------- end: pull services for each region -----------------------------------"
fnEcho ${LINENO} ""
fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnEcho ${LINENO} ""
fnEcho ${LINENO} ""
#
#
##########################################################################
#
#
# merge the region 'all services' json files into a master 'all services' file 
#
if [[ "$aws_region" = 'all' ]] 
    then 
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "---------------------- begin: create account 'all regions - all services' JSON file ----------------------"
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} ""
        #
        #
        ##########################################################################
        #
        #
        # display the header     
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " display the header      "  
        fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #          
        fnDisplayHeader
        #
        fnEcho ${LINENO} level_0 ""
        fnEcho ${LINENO} level_0 "Merging 'all services' files for account: "$aws_account" "
        fnEcho ${LINENO} level_0 ""                                                                                              
        #
        #
        ##########################################################################
        #
        #
        # set the file find 'find_name' variable for the merge file run 
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " set the file find 'find_name' variable for the merge file run    "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "loading variable 'find_name' "
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
                    fnEcho ${LINENO} level_0 ""
                    fnEcho ${LINENO} level_0 "value of variable 'find_name':"
                    fnEcho ${LINENO} level_0 "$find_name"
                    fnEcho ${LINENO} level_0 ""
                    #
                    # call the command / pipeline error function
                    fnErrorPipeline
                    #
            #
            fi
            #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "value of variable 'find_name': "
        fnEcho ${LINENO} "$find_name"
        fnEcho ${LINENO} ""
        #
        #
        ##########################################################################
        #
        #
        # create the merged all services JSON file for the region
        #
        fnEcho ${LINENO} ""  
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} " create the merged all services JSON file for the region    "
        fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
        fnEcho ${LINENO} ""  
        #
        fnEcho ${LINENO} ""
        fnEcho ${LINENO} "calling function: fnCreateMergedServicesJsonFile for account: "$aws_account" "
        fnEcho ${LINENO} ""
        #
        fnCreateMergedServicesAllJsonFile 'all' "$find_name"
        #
        #
fi  # end check for all regions
#
#
# write out the temp log and empty the log variable
fnFileAppendLogTemp
#
#
##########################################################################
#
#
# increment the AWS region counter 
# calling function: 'fnCounterIncrementAwsSnapshotCommands'
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} "increment the AWS region counter "               
fnEcho ${LINENO} "calling function: 'fnCounterIncrementRegions' "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                  
fnCounterIncrementRegions
#
##########################################################################
#
#
# increment the task counter    
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " increment the task counter      "  
fnEcho ${LINENO} " calling function 'fnCounterIncrementTask'      "               
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#
fnCounterIncrementTask
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} ""
fnEcho ${LINENO} ""
fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnEcho ${LINENO} ""
fnEcho ${LINENO} "----------------------- end: create account 'all regions - all services' JSON file -----------------------"
fnEcho ${LINENO} ""
fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnEcho ${LINENO} ""
fnEcho ${LINENO} ""
#
#
#
##########################################################################
#
#
# create the summary report 
#
fnEcho ${LINENO} ""
fnEcho ${LINENO} ""
fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnEcho ${LINENO} ""
fnEcho ${LINENO} "------------------------------------- begin: print summary report ----------------------------------------"
fnEcho ${LINENO} ""
fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnEcho ${LINENO} ""
fnEcho ${LINENO} ""
#
#
##########################################################################
#
#
# display the header     
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " display the header      "  
fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#          
fnDisplayHeader
#
##########################################################################
#
#
# Creating job summary report file
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} "Creating job summary report file "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                  
#
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 "Creating job summary report file "
fnEcho ${LINENO} level_0 ""
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
echo "  Driver file name: "$file_snapshot_driver_file_name" ">>"$this_summary_report_full_path"
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
if [[ ("$logging" = "y") || ("$logging" = "z") ]] 
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
        fnEcho ${LINENO} "$feed_write_log"
        echo "">>"$this_summary_report_full_path"
        echo "">>"$this_summary_report_full_path"
        echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
fi
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
#
# write the names of the snapshotted services to the report
fnEcho ${LINENO} "writing contents of variable: 'aws_region_list' to the report " 
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
fnEcho ${LINENO} "writing contents of file: "${!write_file_service_names}" to the report " 
echo "  Snapshots created for services:">>"$this_summary_report_full_path"
echo "  -----------------------------------------------------------------------">>"$this_summary_report_full_path"
#
# add leading 5 characters to match report margin
cat "$this_path_temp"/"$write_file_service_names" | sed -e 's/^/     /'>>"$this_summary_report_full_path"
#
#
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
#
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 "Summary report complete. "
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 "Report is located here: "
fnEcho ${LINENO} level_0 "$this_summary_report_full_path"
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} ""  
#
##########################################################################
#
#
# increment the task counter    
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " increment the task counter      "  
fnEcho ${LINENO} " calling function 'fnCounterIncrementTask'      "               
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#
fnCounterIncrementTask
#
fnEcho ${LINENO} ""
fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnEcho ${LINENO} ""
fnEcho ${LINENO} "----------------------------- end: print summary report for each LC name ---------------------------------"
fnEcho ${LINENO} ""
fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnEcho ${LINENO} ""
fnEcho ${LINENO} ""
#
##########################################################################
#
#
# delete the work files 
#
fnEcho ${LINENO} ""
fnEcho ${LINENO} ""
fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnEcho ${LINENO} ""
fnEcho ${LINENO} "---------------------------------------- begin: delete work files ----------------------------------------"
fnEcho ${LINENO} ""
fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnEcho ${LINENO} ""
fnEcho ${LINENO} ""
#
#
##########################################################################
#
#
# display the header     
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " display the header      "  
fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#          
fnDisplayHeader
#
#
fnDeleteWorkFiles
#
fnEcho ${LINENO} ""  
#
##########################################################################
#
#
# increment the task counter    
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " increment the task counter      "  
fnEcho ${LINENO} " calling function 'fnCounterIncrementTask'      "               
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#
fnCounterIncrementTask
#
fnEcho ${LINENO} ""
fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnEcho ${LINENO} ""
fnEcho ${LINENO} "----------------------------------------- end: delete work files -----------------------------------------"
fnEcho ${LINENO} ""
fnEcho ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnEcho ${LINENO} ""
fnEcho ${LINENO} ""
#
##########################################################################
#
#
# display the job complete message 
#
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " display the job complete message    "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                       
#
##########################################################################
#
#
# display the header     
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " display the header      "  
fnEcho ${LINENO} " calling function 'fnDisplayHeader'      "               
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#          
fnDisplayHeader
#
#
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 "                            Job Complete "
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 " Summary report location: "
fnEcho ${LINENO} level_0 " "$write_path"/ "
fnEcho ${LINENO} level_0 " "$this_summary_report" "
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 " Snapshots location: "
fnEcho ${LINENO} level_0 " "$write_path_snapshots"/"
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 ""
if [[ ("$logging" = "y") || ("$logging" = "z") ]] 
    then
        fnEcho ${LINENO} level_0 " Log location: "
        fnEcho ${LINENO} level_0 " "$write_path"/ "
        fnEcho ${LINENO} level_0 " "$this_log_file" "
        fnEcho ${LINENO} level_0 ""
fi 
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 "----------------------------------------------------------------------"
fnEcho ${LINENO} level_0 ""
fnEcho ${LINENO} level_0 ""
if (( "$count_error_lines" > 2 ))
    then
    fnEcho ${LINENO} level_0 ""
    feed_write_log="$(cat "$this_log_file_errors_full_path" 2>&1)" 
    fnEcho ${LINENO} level_0 "$feed_write_log"
    fnEcho ${LINENO} level_0 ""
    fnEcho ${LINENO} level_0 "----------------------------------------------------------------------"
    fnEcho ${LINENO} level_0 ""
fi
#
##########################################################################
#
#
# write the stop timestamp to the log 
#
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " write the stop timestamp to the log     "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                       
date_now="$(date +"%Y-%m-%d-%H%M%S")"
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "-------------------------------------------------------------------------------------------" 
fnEcho ${LINENO} "-------------------------------------------------------------------------------------------" 
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "run end timestamp: "$date_now" " 
fnEcho ${LINENO} "" 
fnEcho ${LINENO} "-------------------------------------------------------------------------------------------" 
fnEcho ${LINENO} "-------------------------------------------------------------------------------------------" 
fnEcho ${LINENO} "" 
#
##########################################################################
#
#
# write the log file 
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " write the log file      "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                       
if [[ ("$logging" = "y") || ("$logging" = "z") ]] 
    then 
        # append the temp log onto the log file
        fnFileAppendLogTemp
        # write the log variable to the log file
        fnFileAppendLog
    else 
        # delete the temp log file
        rm -f "$this_log_temp_file_full_path"        
fi
#
#
##########################################################################
#
#
# exit with success 
#
fnEcho ${LINENO} ""  
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} " exit with success     "
fnEcho ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnEcho ${LINENO} ""  
#                       
exit 0
#
#
#
###############################################################################
#  
# >>>> end main <<<< 
#
###############################################################################
#
#
##########################################
# 
# end bash shell script 
#
##########################################


