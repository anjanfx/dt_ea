#define COMPILED_FOR_BUILD 1147

#include "niclib.mqh"
#include "dt_ind.mqh"
#include "dt_ui.mqh"

//INPUTS
input bool inp_use_gui = true;            //GUI
input int inp_max_concurrent_trades = 5;  //Max concurrent trades
input double inp_lots = 0.1;              //Lots
input int inp_stop_pips = 100;            //SL pips
input int inp_take_pips = 100;            //TP pips
input bool inp_alerts = true;             //Alert on Trade
input ENUM_TIMEFRAMES inp_dt1_timeframe = PERIOD_M15;//Lowest TimeFrame
input int inp_dt1_rsi_period = 13;        //RSI period
input int inp_dt1_sto_period = 8;         //STO period
input int inp_dt1_sk_period = 5;          //K period
input int inp_dt1_sd_period = 3;          //D period

input ENUM_TIMEFRAMES inp_dt2_timeframe = PERIOD_H1;//Middle TimeFrame
input int inp_dt2_rsi_period = 13;        //RSI period
input int inp_dt2_sto_period = 8;         //STO period
input int inp_dt2_sk_period = 5;          //K period
input int inp_dt2_sd_period = 3;          //D period

input ENUM_TIMEFRAMES inp_dt3_timeframe = PERIOD_H4;//Highest TimeFrame
input int inp_dt3_rsi_period = 13;        //RSI period
input int inp_dt3_sto_period = 8;         //STO period
input int inp_dt3_sk_period = 5;          //K period
input int inp_dt3_sd_period = 3;          //D period

//+------------------------------------------------------------------+
//| DtExpert headers. The main program. 
//+------------------------------------------------------------------+
#define MAGIC 661666
#define __EXPERT__ DtExpert

class DtExpert : public Expert
{
 protected:
   CiDtOscillator m_dt1;
   CiDtOscillator m_dt2;
   CiDtOscillator m_dt3;
   bool           m_indicators_ready;
   string         m_ea_name;
   DtGui           m_gui;
 public: //overrides
   DtExpert(const int magic):Expert(magic),
                             m_indicators_ready(false),
                             m_ea_name("3 Level DT"){}
   virtual bool   on_chartevent( const int    id,
                                 const long   &lparam,
                                 const double &dparam,
                                 const string &sparam) override;
   virtual bool   on_init(const string symbol=NULL) override; 
   virtual bool   on_deinit(const int reason) override;
   virtual bool   on_tick() override;
   virtual int    signals() override;
 public: //unique
   bool           can_trade();
   void           alert(const int ticket);
 protected:
   bool           _indicators_ready();
};
//+------------------------------------------------------------------+
//| DtExpert src
//+------------------------------------------------------------------+

bool DtExpert::on_init(const string symbol=NULL) override 
{
   if(!Expert::on_init(symbol))
      return false;
   if(!(bool)MQLInfoInteger(MQL_TRADE_ALLOWED))
      return false;
   bool create1 = m_dt1.Create(
      m_symbol.Name(), 
      inp_dt1_timeframe, 
      inp_dt1_rsi_period, 
      inp_dt1_sto_period, 
      inp_dt1_sk_period, 
      inp_dt1_sd_period
   );
   bool create2 = m_dt2.Create(
      m_symbol.Name(), 
      inp_dt2_timeframe, 
      inp_dt2_rsi_period, 
      inp_dt2_sto_period, 
      inp_dt2_sk_period, 
      inp_dt2_sd_period
   );
   bool create3 = m_dt3.Create(
      m_symbol.Name(), 
      inp_dt3_timeframe, 
      inp_dt3_rsi_period, 
      inp_dt3_sto_period, 
      inp_dt3_sk_period, 
      inp_dt3_sd_period
   );
   int build = TerminalInfoInteger(TERMINAL_BUILD);
   if(build != COMPILED_FOR_BUILD) {
      printf("WARNING: %s was compiled for terminal build %d"
         + " and your current build is %d.",
         m_ea_name, COMPILED_FOR_BUILD, build
      );
   }
   bool init = (create1 && create2 && create3);
   if(!init) {
      printf("%s::Initialization failed!", m_ea_name);
      return false;
   }else{
      printf("%s::initialized successfully on %s"
         + " with magic number %d",
         m_ea_name, m_symbol.Name(), m_magic
      );
   }
   if(inp_use_gui && (!m_gui.create(m_ea_name) || !m_gui.Run()))
      return false;
   return true;
}

bool DtExpert::on_tick(void) override
{
   if(!Expert::on_tick() || !this._indicators_ready())
      return false;
   if(this.can_trade()){
      int signal = this.signals();
      if(this.check_signal(XLONG_STRONG, signal)) {
         int ticket = this._market_buy(
            inp_lots, 
            inp_stop_pips * m_pip_mod, 
            inp_take_pips * m_pip_mod
         );
         if(ticket >= 0 && m_gui.is_alerts())
            this.alert(ticket);
      }
      if(this.check_signal(XSHORT_STRONG, signal)) {
         int ticket = this._market_sell(
            inp_lots, 
            inp_stop_pips * m_pip_mod, 
            inp_take_pips * m_pip_mod
         );
         if(ticket >= 0 && m_gui.is_alerts())
            this.alert(ticket);
      }
   }
   return true;
}

int DtExpert::signals(void) override
{
   if(   m_dt3.Main(0) > m_dt3.Signal(0)
      && m_dt2.Main(0) > m_dt2.Signal(0)
      && m_dt1.Main(0) > m_dt1.Signal(0)
      && m_dt1.Main(1) < 25
      && m_dt1.Main(1) <= m_dt1.Signal(1)
   ){
      return (XLONG_STRONG|XLONG_WEAK);
   }
   if(   m_dt3.Main(0) < m_dt3.Signal(0)
      && m_dt2.Main(0) < m_dt2.Signal(0)
      && m_dt1.Main(0) < m_dt1.Signal(0)
      && m_dt1.Main(1) > 75
      && m_dt1.Main(1) >= m_dt1.Signal(1)
   ){
      return (XSHORT_STRONG|XSHORT_WEAK);
   }
   if(!IsTesting()) {
      m_gui.update_sig1(tf_to_string(m_dt1.Period()),
         m_dt1.Main(0), m_dt1.Signal(0)
      );
      m_gui.update_sig2(tf_to_string(m_dt2.Period()),
         m_dt2.Main(0), m_dt2.Signal(0)
      );
      m_gui.update_sig3(tf_to_string(m_dt3.Period()),
         m_dt3.Main(0), m_dt3.Signal(0)
      );
   }
   return XNONE;
}

bool DtExpert::can_trade(void)
{
   if(!this._refresh_pool() || !this._refresh_history_pool())
      return false;
   objvector<Ticket*> tickets;
   tickets.FreeMode(false);
   tickets.AddArray(&m_positions_long);
   tickets.AddArray(&m_positions_short);
   if(tickets.Total() >= inp_max_concurrent_trades)
      return false;
   tickets.AddArray(&m_deals_long);
   tickets.AddArray(&m_deals_short);
   int total = tickets.Total();
   if(total == 0)
      return true;
   
   datetime curr_bar = (datetime)SeriesInfoInteger(
      m_symbol.Name(), 
      inp_dt1_timeframe,
      SERIES_LASTBAR_DATE
   );
   for(int i=tickets.Total()-1; i>=0; --i) {
      if(!tickets[i].select()
         || OrderOpenTime() >= curr_bar
      ){
         return false;
      }
   }
   return true;
}

bool DtExpert::_indicators_ready(void)
{
   if(m_indicators_ready)
      return true;
   objvector<CiDtOscillator*> indies;
   indies.Add(&m_dt1);
   indies.Add(&m_dt2);
   indies.Add(&m_dt3);
   bool res = true;
   for(int i=indies.Total()-1; i>=0; --i) {
      ResetLastError();
      double dummy_val = indies[i].Main(1);
      if(GetLastError() != ERR_NO_ERROR) 
         res = false;
   }
   m_indicators_ready = res;
   return res;
}

void DtExpert::alert(const int ticket)
{
   if(OrderSelect(ticket, SELECT_BY_TICKET)) {
      string message = StringFormat(
         "%s:: %.2f Lot %s trade on %s @ %s",
         m_ea_name, 
         OrderLots(), 
         OrderType() == OP_BUY ? "BUY" : "SELL",
         OrderSymbol(), 
         TimeToString(OrderOpenTime())
      );
      Alert(message);
      SendMail(m_ea_name, message);
      SendNotification(message);
   }
}

bool DtExpert::on_chartevent( const int id,
                              const long &lparam,
                              const double &dparam,
                              const string &sparam)
{
   m_gui.ChartEvent(id, lparam, dparam, sparam);
   return true;
}

bool DtExpert::on_deinit(const int reason)
{
   m_gui.Destroy(reason);
   return true;
}