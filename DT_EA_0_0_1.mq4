//+------------------------------------------------------------------+
//|                                                  DT_EA_0_0_1.mq4 |
//|                                                      nicholishen |
//|                         https://www.forexfactory.com/nicholishen |
//+------------------------------------------------------------------+
#property strict
#include "dt_ea.mqh"

__EXPERT__ *expert;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   expert = new __EXPERT__(); //MACRO overwrites this with proper class name
   if(!expert.on_init(MAGIC)) //MAGIC always needs to be defined in the header file
      return INIT_FAILED;
   return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(!expert.on_deinit(reason))
      Print(VERBOSE_ERROR);
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

