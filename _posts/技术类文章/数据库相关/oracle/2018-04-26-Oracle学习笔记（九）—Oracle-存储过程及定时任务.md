---
layout:     post
title:      Oracle学习笔记（九）—Oracle-存储过程及定时任务
date:       2018-04-26
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Oracle
---


```sql
-- 函数
-- ORACLE产生UUID
CREATE OR REPLACE FUNCTION getUuid RETURN VARCHAR IS 
uuid VARCHAR(32);
BEGIN 
    uuid := lower(sys_guid());
	RETURN SUBSTR(uuid,1,8) || '-' || SUBSTR(uuid,9,4) || '-' || SUBSTR(uuid,13,4) || '-' || SUBSTR(uuid,17,4) || '-' || SUBSTR(uuid,21,12);
END;

-- #####################################################################################################################################################
-- #####################################################################################################################################################

-- 存储过程
create or replace procedure proc_combine_table AS
v_sql varchar2(4000);
receive_table_name varchar2(256);
target_table_name varchar2(256);
begin
  v_sql := 'select receive_table_name from (select receive_table_name,row_number() over(order by receive_table_name asc ) rn from tb_receive_log where receive_result =''OK'' and combile_status is null) where rn=1';
  dbms_output.put_line(v_sql);
  execute immediate v_sql into receive_table_name;
  dbms_output.put_line(receive_table_name);
  if receive_table_name is null then  
    return;
  end if;
  select regexp_replace(receive_table_name,'_[0-9]{10}$','') into target_table_name from dual where rownum<2;
  dbms_output.put_line(target_table_name);
  execute immediate 'drop table ' || target_table_name || '_bak';
  execute immediate 'alter table ' || target_table_name || ' rename to ' || target_table_name || '_bak';
  execute immediate 'alter table ' || receive_table_name || ' rename to ' || target_table_name;
  v_sql :='update tb_receive_log set combile_status=''OK'' where receive_table_name='' || receive_table_name ||''';
  dbms_output.put_line(v_sql);
  execute immediate v_sql;
end;

-- #####################################################################################################################################################
-- #####################################################################################################################################################

-- 新增定时任务
declare job_proc_combine_table number;
begin 
  sys.dbms_job.submit(
        job_proc_combine_table,--任务名称
        'proc_combine_table;',--执行存储过程名称,切记，必须加分号
        sysdate,--执行时间
        'sysdate+1/(24*12)');--每五分钟执行一次
  commit;
end;

-- 查看job详细信息，主要插叙ID进行启动任务
select * from user_jobs 
-- 执行JOB
begin
    dbms_job.run(21);
end;

-- 停止JOB
begin
    dbms_job.broken(21,true,sysdate);
end;

-- 删除JOB
begin
    dbms_job.remove(21);
end;

```