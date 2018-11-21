#include <stdlib.mqh>
#include <arrays/arrayobj.mqh>
#include <arrays/arrayint.mqh>
#include <arrays/arraydouble.mqh>
#include <arrays/arraystring.mqh>
#include "SymbolInfo.mqh"

#define VERBOSE_ERROR StringFormat("ERROR(%s) --> %s", ErrorDescription(GetLastError()), __FUNCTION__)

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

template<typename T>
class objvector : public CArrayObj
{
 public:
   T operator[](const int i) const { return this.At(i); }
   bool Add(T element){ return CArrayObj::Add(element); }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class SymbolInfo : public CSymbolInfo
{
   public: double NormalizeLots(const double lots) const {
      return floor(lots / this.LotsStep()) * this.LotsStep();
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum XSIGNAL_FLAGS
{
   XNONE          = (0),
   XLONG_STRONG   = (1<<0),
   XLONG_WEAK     = (1<<1),
   XSHORT_STRONG  = (1<<2),
   XSHORT_WEAK    = (1<<3)
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Ticket : public CObject //Sorts orders by open time for FIFO
{
 protected:
   int         m_ticket;
   datetime    m_open_time;
 public:
   Ticket(const int ticket):m_ticket(ticket) 
   {
      if(this.select())
         m_open_time = OrderOpenTime();
      else
         m_open_time = WRONG_VALUE;
   }
   virtual bool select() const 
   {
      return OrderSelect(m_ticket, SELECT_BY_TICKET);
   }
   virtual int Compare(const CObject *node, const int mode=0) const override 
   {
      const Ticket *other = node;
      if(this.m_open_time == WRONG_VALUE || this.m_open_time > other.m_open_time)
         return 1;
      if(this.m_open_time < other.m_open_time)
         return -1;
      if(this.m_open_time == other.m_open_time)
         if(this.m_ticket < other.m_ticket)
            return -1;
         else if(this.m_ticket > other.m_ticket)
            return 1;
      return 0;
   }
};

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Expert : public CObject
{
 protected:
   int                  m_magic;
   SymbolInfo           m_symbol;
   double               m_pip;
   int                  m_pip_mod;
   objvector<Ticket*>   m_orders_long;
   objvector<Ticket*>   m_orders_short;
   objvector<Ticket*>   m_positions_long;
   objvector<Ticket*>   m_positions_short;
   objvector<Ticket*>   m_deals_long;
   objvector<Ticket*>   m_deals_short;
 public:
   Expert(const int magic):m_magic(magic){}
   //EVENT HANDLERS
   virtual bool on_init(const string symbol=NULL);
   virtual bool on_tick()                    { return m_symbol.RefreshRates();}
   virtual bool on_timer()                   { return true;}
   virtual bool on_tester()                  { return true;}
   virtual bool on_deinit(const int reason)  { return true; } 
   virtual bool on_chartevent(const int    id,
                              const long   &lparam,
                              const double &dparam,
                              const string &sparam){ return true; }
   //SIGNALS
   virtual int  signals()     { return 0; }
   
   static  bool check_signal(const XSIGNAL_FLAGS signal_flag, 
                             const int signals);
 protected:
   virtual bool _refresh_pool();
   virtual bool _refresh_history_pool();
   virtual int   _market_buy( double volume, 
                             int sl=0, 
                             int tp=0, 
                             string comment=NULL, 
                             int slippage=0);
   virtual int   _market_sell(double volume, 
                             int sl=0, 
                             int tp=0, 
                             string comment=NULL, 
                             int slippage=0);
   
   double       _rtick(double price) const;
   double       _rlot(double lots) const;
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

bool Expert::on_init(const string symbol=NULL)
{
   if(!m_symbol.Name(symbol == NULL ? _Symbol : symbol))
      return false;
   if(m_symbol.Digits() == 3 || m_symbol.Digits() == 5){
      m_pip = m_symbol.Point() * 10;
      m_pip_mod = 10;
   }else{
      m_pip = m_symbol.Point();
      m_pip_mod = 1;
   }
   return true;
}

bool Expert::_refresh_pool()
{
   m_orders_long.Clear();
   m_orders_short.Clear();
   m_positions_long.Clear();
   m_positions_short.Clear();
   int total = OrdersTotal();
   if(total == 0)
      return true;
   bool sort = false;
   for(int i=total-1; i>=0; --i) {
      if(OrderSelect(i, SELECT_BY_POS)
         && OrderSymbol() == Symbol()
         && OrderMagicNumber() == m_magic
      ){
         Ticket *ticket = new Ticket(OrderTicket());
         switch(OrderType()) {
            case OP_BUY:
               m_positions_long.Add(ticket);
               sort = true;
               break;
            case OP_SELL:
               m_positions_short.Add(ticket);
               sort = true;
               break;
            case OP_BUYLIMIT:
            case OP_BUYSTOP:
               m_orders_long.Add(ticket);
               sort = true;
               break;
            case OP_SELLLIMIT:
            case OP_SELLSTOP:
               m_orders_short.Add(ticket);
               sort = true;
         }
      }
   }
   if(sort) {
      m_orders_long.Sort();
      m_orders_short.Sort();
      m_positions_long.Sort();
      m_positions_short.Sort();
   }
   return true;
}

bool Expert::_refresh_history_pool()
{
   m_deals_long.Clear();
   m_deals_short.Clear();
   bool sort = false;
   for(int i=OrdersHistoryTotal()-1; i>=0; --i) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)
         && OrderSymbol() == Symbol()
         && OrderMagicNumber() == m_magic
      ){
         Ticket *ticket = new Ticket(OrderTicket());
         switch(OrderType()) {
            case OP_BUY:
               m_deals_long.Add(ticket);
               sort = true;
               break;
            case OP_SELL:
               m_deals_short.Add(ticket);
               sort = true;
               break;
         }
      }
   }
   if(sort) {
      m_deals_long.Sort();
      m_deals_short.Sort();
   }
   return true;
}

double Expert::_rtick(const double price) const
{
   return m_symbol.NormalizePrice(price);
}

double Expert::_rlot(const double lots) const
{
   return m_symbol.NormalizeLots(lots);
}

int Expert::_market_buy(double volume, 
                         int sl=0, 
                         int tp=0, 
                         string comment=NULL, 
                         int slippage=0)
{  
   if(!m_symbol.RefreshRates())
      return false;
   double ask = m_symbol.Ask();
   int ticket = OrderSend(
      m_symbol.Name(), 
      OP_BUY, 
      this._rlot(volume), 
      ask, 
      slippage,
      sl==0 ? 0.0 : this._rtick(ask - sl * m_symbol.Point()),
      tp==0 ? 0.0 : this._rtick(ask + tp * m_symbol.Point()),
      comment, 
      m_magic
   );
   return ticket;
}

int Expert::_market_sell(double volume, 
                          int sl=0, 
                          int tp=0, 
                          string comment=NULL, 
                          int slippage=0)
{
   if(!m_symbol.RefreshRates())
      return false;
   double bid = m_symbol.Bid();
   int ticket = OrderSend(
      m_symbol.Name(), 
      OP_SELL, 
      this._rlot(volume), 
      this._rtick(bid), 
      slippage,
      sl==0 ? 0.0 : this._rtick(bid + sl * m_symbol.Point()),
      tp==0 ? 0.0 : this._rtick(bid - tp * m_symbol.Point()),
      comment, 
      m_magic
   );
   return ticket;
}

bool Expert::check_signal(const XSIGNAL_FLAGS signal_flag, 
                          const int signals)
{
   return bool(signals&signal_flag);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

bool reverse_trade(const int ticket)
{
   if(!OrderSelect(ticket, SELECT_BY_TICKET) 
      || OrderCloseTime() > 0  
      || OrderType() >= 2
   ){
      return false; // order cannot be selected or is already closed or is not live
   }  
   int second_ticket = -1;
   MqlTick tick;
   if(!SymbolSelect(OrderSymbol(), true) 
      || !SymbolInfoTick(OrderSymbol(), tick)
   )
      return false;
   if(OrderType() == OP_BUY){
      second_ticket = OrderSend(OrderSymbol(), OP_SELL,
         OrderLots() * 2, tick.bid, 0, 0.0, 0.0 
      );
   }else{
      second_ticket = OrderSend(OrderSymbol(), OP_BUY,
         OrderLots() * 2, tick.ask, 0, 0.0, 0.0 
      );
   }
   if(second_ticket < 0)
      return false;
   return OrderCloseBy(ticket, second_ticket);
}

string tf_to_string(ENUM_TIMEFRAMES timeframe)
{
   if(timeframe == PERIOD_CURRENT)
      timeframe = (ENUM_TIMEFRAMES)_Period;
   return StringSubstr(EnumToString(timeframe), 7);
}

string tf_to_string(int timeframe)
{
   return tf_to_string((ENUM_TIMEFRAMES)timeframe);
}

