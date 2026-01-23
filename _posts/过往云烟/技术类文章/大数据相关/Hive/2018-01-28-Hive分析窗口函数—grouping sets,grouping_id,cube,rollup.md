---
layout:     post
title:      Hive分析窗口函数—grouping sets,grouping_id,cube,rollup
date:       2018-02-16
author:     timebusker
header-img: img/home-bg.jpg
catalog: true
tags:
    - Hive
    - SparkSQL
---  

#### 数据准备

```
2015-03,2015-03-10,cookie1
2015-03,2015-03-10,cookie5
2015-03,2015-03-12,cookie7
2015-04,2015-04-12,cookie3
2015-04,2015-04-13,cookie2
2015-04,2015-04-13,cookie4
2015-04,2015-04-16,cookie4
2015-03,2015-03-10,cookie2
2015-03,2015-03-10,cookie3
2015-04,2015-04-12,cookie5
2015-04,2015-04-13,cookie6
2015-04,2015-04-15,cookie3
2015-04,2015-04-15,cookie2
2015-04,2015-04-16,cookie1


create table cookie3(month string, day string, cookieid string) row format delimited fields terminated by ',';
load data local inpath "/root/data/cookie3" into table cookie3;
select * from cookie3;
```

#### grouping sets/grouping__id

> 同时对多个维度进行分组计算

在一个`group by`查询中，根据不同的维度组合进行聚合，等价于将不同维度的`group by`结果集进行`union all`。

`grouping__id`，表示结果属于哪一个分组集合。

```
select 
  month,
  day,
  count(distinct cookieid) as uv,
  grouping__id
from cookie3
group by month,day 
grouping sets (month,day) 
order by grouping__id;

# 等价于

select month,null,count(distinct cookieid) as uv,1 as grouping__id from cookie3 group by month 
union all 
select null,day,count(distinct cookieid) as uv,2 as grouping__id from cookie3 group by day


+----------+-------------+-----+---------------+--+
|  month   |    NULL     | uv  | GROUPING__ID  |
+----------+-------------+-----+---------------+--+
| 2015-04  | NULL        | 6   | 1             |
| 2015-03  | NULL        | 5   | 1             |
| NULL     | 2015-04-12  | 2   | 2             |
| NULL     | 2015-04-13  | 3   | 2             |
| NULL     | 2015-03-10  | 4   | 2             |
| NULL     | 2015-04-16  | 2   | 2             |
| NULL     | 2015-04-15  | 2   | 2             |
| NULL     | 2015-03-12  | 1   | 2             |
+----------+-------------+-----+---------------+--+
```

```
select  month, day,
count(distinct cookieid) as uv,
grouping__id 
from cookie3 
group by month,day 
grouping sets (month,day,(month,day)) 
order by grouping__id;

# 等价于

select month,null,count(distinct cookieid) as uv,1 as grouping__id from cookie3 group by month 
union all 
select null,day,count(distinct cookieid) as uv,2 as grouping__id from cookie3 group by day
union all 
select month,day,count(distinct cookieid) as uv,3 as grouping__id from cookie3 group by month,day


+----------+-------------+-----+---------------+--+
|  month   |     day     | uv  | grouping__id  |
+----------+-------------+-----+---------------+--+
| 2015-04  | 2015-04-13  | 3   | 0             |
| 2015-03  | 2015-03-12  | 1   | 0             |
| 2015-03  | 2015-03-10  | 4   | 0             |
| 2015-04  | 2015-04-15  | 2   | 0             |
| 2015-04  | 2015-04-12  | 2   | 0             |
| 2015-04  | 2015-04-16  | 2   | 0             |
| 2015-04  | NULL        | 6   | 1             |
| 2015-03  | NULL        | 5   | 1             |
| NULL     | 2015-03-10  | 4   | 2             |
| NULL     | 2015-04-13  | 3   | 2             |
| NULL     | 2015-04-15  | 2   | 2             |
| NULL     | 2015-03-12  | 1   | 2             |
| NULL     | 2015-04-12  | 2   | 2             |
| NULL     | 2015-04-16  | 2   | 2             |
+----------+-------------+-----+---------------+--+
```

#### cube

> 根据`GROUP BY`的维度的所有组合进行聚合

```
select month, day,
count(distinct cookieid) as uv,
grouping__id 
from cookie3 
group by month,day 
with cube order by grouping__id;

# 等价于

select null,null,count(distinct cookieid) as uv,0 as grouping__id from cookie3
union all 
select month,null,count(distinct cookieid) as uv,1 as grouping__id from cookie3 group by month 
union all 
select null,day,count(distinct cookieid) as uv,2 as grouping__id from cookie3 group by day
union all 
select month,day,count(distinct cookieid) as uv,3 as grouping__id from cookie3 group by month,day;


+----------+-------------+-----+---------------+--+
|   NULL   |    NULL     | uv  | grouping__id  |
+----------+-------------+-----+---------------+--+
| NULL     | NULL        | 7   | 0             |
| 2015-03  | NULL        | 5   | 1             |
| 2015-04  | NULL        | 6   | 1             |
| NULL     | 2015-04-13  | 3   | 2             |
| NULL     | 2015-04-12  | 2   | 2             |
| NULL     | 2015-03-10  | 4   | 2             |
| NULL     | 2015-04-15  | 2   | 2             |
| NULL     | 2015-03-12  | 1   | 2             |
| NULL     | 2015-04-16  | 2   | 2             |
| 2015-04  | 2015-04-16  | 2   | 3             |
| 2015-03  | 2015-03-10  | 4   | 3             |
| 2015-03  | 2015-03-12  | 1   | 3             |
| 2015-04  | 2015-04-13  | 3   | 3             |
| 2015-04  | 2015-04-15  | 2   | 3             |
| 2015-04  | 2015-04-12  | 2   | 3             |
+----------+-------------+-----+---------------+--+
```

#### rollup
rollup是cube的子集，以最左侧的维度为主，从该维度进行层级聚合

```
# 以month维度进行层级聚合
SELECT month, day, COUNT(DISTINCT cookieid) AS uv, GROUPING__ID FROM cookie3 
GROUP BY month,day WITH ROLLUP ORDER BY GROUPING__ID;

+----------+-------------+-----+---------------+--+
|  month   |     day     | uv  | grouping__id  |
+----------+-------------+-----+---------------+--+
| 2015-04  | 2015-04-13  | 3   | 0             |
| 2015-04  | 2015-04-16  | 2   | 0             |
| 2015-03  | 2015-03-12  | 1   | 0             |
| 2015-03  | 2015-03-10  | 4   | 0             |
| 2015-04  | 2015-04-15  | 2   | 0             |
| 2015-04  | 2015-04-12  | 2   | 0             |
| 2015-04  | NULL        | 6   | 1             |
| 2015-03  | NULL        | 5   | 1             |
| NULL     | NULL        | 7   | 3             |
+----------+-------------+-----+---------------+--+
```

```
# 以day维度进行层级聚合
SELECT month, day, COUNT(DISTINCT cookieid) AS uv, GROUPING__ID FROM cookie3 
GROUP BY day,month WITH ROLLUP ORDER BY GROUPING__ID;

+----------+-------------+-----+---------------+--+
|  month   |     day     | uv  | grouping__id  |
+----------+-------------+-----+---------------+--+
| 2015-03  | 2015-03-10  | 4   | 0             |
| 2015-04  | 2015-04-15  | 2   | 0             |
| 2015-04  | 2015-04-12  | 2   | 0             |
| 2015-04  | 2015-04-13  | 3   | 0             |
| 2015-03  | 2015-03-12  | 1   | 0             |
| 2015-04  | 2015-04-16  | 2   | 0             |
| NULL     | 2015-04-13  | 3   | 1             |
| NULL     | 2015-03-10  | 4   | 1             |
| NULL     | 2015-04-16  | 2   | 1             |
| NULL     | 2015-04-12  | 2   | 1             |
| NULL     | 2015-04-15  | 2   | 1             |
| NULL     | 2015-03-12  | 1   | 1             |
| NULL     | NULL        | 7   | 3             |
+----------+-------------+-----+---------------+--+
```