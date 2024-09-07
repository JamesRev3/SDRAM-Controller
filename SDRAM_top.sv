`timescale 1ns / 1ps


module SDRAM_top(
// inputs are from the CPU
input [19:1] address_from_CPU,
input CLK, RDY, RST_N,
input [1:0] BE_N,
input locked,
input [2:0] state_n,

input MRDC_N, MWTC_N, IORC_N, IORD_N,
// data is coming from and going to the uP
inout [15:0] sdram_data,

// outputs from the controller to the memory
output [11:0] address_to_SD,
output [1:0]bank,
output DQM, SDRAM_CLK,
// command signals
output reg CS_N, RAS_N, CAS_N, WE_N, CKE
    );
    // command will be a function of the state
    // BL = 4
    // A11,A9-0 will have address bits
    // A10 will contain precharge, auto or manual
    // what will be on data lines
    // we are going to have 4 bursts that contain the data
    // they all must be latched
    // latched as a function of the state
    // gates^
    // all signals will have output enables
    // 4 bit memory to provide 16 bits of memory
    
    // DQM bit
    // do I want to read it or not?
    // on transfer level, like a byte enable
    // DQ Mask
    // DQM starts with column address
    // do I want to mask or not
    // BE0 is driving these signals d3-0, d7-4
    // BE1 is driving d11-8, d15-12
    // determines if valid and aligned with column address
    // last piece of it
    // if only want to read lower byte
    // 
    
    
    // reading is delayed by cas latency
    // write occurs at the same time
    // DQM will be driven by a mux
    // 
    
    // state before active is idle
    // 
    
    // how do we let the uP know we are ready?
    // when done with read/write
    // will need a ready signal
    // 
    
    // column addres concatenated with 00
    // 4 bits
    // 
    
    // chip needs a column and a row
    // 4 nibbles in a burst length
    // 512 kiB
    // that means what?
    // only reach 512 kiB
    // 1048 kib
    // most are coded as 0
    // 64 mib
    
    // 00 because that will give us a word?
    // 
    
    
    
    reg[31:0] WaitCounter;
    reg[31:0] RefreshCounter;
    
    parameter WaitCycles = 10000;
    parameter RefreshCycles = 1500;
    
    reg[5:0] state;
    
    parameter WaitCLK = 6'd0;
    parameter Wait100 = 6'd1;
    parameter Precharge_S = 6'd2;
    parameter Auto1 = 6'd3;
    parameter Auto2 = 6'd4;
    parameter LMR = 6'd5;
    parameter IDLE = 6'd6;
    parameter NOP1 = 6'd7;
    parameter NOP2 = 6'd8;
    parameter NOP3 = 6'd9;
    parameter NOP4 = 6'd10;
    parameter NOP5 = 6'd11;
    parameter NOP6 = 6'd12;
    parameter NOP7 = 6'd13;
    parameter NOP8 = 6'd14;
    parameter NOP9 = 6'd15;
    parameter NOP10 = 6'd16;
    parameter NOP11 = 6'd17;
    parameter NOP12 = 6'd17;
    parameter NOP13 = 6'd18;
    parameter AutoRefresh = 6'd19;
    parameter Read = 6'd20;
    parameter Write = 6'd21;
    
    // operating state parameters
    parameter Refresh_NOP1 = 6'd22;
    parameter Refresh_NOP2 = 6'd23;
    parameter Refresh_NOP3 = 6'd24;
    parameter Refresh_NOP4 = 6'd25;
    parameter Refresh_NOP5 = 6'd26;
    parameter Refresh_NOP6 = 6'd27;
    
    parameter Read_NOP_2 = 6'd28;
    parameter Read_CMD_3 = 6'd29;
    parameter Read_NOP_4 = 6'd30;
    parameter Read_NOP_5 = 6'd31;
    parameter Read_NOP_6 = 6'd32;
    parameter Read_NOP_7 = 6'd33;
    parameter Read_NOP_8 = 6'd34;
    
    parameter Write_NOP_2 = 6'd35;
    parameter Write_CMD_3 = 6'd36;
    parameter Write_NOP_4 = 6'd37;
    parameter Write_NOP_5 = 6'd38;
    parameter Write_NOP_6 = 6'd39;
    parameter Write_NOP_7 = 6'd40;
    parameter Write_NOP_8 = 6'd41;
    
    // Initialization Load Mode Register Parameters
    // ------------------------------- Load Mode Register ---------------------------------------- |
    // A[11:10] | A[9]             | A[8:7]         | A[6:4]          | A[3]       | A[2:0]        |
    // 00       | 0                | 00             | 010             | 0          | 010           |
    // N/A      | Programmed Write | Normal         | CAS = 2 cycles  | Sequential | BL = 4 cycles |
    // Reserved | Write_Burst_Mode | Operating_Mode | CAS_Latency     | Burst_Type | Burst_Length  |
    // ------------------------------------------------------------------------------------------- |
    parameter Reserved = 2'b00;  // Reserved
    parameter Write_Burst_Mode  = 1'b0;   // Write Burst Mode (Sequential)
    parameter Operating_Mode = 2'b00;  // Operating Mode (Standard)
    parameter CAS_Latency  = 3'b010; // CAS Latency (2 cycles)
    parameter Burst_Type  = 1'b0;   // Burst Type
    parameter Burst_Length  = 3'b010; // Burst Length (4 cycles)
    
    
    // stuffs
    parameter CPU_CODE = 3'b100;
    parameter CPU_READ = 3'b101;
    parameter CPU_WRITE = 3'b110;
    

    
    // These are the actual data bits of whatever we are reading/writing
    parameter Read_Data_1 = Read_NOP_5;
    parameter Read_Data_2 = Read_NOP_6;
    parameter Read_Data_3 = Read_NOP_7;
    parameter Read_Data_4 = Read_NOP_8;
    
    parameter Write_Data_1 = Write_CMD_3;
    parameter Write_Data_2 = Write_NOP_4;
    parameter Write_Data_3 = Write_NOP_5;
    parameter Write_Data_4 = Write_NOP_6;
    
    //DQM Bits ---------------------------------------------------------------------------------------------------------
    // DQM bit
    // do I want to read it or not?
    // on transfer level, like a byte enable
    // DQ Mask
    // DQM starts with column address
    // do I want to mask or not
    // BE0 is driving these signals d3-0, d7-4
    // BE1 is driving d11-8, d15-12
    // determines if valid and aligned with column address
    // last piece of it
    // if only want to read lower byte
    // 
    parameter Read_DQM_1 = Read_CMD_3;
    parameter Read_DQM_2 = Read_NOP_4;
    parameter Read_DQM_3 = Read_NOP_5;
    parameter Read_DQM_4 = Read_NOP_6;
    
    parameter Write_DQM_1 = Write_CMD_3;
    parameter Write_DQM_2 = Write_NOP_4;
    parameter Write_DQM_3 = Write_NOP_5;
    parameter Write_DQM_4 = Write_NOP_6;
    
    
    reg [2:0] state_n_q;
    reg [2:0] state_n_qq;
    wire pending_access = (state_n_qq == CPU_CODE || state_n_qq == CPU_READ || state_n_qq == CPU_WRITE);

    
    always @ (negedge SDRAM_CLK) begin
        state_n_q <= state_n;
        state_n_qq <= state_n_qq;
    end
    
      
    wire done = (WaitCounter == 32'd0);
    wire refresh_request = (RefreshCounter == 16'd0);
    wire refresh_grant = (state = AutoRefresh);
    
    // refresh timer
    always @ (negedge SDRAM_CLK) begin
        if (!RST_N || state == AutoRefresh)
            RefreshCounter <= RefreshCycles;
        else if(RefreshCounter!=0)
            RefreshCounter <= RefreshCounter - 32'd1;
        else
            RefreshCounter <= RefreshCounter;
    end
    
    // ready signals----------------------------------------------
    
    reg MRDC_N_Q;
    reg MRDC_N_QQ;
    reg MRDC_N_QQQ;
    
    reg MWTC_N_Q;
    reg MWTC_N_QQ;
    reg MWTC_N_QQQ;
    
    wire read_request = ~MRDC_N_QQ && MRDC_N_QQQ;
    wire write_request = ~MWTC_N_QQ && MWTC_N_QQQ;
    
    always @ (negedge SDRAM_CLK) begin
        MRDC_N_Q <= MRDC_N;
        MRDC_N_QQ <= MRDC_N_Q;
        MRDC_N_QQQ <= MRDC_N_QQ;
    
        MWTC_N_Q <= MWTC_N;
        MWTC_N_QQ <= MWTC_N_Q;
        MWTC_N_QQQ <= MWTC_N_QQ;
    end
    
    
    reg [19:1] address_reg; // byte 0 is a load enable??
    
    always @(negedge SDRAM_CLK) begin
        if(!RST_N)
            address_reg <= 19'b0;
        else if(state == IDLE &&(read_request || write_request))
            address_reg <= address_from_CPU[19:1];
        else
            address_reg <= address_reg;
    end
        
        
    
    // refresh_req refreshes same amount as the test
    // why does it need to be latched
    // what if in a multi byte read, if no idle 
    
    
    // there is a command to send out the refresh
    // 
    
    // what if read write and precharge are all pending?
    // refresh_req && !read && !write
    
    
    // (CS_N == 0 && RAS_N == 0 &&
    //      CAS_N == 1 && WE_N == 0)
    
    
    reg [1:0] BE_N_q;
    reg [1:0] BE_N_qq;
    reg [1:0] BE_N_reg;
    
    // doesn't hurt to have
    always @ (negedge SDRAM_CLK) begin
        BE_N_q <= BE_N;
        BE_N_qq <= BE_N_q;
    end
    
    // doesn't hurt to have
    always @ (negedge SDRAM_CLK) begin
        if(!RST_N)
            BE_N_reg <= 2'b11;
        else if (state == IDLE && (read_request || write_request))
            BE_N_reg <= BE_N_qq;
        else
            BE_N_reg <= BE_N_reg;
    end
    
    
    // Data Read Register ------------------------------------------------------------------
    reg [15:0] Data_Read_Reg;
    
    always @ (negedge SDRAM_CLK) begin
        if (!RST_N)
            Data_Read_Reg <= 16'd0;
        case (state)
            Read_Data_1: Data_Read_Reg[3:0] <= sdram_data;
            Read_Data_2: Data_Read_Reg[7:4] <= sdram_data;
            Read_Data_3: Data_Read_Reg[11:8] <= sdram_data;
            Read_Data_4: Data_Read_Reg[15:12] <= sdram_data;
            default: Data_Read_Reg <= Data_Read_Reg;
        endcase
    end
            
    // Data Write Register ------------------------------------------------------------------
    reg [15:0] Data_Write_q;
    reg [15:0] Data_Write_qq;
    reg [15:0] Data_Write_Reg;
         
    always @ (negedge SDRAM_CLK) begin
        Data_Write_q <= sdram_data;
        Data_Write_qq <= Data_Write_q;
    end
    
    always @ (negedge SDRAM_CLK) begin
        if (!RST_N)
            Data_Write_Reg <= 16'd0;
        else if(state == IDLE && write_request)
            Data_Write_Reg <= Data_Write_qq;
        else
            Data_Write_Reg <= Data_Write_Reg;
    end
    
    
    
    // wait 100 us timer -------------------------------------------------------------
    always @ (negedge SDRAM_CLK) begin
        if(RST_N == 0)
            WaitCounter <= WaitCycles;
        else if(WaitCounter!=0 && state!=Wait100)
            WaitCounter <= WaitCounter - 32'd1;  
        else
            WaitCounter <= WaitCounter;
        end
    
    
// Transition logic ------------------------------------------------------------
    always @ (negedge SDRAM_CLK) begin
        if(RST_N == 0)
            state <= WaitCLK;
        else begin
        case (state)
        // Getting to initialization
            WaitCLK:
                if(locked == 1)
                state <= Wait100;
            Wait100:
                if(done == 1)
                state <= Precharge_S;
            Precharge_S:
                state <= NOP1;
            // TRFC = 66 ns therefore we need 7 nops
            NOP1:
                state <= Auto1;
            Auto1:
                state <= NOP2;
            NOP2:
                state <= NOP3;
            NOP3:
                state <= NOP4;
            NOP4:
                state <= NOP5;
            NOP5:
                state <= NOP6;
            NOP6:               
                state <= Auto2;
            Auto2:
                state <= NOP7;
            NOP7:
                state <= NOP8;
            NOP8:
                state <= NOP9;
            NOP9:
                state <= NOP10;
            NOP10:
                state <= NOP11;
            NOP11:
                state <= NOP12;
            NOP12:
                state <= LMR;
            LMR:
                state <= IDLE;
                
            // at IDLE
            IDLE:
                if(address_from_CPU[19]) state <= IDLE;
                else if (read_request) state <= Read;
                else if (write_request) state <= Write;
                else if (refresh_request && !pending_access) state <= AutoRefresh;
                else state <= IDLE;
                
            // Refresh -----------------------------------    
            AutoRefresh:
                state <= Refresh_NOP1;
            Refresh_NOP1:
                state <= Refresh_NOP2;
            Refresh_NOP2:
                state <= Refresh_NOP3;
            Refresh_NOP3:
                state <= Refresh_NOP4;
            Refresh_NOP4:
                state <= Refresh_NOP5;
            Refresh_NOP5:
                state <= Refresh_NOP6;
            Refresh_NOP6:
                state <= IDLE;
            
            
            // Read ---------------------------------------------    
            Read:                       // Active
                state <= Read_NOP_2; 
            Read_NOP_2:                 // NOP
                state <= Read_NOP_2;
            Read_CMD_3:                 // CMD
                state <= Read_NOP_4;
            Read_NOP_4:                 // NOP
                state <= Read_NOP_5;
            Read_NOP_5:                 // Data 1
                state <= Read_NOP_6;
            Read_NOP_6:                 // Data 2
                state <= Read_NOP_7;
            Read_NOP_7:                 // Data 3 w/ precharge
                state <= Read_NOP_8;
            Read_NOP_8:                 // Data 4
                state <= IDLE;
                
                
                
            // Write -----------------------------------------
            Write:
                state <= Write_NOP_2;
            Write_NOP_2:
                state <= Write_CMD_3;
            Write_CMD_3:
                state <= Write_NOP_4;
            Write_NOP_4:
                state <= Write_NOP_5;
            Write_NOP_5:
                state <= Write_NOP_6;
            Write_NOP_6:
                state <= Write_NOP_7;
            Write_NOP_7:
                state <= Write_NOP_8;
            Write_NOP_8:
                state <= IDLE;
            
                  
            // at the end of every read or write we need to precharge  
            
        endcase   
        end 
        
    end
    // timer counts down for 100us
    // 100us is 10 clks
    //  WE_N, 
    //  RAS_N, 
    //  CAS_N, 
    //  CS_N
    
    // will need to create a new CKE for the mux
    
	
	// output parameters
    parameter Undefined = {12{1'b0}}; // 144 undefined x's
    
    parameter Undefined_CMD = 3'b111;
    parameter NOP_CMD = 3'b111;
    parameter Precharge_CMD = 3'b010;
    parameter Refresh_CMD = 3'b001;
    parameter LoadModeRegister_CMD = 3'b000;
    parameter Active_CMD = 3'b011;
    parameter Read_CMD = 3'b101;
    parameter Write_CMD = 3'b100;
	
	
    
    // Output logic ------------------------------------------------
    
    reg [2:0] command;
    reg [11:0] address;
    
    
     always @ (*) begin
        case (state)
            WaitCLK: 
                begin command = Undefined_CMD; address = Undefined; end
            Wait100:
                begin command = NOP_CMD; address = Undefined; end 
            Precharge_S:
                begin command = Precharge_CMD; address = Undefined; end
            Auto1:
                begin command = Refresh_CMD; address = Undefined; end
            Auto2:
                begin command = Refresh_CMD; address = Undefined; end
            LMR:
                begin
                    command = LoadModeRegister_CMD;
                    address[11:10] = Reserved;
                    address[9] = Write_Burst_Mode;
                    address[8:7] = Operating_Mode;
                    address[6:4] = CAS_Latency;
                    address[3] = Burst_Type;
                    address[2:0] = Burst_Length;
                end

            // at IDLE
            IDLE:
                begin command = NOP_CMD; address = Undefined; end
            AutoRefresh:
                begin command = Refresh_CMD; address = Undefined; end
                
                
            Read:
                begin
                    command = Active_CMD;
                    address[11:10] = 2'b00;
                    address[9:0] = address_reg[18:9];
                end
            Read_CMD_3:
                begin
                    command = Read_CMD;
                    address[11] = 1'bx;
                    address[10] = 1'b1;
                    address[9] = {address_reg[8:1], 2'b00};
                end
            Write:
                begin
                    command = Active_CMD;
                    address[11:10] = 2'b00;
                    address[9:0] = address_reg[18:9];
                end
            Write_CMD_3:
                begin
                    command = Write_CMD;
                    address[11] = 1'bx;
                    address[10] = 1'b1;
                    address[9] = {address_reg[8:1], 2'b00};
                end
                
            default: begin command = NOP_CMD; address = Undefined; end
            // at the end of every read or write we need to precharge   
        endcase   
    end
    
    assign data = (state == IDLE) ? Data_Read_Reg : {16{1'bz}};
    assign ready = (state == IDLE);
    
    assign sdram_cke = (state != WaitCLK);
    assign sdram_data = (state == Write_Data_1) ? Data_Write_Reg[3:0]
        : (state == Write_Data_2) ? Data_Write_Reg[7:4]
		: (state == Write_Data_3) ? Data_Write_Reg[11:8]
		: (state == Write_Data_4) ? Data_Write_Reg[15:12]
		: 4'bzzzz;

    assign sdram_dqm = (state == Read_DQM_1 || state == Write_DQM_1) ? BE_N_reg[0]
		: (state == Read_DQM_2 || state == Write_DQM_2) ? BE_N_reg[0]
		: (state == Read_DQM_3 || state == Write_DQM_3) ? BE_N_reg[1]
		: (state == Read_DQM_4 || state == Write_DQM_4) ? BE_N_reg[1]
        : 1'b0;
                
    assign sdram_cs_n = address_reg[19];
    assign sdram_ras_n = command[2];
    assign sdram_cas_n = command[1];
    assign sdram_we_n = command[0];
    assign sdram_addr = address; 
    
endmodule
