# Method Swizzling


Method swizzling指的是改变一个已存在的选择器对应的实现的过程，它依赖于Objectvie-C中方法的调用能够在运行时进改变——通过改变类的调度表（dispatch table）中选择器到最终函数间的映射关系。

##### +load vs. +initialize

Swizzling应该在+load方法中实现。

每个类的这两个方法会被Objective-C运行时系统自动调用，+load是在一个类最开始加载时调用，+initialize是在应用中第一次调用该类或它的实例的方式之前调用。这两个方法都是可选的，只有实现了才会被执行。

因为method swizzling会影响全局，所以减少冒险情况就很重要。+load能够保证在类初始化的时候就会被加载，这为改变系统行为提供了一些统一性。但+initialize并不能保证在什么时候被调用——事实上也有可能永远也不会被调用，例如应用程序从未直接的给该类发送消息。

##### dispatch_once

Swizzling应该在dispatch_once中实现。

还是因为swizzling会改变全局，我们需要在运行时采取所有可用的防范措施。保障原子性就是一个措施，它确保代码即使在多线程环境下也只会被执行一次。GCD中的diapatch_once就提供这些保障，它应该被当做swizzling的标准实践。

##### 选择器、方法及实现

在Objective-C中，尽管这些词经常被放在一起来描述消息传递的过程，但选择器、方法及实现分别代表运行时的不同方面。

下面是苹果Objective-C Runtime Reference文档中对它们的描述：

1.选择器（`typedef struct objc_selector *SEL`）：选择器用于表示一个方法在运行时的名字，一个方法的选择器是一个注册到（或映射到）Objective-C运行时中的C字符串，它是由编译器生成并在类加载的时候被运行时系统自动映射。
 
2.方法（`typedef struct objc_method *Method`）：一个代表类定义中一个方法的不明类型。
 
3.实现（`typedef id (*IMP)(id, SEL, ...)`）：这种数据类型是实现某个方法的函数开始位置的指针，函数使用的是基于当前CPU架构的标准C调用规约。第一个参数是指向self的指针（也就是该类的某个实例的内存空间，或者对于类方法来说，是指向元类（metaclass）的指针）。第二个参数是方法的选择器，后面跟的都是参数。
 
理解这些概念之间关系最好的方式是：一个类（`Class`）维护一张调度表（dispatch table）用于解析运行时发送的消息；调度表中的每个实体（`entry`）都是一个方法（`Method`），其中key值是一个唯一的名字——选择器（`SEL`），它对应到一个实现（`IMP`）——实际上就是指向标准C函数的指针。
 
Method Swizzling就是改变类的调度表让消息解析时从一个选择器对应到另外一个的实现，同时将原始的方法实现混淆到一个新的选择器。

##### 调用_cmd

下面这段代码看起来像是会导致一个死循环：

	- (void)xxx_viewWillAppear:(BOOL)animated { 
    
    	[self xxx_viewWillAppear:animated]; 
    
    	NSLog(@"viewWillAppear: %@", NSStringFromClass([self class])); 
	}

但其实并没有，在Swizzling的过程中，`xxx_viewWillAppear:`会被重新分配给`UIViewController`的`-viewWillAppear:`的原始实现。一个优秀程序员应有的直觉会告诉你在一个方法的实现中通过self调用当前方法自身会产生错误，但是在当前这种情况下，如果我们记住到底是怎么回事更有意义。反而，如果我们在这个方法中调用`viewWillAppear:`才会真的导致死循环，因为这个方法的实现会在运行时被swizzle到`viewWillAppear:`的选择器。

记住给swizzled方法加上前缀，这和你需要给可能产生冲突的分类方法加前缀是一个道理。

##### 注意事项

Swizzling被普遍认为是一种巫术，容易导致不可预料的行为和结果。尽管不是最安全的，但是如果你采取下面这些措施，method swizzling还是很安全的。

**1.始终调用方法的原始实现（除非你有足够的理由不这么做）**： API为输入和输出提供规约，但它里面具体的实现其实是个黑匣子，在Method Swizzling过程中不调用它原始的实现可能会破坏一些私有状态，甚至是程序的其他部分。

**2.避免冲突**：给分类方法加前缀，一定要确保不要让你代码库中其他代码（或是依赖库）在做与你相同的事。

**3.理解**：只是简单的复制粘贴swizzling代码而不去理解它是怎么运行的，这不仅非常危险，而且还浪费了学习Objective-C运行时的机会。阅读  [Objective-C Runtime Reference](https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ObjCRuntimeRef/index.html) 和 `<objc/rumtime.h> `去理解代码是怎样和为什么这样执行的，努力的用你的理解来消灭你的疑惑。

**谨慎行事**：无论我们对Foundation, UIKit或其它内建框架执行Swizzle操作抱有多大信心，请记住所有这些都可能在下一个版本中就不好使。提前做好准备，防范于未然才不至于到时候焦头烂额。


**以上内容翻译自** [Method Swizzling](http://nshipster.com/method-swizzling/)

***

##### 其它文章

**[Objective-C的hook方案（一）: Method Swizzling](http://blog.csdn.net/yiyaaixuexi/article/details/9374411)**

