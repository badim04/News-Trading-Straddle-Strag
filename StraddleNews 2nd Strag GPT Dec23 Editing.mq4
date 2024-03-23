//+------------------------------------------------------------------+
//|                                 StraddleNews Strag GPT Dec23.mq4 |
//|                                                            Badim |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Badim"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict


// Only issue now is that sell and buy stop error placing trades order
// No issue anymore, just network would determine if it would carry trade or not
// Issue now is no TP n SL, No deleting trades
// Shows countdown, accurate and all
// It triggers right on time


// Input parameters
input datetime TradeDateTime = D'2024.02.22 21:05'; // Specify your desired date and time for the trade.
input int StopLossPips = 200; // Stop-loss in broker's pips.
input int TakeProfitPips = 200; // Take-profit in broker's pips.
input int PipsAway = 100; // BUYSTOP and SELLSTOP pips.
input double LotSize = 1.0; // Lot size for trades
input int Slippage = 0;

// Global variables
int BuyStopTicket = 0;
int SellStopTicket = 0;
datetime LastTradeTime = 0;
double TakeProfit;//To convert the tp n sl so it would be in pips
double StopLoss;
double PipsDiff;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   //trial SL and TP , maybe removed
   StopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL);
   if (SL < StopLevel) SL = StopLevel;
   if (TP < StopLevel) TP = StopLevel;
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
}

//+------------------------------------------------------------------+
//| Function to Validate Inputs                        |
//+------------------------------------------------------------------+
int Validateinputs(){//This is a func to validate the inputs
   
   //SL n TP must be more than 0
   if(StopLossPips <= 0 || TakeProfitPips <= 0 || PipsAway <= 0){
      Print("SL, TP and Pips must be greater than 0");
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
//| Function to calculate Take Profit and Stop Loss prices           |
//+------------------------------------------------------------------+

void CalculateTPSL(ENUM_ORDER_TYPE orderType, double& openPrice, double& takeprofitprice, double& stoplossprice)
{
   if (orderType == ORDER_TYPE_BUY)
   {
      openPrice = Ask;
      takeprofitprice = openPrice + TakeProfit;
      stoplossprice = Bid - StopLoss;
   }
   else
   {
      openPrice = Bid;
      takeprofitprice = openPrice - TakeProfit;
      stoplossprice = Ask + StopLoss;
   }
}


//+------------------------------------------------------------------+
//| Function to calculate BuyStop and SellStop prices                |
//+------------------------------------------------------------------+
void CalculateStopPrices(ENUM_ORDER_TYPE orderType, double& BuyStopPrice, double& SellStopPrice)
{
   double openPrice;
   double takeprofitprice;
   double stoplossprice;

   CalculateTPSL(orderType, openPrice, takeprofitprice, stoplossprice);

   PipsDiff = PipsToPrice(PipsAway, Symbol());

   if (orderType == ORDER_TYPE_BUY)
   {
      BuyStopPrice = openPrice + PipsDiff;
      SellStopPrice = openPrice - PipsDiff;
   }
   else
   {
      BuyStopPrice = openPrice - PipsDiff;
      SellStopPrice = openPrice + PipsDiff;
   }
}


//+------------------------------------------------------------------+
//| Function to place BuyStop and SellStop orders                    |
//+------------------------------------------------------------------+
void OpenStopOrder()
{
   double BuyStopPrice;
   double SellStopPrice;

   // Calculate BuyStop and SellStop prices
   CalculateStopPrices(ORDER_TYPE_BUY, BuyStopPrice, SellStopPrice);
   
 /* 
   // Check stop levels for BuyStop
   if (!CheckStopLevels(BuyStopPrice, 0))
   {
      Print("BuyStop levels check failed.");
      return;
   }
 */   
   // Place BuyStop order
   BuyStopTicket = OrderSend(Symbol(), OP_BUYSTOP, LotSize, BuyStopPrice, Slippage, TakeProfit, StopLoss, "BuyStop Order", 0, 0, clrGreen);
   if (BuyStopTicket > 0)
   {
      Print("BuyStop order placed successfully.");
   }
   else
   {
      Print("Error placing BuyStop order: ", GetLastError());
      Print("Symbol: ", Symbol()); // Print the symbol for debugging
   }
 /* 
   // Check stop levels for SellStop
   if (!CheckStopLevels(0, SellStopPrice))
   {
      Print("SellStop levels check failed.");
      return;
   }
  */
   //minimum stop level set in your broker's MetaTrader
   Print("StopLevel = ", (int)MarketInfo(Symbol(), MODE_STOPLEVEL));
   // Place SellStop order
   SellStopTicket = OrderSend(Symbol(), OP_SELLSTOP, LotSize, SellStopPrice, Slippage, 100.0, 100.0, "SellStop Order", 0, 0, clrRed);
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
/*
//+------------------------------------------------------------------+
//| Function to check stop levels before placing orders             |
//+------------------------------------------------------------------+
bool CheckStopLevels(double buyStopLevel, double sellStopLevel)
{
    double stopLevel = MarketInfo(Symbol(), MODE_STOPLEVEL);
    
    Print("Checking stop and buy - Stop levels.");
    
    Print("stopLevel:",stopLevel," buyStopLevel:", buyStopLevel, " sellStopLevel:",sellStopLevel);
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
*/


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
    //int elapsedSeconds = TimeCurrent() - LastTradeTime;
    // Calculate the time elapsed since the last trade
    int elapsedSeconds = int(TimeCurrent() - LastTradeTime);


    // Check if 5 minutes have passed since the last trade
    if (elapsedSeconds >= 300)
    {
        // Close BuyStop and SellStop orders if they are still open
        CloseOrders();
    }
}

/*
//+------------------------------------------------------------------+
//| Function to close BuyStop and SellStop orders                    |
//+------------------------------------------------------------------+
void CloseOrders()
{
    // Close BuyStop order
    if (BuyStopTicket > 0 && OrderClose(BuyStopTicket, OrderLots(), MarketInfo(BuyStopTicket, MODE_BID), Slippage, clrWhite))
    {
        Print("Closed BuyStop order.");
    }

    // Close SellStop order
    if (SellStopTicket > 0 && OrderClose(SellStopTicket, OrderLots(), MarketInfo(SellStopTicket, MODE_ASK), Slippage, clrWhite))
    {
        Print("Closed SellStop order.");
    }
}
*/
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



