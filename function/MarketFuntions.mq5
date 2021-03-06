#property library
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property version   "1.0"

#include <Trade/Trade.mqh>
CTrade trade;
MqlTick tick;

bool MarketBuy(int num, double sl, double tp)
  {
   trade.Buy(num,_Symbol,NormalizeDouble(tick.ask,_Digits),NormalizeDouble(sl, _Digits), NormalizeDouble(tp, _Digits));
   return CheckError(trade.ResultRetcode());
  }

bool MarketSell(int num, double sl, double tp)
  {
   trade.Sell(num,_Symbol,NormalizeDouble(tick.ask,_Digits),NormalizeDouble(sl, _Digits), NormalizeDouble(tp, _Digits));
   return CheckError(trade.ResultRetcode());
  }

bool ModifyPosition(double sl, double tp){
   trade.PositionModify(PositionGetTicket(0),sl, tp);
   return CheckError(trade.ResultRetcode());
}  

bool ClosePosition()
  {
   ulong ticket = PositionGetTicket(0);
   trade.PositionClose(ticket);
   return CheckError(trade.ResultRetcode());
  }

bool CheckError(int resultRetCode, int code=2)
  {
   if((resultRetCode == 10008 && code == 1) || resultRetCode == 10009)
     {
      Print("Cod: ", resultRetCode, "Ordem Executada com Sucesso!");
      return true;
     }
   else
     {
      Print("Execution Error: ", GetLastError());
      ResetLastError();
      return false;
     }
  }
//+------------------------------------------------------------------+
