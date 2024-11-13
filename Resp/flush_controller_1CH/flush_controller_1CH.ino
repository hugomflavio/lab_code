// Flush and measurement times in milliseconds
long flush_time = 120000;
long meas_time = 180000;



// DON'T GO BELOW THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING


#define button1_pin 2
#define relay1_pin 8

// The message interval variable controls how often the arduino
// sends information to the computer. Note: It also controls how
// the maximum time it can take for the permanent flush to come 
// on/turn off after being clicked.
long message_interval = 1000;

// last print time just keeps track of the millis() at printing time.
long last_print_time = 0; 

// relay 1 VARIABLES 
  long phase_start_millis_1 = 0; // Millis when the phase started
  long phase_millis_1 = 0; // how long has the phase been going on for
  int cycle_1 = 0; // current cycle for the relay
  long phase_millis_left_1 = 0; // number of seconds left in the phase, for the print
  boolean flush_1 = false; // Will the next phase be a flush?
  boolean start_phase_1 = true; // is it time to start a new phase?
  boolean check_1 = true; // Has the information for this relay been checked during this message iteration?
  boolean relay1_is_on = false; // Is the flush currently on?
  String phase_1; // Report whether this is a "M" phase or "F" phase for the serial print.
  String button1_status; // Report whether button1 is ON or OFF
////////////////////

void setup() {
  // initiate the pins
  pinMode(button1_pin, INPUT_PULLUP);
  pinMode(relay1_pin, OUTPUT);

  // initiate the serial connection
  Serial.begin(9600);

  // table header
  Serial.println("Millis\tBtn\tPhase\tTime");
}


void loop() {
  if (millis() - last_print_time >= message_interval) {

    last_print_time = millis();


    // This note relates to an if statement present in all relays:

    // The reason for the odd "interval*2-10" thing going on in the line below is the following:
    // For t being the time at which the actions are taken and the messages are sent, the decisions for
    // t+1 are decided right after t. As such, if we want the phase to change at t+1, we need to signal
    // that immediately after t (hence the message_interval - 10 milliseconds). The message interval time
    // is doubled up to account for situations where the permanent flush has been triggered and was just
    // let go. Because the permanent flush is checked in real time, the start time of the phase coming
    // out of the permanent flush is not synchronized with the message intervals. 
    // e.g. if have 5s phases and a message interval of 1s and I click the button off at ms 1500, then the 
    // phase times will become 0ms, 500ms, 1500ms, 2500ms, 3500ms. Because 3500ms is still less than 5000-1000-10,
    // the system would command the phase to go over another second, ending the phase after
    // six seconds instead of five. By doubling down the message interval, we ensure that clicking the
    // button at any time mid-message interval cannot cause a delay so large that it will fool the system
    // into going over one second. This does not affect the natural cycles because the milliseconds
    // in natural cycles go 0, 1000, 2000, 3000 (which is still lower than 5000 - 1990), and then 4000, which
    // triggers the change of phase on the next second.
          

   // relay 1 STARTS HERE
      if (digitalRead(button1_pin) == LOW) {
        // start permanent flush
        button1_status = "ON";
        relay1_is_on = true;
        phase_1 = "F";
        phase_millis_left_1 = 0; // permanent flush runs until the buttons are turned off
        start_phase_1 = true;
        flush_1 = false;
      }
      else {
        // do cycles instead
        button1_status = "OFF";
        if (start_phase_1 && check_1) {
          // Serial.println("Starting new phase for 1 on next message"); // debug message

          phase_start_millis_1 = millis(); // phase is starting now.
          phase_millis_1 = 0;
          // Serial.println((String) "phase_start_millis_1: " + phase_start_millis_1); // debug message

          if (flush_1) { // if a flush phase is starting
            relay1_is_on = true;
            phase_1 = "F";
            phase_millis_left_1 = flush_time;
          }
          else { // if a measurement phase is starting
            relay1_is_on = false;
            phase_1 = "M";
            phase_millis_left_1 = meas_time;
            cycle_1 = ++cycle_1; // notice that the measurement phases drive the cycles
          }

          start_phase_1 = false; // phase started
          check_1 = false; // relay checked
        }

        if (check_1) { // if the phase just started, skip this.
          phase_millis_1 = millis() - phase_start_millis_1;
          // Serial.println((String) "phase_millis_1: " + phase_millis_1); // debug message

          if (flush_1) { // if this is a flush phase
            if (phase_millis_1 >= (flush_time - (message_interval * 2 - 10))) { // if it is time to end the phase
              flush_1 = false; // next phase is not flush
              start_phase_1 = true; // start new phase
            } 
            phase_millis_left_1 = flush_time - phase_millis_1; // update seconds left for the print.
          }
          else { // else this is a measurement phase
            if (phase_millis_1 >= (meas_time - (message_interval * 2 - 10))) { // if it is time to end the phase
              flush_1 = true; // next phase is a flush
              start_phase_1 = true; // start new phase
            }
            phase_millis_left_1 = meas_time - phase_millis_1;
          }
          check_1 = false; // relay checked
        }
      }
    // relay 1 ENDS HERE


    if (relay1_is_on) {
      digitalWrite(relay1_pin, LOW);
    }
    else {
      digitalWrite(relay1_pin, HIGH);
    }
   
    if (!Serial) { // attempt to recover from serial crash
      Serial.end();
      delay(100);
      Serial.begin(9600);
    }

    Serial.print(last_print_time);
    Serial.print("\t");
    Serial.print(button1_status);
    Serial.print("\t");
    Serial.print(phase_1);
    Serial.print(cycle_1);
    Serial.print("\t");
    Serial.println(phase_millis_left_1/1000); // divided by 1000 to get seconds

    // reset the checks for a new iteration
    check_1 = true;
  }
 } 

 
