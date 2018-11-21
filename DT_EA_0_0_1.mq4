//+------------------------------------------------------------------+
//|                                                  DT_EA_0_0_1.mq4 |
//|                                                      nicholishen |
//|                         https://www.forexfactory.com/nicholishen |
//+------------------------------------------------------------------+
#property strict

#include "dt_ea.mqh"

__EXPERT__ *expert;
//+------------------------------------------------------------------+
int OnInit()
{
   //__EXPERT__ macro overwrites this with proper class name
   //MAGIC always needs to be defined in the header file
   expert = new __EXPERT__(MAGIC); 
   if(!expert.on_init()) 
      return INIT_FAILED;
   return INIT_SUCCEEDED;
}
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(!expert.on_deinit(reason))
      Print(VERBOSE_ERROR);
   delete expert;
}
//+------------------------------------------------------------------+
void OnTick()
{
   if(!expert.on_tick())
      Print(VERBOSE_ERROR);
}
//+------------------------------------------------------------------+
void OnTimer()
{
   if(!expert.on_timer())
      Print(VERBOSE_ERROR);
}
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
