//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2012, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#resource "ModernDtOscillator.ex4"

#include <Indicators\Indicator.mqh>
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CiDtOscillator : public CIndicator
  {
protected:
   int               m_rsi_period;
   int               m_sto_period;
   int               m_sk_period;
   int               m_sd_period;
   ENUM_MA_METHOD    m_ma_method;
public:
                     CiDtOscillator(void);
                    ~CiDtOscillator(void);
   //--- methods of access to protected data
   int               RsiPeriod(void) const { return(m_rsi_period);     }
   int               StoPeriod(void) const { return m_sto_period; }
   int               SkPeriod(void)           const { return(m_sk_period);     }
   int               SdPeriod(void)           const { return(m_sd_period);     }
   ENUM_MA_METHOD    MaMethod(void) const { return(m_ma_method);   }
   int               BarsCalculated() const;
   //--- method create
   bool              Create(const string symbol,const ENUM_TIMEFRAMES period,
                            const int RsiPeriod,const int StoPeriod,
                            const int SkPeriod,const int SdPeriod,
                            const ENUM_MA_METHOD ma_method=MODE_SMA);
   //--- methods of access to indicator data
   virtual double    GetData(const int buffer_num,const int index) const;
   double            Main(const int index) const;
   double            Signal(const int index) const;
   //--- method of identifying
   virtual int       Type(void) const { return(IND_CUSTOM); }

protected:
   //--- methods of tuning
   //virtual bool      Initialize(const string symbol,const ENUM_TIMEFRAMES period,const int num_params,const MqlParam &params[]);
   bool              Initialize(const string symbol,const ENUM_TIMEFRAMES period,
                                const int RsiPeriod,const int StoPeriod,
                                const int SkPeriod,const int SdPeriod,
                                const ENUM_MA_METHOD ma_method=MODE_SMA);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CiDtOscillator::CiDtOscillator(void) : m_rsi_period(-1),
                                       m_sto_period(-1),
                                       m_sk_period(-1),
                                       m_sd_period(-1),
                                       m_ma_method(WRONG_VALUE)
  {
  }
//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CiDtOscillator::~CiDtOscillator(void)
  {
  }
//+------------------------------------------------------------------+
//| Create the "Stochastic Oscillator" indicator                     |
//+------------------------------------------------------------------+
bool CiDtOscillator::Create(const string symbol,const ENUM_TIMEFRAMES period,
                            const int RsiPeriod,const int StoPeriod,
                            const int SkPeriod,const int SdPeriod,
                            const ENUM_MA_METHOD ma_method=MODE_SMA)
  {
   SetSymbolPeriod(symbol,period);
//--- result of initialization
   return(Initialize(symbol,period,RsiPeriod,StoPeriod,SkPeriod,SdPeriod,ma_method));
  }
//+------------------------------------------------------------------+
//| Initialize the indicator with universal parameters               |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Initialize the indicator with special parameters                 |
//+------------------------------------------------------------------+
bool CiDtOscillator::Initialize(const string symbol,const ENUM_TIMEFRAMES period,
                                const int RsiPeriod,const int StoPeriod,
                                const int SkPeriod,const int SdPeriod,
                                const ENUM_MA_METHOD ma_method=MODE_SMA)
  {
   m_name          = "DT Oscillator";
   m_rsi_period    = RsiPeriod;
   m_sto_period    = StoPeriod;
   m_sk_period     = SkPeriod;
   m_sd_period     = SdPeriod;
   m_ma_method     = ma_method;
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Access to buffer of "Stochastic Oscillator"                      |
//+------------------------------------------------------------------+
double CiDtOscillator::GetData(const int buffer_num,const int index) const
  {
   double result = iCustom(
      m_symbol,
      m_period,
      "::ModernDtOscillator.ex4", //included as resource so it's compiled in
      m_rsi_period,
      m_sto_period,
      m_sk_period,
      m_sd_period,
      buffer_num,
      index
   );
   return result;
  }
//+------------------------------------------------------------------+
//| Access to Main buffer of "Stochastic Oscillator"                 |
//+------------------------------------------------------------------+
double CiDtOscillator::Main(const int index) const
  {
   return(GetData(MODE_MAIN,index));
  }
//+------------------------------------------------------------------+
//| Access to Signal buffer of "Stochastic Oscillator"               |
//+------------------------------------------------------------------+
double CiDtOscillator::Signal(const int index) const
  {
   return(GetData(MODE_SIGNAL,index));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CiDtOscillator::BarsCalculated(void) const
  {
   return int(round(this.GetData(4, 0)));
  }
//+------------------------------------------------------------------+
