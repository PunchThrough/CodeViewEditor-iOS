/* comment one line */
void setup() {
  // comment one line
  int i = 1;
  int j = 0xFF;
  int f = 0xff;
  int g = 0b1010;
  Serial.begin(9600);
}

/* commment 'inline string'
multiple "another inline string"
lines // inline comment
*/
void loop() {
  char *i = " // comment in string test ";
  char *j = ' /* comment in string test */ ';
  char *h = ' /* comment breaks after 1 line
  
  ';
  
  protected // KEYWORD1
  INTERNAL1V1 // LITERAL1
  highByte //KEYWORD2
}

/* unterminated comment


