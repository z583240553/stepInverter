local _M = {}
local bit = require "bit"
local cjson = require "cjson.safe"

local Json = cjson.encode

local insert = table.insert
local concat = table.concat
--
local strload

local cmds = {
  [0] = "length",
  [1] = "DTU_time",
  [2] = "DTU_status",
  [3] = "DTU_function",
  [4] = "device_address"
}

local status_cmds = {
  [1] = "feedback_speed",           --反馈速度
  [2] = "given_speed",              --给定速度
  [3] = "output_voltage",           --输出电压
  [4] = "output_current",           --输出电流
  [5] = "output_torque",             --输出转矩
  [6] = "bus_voltage",              --母线电压
  [7] = "analog_input0",
  [8] = "analog_input1",
  [9] = "analog_input2",
  [10] = "cooling_temperature",      --散热器温度
  [11] = "output_actpow",        
  [12] = "run_state",                --运行状态
  [13] = "inputIO_state",
  [14] = "outputIO_state",          
  [15] = "drive_efficiency",         --驱动器效率
  [16] = "output_rmp"                --输出转速
}

local inputIO_cmds ={
  [1] = "X0",           --X0 有值1时绿色显示 值0时灰色显示
  [2] = "X1",           --X1
  [3] = "X2",           --X2
  [4] = "X3",           --X3
  [5] = "X4",           --X4
  [6] = "X5",           --X5
  [7] = "X6"		    --X6
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
  ["P00_"] = 3,
  ["P10_"] = 11,
  ["P11_"] = 22,
  ["P12_"] = 11,
  ["P13_"] = 2,
  ["P14_"] = 15,
  ["P20_"] = 28,
  ["P21_"] = 11,
  ["P22_"] = 14,        --从22.01开始
  ["P23_"] = 6,         --从23.01开始
  ["P30_"] = 9,
  ["P31_"] = 26,
  ["P32_"] = 12,
  ["P33_"] = 8,
  ["P40_"] = 22,
  ["P41_"] = 17,
  ["P50_"] = 2,
  ["P60_"] = 17,
  ["P61_"] = 16,
  ["P62_"] = 4,
  ["P63_"] = 5,
  ["P70_"] = 36,
  ["P71_"] = 65,
  ["P80_"] = 1,
  ["P81_"] = 8,
  ["P82_"] = 11,
  ["P90_"] = 1,
  ["P91_"] = 8,
  ["P92_"] = 1,
  ["P93_"] = 8,
  ["P94_"] = 26,
  ["P95_"] = 4,
  ["P96_"] = 20
}
local para_0 = {  
          "P00_",
          "P10_","P11_","P12_","P13_","P14_",
          "P20_","P21_","P22_","P23_",
          "P30_","P31_","P32_","P33_",
          "P40_","P41_",
          "P50_",
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
    if ("P22_" == v) or ("P23_" == v) then
      parameter_cmds[num] = v..string.format("%02d",i+1)
    else
      parameter_cmds[num] = v..string.format("%02d",i)
    end
    num = num + 1
  end
end

local parameter_RealValue0 = {
["P22_04"]=1,["P11_11"]=2,["P32_01"]=0,["P71_36"]=1,["P60_05"]=2,["P21_03"]=4,["P96_14"]=-1,["P41_15"]=2,["P33_02"]=1,["P41_05"]=2,
["P96_16"]=0,["P94_03"]=2,["P96_10"]=-1,["P22_11"]=1,["P14_06"]=2,["P70_32"]=0,["P30_03"]=0,["P63_03"]=1,["P41_10"]=2,["P96_07"]=0,
["P30_05"]=0,["P11_15"]=1,["P14_11"]=0,["P31_24"]=0,["P71_45"]=2,["P20_15"]=2,["P41_06"]=2,["P71_34"]=0,["P60_16"]=1,["P32_10"]=0,
["P93_07"]=0,["P41_16"]=2,["P40_06"]=2,["P60_07"]=0,["P20_03"]=2,["P31_10"]=1,["P20_09"]=0,["P12_05"]=1,["P31_17"]=1,["P71_39"]=0,
["P40_05"]=2,["P21_09"]=4,["P21_05"]=4,["P31_18"]=-1,["P31_11"]=1,["P71_63"]=0,["P70_34"]=2,["P71_08"]=0,["P70_16"]=3,["P31_06"]=1,
["P94_23"]=0,["P41_01"]=2,["P71_53"]=1,["P22_12"]=0,["P70_07"]=2,["P30_06"]=0,["P21_10"]=4,["P71_30"]=1,["P31_03"]=0,["P40_10"]=2,
["P31_09"]=1,["P11_04"]=1,["P70_30"]=1,["P61_14"]=2,["P11_13"]=0,["P94_09"]=0,["P31_05"]=0,["P40_03"]=2,["P40_15"]=2,["P11_12"]=2,
["P40_02"]=2,["P21_06"]=3,["P23_04"]=1,["P22_05"]=0,["P31_01"]=0,["P33_03"]=0,["P71_29"]=0,["P20_06"]=0,["P20_18"]=0,["P33_05"]=1,
["P96_01"]=1,["P40_01"]=2,["P91_00"]=0,["P33_01"]=2,["P11_18"]=-1,["P20_07"]=2,["P23_03"]=1,["P70_03"]=2,["P20_04"]=0,["P82_10"]=0,
["P12_09"]=1,["P96_03"]=0,["P21_01"]=3,["P31_16"]=1,["P96_19"]=1,["P96_18"]=1,["P70_27"]=0,["P94_02"]=0,["P96_15"]=0,["P22_01"]=0,
["P10_09"]=0,["P71_51"]=1,["P20_10"]=2,["P11_07"]=2,["P96_12"]=-1,["P96_11"]=-1,["P90_00"]=0,["P70_05"]=0,["P31_13"]=1,["P11_09"]=0,
["P10_07"]=0,["P94_13"]=0,["P20_12"]=-1,["P10_06"]=0,["P60_03"]=2,["P70_20"]=0,["P20_16"]=1,["P20_24"]=2,["P60_15"]=2,["P71_56"]=1,
["P70_28"]=3,["P22_09"]=0,["P10_00"]=0,["P11_01"]=2,["P95_01"]=2,["P96_05"]=0,["P71_40"]=0,["P96_04"]=0,["P96_02"]=1,["P96_00"]=2,
["P12_01"]=2,["P95_03"]=3,["P95_02"]=2,["P40_18"]=2,["P23_05"]=1,["P94_25"]=0,["P41_07"]=2,["P61_09"]=4,["P70_25"]=1,["P14_12"]=0,
["P94_19"]=3,["P13_01"]=0,["P61_05"]=0,["P60_11"]=0,["P60_09"]=1,["P40_07"]=2,["P14_05"]=0,["P94_24"]=0,["P14_01"]=0,["P40_00"]=2,
["P96_13"]=-1,["P94_21"]=0,["P11_06"]=1,["P70_15"]=3,["P22_10"]=0,["P20_22"]=2,["P94_18"]=0,["P63_00"]=0,["P21_02"]=3,["P94_16"]=0,
["P94_17"]=0,["P81_01"]=0,["P71_05"]=0,["P12_04"]=1,["P94_15"]=1,["P94_14"]=1,["P71_07"]=0,["P94_12"]=0,["P71_09"]=1,["P31_07"]=1,
["P71_03"]=2,["P94_11"]=0,["P94_10"]=0,["P31_15"]=1,["P94_08"]=3,["P94_07"]=0,["P30_07"]=0,["P70_09"]=-1,["P00_02"]=0,["P91_04"]=0,
["P50_00"]=0,["P10_04"]=0,["P70_21"]=0,["P40_16"]=2,["P94_05"]=0,["P94_04"]=2,["P94_01"]=1,["P94_00"]=0,["P93_06"]=0,["P93_05"]=1,
["P93_04"]=1,["P11_02"]=1,["P70_22"]=0,["P61_03"]=1,["P93_02"]=0,["P00_01"]=0,["P96_06"]=0,["P93_00"]=0,["P61_13"]=0,["P41_09"]=2,
["P32_02"]=2,["P32_00"]=0,["P11_14"]=1,["P92_00"]=0,["P71_57"]=2,["P91_07"]=0,["P41_12"]=2,["P60_13"]=2,["P91_06"]=0,["P91_05"]=0,
["P94_06"]=0,["P60_00"]=2,["P40_20"]=2,["P70_12"]=3,["P91_03"]=0,["P71_21"]=1,["P31_14"]=1,["P40_21"]=0,["P91_01"]=0,["P96_09"]=-1
}
local parameter_RealValue1 = {
["P14_03"]=0,["P70_02"]=2,["P14_14"]=2,["P61_01"]=2,["P41_02"]=2,["P82_08"]=0,["P40_19"]=2,["P60_04"]=0,["P40_08"]=2,["P70_18"]=0,
["P62_01"]=0,["P71_13"]=3,["P82_07"]=0,["P82_06"]=0,["P82_05"]=0,["P71_26"]=0,["P62_02"]=2,["P71_44"]=2,["P70_13"]=1,["P31_12"]=1,
["P71_20"]=1,["P21_00"]=0,["P70_00"]=2,["P71_27"]=0,["P22_14"]=2,["P82_03"]=0,["P12_07"]=0,["P60_12"]=2,["P71_42"]=1,["P70_33"]=2,
["P60_02"]=2,["P82_00"]=0,["P81_07"]=0,["P41_08"]=2,["P31_04"]=0,["P12_06"]=0,["P81_05"]=-1,["P31_02"]=0,["P81_04"]=0,["P71_60"]=1,
["P70_23"]=0,["P20_01"]=2,["P12_02"]=1,["P81_00"]=0,["P80_00"]=0,["P71_64"]=2,["P71_62"]=0,["P22_03"]=0,["P31_23"]=2,["P20_17"]=2,
["P70_08"]=0,["P71_61"]=1,["P81_03"]=-1,["P70_29"]=4,["P11_08"]=0,["P71_58"]=0,["P96_08"]=3,["P61_02"]=2,["P71_55"]=1,["P31_20"]=1,
["P00_00"]=0,["P71_54"]=1,["P11_16"]=-1,["P40_17"]=2,["P20_21"]=2,["P32_09"]=1,["P70_14"]=0,["P71_49"]=2,["P71_48"]=2,["P71_47"]=2,
["P60_08"]=2,["P71_46"]=-1,["P30_01"]=0,["P40_04"]=2,["P14_09"]=0,["P71_43"]=0,["P82_01"]=0,["P10_05"]=0,["P41_00"]=2,["P71_38"]=2,
["P71_37"]=1,["P71_35"]=1,["P10_01"]=0,["P71_32"]=0,["P71_15"]=-1,["P71_31"]=0,["P71_28"]=0,["P71_25"]=0,["P40_11"]=2,["P71_23"]=0,
["P82_04"]=0,["P71_22"]=2,["P71_19"]=1,["P22_08"]=0,["P23_01"]=3,["P71_17"]=1,["P71_16"]=0,["P11_19"]=1,["P21_08"]=4,["P71_14"]=3,
["P71_12"]=2,["P71_41"]=0,["P20_05"]=0,["P71_10"]=2,["P41_04"]=2,["P71_04"]=1,["P10_08"]=0,["P71_02"]=2,["P71_01"]=2,["P11_10"]=2,
["P71_00"]=2,["P60_10"]=2,["P70_31"]=0,["P96_17"]=0,["P11_00"]=0,["P61_10"]=2,["P70_19"]=0,["P70_24"]=2,["P32_04"]=0,["P81_02"]=0,
["P70_17"]=1,["P71_50"]=2,["P30_02"]=0,["P14_02"]=2,["P70_11"]=3,["P11_20"]=1,["P70_10"]=0,["P14_00"]=0,["P31_21"]=2,["P32_05"]=3,
["P70_04"]=0,["P70_01"]=2,["P63_04"]=1,["P63_02"]=-1,["P63_01"]=1,["P20_23"]=0,["P31_25"]=0,["P71_24"]=1,["P21_04"]=4,["P11_03"]=1,
["P40_09"]=2,["P14_07"]=0,["P11_05"]=1,["P61_07"]=1,["P62_00"]=1,["P41_14"]=2,["P61_15"]=0,["P41_11"]=2,["P71_33"]=1,["P61_12"]=2,
["P70_26"]=0,["P81_06"]=-1,["P20_26"]=-1,["P71_59"]=4,["P22_13"]=0,["P30_00"]=0,["P20_14"]=0,["P20_02"]=1,["P32_03"]=1,["P61_04"]=-1,
["P94_22"]=0,["P93_03"]=0,["P60_01"]=0,["P61_00"]=2,["P13_00"]=0,["P60_14"]=0,["P31_19"]=-1,["P14_10"]=2,["P20_11"]=0,["P30_08"]=0,
["P70_35"]=0,["P12_00"]=0,["P62_03"]=2,["P11_17"]=2,["P50_01"]=0,["P71_11"]=-1,["P14_08"]=2,["P20_19"]=0,["P10_10"]=0,["P95_00"]=2,
["P31_00"]=0,["P41_13"]=2,["P12_03"]=2,["P32_08"]=2,["P71_06"]=1,["P41_03"]=2,["P20_25"]=0,["P93_01"]=0,["P10_02"]=0,["P32_07"]=0,
["P11_21"]=1,["P33_04"]=2,["P31_08"]=1,["P70_06"]=0,["P10_03"]=0,["P30_04"]=0,["P33_07"]=0,["P20_20"]=0,["P21_07"]=3,["P71_52"]=1,
["P40_14"]=2,["P40_13"]=2,["P23_06"]=1,["P20_08"]=2,["P40_12"]=2,["P20_00"]=0,["P82_02"]=0,["P12_08"]=2,["P20_13"]=-1,["P33_06"]=0,
["P22_02"]=0,["P22_06"]=0,["P14_13"]=2,["P61_11"]=2,["P31_22"]=2,["P33_00"]=0,["P32_06"]=0,["P61_06"]=1,["P20_27"]=0,["P32_11"]=3,
["P22_07"]=0,["P91_02"]=0,["P71_18"]=1,["P61_08"]=2,["P60_06"]=2,["P94_20"]=0,["P23_02"]=-1,["P14_04"]=2,["P12_10"]=0,["P82_09"]=0
}

local fault_cmds = {}
local faultcmds = {
    [1] = "code",
    [2] = "real_speed",
    [3] = "given_speed",
    [4] = "bus_voltage",
    [5] = "current"
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

      local func = getnumber(10)
      if func == 1 then
          packet[ cmds[3] ] = 'func-status'
          FCS_Value = bit.lshift( getnumber(44) , 8 ) + getnumber(45)
          for i=1,16,1 do        
            packet[ status_cmds[i] ] = bit.lshift( getnumber(10+i*2) , 8 ) + getnumber(11+i*2)
          end
    	    packet[ status_cmds[1] ] = ( bit.lshift( getnumber(12) , 8 ) + getnumber(13) ) / 100
    	    packet[ status_cmds[2] ] = ( bit.lshift( getnumber(14) , 8 ) + getnumber(15) ) / 100
    	    packet[ status_cmds[5] ] = ( bit.lshift( getnumber(20) , 8 ) + getnumber(21) ) / 10
    	    packet[ status_cmds[7] ] = ( bit.lshift( getnumber(24) , 8 ) + getnumber(25) ) / 1000  
    	    packet[ status_cmds[8] ] = ( bit.lshift( getnumber(26) , 8 ) + getnumber(27) ) / 1000  
            packet[ status_cmds[9] ] = ( bit.lshift( getnumber(28) , 8 ) + getnumber(29) ) / 1000
            packet[ status_cmds[16] ] = ( bit.lshift( getnumber(42) , 8 ) + getnumber(43) ) / 10

		
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
		
          for i=1,43,1 do        
            table.insert(FCS_Array,getnumber(i))
          end
          
        else if func == 2 then
          packet[ cmds[3] ] = 'func-fault'
          FCS_Value = bit.lshift( getnumber(92) , 8 ) + getnumber(93)
          for i=1,40,1 do
      	    local x = i % 5
      	    if x == 2 or x == 3 then
                    packet[ fault_cmds[i] ] = ( bit.lshift( getnumber(10+i*2) , 8 ) + getnumber(11+i*2) ) / 100
      	    else
      	      packet[ fault_cmds[i] ] = bit.lshift( getnumber(10+i*2) , 8 ) + getnumber(11+i*2)
      	    end
          end
          for i=1,91,1 do        
            table.insert(FCS_Array,getnumber(i))
          end

        else
          packet[ cmds[3] ] = 'func-parameter'
          FCS_Value = bit.lshift( getnumber(912) , 8 ) + getnumber(913)
          for i=1,450,1 do 
      	    local temp = 0
            if parameter_RealValue0[ parameter_cmds[i] ] ~= nil then
              temp = parameter_RealValue0[ parameter_cmds[i] ]
            else
              temp = parameter_RealValue1[ parameter_cmds[i] ]
            end
      	    if temp ~= -1 then
              local paranum = ( bit.lshift( getnumber(10+i*2) , 8 ) + getnumber(11+i*2) ) / ( 10^temp )
              local parastrformat = "%0."..temp.."f"
      	      packet[ parameter_cmds[i] ] = string.format(parastrformat,paranum)
      	    end
          end
          for i=1,911,1 do        
            table.insert(FCS_Array,getnumber(i))
          end

        end
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
