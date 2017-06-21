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

