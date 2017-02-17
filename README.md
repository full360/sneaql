<img src="https://raw.githubusercontent.com/full360/sneaql/master/sneaql.jpg" alt="sneaql raccoon" width="800">

# SneaQL - Sneaking Interactivity into SQL statements

SQL Markup with Command Tags

## Purpose

To enable conditional functionality in otherwise static SQL scripts in order to facilitate the following:

* Automated SQL testing
* Data integrity testing in production
* Idempotent preconditions in SQL scripts
* Simple parameterization

## Installing SneaQL

SneaQL runs on jruby, the ruby language implemented in java.  Jruby allows for the use of JDBC, which reduces the complexity in configuring database connections. 

### Installing JRuby (OSX)

The best way to install jruby on OSX is using the following applications:

* [**Homebrew**](https://brew.sh/) - a package manager for OSX
* [**rbenv**](https://github.com/rbenv/rbenv) - a ruby environment manager
* [**ruby-build**](https://github.com/rbenv/ruby-build) - an extension to rbenv which allows for easy ruby install

The following commands should be run in the terminal app, and will install all three of the above applications:

```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew install rbenv ruby-build
```

Once rbenv and ruby-build are installed... you can install and configure jruby using the following commands:

```
rbenv install jruby-9.1.5.0
rbenv global jruby-9.1.5.0
```

Please note that this will make jruby the default version of ruby for your system.  If you need to use other versions of ruby for other tasks please read up on how to use rbenv.

### Installing JRuby (Windows)

To install jruby on windows you will need to download the appropriate installer from the jruby website:

[**http://jruby.org**](http://jruby.org)


### Installing SneaQL Gem

Now that jruby is installed... installing SneaQL is easy:

```
gem install sneaql
rbenv rehash
```

## Running SneaQL from the command line

Once SneaQL is installed... running it is easy! Simply navigate to the directory containing a SneaQL transform, then run the sneaql command:

```
cd /path/to/my/transform
sneaql exec .
```

For help with the exec command parameters:

```
sneaql help exec
```

#### Connection Details

Connection details to the database can be provided one of several ways, in order of precendence

1. command line arguments 
2. environment variables
3. environment variables stored in a sneaql.env file

The required fields are listed below (command line argument / environment variable)

* **--jdbc_url/SNEAQL_JDBC_URL** - the JDBC url associated with your database instance. You can get this from your DBA
* **--db_user/SNEAQL_DB_USER** - username for database connection
* **--db_pass/SNEAQL_DB_PASS** - password for database user
* **--jdbc_driver_jar/SNEAQL_JDBC_DRIVER_JAR** - location of the JDBC driver jar file (see section below)
* **--jdbc_driver_class/SNEQAL_JDBC_DRIVER_CLASS** - class name for use with JDBC driver

#### sneaql.json

sneaql.json is required file that tells sneaql the order in which to execute the transform "steps"... where each step correlates to a SQL file.  Every transform needs to have a sneaql.json file in it's base directory.  Below is an example sneaql.json file that executes two files, silly.sql and serious.sql in that order:

```
[
  {"step_number" : 1, "step_file" : "silly.sql" },
  {"step_number" : 2, "step_file" : "serious.sql" }
]
```

#### JDBC Driver

In order to connect you will need the JDBC driver jar for your database. At this time, the following databases are supported with info on where to find the JDBC driver listed below:

* **Amazon Redshift** - [http://docs.aws.amazon.com/redshift/latest/mgmt/configure-jdbc-connection.html](http://docs.aws.amazon.com/redshift/latest/mgmt/configure-jdbc-connection.html)
* **HPE Vertica** - [https://my.vertica.com/download/vertica/client-drivers/](https://my.vertica.com/download/vertica/client-drivers/)

Note that you should always use the JDBC driver matching the version of your database.  If you have any questions or issues you should reach out to your DBA.


## Running SneaQL from JRuby

SneaQL transforms are initiated by way of the Sneaql::Transform class... which is passed a hash of parameters at initialization.

Note that the JDBC driver for your database must be initialized into the current context before you can run a transform.  Sqlite is a great option for testing because it runs with only the JDBC driver installed. 

[https://www.sqlite.org](https://www.sqlite.org)

[https://github.com/xerial/sqlite-jdbc](https://github.com/xerial/sqlite-jdbc)

Below is a simple example using sqlite:

     require 'sneaql'
     require_relative 'sqlite-jdbc-3.8.11.2.jar'
     java_import 'org.sqlite.JDBC'
     
     t = Sneaql::Transform.new(
       {  
         transform_name: 'test-transform',
         repo_base_dir: "/path/test-transform",
         repo_type: 'local', 
         database: 'sqlite', 
         jdbc_url: 'jdbc:sqlite:',
         db_user: '',
         db_pass: '',
         step_metadata_manager_type: 'local_file',
         step_metadata_file_path: "/path/test-transform/steps.json"
       }
     )

Sneaql::Transform objects provide a few attributes for understanding the outcome of the transform.

     p t.exit_code
     p t.start_time
     p t.end_time
     p t.current_step
     p t.current_statement

## Overview

SneaQL commands are embedded in special comment tags in the format /*-sneaql_command param1 param2-*/ .  These commands are associated with the SQL statement that immediately follows the tag.  Sneaql command tags appear as comments and are ingnored by the RDBMS.

Sneaql enables you with the following capabilities:

* Exiting a SQL script if a condition is met.
* Storing results of a SQL query into a variable for use in subsequent sneaql statements.
* Optionally executing (or not executing) a SQL statement based upon the evaluation of a comparison.
* Parameterizing SQL statements with the values of variables.

## Command Usage

1. Every SQL statement **must** be preceded by a sneaql command tag.
1. Command tags are comments from a SQL perspective... and can be used along side other comments and even hints!
1. A command tag governs everything following it until the next command tag is reached.
1. Some tags are not associated with SQL statements (such as exit_if).
1. Expressions can be used in tag parameter references as well as within the actual SQL statements.

## Command Tags

* Tags are enclosed by /*- and -*/ 
* Command is always lowercase and must follow the left tag without spaces **/*-command** parameter-*/

## Expressions

An expression can be one of the following:

1. a  string constant (note that it must be a single, contigious string. MyName_Here
1. an integer constant 23
1. a float constant 23.5
1. a reference to a predefined variable with the name preceded by a colon as per the dynamic SQL standard :variable_name

Expressions are always evaluated immediately before they are used (as opposed to being evaluated at the time the SQL script is loaded).

## Comparisons

Several commands take action based upon the result of a comparison between two expressions.

* Expressions are evaluated for their values immediately before the comparison
* Values are converted to the appropriate data type before comparison.
* Comparison will convert data types with the following logic applied in the order shown before the actual comparison takes place...

     if data types match... do not convert
     if either one of the data types is a float, convert both to float
     if either one of the data types is an integer, convert both to integer



## Recordsets

SneaQL provides a facility to store the results of a query in memory, to be used by other commands.  Included in the core platform are the following commands:

* **recordset** - stores the results of a SQL query as a named recorset in memory
* **iterate** - iterates through each record in a stored recordset and executes the query in the context of the record being iterated

This is very powerful feature that provides basic looping functionality.  If you are a ruby programmer, it is possible to create your own command tags to populate or utilize recordsets in many different ways.

**NOTE:**  Recordsets are stored in memory on the machine running SneaQL.  Returning large recordsets will fill up the memory on your machine and likely crash the underlying JVM!  Things you should do:

* Always put a TOP or LIMIT clause on your query to prevent unintentionally huge recordsets from being stored.
* Only select the fields you need into your recordset (SELECT * is not your friend here!)
* Increase your JVM heap size to provide some headroom.  export JRUBY_OPTS="-J-Xmx8G -J-Xss8096k"

## Example

     /*-execute-*/ 
     set session autocommit to off;
     
     /*-execute-*/ 
     set time zone to 'UTC';
     
     /*-execute-*/
     create table if not exists public.test(x integer);
     
     /*-execute first_insert-*/
     insert into public.test values (1);
     
     /*-execute_if 1 = 1-*/
     insert into public.test values (2);
     
     /*-execute-*/
     insert into public.test values (3);
     
     /*-execute-*/
     commit;
     
     /*-assign_result test_count-*/
     select count(*) from public.test;
     
     /*-exit_if :test_count = 0 -*/
     
     /*-execute-*/
     drop table if exists public.test cascade;
     
     /*-test > 0-*/
     select max(batch_id) from staging.ingestion_control;
     
     /*-assign this_var 2-*/
     
     /*-assign this_var :last_statment_rows_affected-*/
     
     /*-execute-*/
     insert into public.test values (:this_var);

## Core Commands

The core SneaQL commands are detailed in the following sections.

## Command: ASSIGN

**description:**

assign an expression value to a variable

**parameters:**

* required - variable name
* required - expression to assign

**behavior:**

* expression is assigned to variable name
* is not associated with a SQL statement

**examples:**

     /*-assign varname 2 -*/
     
     /*-assign varname :another_var_name -*/

## Command: ASSIGN_RESULT

**description:**

execute a SQL statement that returns a single value, store that value in a variable

**parameters:**

* required - variable name to store first value returned

**behavior:**

* first column of first row retrieved is assigned to variable... regardless of result set dimensions

**examples:**

     /*-assign_result public_test_count-*/
     select count(*) from public.test;

## Command: EXECUTE

**description:**

execute a SQL statement following the tag.

**parameters:**

* optional - variable name to store rows_affected

**behavior:**

* every sql_execute stores (and overwrites) 'last_statement_rows_affected' variable

**examples:**

     /*-execute-*/ 
     set session autocommit to off;
     
     /*-execute-*/ 
     set time zone to 'UTC';
     
     /*-execute-*/
     create table if not exists public.test(x integer);
     
     /*-execute first_insert-*/ --this example stores rows_affected in variable named 'first_insert'
     insert into public.test values (1);

## Command: EXECUTE_IF

**description: **

execute a SQL statement if condition is true

**parameters:**

* required - expression1
* required - conditional_operator... = != >= =< > <
* required - expression2

**behavior:**

* evaluates provided condition.  if condition is true, SQL statement is executed
* stores (and overwrites) 'last_statement_rows_affected' variable

**examples:**

     /*-execute_if :last_statement_rows_affected > 0-*/ 
     insert into public.test values (1);

## Command: EXIT_IF

**description:**

evaluate an expression... exit script if condition is true

**parameters:**

* required - expression1
* required - conditional_operator... = != >= =< > <
* required - expression2

**behavior:**

* expressions can be either a numeric literal, or a variable reference enclosed in braces
* is not associated with a SQL statement

**examples:**

     /*-exit_if :first_insert = 0 -*/
     
     /*-exit_if :first_insert > :last_statement_rows_affected -*/

## Command: EXIT_STEP_IF

**description:**

evaluate an expression... exit the current step if condition is true.  transform will continue to run starting with the next step.

**parameters:**

* required - expression1
* required - conditional_operator... = != >= =< > <
* required - expression2

**behavior:**

* expressions can be either a numeric literal, or a variable reference enclosed in braces
* is not associated with a SQL statement

**examples:**

     /*-exit_step_if :first_insert = 0 -*/
     
     /*-exit_step_if :first_insert > :last_statement_rows_affected -*/

## Command: TEST

**description:**

compare single value from SQL statement to an expression... exit script if condition evaluates to false.

**parameters:**

* required - conditional_operator... = != >= =< > <
* required - expression

**behavior:**

* single value returned from result set will be compared to expression
* expression can be either a numeric literal, or a variable reference enclosed in braces

**examples:**

     /*-test < 0-*/
     select max(batch_id) from staging.ingestion_control;
     
     /*-test < :some_other_batch_id-*/
     select max(batch_id) from staging.ingestion_control;

## Command: RECORDSET

**description:**

run a SQL query and store the results as a recordset in memory.  this recordset can be accessed and used by other commands such as the iterate command.

NOTE: large query results will fill up your local memory!  be mindful of how much data you pull by using a TOP or LIMIT clauses in your SQL query.

also note that you should not create a recordset with the same name as a session variable because this will lead to incorrect parsing.

**parameters:**

* required - recordset name

**behavior:**

* SQL query will be executed
* query results will be stored in memory as a named recordset

**examples:**

     /*-recordset rs-*/
     select a, b from table_name limit 100;

## Command: ITERATE

**description:**

iterates through every record of a named recordset that has been stored in memory.  the SQL statement in the tag will be executed once for every record in the recordset.  the fields of the current record can be accessed in the format:

:recordset.field

**parameters:**

* required - recordset name

**behavior:**

* recordset will be iterated
* query will be executed once for every record in the set
* references to record values will be evaluated before query is executed

**examples:**

     /*-iterate rs-*/
     insert into some_table(f, g) values (:rs.a, :rs.b);