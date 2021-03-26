# Java8一些不常用的方法



### List如何转TreeMap

```java
TreeMap<Long, List<Chat>> chatDateMap = groupChatRecordList.stream()
        .collect(Collectors.groupingBy(chat -> chat.getCreateTime().toLocalDate().toEpochDay(), TreeMap::new, Collectors.toList()));
```



#### Map中get元素，如果没有就new一个放入

```java
Map<Long, WxFriendCollectionGroupDataInfo> groupDateMap = resultMap.computeIfAbsent(group.getId(), k -> new HashMap<>());
groupDateMap是resultMap元素
```

