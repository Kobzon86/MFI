//! Модуль, конвертирующий 4 пикселя RGB, в 4 пикселя RGBA
//! { signal: [
//!   ['sink',
//!     {  name: 'ready',       wave: '1........'},
//!     {  name: 'valid',       wave: '01......0'},
//!     {  name: 'sop',         wave: '010......'},
//!    	{  name: 'eop',         wave: '0......10'},
//!    	{  name: 'empty[3:0]', 	wave: 'x3......x', data: 'empty[3:0]'},
//!    	{  name: 'data[95:0]',  wave: 'x4......x', data: 'data[95:0]'},
//!   ],
//!   {},
//!   ['source',
//!     {  name: 'ready',       wave: '1........'},
//!     {  name: 'valid',       wave: '01......0'},
//!     {  name: 'sop',         wave: '010......'},
//!    	{  name: 'eop',         wave: '0......10'},
//!    	{  name: 'empty[3:0]', 	wave: 'x3......x', data: 'empty[3:0]'},
//!    	{  name: 'data[127:0]',  wave: 'x4......x', data: 'data[127:0]'},
//!   ]
//! ]} 
module conv_6to8 ( 
  input         reset_n,  //! Don't used
  input         clk,      //! Don't used
  
  output        sink_ready, //!
  input         sink_valid, //!
  input         sink_sop,   //!
  input         sink_eop,   //!
  input   [3:0] sink_empty, //!
  input  [95:0] sink_data,  //!
  
  input         source_ready,
  output        source_valid,
  output        source_sop,
  output        source_eop,
  output  [3:0] source_empty,
  output [127:0] source_data
  
);

assign sink_ready   = source_ready;
assign source_valid = sink_valid;
assign source_sop   = sink_sop;
assign source_eop   = sink_eop;
assign source_empty = sink_empty;
assign source_data  = { sink_data[95:90], sink_data[95:94],
                        sink_data[89:84], sink_data[89:88],
                        sink_data[83:78], sink_data[83:82],
                        sink_data[77:72], sink_data[77:76],

                        sink_data[71:66], sink_data[71:70],
                        sink_data[65:60], sink_data[65:64],
                        sink_data[59:54], sink_data[59:58],
                        sink_data[53:48], sink_data[53:52],

                        sink_data[47:42], sink_data[47:46],
                        sink_data[41:36], sink_data[41:40],
                        sink_data[35:30], sink_data[35:34],
                        sink_data[29:24], sink_data[29:28],

                        sink_data[23:18], sink_data[23:22],
                        sink_data[17:12], sink_data[17:16],
                        sink_data[11:6],  sink_data[11:10],
                        sink_data[5:0],   sink_data[5:4] };



endmodule
