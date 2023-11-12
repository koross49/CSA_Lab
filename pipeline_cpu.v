`timescale 1ns / 1ps

module pipeline_cpu(  // 多周期cpu
    input clk,           // 时钟
    input resetn,        // 复位信号，低电平有效
    
    //display data
    input  [ 4:0] rf_addr,
    input  [31:0] mem_addr,
    output [31:0] rf_data,
    output [31:0] mem_data,
    output [31:0] IF_pc,
    output [31:0] IF_inst,
    output [31:0] ID_pc,
    output [31:0] EXE_pc,
    output [31:0] MEM_pc,
    output [31:0] WB_pc,
    
    //5级流水新增
    output [31:0] cpu_5_valid,
    output [31:0] HI_data,
    output [31:0] LO_data
    );
//------------------------{5级流水控制信号}begin-------------------------//
    //5模块的valid信号
    wire   IF_valid;
    wire   ID_valid;
    wire   EXE_valid;
    wire   MEM_valid;
    wire   WB_valid;
    //5模块执行完成信号,来自各模块的输出
    wire IF_over;
    wire ID_over;
    wire EXE_over;
    wire MEM_over;
    wire WB_over;
    wire cancel;    
   //级间输出
    wire IF_to_ID;
    wire ID_to_EXE;
    wire EXE_to_MEM;
    wire MEM_to_WB;

    wire next_fetch;
    wire MEM_allow_in;

//-------------------------{ctrl实例化}begin---------------------------//
    ctrl CTRL_module(
        .clk(clk),           // 时钟
        .resetn(resetn),        // 复位信号，低电平有效

        .IF_over(IF_over),
        .ID_over(ID_over),
        .EXE_over(EXE_over),
        .MEM_over(MEM_over),
        .WB_over(WB_over),
        .cancel(cancel), 


        //级间总线
        .IF_to_ID(IF_to_ID),
        .ID_to_EXE(ID_to_EXE),
        .EXE_to_MEM(EXE_to_MEM),
        .MEM_to_WB(MEM_to_WB),
        .MEM_allow_in(MEM_allow_in),

        .next_fetch(next_fetch),

        //valid信号
        .IF_valid(IF_valid),
        .ID_valid(ID_valid),
        .EXE_valid(EXE_valid),
        .MEM_valid(MEM_valid),
        .WB_valid(WB_valid),
        
        .cpu_5_valid(cpu_5_valid)
    );
//-------------------------{ctrl实例化}end---------------------------//
 
//-------------------------{5级流水控制信号}end--------------------------//

//--------------------------{5级间的总线}begin---------------------------//
    wire [ 63:0] IF_ID_bus;   // IF->ID级总线
    wire [167:0] ID_EXE_bus;  // ID->EXE级总线
    wire [154:0] EXE_MEM_bus; // EXE->MEM级总线
    wire [118:0] MEM_WB_bus;  // MEM->WB级总线
    
    //锁存以上总线信号
    reg [ 63:0] IF_ID_bus_r;
    reg [167:0] ID_EXE_bus_r;
    reg [154:0] EXE_MEM_bus_r;
    reg [118:0] MEM_WB_bus_r;

    always @(posedge clk)
    begin
        if(IF_to_ID)IF_ID_bus_r <= IF_ID_bus;
        if(ID_to_EXE)ID_EXE_bus_r <= ID_EXE_bus;
        if(EXE_to_MEM) EXE_MEM_bus_r <= EXE_MEM_bus;
        if(MEM_to_WB) MEM_WB_bus_r <= MEM_WB_bus;
    end
    
//---------------------------{5级间的总线}end----------------------------//

//--------------------------{其他交互信号}begin--------------------------//
    //跳转总线
    wire [ 32:0] jbr_bus;    

    //IF与inst_rom交互
    wire [31:0] inst_addr;
    wire [31:0] inst;

    //ID与EXE、MEM、WB交互
    wire [ 4:0] EXE_wdest;
    wire [ 4:0] MEM_wdest;
    wire [ 4:0] WB_wdest;
    
    //旁路新增
    wire        EXE_bypass_en;
    wire [31:0] EXE_rs_value;
    wire        MEM_bypass_en;
    wire [31:0] MEM_rs_value;
    //wire        WB_bypass_en;
    //wire [31:0] WB_rs_value;
    
    
    //MEM与data_ram交互    
    wire [ 3:0] dm_wen;
    wire [31:0] dm_addr;
    wire [31:0] dm_wdata;
    wire [31:0] dm_rdata;

    //ID与regfile交互
    wire [ 4:0] rs;
    wire [ 4:0] rt;   
    wire [31:0] rs_value;
    wire [31:0] rt_value;
    
    //WB与regfile交互
    wire        rf_wen;
    wire [ 4:0] rf_wdest;
    wire [31:0] rf_wdata;    
    
    //WB与IF间的交互信号
    wire [32:0] exc_bus;
//---------------------------{其他交互信号}end---------------------------//

//-------------------------{各模块实例化}begin---------------------------//
    //wire next_fetch; //即将运行取指模块，需要先锁存PC值
    //IF允许进入时，即锁存PC值，取下一条指令
    //assign next_fetch = IF_allow_in;
    fetch IF_module(             // 取指级
        .clk       (clk       ),  // I, 1
        .resetn    (resetn    ),  // I, 1
        .IF_valid  (IF_valid  ),  // I, 1
        .next_fetch(next_fetch),  // I, 1
        .inst      (inst      ),  // I, 32
        .jbr_bus   (jbr_bus   ),  // I, 33
        .inst_addr (inst_addr ),  // O, 32
        .IF_over   (IF_over   ),  // O, 1
        .IF_ID_bus (IF_ID_bus ),  // O, 64
        
        //5级流水新增接口
        .exc_bus   (exc_bus   ),  // I, 32
        
        //展示PC和取出的指令
        .IF_pc     (IF_pc     ),  // O, 32
        .IF_inst   (IF_inst   )   // O, 32
    );

    decode ID_module(               // 译码级
        .ID_valid   (ID_valid   ),  // I, 1
        .IF_ID_bus_r(IF_ID_bus_r),  // I, 64
        .rs_value   (rs_value   ),  // I, 32
        .rt_value   (rt_value   ),  // I, 32
        .rs         (rs         ),  // O, 5
        .rt         (rt         ),  // O, 5
        .jbr_bus    (jbr_bus    ),  // O, 33
//        .inst_jbr   (inst_jbr   ),  // O, 1
        .ID_over    (ID_over    ),  // O, 1
        .ID_EXE_bus (ID_EXE_bus ),  // O, 167
        
        //5级流水新增
        .IF_over     (IF_over     ),// I, 1
        .EXE_wdest   (EXE_wdest   ),// I, 5
        .MEM_wdest   (MEM_wdest   ),// I, 5
        .WB_wdest    (WB_wdest    ),// I, 5
        
        // 旁路相关
        .EXE_over    (EXE_over),
        .MEM_over    (MEM_over),
        .EXE_rs_value(EXE_rs_value),
        .MEM_rs_value(MEM_rs_value),
        .EXE_bypass_en(EXE_bypass_en),
        .MEM_bypass_en(MEM_bypass_en),
        
        //展示PC
        .ID_pc       (ID_pc       ) // O, 32
    ); 

    exe EXE_module(                   // 执行级
        .EXE_valid   (EXE_valid   ),  // I, 1
        .ID_EXE_bus_r(ID_EXE_bus_r),  // I, 167
        .EXE_over    (EXE_over    ),  // O, 1 
        .EXE_MEM_bus (EXE_MEM_bus ),  // O, 154
        
        //5级流水新增
        .clk         (clk         ),  // I, 1
        .EXE_wdest   (EXE_wdest   ),  // O, 5
        
        //旁路新增
        .EXE_rs_value(EXE_rs_value),    //O, 32
        .EXE_bypass_en(EXE_bypass_en),  //I, 1
        
        //展示PC
        .EXE_pc      (EXE_pc      )   // O, 32
    );

    mem MEM_module(                     // 访存级
        .clk          (clk          ),  // I, 1 
        .MEM_valid    (MEM_valid    ),  // I, 1
        .EXE_MEM_bus_r(EXE_MEM_bus_r),  // I, 154
        .dm_rdata     (dm_rdata     ),  // I, 32
        .dm_addr      (dm_addr      ),  // O, 32
        .dm_wen       (dm_wen       ),  // O, 4 
        .dm_wdata     (dm_wdata     ),  // O, 32
        .MEM_over     (MEM_over     ),  // O, 1
        .MEM_WB_bus   (MEM_WB_bus   ),  // O, 118
        
        //5级流水新增接口
        .MEM_allow_in (MEM_allow_in ),  // I, 1
        .MEM_wdest    (MEM_wdest    ),  // O, 5
        
        //旁路新增
        .MEM_rs_value(MEM_rs_value),    //O, 32
        .MEM_bypass_en(MEM_bypass_en),  //I, 1
        
        //展示PC
        .MEM_pc       (MEM_pc       )   // O, 32
    );          
 
    wb WB_module(                     // 写回级
        .WB_valid    (WB_valid    ),  // I, 1
        .MEM_WB_bus_r(MEM_WB_bus_r),  // I, 118
        .rf_wen      (rf_wen      ),  // O, 1
        .rf_wdest    (rf_wdest    ),  // O, 5
        .rf_wdata    (rf_wdata    ),  // O, 32
          .WB_over     (WB_over     ),  // O, 1
        
        //5级流水新增接口
        .clk         (clk         ),  // I, 1
      .resetn      (resetn      ),  // I, 1
        .exc_bus     (exc_bus     ),  // O, 32
        .WB_wdest    (WB_wdest    ),  // O, 5
        .cancel      (cancel      ),  // O, 1
        
        
        //展示PC和HI/LO值
        .WB_pc       (WB_pc       ),  // O, 32
        .HI_data     (HI_data     ),  // O, 32
        .LO_data     (LO_data     )   // O, 32
    );

    inst_rom inst_rom_module(         // 指令存储器
        .clka       (clk           ),  // I, 1 ,时钟
        .addra      (inst_addr[9:2]),  // I, 8 ,指令地址
        .douta      (inst          )   // O, 32,指令
    );

    regfile rf_module(        // 寄存器堆模块
        .clk    (clk      ),  // I, 1
        .wen    (rf_wen   ),  // I, 1
        .raddr1 (rs       ),  // I, 5
        .raddr2 (rt       ),  // I, 5
        .waddr  (rf_wdest ),  // I, 5
        .wdata  (rf_wdata ),  // I, 32
        .rdata1 (rs_value ),  // O, 32
        .rdata2 (rt_value ),  // O, 32

        //display rf
        .test_addr(rf_addr),  // I, 5
        .test_data(rf_data)   // O, 32
    );
    
    data_ram data_ram_module(   // 数据存储模块
        .clka   (clk         ),  // I, 1,  时钟
        .wea    (dm_wen      ),  // I, 1,  写使能
        .addra  (dm_addr[9:2]),  // I, 8,  读地址
        .dina   (dm_wdata    ),  // I, 32, 写数据
        .douta  (dm_rdata    ),  // O, 32, 读数据

        //display mem
        .clkb   (clk          ),  // I, 1,  时钟
        .web    (4'd0         ),  // 不使用端口2的写功能
        .addrb  (mem_addr[9:2]),  // I, 8,  读地址
        .doutb  (mem_data     ),  // I, 32, 写数据
        .dinb   (32'd0        )   // 不使用端口2的写功能
    );
//--------------------------{各模块实例化}end----------------------------//
endmodule