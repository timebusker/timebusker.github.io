---
layout:     post
title:      Hive分析窗口函数—cume_dist,percent_rank
date:       2018-02-14
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

#### cume_dist
cume_dist：`*小于等于*当前值的行数/分组内总行数`

```
# 统计小于等于当前pv的cookieid，所占总数的比例

select 
cookieid,
pv,
cume_dist() over(order by createtime) as rn1,
cume_dist() over(partition by cookieid order by createtime) as rn2
from cookie1

# rn1:未分组，直接求比例
# rn2：先分组，再求比例
+-----------+-----+----------------------+----------------------+--+
| cookieid  | pv  |         rn1          |         rn2          |
+-----------+-----+----------------------+----------------------+--+
| cookie1   | 1   | 0.09090909090909091  | 0.14285714285714285  |
| cookie1   | 5   | 0.18181818181818182  | 0.2857142857142857   |
| cookie1   | 7   | 0.36363636363636365  | 0.42857142857142855  |
| cookie2   | 7   | 0.36363636363636365  | 0.25                 |
| cookie1   | 3   | 0.5454545454545454   | 0.5714285714285714   |
| cookie2   | 3   | 0.5454545454545454   | 0.5                  |
| cookie1   | 2   | 0.7272727272727273   | 0.7142857142857143   |
| cookie2   | 2   | 0.7272727272727273   | 0.75                 |
| cookie1   | 4   | 0.9090909090909091   | 0.8571428571428571   |
| cookie2   | 4   | 0.9090909090909091   | 1.0                  |
| cookie1   | 4   | 1.0                  | 1.0                  |
+-----------+-----+----------------------+----------------------+--+
```

#### percent_rank
percent_rank ：`分组内当前行的RANK值-1/分组内总行数-1`

```
select 
  cookieid,
  pv,
  percent_rank() over (order by pv) as rn1, --分组内
  rank() over (order by pv) as rn2, --分组内的rank值
  sum(1) over (order by pv) as rn3, --分组内总行数
  percent_rank() over (partition by cookieid order by createtime) as rn4,
  rank() over (partition by cookieid order by createtime) as rn5,
  sum(1) over (partition by cookieid order by createtime) as rn6 
from cookie1;

# 出现0.0，是rank-1导致分子为0
+-----------+-----+------+------+------+----------------------+------+------+--+
| cookieid  | pv  | rn1  | rn2  | rn3  |         rn4          | rn5  | rn6  |
+-----------+-----+------+------+------+----------------------+------+------+--+
| cookie1   | 1   | 0.0  | 1    | 1    | 0.0                  | 1    | 1    |
| cookie1   | 2   | 0.1  | 2    | 3    | 0.6666666666666666   | 5    | 5    |
| cookie2   | 2   | 0.1  | 2    | 3    | 0.6666666666666666   | 3    | 3    |
| cookie1   | 3   | 0.3  | 4    | 5    | 0.5                  | 4    | 4    |
| cookie2   | 3   | 0.3  | 4    | 5    | 0.3333333333333333   | 2    | 2    |
| cookie1   | 4   | 0.5  | 6    | 8    | 0.8333333333333334   | 6    | 6    |
| cookie1   | 4   | 0.5  | 6    | 8    | 1.0                  | 7    | 7    |
| cookie2   | 4   | 0.5  | 6    | 8    | 1.0                  | 4    | 4    |
| cookie1   | 5   | 0.8  | 9    | 9    | 0.16666666666666666  | 2    | 2    |
| cookie1   | 7   | 0.9  | 10   | 11   | 0.3333333333333333   | 3    | 3    |
| cookie2   | 7   | 0.9  | 10   | 11   | 0.0                  | 1    | 1    |
+-----------+-----+------+------+------+----------------------+------+------+--+
```