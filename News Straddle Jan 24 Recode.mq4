//+------------------------------------------------------------------+
//|                              StraddleNews Strag GPT Dec23.mq4    |
//|                                                                 |
//|                                                      Original by |
//|                                                                  |
//|                                                                 |
//+------------------------------------------------------------------+
#property copyright "Badim"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

// Define global variables for logging
string LOG_FILE_NAME = "StraddleEA_Log.txt";
int logHandle;

// Only issue now is that sell and buy stop error placing trades order
// No issue anymore, just network would determine if it would carry trade or not
// Shows countdown, accurate and all
// It triggers right on time

// Input parameters
input datetime TradeDateTime = D'2023.12.12 16:00'; // Specify your desired date and time for the trade.
input int StopLossPips = 20; // Stop-loss in broker's pips.
input int TakeProfitPips = 20; // Take-profit in broker's pips.
input int PipsAway = 10; // BUYSTOP and SELLSTOP pips.
input double LotSize = 0.01; // Lot size for trades
input int Slippage = 0;

// Global variables
int BuyStopTicket = 0;
int SellStopTicket = 0;
datetime LastTradeTime = 0;
double TakeProfit; // To convert the tp n sl so it would be in pips
double StopLoss;
double PipsDiff;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Open the log file in append mode
    logHandle = FileOpen(LOG_FILE_NAME, FILE_READ|FILE_WRITE|FILE_TXT);
    if (logHandle == INVALID_HANDLE)
    {
        Print("Error opening log file: ", GetLastError());
    }
    else
    {
        Print("Log file opened successfully.");
    }

    // Place the initial countdown label
    DisplayCountdown();

    return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Display the countdown
    DisplayCountdown();

    // Check if it's time to trade
    if (ShouldTrade())
    {
        // Delete opposite pending orders if they exist
        if (BuyStopTicket > 0)
        {
            if (OrderDelete(BuyStopTicket))
            {
                Log("Deleted BuyStop order.");
            }
            else
            {
                Log("Error deleting BuyStop order: " + IntegerToString(GetLastError()));

            }
        }
        
        if (SellStopTicket > 0)
        {
            if (OrderDelete(SellStopTicket))
            {
                Log("Deleted SellStop order.");
            }
            else
            {
                Log("Error deleting SellStop order: " + IntegerToString(GetLastError()));
            }
        }

        // Place BuyStop and SellStop orders.
        OpenStopOrder();
    }

    // Check and delete pending orders after 5 minutes
    int elapsedSeconds = int(TimeCurrent() - LastTradeTime);
    if (elapsedSeconds >= 300)
    {
        CloseOrders();
    }
}

//+------------------------------------------------------------------+
//| Function to Validate Inputs                        |
//+------------------------------------------------------------------+
int Validateinputs()
{
    //SL n TP must be more than 0
    if(StopLossPips <= 0 || TakeProfitPips <= 0 || PipsAway <= 0)
    {
        Log("SL, TP and Pips must be greater than 0");
        return(INIT_PARAMETERS_INCORRECT);
    }

    //Then validate the tp, sl n pips conversion
    TakeProfit = PipsToPrice(TakeProfitPips, Symbol());
    StopLoss = PipsToPrice(StopLossPips, Symbol());
    PipsDiff = PipsToPrice(PipsAway, Symbol());
   
    return(INIT_SUCCEEDED);//If none of these error then run the bot succesfully
}

//+------------------------------------------------------------------+
//| Function to check if it's time to trade                         |
//+------------------------------------------------------------------+
bool ShouldTrade()
{
    datetime currentDateTime = TimeCurrent();

    if (currentDateTime == TradeDateTime && currentDateTime != LastTradeTime)
    {
        // Update the last trade time.
        LastTradeTime = currentDateTime;
        return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| Function to calculate Take Profit, Stop Loss, BuyStop, and SellStop prices |
//+------------------------------------------------------------------+
void CalculatePrices(ENUM_ORDER_TYPE orderType, double& openPrice, double& takeprofitprice, double& stoplossprice, double& BuyStopPrice, double& SellStopPrice)
{
    if (orderType == ORDER_TYPE_BUY)
    {
        openPrice = Ask;
        takeprofitprice = openPrice + TakeProfit;
        stoplossprice = Bid - StopLoss;
        PipsDiff = PipsToPrice(PipsAway, Symbol());
        BuyStopPrice = openPrice + PipsDiff;
        SellStopPrice = openPrice - PipsDiff;
    }
    else
    {
        openPrice = Bid;
        takeprofitprice = openPrice - TakeProfit;
        stoplossprice = Ask + StopLoss;
        PipsDiff = PipsToPrice(PipsAway, Symbol());
        BuyStopPrice = openPrice - PipsDiff;
        SellStopPrice = openPrice + PipsDiff;
    }
}

//+------------------------------------------------------------------+
//| Function to place BuyStop and SellStop orders                    |
//+------------------------------------------------------------------+
void OpenStopOrder()
{
    double openPrice;
    double takeprofitprice;
    double stoplossprice;
    double BuyStopPrice;
    double SellStopPrice;

    // Calculate all necessary prices
    CalculatePrices(ORDER_TYPE_BUY, openPrice, takeprofitprice, stoplossprice, BuyStopPrice, SellStopPrice);

    // Check stop levels for BuyStop
    if (!CheckStopLevels(BuyStopPrice, 0))
    {
        Log("BuyStop levels check failed.");
        return;
    }

    // Place BuyStop order
    BuyStopTicket = OrderSend(Symbol(), OP_BUYSTOP, LotSize, BuyStopPrice, Slippage, 0, 0, "BuyStop Order", 0, 0, clrGreen);
    if (BuyStopTicket > 0)
    {
        Log("BuyStop order placed successfully.");
    }
    else
    {
        Log("Error placing BuyStop order: " + IntegerToString(GetLastError()));
        Log("Symbol: " + Symbol()); // Print the symbol for debugging
    }

    // Check stop levels for SellStop
    if (!CheckStopLevels(0, SellStopPrice))
    {
        Log("SellStop levels check failed.");
        return;
    }

    // Place SellStop order
    SellStopTicket = OrderSend(Symbol(), OP_SELLSTOP, LotSize, SellStopPrice, Slippage, stoplossprice, takeprofitprice, "SellStop Order", 0, 0, clrRed);
    if (SellStopTicket > 0)
    {
        Log("SellStop order placed successfully.");
    }
    else
    {
        Log("Error placing SellStop order: " + IntegerToString(GetLastError()));
        Log("Symbol: " + Symbol()); // Print the symbol for debugging
    }
}

//+------------------------------------------------------------------+
//| Function to check stop levels before placing orders             |
//+------------------------------------------------------------------+
bool CheckStopLevels(double buyStopLevel, double sellStopLevel)
{
    double stopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL);
    
    // Check if the broker's stop level is not known (indicated by -1)
    if (stopLevel <= 0)
    {
        Log("Unable to determine the broker's stop level. Please check your broker's specifications.");
        return false;
    }

    if (buyStopLevel < stopLevel || sellStopLevel < stopLevel)
    {
        Log("Stop level violation. Adjust PipsAway or try again later.");
        return false;
    }

    return true;
}

//+------------------------------------------------------------------+
//| Function to display the countdown label                         |
//+------------------------------------------------------------------+
void DisplayCountdown()
{
    int remainingTime = SecondsUntilTradingTime(TradeDateTime);
    if (remainingTime >= 0)
    {
        string countdown = TimeRemainingString(remainingTime);

        ObjectsDeleteAll(0, OBJ_LABEL); // Delete previous labels

        ObjectCreate("CountdownLabel", OBJ_LABEL, 0, 0, 0);
        ObjectSetText("CountdownLabel", "Time Remaining: " + countdown, 10, "Arial", clrWhite);
        ObjectSet("CountdownLabel", OBJPROP_CORNER, 0);
        ObjectSet("CountdownLabel", OBJPROP_XDISTANCE, 20);
        ObjectSet("CountdownLabel", OBJPROP_YDISTANCE, 20);
    }
    else
    {
        // Delete the countdown label if the time has passed
        ObjectsDeleteAll(0, OBJ_LABEL);
    }
}

//+------------------------------------------------------------------+
//| Function to calculate seconds remaining until trading time      |
//+------------------------------------------------------------------+
int SecondsUntilTradingTime(datetime tradeTime)
{
    datetime currentDateTime = TimeCurrent();
    int secondsUntil = int(tradeTime - currentDateTime);

    if (secondsUntil >= 0)
    {
        return secondsUntil;
    }
    return -1; // Indicates that the time has passed.
}

//+------------------------------------------------------------------+
//| Function to format time remaining string                        |
//+------------------------------------------------------------------+
string TimeRemainingString(int secondsRemaining)
{
    int hours = secondsRemaining / 3600;
    int minutes = (secondsRemaining % 3600) / 60;
    int seconds = secondsRemaining % 60;
    return StringFormat("%02d:%02d:%02d", hours, minutes, seconds);
}

//+------------------------------------------------------------------+
//| Function to close trades after 5 minutes of trigger             |
//+------------------------------------------------------------------+
void OnTimer()
{
    // Calculate the time elapsed since the last trade
    int elapsedSeconds = int(TimeCurrent() - LastTradeTime);

    // Check if 5 minutes have passed since the last trade
    if (elapsedSeconds >= 300)
    {
        // Close BuyStop and SellStop orders if they are still open
        CloseOrders();
    }
}

//+------------------------------------------------------------------+
//| Function to close BuyStop and SellStop orders                    |
//+------------------------------------------------------------------+
void CloseOrders()
{
    // Close BuyStop order
    if (BuyStopTicket > 0 && OrderDelete(BuyStopTicket))
    {
        Log("Closed BuyStop order.");
    }

    // Close SellStop order
    if (SellStopTicket > 0 && OrderDelete(SellStopTicket))
    {
        Log("Closed SellStop order.");
    }
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Close the log file handle
    if (logHandle != INVALID_HANDLE)
    {
        FileClose(logHandle);
    }

    // Delete the countdown label when the EA is removed
    ObjectsDeleteAll(0, OBJ_LABEL);
}

//+------------------------------------------------------------------+
//| Pip Conversion function                                |
//+------------------------------------------------------------------+
//Calculating pip size
double Pipsize(string symbol) {
   double point = MarketInfo(symbol, MODE_POINT);
   int digits = (int)MarketInfo(symbol, MODE_DIGITS);
   return( ((digits%2)==1) ? point*10 : point);
}

//Converting pips to price
double PipsToPrice(double pips, string symbol) {
   return(pips*Pipsize(symbol));
}

// Logging function
void Log(string message)
{
    if (logHandle != INVALID_HANDLE)
    {
        // Get the current date and time
        string timestamp = TimeToStr(TimeCurrent(), TIME_DATE|TIME_SECONDS);

        // Create log entry
        string logEntry = timestamp + ": " + message + "\n";

        // Write log entry to file
        FileWriteString(logHandle, logEntry);
    }
}







// rewriting the whole code with gpt improvemnets
/*
// Constants
static const int SECONDS_IN_FIVE_MINUTES = 300;

// Input parameters
input datetime TradeDateTime = D'2023.12.12 16:00';
input int StopLossPips = 20;
input int TakeProfitPips = 20;
input int PipsAway = 10;
input double LotSize = 0.01;
input int Slippage = 0;

// Global variables
int BuyStopTicket = 0;
int SellStopTicket = 0;
datetime LastTradeTime = 0;
double TakeProfit;
double StopLoss;
double PipsDiff;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Place the initial countdown label
    DisplayCountdown();

    return ValidateInputs();
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Display the countdown
    DisplayCountdown();

    // Check if it's time to trade
    if (ShouldTrade())
    {
        // Delete opposite pending orders if they exist
        if (BuyStopTicket > 0)
        {
            if (OrderDelete(BuyStopTicket))
            {
                Print("Deleted BuyStop order.");
            }
            else
            {
                Print("Error deleting BuyStop order: ", GetLastError());
            }
        }
        
        if (SellStopTicket > 0)
        {
            if (OrderDelete(SellStopTicket))
            {
                Print("Deleted SellStop order.");
            }
            else
            {
                Print("Error deleting SellStop order: ", GetLastError());
            }
        }

        // Place BuyStop and SellStop orders.
        OpenStopOrder();
    }

    // Check and delete pending orders after 5 minutes
    CheckAndDeletePendingOrders();
}

//+------------------------------------------------------------------+
//| Function to Validate Inputs                                      |
//+------------------------------------------------------------------+
int ValidateInputs()
{
    // SL, TP, and Pips must be greater than 0
    if (StopLossPips <= 0 || TakeProfitPips <= 0 || PipsAway <= 0)
    {
        Print("SL, TP, and Pips must be greater than 0");
        return INIT_PARAMETERS_INCORRECT;
    }

    // Validate the TP, SL, and Pips conversion
    TakeProfit = PipsToPrice(TakeProfitPips, Symbol());
    StopLoss = PipsToPrice(StopLossPips, Symbol());
    PipsDiff = PipsToPrice(PipsAway, Symbol());

    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Function to check if it's time to trade                         |
//+------------------------------------------------------------------+
bool ShouldTrade()
{
    datetime currentDateTime = TimeCurrent();

    if (currentDateTime == TradeDateTime && currentDateTime != LastTradeTime)
    {
        // Update the last trade time.
        LastTradeTime = currentDateTime;
        return true;
    }

    return false;
}

//+------------------------------------------------------------------+
//| Function to calculate Take Profit, Stop Loss, BuyStop, and SellStop prices |
//+------------------------------------------------------------------+
void CalculatePrices(ENUM_ORDER_TYPE orderType, double& openPrice, double& takeprofitprice, double& stoplossprice, double& BuyStopPrice, double& SellStopPrice)
{
    if (orderType == ORDER_TYPE_BUY)
    {
        openPrice = Ask;
        takeprofitprice = openPrice + TakeProfit;
        stoplossprice = Bid - StopLoss;
        PipsDiff = PipsToPrice(PipsAway, Symbol());
        BuyStopPrice = openPrice + PipsDiff;
        SellStopPrice = openPrice - PipsDiff;
    }
    else
    {
        openPrice = Bid;
        takeprofitprice = openPrice - TakeProfit;
        stoplossprice = Ask + StopLoss;
        PipsDiff = PipsToPrice(PipsAway, Symbol());
        BuyStopPrice = openPrice - PipsDiff;
        SellStopPrice = openPrice + PipsDiff;
    }
}

//+------------------------------------------------------------------+
//| Function to place BuyStop and SellStop orders                    |
//+------------------------------------------------------------------+
void OpenStopOrder()
{
   double openPrice;
   double takeprofitprice;
   double stoplossprice;
   double BuyStopPrice;
   double SellStopPrice;

   // Calculate all necessary prices
   CalculatePrices(ORDER_TYPE_BUY, openPrice, takeprofitprice, stoplossprice, BuyStopPrice, SellStopPrice);

   // Check stop levels for BuyStop
   if (!CheckStopLevels(BuyStopPrice, 0))
   {
      Print("BuyStop levels check failed.");
      return;
   }

   // Place BuyStop order
   BuyStopTicket = OrderSend(Symbol(), OP_BUYSTOP, LotSize, BuyStopPrice, Slippage, stoplossprice, takeprofitprice, "BuyStop Order", 0, 0, clrGreen);
   if (BuyStopTicket > 0)
   {
      Print("BuyStop order placed successfully.");
   }
   else
   {
      Print("Error placing BuyStop order: ", GetLastError());
      Print("Symbol: ", Symbol()); // Print the symbol for debugging
   }

   // Check stop levels for SellStop
   if (!CheckStopLevels(0, SellStopPrice))
   {
      Print("SellStop levels check failed.");
      return;
   }

   // Place SellStop order
   SellStopTicket = OrderSend(Symbol(), OP_SELLSTOP, LotSize, SellStopPrice, Slippage, stoplossprice, takeprofitprice, "SellStop Order", 0, 0, clrRed);
   if (SellStopTicket > 0)
   {
      Print("SellStop order placed successfully.");
   }
   else
   {
      Print("Error placing SellStop order: ", GetLastError());
      Print("Symbol: ", Symbol()); // Print the symbol for debugging
   }
}

//+------------------------------------------------------------------+
//| Function to check stop levels before placing orders             |
//+------------------------------------------------------------------+
bool CheckStopLevels(double buyStopLevel, double sellStopLevel)
{
    double stopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL);
    
    // Check if the broker's stop level is not known (indicated by -1)
    if (stopLevel <= 0)
    {
        Print("Unable to determine the broker's stop level. Please check your broker's specifications.");
        return false;
    }

    if (buyStopLevel < stopLevel || sellStopLevel < stopLevel)
    {
        Print("Stop level violation. Adjust PipsAway or try again later.");
        return false;
    }

    return true;
}

//+------------------------------------------------------------------+
//| Function to display the countdown label                         |
//+------------------------------------------------------------------+
void DisplayCountdown()
{
    int remainingTime = SecondsUntilTradingTime(TradeDateTime);
    if (remainingTime >= 0)
    {
        string countdown = TimeRemainingString(remainingTime);

        ObjectsDeleteAll(0, OBJ_LABEL); // Delete previous labels

        ObjectCreate("CountdownLabel", OBJ_LABEL, 0, 0, 0);
        ObjectSetText("CountdownLabel", "Time Remaining: " + countdown, 10, "Arial", clrWhite);
        ObjectSet("CountdownLabel", OBJPROP_CORNER, 0);
        ObjectSet("CountdownLabel", OBJPROP_XDISTANCE, 20);
        ObjectSet("CountdownLabel", OBJPROP_YDISTANCE, 20);
    }
    else
    {
        // Delete the countdown label if the time has passed
        ObjectsDeleteAll(0, OBJ_LABEL);
    }
}

//+------------------------------------------------------------------+
//| Function to calculate seconds remaining until trading time      |
//+------------------------------------------------------------------+
int SecondsUntilTradingTime(datetime tradeTime)
{
    datetime currentDateTime = TimeCurrent();
    int secondsUntil = int(tradeTime - currentDateTime);

    if (secondsUntil >= 0)
    {
        return secondsUntil;
    }
    return -1; // Indicates that the time has passed.
}

//+------------------------------------------------------------------+
//| Function to format time remaining string                        |
//+------------------------------------------------------------------+
string TimeRemainingString(int secondsRemaining)
{
    int hours = secondsRemaining / 3600;
    int minutes = (secondsRemaining % 3600) / 60;
    int seconds = secondsRemaining % 60;
    return StringFormat("%02d:%02d:%02d", hours, minutes, seconds);
}

//+------------------------------------------------------------------+
//| Function to check and delete pending orders after 5 minutes     |
//+------------------------------------------------------------------+
void CheckAndDeletePendingOrders()
{
    int elapsedSeconds = int(TimeCurrent() - LastTradeTime);
    if (elapsedSeconds >= SECONDS_IN_FIVE_MINUTES)
    {
        CloseOrders();
    }
}

//+------------------------------------------------------------------+
//| Function to close BuyStop and SellStop orders                    |
//+------------------------------------------------------------------+
void CloseOrders()
{
    // Close BuyStop order
    if (BuyStopTicket > 0 && OrderDelete(BuyStopTicket))
    {
        Print("Closed BuyStop order.");
    }

    // Close SellStop order
    if (SellStopTicket > 0 && OrderDelete(SellStopTicket))
    {
        Print("Closed SellStop order.");
    }
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Delete the countdown label when the EA is removed
    ObjectsDeleteAll(0, OBJ_LABEL);
}

//+------------------------------------------------------------------+
//| Pip Conversion function                                          |
//+------------------------------------------------------------------+
//Calculating pip size
double Pipsize(string symbol) {
   double point = MarketInfo(symbol, MODE_POINT);
   int digits = (int)MarketInfo(symbol, MODE_DIGITS);
   return( ((digits%2)==1) ? point*10 : point);
}

//Converting pips to price
double PipsToPrice(double pips, string symbol) {
   return(pips*Pipsize(symbol));
}


*/

//Then adding two more times to the code
/*
// Define additional trade times
input datetime TradeDateTime2 = D'2023.12.13 16:00'; // Add your second desired date and time for the trade.
input datetime TradeDateTime3 = D'2023.12.14 16:00'; // Add your third desired date and time for the trade.

// ...

// Function to check if it's time to trade
bool ShouldTrade()
{
    datetime currentDateTime = TimeCurrent();

    // Check for the first trade time
    if (currentDateTime == TradeDateTime && currentDateTime != LastTradeTime)
    {
        // Update the last trade time.
        LastTradeTime = currentDateTime;
        return true;
    }

    // Check for the second trade time
    if (currentDateTime == TradeDateTime2 && currentDateTime != LastTradeTime)
    {
        // Update the last trade time.
        LastTradeTime = currentDateTime;
        return true;
    }

    // Check for the third trade time
    if (currentDateTime == TradeDateTime3 && currentDateTime != LastTradeTime)
    {
        // Update the last trade time.
        LastTradeTime = currentDateTime;
        return true;
    }

    return false;
}

// ...

*/