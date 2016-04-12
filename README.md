#Perforce数据备份
（本文大部分内容来自Perforce官方文档）

Perforce储存的数据分两种：版本文件(versioned files)和元数据(metadata)

* 版本文件就是用户submit的文件，储存在depots目录树里
* 数据库文件储存这metadata，包括了changelist，打开（checkout）的文件，客户端workspace配置，branch映射，以及其他历史记录和文件状态之类的数据。数据库文件以`db.*`文件的形式呈现在P4根目录，每个`db.*`文件都包含一个单独的二进制数据表

##备份和恢复的基本概念
磁盘空间不足，硬件故障，以及系统崩溃都可能导致Perforce服务器文件损坏，因此应该定期备份整个P4根目录（版本文件和数据库）。

保存在depot子目录中的版本文件可以直接从备份中无损失地拷贝还原，但数据库文件这样还原则无法保证完整性，直接拷贝`db.*`文件可能导致数据库状态异常。保证其完整性的唯一方法就是用P4的checkpoint和journal文件来重建`db.*`文件：

* *checkpoint*是某一时刻数据库的快照
* *journal*是自上次快照以来，数据库更新的记录

Checkpoint文件通常比原始数据库小很多，且压缩后可以更小；而journal文件能够增长得相当大，每次生成checkpoint的时候，老的journal文件被截断并重命名，新的journal重新开始生成。此时可以把老journal文件备份到别处，以空出运行空间。

Checkpoint和journal都是格式相同的文本文件，一个checkpoint和它之后的journal文件就可以恢复P4的数据库。

**注意**！Checkpoint和journal只记录了P4的数据库，**并不**记录depot目录中的版本文件！所以进行checkpoint动作之后，必须另外单独备份depot文件！

###Checkpoint文件
Checkpoint包含了重建P4数据库元数据的所有信息，创建checkpoint的时候，P4会锁定数据库，以便保存快照。**再次提醒：从checkpoint无法恢复任何版本文件（我们的源码）**

为保证恢复后数据库的完整性，checkpoint必须比depot中的版本文件旧，或者至少一样。也就是说，备份时应该在checkpoint完全生成后，再开始备份版本文件。

###创建checkpoint
Checkpoint不会自动进行，一般可以使用如下命令：

	p4d -r server_root -jc

-jc代表journal-create，`server_root`是你的P4根目录，如果不指定，会默认使用`$P4ROOT`

生成checkpoint时，`p4d`会锁定数据库，将其内容dump到checkpoint.*n*文件中，*n*为序号。解锁数据库之前，`p4d`还会把journal文件以journal.*n-1*的文件名复制到P4ROOT目录（无论当前journal保存在哪里）然后重置当前的journal。checkpoint文件的MD5校验和会被写到checkpoint.*n*.md5文件，同时`lastCheckpointAction`计数也会相应增加。这样可以确保把最后的一个checkpoint（checkpoint.*n*）和当前journal结合起来就能够得到创建此checkpoint时数据库的完整内容。

checkpoint生成后，建议核对MD5值，随后可以把checkpoint压缩转存，MD5也妥善保存，随后备份depot文件（源码）。

要从备份中恢复，*checkpoint不能够比depot文件新*，也就是说，depot文件可以比checkpoint新，不过时间差越短越好。

###Journal文件
Journal是上次checkpoint之后记录所有数据库修改的日志，是相邻两个checkpoint的桥梁。比如我们每天晚上10点做checkpoint，周一做了checkpoint，周二晚上10点之前硬盘挂了，那么周一的checkpoint加上随后产生的journal就可以把数据库还原到周三的状态。

**警告**：这里可以看出journal的重要性，而默认情况journal是放在P4ROOT目录下的，这样如果P4根目录的文件系统挂了，journal也就没用了。所以除了定期生成并备份checkpoint，journal文件最好也写到其他文件系统去（最好是另一个物理硬盘）。可以通过修改P4JOURNAL环境变量，或者启动`p4d`时用`-J filename`参数来指定。

**注意**：还要注意，如果journal不是保存在默认路径，那么生成checkpoint时也要指定相应路径。
比如，如果服务启动命令是这样：

	$ p4d -r $P4ROOT -p 1666 -J /usr/local/perforce/journalfile
	Perforce Server starting...
	
那么checkpoint命令就得这样写：

	$ p4d -r $P4ROOT -J /usr/local/perforce/journalfile -jc
	
	Checkpointing to checkpoint.19...
	Saving journal to journal.18...
	Truncating /usr/local/perforce/journalfile...

或者直接把`/usr/local/perforce/journalfile`设置到`P4JOURNAL`环境变量里，命令就简化成：

	$ p4d -r $P4ROOT -jc
	Checkpointing to checkpoint.19...
	Saving journal to journal.18...
	Truncating /usr/local/perforce/journalfile...

###版本文件
Checkpoint和journal只能用来重建数据库，版本文件必须单独备份
####版本文件格式
版本文件保存在P4根目录下的子目录中，文本文件以[RCS格式](http://durak.org/sean/pubs/software/cvsbook/RCS-Format.html)存储，文件名为`filename,v`，每个文本文件对应一个RCS格式(,v)文件。二进制文件则完整保存在名称为`filename,d`的目录中。

Perforce在保存版本文件时已经进行了压缩

##备份脚本

备份脚本为[p4backup.sh](https://github.com/pizzanicky/Perforce-backup-scripts/blob/master/p4backup.sh)

添加到crontab，每天凌晨5:18分运行（因为verify数据完整性时会对性能有影响，特别数据比较大时，所以备份尽量放在低谷时间）：

	crontab -e

添加任务：

	18 5 * * * /opt/p4backup.sh

##参考链接
[Perforce Backup and Recovery](https://www.perforce.com/perforce/r15.2/manuals/p4sag/chapter.backup.html)

[RCS Format](http://durak.org/sean/pubs/software/cvsbook/RCS-Format.html)