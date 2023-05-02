#include <Trade/Trade.mqh>
#include <math_utils.mqh>
CTrade trade;

string indicator_name = "\\Indicators\\supertrend.ex5";
string indicator_volume = "\\Indicators\\VolumeAverage.ex5";

double super_T[];
int supertrend;


int ATR;
double atr_array[];
double atr_stop;
double precio_position = 0;

double volumenes[];
int volumen;
double ema_volumen[];

int MACD_h;
double MACD[];     
double SIGNAL[];
double actual_price=0;

double lote;


double puntos;

double Ask;
double Bid;

double capital_inicial = AccountInfoDouble(ACCOUNT_BALANCE);
//depende de valor inicial /10000 para el 10%
double factor_riesgo = 0.01;


//input int not_used;
input int per_supertrend = 10;
input int mult_supertrend = 3;

input int fast_macd = 12;
input int slow_macd = 26;
input int signal_macd = 9;


input double factor_volume = 0.8;
input double atr_factor = 1.1;



//pruebas
//input double distancia_macd = 0.0003;
//input int limite_adx = 35;



int typeC = 0;
//0 compra // 1 venta
double last_color=0;
// 0 verde // 1 rojo

bool verificar_cruce_macd(int cantidad_atras,int tipo,double &MAC[],double &SIG[]){
   bool cruce = false;
   if (tipo == 0){
      for(int i=0;i<cantidad_atras-1; i++){
         if(MAC[1+i] < SIG[1+i] && MAC[0+i] > SIG[0+i] && MAC[0+i] < 0 && MAC[1+i] < 0 && SIG[0+i] < 0 && SIG[1+i] < 0){
            cruce = true;
            return cruce;
         }
      }
   }
   
   else if(tipo == 1){
      for(int i=0;i<cantidad_atras-1; i++){
         if(MAC[1+i] > SIG[1+i] && MAC[0+i] < SIG[0+i] && MAC[0+i] > 0 && MAC[1+i] > 0 && SIG[0+i] > 0 && SIG[1+i] > 0){
            cruce = true;
            return cruce;
         }
      }
   }
   
   return cruce;
}





int OnInit() {
   
   
   ATR = iATR(_Symbol,PERIOD_CURRENT,14);
   ArraySetAsSeries(atr_array, true);
   
   supertrend = iCustom(_Symbol,_Period,indicator_name,per_supertrend,mult_supertrend,false);
   ArraySetAsSeries(super_T, true);
   
   volumen = iCustom(_Symbol,_Period,indicator_volume);
   ArraySetAsSeries(volumenes, true);
   

   MACD_h = iMACD(_Symbol, _Period, fast_macd, slow_macd, signal_macd, PRICE_CLOSE);
   ArraySetAsSeries(MACD, true);
   ArraySetAsSeries(SIGNAL, true);

   return(INIT_SUCCEEDED);
}

void OnTick() {

   
   CopyBuffer(supertrend, 3, 1, 1,super_T);
   
   
   CopyBuffer(ATR, 0, 0, 1,atr_array);
   

   
   CopyBuffer(volumen, 0, 0, 2,volumenes);
   CopyBuffer(volumen, 2, 0, 2,ema_volumen);
   
   last_color=super_T[0];

   CopyBuffer(MACD_h, 0, 0, 2, MACD);
   CopyBuffer(MACD_h, 1, 0, 2, SIGNAL);
   
   // balance en base a riesgo (mejores ganancias)
   lote = (factor_riesgo*AccountInfoDouble(ACCOUNT_BALANCE))/capital_inicial;
   
   /* para gastar el 10%
   atr_stop = NormalizeDouble(atr_array[0],5);
   puntos = (atr_factor*atr_stop)/_Point;
   lote = (factor_riesgo*AccountInfoDouble(ACCOUNT_BALANCE))/(10*puntos);
   */
   
   
   
   lote = RoundToDigitsUp(lote,2);


   
   
   Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   actual_price=(Ask+Bid)/2;  
   
   
   
   if (PositionsTotal() < 1 && verificar_cruce_macd(2,0,MACD,SIGNAL) && super_T[0] == 0 && volumenes[0] > factor_volume*ema_volumen[0]) {
      Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);   
      typeC=0;
      precio_position = actual_price;
      atr_stop = NormalizeDouble(atr_array[0],5);
      trade.Buy(lote, _Symbol, Ask,precio_position-atr_factor*atr_stop,0,NULL);
   } 
   
   
   else if (PositionsTotal() < 1 && verificar_cruce_macd(2,1,MACD,SIGNAL) && super_T[0] == 1 && volumenes[0] > factor_volume*ema_volumen[0]) {
      Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
      typeC=1;
      precio_position = actual_price;
      atr_stop = NormalizeDouble(atr_array[0],5);
      trade.Sell(lote, _Symbol, Bid,precio_position+atr_factor*atr_stop,0,NULL);
   }
   

   
   if (PositionsTotal() > 0){
      if(typeC==0 && last_color == 1 ){
         trade.PositionClose(_Symbol,-1);
      }
      else if (typeC == 1 && last_color == 0){
         trade.PositionClose(_Symbol,-1);
      }
      
   }  
   
   
}


