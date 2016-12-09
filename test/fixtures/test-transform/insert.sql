/*-execute-*/ create table test(a integer);

/*-execute-*/ insert into test values (1);

/*-execute-*/ insert into test values (2);

/*-test = 3-*/ select sum(a) from test;

