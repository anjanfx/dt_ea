//+------------------------------------------------------------------+
//|                                                  DT_EA_0_0_1.mq4 |
//|                                                      nicholishen |
//|                         https://www.forexfactory.com/nicholishen |
//+------------------------------------------------------------------+
#property strict
#include "dt_ea.mqh"

EXPERT *expert;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   expert = new EXPERT();
   if(!expert.on_init(MAGIC))
      return INIT_FAILED;
   return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   expert.on_deinit(reason);
   delete expert;
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!expert.on_tick())
      Print(VERBOSE_ERROR);
}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   if(!expert.on_timer())
      Print(VERBOSE_ERROR);
}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if(!expert.on_chartevent(id, lparam, dparam, sparam))
      Print(VERBOSE_ERROR);
}
//+------------------------------------------------------------------+

