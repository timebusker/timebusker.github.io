---
layout:     post
title:      Hive分析窗口函数—ntile,row_number,rank,dense_rank
date:       2018-02-13
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

#### ntile

`对数据按照规则[分组或排序]后然后再对数据分片（分堆），并返回分堆序号`

ntile(n)，用于将分组数据按照顺序切分成n片，返回当前切片值
ntile不支持rows between，比如 ntile(2) over(partition by cookieid order by createtime rows between 3 preceding and current row)
如果切片不均匀，默认增加第一个切片的分布.

```
select
  cookieid,
  createtime,
  pv,
  ntile(4) over (partition by cookieid order by createtime) as rn1,--将所有数据分成4片
  ntile(4) over (order by createtime) as rn2 --将所有数据分成4片
from cookie1 
order by cookieid,createtime;

+-----------+-------------+-----+------+------+--+
| cookieid  | createtime  | pv  | rn1  | rn2  |
+-----------+-------------+-----+------+------+--+
| cookie1   | 2015-04-10  | 1   | 1    | 1    |
| cookie1   | 2015-04-11  | 5   | 1    | 1    |
| cookie1   | 2015-04-12  | 7   | 2    | 1    |
| cookie2   | 2015-04-12  | 7   | 1    | 2    |
| cookie1   | 2015-04-13  | 3   | 2    | 2    |
| cookie2   | 2015-04-13  | 3   | 2    | 2    |
| cookie1   | 2015-04-14  | 2   | 3    | 3    |
| cookie2   | 2015-04-14  | 2   | 3    | 3    |
| cookie1   | 2015-04-15  | 4   | 3    | 3    |
| cookie2   | 2015-04-15  | 4   | 4    | 4    |
| cookie1   | 2015-04-16  | 4   | 4    | 4    |
+-----------+-------------+-----+------+------+--+
```

#### row_number

`对数据按照规则分组排序后，并返回分排序序号`

ROW_NUMBER() –从1开始，按照顺序，生成分组内记录的序列。比如，按照pv降序排列，生成分组内每天的pv名次
ROW_NUMBER() 的应用场景非常多，再比如，获取分组内排序第一的记录;

```
select
  cookieid,
  createtime,
  pv,
  row_number() over (partition by cookieid order by pv desc) as rn
from cookie1;


+-----------+-------------+-----+-----+--+
| cookieid  | createtime  | pv  | rn  |
+-----------+-------------+-----+-----+--+
| cookie1   | 2015-04-12  | 7   | 1   |
| cookie1   | 2015-04-11  | 5   | 2   |
| cookie1   | 2015-04-15  | 4   | 3   |
| cookie1   | 2015-04-16  | 4   | 4   |
| cookie1   | 2015-04-13  | 3   | 5   |
| cookie1   | 2015-04-14  | 2   | 6   |
| cookie1   | 2015-04-10  | 1   | 7   |
| cookie2   | 2015-04-12  | 7   | 1   |
| cookie2   | 2015-04-15  | 4   | 2   |
| cookie2   | 2015-04-13  | 3   | 3   |
| cookie2   | 2015-04-14  | 2   | 4   |
+-----------+-------------+-----+-----+--+
```

#### RANK/DENSE_RANK

> `row_number有所不同`

- `row_number`： 按顺序编号，不留空位
- `rank`： 按顺序编号，相同的值编相同号，留空位
- `dense_rank`： 按顺序编号，相同的值编相同的号，不留空位

- RANK() 生成数据项在分组中的排名，排名相等会在名次中留下空位
- DENSE_RANK() 生成数据项在分组中的排名，排名相等会在名次中不会留下空位

```
select
  cookieid,
  createtime,
  pv,
  rank() over (partition by cookieid order by pv desc) as rn1,
  dense_rank() over (partition by cookieid order by pv desc) as rn2,
  row_number() over (partition by cookieid order by pv desc) as rn3
from cookie1 
where cookieid='cookie1';

+-----------+-------------+-----+------+------+------+--+
| cookieid  | createtime  | pv  | rn1  | rn2  | rn3  |
+-----------+-------------+-----+------+------+------+--+
| cookie1   | 2015-04-12  | 7   | 1    | 1    | 1    |
| cookie1   | 2015-04-11  | 5   | 2    | 2    | 2    |
| cookie1   | 2015-04-15  | 4   | 3    | 3    | 3    |
| cookie1   | 2015-04-16  | 4   | 3    | 3    | 4    |
| cookie1   | 2015-04-13  | 3   | 5    | 4    | 5    |
| cookie1   | 2015-04-14  | 2   | 6    | 5    | 6    |
| cookie1   | 2015-04-10  | 1   | 7    | 6    | 7    |
+-----------+-------------+-----+------+------+------+--+
```