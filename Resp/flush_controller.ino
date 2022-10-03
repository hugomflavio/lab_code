// Flush and measurement times in milliseconds
long flush_time = 5000;
long meas_time = 5000;



// DON'T GO BELOW THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING




#define Sauron_pin 2

#define relay1_pin 3
#define button1_pin 4

#define relay2_pin 5
#define button2_pin 6

#define relay3_pin 7
#define button3_pin 8

#define relay4_pin 9
#define button4_pin 10

// The message interval variable controls how often the arduino
// sends information to the computer. Note: It also controls how
// the maximum time it can take for the permanent flush to come 
// on/turn off after being clicked.
long message_interval = 1000;

// last print time just keeps track of the millis() at printing time.
long last_print_time = 0; 

// The relay has a button that overrides all the others (hence the name)
// This variable is just for printing purposes.
String Sauron_status;

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

// relay 2 VARIABLES 
  long phase_start_millis_2 = 0; // Millis when the phase started
  long phase_millis_2 = 0; // how long has the phase been going on for
  int cycle_2 = 0; // current cycle for the relay
  long phase_millis_left_2 = 0; // number of seconds left in the phase, for the print
  boolean flush_2 = false; // Will the next phase be a flush?
  boolean start_phase_2 = true; // is it time to start a new phase?
  boolean check_2 = true; // Has the information for this relay been checked during this message iteration?
  boolean relay2_is_on = false; // Is the flush currently on?
  String phase_2; // Report whether this is a "M" phase or "F" phase for the serial print.
  String button2_status; // Report whether button1 is ON or OFF
////////////////////

// relay 3 VARIABLES 
  long phase_start_millis_3 = 0; // Millis when the phase started
  long phase_millis_3 = 0; // how long has the phase been going on for
  int cycle_3 = 0; // current cycle for the relay
  long phase_millis_left_3 = 0; // number of seconds left in the phase, for the print
  boolean flush_3 = false; // Will the next phase be a flush?
  boolean start_phase_3 = true; // is it time to start a new phase?
  boolean check_3 = true; // Has the information for this relay been checked during this message iteration?
  boolean relay3_is_on = false; // Is the flush currently on?
  String phase_3; // Report whether this is a "M" phase or "F" phase for the serial print.
  String button3_status; // Report whether button1 is ON or OFF
////////////////////

// relay 4 VARIABLES 
  long phase_start_millis_4 = 0; // Millis when the phase started
  long phase_millis_4 = 0; // how long has the phase been going on for
  int cycle_4 = 0; // current cycle for the relay
  long phase_millis_left_4 = 0; // number of seconds left in the phase, for the print
  boolean flush_4 = false; // Will the next phase be a flush?
  boolean start_phase_4 = true; // is it time to start a new phase?
  boolean check_4 = true; // Has the information for this relay been checked during this message iteration?
  boolean relay4_is_on = false; // Is the flush currently on?
  String phase_4; // Report whether this is a "M" phase or "F" phase for the serial print.
  String button4_status; // Report whether button1 is ON or OFF
////////////////////


void setup() {
  // initiate the pins
  pinMode(Sauron_pin, INPUT);
  pinMode(button1_pin, INPUT);
  pinMode(button2_pin, INPUT);
  pinMode(button3_pin, INPUT);
  pinMode(button4_pin, INPUT);
  pinMode(relay1_pin, OUTPUT);
  pinMode(relay2_pin, OUTPUT);
  pinMode(relay3_pin, OUTPUT);
  pinMode(relay4_pin, OUTPUT);

  // initiate the serial connection
  Serial.begin(9600);

  // table header
  Serial.println("Millis\tMaster\tBtn_1\tPhase_1\tTime_1\tBtn_2\tPhase_2\tTime_2\tBtn_3\tPhase_3\tTime_3\tBtn_4\tPhase_4\tTime_4");
}


void loop() {
  if (digitalRead(Sauron_pin) == HIGH) {
    Sauron_status = "ON";
  }
  else {
    Sauron_status = "OFF";
  }

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
  if (digitalRead(button1_pin) == HIGH) {
    button1_status = "ON";
  }
  else {
    button1_status = "OFF";
  }

  if ((digitalRead(button1_pin) == HIGH || digitalRead(Sauron_pin) == HIGH)) {
    // start permanent flush
    relay1_is_on = true;
    phase_1 = "F";
    phase_millis_left_1 = 0; // permanent flush runs until the buttons are turned off
    start_phase_1 = true;
    flush_1 = false;
  }
  else {
    // do cycles instead
    if (start_phase_1 && check_1) {
      // Serial.println("Starting new phase on next message"); // debug message

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


// relay 2 STARTS HERE
  if (digitalRead(button2_pin) == HIGH) {
    button2_status = "ON";
  }
  else {
    button2_status = "OFF";
  }

  if ((digitalRead(button2_pin) == HIGH || digitalRead(Sauron_pin) == HIGH)) {
    // start permanent flush
    relay2_is_on = true;
    phase_2 = "F";
    phase_millis_left_2 = 0; // permanent flush runs until the buttons are turned off
    start_phase_2 = true;
    flush_2 = false;
  }
  else {
    // do cycles instead
    if (start_phase_2 && check_2) {
      // Serial.println("Starting new phase on next message"); // debug message

      phase_start_millis_2 = millis(); // phase is starting now.
      phase_millis_2 = 0;
      // Serial.println((String) "phase_start_millis_2: " + phase_start_millis_2); // debug message

      if (flush_2) { // if a flush phase is starting
        relay2_is_on = true;
        phase_2 = "F";
        phase_millis_left_2 = flush_time;
      }
      else { // if a measurement phase is starting
        relay2_is_on = false;
        phase_2 = "M";
        phase_millis_left_2 = meas_time;
        cycle_2 = ++cycle_2; // notice that the measurement phases drive the cycles
      }

      start_phase_2 = false; // phase started
      check_2 = false; // relay checked
    }

    if (check_2) { // if the phase just started, skip this.
      phase_millis_2 = millis() - phase_start_millis_2;
      // Serial.println((String) "phase_millis_2: " + phase_millis_2); // debug message

      if (flush_2) { // if this is a flush phase
        if (phase_millis_2 >= (flush_time - (message_interval * 2 - 10))) { // if it is time to end the phase
          flush_2 = false; // next phase is not flush
          start_phase_2 = true; // start new phase
        } 
        phase_millis_left_2 = flush_time - phase_millis_2; // update seconds left for the print.
      }
      else { // else this is a measurement phase
        if (phase_millis_2 >= (meas_time - (message_interval * 2 - 10))) { // if it is time to end the phase
          flush_2 = true; // next phase is a flush
          start_phase_2 = true; // start new phase
        }
        phase_millis_left_2 = meas_time - phase_millis_2;
      }
      check_2 = false; // relay checked
    }
  }
// relay 2 ENDS HERE


// relay 3 STARTS HERE
  if (digitalRead(button3_pin) == HIGH) {
    button3_status = "ON";
  }
  else {
    button3_status = "OFF";
  }

  if ((digitalRead(button3_pin) == HIGH || digitalRead(Sauron_pin) == HIGH)) {
    // start permanent flush
    relay3_is_on = true;
    phase_3 = "F";
    phase_millis_left_3 = 0; // permanent flush runs until the buttons are turned off
    start_phase_3 = true;
    flush_3 = false;
  }
  else {
    // do cycles instead
    if (start_phase_3 && check_3) {
      // Serial.println("Starting new phase on next message"); // debug message

      phase_start_millis_3 = millis(); // phase is starting now.
      phase_millis_3 = 0;
      // Serial.println((String) "phase_start_millis_3: " + phase_start_millis_3); // debug message

      if (flush_3) { // if a flush phase is starting
        relay3_is_on = true;
        phase_3 = "F";
        phase_millis_left_3 = flush_time;
      }
      else { // if a measurement phase is starting
        relay3_is_on = false;
        phase_3 = "M";
        phase_millis_left_3 = meas_time;
        cycle_3 = ++cycle_3; // notice that the measurement phases drive the cycles
      }

      start_phase_3 = false; // phase started
      check_3 = false; // relay checked
    }

    if (check_3) { // if the phase just started, skip this.
      phase_millis_3 = millis() - phase_start_millis_3;
      // Serial.println((String) "phase_millis_3: " + phase_millis_3); // debug message

      if (flush_3) { // if this is a flush phase
        if (phase_millis_3 >= (flush_time - (message_interval * 2 - 10))) { // if it is time to end the phase
          flush_3 = false; // next phase is not flush
          start_phase_3 = true; // start new phase
        } 
        phase_millis_left_3 = flush_time - phase_millis_3; // update seconds left for the print.
      }
      else { // else this is a measurement phase
        if (phase_millis_3 >= (meas_time - (message_interval * 2 - 10))) { // if it is time to end the phase
          flush_3 = true; // next phase is a flush
          start_phase_3 = true; // start new phase
        }
        phase_millis_left_3 = meas_time - phase_millis_3;
      }
      check_3 = false; // relay checked
    }
  }
// relay 3 ENDS HERE


// relay 4 STARTS HERE
  if (digitalRead(button4_pin) == HIGH) {
    button4_status = "ON";
  }
  else {
    button4_status = "OFF";
  }

  if ((digitalRead(button4_pin) == HIGH || digitalRead(Sauron_pin) == HIGH)) {
    // start permanent flush
    relay4_is_on = true;
    phase_4 = "F";
    phase_millis_left_4 = 0; // permanent flush runs until the buttons are turned off
    start_phase_4 = true;
    flush_4 = false;
  }
  else {
    // do cycles instead
    if (start_phase_4 && check_4) {
      // Serial.println("Starting new phase on next message"); // debug message

      phase_start_millis_4 = millis(); // phase is starting now.
      phase_millis_4 = 0;
      // Serial.println((String) "phase_start_millis_4: " + phase_start_millis_4); // debug message

      if (flush_4) { // if a flush phase is starting
        relay4_is_on = true;
        phase_4 = "F";
        phase_millis_left_4 = flush_time;
      }
      else { // if a measurement phase is starting
        relay4_is_on = false;
        phase_4 = "M";
        phase_millis_left_4 = meas_time;
        cycle_4 = ++cycle_4; // notice that the measurement phases drive the cycles
      }

      start_phase_4 = false; // phase started
      check_4 = false; // relay checked
    }

    if (check_4) { // if the phase just started, skip this.
      phase_millis_4 = millis() - phase_start_millis_4;
      // Serial.println((String) "phase_millis_4: " + phase_millis_4); // debug message

      if (flush_4) { // if this is a flush phase
        if (phase_millis_4 >= (flush_time - (message_interval * 2 - 10))) { // if it is time to end the phase
          flush_4 = false; // next phase is not flush
          start_phase_4 = true; // start new phase
        } 
        phase_millis_left_4 = flush_time - phase_millis_4; // update seconds left for the print.
      }
      else { // else this is a measurement phase
        if (phase_millis_4 >= (meas_time - (message_interval * 2 - 10))) { // if it is time to end the phase
          flush_4 = true; // next phase is a flush
          start_phase_4 = true; // start new phase
        }
        phase_millis_left_4 = meas_time - phase_millis_4;
      }
      check_4 = false; // relay checked
    }
  }
// relay 4 ENDS HERE


  if (millis() - last_print_time >= message_interval) {

    if (relay1_is_on) {
      digitalWrite(relay1_pin, HIGH);
    }
    else {
      digitalWrite(relay1_pin, LOW);
    }
    
    if (relay2_is_on) {
      digitalWrite(relay2_pin, HIGH);
    }
    else {
      digitalWrite(relay2_pin, LOW);
    }

    if (relay3_is_on) {
      digitalWrite(relay3_pin, HIGH);
    }
    else {
      digitalWrite(relay3_pin, LOW);
    }

    if (relay4_is_on) {
      digitalWrite(relay4_pin, HIGH);
    }
    else {
      digitalWrite(relay4_pin, LOW);
    }

    last_print_time = millis();
    
    Serial.print(last_print_time);
    Serial.print("\t");
    Serial.print(Sauron_status);
    Serial.print("\t");
    Serial.print(button1_status);
    Serial.print("\t");
    Serial.print(phase_1);
    Serial.print(cycle_1);
    Serial.print("\t");
    Serial.print(phase_millis_left_1/1000); // divided by 1000 to get seconds
    Serial.print("\t");
    Serial.print(button2_status);
    Serial.print("\t");
    Serial.print(phase_2);
    Serial.print(cycle_2);
    Serial.print("\t");
    Serial.print(phase_millis_left_2/1000); // divided by 1000 to get seconds
    Serial.print("\t");
    Serial.print(button3_status);
    Serial.print("\t");
    Serial.print(phase_3);
    Serial.print(cycle_3);
    Serial.print("\t");
    Serial.print(phase_millis_left_3/1000); // divided by 1000 to get seconds
    Serial.print("\t");
    Serial.print(button4_status);
    Serial.print("\t");
    Serial.print(phase_4);
    Serial.print(cycle_4);
    Serial.print("\t");
    Serial.println(phase_millis_left_4/1000); // divided by 1000 to get seconds

    // reset the checks for a new iteration
    check_1 = true;
    check_2 = true;
    check_3 = true;
    check_4 = true;
  }
 } 

 
