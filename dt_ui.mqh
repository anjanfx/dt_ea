#include <controls/dialog.mqh>
#include <controls/label.mqh>
#include <controls/checkbox.mqh>

#define INDENT_LEFT     (8)       // left indent (including the border width)
#define INDENT_TOP      (8)       // top indent (including the border width)
#define EDIT_WIDTH      (100)     // size along the X-axis
#define EDIT_HEIGHT     (20)  
#define GAP             (5) 

class DtGui: public CAppDialog
{
 protected:
   CLabel            m_sig1;
   CLabel            m_sig2;
   CLabel            m_sig3;
   CCheckBox         m_alerts;
 public:
   virtual bool      create(string name);
   virtual bool      OnEvent(const int id,
                             const long &lparam,
                             const double &dparam,
                             const string &sparam);
                             
   virtual bool      update_sig1(string tf, double main, double signal);
   virtual bool      update_sig2(string tf, double main, double signal);
   virtual bool      update_sig3(string tf, double main, double signal);
   virtual bool      is_alerts();
 protected:
   virtual void      _alerts_on();
 
};

bool DtGui::create(string name)
{
   bool parent_create = this.Create(
      ChartID(), name, 0, 10, 10, 150, 150
   );
   if(!parent_create)
      return false;
   int x1 = INDENT_LEFT;
   int y1 = INDENT_TOP;
   int x2 = x1 + EDIT_WIDTH;
   int y2 = y1 + EDIT_HEIGHT;
   if(!m_sig1.Create(m_chart_id, m_name+"_sig1", m_subwin, x1, y1, x2, y2))
      return false;
   y1 = y2 + GAP;
   y2 = y1 + EDIT_HEIGHT;
   if(!m_sig2.Create(m_chart_id, m_name+"_sig2", m_subwin, x1, y1, x2, y2))
      return false;
   y1 = y2 + GAP;
   y2 = y1 + EDIT_HEIGHT;
   if(!m_sig3.Create(m_chart_id, m_name+"_sig3", m_subwin, x1, y1, x2, y2))
      return false;
   y1 = y2 + GAP;
   y2 = y1 + EDIT_HEIGHT;
   if(!m_alerts.Create(m_chart_id, m_name+"_checkie", m_subwin, x1, y1, x2, y2))
      return false;
   m_alerts.Text("Alerts");
   m_sig1.Text("FST (%.2f, %.2f)");
   m_sig2.Text("MED (%.2f, %.2f)");
   m_sig3.Text("SLO (%.2f, %.2f)");
   return (
         this.Add(m_sig1)
      && this.Add(m_sig2)
      && this.Add(m_sig3)
      && this.Add(m_alerts)
   );
   return true;
}
   

EVENT_MAP_BEGIN(DtGui)
EVENT_MAP_END(CAppDialog)


bool DtGui::update_sig1(string tf, double main,double signal)
{
   color c = main > signal ? clrGreen : clrRed;
   string text = StringFormat("%s (%.2f, %.2f)",
      tf, main, signal
   );
   return m_sig1.Text(text) && m_sig1.Color(c);
}

bool DtGui::update_sig2(string tf, double main,double signal)
{
   color c = main > signal ? clrGreen : clrRed;
   string text = StringFormat("%s (%.2f, %.2f)",
      tf, main, signal
   );
   return m_sig2.Text(text) && m_sig2.Color(c);
}

bool DtGui::update_sig3(string tf, double main,double signal)
{
   color c = main > signal ? clrGreen : clrRed;
   string text = StringFormat("%s (%.2f, %.2f)",
      tf, main, signal
   );
   return m_sig3.Text(text) && m_sig3.Color(c);
}

bool DtGui::is_alerts(void)
{
   return m_alerts.Checked();
}

void DtGui::_alerts_on(void)
{
   //if(m_alerts.Checked())
      Alert("Alerts on");
}

