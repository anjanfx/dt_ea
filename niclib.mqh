#include <stdlib.mqh>
#include <Arrays\ArrayObj.mqh>
#include <Arrays\ArrayInt.mqh>
#include <Arrays\ArrayDouble.mqh>
#include <Arrays\ArrayString.mqh>


#define VERBOSE_ERROR StringFormat("ERROR(%s) --> %s", ErrorDescription(GetLastError()), __FUNCTION__)


template<typename T>
class objvector : public CArrayObj
{
 public:
   T operator[](const int i) const { return this.At(i); }
   bool Add(T element){ return CArrayObj::Add(element); }
};


enum XSIGNAL_FLAGS
{
   XNONE          = (0),
   XLONG_STRONG   = (1<<0),
   XLONG_WEAK     = (1<<1),
   XSHORT_STRONG  = (1<<2),
   XSHORT_WEAK    = (1<<3)
};


class Ticket : public CObject
{
 protected:
   int         m_ticket;
   datetime    m_open_time;
 public:
   Ticket(const int ticket):m_ticket(ticket){
      if(this.select())
         m_open_time = OrderOpenTime();
      else
         m_open_time = WRONG_VALUE;
   }
   virtual bool select() const { return OrderSelect(m_ticket, SELECT_BY_TICKET); }
   virtual int Compare(const CObject *node, const int mode=0) const override {
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


class Expert : public CObject
{
 protected:
   int                  m_magic;
   string               m_symbol;
   double               m_tick_step;
   double               m_lot_step;
   double               m_lot_min;
   double               m_lot_max;
   double               m_digits;
   double               m_point;
   double               m_pip;
   int                  m_pip_mod;
   MqlTick              m_tick;
   objvector<Ticket*>   m_orders_long;
   objvector<Ticket*>   m_orders_short;
   objvector<Ticket*>   m_positions_long;
   objvector<Ticket*>   m_positions_short;
   objvector<Ticket*>   m_deals_long;
   objvector<Ticket*>   m_deals_short;
 public:
   //EVENT HANDLERS
   virtual bool on_tick()     { return SymbolInfoTick(m_symbol, m_tick); }
   virtual bool on_timer()    { return true;}
   virtual bool on_init(const int magic, const string symbol=NULL);
   virtual bool on_tester()   { return true;}
   virtual bool on_deinit(const int reason) { return true; } 
   virtual bool on_chartevent(const int    id,
                              const long   &lparam,
                              const double &dparam,
                              const string &sparam){ return true; }
   //SIGNALS
   virtual int  signals()     { return 0; }
   
   static  bool  check_signal(const XSIGNAL_FLAGS signal_flag, const int signals);
 protected:
   virtual bool _refresh_pool();
   virtual bool _refresh_history_pool();
   virtual bool _market_buy(double volume, int sl=0, int tp=0, string comment=NULL, int slippage=0);
   virtual bool _market_sell(double volume, int sl=0, int tp=0, string comment=NULL, int slippage=0);
   
   double       _rtick(double price);
   double       _rlot(double lots);

   
   
};

bool Expert::on_init(const int magic, const string symbol=NULL)
{
   m_magic = magic;
   m_symbol = symbol == NULL ? _Symbol : symbol;
   if(!SymbolSelect(m_symbol, true))
      return false;
   m_tick_step = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
   m_lot_step = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
   m_lot_min = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
   m_lot_max = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
   m_digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
   m_point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
   if(m_digits == 3 || m_digits == 5){
      m_pip = m_point * 10;
      m_pip_mod = 10;
   }else{
      m_pip = m_point;
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
   for(int i=total-1; i>=0; --i){
      if(OrderSelect(i, SELECT_BY_POS)
         && OrderSymbol() == Symbol()
         && OrderMagicNumber() == m_magic
      ){
         Ticket *ticket = new Ticket(OrderTicket());
         switch(OrderType()){
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
   for(int i=OrdersHistoryTotal()-1; i>=0; --i){
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)
         && OrderSymbol() == Symbol()
         && OrderMagicNumber() == m_magic
      ){
         Ticket *ticket = new Ticket(OrderTicket());
         switch(OrderType()){
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

double Expert::_rtick(const double price)
{
   return round(price / m_tick_step) * m_tick_step;
}

double Expert::_rlot(const double lots)
{
   return floor(lots / m_lot_step) * m_lot_step;
}

bool Expert::_market_buy(double volume, int sl=0, int tp=0, string comment=NULL, int slippage=0)
{
   int ticket = OrderSend(
      m_symbol, 
      OP_BUY, 
      this._rlot(volume), 
      this._rtick(m_tick.ask), 
      slippage,
      sl==0 ? 0.0 : this._rtick(m_tick.ask - sl * m_point),
      tp==0 ? 0.0 : this._rtick(m_tick.ask + tp * m_point),
      comment, 
      m_magic
   );
   return ticket >= 0;
}

bool Expert::_market_sell(double volume, int sl=0, int tp=0, string comment=NULL, int slippage=0)
{
   int ticket = OrderSend(
      m_symbol, 
      OP_SELL, 
      this._rlot(volume), 
      this._rtick(m_tick.bid), 
      slippage,
      sl==0 ? 0.0 : this._rtick(m_tick.bid + sl * m_point),
      tp==0 ? 0.0 : this._rtick(m_tick.bid - tp * m_point),
      comment, 
      m_magic
   );
   return ticket >= 0;
}

bool Expert::check_signal(const XSIGNAL_FLAGS signal_flag, const int signals)
{
   return bool(signals&signal_flag);
}










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
   if(!SymbolSelect(OrderSymbol(), true) || !SymbolInfoTick(OrderSymbol(), tick))
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

string timeframe_to_string(ENUM_TIMEFRAMES timeframe)
{
   timeframe = timeframe == PERIOD_CURRENT ? (ENUM_TIMEFRAMES) _Period : timeframe;
   return StringSubstr(EnumToString(PERIOD_D1), 7);
}

string timeframe_to_string(int timeframe)
{
   return timeframe_to_string((ENUM_TIMEFRAMES)timeframe);
}

