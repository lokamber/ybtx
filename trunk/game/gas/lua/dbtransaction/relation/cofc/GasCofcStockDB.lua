--
--local CCofcStock = class()
--local CCofcStockSql = CreateDbBox(...)
--
--local StmtDef = {
--	"_GetExchangeStatisticsID",
--	[[
--		-- 根据给定的交易流水号和时间间隔，拿出交易统计表对应记录的流水号
--		select t2.sesc_uId 
--		from tbl_stock_exchange_cofc as t1, tbl_stock_exchange_statistics_cofc as t2
--		where t1.sec_uId=?
--		and t2.c_uId=t1.c_uId
--		and t2.sesc_nDeltaType=? 
--		and t2.sesc_dtEndTime=timestampadd(minute, 
--			(((hour(t1.sec_dtTraceTime)*60+minute(t1.sec_dtTraceTime)) div ?)+1)*?, 
--			date(t1.sec_dtTraceTime))
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--local StmtDef = {
--	"_InsertExchangeStatistics",
--	[[
--		-- 根据给定的交易流水号和时间间隔，将新的统计信息插入到统计表
--		insert into tbl_stock_exchange_statistics_cofc
--		(c_uId, sesc_dtEndTime, sesc_nNumber, sesc_nSumPrice, sesc_nDeltaType)
--		select c_uId, 
--		timestampadd(minute, 
--		(((hour(sec_dtTraceTime)*60+minute(sec_dtTraceTime)) div ?)+1)*?, 
--		date(sec_dtTraceTime)),
--		sec_nNumber,
--		sec_nNumber*sec_nPrice,
--		?
--		from tbl_stock_exchange_cofc
--		where sec_uId=?;
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--local StmtDef = {
--	"_UpdateExchangeStatistics",
--	[[
--		-- 根据给定的交易流水号和统计流水号，将交易结果更新到统计表
--		update tbl_stock_exchange_statistics_cofc set
--		sesc_nNumber = sesc_nNumber + 
--			(select sec_nNumber from tbl_stock_exchange_cofc where sec_uId=?),
--		sesc_nSumPrice = sesc_nSumPrice + 
--			(select sec_nNumber * sec_nPrice from tbl_stock_exchange_cofc where sec_uId=?)
--		where sesc_uId = ?;
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
----- @brief 刷新股票交易记录的时间段统计值
----- @param sec_uId 交易记录表的流水号
----- @param delta_minute 间隔的时间段
----- @return 是否成功执行
--function CCofcStockSql.UpdateExchangeStatistics(sec_uId, delta_minute)
--	-- 先确认给定的交易记录是否已经在统计表中存在
--	local tbl = CCofcStock._GetExchangeStatisticsID:ExecSql("n", sec_uId, delta_minute, delta_minute, delta_minute)
--	local sesc_uId = nil
--	if tbl:GetRowNum() > 0 then
--		sesc_uId = tbl:GetData(0, 0)
--	end
--	tbl:Release()
--	-- 如果统计表中不存在，则插入新的统计记录
--	if sesc_uId == nil then
--		CCofcStock._InsertExchangeStatistics:ExecSql("", delta_minute, delta_minute, delta_minute, sec_uId)
--		if g_DbChannelMgr:LastAffectedRowNum() <= 0 then
--			CancelTran()
--			return false
--		else
--			return true
--		end
--	-- 否则刷新原来的统计记录
--	else
--		CCofcStock._UpdateExchangeStatistics:ExecSql("", sec_uId, sec_uId, sesc_uId)
--		if g_DbChannelMgr:LastAffectedRowNum() <= 0 then
--			CancelTran()
--			return false
--		else
--			return true
--		end
--	end
--end
----------------------------------------------------------------------------------------
--local StmtDef = {
--	"_AddExchangeLog",
--	[[
--		insert into tbl_stock_exchange_cofc(c_uId, sec_uFromId, sec_uToId, sec_dtTraceTime, sec_nNumber, sec_nPrice)
--		values (?, ?, ?, now(), ?, ?)
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
----- @brief 插入交易记录
--function CCofcStockSql.AddExchangeLog(cofc_id, from_id, to_id, number, price)
--	cofc_id = tonumber(cofc_id) or 0
--	from_id = tonumber(from_id) or 0
--	to_id = tonumber(to_id) or 0
--	number = tonumber(number) or 0
--	price = tonumber(price) or 0
--	if cofc_id == 0 or (from_id == 0 and to_id == 0) then
--	--	MsgToConn(Conn, 11001, "参数错误")
--		return 110017
--	end
--	if number == 0 then
--		return true
--	end
--	-- 记录插入
--	CCofcStock._AddExchangeLog:ExecSql("", cofc_id, from_id, to_id, number, price)
--	if g_DbChannelMgr:LastAffectedRowNum() <= 0 then
--		CancelTran()
--		return false
--	end
--	-- 更新时间段统计表
--	local sec_uId = g_DbChannelMgr:LastInsertId()
--	if CCofcStockSql.UpdateExchangeStatistics(sec_uId, 15) and
--		CCofcStockSql.UpdateExchangeStatistics(sec_uId, 2 * 60) and
--		CCofcStockSql.UpdateExchangeStatistics(sec_uId, 8 * 60) then
--		return true
--	else
--		return false
--	end
--end
----------------------------------------------------------------------------------------
--local StmtDef = {
--	"_GetExchangeStatistics",
--	[[
--		select unix_timestamp(sesc_dtEndTime), sesc_nNumber, sesc_nSumPrice
--		from tbl_stock_exchange_statistics_cofc
--		where sesc_dtEndTime <= now() 
--		and sesc_dtEndTime > date_add(now(), interval ? minute)
--		and sesc_nDeltaType = ?
--		and c_uId=?
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--local StmtDef = {
--	"_GetPreSpanUnixTimeStamp",
--	-- 得到当前时间向前最近的一个和给定间隔相模的时间值
--	[[
--		select unix_timestamp(date_add(date(now()), interval ((hour(now())*60+minute(now())) div ? * ?) minute))
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--local StmtDef = {
--	"_GetExchangeStatisticsAll",
--	[[
--		select unix_timestamp(sesc_dtEndTime), sum(sesc_nNumber), sum(sesc_nSumPrice)
--		from tbl_stock_exchange_statistics_cofc
--		where sesc_dtEndTime <= now() 
--		and sesc_dtEndTime > date_add(now(), interval ? minute)
--		and sesc_nDeltaType = ?
--		group by sesc_dtEndTime
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--
----- @brief 得到股票交易记录统计数据，用于客户端K线图绘制
----- @param cofc_id 股票代码（商会id），传0表示查所有商会
----- @param pre_minute 从现在开始往前的分钟数（负值）
----- @param delta_minute 统计的间隔时间（15、2*60、8*60）
----- @return 实际返回的记录条数
--function CCofcStockSql.GetExchangeStatistics(data)
--	local playerId = tonumber(data["playerId"])
--	local cofc_id = tonumber(data["cofc_id"])
--	local pre_minute = tonumber(data["pre_minute"])
--	local delta_minute = tonumber(data["delta_minute"])
--	local tbl = {}
--	if pre_minute >= 0 or 
--		(delta_minute ~= 15 and delta_minute ~= 2 * 60 and delta_minute ~= 8 * 60) then
--		return 0
--	end
--
--	-- 取得K线图数据
--	local tbl = nil
--	if cofc_id == nil or cofc_id == 0 then
--		local res = CCofcStock._GetExchangeStatisticsAll:ExecSql("nnn", pre_minute, delta_minute)
--		if nil ~= res and res:GetRowNum()>0 then
--			for i = 1,res:GetRowNum() do
--				table.insert(tbl,res:GetRow(i-1))
--			end
--		end
--	else
--		local res = CCofcStock._GetExchangeStatistics:ExecSql("nnn", pre_minute, delta_minute, cofc_id)
--		if nil ~= res and res:GetRowNum()>0 then
--			for i = 1,res:GetRowNum() do
--				table.insert(tbl,res:GetRow(i-1))
--			end
--		end
--	end
--	-- 取得起始时间点
--	local tblPreSpan= CCofcStock._GetPreSpanUnixTimeStamp:ExecSql("n", delta_minute, delta_minute)
--	local time_end = tblPreSpan:GetData(0, 0)
--	local time_begin = time_end - (- pre_minute) * 60
--	return tbl,time_begin,time_end
--end
----------------------------------------------------------------------------------------
--local StmtDef = { 
--	"_GetAllStockInfo",
--	[[
--	select 
--		tbl_cofc.c_uId as '代码', 
--		tbl_cofc.c_sName as '名称',
--		ifnull((select shc_uNumber from tbl_stock_have_cofc where cs_uId=? and c_uId=tbl_cofc.c_uId), 0) as '持有',
--		ifnull((select shc_uPrice from tbl_stock_have_cofc where cs_uId=? and c_uId=tbl_cofc.c_uId), 0) as '成本',
--		ifnull(format((today_price.price - yesterday_price.price) * 100 / yesterday_price.price, 2), "0.00") as '涨幅',
--		ifnull((select sum(sec_nNumber) from tbl_stock_exchange_cofc where sec_dtTraceTime >= date_add(now(), interval -1 day) and c_uId=tbl_cofc.c_uId), 0) as '交易量',
--		ifnull((select min(soc_uPrice) from tbl_stock_order_cofc where soc_uType=1 and c_uId=tbl_cofc.c_uId), 0) as '叫卖',
--		ifnull((select max(soc_uPrice) from tbl_stock_order_cofc where soc_uType=0 and c_uId=tbl_cofc.c_uId), 0) as '叫买',
--		ifnull((select max(sec_nPrice) from tbl_stock_exchange_cofc where sec_dtTraceTime >= date_add(now(), interval -1 day) and c_uId=tbl_cofc.c_uId), 0) as '最高',
--		ifnull((select min(sec_nPrice) from tbl_stock_exchange_cofc where sec_dtTraceTime >= date_add(now(), interval -1 day) and c_uId=tbl_cofc.c_uId), 0) as '最低'
--		from
--		-- 得到代码和名称
--		tbl_cofc left join(
--			-- 得到今天的市价
--			(select ta.c_uId as cofc_id, ta.sesc_nSumPrice / ta.sesc_nNumber as price
--				from tbl_stock_exchange_statistics_cofc as ta, 
--				-- 获取今天最后的市价的产生点
--				(select c_uId, max(sesc_dtEndTime) as end_time
--				from tbl_stock_exchange_statistics_cofc
--				where sesc_dtEndTime <= now() 
--				and sesc_nDeltaType = 15
--				group by c_uId) as tb
--				where ta.sesc_nDeltaType = 15 
--				and ta.c_uId = tb.c_uId
--				and ta.sesc_dtEndTime = tb.end_time) as today_price,
--				-- 得到昨天的市价
--				(select ta.c_uId as cofc_id, ta.sesc_nSumPrice / ta.sesc_nNumber as price
--				from tbl_stock_exchange_statistics_cofc as ta, 
--				-- 获取昨天最后的市价的产生点 
--				(select c_uId, max(sesc_dtEndTime) as end_time
--				from tbl_stock_exchange_statistics_cofc
--				where sesc_dtEndTime <= date_add(now(), interval -1 day)
--				and sesc_nDeltaType = 15
--				group by c_uId) as tb
--				where ta.sesc_nDeltaType = 15 
--				and ta.c_uId = tb.c_uId
--				and ta.sesc_dtEndTime = tb.end_time) as yesterday_price
--		)
--		on(tbl_cofc.c_uId = today_price.cofc_id
--		and tbl_cofc.c_uId = yesterday_price.cofc_id
--		)
--		order by tbl_cofc.c_uId
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
----- @brief 得到所有股票总揽信息
--function CCofcStockSql.GetCofCStockInfo(data)
--	local playerId = data["playerId"]
--	local tbl = {}
--	local res = CCofcStock._GetAllStockInfo:ExecSql("ns[32]nns[8]nnnnn", playerId, playerId)
--	if nil ~= res and res:GetRowNum()>0 then
--		for i = 1,res:GetRowNum() do
--			table.insert(tbl,res:GetRow(i-1))
--		end
--	end
--	return tbl
--end
----------------------------------------------------------------------------------------
--local StmtDef = { 
--	"_GetStockOrderList",
--	[[
--		(select 0, soc_uId, soc_uPrice, soc_uNumber from tbl_stock_order_cofc
--		where soc_uType = 0 and c_uId = ?
--		order by soc_uPrice desc, soc_uNumber desc limit 5)
--		union
--		(select 1, soc_uId, soc_uPrice, soc_uNumber from tbl_stock_order_cofc
--		where soc_uType = 1 and c_uId = ?
--		order by soc_uPrice asc, soc_uNumber desc limit 5)
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--local StmtDef = { 
--	"_GetOrderListCount",
--	[[
--		(select sum(soc_uNumber)
--		from tbl_stock_order_cofc where soc_uType = 0 and c_uId = ?)
--		union all
--		(select count(soc_uNumber) 
--		from tbl_stock_order_cofc where soc_uType = 1 and c_uId = ?)
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
----- @brief 得到股票的订单列表
--function CCofcStockSql.GetCofCStockOrderList(data)
--	local playerId = data["playerId"]
--	local cofc_id = data["cofc_id"]
--	local tbl1 = {}
--	local tbl2 = {}
--	local res1 = CCofcStock._GetStockOrderList:ExecSql("nnnn", cofc_id, cofc_id)
--	if nil ~= res1 and res1:GetRowNum()>0 then
--		for i =1 ,res1:GetRowNum() do
--			table.insert(tbl1,res1:GetRow(i-1))
--		end
--	end
--	local res2 = CCofcStock._GetOrderListCount:ExecSql("n", cofc_id, cofc_id)
--	if nil ~= res2 and res2:GetRowNum()>0 then
--		for i =1 ,res2:GetRowNum() do
--			table.insert(tbl2,res2:GetRow(i-1))
--		end
--	end
--	return tbl1,tbl2
--end
----------------------------------------------------------------------------------------
--local StmtDef = { 
--	"_GetMyStockOrderList",
--	[[
--		select 	
--			t_order.soc_uId as '订单流水号', 
--			t_order.c_uId as '代码', 
--			(select c_sName from tbl_cofc as t_c where t_c.c_uId = t_order.c_uId) as '名称',
--			t_order.soc_uNumber as '挂单数量', 
--			t_order.soc_uType as '类型', 
--			t_order.soc_uPrice as '挂单价格',
--			ifnull(format((today_price.price - yesterday_price.price) * 100 / yesterday_price.price, 2), "0.00") as '涨幅',
--			(select ifnull(min(soc_uPrice), 0) from tbl_stock_order_cofc as t_soc where soc_uType=1 and t_soc.c_uId=t_order.c_uId and t_soc.cs_uId=t_order.cs_uId) as '叫卖',
--			(select ifnull(max(soc_uPrice), 0) from tbl_stock_order_cofc as t_soc where soc_uType=0 and t_soc.c_uId=t_order.c_uId and t_soc.cs_uId=t_order.cs_uId) as '叫买',
--			ifnull(t_have.shc_uNumber, 0) as '执有', 
--			ifnull(t_have.shc_uPrice, 0) as '成本'
--			from tbl_stock_order_cofc as t_order left join(
--			tbl_stock_have_cofc as t_have,
--			-- 得到今天的市价
--		(select ta.c_uId as cofc_id, ta.sesc_nSumPrice / ta.sesc_nNumber as price
--		from tbl_stock_exchange_statistics_cofc as ta, 
--		-- 获取今天最后的市价的产生点
--		(select c_uId, max(sesc_dtEndTime) as end_time
--		from tbl_stock_exchange_statistics_cofc
--		where sesc_dtEndTime <= now() 
--		and sesc_nDeltaType = 15
--		group by c_uId) as tb
--		where ta.sesc_nDeltaType = 15 
--		and ta.c_uId = tb.c_uId
--		and ta.sesc_dtEndTime = tb.end_time) as today_price,
--		-- 得到昨天的市价
--		(select ta.c_uId as cofc_id, ta.sesc_nSumPrice / ta.sesc_nNumber as price
--		from tbl_stock_exchange_statistics_cofc as ta, 
--		-- 获取昨天最后的市价的产生点 
--		(select c_uId, max(sesc_dtEndTime) as end_time
--		from tbl_stock_exchange_statistics_cofc
--		where sesc_dtEndTime <= date_add(now(), interval -1 day)
--		and sesc_nDeltaType = 15
--		group by c_uId) as tb
--		where ta.sesc_nDeltaType = 15 
--		and ta.c_uId = tb.c_uId
--		and ta.sesc_dtEndTime = tb.end_time) as yesterday_price
--		)
--		on(t_order.c_uId = t_have.c_uId
--		and t_order.c_uId = today_price.cofc_id
--		and t_order.c_uId = yesterday_price.cofc_id)
--		where t_order.cs_uId = ?
--		and (t_have.cs_uId=t_order.cs_uId or t_have.cs_uId is null)
--		and (today_price.cofc_id = t_order.cs_uId or today_price.cofc_id is null)
--		and (yesterday_price.cofc_id = t_order.cs_uId or yesterday_price.cofc_id is null)
--		order by t_order.c_uId asc, t_order.soc_uId asc
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
----- @brief 得到我的订单信息
--function CCofcStockSql.GetCofCStockMyDealingInfo(data)
--	local playerId = data["playerId"]
--	local tbl = {}
--	local res = CCofcStock._GetMyStockOrderList:ExecSql("nns[32]nnns[8]nnnn", playerId)
--	if nil ~= res and res:GetRowNum()>0 then
--		for i = 1,res:GetRowNum() do
--			table.insert(tbl,res:GetRow(i-1))
--		end
--	end
--	return tbl
--end
----------------------------------------------------------------------------------------
--local StmtDef = { 
--	"_GetStockReport",
--	[[
--		select tsrc.src_uId,
--		tc.c_sName, tsrc.c_uId,
--		date_add(date(now()), interval -weekday(now())-8-7*? day),
--		date_add(date(now()), interval -weekday(now())-2-7*? day),
--		tsrc.src_uLevel, tsrc.src_uMoneyAll, tsrc.src_uMoneyIncome, 
--		tsrc.src_uStockNum, tsrc.src_uExchangeNum, tsrc.src_uBonusAll,
--		tsrc.src_uMemberNum, tsrc.src_uActivePoint
--		from tbl_stock_report_cofc as tsrc,
--		tbl_cofc as tc
--		where 
--		tsrc.c_uId = tc.c_uId
--		and tsrc.c_uId = ?
--		and tsrc.src_dtEndTime = date_add(date(now()), interval -weekday(now())-1-7*? day)
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--local StmtDef = { 
--	"_GetMajorShareholder",
--	[[
--		select t1.c_sName, t2.srsc_uNumber
--		from tbl_char as t1, tbl_stock_report_shareholder_cofc as t2
--		where t1.cs_uId = t2.cs_uId
--		and src_uId = ?
--		order by t2.srsc_uNumber desc
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
----得到某支股票的财务报告
--function CCofcStockSql.GetStockFinancialReport(data)
--	local playerId = data["playerId"]
--	local cofc_id = data["cofc_id"]
--	local pre_week = data["pre_week"]
--	local tbl_rpt = {}
--	local tbl_have = {}
--	local tbl_msh = nil
--	local tbl_rpt_set = CCofcStock._GetStockReport:ExecSql("ns[32]ns[32]s[32]nnnnnnnn", pre_week, pre_week, cofc_id, pre_week)
--	if nil ~= tbl_rpt_set and tbl_rpt_set:GetRowNum()>0 then
--		for i = 1,tbl_rpt_set:GetRowNum() do
--			table.insert(tbl_rpt,tbl_rpt_set:GetRow(i-1))
--		end
--	end
--	local tbl_have_set = CCofcStock._GetCofcMyHaveInfo:ExecSql("nn", playerId, cofc_id)
--	if nil ~= tbl_have_set and tbl_have_set:GetRowNum()>0 then
--		for i = 1,tbl_have_set:GetRowNum() do
--			table.insert(tbl_have,tbl_have_set:GetRow(i-1))
--		end
--	end
--	if next(tbl_rpt) then
--		tbl_msh_set = CCofcStock._GetMajorShareholder:ExecSql("s[32]n", tbl_rpt:GetData(0, 0))
--		if nil ~= tbl_msh_set and tbl_msh_set:GetRowNum()>0 then
--			for i = 1,tbl_msh_set:GetRowNum() do
--				table.insert(tbl_msh,tbl_msh_set:GetRow(i-1))
--			end
--		end
--	end
--	return tbl_have,tbl_rpt,tbl_msh
--end
----------------------------------------------------------------------------------------
--local StmtDef = { 
--	"_GetCofcMyHaveInfo",
--	[[
--		select shc_uNumber, shc_uPrice
--		from tbl_stock_have_cofc
--		where cs_uId = ? and c_uId = ?;
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
----- @brief 得到我对某支股票的持有信息
--function CCofcStockSql.GetCofcMyHaveInfo(data)
--	local playerId = data["playerId"]
--	local cofc_id = data["cofc_id"]
--	local tbl = {}
--	local res = CCofcStock._GetCofcMyHaveInfo:ExecSql("nn", playerId, cofc_id)
--	if nil ~= res and res:GetRowNum() > 0 then
--		for i = 1,res:GetRowNum() do
--			table.insert(tbl,res:GetRow(i-1))
--		end
--	end
--	return tbl
--end
----------------------------------------------------------------------------------------
--local StmtDef = { 
--	"_GetOrderList_Buy",
--	--- @brief 得到订单列表
--	[[
--		select soc_uId, soc_uPrice, soc_uNumber, cs_uId 
--		from tbl_stock_order_cofc
--		where c_uId = ? and soc_uType = 1 and soc_uPrice <= ?
--		order by soc_uPrice asc
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--
--local StmtDef = {
--	--- @brief 添加新订单
--	"_AddNewOrder",
--	[[
--		insert into tbl_stock_order_cofc
--		(soc_dtCreateTime, soc_uType, c_uId, cs_uId, soc_uPrice, soc_uNumber,soc_uCostPrice)
--		values (now(),?,?,?,?,?,?)
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--local StmtDef = {
--	"_DeleteOrderList",
--	--- @brief 删除订单
--	[[
--		delete from tbl_stock_order_cofc where soc_uId = ?
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--local StmtDef = {
--	"_ResetOrderList",
--	--- @brief 重新设置订单数额
--	[[
--		update tbl_stock_order_cofc set soc_uNumber=? where soc_uId=?
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--local StmtDef = {
--	"_SubOrderList",
--	--- @brief 减少订单数额
--	[[
--		update tbl_stock_order_cofc set soc_uNumber = soc_uNumber-? where soc_uId = ?
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--
--local StmtDef = {
--	"_GetScockHave",
--	--- @brief 得到股票的持有信息
--	[[
--		select shc_uId, shc_uNumber,shc_uPrice from tbl_stock_have_cofc where c_uId = ? and cs_uId = ?
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--local StmtDef = {
--	"_InsertScockHave",
--	--- @brief 添加对某股票的持有
--	[[
--		insert into tbl_stock_have_cofc
--		(c_uId, cs_uId, shc_uNumber, shc_uPrice, shc_dtTradeTime)
--		values(?, ?, ?, ?, now())
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--local StmtDef = {
--	"_AddScockHave",
--	--- @brief 增加对某支股票的持有量
--	[[
--		update tbl_stock_have_cofc
--		set
--		shc_uPrice=(shc_uNumber*shc_uPrice + ?*? + ?) div (shc_uNumber+?+?),
--		shc_uNumber=shc_uNumber+?
--		where shc_uId=?
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--local StmtDef = {
--	"_SubStockHave",
--	--- @brief 减少对某支股票的持有量
--	[[
--		update tbl_stock_have_cofc set shc_uNumber = shc_uNumber-? where shc_uId = ?
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--local StmtDef = {
--	"_DeleteStockHave",
--	--- @brief 删除对股票的持有
--	[[
--		delete from tbl_stock_have_cofc where shc_uId = ?
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--local StmtDef = {
--	"_AddMoneyForCofc",
--	[[
--		update tbl_cofc set c_uMoney = c_uMoney+? ,c_nStockSum = c_nStockSum - ? where c_uId=?
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--
--local StmtDef = { 
--	"_GetOrderInfoByPlayerId",
--	[[
--		select soc_uType, soc_uNumber,soc_uCostPrice
--		from tbl_stock_order_cofc
--		where c_uId = ? and cs_uId = ?
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--
---- @brief 我要买股票
---- @param playerId:	要买股票的玩家ID
---- @param cofc_id:	要买股票的股票代码
---- @param price:		买股票出的价格
---- @param number:		要买的数量
--
--function CCofcStockSql.StockBuy(data)
--	local playerId = data["playerId"]
--	local cofc_id = data["cofc_id"]
--	local price = data["price"]
--	local number = data["number"]
--	local code = {}
--	if number <= 0 or price <= 0  then --输入参数有误
--		return 110017
--	end
--	
--	-- 取得我对该股票的持有信息，若没有对其的持有，则新插入一条空的持有信息方便后边进行更新操作
--	local tbl_buy = CCofcStock._GetScockHave:ExecSql("nnn", cofc_id, playerId)
--	if tbl_buy:GetRowNum() == 0 then
--		tbl_buy:Release()
--		CCofcStock._InsertScockHave:ExecSql("", cofc_id, playerId, 0, 0)
--		if g_DbChannelMgr:LastAffectedRowNum() == 0 then
--			CancelTran()
--			return false
--		end
--		tbl_buy = CCofcStock._GetScockHave:ExecSql("nnn", cofc_id, playerId)
--		if tbl_buy:GetRowNum() == 0 then
--			return false
--		end
--	end
--	
--	local sell_num = 0
--	local sell_costprice = 0
--	--在股票订单中查询该玩家针对指定代码的股票
--	local order_list = CCofcStock._GetOrderInfoByPlayerId:ExecSql("nnn", cofc_id,playerId)
--		--在查询出来的结果集里面遍历订单列表里面的所有卖单
--	if nil ~= order_list and order_list:GetRowNum() > 0 then
--		for i = 0,order_list:GetRowNum()-1  do
--			if order_list:GetData(i,0) == 1 then
--				sell_num = sell_num + order_list:GetData(i,1)
--				sell_costprice = sell_costprice + order_list:GetData(i,1)*order_list:GetData(i,2)
--			end
--		end
--	end 
--	
--	local my_have_id = tbl_buy:GetData(0, 0) -- 我在持有表中记录的流水号
--	
--	-- 取得所有可能用到的订单列表
--	-- soc_uId, soc_uPrice, soc_uNumber, cs_uId
--	local tbl_orderList = CCofcStock._GetOrderList_Buy:ExecSql("nnnn", cofc_id, price)
--	
--	-- 遍历订单列表进行购买
--	local num =  tbl_orderList:GetRowNum() --订单数目
--	local MoneyManagerDB=	RequireDbBox("MoneyMgrDB")
--	for i = 0, num - 1 do
--		-- 原始股购买流程
--		if tbl_orderList:IsNull(i, 3) then
--			-- 计算交易量
--			-- 交易价格
--			local exchange_price = tbl_orderList:GetData(i, 1)
--			-- 卖家可售出量 = 原始股挂单量
--			local sell_number = tbl_orderList:GetData(i, 2)
--			-- 买家可购买量 = min(买家剩余需求量，金钱可支付量)
--			local buy_number = math.min(number, math.floor(MoneyManagerDB.GetMoney(playerId) / exchange_price))
--			-- 交易量	= min(卖家可售出额，买家可购买量)
--			local exchange_number =	math.min(sell_number, buy_number)
--			
--			if exchange_number ~= 0 then
--				-- 金钱转移
--				if MoneyManagerDB.AddMoney(playerId, - exchange_number * exchange_price) then
--					
--					local g_LogMgr = RequireDbBox("LogMgrDB")
--					g_LogMgr.LogPlayerGiverToNpc( playerId, "购买股票",{},exchange_number * exchange_price,1)
--	
--					local money_add = math.floor(exchange_number * exchange_price * (1 - 0.02))
--					CCofcStock._AddMoneyForCofc:ExecSql("", money_add,exchange_number ,cofc_id)
--					if g_DbChannelMgr:LastAffectedRowNum() > 0 then
--						-- 更新商会股票持有挂单
--						CCofcStock._SubOrderList:ExecSql("", exchange_number, tbl_orderList:GetData(i, 0))
--						if g_DbChannelMgr:LastAffectedRowNum() <= 0 then
--							CancelTran()
--							return 110047 --购买失败，扣除商会的原始股失败
--						end
--						-- 更新我的股票持有
--						CCofcStock._AddScockHave:ExecSql("", exchange_number, exchange_price, sell_costprice,exchange_number,sell_num ,exchange_number, my_have_id)
--						if g_DbChannelMgr:LastAffectedRowNum() <= 0 then
--							CancelTran()
--							return 110048 -- 购买失败，购买原始股时无法更新我的股票持有
--						end
--						-- 记录交易记录
--						CCofcStockSql.AddExchangeLog(cofc_id, 0, playerId, exchange_number, exchange_price)
--						-- MsgToConn(Conn, 11001, "以" .. exchange_price .. "的价格购买了" .. exchange_number .. "股的原始股")
--						number = number	- exchange_number
--						table.insert(code,{110059,exchange_price,exchange_number})
--					end
--				end
--			end
--		else -- 非原始股购买流程
--			-- 得到卖家的持有信息
--			-- shc_uId, shc_uNumber
--			local tbl_sell = CCofcStock._GetScockHave:ExecSql("nnn", cofc_id, tbl_orderList:GetData(i, 3))
--			if tbl_sell:GetRowNum() > 0 then
--				if tbl_sell:GetData(0, 1) == 0 then
--				--	CCofcStock._DeleteStockHave:ExecSql("", tbl_sell:GetData(0, 0))
--					if g_DbChannelMgr:LastAffectedRowNum() <= 0 then
--						CancelTran()
--						return 110049 -- 删除原有股票持有表时错误
--					end
--				else
--					-- 交易价格
--					local exchange_price = tbl_orderList:GetData(i,	1)		
--					-- 卖家可售出额 = min(卖家持有量，卖家订单量)
--					local sell_number = math.min(tbl_sell:GetData(0, 1), tbl_orderList:GetData(i, 2))
--					-- 买家可购买量 = min(买家剩余需求量，金钱可支付量)
--					local buy_number = math.min(number, math.floor(MoneyManagerDB.GetMoney(playerId) / exchange_price))
--					-- 交易量       = min(卖家可售出额，买家可购买量)
--					local exchange_number =	math.min(sell_number, buy_number)
--					if exchange_number ~= 0 then
--						---- 金钱转移
--						if MoneyManagerDB.MoveMoney(playerId, tbl_orderList:GetData(i, 3), exchange_number * exchange_price, 0, 0.02) then
--							
--							local g_LogMgr = RequireDbBox("LogMgrDB")
--
--							---- 扣除卖家的股票并调整订单
--							-- if 交易量 ==	卖家持有量，则删除卖家持有和卖家订单
--							if exchange_number == tbl_sell:GetData(0, 1)	then
--							--	CCofcStock._DeleteStockHave:ExecSql("", tbl_sell:GetData(0, 0))
--								if g_DbChannelMgr:LastAffectedRowNum() <= 0 then
--									CancelTran()
--									return 110050 --删除卖家持有股票表时错误
--								end
--								CCofcStock._DeleteOrderList:ExecSql("", tbl_orderList:GetData(i, 0))
--								if g_DbChannelMgr:LastAffectedRowNum() <= 0 then
--									CancelTran()
--									return 110051 --删除股票挂单信息表时错误
--								end
--							-- else	刷新持有表
--							else
--								--CCofcStock._SubStockHave:ExecSql("", exchange_number, tbl_sell:GetData(0, 0))
--								-- if 交易量 == 订单额，删除订单
--								if exchange_number == tbl_orderList:GetData(i,	2) then
--									CCofcStock._DeleteOrderList:ExecSql("", tbl_orderList:GetData(i, 0))
--									if g_DbChannelMgr:LastAffectedRowNum() <= 0 then
--										CancelTran()
--										return 110051 --删除股票挂单信息表时错误
--									end
--								-- else 更新订单额 = min(原订单额-交易额，原持有额-交易额)
--								else
--									local new_order_number = math.min(tbl_orderList:GetData(i, 2), tbl_sell:GetData(0, 1)) - exchange_number
--									CCofcStock._ResetOrderList:ExecSql("", new_order_number, tbl_orderList:GetData(i, 0))
--									if g_DbChannelMgr:LastAffectedRowNum() <= 0 then
--										CancelTran()
--										return 110052 --重新设置股票挂单信息表时错误
--									end
--								end
--							end
--						end
--						---- 更新我的股票持有
--						CCofcStock._AddScockHave:ExecSql("", exchange_number, exchange_price,sell_costprice ,exchange_number,sell_num ,exchange_number, my_have_id)
--						if g_DbChannelMgr:LastAffectedRowNum() <= 0 then
--							CancelTran()
--							return 110053 --更新我的股票持有表时错误
--						end
--						---- 记录交易记录
--						CCofcStockSql.AddExchangeLog(cofc_id, tbl_orderList:GetData(i, 3),playerId, exchange_number, exchange_price)
--						--MsgToConn(Conn, 11001, "以" .. exchange_price .. "的价格购买了" .. exchange_number .. "股")
--						number = number	- exchange_number
--						table.insert(code,{110057,exchange_price,exchange_number})
--					end
--				end
--			end
--		end
--	end
--	---- 将没有满足的需求生成订单
--	if number ~= 0 then
--		if MoneyManagerDB.AddMoney(playerId, -price * number) then
--			CCofcStock._AddNewOrder:ExecSql("", 0, cofc_id, playerId, price, number,0)
--			if g_DbChannelMgr:LastAffectedRowNum() <= 0 then
--				CancelTran()
--				MoneyManagerDB.AddMoney(playerId, price * number)
--				return 110054 --购买失败，可能是因为新订单添加失败
--			end
--			--MsgToConn(Conn, 11001, "因市面股票不足，以" .. price .. "的价格挂了个" .. number .. "的买单")
--			table.insert(code,{110058,price,number})
--			
--			local g_LogMgr = RequireDbBox("LogMgrDB")
--			g_LogMgr.LogPlayerGiverToNpc( playerId, "购买股票",{},price * number,1)
--			
--		else
--			return 110055   --购买失败，可能是因为扣挂单费用失败
--		end
--	end
--	return 110056,code  --股票购买完成
--end
----------------------------------------------------------------------------------------
--local StmtDef = { 
--	"_GetOrderList_Sell",
--	--- @brief 得到订单列表
--	[[
--		select soc_uId, soc_uPrice, soc_uNumber, cs_uId 
--		from tbl_stock_order_cofc
--		where c_uId = ? and soc_uType = 0 and soc_uPrice >= ?
--		order by soc_uPrice desc
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
---- @brief 我要卖股票
---- @param playerId:	要卖股票的玩家ID
---- @param cofc_id:	要卖股票的代码
---- @param number:		声称要卖出的股票数量
---- @param price:		股票要卖的价格
--
--function CCofcStockSql.StockSell(data)
--	local playerId = data["playerId"]
--	local cofc_id = data["cofc_id"]
--	local number = data["number"]
--	local price = data["price"]
--	local code = {}
--	local bFlag = true
--	--取得我对该股票的持有信息，若没有持有则返回
--	local tbl_sell = CCofcStock._GetScockHave:ExecSql("nnn", cofc_id, playerId)
--	
--	if tbl_sell:GetRowNum() == 0 or tbl_sell:GetData(0, 1) == 0 then
--		return 110073
--	end
--	local stock_have_player_id = tbl_sell:GetData(0,0)
--	-- 可卖出量 = min(我的持有量，我声称的卖出量)
--	number = math.min(tbl_sell:GetData(0, 1),number)
--
--	if number == 0 then	--可以卖的股票数是0
--		return 110073
--	end
--	
--	local sell_num = 0   --订单列表中所有玩家还没出售的股票数量
--	local sell_costprice = 0    --订单列表中所有玩家还没出售的股票当时所花费玩家的钱
--	--在股票订单中查询该玩家针对指定代码的股票
--	local order_list = CCofcStock._GetOrderInfoByPlayerId:ExecSql("nnn", cofc_id,playerId)
--		--在查询出来的结果集里面遍历订单列表里面的所有卖单
--	if nil ~= order_list and order_list:GetRowNum() > 0 then
--		for i = 0,order_list:GetRowNum()-1  do
--			if order_list:GetData(i,0) == 1 then
--				sell_num = sell_num + order_list:GetData(i,1)
--				sell_costprice = sell_costprice + order_list:GetData(i,1)*order_list:GetData(i,2)
--			end
--		end
--	end 
--	
--	-- 取得所有可能用到的订单列表
--	-- soc_uId, soc_uPrice, soc_uNumber, cs_uId(买单中的字段)
--	local tbl_orderList = CCofcStock._GetOrderList_Sell:ExecSql("nnnn", cofc_id, price)
--	-- 遍历订单列表进行销售
--	local sum_exchange_number = 0
--	local sum_money_add = 0
--	local num = tbl_orderList:GetRowNum() --可匹配买单的条数
--	local MoneyManagerDB =	RequireDbBox("MoneyMgrDB")
--	
--	--将所有买单都遍历一遍
--	for i = 0, num - 1 do
--		-- 交易价格
--		local exchange_price = tbl_orderList:GetData(i,	1) --以买家的价格为准
--		-- 交易量 = min(可卖出量，买家订单额)
--		local exchange_number = math.min(number, tbl_orderList:GetData(i, 2))
--		if exchange_number == 0 then --如果可交易的数量是0的话就跳出
--			bFlag = false
--		end
--		
--		if bFlag then
--			-- 把股票转给购买者
--			-- 查询下买单的玩家对玩家出售的这支股的控股情况。
--			local tbl_buy = CCofcStock._GetScockHave:ExecSql("nnn", cofc_id, tbl_orderList:GetData(i, 3))
--			--以前没有对该股的股份就插入一条新记录
--			if tbl_buy:GetRowNum() == 0 then
--				CCofcStock._InsertScockHave:ExecSql("", cofc_id, tbl_orderList:GetData(i, 3), exchange_number, exchange_price)
--			else
--				CCofcStock._AddScockHave:ExecSql("", exchange_number, exchange_price,sell_costprice ,exchange_number, sell_num,exchange_number, tbl_buy:GetData(0, 0))
--			end
--			
--			if g_DbChannelMgr:LastAffectedRowNum() <= 0 then
--				CancelTran()
--				return 110060 --将股票转给购买者时发生异常
--			end
--			
--			-- 购买者订单调整
--			if exchange_number == tbl_orderList:GetData(i, 2) then
--				CCofcStock._DeleteOrderList:ExecSql("", tbl_orderList:GetData(i, 0))
--			else
--				CCofcStock._SubOrderList:ExecSql("", exchange_number, tbl_orderList:GetData(i, 0))
--			end
--
--			if g_DbChannelMgr:LastAffectedRowNum() <= 0 then
--				CancelTran()
--				return 110061 --调整购买者订单时发生异常
--			end
--			
--			-- 记录交易记录
--			CCofcStockSql.AddExchangeLog(cofc_id, playerId, tbl_orderList:GetData(i, 3), exchange_number, exchange_price)
--			
--			-- 循环变量调整
--			number = number - exchange_number
--			sum_exchange_number = sum_exchange_number + exchange_number
--			sum_money_add = sum_money_add + exchange_number * exchange_price
--			--MsgToConn(Conn, 11001, "以" .. exchange_price .. "的价格卖了" .. exchange_number .. "股")
--			table.insert(code,{110062,exchange_price,exchange_number})
--			--减掉我的股票持有
--			if sum_exchange_number ~= 0 then
--				CCofcStock._SubStockHave:ExecSql("", sum_exchange_number, stock_have_player_id)
--			end
--
--			if g_DbChannelMgr:LastAffectedRowNum() <= 0 then
--				CancelTran()
--				return 110061 --调整购买者订单时发生异常
--			end
--			
--			-- 给我加钱
--			local ret = MoneyManagerDB.AddMoney(playerId, sum_money_add * (1 - 0.02))
--			
--							
--			if ret == false then
--				return 110063 --钱的改变时时发生异常
--			end
--		end
--	end
--	
--	-- 将没有满足的需求生成订单
--	if number ~= 0 then
--	--	MsgToConn(Conn, 11001, "还有" .. number .. "股没有卖掉，以" .. price .. "的价格挂了卖单")
--		table.insert(code,{110064,number,price})
--		CCofcStock._AddNewOrder:ExecSql("", 1, cofc_id, playerId, price, number,tbl_sell:GetData(0,2))
--		CCofcStock._SubStockHave:ExecSql("", number, stock_have_player_id)
--		if g_DbChannelMgr:LastAffectedRowNum() <= 0 then
--			CancelTran()
--			return false
--		end
--	end
--	return 110065,code --股票销售完成
--end
--------------------------------------------------------------------------------------
--local StmtDef = {
--	"_RequestOpenCofCStock",
--	[[
--		update tbl_cofc set c_nStockSum=? where c_uId=? and c_nStockSum=0
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--local StmtDef = {
--	"_CreateInitialOrder",
--	[[
--		insert into tbl_stock_order_cofc(c_uId, soc_uType, soc_dtCreateTime, soc_uPrice, soc_uNumber)
--		values(?, 1, now(), ?*100, ?)
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--local StmtDef = {
--	"_SelectCofcOrder",
--	[[
--		select cs_uId from tbl_stock_order_cofc where c_uId = ?
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--
--
----- @brief 请求开通商会股票
--function CCofcStockSql.RequestOpenCofCStock(data)
--	local playerId = data["playerId"]
--	
--	local CofcBasicDB = RequireDbBox("CofcBasicDB")
--	local cofc_id = CofcBasicDB.GetCofcID(playerId)
--	
--	if cofc_id == nil or cofc_id == 0 then
--		return false
--	end
--	local CofcBasicDB = RequireDbBox("CofcBasicDB")
--	local position = CofcBasicDB.GetPosition(playerId)
--	if position ~= "会长" then
--		return 110069
--	end
--	
--	local result =  CCofcStock._SelectCofcOrder:ExecSql("n",cofc_id)
--	if result:GetRowNum() > 0 then
--		return 110070
--	end
--	local initStockNumber = 10000
--	local initStockPrice  = 1
--	CCofcStock._RequestOpenCofCStock:ExecSql("", initStockNumber, cofc_id)
--	if g_DbChannelMgr:LastAffectedRowNum() == 0 then
--		CancelTran()
--		return false
--	end
--	CCofcStock._CreateInitialOrder:ExecSql("", cofc_id, initStockPrice, initStockNumber)
--	if g_DbChannelMgr:LastAffectedRowNum() == 0 then
--		CancelTran()
--		return false
--	end
--	return true
--end
--------------------------------------------------------------------------------------
--local StmtDef = { 
--	"_GetOrderInfo",
--	[[
--		select cs_uId, soc_uType, soc_uPrice, soc_uNumber
--		from tbl_stock_order_cofc
--		where soc_uId = ?
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--
--local StmtDef = {
--	"_AddStockHave",
--	--- @brief 增加对某支股票的持有量
--	[[
--		update tbl_stock_have_cofc set shc_uNumber = shc_uNumber + ? where shc_uId = ?
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--
----- @brief 删除订单
----- @param order_sid 订单流水号
--function CCofcStockSql.DeleteOrder(data)
--	local order_sid = data["order_sid"]
--	local playerId = data["playerId"]
--	local tbl = CCofcStock._GetOrderInfo:ExecSql("nnnn", order_sid)
--	local MoneyManagerDB=	RequireDbBox("MoneyMgrDB")
--	local money = 0
--	if tbl:GetRowNum() > 0 then
--		-- 如果是买单则涉及到退钱
--		if tbl:GetData(0, 1) == 0 then
--			money = tbl:GetData(0, 2) * tbl:GetData(0, 3)
--			if not MoneyManagerDB.AddMoney(playerId, money) then
--				return false
--			end
--		end
--		-- 如果是卖单则涉及到加股票
--		local tbl_sell = CCofcStock._GetScockHave:ExecSql("nnn", tbl:GetData(0,0), playerId)
--		if tbl:GetData(0, 1) == 1 then
--			if nil ~= tbl_sell and tbl_sell:GetRowNum() > 0 then
--				CCofcStock._AddStockHave:ExecSql("",tbl:GetData(0, 3),tbl_sell:GetData(0,0))
--				if g_DbChannelMgr:LastAffectedRowNum() == 0 then
--					CancelTran()
--					return false
--				end
--			end
--		end 
--		
--		CCofcStock._DeleteOrderList:ExecSql("", order_sid)
--		if g_DbChannelMgr:LastAffectedRowNum() == 0 then
--			CancelTran()
--			return false
--		end
--		
--		return true,money
--	end
--	return false
--end
----------------------------------------------------------------------------------------
--local StmtDef = { 
--	"_CheckFinancialReport",
--	--- @brief 通过获取任意当前财务周期的id，确认当前周期财务结算是否进行过
--	[[
--		select src_uId
--		from tbl_stock_report_cofc
--		where src_dtEndTime = date_add(date(now()), interval -weekday(now()) - 1 day) limit 1
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--local StmtDef = { 
--	"_CreateFinancialReport",
--	--- @brief 生成本期财务报表
--	[[
--		insert into tbl_stock_report_cofc(
--		c_uId, 
--		src_dtEndTime, 
--		src_uLevel, 
--		src_uMemberNum, 
--		src_uMoneyAll, 
--		src_uMoneyIncome,
--		src_uExchangeNum, 
--		src_uBonusAll, 
--		src_uStockNum, 
--		src_uActivePoint)
--		(select 
--			tc.c_uId, 
--			date_add(date(now()), interval -weekday(now()) - 1 day), 
--			tc.c_uLevel, 
--			(select count(*) from tbl_member_cofc as tmc where tmc.c_uId=tc.c_uId),
--			tc.c_uMoney,
--			0, -- TODO: 期间收入
--			ifnull((select sum(tsec.sec_nNumber) 
--				from tbl_stock_exchange_cofc as tsec 
--				where tsec.c_uId=tc.c_uId 
--				and tsec.sec_dtTraceTime >= date_add(date(now()), interval -weekday(now()) - 8 day)
--				and tsec.sec_dtTraceTime < date_add(date(now()), interval -weekday(now()) - 1 day)), 0),
--			0, -- TODO: 可分红利总数
--			tc.c_nStockSum - ifnull((select soc_uNumber from tbl_stock_order_cofc where c_uId = tc.c_uId and soc_uType = 1 and cs_uId is null limit 1), 0),
--			0  -- TODO: 活跃点数
--		from tbl_cofc as tc)
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
--local StmtDef = { 
--	"_UpdateMajorShareholder",
--	--- @brief 更新大股东表
--	[[
--		insert into tbl_stock_report_shareholder_cofc(src_uId, cs_uId, srsc_uNumber) 
--		(select tsrc.src_uId, tshc.cs_uId, tshc.shc_uNumber
--		from tbl_stock_have_cofc as tshc,
--			tbl_stock_report_cofc as tsrc
--		where tshc.c_uId in (select c_uId from tbl_stock_report_cofc
--			where src_dtEndTime = date_add(date(now()), interval -weekday(now()) - 1 day))
--			and tsrc.src_dtEndTime = date_add(date(now()), interval -weekday(now()) - 1 day)
--			and tsrc.c_uId = tshc.c_uId
--		order by shc_uNumber desc
--		limit 5)
--	]]
--}
--DefineSql(StmtDef, CCofcStock)
------- @brief 财务结算。分红并生成财务报表
--function CCofcStockSql.CofcStockFinancialBalance(parameter)
--	local tbl = CCofcStock._CheckFinancialReport:ExecSql("n")
--	-- 本期已经结算过了
--	if tbl:GetRowNum() > 0 then
----		print("财务结算跳过")
--		return false
--	end
--	-- 生成本次财报
--	CCofcStock._CreateFinancialReport:ExecSql("")
--	if g_DbChannelMgr:LastAffectedRowNum() > 0 then
----		print("财报生成成功：" .. g_DbChannelMgr:LastAffectedRowNum())
--	else
----		print("没有生成财报")
--	end
--	CCofcStock._UpdateMajorShareholder:ExecSql("")
--	if g_DbChannelMgr:LastAffectedRowNum() > 0 then
----		print("大股东表更新成功：" .. g_DbChannelMgr:LastAffectedRowNum())
--	else
----		print("没有更新大股东表")
--	end
--	-- TODO: 计算本期分红
--	return true
--end
----------------------------------------------------------------------------------------
--
--return CCofcStockSql
