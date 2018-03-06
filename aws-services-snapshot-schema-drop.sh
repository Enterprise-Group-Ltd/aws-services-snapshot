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
# File: aws-services-snapshot-schema-drop.sh
# Source: https://github.com/Enterprise-Group-Ltd/aws-services-snapshot
#
script_version=0.0.7  
#
#  Dependencies:
#  - postgresql instance running on EC2; setup instructions here:
#  - bash shell
#
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
# 
# Type: PostreSQL utility
#
# Description: 
# This utility executes a series of shell and psql commands that drop PostgreSQL schemas created 
# by the AWS Services Snapshot utility 
#
#
# Roadmap:
# - none at this time
#
#
#
###############################################################################
#  
# >>>> end documentation <<<< 
#
###############################################################################
# 
###############################################################################
#  
# >>>> --- begin: initialize <<<< 
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
#
count_schema=0
counter_schema=0
db_host=""
db_name=""
db_port="" 
db_schema=""
db_user=""
feed_write_log=""
filter_aws_account=""
filter_cloud=""
filter_date_max=""
filter_date_max_input=""
filter_day=""
filter_hhmmss=""
filter_month=""
filter_timestamp=""
filter_util=""
filter_year=""
query_schema_drop=""
query_schema_list=""
query_schema_list_filtered=""
query_schema_list_line_filtered=""
schemas_dropped=""
verbose=""
#
###############################################################################
# 
#
# initialize the baseline variables
#
this_utility_acronym="spsds"
this_utility_filename_plug="snapshot-drop-schema"
date_file="$(date +"%Y-%m-%d-%H%M%S")"
date_file_underscore="$(date +"%Y_%m_%d_%H%M%S")"
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
counter_schema=0
#
db_host="localhost"
db_name="aws_snapshot"
db_port="5432"
db_type="postresql"
db_user="ec2-user"
#
write_path="$this_path"/aws-"$this_utility_filename_plug"-"$date_file"
write_path_schemas="$write_path"/"$this_utility_filename_plug"-files
this_path_temp="$write_path"/"$this_utility_acronym"-temp-"$date_file"
this_file_account_region_services_all="$write_path_schemas"/"aws-""$this_utility_filename_plug"-"$date_file"-all-services.json 
this_file_account_services_all="$write_path_schemas"/"aws-"-"$this_utility_filename_plug"-"$date_file"-all-services.json         
this_log_file="aws-""$this_utility_filename_plug"-"$date_file"-"$log_suffix".log 
this_log_file_errors=aws-"$this_utility_filename_plug"-"$date_file"-errors.log 
this_log_file_full_path="$write_path"/"$this_log_file"
this_log_file_errors_full_path="$write_path"/"$this_log_file_errors"
this_summary_report="aws-""$this_utility_filename_plug"-"$date_file"-summary-report.txt
this_summary_report_full_path="$write_path"/"$this_summary_report"
#
# 
###############################################################################
#  
# >>>> --- end: initialize <<<< 
#
###############################################################################
#
# 
###############################################################################
#  
# >>>> --- begin: functionDefinition <<<< 
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
    echo " ---------------------------------- AWS Service Snapshot Schema Drop utility usage -----------------------------------"
    echo ""
    echo " This utility drops PostgreSQL schemas older than a specific date timestamp  "  
    echo ""
    echo " This script will: "
    echo " * Drop PostgreSQL schemas from the database: 'aws_snapshot' "
    echo ""
    echo "----------------------------------------------------------------------------------------------------------------------"
    echo ""
    echo " Usage:"
    echo "         aws-services-snapshot-schema-drop.sh -t timestamp "
    echo ""
    echo "         Optional parameters: -b y -g y "
    echo ""
    echo " Where: "
    echo "  -t - The date timestamp. All schemas older than this date timestamp will be dropped"
    echo "         Example: -t 2018-03-28-182417 "
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
    printf "\r           Schema Progress : [${_fill_task// /#}${_empty_task// /-}] ${_progress_task}%%"

}
#
#######################################################################
#
#
# function to display the subtask text   
#
function fnTaskSubText() 
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable: 'counter_schema': "$counter_schema" "
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable: 'count_schema': "$count_schema" "
    fnWriteLog ${LINENO} ""         
    #
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "This job takes a while. Please wait..."
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 ""                                                         
    fnWriteLog ${LINENO} level_0 "Dropping schema: "$query_schema_list_filtered_date_line"  " 
    fnWriteLog ${LINENO} level_0"" 
    fnWriteLog ${LINENO} ""   
    fnWriteLog ${LINENO} ""   
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
                feed_write_log="$(rm -f "$write_path_schemas"/"$this_utility_acronym"* 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                feed_write_log="$(rm -f "$write_path_schemas"/"$this_utility_acronym"* 2>&1)"
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
# function to handle command or pipeline errors 
#
function fnErrorPipeline()
{
    #                                                                                                                                                                                                                               #
    ##########################################################################
    #
    #
    # begin function 'fnErrorPipeline'     
    #
    fnWriteLog ${LINENO} ""  
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnWriteLog ${LINENO} " begin function 'fnErrorPipeline'      "       
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnWriteLog ${LINENO} ""  
    #                          
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
# function for psql errors 
#
function fnErrorPsql()
{
    #                                                                                                                                                                                                                               #
    ##########################################################################
    #
    #
    # begin function 'fnErrorPsql'     
    #
    fnWriteLog ${LINENO} ""  
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnWriteLog ${LINENO} " begin function 'fnErrorPsql'      "       
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnWriteLog ${LINENO} ""  
    #                              
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnErrorPsql' "
    fnWriteLog ${LINENO} ""
    #    
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Error at script line number: "$error_line_psql" "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " There was a psql error while querying the database "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Please check the psql error message above "
    fnWriteLog ${LINENO} level_0 ""
    if [[ ("$logging" = "y") || ("$logging" = "z") ]]
        then 
            fnWriteLog ${LINENO} level_0 " The log will also show the AWS error message and other diagnostic information "
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 " The log is located here: "
            fnWriteLog ${LINENO} level_0 " "$write_path"/ "
            fnWriteLog ${LINENO} level_0 " "$this_log_file" "
    fi
    fnWriteLog ${LINENO} level_0 " The log will also show the psql error message and other diagnostic information "
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
# function to increment the schema counter 
#
function fnCounterIncrementSchema()
{
    #                                                                                                                                                                                                                               #
    ##########################################################################
    #
    #
    # begin function 'fnCounterIncrementSchema'     
    #
    fnWriteLog ${LINENO} ""  
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnWriteLog ${LINENO} " begin function 'fnCounterIncrementSchema'      "       
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnWriteLog ${LINENO} ""  
    #                              
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in function: 'fnCounterIncrementSchema' "
    fnWriteLog ${LINENO} ""
    #      
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "increment the schema counter: 'counter_schema'"
    counter_schema="$((counter_schema+1))"
    fnWriteLog ${LINENO} ""    
    fnWriteLog ${LINENO} "post-increment value of variable 'counter_schema': "$counter_schema" "
    fnWriteLog ${LINENO} ""
    #
    #                                                                                                                                                                                                                               #
    ##########################################################################
    #
    #
    # end function 'fnCounterIncrementSchema'     
    #
    fnWriteLog ${LINENO} ""  
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnWriteLog ${LINENO} " end function 'fnCounterIncrementSchema'      "       
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
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
    #                                                                                                                                                                                                                               #
    ##########################################################################
    #
    #
    # begin function 'fnCounterIncrementTask'     
    #
    fnWriteLog ${LINENO} ""  
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnWriteLog ${LINENO} " begin function 'fnCounterIncrementTask'      "       
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnWriteLog ${LINENO} ""  
    #                              
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
    #                                                                                                                                                                                                                               #
    ##########################################################################
    #
    #
    # end function 'fnCounterIncrementTask'     
    #
    fnWriteLog ${LINENO} ""  
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnWriteLog ${LINENO} " end function 'fnCounterIncrementTask'      "       
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnWriteLog ${LINENO} ""  
    #                              
}
# 
# run once for initialization
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
# run again for functionDefinition
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
#
###############################################################################
#  
# >>>> --- end: functionDefinition <<<< 
#
###############################################################################
#
###############################################################################
#  
# >>>> --- begin: setup <<<< 
#
###############################################################################
#
# 
###########################################################################################################################
#
#
# enable logging to capture initial segments
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " enable logging to capture initial segments    "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#                          
logging="x"
# 
###########################################################################################################################
#
#
# build the menu and header text line and bars 
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " build the menu and header text line and bars    "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#                          
text_header='AWS Services Snapshot Schema Drop Utility v'
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
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " display initializing message    "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#                          
clear
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_header"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " This utility drops schemas from the PostgreSQL that are older than a specific date timestamp "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " This script will: "
fnWriteLog ${LINENO} level_0 " - Drop PostgreSQL schemas from the database 'aws_snapshot'   "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_header_bar"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "                            Please wait  "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "  Checking the input parameters and initializing the app " 
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "  Depending on connection speed and PostgreSQL response, this can take " 
fnWriteLog ${LINENO} level_0 "  from a few seconds to a few minutes "
fnWriteLog ${LINENO} level_0 ""
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
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " log the task counts    "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
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
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " check command line parameters     "
fnWriteLog ${LINENO} " check for -h    "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
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
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " check command line parameters     "
fnWriteLog ${LINENO} " check for --version     "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#                          
if [[ "$1" = "--version" ]]  
    then
        clear 
        echo ""
        echo "'AWS Services Snapshot Schema Drop' script version: "$script_version" "
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
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " check command line parameters     "
fnWriteLog ${LINENO} " if less than 2, then display the Usage     "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#                          
if [[ "$#" -lt 2 ]]  
    then
        clear
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "-------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  ERROR: You did not enter all of the required parameters " 
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  You must provide a timestamp for the profile parameter: -t  "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  Example: "$0" -t 2018-03-27-134318  "
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
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " check command line parameters     "
fnWriteLog ${LINENO} " if too many parameters, then display the error message and useage     "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#                          
if [[ "$#" -gt 6 ]]  
    then
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
# command line parameter values 
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " command line parameter values     "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
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
fnWriteLog ${LINENO} "value of parameter '7' "$7" "
fnWriteLog ${LINENO} "value of parameter '8' "$8" "
fnWriteLog ${LINENO} "value of parameter '9' "$9" "
fnWriteLog ${LINENO} "value of parameter '10' "${10}" "
fnWriteLog ${LINENO} "value of parameter '11' "${11}" "
fnWriteLog ${LINENO} "value of parameter '12' "${12}" "
#
###################################################
#
#
# load the main loop variables from the command line parameters 
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " load the main loop variables from the command line parameters      "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#                          
while getopts "t:b:g:h" opt; 
    do
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable '@': "$@" "
        fnWriteLog ${LINENO} "value of variable 'opt': "$opt" "
        fnWriteLog ${LINENO} "value of variable 'OPTIND': "$OPTIND" "
        fnWriteLog ${LINENO} ""   
        #     
        case "$opt" in
        t)
            filter_date_max_input="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -t 'filter_date_max_input': "$cli_profile" "
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
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " check logging variable      "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
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
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " disable logging if not set by the -g parameter       "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
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
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " set the log suffix parameter       "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
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
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " log the parameter values      "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#                          
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'filter_date_max_input': "$filter_date_max_input" "
fnWriteLog ${LINENO} "value of variable 'verbose': "$verbose" "
fnWriteLog ${LINENO} "value of variable 'logging': "$logging" "
fnWriteLog ${LINENO} "value of variable 'log_suffix': "$log_suffix" "
#
##########################################################################
#
#
# set the filter date
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " set the filter date    "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#    
# removing dashes or underscores in the date max parameter        
filter_date_max="$(echo "$filter_date_max_input" | sed s/-//g | sed s/_//g )"
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'filter_date_max': "
feed_write_log="$(echo "$filter_date_max"  2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""  
#   
#
###################################################
#
#
# create the directories
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " create the directories   "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#                          
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "creating write path directories "
feed_write_log="$(mkdir -p "$write_path_schemas" 2>&1)"
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
###############################################################################
# 
#
# Initialize the query_schema_list_filtered_date.txt file
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " Initialize the query_schema_list_filtered_date.txt file    "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#                          
echo "" > "$this_path_temp"/query_schema_list_filtered_date.txt
#
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "contents of file '"$this_path_temp"/query_schema_list_filtered_date.txt' : "
feed_write_log="$(cat "$this_path_temp"/query_schema_list_filtered_date.txt  2>&1)"
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
#
###############################################################################
# 
#
# Initialize the log file
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " Initialize the log file    "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#                          
if [[ ("$logging" = "y") || ("$logging" = "z") ]] 
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
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " Initialize the error log file    "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#                          
echo "  Errors:" > "$this_log_file_errors_full_path"
echo "" >> "$this_log_file_errors_full_path"
#
#
##########################################################################
#
#
# query the list of PostgreSQL schemas
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " query the list of PostgreSQL schemas    "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#            
query_schema_list="$(psql \
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
--command="select schema_name from information_schema.schemata;;" 
2>&1 )"
#
# check for command error(s)
if [ "$?" -eq 3 ]
    then
        #
        # set the command/pipeline error line number
        error_line_psql="$((${LINENO}-7))"
        #
        #
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "value of variable 'query_schema_list':"
        fnWriteLog ${LINENO} level_0 "$query_schema_list"
        fnWriteLog ${LINENO} level_0 ""
        # call the command / pipeline error function
        fnErrorPsql
        #
#
fi
#
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'query_schema_list': "
feed_write_log="$(echo "$query_schema_list"  2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""  
#   
fnWriteLog ${LINENO} ""
#
#
##########################################################################
#
#
# filter the schema list for older schemas
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " filter the schema list for older schemas   "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#   
# filter for the schemas
query_schema_list_filtered_name="$(echo "$query_schema_list" | grep -E '^aws_sps_[0-9]{12}.*' )"
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'query_schema_list_filtered_name': "
feed_write_log="$(echo "$query_schema_list_filtered_name"  2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""  
# 
#
# read each schema name and test it for older date
while read query_schema_list_filtered_name_line
	do
		# backup the bash parse variable
		IFS_backup="$IFS"
		# set the bash parse variable to underscore
		IFS='_'
		# parse the schema name and test for older date		
		while read filter_cloud filter_util filter_aws_account filter_year filter_month filter_day filter_hhmmss 
			do
				#
				filter_timestamp="$filter_year""$filter_month""$filter_day""$filter_hhmmss"
				#
				if [[ "$filter_timestamp" -lt "$filter_date_max" ]] 
					then 
				        #     
				        # schema is older, writing it to the schema drop file   
					    #
					    fnWriteLog ${LINENO} ""
					    fnWriteLog ${LINENO} "schema is older, writing it to the schema drop file    "				    
					    fnWriteLog ${LINENO} "value of variable 'query_schema_list_filtered_name_line':  "
					    fnWriteLog ${LINENO} "$query_schema_list_filtered_name_line"
					    fnWriteLog ${LINENO} ""
					    #      
				        feed_write_log="$(echo "$query_schema_list_filtered_name_line" >> "$this_path_temp"/query_schema_list_filtered_date.txt 2>&1)"
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
				fi # end test for older schema timestamp
				#
		done< <(echo "$query_schema_list_filtered_name_line")
		# restore the bash parse variable
		IFS="$IFS_backup"
		#
done< <(echo "$query_schema_list_filtered_name")
#
#
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "contents of file '"$this_path_temp"/query_schema_list_filtered_date.txt' : "
feed_write_log="$(cat "$this_path_temp"/query_schema_list_filtered_date.txt  2>&1)"
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
#   
#
#
##########################################################################
#
#
# count the schemas
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " count the schemas   "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#   
# count non-empty lines
# the following is throwing an error on zero count 
count_schema="$(cat "$this_path_temp"/query_schema_list_filtered_date.txt | grep -v '^$' | wc -l 2>&1)"
# #
# # check for command / pipeline error(s)
# if [ "$?" -ne 0 ]
#     then
#         #
#         # set the command/pipeline error line number
#         error_line_pipeline="$((${LINENO}-7))"
#         #
#         #
#         fnWriteLog ${LINENO} level_0 ""
#         fnWriteLog ${LINENO} level_0 "value of variable 'count_schema':"
#         fnWriteLog ${LINENO} level_0 "$feed_write_log"
#         fnWriteLog ${LINENO} level_0 ""
#         #                                                                                                
#         # call the command / pipeline error function
#         fnErrorPipeline
#         #
# #
# fi  # end check for pipeline error(s)        
# #
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'count_schema': "
feed_write_log="$(echo "$count_schema"  2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""  
#
#
##########################################################################
#
#
# check for zero schemas to drop
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " check for zero schemas to drop   "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#   
if [[ "$count_schema" = 0 ]] 
	then 
		#                                                                                                                                                                                                                               #
		##########################################################################
		#
		#
		# clear the console    
		#
		fnWriteLog ${LINENO} ""  
		fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		fnWriteLog ${LINENO} " clear the console     "  
		fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		fnWriteLog ${LINENO} ""  
		#
		clear 
		#                                                                                                                                                                                                                               #
		##########################################################################
		#
		#
		# display the header     
		#
		fnWriteLog ${LINENO} ""  
		fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		fnWriteLog ${LINENO} " display the header      "  
		fnWriteLog ${LINENO} " calling function 'fnHeader'      "               
		fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
		fnWriteLog ${LINENO} ""  
		#          
		fnHeader
	    #       
	    fnWriteLog ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------"       
	    fnWriteLog ${LINENO} level_0 ""
	    fnWriteLog ${LINENO} level_0 " Zero Schemas to Drop Error "
	    fnWriteLog ${LINENO} level_0 ""
	    fnWriteLog ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------"
	    fnWriteLog ${LINENO} level_0 ""
	    fnWriteLog ${LINENO} level_0 " There are no schemas to drop  "
	    fnWriteLog ${LINENO} level_0 ""
	    fnWriteLog ${LINENO} level_0 " Please check the date timestamp "
	    fnWriteLog ${LINENO} level_0 ""
	    fnWriteLog ${LINENO} level_0 " Date timestamp: "$filter_date_max_input" "
	    fnWriteLog ${LINENO} level_0 ""
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
fi # end check for zero schemas to drop	
#                                                                                                                                                                                                                               #
##########################################################################
#
#
# clear the console    
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " clear the console     "  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
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
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " Opening menu     "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#                          
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_menu"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " Drop PostgreSQL schemas older than: "$filter_date_max_input"   "  
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_menu_bar"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "Count of PostgreSQL schemas to drop: "$count_schema" "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_menu_bar"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "The PostgreSQL schemas to be dropped: "
#
feed_write_log="$(cat "$this_path_temp"/query_schema_list_filtered_date.txt  2>&1)"
fnWriteLog ${LINENO} level_0 "$feed_write_log"
#    
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "The PostgreSQL schemas in the list above will be dropped "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " ###############################################"
fnWriteLog ${LINENO} level_0 " >> Note: There is no undo for this operation << "
fnWriteLog ${LINENO} level_0 " ###############################################"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " By running this utility script you are taking full responsibility for any and all outcomes"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "AWS Services Snapshot Schema Drop utility"
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
                fnWriteLog ${LINENO} level_0 "Running AWS Service Snapshot Schema Drop utility"
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
#
# run for setup
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
###############################################################################
#  
# >>>> --- end: setup <<<< 
#
###############################################################################
#
###############################################################################
#  
# >>>> --- begin: main <<<< 
#
###############################################################################
#
#                                                                                                                                                                                                                               #
##########################################################################
#
#
# clear the console    
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " clear the console     "  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#
clear 
#                                                                                                                                                                                                                               #
##########################################################################
#
#
# display the header     
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " display the header      "  
fnWriteLog ${LINENO} " calling function 'fnHeader'      "               
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#          
fnHeader
#
##########################################################################
#
#
# --- begin: loop read: '"$this_path_temp"/query_schema_list_filtered_date.txt'
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " begin loop read: '"$this_path_temp"/query_schema_list_filtered_date.txt'   "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#   
while read -r query_schema_list_filtered_date_line 
do 
	#
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------------------------  "          
    fnWriteLog ${LINENO} "--------------------------- loop head read: '"$this_path_temp"/query_schema_list_filtered_date.txt' ---------------------------  "
    fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------------------------  "          
    fnWriteLog ${LINENO} ""   
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'query_schema_list_filtered_date_line':  "
    fnWriteLog ${LINENO} "$query_schema_list_filtered_date_line"
    fnWriteLog ${LINENO} ""
    #      
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "dropping the schema: "$query_schema_list_filtered_date_line" "
    fnWriteLog ${LINENO} ""
	#                                                                                                                                                                                                                               #
	##########################################################################
	#
	#
	# display the header     
	#
	fnWriteLog ${LINENO} ""  
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} " display the header      "  
	fnWriteLog ${LINENO} " calling function 'fnHeader'      "               
	fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
	fnWriteLog ${LINENO} ""  
	#          
	fnHeader
    #                                                                                                                                                                                                                               #
    ##########################################################################
    #
    #
    # display the task progress bar
    #
    #
    fnWriteLog ${LINENO} ""  
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnWriteLog ${LINENO} " display the task progress bar       "  
    fnWriteLog ${LINENO} " calling function 'fnProgressBarTaskDisplay'      "               
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnWriteLog ${LINENO} ""  
	#
	fnProgressBarTaskDisplay "$counter_schema" "$count_schema"
    #
    #                                                                                                                                                                                                                               #
    ##########################################################################
    #
    #
    # display the subtask text      
    #
    fnWriteLog ${LINENO} ""  
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnWriteLog ${LINENO} " display the subtask text       "  
    fnWriteLog ${LINENO} " calling function 'fnTaskSubText'      "               
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnWriteLog ${LINENO} ""  
    #
    fnTaskSubText
    #
    #
    #
    ##########################################################################
    #
    #
    # drop the schema if exists
    #
    fnWriteLog ${LINENO} ""  
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnWriteLog ${LINENO} " drop the schema if exists    "
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnWriteLog ${LINENO} ""  
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
    --command="DROP SCHEMA IF EXISTS "$query_schema_list_filtered_date_line" CASCADE;" 
    2>&1 )"
    #
    # check for command error(s)
    if [ "$?" -eq 3 ]
        then
            #
            # set the command/pipeline error line number
            error_line_psql="$((${LINENO}-7))"
            #
            #
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "value of variable 'query_schema_drop':"
            fnWriteLog ${LINENO} level_0 "$query_schema_drop"
            fnWriteLog ${LINENO} level_0 ""
            # call the command / pipeline error function
            fnErrorPsql
            #
    #
    fi
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "value of variable 'query_schema_drop': "
    feed_write_log="$(echo "$query_schema_drop"  2>&1)"
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""  
    #   
    #
    ##########################################################################
    #
    #
    # increment the schema counter
    # calling function: 'fnCounterIncrementSchema'
    #
    fnWriteLog ${LINENO} ""  
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnWriteLog ${LINENO} "increment the AWS schema counter "               
    fnWriteLog ${LINENO} "calling function: 'fnCounterIncrementSchema' "
    fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
    fnWriteLog ${LINENO} ""  
    #                  
    fnCounterIncrementSchema
    #
    fnWriteLog ${LINENO} "value of variable 'counter_schema': "$counter_schema" "
    fnWriteLog ${LINENO} "value of variable 'count_schema': "$count_schema" "
    fnWriteLog ${LINENO} ""
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------------------------  "          
    fnWriteLog ${LINENO} "--------------------------- loop tail read: '"$this_path_temp"/query_schema_list_filtered_date.txt' ---------------------------  "
    fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------------------------  "          
    fnWriteLog ${LINENO} ""   
    #
done< <(cat "$this_path_temp"/query_schema_list_filtered_date.txt)
#
##########################################################################
#
#
# --- end: loop read: '"$this_path_temp"/query_schema_list_filtered_date.txt'
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " end loop read: '"$this_path_temp"/query_schema_list_filtered_date.txt'   "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#  
# run for loop read
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
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
fnWriteLog ${LINENO} "------------------------------------ begin: create summary report ----------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
#                                                                                                                                                                                                                               #
##########################################################################
#
#
# display the header     
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " display the header      "  
fnWriteLog ${LINENO} " calling function 'fnHeader'      "               
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#          
fnHeader
#
##########################################################################
#
#
# Creating job summary report file
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} "Creating job summary report file "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#  
#
##########################################################################
#
#
# load the report variable: 'schemas_dropped'
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} "load the report variable: 'schemas_dropped' "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#  
schemas_dropped="$(cat "$this_path_temp"/query_schema_list_filtered_date.txt | grep -v '^$' 2>&1)"
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
        fnWriteLog ${LINENO} level_0 "value of variable 'count_schema':"
        fnWriteLog ${LINENO} level_0 "$feed_write_log"
        fnWriteLog ${LINENO} level_0 ""
        #                                                                                                
        # call the command / pipeline error function
        fnErrorPipeline
        #
#
fi  # end check for pipeline error(s)        
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'schemas_dropped': "
feed_write_log="$(echo "$schemas_dropped"  2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""  
#
#
##########################################################################
#
#
# initialize the report file and append the report lines to the file
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} "initialize the report file and append the report lines to the file "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#  
echo "">"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  AWS Services Snapshot Schema Drop Summary Report">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  Script Version: "$script_version"">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  Date: "$date_file"">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  Number of schemas dropped: "$count_schema" ">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
if [[ ("$logging" = "y") || ("$logging" = "z") ]] 
    then
        echo "  AWS Services Snapshot Schema Drop job log file: ">>"$this_summary_report_full_path"
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
# write the names of the dropped schemas to the report
fnWriteLog ${LINENO} "writing contents of variable: 'schemas_dropped' to the report " 
echo "  Schemas dropped:">>"$this_summary_report_full_path"
echo "  -----------------------------------------------------------------------">>"$this_summary_report_full_path"
#
# add leading 5 characters to match report margin
echo "$schemas_dropped" | sed -e 's/^/     /'>>"$this_summary_report_full_path"
#
#
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  -----------------------------------------------------------------------">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
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
fnWriteLog ${LINENO} "------------------------------------- end: create summary report -----------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
# 
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
#                                                                                                                                                                                                                               #
##########################################################################
#
#
# display the header     
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " display the header      "  
fnWriteLog ${LINENO} " calling function 'fnHeader'      "               
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#          
fnHeader
#
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
# display the job complete message 
#
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " display the job complete message    "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#                       
# run for job complete
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
#                                                                                                                                                                                                                               #
##########################################################################
#
#
# display the header     
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " display the header      "  
fnWriteLog ${LINENO} " calling function 'fnHeader'      "               
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
#          
fnHeader
#
#
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
if [[ ("$logging" = "y") || ("$logging" = "z") ]] 
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
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " write the stop timestamp to the log     "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
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
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " write the log file      "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
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
#
##########################################################################
#
#
# exit with success 
#
fnWriteLog ${LINENO} ""  
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} " exit with success     "
fnWriteLog ${LINENO} "---------------------------------------------------------------------------------------------------------"  
fnWriteLog ${LINENO} ""  
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


