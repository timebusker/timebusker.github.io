---
layout:     post
title:      Hive分析窗口函数—sum,avg,min,max
date:       2018-02-12
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Hive
    - SparkSQL
---  

#### 测试数据

```
cookie1,2015-04-10,1
cookie1,2015-04-11,5
cookie1,2015-04-12,7
cookie1,2015-04-13,3
cookie1,2015-04-14,2
cookie1,2015-04-15,4
cookie1,2015-04-16,4
cookie2,2015-04-12,7
cookie2,2015-04-13,3
cookie2,2015-04-14,2
cookie2,2015-04-15,4

# 加载数据
drop table if exists cookie1;
create table cookie1(cookieid string, createtime string, pv int) row format delimited fields terminated by ',';
load data local inpath "/home/hadoop/cookie1.txt" into table cookie1;
select * from cookie1;
```

#### SUM

```
select 
   cookieid, 
   createtime, 
   pv, 
   sum(pv) over (partition by cookieid order by createtime rows between unbounded preceding and current row) as pv1, 
   sum(pv) over (partition by cookieid order by createtime) as pv2, 
   sum(pv) over (partition by cookieid) as pv3, 
   sum(pv) over (partition by cookieid order by createtime rows between 3 preceding and current row) as pv4, 
   sum(pv) over (partition by cookieid order by createtime rows between 3 preceding and 1 following) as pv5, 
   sum(pv) over (partition by cookieid order by createtime rows between current row and unbounded following) as pv6 
from cookie1;

+-----------+-------------+-----+------+------+------+------+------+------+--+
| cookieid  | createtime  | pv  | pv1  | pv2  | pv3  | pv4  | pv5  | pv6  |
+-----------+-------------+-----+------+------+------+------+------+------+--+
| cookie1   | 2015-04-10  | 1   | 1    | 1    | 26   | 1    | 6    | 26   |
| cookie1   | 2015-04-11  | 5   | 6    | 6    | 26   | 6    | 13   | 25   |
| cookie1   | 2015-04-12  | 7   | 13   | 13   | 26   | 13   | 16   | 20   |
| cookie1   | 2015-04-13  | 3   | 16   | 16   | 26   | 16   | 18   | 13   |
| cookie1   | 2015-04-14  | 2   | 18   | 18   | 26   | 17   | 21   | 10   |
| cookie1   | 2015-04-15  | 4   | 22   | 22   | 26   | 16   | 20   | 8    |
| cookie1   | 2015-04-16  | 4   | 26   | 26   | 26   | 13   | 13   | 4    |
| cookie2   | 2015-04-12  | 7   | 7    | 7    | 16   | 7    | 10   | 16   |
| cookie2   | 2015-04-13  | 3   | 10   | 10   | 16   | 10   | 12   | 9    |
| cookie2   | 2015-04-14  | 2   | 12   | 12   | 16   | 12   | 16   | 6    |
| cookie2   | 2015-04-15  | 4   | 16   | 16   | 16   | 16   | 16   | 4    |
+-----------+-------------+-----+------+------+------+------+------+------+--+
```

- pv1: 分组内从起点到当前行的pv累积，如，11号的pv1=10号的pv+11号的pv, 12号=10号+11号+12号
- pv2: 同pv1
- pv3: 分组内(cookie1)所有的pv累加
- pv4: 分组内当前行+往前3行，如，11号=10号+11号， 12号=10号+11号+12号， 13号=10号+11号+12号+13号， 14号=11号+12号+13号+14号
- pv5: 分组内当前行+往前3行+往后1行，如，14号=11号+12号+13号+14号+15号=5+7+3+2+4=21
- pv6: 分组内当前行+往后所有行，如，13号=13号+14号+15号+16号=3+2+4+4=13，14号=14号+15号+16号=2+4+4=10

#### AVG

```
select 
   cookieid, 
   createtime, 
   round(pv,2), 
   round(avg(pv) over (partition by cookieid order by createtime rows between unbounded preceding and current row),2) as pv1, -- 默认为从起点到当前行
   round(avg(pv) over (partition by cookieid order by createtime),2) as pv2, --从起点到当前行，结果同pv1
   round(avg(pv) over (partition by cookieid),2) as pv3, --分组内所有行
   round(avg(pv) over (partition by cookieid order by createtime rows between 3 preceding and current row),2) as pv4, --当前行+往前3行
   round(avg(pv) over (partition by cookieid order by createtime rows between 3 preceding and 1 following),2) as pv5, --当前行+往前3行+往后1行
   round(avg(pv) over (partition by cookieid order by createtime rows between current row and unbounded following),2) as pv6  --当前行+往后所有行
from cookie1;

+-----------+-------------+---------------+-------+-------+-------+-------+-------+-------+--+
| cookieid  | createtime  | round(pv, 2)  |  pv1  |  pv2  |  pv3  |  pv4  |  pv5  |  pv6  |
+-----------+-------------+---------------+-------+-------+-------+-------+-------+-------+--+
| cookie1   | 2015-04-10  | 1             | 1.0   | 1.0   | 3.71  | 1.0   | 3.0   | 3.71  |
| cookie1   | 2015-04-11  | 5             | 3.0   | 3.0   | 3.71  | 3.0   | 4.33  | 4.17  |
| cookie1   | 2015-04-12  | 7             | 4.33  | 4.33  | 3.71  | 4.33  | 4.0   | 4.0   |
| cookie1   | 2015-04-13  | 3             | 4.0   | 4.0   | 3.71  | 4.0   | 3.6   | 3.25  |
| cookie1   | 2015-04-14  | 2             | 3.6   | 3.6   | 3.71  | 4.25  | 4.2   | 3.33  |
| cookie1   | 2015-04-15  | 4             | 3.67  | 3.67  | 3.71  | 4.0   | 4.0   | 4.0   |
| cookie1   | 2015-04-16  | 4             | 3.71  | 3.71  | 3.71  | 3.25  | 3.25  | 4.0   |
| cookie2   | 2015-04-12  | 7             | 7.0   | 7.0   | 4.0   | 7.0   | 5.0   | 4.0   |
| cookie2   | 2015-04-13  | 3             | 5.0   | 5.0   | 4.0   | 5.0   | 4.0   | 3.0   |
| cookie2   | 2015-04-14  | 2             | 4.0   | 4.0   | 4.0   | 4.0   | 4.0   | 3.0   |
| cookie2   | 2015-04-15  | 4             | 4.0   | 4.0   | 4.0   | 4.0   | 4.0   | 4.0   |
+-----------+-------------+---------------+-------+-------+-------+-------+-------+-------+--+
```

#### MIN

```
select 
   cookieid, 
   createtime, 
   pv, 
   min(pv) over (partition by cookieid order by createtime rows between unbounded preceding and current row) as pv1, -- 默认为从起点到当前行
   min(pv) over (partition by cookieid order by createtime) as pv2, --从起点到当前行，结果同pv1
   min(pv) over (partition by cookieid) as pv3, --分组内所有行
   min(pv) over (partition by cookieid order by createtime rows between 3 preceding and current row) as pv4, --当前行+往前3行
   min(pv) over (partition by cookieid order by createtime rows between 3 preceding and 1 following) as pv5, --当前行+往前3行+往后1行
   min(pv) over (partition by cookieid order by createtime rows between current row and unbounded following) as pv6  --当前行+往后所有行
from cookie1;

+-----------+-------------+-----+------+------+------+------+------+------+--+
| cookieid  | createtime  | pv  | pv1  | pv2  | pv3  | pv4  | pv5  | pv6  |
+-----------+-------------+-----+------+------+------+------+------+------+--+
| cookie1   | 2015-04-10  | 1   | 1    | 1    | 1    | 1    | 1    | 1    |
| cookie1   | 2015-04-11  | 5   | 1    | 1    | 1    | 1    | 1    | 2    |
| cookie1   | 2015-04-12  | 7   | 1    | 1    | 1    | 1    | 1    | 2    |
| cookie1   | 2015-04-13  | 3   | 1    | 1    | 1    | 1    | 1    | 2    |
| cookie1   | 2015-04-14  | 2   | 1    | 1    | 1    | 2    | 2    | 2    |
| cookie1   | 2015-04-15  | 4   | 1    | 1    | 1    | 2    | 2    | 4    |
| cookie1   | 2015-04-16  | 4   | 1    | 1    | 1    | 2    | 2    | 4    |
| cookie2   | 2015-04-12  | 7   | 7    | 7    | 2    | 7    | 3    | 2    |
| cookie2   | 2015-04-13  | 3   | 3    | 3    | 2    | 3    | 2    | 2    |
| cookie2   | 2015-04-14  | 2   | 2    | 2    | 2    | 2    | 2    | 2    |
| cookie2   | 2015-04-15  | 4   | 2    | 2    | 2    | 2    | 2    | 4    |
+-----------+-------------+-----+------+------+------+------+------+------+--+
```

#### MAX

````
select 
   cookieid, 
   createtime, 
   pv, 
   max(pv) over (partition by cookieid order by createtime rows between unbounded preceding and current row) as pv1, -- 默认为从起点到当前行
   max(pv) over (partition by cookieid order by createtime) as pv2, --从起点到当前行，结果同pv1
   max(pv) over (partition by cookieid) as pv3, --分组内所有行
   max(pv) over (partition by cookieid order by createtime rows between 3 preceding and current row) as pv4, --当前行+往前3行
   max(pv) over (partition by cookieid order by createtime rows between 3 preceding and 1 following) as pv5, --当前行+往前3行+往后1行
   max(pv) over (partition by cookieid order by createtime rows between current row and unbounded following) as pv6  --当前行+往后所有行
from cookie1;


+-----------+-------------+-----+------+------+------+------+------+------+--+
| cookieid  | createtime  | pv  | pv1  | pv2  | pv3  | pv4  | pv5  | pv6  |
+-----------+-------------+-----+------+------+------+------+------+------+--+
| cookie1   | 2015-04-10  | 1   | 1    | 1    | 7    | 1    | 5    | 7    |
| cookie1   | 2015-04-11  | 5   | 5    | 5    | 7    | 5    | 7    | 7    |
| cookie1   | 2015-04-12  | 7   | 7    | 7    | 7    | 7    | 7    | 7    |
| cookie1   | 2015-04-13  | 3   | 7    | 7    | 7    | 7    | 7    | 4    |
| cookie1   | 2015-04-14  | 2   | 7    | 7    | 7    | 7    | 7    | 4    |
| cookie1   | 2015-04-15  | 4   | 7    | 7    | 7    | 7    | 7    | 4    |
| cookie1   | 2015-04-16  | 4   | 7    | 7    | 7    | 4    | 4    | 4    |
| cookie2   | 2015-04-12  | 7   | 7    | 7    | 7    | 7    | 7    | 7    |
| cookie2   | 2015-04-13  | 3   | 7    | 7    | 7    | 7    | 7    | 4    |
| cookie2   | 2015-04-14  | 2   | 7    | 7    | 7    | 7    | 7    | 4    |
| cookie2   | 2015-04-15  | 4   | 7    | 7    | 7    | 7    | 7    | 4    |
+-----------+-------------+-----+------+------+------+------+------+------+--+
````
