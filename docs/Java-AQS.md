



通常使用ReentrantLock的方式：

```java
Lock lock = new ReentrantLock();
lock.lock();
try{
	.......
}finally{
	lock.unlock();
}
```



AQS的设计是使用模板方法设计模式

