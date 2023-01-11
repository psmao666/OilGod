#property copyright "PSMao"
#property link      "www.github.com/psmao666"
#property version   "1.00"
#property strict
#define MagicNumberLong 2000110266
#define MagicNumberShort 2000110233

input string USOIL="CL-OIL";       //WTI Symbol
input string UKOIL="UKOUSDft";       //BRENT Symbol
input double startLots = 0.1;
input double addLots = 0.03;
input double goGap = 0.2;
input double OpenGap = 0.5;
input double TakeProfitRatio = 500;
input int  MovingPeriod = 50;
input double    stime=3.1;                   //Start Time
input double    etime=23.9;                    //End Time

double current_long_lots = startLots, current_short_lots = startLots;
double LastLongGap = 0, LastShortGap = 0;

bool tradetime(int starttime,int endtime)
{
   return TimeHour(TimeCurrent()) >= starttime && TimeHour(TimeCurrent()) < endtime;     
}

bool hasLongPosition()
{
    for (int i = OrdersTotal() - 1; i >= 0; -- i)
     {
         if (!OrderSelect(i,SELECT_BY_POS)) break;
         if (OrderMagicNumber() != MagicNumberLong || (OrderSymbol()!=USOIL && OrderSymbol()!=UKOIL)) continue;
         
         return true;
     }
   return false;
}

bool hasShortPosition()
{
    for (int i = OrdersTotal() - 1; i >= 0; -- i)
     {
         if (!OrderSelect(i,SELECT_BY_POS)) break;
         if (OrderMagicNumber() != MagicNumberShort || (OrderSymbol()!=USOIL && OrderSymbol()!=UKOIL)) continue;
         return true;
     }
   return false;
}

void display(double GapMa, double priceGap, double upperband, double lowerband)
{
   ObjectCreate("Gap Average", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("Gap Average","Average Gap is "+GapMa, 32, "Verdana", White);
   ObjectSet("Gap Average", OBJPROP_CORNER, 0);
   ObjectSet("Gap Average", OBJPROP_XDISTANCE, 20);
   ObjectSet("Gap Average", OBJPROP_YDISTANCE, 20);
   ObjectCreate("current Average", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("current Average","Current Gap is "+priceGap, 32, "Verdana", White);
   ObjectSet("current Average", OBJPROP_CORNER, 0);
   ObjectSet("current Average", OBJPROP_XDISTANCE, 20);
   ObjectSet("current Average", OBJPROP_YDISTANCE, 100);
   ObjectCreate("upperband", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("upperband","upperband is "+upperband, 32, "Verdana", White);
   ObjectSet("upperband", OBJPROP_CORNER, 0);
   ObjectSet("upperband", OBJPROP_XDISTANCE, 20);
   ObjectSet("upperband", OBJPROP_YDISTANCE, 150);
   ObjectCreate("lowerband", OBJ_LABEL, 0, 0, 0);
   ObjectSetText("lowerband","lowerband is "+lowerband, 32, "Verdana", White);
   ObjectSet("lowerband", OBJPROP_CORNER, 0);
   ObjectSet("lowerband", OBJPROP_XDISTANCE, 20);
   ObjectSet("lowerband", OBJPROP_YDISTANCE, 200);
}


void checkForCloseLong()
{
    double profit = 0;
    double lots = 0;
    for (int i = OrdersTotal() - 1; i >= 0; -- i)
    {
       if (!OrderSelect(i, SELECT_BY_POS)) break;
       if (OrderMagicNumber() != MagicNumberLong) continue;
       profit += OrderProfit();
       lots += OrderLots();
    }
    
    if (lots * TakeProfitRatio / 2 > profit) return;
    
    for (int i = OrdersTotal() - 1; i >= 0; -- i)
    {
       if (!OrderSelect(i, SELECT_BY_POS)) break;
       if (OrderMagicNumber() != MagicNumberLong) continue;
       string instru = OrderSymbol();
       double price = 0;
       if (OrderType() == OP_BUY) price = NormalizeDouble(MarketInfo(instru,MODE_ASK),(int)MarketInfo(UKOIL,MODE_DIGITS));
       else price = NormalizeDouble(MarketInfo(instru,MODE_BID),(int)MarketInfo(UKOIL,MODE_DIGITS)); 
       
       if (!OrderClose(OrderTicket(), OrderLots(), price, 20, Red))
         Print("Error on closing orders");         
    }
         
}
void checkForCloseShort()
{
    double profit = 0;
    double lots = 0;
    for (int i = OrdersTotal() - 1; i >= 0; -- i)
    {
       if (!OrderSelect(i, SELECT_BY_POS)) break;
       if (OrderMagicNumber() != MagicNumberShort) continue;
       profit += OrderProfit();
       lots += OrderLots();
    }
    
    if (lots * TakeProfitRatio / 2 > profit) return;
    
    
    for (int i = OrdersTotal() - 1; i >= 0; -- i)
    {
       if (!OrderSelect(i, SELECT_BY_POS)) break;
       if (OrderMagicNumber() != MagicNumberShort) continue;
       string instru = OrderSymbol();
       double price = 0;
       if (OrderType() == OP_BUY) price = NormalizeDouble(MarketInfo(instru,MODE_ASK),(int)MarketInfo(UKOIL,MODE_DIGITS));
       else price = NormalizeDouble(MarketInfo(instru,MODE_BID),(int)MarketInfo(UKOIL,MODE_DIGITS)); 
       
       if (!OrderClose(OrderTicket(), OrderLots(), price, 20, Red))
         Print("Error on closing orders");         
    }
}


void doShort()
{
    int tkt1, tkt2;
    double priceDiff = NormalizeDouble(MarketInfo(UKOIL,MODE_ASK)-MarketInfo(USOIL,MODE_BID),(int)MarketInfo(UKOIL,MODE_DIGITS));
    
    if (priceDiff - LastShortGap >= goGap) 
    {
      tkt1 = OrderSend(UKOIL,OP_SELL,current_short_lots,MarketInfo(UKOIL,MODE_ASK),20,0,0,"short the spread",MagicNumberShort);
      tkt2 = OrderSend(USOIL,OP_BUY,current_short_lots,MarketInfo(USOIL,MODE_BID),20,0,0,"short the spread",MagicNumberShort);
      current_short_lots += addLots;
      LastShortGap = priceDiff;
    }
}

void doLong()
{
    int tkt1, tkt2;
    double priceDiff = NormalizeDouble(MarketInfo(UKOIL,MODE_BID)-MarketInfo(USOIL,MODE_ASK),(int)MarketInfo(UKOIL,MODE_DIGITS));
    
    if (LastLongGap - priceDiff >= goGap) 
    {
      tkt1 = OrderSend(USOIL,OP_SELL,current_long_lots,MarketInfo(USOIL,MODE_ASK),20,0,0,"long the spread",MagicNumberLong);
      tkt2 = OrderSend(UKOIL,OP_BUY,current_long_lots,MarketInfo(UKOIL,MODE_BID),20,0,0,"long the spread",MagicNumberLong);
      current_long_lots += addLots;
      LastLongGap = priceDiff;
    }
}
void tryshort()
{

    double usoilMa = iMA(USOIL,0,MovingPeriod,6,MODE_EMA,PRICE_OPEN,0);
    double ukoilMa = iMA(UKOIL,0,MovingPeriod,6,MODE_EMA,PRICE_OPEN,0);
    double GapMa = ukoilMa - usoilMa;
    
    double upperBand = OpenGap + GapMa;
    
    int tkt1, tkt2;
    double priceDiff = NormalizeDouble(MarketInfo(UKOIL,MODE_ASK)-MarketInfo(USOIL,MODE_BID),(int)MarketInfo(UKOIL,MODE_DIGITS));
    
    if (priceDiff >= upperBand) 
    {
      // short UKOIL, long USOIL
      tkt1 = OrderSend(UKOIL,OP_SELL,current_short_lots,MarketInfo(UKOIL,MODE_ASK),20,0,0,"short the spread",MagicNumberShort);
      tkt2 = OrderSend(USOIL,OP_BUY,current_short_lots,MarketInfo(USOIL,MODE_BID),20,0,0,"short the spread",MagicNumberShort);
      current_short_lots += addLots;
      LastShortGap = priceDiff;
    }
}

void trylong()
{

    double usoilMa = iMA(USOIL,0,MovingPeriod,6,MODE_EMA,PRICE_OPEN,0);
    double ukoilMa = iMA(UKOIL,0,MovingPeriod,6,MODE_EMA,PRICE_OPEN,0);
    double GapMa = ukoilMa - usoilMa;
   
    double lowerBand = GapMa - OpenGap;
    
    int tkt1, tkt2;
    double priceDiff = NormalizeDouble(MarketInfo(UKOIL,MODE_BID)-MarketInfo(USOIL,MODE_ASK),(int)MarketInfo(UKOIL,MODE_DIGITS));
    
    
    if (priceDiff <= lowerBand)
    {
      // short USOIL, long UKOIL
      tkt1 = OrderSend(USOIL,OP_SELL,current_long_lots,MarketInfo(USOIL,MODE_ASK),20,0,0,"long the spread",MagicNumberLong);
      tkt2 = OrderSend(UKOIL,OP_BUY,current_long_lots,MarketInfo(UKOIL,MODE_BID),20,0,0,"long the spread",MagicNumberLong);
      current_long_lots += addLots;
      LastLongGap = priceDiff;
    }
}

void checkForOpen()
{
    if (hasShortPosition()) doShort();
    else tryshort();
    if (hasLongPosition()) doLong();
    else trylong();
    
}
void checkForClose()
{
   if (hasLongPosition()) checkForCloseLong();
   if (hasShortPosition()) checkForCloseShort();
}

void OnTick()
{
    if (Bars < 3 || IsTradeAllowed() == false) return;
    if (tradetime(stime,etime) == false) return;
    
    double usoilMa = iMA(USOIL,0,MovingPeriod,6,MODE_EMA,PRICE_OPEN,0);
    double ukoilMa = iMA(UKOIL,0,MovingPeriod,6,MODE_EMA,PRICE_OPEN,0);
    double GapMa = ukoilMa - usoilMa;
    double upperband = GapMa + OpenGap;
    double lowerband = GapMa - OpenGap;
    
    double priceDiff = NormalizeDouble(MarketInfo(UKOIL,MODE_BID)-MarketInfo(USOIL,MODE_ASK),(int)MarketInfo(UKOIL,MODE_DIGITS));
    
    display(GapMa, priceDiff, upperband, lowerband);
    
    checkForClose();
    checkForOpen();

}
