##################################################################################
##                                                                               #
##                                 ==**商会相关**==                              #
##                                                                               #
##################################################################################
###商会信息表
#create table tbl_cofc
#(
#	c_uId				bigint unsigned		not null auto_increment,	##商会id
#	c_sName				varchar(100) collate utf8_unicode_ci not null,					##商会名字
#	c_dtCreateTime		datetime			not null,					##商会创建时间
#	c_uLevel			int unsigned		not null default 1,			##商会等级
#	c_uMoney			bigint unsigned		not null default 0,			##商会资金
#	c_sPurpose			varchar(600)		not null default '',		##商会宗旨
#	c_nStockSum			int unsigned		not null default 0,			##该商会的股票总数
#	tc_nTechId      int unsigned    not null  default 0,    #科技代号(当前科研项目)；为0时没有科研项目
#	primary key(c_uId),
#	unique key(c_sName)
#)engine=innodb;
#
###商会人气表，以日为分类存贮
#create table tbl_day_popular_cofc
#(
#	c_uId				bigint unsigned		not null,					##商会id
#	dpc_uYear			smallint unsigned	not null,					##年
#	dpc_uDayOfYear		smallint unsigned	not null,					##该年中的天数，通过dayofyear()获取
#	dpc_uWeekOfYear		smallint unsigned	not null,					##该日在该年中的星期数，通过weekofyear()获取
#	dpc_uPopular		bigint				not null default 0,			##商会的人气值
#	primary key(c_uId, dpc_uYear, dpc_uDayOfYear),
#	foreign	key(c_uId)		references tbl_cofc(c_uId) on update cascade on delete cascade
#)engine=innodb;
#
###商会人员表
#create table tbl_member_cofc
#( 
#	cs_uId				bigint unsigned		not null,					##成员的角色id
#	c_uId				bigint unsigned		not null,					##商会id
#	mc_uPosition		varchar(96)			not null,					##在商会中的职位
#	mc_uProffer			tinyint unsigned	not null default 0,			##帮贡
#	mc_dtJoinTime		datetime			not null,					##加入时间
#	primary key(cs_uId),
#	foreign	key (cs_uId)	references tbl_char_static(cs_uId) on update cascade on delete cascade,
#	foreign	key(c_uId)		references tbl_cofc(c_uId) on update cascade on delete cascade
#)engine=innodb;
#
###商会日志信息表
#create table tbl_log_cofc
#( 
#	lc_uId				bigint unsigned		not null auto_increment,	##日志id
#	c_uId				bigint unsigned		not null,					##商会id
#	lc_sContent			varchar(300)		not null,					##日志内容
#	lc_Type				tinyint unsigned	not null,					##日志类别
#	lc_dtCreateTime		datetime			not null,					##时间
#	primary key(lc_uId),
#	foreign	key(c_uId)	references tbl_cofc(c_uId) on update cascade on delete cascade
#)engine=innodb;
#
###申请信息表
#create table tbl_request_cofc
#(
#	cs_uId				bigint unsigned		not null,					##申请者id
#	c_uId				bigint unsigned		not null,					##商会id
#	rc_uRecomId		bigint unsigned  not null,				##引荐者id
#	rc_dtRequestTime	datetime			not null,					##发出申请的时间
#	rc_sExtraInfo		varchar(300)		not null,					##附加的请求信息
#	primary key(cs_uId,c_uId),
#	foreign	key(cs_uId)			references tbl_char_static(cs_uId) on update cascade on delete cascade,
#	foreign	key(rc_uRecomId)	references tbl_char_static(cs_uId) on update cascade on delete cascade,
#	foreign	key(c_uId)			references tbl_cofc(c_uId) on update cascade on delete cascade
#)engine=innodb;
#
#
###成员退出商会信息表
#create table tbl_leave_cofc
#(
#	cs_uId				bigint unsigned		not null,					##退出者id
#	lc_dtQuitTime		datetime			not null,					##退出商会时间
#	foreign	key (cs_uId)		references tbl_char_static(cs_uId) on update cascade on delete cascade
#)engine=innodb;
#
##################################################################################
##                                    股票相关                                   #
##################################################################################
###股票持有表
#create table tbl_stock_have_cofc
#(
#	c_uId				bigint unsigned		not null,					##股票的代码（商会的id）
#	cs_uId				bigint unsigned		not null default 0,			##股票所有者id
#	
#	shc_uId				bigint unsigned		not null auto_increment,	##记录的流水号
#	shc_uNumber			int unsigned		not null,					##持有的股票数量
#	shc_uPrice			bigint unsigned		not null default 0,			##购入价格的100倍�
#	shc_dtTradeTime		datetime			not null,					##购入日期
#	
#	primary key(shc_uId),
#	foreign key(c_uId)			references tbl_cofc(c_uId) on update cascade on delete cascade,
#	foreign key(cs_uId)			references tbl_char_static(cs_uId) on update cascade on delete cascade
#)engine=innodb;
#
###股票交易历史表
#create table tbl_stock_exchange_cofc
#(
#	c_uId				bigint unsigned		not null,					##股票的代码（商会的id）
#	sec_uId				bigint unsigned		not null auto_increment,	##记录的流水号
#	
#	sec_uFromId			bigint unsigned		not null,					##股票流动的起始方id，若为0表示商会本身
#	sec_uToId			bigint unsigned		not null,					##股票流动的终结方id，若为0表示商会本身
#	
#	sec_dtTraceTime		datetime			not null,					##交易时间戳
#	sec_nNumber			bigint unsigned		not null,					##交易额
#	sec_nPrice			bigint unsigned		not null,					##交易价格的100倍
#	
#	primary key(sec_uId),
#	foreign key(c_uId)			references tbl_cofc(c_uId) on update cascade on delete cascade
#)engine=innodb;
#
###股票交易统计历史（完全是对表tbl_stock_exchange_cofc间隔时间的统计值）
#create table tbl_stock_exchange_statistics_cofc
#(
#	c_uId				bigint unsigned		not null,					##股票的代码（商会的id）
#	sesc_uId			bigint unsigned		not null auto_increment,	##记录的流水号
#	sesc_dtEndTime		datetime			not null,					##统计时间段的终点时间
#	
#	sesc_nNumber		bigint unsigned		not null default 0,			##总交易量
#	sesc_nSumPrice		bigint unsigned		not null default 0,			##总交易金额的100倍（时间段内 交易量*价格成绩 的加合）
#	sesc_nDeltaType		int unsigned		not null,					##时间间隔类型。15为15分钟，120为2h，480为8h
#	
#	primary key(sesc_uId),
#	foreign key(c_uId)			references tbl_cofc(c_uId) on update cascade on delete cascade
#)engine=innodb;
#
###股票订单表
#create table tbl_stock_order_cofc
#(
#	c_uId				bigint unsigned		not null,					##股票的代码（商会的id）
#	cs_uId				bigint unsigned,								##下单用户id
#	soc_uId				bigint unsigned		not null auto_increment,	##订单流水号
#	soc_uType			tinyint unsigned	not null,					##订单类型，0为买单，1为卖单
#	soc_dtCreateTime	datetime			not null,					##订单生成时间
#	soc_uPrice			bigint unsigned		not null,					##挂单的价格(想要买或者卖的单支股的价格)
#	soc_uCostPrice  bigint unsigned		not null default 0,	##挂卖单之前的成本价格(买单的成本价格是0)
#	soc_uNumber			bigint unsigned		not null,					##预期交易量
#	
#	primary key(soc_uId),
#	foreign key(c_uId)			references tbl_cofc(c_uId) on update cascade on delete cascade,
#	foreign key(cs_uId)			references tbl_char_static(cs_uId) on update cascade on delete cascade
#)engine=innodb;
#
###财报表
#create table tbl_stock_report_cofc
#(
#	c_uId				bigint unsigned 	not null,					##股票的代码（商会的id）
#	
#	src_uId				bigint unsigned		not null auto_increment,	##财报流水号
#	src_dtEndTime		datetime			not null,					##结算时间
#	
#	src_uLevel			int unsigned		not null,					##商会等级
#	src_uMemberNum		int unsigned		not null,					##商会成员数
#	src_uMoneyAll		bigint unsigned		not null,					##商会总资金
#	src_uMoneyIncome	bigint unsigned		not null,					##期间收入
#	src_uExchangeNum	bigint unsigned		not null,					##期间总交易量
#	src_uBonusAll		bigint unsigned		not null,					##分出的总红利
#	src_uStockNum		int					not null,					##售出的总股数
#	src_uActivePoint	bigint unsigned		not null,					##活跃度
#	
#	primary key(src_uId),
#	foreign key(c_uId)			references tbl_cofc(c_uId) on update cascade on delete cascade
#)engine=innodb;
#
###财报大股东表
#create table tbl_stock_report_shareholder_cofc
#(
#	src_uId				bigint unsigned		not null,					##财报表的流水号
#	cs_uId				bigint unsigned		not null,					##股票所有者id
#	
#	srsc_uNumber		bigint unsigned		not null,					##持有量
#	
#	primary key(src_uId, cs_uId),
#	foreign key(src_uId)	references tbl_stock_report_cofc(src_uId)	on update cascade on delete cascade,
#	foreign key(cs_uId)		references tbl_char_static(cs_uId)			on update cascade on delete cascade
#)engine=innodb;
##################################################################################
##                                    商会运输车                             #
##################################################################################
##
#create table tbl_cofc_truck
#(
#	ct_uId				bigint unsigned		not null auto_increment,	##运输车的流水号
#	ct_uCarTyp smallint unsigned	not null,			##运输车的型号 1-大型车 ；2 -中型车；3 - 小型车
#	ct_uCapacity	bigint unsigned		not null,		##运输车的当前容量
#	ct_uHP			bigint unsigned		not null,			##运输车的当前生命值
#	cs_uId				bigint unsigned		default null,		##运输车的持有者id
#	c_uId				bigint unsigned 	default null,			##运输车的持有商会代码
#	
#	primary key(ct_uId),
#	foreign key(cs_uId)	references tbl_char_static(cs_uId)	on update cascade on delete cascade,
#	foreign key(c_uId)	references tbl_cofc(c_uId)				on update cascade on delete cascade
#)engine = innodb;
##################################################################################
##                                    商会科技                                  #
##################################################################################
#create table tbl_technology_cofc
#(       
#	c_uId		 					bigint unsigned     	not null,										#商会id
#	tc_nTechId        int unsigned        	not null,                		#科技代号
#	tc_uPoint   			bigint unsigned     	not null   default 0,      	#当前点数（完成度）
#	tc_uLevel        	int unsigned        	not null   default 0,      	#当前等级
#	primary	key(c_uId,tc_nTechId),
#	foreign key(c_uId)			references tbl_cofc(c_uId) on update cascade on delete cascade
#)engine=innodb;
