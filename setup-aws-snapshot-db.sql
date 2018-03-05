/*

SQL setup script for AWS Services Snapshot utility

v0.0.1

This script sets up the PostgreSQL database 'aws_snapshot' for use by the 
AWS Services Snapshot utility


>> Note: this script must be executed using the 'ec2-user' role <<


 ------------------------------------------------------------------------------------

 MIT License
 
 Copyright (c) 2018 Enterprise Group, Ltd.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.

 ------------------------------------------------------------------------------------

*/

/* create aws_sps__commands schema */

CREATE SCHEMA IF NOT EXISTS aws_sps__commands
;



/* create driver_aws_services table */

DROP TABLE IF EXISTS aws_sps__commands.driver_aws_services
;

CREATE TABLE aws_sps__commands.driver_aws_services(
  id SERIAL PRIMARY KEY
, aws_service TEXT NOT NULL 
, execute_yn TEXT NOT NULL
, global_aws_service_yn TEXT NOT NULL
, driver_ver TEXT NOT NULL 
, driver_tested_yn TEXT NOT NULL 
, driver_all_ok_yn TEXT NOT NULL 
, aws_service_comment TEXT NOT NULL
);


/* create driver_aws_cli_commands table */

DROP TABLE IF EXISTS aws_sps__commands.driver_aws_cli_commands
;

CREATE TABLE aws_sps__commands.driver_aws_cli_commands(
  id SERIAL PRIMARY KEY
, aws_service TEXT NOT NULL 
, aws_cli_command TEXT NOT NULL 
, recursive_yn TEXT NOT NULL 
, execute_yn TEXT NOT NULL 
, test_ok_yn TEXT NOT NULL 
, command_comment TEXT NOT NULL 
);



/* create driver_aws_cli_commands_recursive table */

DROP TABLE IF EXISTS aws_sps__commands.driver_aws_cli_commands_recursive
;

CREATE TABLE aws_sps__commands.driver_aws_cli_commands_recursive(
key_id	SERIAL PRIMARY KEY
, aws_service	TEXT NOT NULL
, aws_cli_command	TEXT NOT NULL
, recursive_yn	TEXT NOT NULL
, execute_yn	TEXT NOT NULL
, command_repeated	TEXT NOT NULL
, command_recursive_table	TEXT NOT NULL
, parameter_source_aws_service	TEXT NOT NULL
, parameter_source_aws_cli_command	TEXT NOT NULL
, parameter_source_table	TEXT NOT NULL
, parameter_source_attribute	TEXT NOT NULL
, parameter_source_key	TEXT NOT NULL
, parameter_source_join_attribute	TEXT NOT NULL
, recursive_dependent_yn	TEXT NOT NULL
, parameter_multi_yn	TEXT NOT NULL
, parameter_count	TEXT NOT NULL
, paramete_source_table_multi_yn	TEXT NOT NULL
, parameter_source_table_count	TEXT NOT NULL
, command_parameter	TEXT NOT NULL
, parameter_key_hardcode_yn	TEXT
, parameter_key_hardcode_value	TEXT
, command_repeated_hardcoded_yn	TEXT
, command_repeated_hardcoded_prior	TEXT
, command_repeated_hardcoded_after	TEXT
, join_type	TEXT
, test_ok_yn	TEXT
, command_recursive_comment	TEXT
, command_recursive	TEXT
, command_recursive_header	TEXT
, command_recursive_1	TEXT
, command_recursive_2	TEXT
, command_recursive_3	TEXT
, command_recursive_4	TEXT
, command_recursive_5	TEXT
, command_recursive_6	TEXT
, command_recursive_7	TEXT
, command_recursive_8	TEXT
, parameter_01_source_table	TEXT
, parameter_02_source_table	TEXT
, parameter_03_source_table	TEXT
, parameter_04_source_table	TEXT
, parameter_05_source_table	TEXT
, parameter_06_source_table	TEXT
, parameter_07_source_table	TEXT
, parameter_08_source_table	TEXT
, parameter_01_source_key	TEXT
, parameter_02_source_key	TEXT
, parameter_03_source_key	TEXT
, parameter_04_source_key	TEXT
, parameter_05_source_key	TEXT
, parameter_06_source_key	TEXT
, parameter_07_source_key	TEXT
, parameter_08_source_key	TEXT
, command_recursive_single_query	TEXT
, command_recursive_multi_query	TEXT
, query_1_param	TEXT
, query_name	TEXT
, query_drop	TEXT
, query_create_build	TEXT
, query_create_header	TEXT
, query_create_1	TEXT
, query_create_2	TEXT
, query_create_3	TEXT
, query_create_4	TEXT
, query_create_5	TEXT
, query_create_6	TEXT
, query_create_7	TEXT
, query_create_8	TEXT
, query_create_tail	TEXT
, query_insert_build	TEXT
, query_insert_header	TEXT
, query_insert_1	TEXT
, query_insert_2	TEXT
, query_insert_3	TEXT
, query_insert_4	TEXT
, query_insert_5	TEXT
, query_insert_6	TEXT
, query_insert_7	TEXT
, query_insert_8	TEXT
, query_insert_tail	TEXT
, query_select_build	TEXT
, query_select_header	TEXT
, query_select_2	TEXT
, query_select_3	TEXT
, query_select_4	TEXT
, query_select_5	TEXT
, query_select_6	TEXT
, query_select_7	TEXT
, query_select_8	TEXT
, query_from	TEXT
, query_from_2	TEXT
, query_from_3	TEXT
, query_from_4	TEXT
, query_from_5	TEXT
, query_from_6	TEXT
, query_from_7	TEXT
, query_from_8	TEXT
, query_tail	TEXT
)
;


