onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix hexadecimal /mp3_tb/rvfi/clk
add wave -noupdate -radix hexadecimal /mp3_tb/rvfi/rst
add wave -noupdate -radix hexadecimal /mp3_tb/rvfi/halt
add wave -noupdate -radix hexadecimal /mp3_tb/rvfi/commit
add wave -noupdate -radix hexadecimal /mp3_tb/rvfi/order
add wave -noupdate -radix hexadecimal /mp3_tb/rvfi/inst
add wave -noupdate -radix hexadecimal /mp3_tb/rvfi/trap
add wave -noupdate -radix hexadecimal /mp3_tb/rvfi/rs1_addr
add wave -noupdate -radix hexadecimal /mp3_tb/rvfi/rs2_addr
add wave -noupdate -radix hexadecimal /mp3_tb/rvfi/rs1_rdata
add wave -noupdate -radix hexadecimal /mp3_tb/rvfi/rs2_rdata
add wave -noupdate -radix hexadecimal /mp3_tb/rvfi/load_regfile
add wave -noupdate -radix hexadecimal /mp3_tb/rvfi/rd_addr
add wave -noupdate -radix hexadecimal /mp3_tb/rvfi/rd_wdata
add wave -noupdate -radix hexadecimal /mp3_tb/rvfi/pc_rdata
add wave -noupdate -radix hexadecimal /mp3_tb/rvfi/pc_wdata
add wave -noupdate /mp3_tb/mem_addr
add wave -noupdate /mp3_tb/stall_flag
add wave -noupdate -radix hexadecimal /mp3_tb/rvfi/mem_addr
add wave -noupdate -radix hexadecimal /mp3_tb/rvfi/mem_rmask
add wave -noupdate -radix hexadecimal /mp3_tb/rvfi/mem_wmask
add wave -noupdate -radix hexadecimal /mp3_tb/rvfi/mem_rdata
add wave -noupdate -radix hexadecimal /mp3_tb/rvfi/mem_wdata
add wave -noupdate -radix hexadecimal /mp3_tb/rvfi/errcode
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3311089 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 196
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {2509600 ps} {4957390 ps}
