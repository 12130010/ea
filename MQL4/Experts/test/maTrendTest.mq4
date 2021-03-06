//+------------------------------------------------------------------+
//|                                                  pinBarsTest.mq4 |
//|                                                            hle56 |
//|                                                     facebook.com |
//+------------------------------------------------------------------+
#property copyright "hle56"
#property link      "facebook.com"
#property version   "1.00"
#property strict

#include "..\common\common-func.mq4"
#include "..\common\common-MA.mq4"
#include "..\common\common-draw-vline.mq4"
#include  "..\..\Libraries\stdlib.mq4"
#include <WinUser32.mqh>



//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

int n = 0;
input color           InpColor=clrRed;     // Line color
input ENUM_LINE_STYLE InpStyle=STYLE_DASH; // Line style
input int             InpWidth=1;          // Line width
input bool            InpBack=false;       // Background line
input bool            InpSelection=true;   // Highlight to move
input bool            InpHidden=true;      // Hidden in the object list
input long            InpZOrder=0;         // Priority for mouse click

int OnInit() {
   //ChartApplyTemplate(0, "CandleStick-MA6-12-24.tpl");
   return(INIT_SUCCEEDED);
 }

int ticketNumber = 0;
int currentOrderType = -1;

double maFast1[], maFast2[], maMedium1[], maMedium2[], maLow1[], maLow2[];

void OnTick() {
  //if (IsNewBar()) {}
  
  
  double lot = 0.1;
  int magicNumber = 123456;
  
  int totalOrders = getTotalOpenOrders(magicNumber);
  
  if (totalOrders == 0){ //there are no any order were opened.
     int direction = getSignal();   
     int stopLoss = 200;
     int takeProfit = 200;
     
     if (direction > 0) {
         currentOrderType = OP_BUY;
         //ticketNumber = OrderSend(Symbol(), OP_BUY, lot, Ask, 3, Bid - stopLoss*Point, Bid + takeProfit*Point, NULL, magicNumber, 0 );
         ticketNumber = OrderSend(Symbol(), OP_BUY, lot, Ask, 3, 0, 0, NULL, magicNumber, 0 );
     } else if (direction < 0) {
         currentOrderType = OP_SELL;
         //ticketNumber = OrderSend(Symbol(), OP_SELL, lot, Bid, 3, Ask + stopLoss*Point, Ask - takeProfit*Point, NULL, magicNumber, 0 );
         ticketNumber = OrderSend(Symbol(), OP_SELL, lot, Bid, 3, 0, 0, NULL, magicNumber, 0 );
     }
     
     if ( ticketNumber < 0) { // error
         int errorCode = GetLastError();
         Print("Order error (", errorCode, ") : ", ErrorDescription(errorCode), ", Order type: ", currentOrderType, ", direction: ", direction);
         
         ticketNumber = 0;
         currentOrderType = -1;
     }
  } else {
       bool isCloseOrder = false;
       bool isCloseSucces = false;
       if (currentOrderType == OP_SELL && !isKeepOrderSell() ) {
            BreakPoint();
            showCurrentMA();
            isCloseSucces = OrderClose(ticketNumber, lot, Ask, 3);
            isCloseOrder = true;
       } else  if (currentOrderType == OP_BUY && !isKeepOrderBuy()) {
           BreakPoint();
           showCurrentMA();
           isCloseSucces = OrderClose(ticketNumber, lot, Bid, 3);
           isCloseOrder = true;
       }
       
       if (isCloseOrder) {
         if (isCloseSucces) {
            ticketNumber = 0;
            currentOrderType = -1;
         }else {
            int errorCode = GetLastError();
            Print("Close Order error (", errorCode, ") : ", ErrorDescription(errorCode));
         }
       }
       
       
  }
  
}
//+------------------------------------------------------------------+


int getSignal () {
   int numberBar = 10;
   int fromBar = 0;
   
   getCurrentCloseMA(maFast1, 3, numberBar, fromBar);
   getCurrentCloseMA(maFast2, 6, numberBar, fromBar);
   getCurrentCloseMA(maMedium1, 9, numberBar, fromBar);
   getCurrentCloseMA(maMedium2, 12, numberBar, fromBar);
   getCurrentCloseMA(maLow1, 24, numberBar, fromBar);
   getCurrentCloseMA(maLow2, 36, numberBar, fromBar);
   
   int direction = 0;
   int x = 0;
    
   if ( isGT(maFast1[x], maFast2[x]) 
     && isGT(maFast2[x], maMedium1[x])
     && isGT(maMedium1[x], maMedium2[x])
     && ( isGT(maMedium2[x], maLow1[x])
         || isGT(maMedium2[x], maLow2[x]))
          ) {
      direction = 1;
   } else if ( isLT(maFast1[x], maFast2[x]) 
              && isLT(maFast2[x], maMedium1[x])
              && isLT(maMedium1[x], maMedium2[x])
              && ( isLT(maMedium2[x], maLow1[x])
                  || isLT(maMedium2[x], maLow2[x])) 
              ) {
      direction = -1;
   }
   
   return direction;
}

bool isKeepOrderBuy () {
   int numberBar = 10;
   int fromBar = 0;
   
   getCurrentCloseMA(maFast1, 3, numberBar, fromBar);
   getCurrentCloseMA(maFast2, 6, numberBar, fromBar);
   getCurrentCloseMA(maMedium1, 9, numberBar, fromBar);
   getCurrentCloseMA(maMedium2, 12, numberBar, fromBar);
   getCurrentCloseMA(maLow1, 24, numberBar, fromBar);
   getCurrentCloseMA(maLow2, 36, numberBar, fromBar);
   
   return isLT(maMedium2[0], maMedium1[0]) ;
}

bool isKeepOrderSell () {
   int numberBar = 10;
   int fromBar = 0;
   
   getCurrentCloseMA(maFast1, 3, numberBar, fromBar);
   getCurrentCloseMA(maFast2, 6, numberBar, fromBar);
   getCurrentCloseMA(maMedium1, 9, numberBar, fromBar);
   getCurrentCloseMA(maMedium2, 12, numberBar, fromBar);
   getCurrentCloseMA(maLow1, 24, numberBar, fromBar);
   getCurrentCloseMA(maLow2, 36, numberBar, fromBar);
   
   return isGT(maMedium2[0], maMedium1[0]);
}

void BreakPoint()
{
   //It is expecting, that this function should work
   //only in tester
   if (!IsVisualMode()) return;
   
   //Preparing a data for printing
   //Comment() function is used as 
   //it give quite clear visualisation
   string Comm="";
   Comm=Comm+arrayToString(maFast1)+"\n";
   Comm=Comm+arrayToString(maFast2)+"\n";
   Comm=Comm+arrayToString(maMedium1)+"\n";
   Comm=Comm+arrayToString(maMedium2)+"\n";
   Comm=Comm+arrayToString(maLow1)+"\n";
   Comm=Comm+arrayToString(maLow2)+"\n";
   
   Comment(Comm);
   
   //Press/release Pause button
   //19 is a Virtual Key code of "Pause" button
   //Sleep() is needed, because of the probability
   //to misprocess too quick pressing/releasing
   //of the button
   keybd_event(19,0,0,0);
   Sleep(10);
   keybd_event(19,0,2,0);
}

string arrayToString(double &data[]){
   string res = "";
   for (int i = 0, len = ArraySize(data); i < len; i++) {
      res = res + data[i] + "; ";
   }
   return res;
}

string arrayToString(double &data[], int from, int to){
   string res = "";
   for (; from <= to; from++) {
      res = res + data[from] + "; ";
   }
   return res;
}

void showCurrentMA(){
   string comment= "";
   comment += "maFast1: " + arrayToString(maFast1, 0 ,0) +"\n";
   comment += "maFast2: " + arrayToString(maFast2, 0 ,0)+"\n";
   comment += "maMedium1: " + arrayToString(maMedium1, 0 ,0)+"\n";
   comment += "maMedium2: " + arrayToString(maMedium2, 0 ,0)+"\n";
   comment += "maLow1: " + arrayToString(maLow1, 0 ,0)+"\n";
   comment += "maLow2: " + arrayToString(maLow2, 0 ,0)+"\n";
   
   Comment(comment);
}