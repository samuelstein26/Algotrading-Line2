#property copyright "Copyright 2021, MetaQuotes Ltd."
#property version   "1.0"

#include <function\MarketFuntions.mq5>

//+------------------------------------------------------------------+
//| SETUP parameters                                                 |
//+------------------------------------------------------------------+
//--- Moving Average 21 (fast)
int emaExpoFast = 21;                   
ENUM_MA_METHOD emaMethodSlow = MODE_EMA;
int emaFastHandle;
double emaFastBuffer[];

//--- Moving Average 72 (slow)
int emaExpoSlow = 72;
ENUM_MA_METHOD emaMethodFast = MODE_EMA;
int emaSlowHandle;
double emaSlowBuffer[];

//--- RSI indicator
int rsiHandle;
double rsiBuffer[];
double ma_period_rsi = 14;
ENUM_APPLIED_PRICE applied_price_rsi = PRICE_CLOSE;
int rsi_nivel_sup = 58;
int rsi_nivel_inf = 38;

//--- Others
MqlRates candles[];
ENUM_TIMEFRAMES graphicPeriod = PERIOD_M10;
ENUM_APPLIED_PRICE emaPrice = PRICE_CLOSE;
const int numberOperationPerDay = 2;
double lastOpen = 0;
int num_lots = 1, start = 0, numberOperation = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   emaSlowHandle  = iMA(_Symbol,graphicPeriod,emaExpoSlow,0,emaMethodSlow,emaPrice);
   emaFastHandle = iMA(_Symbol,graphicPeriod,emaExpoFast,0,emaMethodFast,emaPrice);
   rsiHandle = iRSI(_Symbol, graphicPeriod, ma_period_rsi, applied_price_rsi);

   if(emaSlowHandle<0 || emaFastHandle<0 || rsiHandle<0)
     {
      Alert("Error to create handles: ", GetLastError(), "!");
      return(-1);
     }

   CopyRates(_Symbol,_Period,0,4,candles);
   ChartIndicatorAdd(0,0,emaSlowHandle);
   ChartIndicatorAdd(0,0,emaFastHandle);
   ChartIndicatorAdd(0,0,rsiHandle);
   ArraySetAsSeries(emaSlowBuffer,true);
   ArraySetAsSeries(emaFastBuffer,true);
   ArraySetAsSeries(rsiBuffer,true);
   ArraySetAsSeries(candles,true);
   
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(emaSlowHandle);
   IndicatorRelease(emaFastHandle);
   IndicatorRelease(rsiHandle);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   CopyBuffer(emaSlowHandle,0,0,4,emaSlowBuffer);
   CopyBuffer(emaFastHandle,0,0,4,emaFastBuffer);
   CopyBuffer(rsiHandle,0,0,2,rsiBuffer);
   
   CopyRates(_Symbol,_Period,0,4,candles);
   SymbolInfoTick(_Symbol,tick);

   double maFast = floor(emaFastBuffer[0]);
   double maSlow = floor(emaSlowBuffer[0]);
   double rsi = round(rsiBuffer[0]);
   double openCandle = floor(iOpen(_Symbol,graphicPeriod,0));
   bool timeBetween = CheckTime();
   double takeProfitValue = 10;
   double stopLossValue = 12;

   if(CheckTime())
     {
      if(PositionSelect(_Symbol) == false)
        {
         if(openCandle != lastOpen)
           {
            lastOpen = openCandle;
            bool executeRSI = RsiEntryOperation(rsi, rsi_nivel_inf, rsi_nivel_sup);

            if(!executeRSI)
              {
               ++start;
              }

            if(start > 2 && numberOperation < numberOperationPerDay)
              {
               if(openCandle > maFast && executeRSI)
                 {
                  MarketBuy(num_lots, openCandle-stopLossValue, openCandle+takeProfitValue);
                  numberOperation++;
                  start = 0;
                 }
               else
                  if(openCandle < maFast && executeRSI)
                    {
                     MarketSell(num_lots, openCandle+stopLossValue, openCandle-takeProfitValue);
                     numberOperation++;
                     start = 0;
                    }
              }
           }
        }
      else // PositionSelect(_Symbol) == true
        {
         breakEven();
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
           {
            if(openCandle < maFast || !RsiKeepOperation(rsi, 1))
              {
               ClosePosition();

              }
           }
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
           {
            if(openCandle > maFast || !RsiKeepOperation(rsi, 2))
              {
               ClosePosition();

              }
           }
        }
     }
   else
     {
      start = 0;
      if(PositionSelect(_Symbol))
        {
         ClosePosition();
        }
      numberOperation = 0;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool RsiEntryOperation(double rsi, double rsiInf, double rsiSup)
  {
   if(rsi <= rsiInf || rsi >= rsiSup)
     {
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool RangeToEnter(double open, double ma, double limit)
  {
   if(fabs(open - ma) <= limit)
     {
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool RsiKeepOperation(double rsi, double operationType)
  {
   /*operationType Description
   1 = buy
   2 = sell
   */
   if((rsi > 50 && operationType == 1) || (rsi < 50 && operationType == 2))
     {
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckTime()
  {
   MqlDateTime hourActual;
   TimeToStruct(TimeCurrent(), hourActual);
   int a = hourActual.hour * 60 + hourActual.min;
   int hStart = 549; //9:10
   int hFinish = 960; //16:00

   if(a >= hStart && a <= hFinish)
     {
      return true;
     }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void breakEven()
  {
   double change = 0;
   double slNow=0, tpNow=0, priceOpen=0, priceNow=0;
   bool doChange = false;

   if(PositionSelect(_Symbol))
     {
      slNow = floor(PositionGetDouble(POSITION_SL));
      tpNow = floor(PositionGetDouble(POSITION_TP));
      priceOpen = floor(PositionGetDouble(POSITION_PRICE_OPEN));
      priceNow = floor(tick.last);
     }

   if(((PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL) && priceNow < priceOpen) ||
      ((PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) && priceNow > priceOpen))
     {
      double value = fabs(priceOpen - priceNow);

      if(value >= 8)
        {
         doChange = true;
         if(value <= 10)
           {
            change = 2;
           }
        }

      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
        {
         if(floor(priceOpen - change) < floor(slNow) && doChange)
           {
            if(ModifyPosition(priceOpen - change, tpNow) == false)
              {
               Print("Error modifying price");
              }
           }
        }
      else
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)
           {
            if(floor(priceOpen + change) > floor(slNow) && doChange)  //POSITION_TYPE_BUY
              {
               if(ModifyPosition(priceOpen + change, tpNow) == false)
                 {
                  Print("Error modifying price");
                 }
              }
           }
     }
  }