#property copyright "PSMao"
#property link      "www.github.com/psmao666"
#property version   "1.00"
#property strict
#define MagicNumberLong 2000110266
#define MagicNumberShort 2000110233

input string USOIL="CL-OIL";       //WTI Symbol
input string UKOIL="UKOUSDft";       //BRENT Symbol
input double start_short_position = 0;
input double start_long_position = 0;
input double startLots = 1;
input double addLots = 0.1;
input double goGap = 0.5;
input double TakeProfitRatio = 0.03;
input double StopLossRatio = 0.3;

double current_long_lots = startLots, current_short_lots = startLots;
double LastLongGap = 0, LastShortGap = 0;


void Init()
{
    current_long_lots = NormalizeDouble(AccountBalance()/20000*startLots,2);
    current_short_lots = NormalizeDouble(AccountBalance()/20000*startLots,2);
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

void checkForCloseLong()
{
    double Profit = 0;
    for (int i = 0; i < OrdersTotal(); ++ i)
    {
         if (!OrderSelect(i,SELECT_BY_POS)) break;
         if (OrderMagicNumber() != MagicNumberLong || (OrderSymbol()!=USOIL && OrderSymbol()!=UKOIL)) continue;
         Profit += OrderProfit();
    }
    if (Profit >= TakeProfitRatio * AccountBalance() || 
         Profit <= -1 * StopLossRatio * AccountBalance())
    {
    
      Print("Profit = ", Profit, " current cutloss target is ", -1 * StopLossRatio * AccountBalance());
      for (int i = OrdersTotal() - 1; i >= 0; -- i) // close all orders
      {
         if (!OrderSelect(i,SELECT_BY_POS)) break;
         if (OrderMagicNumber() != MagicNumberLong || (OrderSymbol()!=USOIL && OrderSymbol()!=UKOIL)) continue;
         
         int modUK, modUS, finMode;
         //if (direction == Short) {modUK = MODE_BID; modUS = MODE_ASK;}
         //else {
         modUK = MODE_ASK; 
         modUS = MODE_BID;
         if (OrderSymbol() == USOIL) finMode = modUS;
         else finMode = modUK;
          
         if (!OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),finMode),20))
            Print("Error on Closing");
      }
      Init();
      LastLongGap = 0;
    }
}
void checkForCloseShort()
{
    double Profit = 0;
    for (int i = 0; i < OrdersTotal(); ++ i)
    {
         if (!OrderSelect(i,SELECT_BY_POS)) break;
         if (OrderMagicNumber() != MagicNumberShort || (OrderSymbol()!=USOIL && OrderSymbol()!=UKOIL)) continue;
         Profit += OrderProfit();
    }
    if (Profit >= TakeProfitRatio * AccountBalance() || 
         Profit <= -1 * StopLossRatio * AccountBalance())
    {
    
      Print("Profit = ", Profit, " current cutloss target is ", -1 * StopLossRatio * AccountBalance());
      for (int i = OrdersTotal() - 1; i >= 0; -- i) // close all orders
      {
         if (!OrderSelect(i,SELECT_BY_POS)) break;
         if (OrderMagicNumber() != MagicNumberShort || (OrderSymbol()!=USOIL && OrderSymbol()!=UKOIL)) continue;
         
         int modUK, modUS, finMode;
         modUK = MODE_BID; 
         modUS = MODE_ASK;
         
         if (OrderSymbol() == USOIL) finMode = modUS;
         else finMode = modUK;
          
         if (!OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),finMode),20))
            Print("Error on Closing");
      }
      Init();
      LastShortGap = 0;
    }
}

void doShort()
{
    int tkt1, tkt2;
    double priceDiff = NormalizeDouble(MarketInfo(UKOIL,MODE_BID)-MarketInfo(USOIL,MODE_BID),(int)MarketInfo(UKOIL,MODE_DIGITS));
    
    if (priceDiff - LastShortGap >= goGap) 
    {
      tkt1 = OrderSend(UKOIL,OP_SELL,current_short_lots,MarketInfo(UKOIL,MODE_BID),20,0,0,"short the spread",MagicNumberShort);
      tkt2 = OrderSend(USOIL,OP_BUY,current_short_lots,MarketInfo(USOIL,MODE_ASK),20,0,0,"short the spread",MagicNumberShort);
      current_short_lots += addLots;
      LastShortGap = priceDiff;
    }
}

void doLong()
{
    int tkt1, tkt2;
    double priceDiff = NormalizeDouble(MarketInfo(UKOIL,MODE_BID)-MarketInfo(USOIL,MODE_BID),(int)MarketInfo(UKOIL,MODE_DIGITS));
    
    if (LastLongGap - priceDiff >= goGap) 
    {
      tkt1 = OrderSend(USOIL,OP_SELL,current_long_lots,MarketInfo(USOIL,MODE_BID),20,0,0,"long the spread",MagicNumberLong);
      tkt2 = OrderSend(UKOIL,OP_BUY,current_long_lots,MarketInfo(UKOIL,MODE_ASK),20,0,0,"long the spread",MagicNumberLong);
      current_long_lots += addLots;
      LastLongGap = priceDiff;
    }
}
void tryshort()
{

    int tkt1, tkt2;
    double priceDiff = NormalizeDouble(MarketInfo(UKOIL,MODE_BID)-MarketInfo(USOIL,MODE_BID),(int)MarketInfo(UKOIL,MODE_DIGITS));
    
    if (priceDiff >= start_short_position) 
    {
      // short UKOIL, long USOIL
      tkt1 = OrderSend(UKOIL,OP_SELL,current_short_lots,MarketInfo(UKOIL,MODE_BID),20,0,0,"short the spread",MagicNumberShort);
      tkt2 = OrderSend(USOIL,OP_BUY,current_short_lots,MarketInfo(USOIL,MODE_ASK),20,0,0,"short the spread",MagicNumberShort);
      current_short_lots += addLots;
    }
}
void trylong()
{

    int tkt1, tkt2;
    double priceDiff = NormalizeDouble(MarketInfo(UKOIL,MODE_BID)-MarketInfo(USOIL,MODE_BID),(int)MarketInfo(UKOIL,MODE_DIGITS));
    
    if (priceDiff <= start_long_position)
    {
      // short USOIL, long UKOIL
      tkt1 = OrderSend(USOIL,OP_SELL,current_long_lots,MarketInfo(USOIL,MODE_BID),20,0,0,"long the spread",MagicNumberLong);
      tkt2 = OrderSend(UKOIL,OP_BUY,current_long_lots,MarketInfo(UKOIL,MODE_ASK),20,0,0,"long the spread",MagicNumberLong);
      current_long_lots += addLots;
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
   checkForCloseLong();
   checkForCloseShort();
}

void OnInit()
{
   Init();
}

void OnTick()
{
    if (Bars < 3 || IsTradeAllowed() == false) return;

    checkForClose();
    checkForOpen();

}
