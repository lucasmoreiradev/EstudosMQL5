//+------------------------------------------------------------------+
//|                                             Robô Média Móvel.mq5 |
//|                                                    Lucas Moreira |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Lucas Moreira"
#property link      "https://www.mql5.com"
#property version   "1.00"

// Includes
#include <Trade/Trade.mqh> //biblioteca padrão chamada de CTrade

// Inputs
input int lote = 100;
input int periodoCurta = 10;
input int periodoLonga = 50;

// Variáveis Globais

// Manipuladores dos indicadores de média móvel
int curtaHandle = INVALID_HANDLE;
int longaHandle = INVALID_HANDLE;
// Vetores de dados dos indicadores de média movel
double mediaCurta[];
double mediaLonga[];
// -- declara variável trade
CTrade trade;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

int OnInit()
  {
//---
   
   // Inverte a indexação do array 0, 1, 2, 3 para 3, 2, 1, 0 (Isso porque o gráfico anda pra direita) O número 0 vai ser sempre a última barra disponível.
   // Faz sentido sempre fazer essa inverção de indexação por causa do gráfico cartersiano.
   ArraySetAsSeries(mediaCurta, true);
   ArraySetAsSeries(mediaLonga, true);
   
//-- atribuir valores para os manipuladores de cálculo de média móvel
   // indicator moving average (IMA)
   // SMA = Simple Movie Avarage (Média móvel simples)
   curtaHandle = iMA(_Symbol, _Period, periodoCurta, 0, MODE_SMA, PRICE_CLOSE);  
   longaHandle = iMA(_Symbol, _Period, periodoLonga, 0, MODE_SMA, PRICE_CLOSE);
   
//---
   return(INIT_SUCCEEDED);
  }
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
void OnTick()
  {
  
   if(isNewBar()) 
   {
      // OBTENÇÃO DOS DADOS
      int copied1 = CopyBuffer(curtaHandle,0,0,3,mediaCurta);
      int copied2 = CopyBuffer(longaHandle,0,0,3,mediaLonga);
      
      bool sinalDeCompra = false;
      bool sinalDeVenda = false;
      
      if(copied1==3 && copied2 ==3)
        {
         // -- sinal de compra
         if(mediaCurta[1] > mediaLonga[1] && mediaCurta[2] < mediaLonga[2])
           {
            sinalDeCompra = true;
           }
         // -- sinal de venda
         if(mediaCurta[1] < mediaLonga[1] && mediaCurta[2] > mediaLonga[2])
           {
            sinalDeVenda = true;    
           }            
        }
        
        // verificar se estou posicionado
        bool comprado = false;
        bool vendido = false;
        if(PositionSelect(_Symbol)) {
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY){
            comprado = true;
         }
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL){
            vendido = true;
         }
         
        }
        // A conta do METATRADER precisa ser do tipo NETTING. Não usar o robô em contas HEAD.
        // --- Lógica de roteamento
        if(!comprado && !vendido) {
            if (sinalDeCompra) {
               trade.Buy(lote,_Symbol,0,0,0,"Compra a mercado");
            }
            if (sinalDeVenda) {
//               trade.Sell(lote,_Symbol,0,0,0,"Compra a mercado");
            }
        } else {
         // tem posição
         // -- estou comprado
         if (comprado) {
            if (sinalDeVenda) {
               trade.Sell(lote, _Symbol, 0,0,0, "Fecha posição!!!");
            }
         } else if (vendido) {
            if(sinalDeCompra){
               trade.Buy(lote*2, _Symbol, 0,0,0, "Virada de mão (venda->compra)");
            }
         }
         // -- estou vendido
        }
   }
  }
//+------------------------------------------------------------------+

bool isNewBar()
   {
      static datetime last_time = 0;
      datetime lastbar_time = (datetime) SeriesInfoInteger(Symbol(), Period(), SERIES_LASTBAR_DATE);
      if (last_time == 0)
         {
            last_time = lastbar_time;
            return(false);
         }
         
      if (last_time!=lastbar_time)
         {
            last_time=lastbar_time;
            return(true);
         }
      return(false);
   }
