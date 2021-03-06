local _M = {}
local bit = require "bit"
local cjson = require "cjson.safe"

local Json = cjson.encode

local insert = table.insert
local concat = table.concat

local strload

local cmds = {
  [0] = "length",
  [1] = "DTU_time",
  [2] = "DTU_status",
  [3] = "DTU_function",
  [4] = "device_address"
}

local status_cmds = {
  [1] = "feedback_speed",             --反馈速度
  [2] = "given_speed",                --给定速度
  [3] = "output_voltage",             --输出电压
  [4] = "output_current",             --输出电流
  [5] = "output_torque",              --输出转矩
  [6] = "bus_voltage",                --母线电压
  [7] = "analog_input0",
  [8] = "analog_input1",
  [9] = "analog_input2",
  [10] = "cooling_temperature",       --散热器温度
  [11] = "output_actpow",             --输出有功功率
  [12] = "run_state",                 --运行状态
  [13] = "inputIO_state",
  [14] = "outputIO_state",          
  [15] = "drive_efficiency",          --驱动器效率
  [16] = "output_rmp",                --输出转速
  [17] = "voltage_u",                 --u相电压
  [18] = "voltage_v",                 --v相电压
  [19] = "voltage_w",                 --w相电压
  [20] = "current_u",                 --u相电流
  [21] = "current_v",                 --v相电流
  [22] = "current_w",                 --w相电流
  [23] = "system_time",               --系统时间
  [24] = "total_power",               --输出总功率
  [25] = "power_factor",              --功率因数
  [26] = "inverter_vol",              --变频器额定电压
  [27] = "inverter_cur",              --变频器额定电流
  [28] = "inverter_freq",             --变频器额定频率
  [29] = "inverter_power",            --变频器额定功率
  [30] = "inverter_hardver",          --变频器硬件版本号
  [31] = "inverter_softver",          --变频器软件版本号
  [32] = "inverter_version",          --变频器版本号
  [33] = "motor_vol",                 --电机额定电压
  [34] = "motor_cur",                 --电机器额定电流
  [35] = "motor_freq",                --电机器额定频率
  [36] = "motor_power",               --电机器额定功率
  [37] = "motor_torq",                --电机器额定转矩
  [38] = "motor_speed",               --电机器转速
  [39] = "motor_poles",               --电机器极数
}

--解析运行状态
local run_state_cmds={
  [1] = "run_state_1",               --运行状态bit1——运行or停止 
  [2] = "run_state_2",               --运行状态bit3——正转or反转
  [3] = "run_state_3",               --运行状态bit5——基极封锁与否
  [4] = "run_state_4",               --运行状态bit7——正常or故障
  [5] = "run_state_5",               --运行状态bit12——限频状态 0未限频 1限频
  [6] = "run_state_6",               --运行状态bit13——锁梯状态 0未锁梯 1锁梯
}

local inputIO_cmds ={
  [1] = "X0",           --X0 有值1时绿色显示 值0时灰色显示
  [2] = "X1",           --X1
  [3] = "X2",           --X2
  [4] = "X3",           --X3
  [5] = "X4",           --X4
  [6] = "X5",           --X5
  [7] = "X6"		        --X6
}

local outputIO_cmds ={
  [1] = "K1",           --K1 有值1时蓝色显示 值0时灰色显示
  [2] = "K2",           --K2
  [3] = "K3",           --K3
  [4] = "K4",           --K4
  [5] = "Y0",           --Y0
  [6] = "Y1"            --Y1
}

local para_1 = {
  ["P10_"] = 6,
  ["P11_"] = 10,
  ["P12_"] = 10,
  ["P13_"] = 3,
  ["P14_"] = 11,
  ["P20_"] = 12,
  ["P21_"] = 6,
  ["P22_"] = 8,        --从22.01开始
  ["P23_"] = 7,         --从23.01开始
  ["P30_"] = 11,
  ["P31_"] = 24,
  ["P32_"] = 18,
  ["P33_"] = 6,
  ["P40_"] = 15,
  ["P41_"] = 16,
  ["P50_"] = 3,
  ["P51_"] = 38,
  ["P60_"] = 14,
  ["P61_"] = 8,
  ["P62_"] = 4,
  ["P63_"] = 5,
  ["P70_"] = 10,
  ["P71_"] = 35,
  ["P80_"] = 1,
  ["P81_"] = 8,
  ["P82_"] =5,
  ["P90_"] = 1,
  ["P91_"] = 9,
  ["P92_"] = 1,
  ["P93_"] = 3,
  ["P94_"] = 11,
  ["P95_"] = 3,
  ["P96_"] = 18
}

local para_0 = {  
          "P10_","P11_","P12_","P13_","P14_",
          "P20_","P21_","P22_","P23_",
          "P30_","P31_","P32_","P33_",
          "P40_","P41_",
          "P50_","P51_",
          "P60_","P61_","P62_","P63_",
          "P70_","P71_",
          "P80_","P81_","P82_",
          "P90_","P91_","P92_","P93_","P94_","P95_","P96_"
        }

local num = 1
local parameter_cmds = {}

for k,v in ipairs(para_0) do
  local l = para_1[v]
  for i=0,l-1,1 do
    if ("P71_" == v) then
      if(i<=25) then
        parameter_cmds[num] = v..string.format("%02d",i)
      else
        parameter_cmds[num] = v..string.format("%02d",i+7)
      end
    else
      parameter_cmds[num] = v..string.format("%02d",i)
    end
    num = num + 1
  end
end

--71组中26-32是没有参数的
local parameter_RealValue0 = {
["P10_00"]=0,["P10_01"]=0,["P10_02"]=0,["P10_03"]=0,["P10_04"]=0,["P10_05"]=0,

["P11_00"]=0,["P11_01"]=2,["P11_02"]=1,["P11_03"]=2,["P11_04"]=1,["P11_05"]=1,["P11_06"]=1,["P11_07"]=1,["P11_08"]=1,["P11_09"]=2,

["P12_00"]=0,["P12_01"]=2,["P12_02"]=1,["P12_03"]=2,["P12_04"]=1,["P12_05"]=1,["P12_06"]=1,["P12_07"]=1,["P12_08"]=1,["P12_09"]=1,

["P13_00"]=0,["P13_01"]=0,["P13_02"]=1,

["P14_00"]=0,["P14_01"]=0,["P14_02"]=2,["P14_03"]=0,["P14_04"]=2,["P14_05"]=0,["P14_06"]=2,["P14_07"]=0,["P14_08"]=2,["P14_09"]=0,
["P14_10"]=2,

["P20_00"]=0,["P20_01"]=2,["P20_02"]=1,["P20_03"]=2,["P20_04"]=0,["P20_05"]=0,["P20_06"]=0,["P20_07"]=2,["P20_08"]=2,["P20_09"]=0,
["P20_10"]=2,["P20_11"]=1,

["P21_00"]=0,["P21_01"]=3,["P21_02"]=3,["P21_03"]=4,["P21_04"]=4,["P21_05"]=4,

["P22_00"]=0,["P22_01"]=0,["P22_02"]=0,["P22_03"]=0,["P22_04"]=1,["P22_05"]=0,["P22_06"]=0,["P22_07"]=0,

["P23_00"]=0,["P23_01"]=3,["P23_02"]=1,["P23_03"]=1,["P23_04"]=1,["P23_05"]=1,["P23_06"]=1,

["P30_00"]=0,["P30_01"]=0,["P30_02"]=0,["P30_03"]=0,["P30_04"]=0,["P30_05"]=0,["P30_06"]=0,["P30_07"]=0,["P30_08"]=0,["P30_09"]=2,
["P30_10"]=2,

["P31_00"]=0,["P31_01"]=0,["P31_02"]=0,["P31_03"]=0,["P31_04"]=0,["P31_05"]=0,["P31_06"]=1,["P31_07"]=1,["P31_08"]=1,["P31_09"]=1,
["P31_10"]=1,["P31_11"]=1,["P31_12"]=1,["P31_13"]=1,["P31_14"]=1,["P31_15"]=1,["P31_16"]=1,["P31_17"]=1,["P31_18"]=0,["P31_19"]=0,
["P31_20"]=1,["P31_21"]=2,["P31_22"]=2,["P31_23"]=2,

["P32_00"]=0,["P32_01"]=0,["P32_02"]=3,["P32_03"]=1,["P32_04"]=0,["P32_05"]=3,["P32_06"]=0,["P32_07"]=0,["P32_08"]=3,["P32_09"]=1,
["P32_10"]=0,["P32_11"]=3,["P32_12"]=0,["P32_13"]=0,["P32_14"]=3,["P32_15"]=1,["P32_16"]=0,["P32_17"]=3,

["P33_00"]=0,["P33_01"]=3,["P33_02"]=1,["P33_03"]=0,["P33_04"]=3,["P33_05"]=1,

["P40_00"]=2,["P40_01"]=2,["P40_02"]=2,["P40_03"]=2,["P40_04"]=2,["P40_05"]=2,["P40_06"]=2,["P40_07"]=2,["P40_08"]=2,["P40_09"]=2,
["P40_10"]=2,["P40_11"]=2,["P40_12"]=2,["P40_13"]=2,["P40_14"]=0,

["P41_00"]=2,["P41_01"]=2,["P41_02"]=2,["P41_03"]=2,["P41_04"]=2,["P41_05"]=2,["P41_06"]=2,["P41_07"]=2,["P41_08"]=2,["P41_09"]=2,
["P41_10"]=2,["P41_11"]=2,["P41_12"]=2,["P41_13"]=2,["P41_14"]=2,["P41_15"]=2,
}--14*10
local parameter_RealValue1 = {
["P50_00"]=0,["P50_01"]=0,["P50_02"]=0,

["P51_00"]=0,["P51_01"]=0,["P51_02"]=0,["P51_03"]=0,["P51_04"]=0,["P51_05"]=0,["P51_06"]=0,["P51_07"]=2,["P51_08"]=0,["P51_09"]=2,
["P51_10"]=2,["P51_11"]=2,["P51_12"]=3,["P51_13"]=0,["P51_14"]=2,["P51_15"]=2,["P51_16"]=2,["P51_17"]=2,["P51_18"]=2,["P51_19"]=2,
["P51_20"]=2,["P51_21"]=2,["P51_22"]=1,["P51_23"]=0,["P51_24"]=1,["P51_25"]=1,["P51_26"]=1,["P51_27"]=1,["P51_28"]=0,["P51_29"]=0,
["P51_30"]=0,["P51_31"]=0,["P51_32"]=1,["P51_33"]=3,["P51_34"]=1,["P51_35"]=1,["P51_36"]=1,["P51_37"]=1,

["P60_00"]=2,["P60_01"]=2,["P60_02"]=2,["P60_03"]=2,["P60_04"]=2,["P60_05"]=2,["P60_06"]=2,["P60_07"]=2,["P60_08"]=2,["P60_09"]=2,
["P60_10"]=2,["P60_11"]=2,["P60_12"]=1,["P60_13"]=1,

["P61_00"]=2,["P61_01"]=2,["P61_02"]=2,["P61_03"]=1,["P61_04"]=1,["P61_05"]=0,["P61_06"]=1,["P61_07"]=1,

["P62_00"]=1,["P62_01"]=0,["P62_02"]=2,["P62_03"]=2,

["P63_00"]=0,["P63_01"]=1,["P63_02"]=1,["P63_03"]=1,["P63_04"]=1,

["P70_00"]=2,["P70_01"]=2,["P70_02"]=2,["P70_03"]=0,["P70_04"]=0,["P70_05"]=0,["P70_06"]=0,["P70_07"]=2,["P70_08"]=0,["P70_09"]=0,

["P71_00"]=2,["P71_01"]=2,["P71_02"]=2,["P71_03"]=2,["P71_04"]=1,["P71_05"]=0,["P71_06"]=1,["P71_07"]=0,["P71_08"]=0,["P71_09"]=1,
["P71_10"]=2,["P71_11"]=0,["P71_12"]=2,["P71_13"]=3,["P71_14"]=3,["P71_15"]=3,["P71_16"]=0,["P71_17"]=1,["P71_18"]=1,["P71_19"]=1,
["P71_20"]=1,["P71_21"]=1,["P71_22"]=2,["P71_23"]=0,["P71_24"]=0,["P71_25"]=1,["P71_33"]=1,["P71_34"]=0,["P71_35"]=1,["P71_36"]=1,
["P71_37"]=0,["P71_38"]=1,["P71_39"]=0,["P71_40"]=0,["P71_41"]=4,

["P80_00"]=0,

["P81_00"]=0,["P81_01"]=1,["P81_02"]=0,["P81_03"]=2,["P81_04"]=2,["P81_05"]=0,["P81_06"]=0,["P81_07"]=0,

["P82_00"]=0,["P82_01"]=0,["P82_02"]=0,["P82_03"]=0,["P82_04"]=0,

["P90_00"]=0,

["P91_00"]=0,["P91_01"]=0,["P91_02"]=0,["P91_03"]=0,["P91_04"]=0,
["P91_05"]=0,["P91_06"]=0,["P91_07"]=0,["P91_08"]=0,

["P92_00"]=0,

["P93_00"]=0,["P93_01"]=0,["P93_02"]=1,

["P94_00"]=0,["P94_01"]=1,["P94_02"]=0,["P94_03"]=2,["P94_04"]=2,["P94_05"]=0,["P94_06"]=0,["P94_07"]=0,["P94_08"]=3,["P94_09"]=0,
["P94_10"]=0,

["P95_00"]=2,["P95_01"]=2,["P95_02"]=2,

["P96_00"]=2,["P96_01"]=1,["P96_02"]=1,["P96_03"]=0,["P96_04"]=0,["P96_05"]=0,["P96_06"]=0,["P96_07"]=0,["P96_08"]=3,["P96_09"]=0,
["P96_10"]=0,["P96_11"]=0,["P96_12"]=0,["P96_13"]=0,["P96_14"]=0,["P96_15"]=0,["P96_16"]=0,["P96_17"]=0,
}

local fault_cmds = {}
local faultcmds = {
    [1] = "real_speed",
    [2] = "given_speed",
    [3] = "bus_voltage",
    [4] = "current",
    [5] = "code",
}

for i=0,7,1 do
  for j=1,5,1 do
    fault_cmds[i*5+j] = "fault"..i.."_"..faultcmds[j] 
  end
end

function utilCalcFCS( pBuf , len )
	local rtrn = 0
	local l = len

	while (len ~= 0)
		do
		len = len - 1
		rtrn = bit.bxor( rtrn , pBuf[l-len] )
	end

	return rtrn
end

function getnumber( index )
   return string.byte(strload,index)
end

function _M.encode(payload)
  return payload
end

function _M.decode(payload)
    local packet = {['status']='not'}
    local FCS_Array = {}
    local FCS_Value = 0

    strload = payload

    local head1 = getnumber(1)
    local head2 = getnumber(2)

    if ( head1 == 0x3B and head2 == 0x31 ) then 
      
      local templen = bit.lshift( getnumber(3) , 8 ) + getnumber(4)
      --templen will be the important parameter in the next calculate
      --in different task some number mabey be changed 
      --to avoid unnecessary problem
      packet[ cmds[0] ] = templen
      packet[ cmds[1] ] = bit.lshift( getnumber(5) , 8 ) + bit.lshift( getnumber(6) , 16 ) + bit.lshift( getnumber(7) , 8 ) + getnumber(8)

      local mode = getnumber(9)
      if mode == 1 then
          packet[ cmds[2] ] = 'Mode-485'
        else
          packet[ cmds[2] ] = 'Mode-232'
      end

      local bitbuff_table0={}  --用来暂存inputIO_state的每位bit值
      local bitbuff_table1={}  --用来暂存outputIO_state的每位bit值
      local databuff_table0={}
      local databuff_table1={}
      local func = getnumber(10)

      if func == 1 then
          packet[ cmds[3] ] = 'func-status'
          FCS_Value = bit.lshift( getnumber(90) , 8 ) + getnumber(91)
      
          for i=1,39,1 do  
          	databuff_table0[i] =  bit.lshift( getnumber(10+i*2) , 8 ) + getnumber(11+i*2) 
            
            --判断正负数，处理数据
            local x = bit.band(databuff_table0[i],bit.lshift(1,15))
            if(x == 0) then
              databuff_table1[i] = databuff_table0[i]
            else
              databuff_table1[i] = -(0xffff-databuff_table0[i]+1)
            end 
          
          	if(i==30) then
              packet[ status_cmds[i] ] = databuff_table0[i] 
            else
              packet[ status_cmds[i] ] = databuff_table1[i] 
            end
			         
          end

          --处理小数点
          packet[ status_cmds[1] ] = databuff_table1[1] / 100
    	    packet[ status_cmds[2] ] = databuff_table1[2] / 100
    	    packet[ status_cmds[3] ] = databuff_table1[3] / 10
    	    packet[ status_cmds[4] ] = databuff_table1[4] / 10
    	    packet[ status_cmds[5] ] = databuff_table1[5] / 10
    	    packet[ status_cmds[7] ] = databuff_table1[7] / 1000  
    	    packet[ status_cmds[8] ] = databuff_table1[8] / 1000  
          packet[ status_cmds[9] ] = databuff_table1[9] / 1000
          packet[ status_cmds[16] ] = databuff_table1[16] 

          packet[ status_cmds[27] ] = databuff_table1[27] / 10
          packet[ status_cmds[28] ] = databuff_table1[28] / 100
          packet[ status_cmds[29] ] = databuff_table1[29] / 100
          packet[ status_cmds[30] ] = databuff_table0[30] / 100
          packet[ status_cmds[31] ] = databuff_table1[31] / 100
          packet[ status_cmds[32] ] = databuff_table1[32] / 100
          packet[ status_cmds[34] ] = databuff_table1[34] / 10 
          packet[ status_cmds[35] ] = databuff_table1[35] / 100 
          packet[ status_cmds[36] ] = databuff_table1[36] / 100  
          packet[ status_cmds[37] ] = databuff_table1[37] / 10

          --[[
          [26] = "inverter_vol",              --变频器额定电压
          [27] = "inverter_cur",              --变频器额定电流
          [28] = "inverter_freq",             --变频器额定频率
          [29] = "inverter_power",            --变频器额定功率
          [30] = "inverter_hardver",          --变频器硬件版本号
          [31] = "inverter_softver",          --变频器软件版本号
          [32] = "inverter_version",          --变频器版本号
          [33] = "motor_vol",                 --电机额定电压
          [34] = "motor_cur",                 --电机器额定电流
          [35] = "motor_freq",                --电机器额定频率
          [36] = "motor_power",               --电机器额定功率
          [37] = "motor_torq",                --电机器额定转矩
          [38] = "motor_speed",               --电机器转速
          [39] = "motor_poles",               --电机器极数
          ]]

          --解析run_state bit1 bit3  bit5 bit7对应运行停止 正反转  基极封锁中 故障中
          for i=0,3 do
              local m = bit.band(databuff_table1[12],bit.lshift(1,1+i*2))
              if(i==2)or(i==3) then  --基极封锁状态 故障状态 为配合云端 将其状态取反
                if m==0 then
                  packet[ run_state_cmds[1+i] ] = 1
                else
                  packet[ run_state_cmds[1+i] ] = 0
                end
              else
                if m==0 then
                  packet[ run_state_cmds[1+i] ] = 0
                else
                  packet[ run_state_cmds[1+i] ] = 1
                end
              end    
          end

          --解析run_state bit12 bit13 限频状态 锁梯状态
          for i=0,1 do
              local m = bit.band(databuff_table1[12],bit.lshift(1,12+i))
              if m==0 then
                packet[ run_state_cmds[5+i] ] = 0
              else
                packet[ run_state_cmds[5+i] ] = 1
              end
          end

          --解析inputIO_state(对应高字节getnumber[36],低字节getnumber[37])的每个bit位值
    			for j=0,1 do
    				for i=0,7 do
    					local y = bit.band(getnumber((37-j)),bit.lshift(1,i)) --先低字节解析后高字节解析
    					if(y == 0) then 
	               bitbuff_table0[j*8+i+1] = 0
	            else
	               bitbuff_table0[j*8+i+1] = 1
	            end 
    				end
    			end
    			--将inputIO_state的每位bit值转化为JSON格式数据
    			packet[ inputIO_cmds[1] ] = bitbuff_table0[1]
    			packet[ inputIO_cmds[2] ] = bitbuff_table0[2]
    			packet[ inputIO_cmds[3] ] = bitbuff_table0[3]
    			packet[ inputIO_cmds[4] ] = bitbuff_table0[4]
    			packet[ inputIO_cmds[5] ] = bitbuff_table0[5]
    			packet[ inputIO_cmds[6] ] = bitbuff_table0[6]
    			packet[ inputIO_cmds[7] ] = bitbuff_table0[7]
			
    			--解析outputIO_state(对应高字节getnumber[38],低字节getnumber[39])的每个bit位值
    			for j=0,1 do
    				for i=0,7 do
    					local y = bit.band(getnumber((39-j)),bit.lshift(1,i)) --先低字节解析后高字节解析
    					if(y == 0) then 
	               bitbuff_table1[j*8+i+1] = 0
	            else
	               bitbuff_table1[j*8+i+1] = 1
	            end 
    				end
    			end
    			--将outputIO_state的每位bit值转化为JSON格式数据
    			packet[ outputIO_cmds[1] ] = bitbuff_table1[1]
    			packet[ outputIO_cmds[2] ] = bitbuff_table1[2]
    			packet[ outputIO_cmds[3] ] = bitbuff_table1[3]
    			packet[ outputIO_cmds[4] ] = bitbuff_table1[4]
    			packet[ outputIO_cmds[5] ] = bitbuff_table1[5]
    			packet[ outputIO_cmds[6] ] = bitbuff_table1[6]
		
          for i=1,89,1 do        
            table.insert(FCS_Array,getnumber(i))
          end
          
      else if func == 2 then
        
        packet[ cmds[3] ] = 'func-fault'
        FCS_Value = bit.lshift( getnumber(108) , 8 ) + getnumber(109)       
        for i=0,7,1 do
          packet[ fault_cmds[1+i*5] ] = ( bit.lshift( getnumber(12+i*12) , 8 ) + getnumber(13+i*12) ) /100
          packet[ fault_cmds[2+i*5] ] = ( bit.lshift( getnumber(14+i*12) , 8 ) + getnumber(15+i*12) ) /100
          packet[ fault_cmds[3+i*5] ] = ( bit.lshift( getnumber(16+i*12) , 8 ) + getnumber(17+i*12) ) 
          packet[ fault_cmds[4+i*5] ] = ( bit.lshift( getnumber(18+i*12) , 8 ) + getnumber(19+i*12) ) /100
          packet[ fault_cmds[5+i*5] ] =  getnumber(22+i*12) 
        end
     
        for i=1,107,1 do        
          table.insert(FCS_Array,getnumber(i))
        end
      
      else  --读取参数
          packet[ cmds[3] ] = 'func-parameter'
          FCS_Value = bit.lshift( getnumber(692) , 8 ) + getnumber(693)

          for i=1,340,1 do 
      	      
              local temp = 0
              if(parameter_RealValue0[ parameter_cmds[i] ] ~= nil)then
                temp = parameter_RealValue0[ parameter_cmds[i] ]
              else
                temp = parameter_RealValue1[ parameter_cmds[i] ]
              end 

        	    if temp ~= -1 then
                local paranum = ( bit.lshift( getnumber(10+i*2) , 8 ) + getnumber(11+i*2) ) / ( 10^temp )
                local parastrformat = "%0."..temp.."f"
        	      packet[ parameter_cmds[i] ] = string.format(parastrformat,paranum)
        	    end --88 
          end

          for i=1,691,1 do        
            table.insert(FCS_Array,getnumber(i))
          end
        end --88
      end

      packet[ cmds[4] ] = getnumber(11)

      if(utilCalcFCS(FCS_Array,#FCS_Array) == FCS_Value) then
        packet['status'] = 'SUCCESS'
      else
        packet = {}
        packet['status'] = 'FCS-ERROR'
      end

    end 

    return Json(packet)
end

return _M
