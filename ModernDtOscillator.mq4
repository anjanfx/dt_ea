//+------------------------------------------------------------------+
//|                                           ModernDtOscillator.mq4 |
//|                                                      nicholishen |
//|                         https://www.forexfactory.com/nicholishen |
//+------------------------------------------------------------------+
#property copyright "nicholishen"
#property link      "https://www.forexfactory.com/nicholishen"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_minimum 0
#property indicator_maximum 100
#property indicator_level1 30
#property indicator_level2 70
#property indicator_buffers 5
#property indicator_plots   2
//--- plot Main
#property indicator_label1  "Main"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- plot Signal
#property indicator_label2  "Signal"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDodgerBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1
//--- input parameters
input int               inp_period_rsi = 13;
input int               inp_period_sto = 8;
input int               inp_period_sk  = 5;
input int               inp_period_sd  = 3;
input ENUM_MA_METHOD    inp_ma_method  = MODE_SMA;
//--- indicator buffers
double         MainBuffer[];
double         SignalBuffer[];
double         StoRSI[];
double         RSI[];
double         RatesTotal[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,MainBuffer);
   SetIndexBuffer(1,SignalBuffer);
   SetIndexBuffer(2,StoRSI, INDICATOR_CALCULATIONS);
   SetIndexBuffer(3,RSI, INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,RatesTotal, INDICATOR_CALCULATIONS);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
//---         
   int limit = rates_total - prev_calculated - inp_period_rsi - 1;
   if(limit < 0)
      limit = 0;
   for(int i=limit; i>=0; i--)
   {
      RSI[i] = iRSI(_Symbol, _Period, inp_period_rsi, PRICE_CLOSE, i);
      double LLV = RSI[ArrayMinimum(RSI,inp_period_sto,i)];
      double HHV = RSI[ArrayMaximum(RSI,inp_period_sto,i)];
      if(HHV - LLV != 0)
         StoRSI[i] = 100.0 * ((RSI[i] - LLV) / (HHV - LLV));
      else  
         StoRSI[i] = 0;
   }   
   for(int i=limit; i>=0; i--) 
      MainBuffer[i] = iMAOnArray(StoRSI, 0, inp_period_sk, 0, inp_ma_method, i);
   for(int i=limit; i>=0; i--) 
      SignalBuffer[i] = iMAOnArray(MainBuffer, 0, inp_period_sd, 0, inp_ma_method, i);
//--- return value of prev_calculated for next call
   RatesTotal[0] = rates_total - inp_period_rsi;
   return(rates_total);
  }
//+------------------------------------------------------------------+
