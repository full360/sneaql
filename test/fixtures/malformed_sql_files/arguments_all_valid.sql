/*-execute-*/ select 1;

/*-execute_if :a = :a-*/ select 1;
/*-execute_if :a = 1-*/ select 1;
/*-execute_if 1 = :a-*/ select 1;
/*-execute_if :a = 'a'-*/ select 1;

/*-exit_step_if :a = :a-*/ select 1;
/*-exit_step_if :a = 1-*/ select 1;
/*-exit_step_if 1 = :a-*/ select 1;
/*-exit_step_if :a = 'a'-*/ select 1;

/*-exit_if :a = :a-*/ select 1;
/*-exit_if :a = 1-*/ select 1;
/*-exit_if 1 = :a-*/ select 1;
/*-exit_if :a = 'a'-*/ select 1;

/*-test = :a-*/ select 1;
/*-test = 1-*/ select 1;
/*-test = :a-*/ select 1;
/*-test = 'a'-*/ select 1;

/*-assign a 2-*/
/*-assign a 2.5-*/
/*-assign a :b-*/
/*-assign a 'x'-*/
/*-assign a :env_HOSTNAME-*/