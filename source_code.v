module DigitalClock_12hrFormat(
    input clk,       //system clock
    input center,    //center button of fpga board
    input right,     //right button of fpga board
    input left,      //left button of fpga board
    input up,        //up button of fpga board
    input down,      //down button of fpga board 
    input M_00,      // 0th bit of alarm time minute-ones input  // toggle buttons are used to set the alarm time
    input M_01,      // 1st bit of alarm time minute-ones input
    input M_02,      // 2nd bit of alarm time minute-ones input
    input M_03,      // 3rd bit of alarm time minute-ones input
    input M_10,      // 0th bit of alarm time minute-tens input
    input M_11,      // 1st bit of alarm time minute-tens input
    input M_12,      // 2nd bit of alarm time minute-tens input
    input H_00,      // 0th bit of alarm time hour-ones input
    input H_01,      // 1st bit of alarm time hour-ones input
    input H_02,      // 2nd bit of alarm time hour-ones input
    input H_10,      // 0th bit of alarm time hour-tens input
    input H_11,      // 1st bit of alarm time hour-tens input
    output [6:0] seg, //output to the seven segment display module
    output [3:0] an,  // enabler for the 4 seven segment display boxes 
    output AMPM_indicator_led,  
    output clock_mode_indicator_led,
    output Alarm1,  // alarm leds 
    output Alarm2,
    output Alarm3,
    output Alarm4,
    output Alarm5,
    input stop     // stop button
);
 
    reg [31:0] counter = 0;        // upade after every max_count used to set clock update time 
    parameter max_count = 25_000_000;  
    reg [3:0] H_in1;               // the tens place number in hour
    reg [3:0] H_in0;              //the ones place number in hour 
    reg [3:0] M_in1;                   // the tens place number in minute
    reg [3:0] M_in0;               // the ones place number in minute
    always @(*)begin
    H_in1=H_10+H_11*2;
        H_in0=H_00+H_01*2+H_02*4;
        M_in1=M_10+M_11*2+M_12*4;
        M_in0=M_00+M_01*2+M_02*4+M_03*8;
   
    end
    reg [5:0] hrs,min,sec = 0;    // registers to store hours,mins and seconds
    reg [3:0] min_ones, min_tens, hrs_ones, hrs_tens = 0;  //the output registers to the seven segment display

    reg toggle = 0;  //0 min 1 hour  // toggled when we press the left or right key // initially 0 (set-time mode) 1(clock-mode)

    reg x=0;    // alarm indicator 0 means off initially 
   
assign Alarm1 = x;
assign Alarm2 = x;
assign Alarm3 = x;
assign Alarm4 = x;
assign Alarm5 = x;



always @(*)
begin
if(stop)
x<=0;
if({H_in1,H_in0,M_in1,M_in0}=={hrs_tens,hrs_ones,min_tens,min_ones})
begin
if(stop==0)    // stop button to stop the alarm
  x<=1;    //alarm on
  else
  x<=0;
end
end


    reg pm = 0;    // am pm indicator 0 means pm and 1 means am 
    assign AMPM_indicator_led = pm;   // by default 0

    reg clock_mode = 0;    // clock_mode indicator
    assign clock_mode_indicator_led = clock_mode;

    seven_segment SSM(clk,min_ones,min_tens,hrs_ones,hrs_tens,seg,an);
// parameters are equivalent to the constants
    parameter display_time = 1'b0;
    parameter set_time = 1'b1;
    reg current_mode = set_time;   // by defalut set time mode 
// invoked at every positive edge of the clock
    always @(posedge clk)
    begin
         case(current_mode)
         display_time:
       begin
          if (center)
          begin
            clock_mode <= 0;
            current_mode <= set_time;
            counter <= 0;
            toggle <= 0;
            sec <= 0;
          end

           if (counter < max_count)
           begin
             counter <= counter + 1;
           end
          else
           begin
               counter <= 0;
               sec <= sec + 1;
           end
     
        end


         set_time:
         begin
           if (center) begin
           clock_mode <= 1;
           current_mode <= display_time;
           end

           if (counter < (12_500_000)) begin
           counter <= counter + 1;
           end
           else begin
           counter <= 0;
           case (toggle)
           1'b0:
           begin
              if(up) begin
              min <= min + 1;
           end
   
    if (down) begin
      if (min > 0) begin
    min <= min - 1;
    end
    else if (hrs > 1) begin
    hrs <= hrs - 1;
    min <= 59;
    end else if (hrs == 1) begin
    hrs <=  12;
    min <= 59;
    end
    end

    if (left || right ) begin
     toggle <= 1;
     end
     end

     1'b1 : begin
     if (up) begin
     hrs <= hrs + 1;
     end
     if (down) begin
     if(hrs > 1) begin
     hrs <= hrs - 1;
     end else if (hrs == 1) begin
     hrs <=  12;
     end
     end
     
     if (right || left ) begin
     toggle <= 0;
     end
     end
     endcase
     end
     end
     endcase

      if (sec >= 60) begin
      sec <= 0;
      min <= min + 1;
      end

      if (min >= 60) begin
      min <= 0;
      hrs <= hrs + 1;
      end
      if (hrs >=  24) begin
      hrs <= 0;
      end

      else begin
      min_ones <= min % 10;
      min_tens <= min / 10;
      if (hrs < 12) begin
      if (hrs == 0) begin
      hrs_ones <= 2;
      hrs_tens <= 1;
      end else begin
      hrs_ones <= hrs % 10;
      hrs_tens <= hrs / 10;
      end
      pm <= 0;
      end else begin
      if (hrs == 12) begin
      hrs_ones <= 2;
      hrs_tens <= 1;
      end else begin
      hrs_ones <= (hrs - 12) % 10;
      hrs_tens <= (hrs - 12) / 10;
      end
      pm <= 1;
      end
      end
      end


      endmodule






module seven_segment(input clk,
input [3:0] min_ones,//0-9   
input [3:0] min_tens,//0-9
input [3:0] hrs_ones,//0-9
input [1:0] hrs_tens,//0-2
output reg [6:0] seg,
output reg [3:0] an//4 enablers
);//100Mhz basys 3board
reg [1:0] digit_display=0;//0-3 digits  // for 4 boxes of the display
reg [6:0] display[3:0];   //4 boxes of seven segments
reg [18:0] counter=0;     // used for setting the refresh rate
parameter max_count=125_000;
wire [3:0] four_bit [3:0];  // wires which contains the gigits to be stored in the corresponding display boxes
assign four_bit[0]= min_ones;
assign four_bit[1]= min_tens;
assign four_bit[2]= hrs_ones;
assign four_bit[3]= hrs_tens;
//100 hz slow clock for enabling each segment at refresh rate of 10 ns
always @(posedge clk)begin
    if(counter < max_count)begin
        counter <= counter+1;
    end else begin
        digit_display <= digit_display +1;
        counter<=0;
    end
    case(four_bit[digit_display])
    4'b0000: display[digit_display]<=7'b1000000;
    4'b0001: display[digit_display]<=7'b1111001;
    4'b0010: display[digit_display]<=7'b0100100;
    4'b0011: display[digit_display]<=7'b0110000;
    4'b0100: display[digit_display]<=7'b0011001;
    4'b0101: display[digit_display]<=7'b0010010;
    4'b0110: display[digit_display]<=7'b0000010;
    4'b0111: display[digit_display]<=7'b1111000;
    4'b1000: display[digit_display]<=7'b0000000;
    4'b1001: display[digit_display]<=7'b0011000;
    4'b1010: display[digit_display]<=7'b0001000;
    4'b1011: display[digit_display]<=7'b0000011;
    4'b1100: display[digit_display]<=7'b1000110;
    4'b1101: display[digit_display]<=7'b0100001;
    4'b1110: display[digit_display]<=7'b0000110;
    default: display[digit_display]<=7'b0001110;
    endcase
    case(digit_display)
    0: begin
        an<=4'b1110;
        seg<=display[0];
    end
    1: begin
        an<=4'b1101;
        seg<=display[1];
    end
    2: begin
        an<=4'b1011;
        seg<=display[2];
    end
    3: begin
        an<=4'b0111;
        seg<=display[3];
    end
    endcase


end
endmodule
