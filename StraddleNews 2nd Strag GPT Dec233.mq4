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
double TakeProfit = 200;//To convert the tp n sl so it would be in pips
double StopLoss = 200;
double PipsDiff;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
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
/*
//+------------------------------------------------------------------+
//| Function to calculate Take Profit and Stop Loss prices           |
//+------------------------------------------------------------------+
void CalculateTPSL(ENUM_ORDER_TYPE orderType, double openPrice, double BuyStopPrice, double SellStopPrice, double& takeprofitprice, double& stoplossprice)
{
   // Print out TakeProfit and StopLoss values
   Print("TakeProfit: ", TakeProfit);
   Print("StopLoss: ", StopLoss);

   if (orderType == ORDER_TYPE_BUY)
   {
      takeprofitprice = BuyStopPrice + TakeProfit;
      stoplossprice = BuyStopPrice - StopLoss;
   }
   else
   {
      takeprofitprice = SellStopPrice - TakeProfit;
      stoplossprice = SellStopPrice + StopLoss;
   }

   // Print out calculated Take Profit and Stop Loss prices
   Print("Calculated Take Profit Price: ", takeprofitprice);
   Print("Calculated Stop Loss Price: ", stoplossprice);
}
*/
//+------------------------------------------------------------------+
//| Function to calculate Take Profit and Stop Loss prices           |
//+------------------------------------------------------------------+
void CalculateTPSL(ENUM_ORDER_TYPE orderType, double openPrice, double BuyStopPrice, double SellStopPrice, double& takeprofitprice, double& stoplossprice)
{
   double pipsToPrice = PipsToPrice(TakeProfitPips, Symbol()); // Convert TakeProfitPips to price
   double stopLossPrice = PipsToPrice(StopLossPips, Symbol()); // Convert StopLossPips to price

   if (orderType == ORDER_TYPE_BUY)
   {
      takeprofitprice = BuyStopPrice + pipsToPrice;
      stoplossprice = BuyStopPrice - stopLossPrice;
   }
   else
   {
      takeprofitprice = SellStopPrice - pipsToPrice;
      stoplossprice = SellStopPrice + stopLossPrice;
   }

   // Print out calculated Take Profit and Stop Loss prices
   Print("Calculated Take Profit Price: ", takeprofitprice);
   Print("Calculated Stop Loss Price: ", stoplossprice);
}



//+------------------------------------------------------------------+
//| Function to calculate BuyStop and SellStop prices                |
//+------------------------------------------------------------------+
void CalculateStopPrices(ENUM_ORDER_TYPE orderType, double& BuyStopPrice, double& SellStopPrice)
{
   double openPrice;
   double takeprofitprice;
   double stoplossprice;

   // Use the global variable directly
   PipsDiff = PipsToPrice(PipsAway, Symbol());

   if (orderType == ORDER_TYPE_BUY)
   {
      openPrice = Ask;
      BuyStopPrice = openPrice + PipsDiff;
      SellStopPrice = openPrice - PipsDiff;
   }
   else
   {
      openPrice = Bid;
      BuyStopPrice = openPrice - PipsDiff;
      SellStopPrice = openPrice + PipsDiff;
   }

   CalculateTPSL(orderType, openPrice, BuyStopPrice, SellStopPrice, takeprofitprice, stoplossprice);
}


//+------------------------------------------------------------------+
//| Function to place BuyStop and SellStop orders                    |
//+------------------------------------------------------------------+
void OpenStopOrder()
{
   double BuyStopPrice;
   double SellStopPrice;
   double takeprofitprice = 0.0; // Initialize variables
   double stoplossprice = 0.0;

   // Calculate BuyStop and SellStop prices and their corresponding SL and TP
   CalculateStopPrices(ORDER_TYPE_BUY, BuyStopPrice, SellStopPrice);
   
   // Print out Ask and Bid prices
   Print("Ask Price: ", Ask);
   Print("Bid Price: ", Bid);

   // Place BuyStop order
   BuyStopTicket = OrderSend(Symbol(), OP_BUYSTOP, LotSize, BuyStopPrice, Slippage, 0, 0, "BuyStop Order", 0, 0, clrGreen);
   //BuyStopTicket = OrderSend(Symbol(), OP_BUYSTOP, LotSize, BuyStopPrice, Slippage, BuyStopPrice + (Point * TakeProfit), BuyStopPrice - (Point * StopLoss), "BuyStop Order", 0, 0, clrGreen);
   if (BuyStopTicket > 0)
   {
      Print("BuyStop order placed successfully.");
   }
   else
   {
      Print("Error placing BuyStop order: ", GetLastError());
      Print("Symbol: ", Symbol()); // Print the symbol for debugging
   }

   // Place SellStop order
   SellStopTicket = OrderSend(Symbol(), OP_SELLSTOP, LotSize, SellStopPrice, Slippage, 0, 0, "SellStop Order", 0, 0, clrRed);
   //SellStopTicket = OrderSend(Symbol(), OP_SELLSTOP, LotSize, SellStopPrice, Slippage, SellStopPrice - (Point * TakeProfit), SellStopPrice + (Point * StopLoss), "SellStop Order", 0, 0, clrRed);
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
//| Function to modify BuyStop and SellStop orders                   |
//+------------------------------------------------------------------+
void ModifyStopOrder()
{
   double newBuyStopPrice;
   double newSellStopPrice;
   double takeprofitprice;
   double stoplossprice;

   // Calculate BuyStop and SellStop prices and their corresponding SL and TP
   CalculateStopPrices(ORDER_TYPE_BUY, newBuyStopPrice, newSellStopPrice);

   // Recalculate stop loss and take profit for BuyStop order
   stoplossprice = newBuyStopPrice - (Point * StopLoss);
   takeprofitprice = newBuyStopPrice + (Point * TakeProfit);

   // Modify BuyStop order
   if (!OrderModify(BuyStopTicket, newBuyStopPrice, takeprofitprice, stoplossprice, 0, clrGreen))
   {
      Print("Error modifying BuyStop order: ", GetLastError());
      Print("Symbol: ", Symbol()); // Print the symbol for debugging
   }
   else
   {
      Print("BuyStop order modified successfully.");
   }

   // Recalculate stop loss and take profit for SellStop order
   stoplossprice = newSellStopPrice + (Point * StopLoss);
   takeprofitprice = newSellStopPrice - (Point * TakeProfit);

   // Modify SellStop order
   if (!OrderModify(SellStopTicket, newSellStopPrice, takeprofitprice, stoplossprice, 0, clrRed))
   {
      Print("Error modifying SellStop order: ", GetLastError());
      Print("Symbol: ", Symbol()); // Print the symbol for debugging
   }
   else
   {
      Print("SellStop order modified successfully.");
   }
}


/*
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







/*
// Function to place a buy stop order
bool BuyStopOrder(string symbol, double price, double volume)
{
	// Check if current Bid price is less than the specified stop price
	if (Bid < price)
	{
		// Order parameters
		int order_type = OP_BUYSTOP;
		double stop_price = price;
		int slippage = 5; // Set slippage tolerance
		
		// Place the buy stop order
		int order_ticket = OrderSend(symbol, order_type, volume, stop_price, slippage);
		if (order_ticket > 0)
		{
			// Order placed successfully
			Print("Buy stop order placed for ", symbol, " at ", price, " with volume ", volume, " and order ticket ", order_ticket);
			return true;
		}
		else
		{
			// Order placement failed
			Print("Error placing buy stop order: ", GetLastError());
			return false;
		}
	}
	else
	{
		Print("Current Bid price (" + MathToString(Bid) + ") is equal to or higher than the stop price (" + MathToString(price) + ")");
		return false;
	}
}
*/


/*
//+------------------------------------------------------------------+
//|                                                   NewsTrader.mq4 |
//|                                                     Forex Fellow |
//|                                              www.forexfellow.com |
//+------------------------------------------------------------------+
#property copyright "Forex Fellow"
#property link      "www.forexfellow.com"

int cnt, ticket =0, ticket2=0, total;
extern int lot = 1;
extern int sl = 10;
extern int tp = 10;
extern int bias = 20; //we place our order 20 pips from current price

double orderAsk;
double orderBid;
string OrderCloseDate;
      
int init()
  {
  Print(MarketInfo(Symbol(), MODE_STOPLEVEL));
   return(0);
  }
int deinit()
  {
   return(0);
  }
int start()
  {
   
   //we have to know the time and date of news publication
   //I don't want to write what sombody else has written here https://www.mql5.com/en/articles/1502
   //we can use this indicator to get the date and time of news publications
   //I have put here some example date and 
   int newsDateYear = 2010;
   int newsDateMonth = 3;
   int newsDateDay = 8;
   int newsDateHour = 1;
   int newsDateMinute = 30;
   
   //we need to open order before news publication
   newsDateMinute -= 10; //10 minutes before publication
   string orderOpenDate = newsDateDay + "-" + newsDateMonth + "-" + newsDateYear 
                                                + " " + newsDateHour + ":" + newsDateMinute + ":00";
   int currentYear = Year();
   int currentMonth = Month();
   int currentDay = Day();
   int currentHour = Hour();
   int currentMinute = Minute();
   
   //we get current time
   string currentDate = currentDay + "-" + currentMonth + "-" + currentYear 
                                                + " " + currentHour + ":" + currentMinute + ":00";
                                                             
   
   if(orderOpenDate == currentDate)
   { 
      //we place 2 orders: buy stop and sell stop
      if(ticket < 1)
      {
         orderAsk = Ask - bias * Point;
         orderBid = Bid - bias * Point;
         ticket=OrderSend(Symbol(),OP_SELLSTOP,lot,orderBid,1,orderAsk+Point*sl,orderBid-tp*Point,"NewsTrader",2,0,Red); 
      }
      if(ticket2 < 1)
      {
         orderAsk = Ask + bias * Point;
         orderBid = Bid + bias * Point;
         ticket2=OrderSend(Symbol(),OP_BUYSTOP,lot,orderAsk,1,orderBid-Point*sl,orderAsk+tp*Point,"NewsTrader",2,0,Green); 
      }         
   }
   
   
   return(0);
  }
  
*/


