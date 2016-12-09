/*-recordset rs-*/
select a from test;

/*-iterate rs-*/
insert into test values(:rs.a);

/*-assign_result total_after_iterate-*/
select count(*) from test;