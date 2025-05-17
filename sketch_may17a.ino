extern "C"
{
  void LCD_write();
  void init_car();
  void run_car();
}
//----------------------------------------------------
void setup()
{
  // Initialize car components
  init_car();

  // Start car operation
  run_car();

  // Note: run_car() contains an infinite loop, so the code will not proceed beyond this point
}
//----------------------------------------------------
void loop()
{
  // Empty loop as run_car() contains its own infinite loop
}