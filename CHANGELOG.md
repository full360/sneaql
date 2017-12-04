#### 0.0.23

* added fail option to on_error command tag

#### 0.0.22

* transform error was not being cascaded upward after backtrace

#### 0.0.21

* fixed bug that wasn't allowing or recognizing negative numbers as command tag arguments.

#### 0.0.20

* added support for empty recordsets
* added remove_recordset command
* cleaned up on_error logging to eliminate confusion

#### 0.0.19

* updated for latest jruby

#### 0.0.18

* beefed up error backtraces and logging

#### 0.0.17

* incremented for debugging weird container issue

#### 0.0.16

* removed database manager, enabling general JDBC support
* removed features that depend upon database manager
  * lock manager
  * standard db objects
  * table based step manager
* refactoring of Transform object to reduce redundancy
* added gem version output to binary

#### 0.0.15

* on_error command tag and related changes
* refactoring of object creation in lib/sneaql.rb


#### 0.0.14

* replaced split based command tag parsing with tokenizer, allowing for string literals with whitespace and future language features
* added basic timestamp handling
* small fixes to expression logic
* added changelog :-)
* rubocop refactoring