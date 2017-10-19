 ## script to synchronize laminar and telemetry iEEG recordings 
 ##   
 ##   written by Thomas Thesen, PhD; February 2006, thomas@ucsd.edu
 ##
 ## writes an incrementing (virtual clock) coded output pulse train to ONE output port (defined by variable: 'out_port') at 
 ## regular intervals (defined by variable: 'train_freq'), to be recorded by different acquisition systems
 ## Stop by pressing 'Esc'.  
 ##
 ## Coding: 
 ## 4 output pulses per train, first pulse serves as timing 'beacon' for synchronization, the remainder for 
 ## identifying the specific train by the OFF time interval between the consecuive output pulses. That means the coding is done through the
 ## length of 3 intervals (A,B,C). Values for A B & C are incrementing systematically in decimal steps. If you want to compare it to a clock then 
 ## A would be hours, B the minutes and C the seconds.  
 #
 ## Defaults:
 ## Pulse1: starts the train. 50 ms long (as are all three pulses) (defined by variable: 'pulse_length') 
 
 ## Pulse2: delay to Pulse1 defines the first code (A).  
 ## Time is encoded in changes of 10 ms (defined by variable: 'break_length'). Increments indefinitely. 
  
 ## Pulse3: delay to Pulse2 defines the second code (B). Time is encoded in changes of 10 ms. 
 ## Increments up to 100 and then adds 1 to Pulse2 value (similar to a clock jumping from sec to min).
 
 ## Pulse4: delay to Pulse3 defines the thirdcode element (C). Time is encoded in changes of 10 ms.
 ## Increments up to 100 and then adds 1 to Pulse3 value (Pulse4 increments the fastest = seconds).
 ## 
 ## Interval A (between pulse 1 and 2) = value * 10 ms
 ## Interval B (between pulse 2 and 3) = value * 10 ms
 ## Interval C (between pulse 3 and 4) = value * 10 ms
 ##
 ## Example: Trigger A: 1; Trigger B: 68; Trigger C: 15
 ## Pulse1 -> 10 ms delay -> Pulse2 -> 680 ms delay -> Pulse 3 -> 150 ms delay -> Pulse4 
 ##  
 ## These timing variables can be changed. See top rows of the PCL file.

 
   
default_font_size = 24; 
pcl_file = "syncing_ieeg_prog_clock_2.pcl";  

begin;

picture {} default;

trial {   
   picture {
      text { caption = "default "; } text1;
      x = 0; y = 0;
   } pic1;
} trial1;      





