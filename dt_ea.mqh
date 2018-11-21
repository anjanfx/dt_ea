#include "niclib.mqh"
#include "dt_ind.mqh"

#define MAGIC 661666
#define EXPERT DtExpert

input int inp_max_concurrent_trades = 5;//Max concurrent trades
input double inp_lots = 0.1;//Lots
input int inp_stop_pips = 100;//SL pips
input int inp_take_pips = 100;//TP pips

input ENUM_TIMEFRAMES inp_dt1_timeframe = PERIOD_M15;//Lowest TimeFrame
input int inp_dt1_rsi_period = 13;//RSI period
input int inp_dt1_sto_period = 8;//STO period
input int inp_dt1_sk_period = 5;//K period
input int inp_dt1_sd_period = 3;//D period

input ENUM_TIMEFRAMES inp_dt2_timeframe = PERIOD_H1;//Middle TimeFrame
input int inp_dt2_rsi_period = 13;//RSI period
input int inp_dt2_sto_period = 8;//STO period
input int inp_dt2_sk_period = 5;//K period
input int inp_dt2_sd_period = 3;//D period

input ENUM_TIMEFRAMES inp_dt3_timeframe = PERIOD_H4;//Highest TimeFrame
input int inp_dt3_rsi_period = 13;//RSI period
input int inp_dt3_sto_period = 8;//STO period
input int inp_dt3_sk_period = 5;//K period
input int inp_dt3_sd_period = 3;//D period


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

class DtExpert : public Expert
{
 protected:
   CiDtOscillator m_dt1;
   CiDtOscillator m_dt2;
   CiDtOscillator m_dt3;
   bool           m_indicators_ready;
 public: //overrides
   DtExpert():m_indicators_ready(false){}
   virtual bool on_init(const int magic, const string symbol=NULL) override; 
   virtual bool on_tick() override;
   virtual int  signals() override;
 public: //unique
   bool can_trade();
 protected:
   bool indicators_ready();
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

bool DtExpert::on_init(const int magic, const string symbol=NULL) override 
{
   if(!Expert::on_init(magic, symbol))
      return false;
   bool create1 = m_dt1.Create(m_symbol, 
      inp_dt1_timeframe, 
      inp_dt1_rsi_period, 
      inp_dt1_sto_period, 
      inp_dt1_sk_period, 
      inp_dt1_sd_period
   );
   bool create2 = m_dt2.Create(m_symbol, 
      inp_dt2_timeframe, 
      inp_dt2_rsi_period, 
      inp_dt2_sto_period, 
      inp_dt2_sk_period, 
      inp_dt2_sd_period
   );
   bool create3 = m_dt3.Create(m_symbol, 
      inp_dt3_timeframe, 
      inp_dt3_rsi_period, 
      inp_dt3_sto_period, 
      inp_dt3_sk_period, 
      inp_dt3_sd_period
   );
   return (create1 && create2 && create3);
}

bool DtExpert::on_tick(void) override
{
   if(!Expert::on_tick() || !indicators_ready())
      return false;
   if(can_trade()){
      int signal = this.signals();
      if(this.check_signal(XLONG_STRONG, signal)) {
         return this._market_buy(
            inp_lots, 
            inp_stop_pips * m_pip_mod, 
            inp_take_pips * m_pip_mod
         );
      }
      if(this.check_signal(XSHORT_STRONG, signal)) {
         return this._market_sell(
            inp_lots, 
            inp_stop_pips * m_pip_mod, 
            inp_take_pips * m_pip_mod
         );
      }
   }
   return true;
}

int DtExpert::signals(void)
{
   if(m_dt3.Main(0) > m_dt3.Signal(0)
      && m_dt2.Main(0) > m_dt2.Signal(0)
      && m_dt1.Main(0) > m_dt1.Signal(0)
      && m_dt1.Main(1) < 25
      && m_dt1.Main(1) <= m_dt1.Signal(1)
   ){
      return XLONG_STRONG|XLONG_WEAK;
   }
   if(m_dt3.Main(0) < m_dt3.Signal(0)
      && m_dt2.Main(0) < m_dt2.Signal(0)
      && m_dt1.Main(0) < m_dt1.Signal(0)
      && m_dt1.Main(1) > 75
      && m_dt1.Main(1) >= m_dt1.Signal(1)
   ){
      return XSHORT_STRONG|XSHORT_WEAK;
   }
   return XNONE;
}

bool DtExpert::can_trade(void)
{
   if(!this._refresh_pool())
      return false;
   objvector<Ticket*> tickets;
   tickets.FreeMode(false);
   tickets.AddArray(&m_positions_long);
   tickets.AddArray(&m_positions_short);
   int total = tickets.Total();
   if(total == 0)
      return true;
   if(total >= inp_max_concurrent_trades)
      return false;
   MqlRates rates[];
   int copied = CopyRates(m_symbol, 
      inp_dt1_timeframe, 0, 1, rates
   );
   if(copied < 1)
      return false;
   for(int i=tickets.Total()-1; i>=0; --i) {
      if(!tickets[i].select()
         || OrderOpenTime() >= rates[0].time
      ){
         return false;
      }
   }
   return true;
}

bool DtExpert::indicators_ready(void)
{
   if(m_indicators_ready)
      return true;
   objvector<CiDtOscillator*> indies;
   indies.Add(&m_dt1);
   indies.Add(&m_dt2);
   indies.Add(&m_dt3);
   bool res = true;
   for(int i=indies.Total()-1; i>=0; --i){
      ResetLastError();
      double dummy_val = indies[i].Main(1);
      if(GetLastError() != ERR_NO_ERROR) 
         res = false;
   }
   m_indicators_ready = res;
   return res;
}