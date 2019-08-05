# MyMuduo
从0到1实现muduo网络库

Part1: muduo_base 部分的实现

(1)Timestamp

功能：
时间戳类


知识点：

继承less_than_comparable<Timestamp>，只需实现<，其他自动实现，模板元思想
copyable：空基类，是一个标识类，继承此类表示是值类型，可以拷贝
类的内部可以访问对象的私有成员
PRId64实现了可移植打印（32位和64位统一化）需要先定义#define __STDC_FORMAT_MACROS才能使用
BOOST_STATIC_ASSERT：编译时断言

（2）AtomicIntegerT

功能：
原子操作类

知识点：

为什么要使用原子操作
	避免加锁操作（加锁消耗太大），操作系统提供了一系列原子操作，使用这些原子性操作，编译的时候需要加-march=cpu-type（直接写native）
	cmake中加-march=native

	
	CAS（Compare And Swap）
	
volatile的作用
	作为指令关键字，确保本条指令不会因编译器的优化而省略，且要求每次直接读值。简单地说就是防止编译器对代码进行优化
	当要求使用volatile 声明的变量的值的时候，系统总是重新从它所在的内存读取数据，而不是使用保存在寄存器中的备份。即使它前面的指令刚刚
	从该处读取过数据。而且读取的数据立刻被保存
	用于多线程操作，因为可能内存中的数据被其他线程修改了，若优化后从寄存器取值就不对了，所以要避免优化


（3）Types.h

功能：
定义有一个向下转型以及隐式转换的模板函数

知识点：

__gnu_cxx::__sso_string：
sso如果字符串长度超过15就会在堆上分配内存（否则在栈上），无论长短字符都是深拷贝
std::string类型的C字符都是在堆上，地址相同，修改时才会换地址（写时复制）

（4）Exception

功能：
异常类的封装

知识点：

backtrace，栈回溯，保存各个栈帧的地址
backtrace_symbols，根据地址，转成相应的函数符号
利用 abi::__cxa_demangle名字还原而不是使用C++改名的

（5）Thread

功能：
线程类的封装

知识点：

线程标识符：
	pthread_self（获得的是线程库的线程号，全局不唯一pthread_t）
	gettid（由于线程也是由进程实现的，该函数获得全局唯一线程号tid）但glibc并没有实现该函数，只能通过Linux的系统调用syscall来获取。
	
__thread关键字：
	gcc内置的线程局部存储设施，每个线程都会有一份，如果不加这个修饰，则是共享的
	__thread只能修饰POD类型
	POD类型（plain old data），与C兼容的原始数据，例如，结构和整型等C语言中的类型是 POD 类型，但带有用户定义的构造函数或虚函数的类
	则不是
	
	如果是非POD类型也想线程局部存储，可以使用封装tsd（线程特定数据）
	
boost::is_same：判断两个是否是同一类型
	
pthread_atfork：int pthread_atfork(void (*prepare)(void), void (*parent)(void), void (*child)(void));
	调用fork时，内部创建子进程前在父进程中会调用prepare，内部创建子进程成功后，父进程会调用parent ，子进程会调用child
	使用原因 因为fork可能在子线程中被调用，那么fork得到一个新进程，只有一个执行序列，只有一个线程（调用fork的线程被继承下来）所以需要
	改变名字为main（之前是线程的名字，这个新线程是这个子进程的主线程，所以要改为main）
	
	实际上，多线程最好不要混合多进程，混用容易产生死锁等问题
	父进程在创建子进程的时候，只会复制当前线程的状态，其他的线程不会复制（因此之前的子线程锁住了条件，再fork继承了死锁状态又加锁，从而
	死锁，因为子线程没有可以解锁的线程了）利用pthread_atfork可以防止这种死锁的发生，通过fork前解锁（具体看代码）父进程中再加锁
	
	
一些技巧：
	通过缓存tid，来防止每次都需要系统调用
	加上（void），防止变量在release状态未使用而报错，因为assert语句只有debug模式会执行
	
	
（5）mutex和condition

mutex

功能：
互斥锁的封装

知识点：
	RAII：资源获取即初始化，且无需自己释放
	
	MutexLockGuard类（采用RAII思想）更为常用，MutexLock 存在死锁风险（提前退出而没有解锁），而MutexLockGuard会自动调用构造析构
	
		两者关系：
	第二个类并不拥有mutex，不管理其生存期，因为是引用类型，所以这俩个类只是关联关系，没有存在聚合（整理与局部）关系 ，如果还负责对
	象的销毁，称之为组合关系
	
	第二个类不允许构造匿名对象，因为临时对象不能长时间拥有锁
	
		
	技巧：通过定义匿名对象宏来报错
	
condiotion

功能：
封装条件变量

知识点：
	CountDownLatch类是对条件变量的封装类：倒计时，到0唤醒，包含一个condition类一个mutex类
	既可以用于所有子线程等待主线程发起 “起跑” 
	也可以用于主线程等待子线程初始化完毕才开始工作
	等待wait要放在while循环里面，而不能用if来判断资源有无，否则会有假唤醒
	
	技巧：
	利用mutable修饰在常量函数里面改变成员变量
	
	ptr_vector可以自动销毁指针对象指向的成员

(6) 无界缓冲BlockinngQueue和有界缓冲BoundedBlockingQueue

功能：
生产者消费者里面存放资源使用的缓冲

知识点：
	对于无界缓冲
	利用deque来存储数据，模拟无界
	只有一个notEmpty条件变量，无需notfull条件变量，因为是无界的
	
	对于有界缓冲
	可以考虑用环形缓冲区防止拷贝，但是实际中没有使用，而是直接使用了boost的circular_buff
	利用circular_buff来存储数据，模拟有界
	需要两个条件变量来判断满了和空了


（7）ThreadPool实现

目的：
实现线程池的生产者消费者模型

知识点：
	是一个固定的线程池(由传入线程数为准)，run为向任务队列加任务，runInThread为线程队列执行的函数
	typedef boost::function<void ()> Task; 定义了一个类类型
	

（8）线程安全的Singleton

目的：
实现线程安全的单例模式类

知识点：
	保证线程安全的做法：
	pthread_once：保证一个函数只被执行一次，无锁情况保证线程安全，保证了只生成一个对象
	atexit：注册函数，程序（线程）结束时执行，在这里注册对象销毁
	typedef char T_must_be_complete_type[sizeof(T) == 0 ? -1 : 1]; 定义了一个数组类型，表示销毁的对象类型必须是
	一个complete_type，保证编译期就对不正确的类型报错。因为如果是不完全类型会导致数组的下标为-1

	
	incomplete_type：比如只声明没有定义的类，当定义他的指针，编译不会报错，利用上面的方式使得编译时这种类型时报错
	
（9） ThreadLocal<T>类

目的：
实现线程私有数据

知识点：

为什么需要线程特定数据
	在单线程程序中，我们经常要用到"全局变量"以实现多个函数间共享数据。
	在多线程环境下，由于数据空间是共享的，因此全局变量也为所有线程所共有。 
	但有时应用程序设计中有必要提供线程私有的全局变量，仅在某个线程中有效，但却可以跨多个函数访问。
	POSIX线程库通过维护一定的数据结构来解决这个问题，这个些数据称为（Thread-specific Data，或 TSD）。
	线程特定数据也称为线程本地存储TLS（Thread-local storage）
	对于POD类型的线程本地存储，可以用__thread关键字
	
	
POSIX对于TSD的封装实现（通过四个函数）

	创建key（所有线程共享）
	销毁key（所有线程销毁）
	获取线程某个指针对应的私有数据的地址（即指针值）
	设置线程某个指针对应的私有数据的地址（即指针值）
	
	一旦一个线程创建了一个key,那么所有线程都会有这个key，但是不同线程这个key指向的数据不同（堆上的），
	若要删除数据，可以在第一个函数里面设定回调来销毁堆上的数据（指针被销毁前调用）
	
	
在main线程中调用pthread_exit会起到只让main线程退出，但是保留进程资源，供其他由main创建的线程使用，直至所有线程都结束，
但在其他线程中不会有这种效果


SingletonThreadLocal（整个程序只有一个单例对象,每个线程里面的test是单独拥有）：

作用：
演示单例和singleton的结合使用（Threadlocal类里面的Test是单例的数据类型，只有一个Threadlocal类型的单例对象，
但是每个线程的Test数据有多份）


	#define STL muduo::Singleton<muduo::ThreadLocal<Test> >::instance().value()
	
	为了说明muduo::ThreadLocal<Test>只有一个单例对象，而每个线程依旧有自己的Test
	

（10） ThreadLocalSingleton<T>封装

作用：
每一个线程都一个T类的单例对象，区别SingletonThreadLocal类（实现功能一样（都是特有的TEST类，但是后者使用单例对象类来管理
），但是这一个更加自然）

知识点：
	Deleter（保存共有的指针，用于销毁所指向的线程特有的单例对象（功能和单例类的atexit一样），销毁时自动调用注册的对象销毁函数，无需自己去销毁
	）是ThreadLocalSingleton的一个嵌套类，用TSD实现，所以该类用了两种方式实现TLS（__thread和TSD）


(11) 日志的作用、级别、使用时序
作用：
	开发过程中：
	调试错误
	更好的理解程序
	运行过程中：
	诊断系统故障并处理
	记录系统运行状态
	
	Linux程序员很少使用gdb找错误，一般使用日志，编译运行还可以，逻辑错误还用gdb的话如大海捞针
	
日志级别
	TRACE
	指出比DEBUG粒度更细的一些信息事件（开发过程中使用）
	DEBUG
	指出细粒度信息事件对调试应用程序是非常有帮助的。（开发过程中使用）
	INFO
	表明消息在粗粒度级别上突出强调应用程序的运行过程。
	WARN
	系统能正常运行，但可能会出现潜在错误的情形。
	ERROR
	指出虽然发生错误事件，但仍然不影响系统的继续运行。
	FATAL
	指出每个严重的错误事件将会导致应用程序的退出。
	
	从上往下级别增大
	muduo日志级别默认INFO，低于该级别的不会输出
	
	LOG_ERROR 应用级别的错误，LOG_SYSERR 系统级别（会根据errno来判断）的错误 但两者日志级别都是ERROR
	
	输出样例：muduo::Logger(__FILE__（文件名）, __LINE__（行号）, muduo::Logger::TRACE（级别）, __func__（当前函数）)
	
	通过setoutput选择输出到特定的文件

使用时序

	Logger外层类，Impl为嵌套的实际的实现（格式化日志），借助LogStream输出，先输出到FixedBuffer缓冲区，然后通过g_output输出到文件或者标准输出的缓冲里（Log类的析构函数里实现），通过g_flush将对应缓冲输出到文件或设备(标准输入输出是行缓冲，文件是全缓冲，运行过程中无需flush,只有当出错时才需要flush)
	
	fopen文件的a选项表示追加，e选项exec函数不会被继承该文件指针


(12) 	Logger类和LogStream类封装

作用：
封装日志类

知识点：
	SIZE为非类型参数，直接传递值就行
	is_arithmetic：算术类型
	std::numeric_limits<int16_t>::min() 基值
	#pragma GCC diagnostic ignored "-Wold-style-cast" 当前忽略掉警告
	
	经测试，Logstream写缓存性能居中，对比ssprintf和streamstream

		StringPiece类：谷歌提供的，用于实现高效的字符串传递，避免了拷贝，因为是用指针（传入类型是各种，无需强制转换）
	通过宏来实现更多的运算符（还需要辅助的运算符）


		__type_traits：类型特性，利用模板的特化，实现更高的运行效率（每个类定义一些特征，模板程序中判断是否有这些特性，
	然后按着这些特征更好地编程）

(13) Logfile类的封装

作用：
实现日志滚动

知识点：
	日志滚动条件
	文件大小（例如每写满1G换下一个文件）
	时间（每天零点新建一个日志文件，不论前一个文件是否写满）
	
	一个典型的日志文件名
	logfile_test.20130411-115604.popo.7743.log

	UTC时间和GMT时间是一样的，北京时间为UTC+8
	
	basename：basename的作用是从文件名中去除目录和后缀

	多个线程对同一文件写入，效率可能不如单个线程，因为IO总线不能运行
	如果一定要多个线程写入，采用异步线程（之后会讲到）

	FILE类不是线程安全的，因为是无锁写入（提高效率）。通过LogFile类保证了线程安全
	startOfPeriod每次都会调整为零点，所以只有第二天才会有差异，当天时间调整后都为零点
	使用_r后缀的函数获取时间，保证线程安全（通过传出参数而不是返回指向一块可能被其他线程更改的缓冲区的时间）
	
	
FileUtil空间：SmallFile类应用读取小文件
	读到字符串（大小无限制）或者自己的缓冲区（大小有限制）
	pread：设置偏移读取
	cmdline就会打出本条命令
	
	pread可以从指定的偏移位置来读取文件
	
	scoped_ptr是一个类似于auto_ptr的智能指针，它包装了new操作符在堆上分配的动态对象，能够保证动态创建的对象在任何时候都可以被正确的删除。但是scoped_ptr的所有权更加严格，不能转让，一旦scoped_pstr获取了对象的管理权，你就无法再从它那里取回来。
	
	和unique_ptr的区别
	scoped_ptr是一个类似于auto_ptr的智能指针，它包装了new操作符在堆上分配的动态对象，能够保证动态创建的对象在任何时候都可以被正确的删除。但是scoped_ptr的所有权更加严格，不能转让，一旦scoped_pstr获取了对象的管理权，你就无法再从它那里取回来。 unique_ptr 独占所指向的对象, 同一时刻只能有一个 unique_ptr 指向给定对象(通过禁止拷贝语义, 只有移动语义来实现), 定义于 memory (非memory.h)中, 命名空间为 std



Part2: muduo_net 部分的实现

为什么需要网络库？
	Socket ApI不够完善，所以需要提供更改层次的封装，来降低开发难度
	
TCP网络编程本质
	TCP网络编程最本质是的处理三个半事件
	连接建立：服务器accept（被动）接受连接，客户端connect（主动）发起连接
	
	连接断开：主动断开（close、shutdown），被动断开（read返回0）
	
	消息到达：文件描述符可读（将数据从内核缓冲区移动到应用缓冲区，网络库回调注册的OnMessage检查是不是完整的包，若不是直接返回，继续循环读入缓存，若是，则应用层调用read把数据读取进行处理）
	
	消息发送完毕：这算半个。对于低流量的服务，可不必关心这个事件;这里的发送完毕是指数据写入操作系统缓冲区，将由TCP协议栈负责数据的发送与重传，不代表对方已经接收到数据。（必须把全部数据发送到内核缓冲区，若空间不够先放在应用缓冲区，若够了，内核发送发送完成事件，网络库调用OnWriteComplete函数才可以再次发送数据，以免丢包，所以适用于高流量服务）



(1) 什么都不做的EventLoop
	one loop 	per thread意思是说每个线程最多只能有一个EventLoop对象。若没有，就是非IO线程，可能是计算线程
	EventLoop对象构造的时候，会检查当前线程是否已经创建了其他EventLoop对象，如果已创建，终止程序（LOG_FATAL）
	EventLoop构造函数会记住本对象所属线程（threadId_）。
	创建了EventLoop对象的线程称为IO线程，其功能是运行事件循环（EventLoop::loop）
	
	loop只能在创建该对象的线程中被调用，会判断线程，若不是，直接退出
	
(2) Channel封装

作用：
负责注册和响应IO事件

知识点：
	它不拥有file descriptor。
	Channel是Acceptor、Connector、EventLoop（特有的那个CH）、TimerQueue、TcpConnection的成员，生命期由后者控制。
	POLLPRI：紧急事件，比如TCP带外数据
	POLLNVAL：文件描述符没有打开，或者非法fd
	POLLHUP:挂起，只在写时候出现
	POLLRDHUP:对等方关闭连接事件
	
	从poll移除关注时一定要先update为不关注事件才可以移除
	
	读回调需要一个时间戳
	
（3）定时器的选择

作用：
	定时函数，用于让程序等待一段时间或安排计划任务
	让eventloop能够处理定时器事件

知识点：
函数选择
	timerfd_* 入选的原因：
	1.sleep / alarm / usleep 在实现时有可能用了信号 SIGALRM，在多线程程序中处理信号是个相当麻烦的事情，应当尽量避免
	2.nanosleep 和 clock_nanosleep 是线程安全的，但是在非阻塞网络编程中，绝对不能用让线程挂起的方式来等待一段时间，程序会失去响应。正确的做法是注册一个时间回调函数。 
	3.getitimer 和 timer_create 也是用信号来 deliver 超时，在多线程程序中也会有麻烦。
	4.timer_create 可以指定信号的接收方是进程还是线程，算是一个进步，不过在信号处理函数(signal handler)能做的事情实在很受限。 
	5.timerfd_create 把时间变成了一个文件描述符，该“文件”在定时器超时的那一刻变得可读，这样就能很方便地融入到 select/poll 框架中，用统一的方式来处理 IO 事件和超时事件，这也正是 Reactor 模式的长处。
	
	
	多线程避免用信号
	
	若非要用信号处理，也可以用signalfd将信号转为文件描述符来处理
	
	muduo的定时器也是一次性定时，间隔性的需要多次注册（其实可以通过设置new_value的第一个参数实现间隔定时）
	
	若设置了水平触发，数据不读走的话会一直触发EPOLL（默认是EPOLL模式且为水平触发）
	
	quit函数可以跨线程调用，因为如果是其他线程，可能poll会阻塞，需要唤醒（通过添加监听管道fd，或者用eventfd）才能走到while判断
	
	bool类型quit操作本来就是原子性，所以不需要保护
	
（4） muduo定时器的实现：


作用：
muduo里面对于定时器的封装

知识点：

muduo的定时器由三个类实现，TimerId、Timer、TimerQueue，用户只能看到第一个类，其它两个都是内部实现细节
	TimerQueue的接口很简单，只有两个函数addTimer和cancel
	其实最终是通过EventLoop调用
	EventLoop
		runAt		           在某个时刻运行定时器
		runAfter		过一段时间运行定时器
		runEvery		每隔一段时间运行定时器
		cancel		           取消定时器
	TimerQueue数据结构的选择，能快速根据当前时间找到已到期的定时器，也要高效的添加和删除Timer，因而可以用二叉搜索树，用map或者set
		typedef std::pair<Timestamp, Timer*> Entry;
		typedef std::set<Entry> TimerList;
		
	
	用到的三个类：
	timer类：对定是操作一个高层次的抽象，并没有调用定时器三个函数
	通过原子操作保证定时器序号唯一
	只有一个数据成员的类用值传递效率比引用传递更高（利用寄存器），比如时间戳类
	
	TimerQueue类：定时器的管理器（一个定时器列表），定时器时间如何产生由其负责，调用那三个函数，属于一个loop
	add返回一个Timeid类，cancel参数就是timeid，不会直接调用这俩，而是调用Eventloop中的上面几个函数，EV前三个调用到addtime
	尽量用set而不是map保存，因为可能会用相同时间戳的timer，而map键值不能重复
	cancel、addtimer线程安全，可以跨线程调用
	
	TimerId类：供外部使用，用来取消定时器
	
	
	lower_bound（ele）:返回set里面第一个>=ele的位置的迭代器
	upper_bound（ele）:返回第一个>ele的位置的迭代器
	
	由于用到了entry类，所以可以用lower_bound来保证时间大于now而不是等于（将值设置为最大值）
	Entry 以键值对（key-value pair）的形式定义

	由于RVO优化，在获取到期定时器列表时不会拷贝构造
	
	linux下面有RVO优化，vs的debug模式没有优化，release模式有优化
	
	(5) 线程间事件通知机制
	
	作用：通过wakeupfd唤醒poll以处理pendingfunctor，runinloop使得IO线程可以做其他的任务，不至于一直阻塞浪费资源
	
	知识点：
	
	进程(线程)wait/notify
	pipe：f0读，f1写，是单向的
	socketpair：两个文件描述符即可读又可写，双向通信
	eventfd（muduo库所使用的）：只有一个文件描述符，等待线程和通知线程都操作这个文件描述符
	eventfd 是一个比 pipe 更高效的线程间事件通知机制，一方面它比 pipe 少用一个 file descripor，节省了资源；另一方面，eventfd 的缓冲区管理也简单得多，全部“buffer” 只有定长8 bytes，不像 pipe 那样可能有不定长的真正 buffer。
	
	线程除了以上三种，还可以用条件变量，与上面三者区别是条件变量没有文件描述符，而上面三种都有
	
	eventfd函数
	
	来自 <https://blog.csdn.net/hustfoxy/article/details/23613101> 
	
	
	
	muduo的实现
	 利用eventfd来实现线程通知，在这里的wakeupchannel和EV是组合关系，这是唯一muduo中唯一由EV负责生存期的CH
	
	 EventLoop::runInLoop（保证了在不用锁的情况线程安全，实现了线程安全的异步调用，但是最终执行任务的还是IO线程）
	在I/O线程中执行某个回调函数，该函数可以跨线程调用
	 如果是当前IO线程调用runInLoop，则同步调用cb
	如果是其它线程调用runInLoop，则异步地将cb添加到队列 因为之后执行时有swap的拷贝操作，随意使得threadid和currentid一样
	
	EventLoop::queueInLoop
	调用queueInLoop的线程不是当前IO线程需要唤醒
	 或者调用queueInLoop的线程是当前IO线程，并且此时正在调用pending functor，需要唤醒
	 只有当前IO线程的事件回调中调用queueInLoop才不需要唤醒
	
	
	doPendingFunctors();使得IO线程也能执行一些计算任务（即其他线程加进来的回调），否则当IO不是很繁忙时阻塞就浪费了资源
	
		doPendingFunctors：
	不是简单地在临界区内依次调用Functor，而是把回调列表swap到functors中，这样一方面减小了临界区的长度（意味着不会阻塞其它线程的queueInLoop()），另一方面，也避免了死锁（因为Functor可能再次调用queueInLoop()）
	由于doPendingFunctors()调用的Functor可能再次调用queueInLoop(cb)，这时，queueInLoop()就必须wakeup()，否则新增的cb可能就不能及时调用了
	muduo没有反复执行doPendingFunctors()直到pendingFunctors为空，这是有意的，否则IO线程可能陷入死循环，无法处理IO事件。
	
	（6）	EventLoopThread
	
	  作用：封装IO线程
	
		任何一个线程，只要创建并运行了EventLoop，都称之为IO线程
		IO线程不一定是主线程
	  muduo并发模型one loop per thread（IO线程池，也可以调用EL来进行一些计算任务） + threadpool（计算线程池）
	  为了方便今后使用，定义了EventLoopThread类，该类封装了IO线程
	              EventLoopThread创建了一个线程
	              在线程函数中创建了一个EvenLoop对象并调用EventLoop::loop
	
	初始化的回调函数为空，若有传入会在loop之前被调用

	
	（7）	Socket封装
	作用：封装socket相关基本操作
	
		Endian.h
		封装了字节序转换函数（全局函数，位于muduo::net::sockets名称空间中）。
		htobe64：主机字节序转网络字节序（不是POSIX标准，不可移植，而hton可以移植）
		
	SocketsOps.h/ SocketsOps.cc
		封装了socket相关系统调用（全局函数，位于muduo::net::sockets名称空间中）。
		创建、绑定、监听等
		将网际地址转换成通用地址、设置非阻塞
		readv可以将读取到的数据存放在多个缓存
		writev可以将多个缓冲区的数据发送出去
		
		宏valgrind：检测内存泄漏和文件描述符是否打开的工具
		字符型和整数型IP的转换

	Socket.h/Socket.cc（Socket类）
		用RAII方法封装socket file descriptor
		Nagle算法：充分利用缓冲区发送小文件，会延迟发送
		
		可以设置心跳、Ngale算法开启与否
		
		调用上面的函数
		
		
	InetAddress.h/InetAddress.cc（InetAddress类）
		网际地址sockaddr_in封装
		同样利用SocketsOps定义的全局函数
		
		__attribute__修饰函数表示这个函数是过时的，如果调用会警告
		

（8）Acceptor封装
	作用: Acceptor用于accept(2)接受TCP连接
	
	Acceptor的数据成员包括Socket、Channel，Acceptor的socket是listening socket（即server socket）。Channel用于观察此socket的readable事件，
	并回调Accptor::handleRead()，后者调用accept(2)来接受新连接，并回调用户callback。
	
	
	设置了一个空闲fd防止EMFILE错误


(9) TcpServer/TcpConnection封装
	封装TcpServer的原因
	Acceptor类的主要功能是socket、bind、listen
	一般来说，在上层应用程序中，我们不直接使用Acceptor，而是把它作为TcpServer的成员
	TcpServer还包含了一个TcpConnection列表
	TcpConnection与Acceptor类似，有两个重要的数据成员，Socket与Channel
	
	
	scoped_ptr与auto_ptr类似,但最大的区别就是它不能转让管理权.也就是说,scoped_ptr禁止用户进行拷贝与赋值
	get_pointer可以返回智能指针的原生指针
	
	
(10) TcpConnection生存期管理
不能直接销毁TC，否则CH跟着别销毁，而此时CH在执行handevent函数，弱销毁就会core dump，即TC的生存期要长于he函数，所以用智能指针管理TC对象

	具体办法（中间很多细节没说,下面说的引用计数不对，只是大致的一个增减过程，自己看源码）：
	连接到来时，创建一个用sp管理的TC，引用计数为1，同时在Channel中维护一个wp，将前面的sp赋值给它，此时引用计数依旧为1
	1->1
	
	当连接关闭，HE中将wp提升为sp，此时引用计数为2，erase执行，变为1，将CD加入functors中，引用计数又变为2， 此时HE返回，引用计数又剪为1，CD然后回调用户的CC（和连接的回调是同一个），完了以后引用计数变为0，TC对象销毁

	利用shared_from_this()临时对象（会导致引用计数++再--）来传递对象的SP而不是直接传this指针，这样不会导致引用计数++
	
	
	为什么TC要继承enable_shared_from_this？而不直接用this
	因为用裸指针初始化一个SP无法导致引用计数++（该新的SP引用计数将为1），从而无法达到控制生命的目的
	
	
(11) 	muduo支持多线程
	EventLoopThread（IO线程类）
	EventLoopThreadPool（IO线程池类）
	IO线程池的功能是开启若干个IO线程，并让这些IO线程处于事件循环的状态

	ptr_vector<>：当其销毁，它所管理的对象跟着销毁。
	scoped_ptr：即unique_ptr，禁止我们使用拷贝构造和赋值运算符的重载。
	
	MR关注lfd、SR关注cfd，如果没有SR，MR既需要关注lfd又需要关注cfd
	
	文件描述符的占用情况
	单线程时：
	3、4、5号fd分别被poll、timequeue、wakeupfd占用
	6被lfd占用，7被空闲fd占用，在之后就是各个新连接的fd
	
	3、7都没有关注时间，不会update
	
	多线程时：
	每个线程池都会有自己的pollfd、timerfd、wakeupfd（初始化时poll没有打印pollfd，因为还没开始）
	
(12) muduo应用层缓冲的设计
	应用层缓冲区Buffer设计
		为什么文件设置为非阻塞
		防止IO线程阻塞在read这些函数上面而影响效率
		
		为什么需要有应用层缓冲区（详见MuduoManual.pdf  P76）
		Non-blocking IO 的核心思想是避免阻塞在 read() 或 write() 或其他 IO 系统调
		用上，这样可以最大限度地复用 thread-of-control，让一个线程能服务于多个 socket
		连接。 IO 线程只能阻塞在 IO-multiplexing 函数上，如 select()/poll()/epoll_wait()。
		这样一来，应用层的缓冲是必须的，每个 TCP socket 都要有 stateful 的 input buffer
		和 output buffer。
		
		输入缓冲区需要解决黏包问题，Onmessage回调通过codec根据应用层协议判断网络库的缓冲里是不是完整数据（同时通过指针将网络库缓冲地址传回），如果不是完整，不会取走数据也不会处理，如果完整，就会取走这条消息并处理（不是网络库判断，而是上层应用来判断逻辑）
		
		Buffer结构
		muduo的buffer设计：
		Muduo Buffer 的设计考虑了常见的网络编程需求，我试图在易用性和性能之间找一个平衡点，目前这个平衡点更偏向于易用性。
		
		Muduo Buffer 的设计要点：
		• 对外表现为一块连续的内存 (char*, len)，以方便客户代码的编写。
		• 其 size() 可以自动增长，以适应不同大小的消息。它不是一个 fixed size array
		(即 char buf[8192])。
		• 内部以 vector of char 来保存数据，并提供相应的访问函数
		

		Buffer 其实像是一个 queue，从末尾写入数据，从头部读出数据。
		
		内部腾挪操作：防止pre空间太大，将两个指针前移
		
		前面预留空间的原因：方便设置字节长度来供codec使用
		
		readfd结合栈上的空间，避免内存使用过大，提高内存使用率（就是除了buffer还在栈上开辟了一块大的缓冲，这样不需要每个都分配很大的内存）
		原因：如果有5K个连接，每个连接就分配64K+64K（输入和输出）的缓冲区的话，将占用640M内存，而大多数时候，这些缓冲区的使用率很低
		
		readfd原理：一次性读尽可能多的数据（少触发EPOLLOUT事件），利用readv来实现（若接收到的数据太大，缓冲区不够放，我们再放到栈上这块很大的缓冲区，而不用一开始就开辟很大的buffer）


	epoll使用LT模式的原因
		与poll兼容
		LT模式不会发生漏掉事件的BUG，但POLLOUT事件不能一开始就关注，否则会出现busy loop，而应该在write无法完全写入内核缓冲区的时候才关注，将未写入内核缓冲区的数据添加到应用层output buffer，直到应用层output buffer写完，停止关注POLLOUT事件。
		读写的时候不必等候EAGAIN，可以节省系统调用次数，降低延迟。（注：如果用ET模式，读的时候读到EAGAIN,写的时候直到output buffer写完或者EAGAIN）
		
		所以可见LT模式（可以尽可能多读减少系统调用）效率不一定比ET要低（多了一次系统调用，检测EAGAIN）
		

(13) 	其他缓冲方案以及TcpConnection增加的部分
自己管理内存（不见得性能好于STL）

零拷贝（不是真的，内核和用户之间依旧拷贝，只是用户空间不拷贝（采用libevent2.0内存管理方案），要想真的零拷贝，除非把所有程序写内存）
存储高效但是处理代码复杂

TcpConnection中增加send
		不需要加锁因为一个线程对应一个TC，缓冲区是每个连接私有的 ，所以Buffer不需要线程安全
		
TcpConnection中shutdown的处理方法
		应用程序想关闭，但是输出缓存数据没有发完，那么不能直接调用close，关闭前需要判断缓冲区是不是有数据
		不能跨线程调用
		
		当客户端read返回0后主动关闭，服务器会收到两个事件：POLLIN、POLLHUP（这是服务器端shutdown导致的，而如果是客户端主动断开，只会返回一个POLLIN事件）
		
	
(14) 	TC完善、信号、boost：：any
TC完善
		WriteCompleteCallback含义
		大流量才需要关注（不断生成数据，然后send，若对等方接受不及时，受滑动窗口控制，导致内核发送缓存不足，这时候需要
		把数据放入应用层缓冲OB，那么很可能会撑爆OB，解决方法就是调整发送频率，即关注WriteCompleteCallback，当所有用户数据
		都拷贝到内核，才得到通知发送数据）
		
		低流量不需要关注该事件
		
		调用时机：数据发送完毕回调函数，即所有的用户数据都已拷贝到内核缓冲区时回调该函数
		 outputBuffer_被清空也会回调该函数，可以理解为低水位标回调函数
		
		HighWaterMarkCallback含义
		高水位标回调函数，用法和上面相反（会断开连接）
		
		boost::any context_
		绑定每个连接都有的一个未知类型的上下文对象，给上层应用使用，因为网络库并不知道上层要绑定啥
		
signal(SIGPIPE, SIG_IGN)
		服务器要忽略SIGPIPE
		
		应用编程和系统编程


可变类型解决方案
		void*. 这种方法不是类型安全的
		boost::any
		
		boost::any
		任意类型的类型安全存储以及安全的取回
		在标准库容器中存放不同类型的方法，比如说vector<boost::any>
		

(15) muduo库对编写tcp客户端程序的支持

		Connector	// 主动发起连接
		带有自动重连功能，back-off重连策略，即重连时间逐步增长直至一个最大时间（muduo是30秒）
		
		TcpClient	// 包含了一个Connector对象（就好比Tcpserver包含一个Acceptor用于被动连接一样）
		
		析构TC中的关闭时使用detail中的removeconnection，是因为TC中的有removeconnection有重连功能，然而不需要再重连（因为TC都已经析构了，无需再重连了）

		连接成功后需要不再关注channel的可写事件，重连时需再次关注


Part3:  muduo_http库源码分析

	（1）http request
	request line + header + body （header分为普通报头，请求报头与实体报头）
	header与body之间有一空行（CRLF）
	
	请求方法有：
	Get, Post, Head, Put, Delete等
	协议版本1.0、1.1
	
	常用请求头
	Accept：浏览器可接受的媒体（MIME）类型；
	Accept-Language：浏览器所希望的语言种类
	Accept-Encoding：浏览器能够解码的编码方法，如gzip，deflate等
	User-Agent：告诉HTTP服务器， 客户端使用的操作系统和浏览器的名称和版本
	Connection：表示是否需要持久连接，Keep-Alive表示长连接，close表示短连接
	
	
	（2）http response
	status line + header + body （header分为普通报头，响应报头与实体报头）
	header与body之间有一空行（CRLF）
	
	状态响应码
	1XX  提示信息 - 表示请求已被成功接收，继续处理
	2XX  成功 - 表示请求已被成功接收，理解，接受
	3XX  重定向 - 要完成请求必须进行更进一步的处理
	4XX  客户端错误 -  请求有语法错误或请求无法实现
	5XX  服务器端错误 -   服务器执行一个有效请求失败
	
	
	（3）muduo_http库涉及到的类
	HttpRequest：http请求类封装
	HttpResponse：http响应类封装
	HttpContext：http协议解析类
	HttpServer：http服务器类封装
	
	
	短连接不存在粘包问题，不需要传回长度信息，浏览器也能处理
	长连接需要长度信息
	
	1.0版本还不支持长连接，1.1才支持
	
	muduo设置支持http是为了查看状态，即inspect


part4: muduo_inspect库源码分析

	muduo_inspect库通过HTTP方式为服务器提供监控接口
	接受了多少个TCP连接
	当前有多少个活动连接
	一共响应了多少次请求
	每次请求的平均响应时间多少毫秒
	。。。
	
	Inspector	 // 包含了一个HttpServer对象
	ProcessInspector // 通过ProcessInfo返回进程信息
	ProcessInfo // 获取进程相关信息
	
	模块、命令、帮助、回调
	
	竞态问题：
	不能直接用start，因为构造函数还没执行完，就调用他的成员函数，是不行的，那么用runafter来执行start



Part5: muduo库使用示例
	1. 五个简单TCP协议、muduo库网络模型使用示例（数独）
		（1）五个简单TCP协议
		• discard - 丢弃所有收到的数据；
			包含一个tcpserver对象即可，然后写回调函数（关注三个半事件）
		• daytime - 服务端 accept 连接之后，以字符串形式发送当前时间，然后主动断
		开连接；
		• time - 服务端 accept 连接之后，以二进制形式发送当前时间（从 Epoch 到现在
		的秒数），然后主动断开连接；我们需要一个客户程序来把收到的时间转换为字
		符串。
			源代码有32位数溢出的问题存在，使得时间不准确，通过强转为64位整数解决该问题
			时间会早8小时，因为北京时间是UTC+8
		• echo - 回显服务，把收到的数据发回客户端；
			包含一个tcpserver对象即可，然后写回调函数
		• chargen（char genrator） - 服务端 accept 连接之后，不停地发送测试数据。
			33~126为可打印字符，每行输出72个字符（33.。。104，34.。。105，55.。。126然后又轮转回来 56.。。126，33）
			一次发送94行数据为一组，然后循环发送，每当发送一组，回调onwritecomplete再次发送数据
			由于TCP有限流功能，即使服务器发送很快，若客户端处理不快（打印出来），会使得吞吐量不高，若不打印，会很快
			
			千兆网卡发送上限  1000M/8
			
	（2）muduo库网络模型使用示例
	reactor（一个IO线程）
		IO线程负责所有工作（lfd和cfd）
	multiple reactor （多个IO线程）
		多了一行setthreadnum，导致eventloopthreadpool调用，出现多个reactor，main reactor负责lfd，sub reactor负责cfd，采用轮叫方式分配连接
	one loop per thread + thread pool （多个IO线程 + 计算线程池）
		数独既是IO密集型，又是计算密集型，那么计算过程用计算线程池来处理，防止IO线程阻塞而影响连接，处理完了再通过IO线程来发送




Part6: 基于muduo库的ABC_Bank



