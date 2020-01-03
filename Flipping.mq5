//+------------------------------------------------------------------+
//|                                                     Flipping.mq5 |
//|                                                    Lucas Moreira |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Lucas Moreira"
#property link      "https://www.mql5.com"
#property version   "1.00"

//Includes
#include <Trade/Trade.mqh  > //biblioteca padrão chamada de CTrade

// Inputs
input int lote = 100;

// Variáveis Globais
CTrade trade;
double precoAbertura;
bool flag_comprado = false;
double lastBuyPrice;
double lastSellPrice;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   string Nome = "Flipping";
	PrintFormat("Robô de Flipping inicializando...");
 

//--- Indicadores, se houver, ou personalizado iCustom


//--- Informações                                                               
   PrintFormat(Nome+" Expert Simples configurado em %s",TimeToString(TimeCurrent()));
   PrintFormat(Nome+" Saldo da conta: R$%.2f",AccountInfoDouble(ACCOUNT_BALANCE));
   PrintFormat(Nome+" Margem disponível: R$%.2f",AccountInfoDouble(ACCOUNT_MARGIN_FREE));

//--- Ok
  	PrintFormat(Nome+" Inicializado com sucesso");
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
  
  
void OnTradeTransaction
(
   const MqlTradeTransaction &trans, 
   const MqlTradeRequest     &request, 
   const MqlTradeResult      &result
) 

{ 
   if ( trans.type == TRADE_TRANSACTION_DEAL_ADD )
   {
      if ( trans.deal_type == DEAL_TYPE_BUY  ) lastBuyPrice  = trans.price;
      if ( trans.deal_type == DEAL_TYPE_SELL ) lastSellPrice = trans.price;
   }  
}
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+

void OnTick()
  {
//---
   if(isNewBar()){
      bool sinalDeCompra = false;
      bool sinalDeVenda = false;
      
      MqlRates rt[];
      ArraySetAsSeries(rt,true);      
      MqlRates daily[];
      ArraySetAsSeries(daily, true);
      
      int copiedDaily = CopyRates(Symbol(),PERIOD_D1,0,2,daily);
      
      int copied = CopyRates(Symbol(),Period(),0,2,rt); 
      if (copied == 2) {
         double precoDeCompra = daily[0].open * 0.99;
         if (rt[0].open <= precoDeCompra && !flag_comprado) {
            sinalDeCompra = true;
         }
         
         if (flag_comprado) {
            double precoParafecharPosicao = lastBuyPrice * 1.01;
            if(rt[0].open >= precoParafecharPosicao){
               sinalDeVenda = true;
            }
         }
      }
  
        // A conta do METATRADER precisa ser do tipo NETTING. Não usar o robô em contas HEAD.
        // --- Lógica de roteamento
        if(!flag_comprado) {
            if (sinalDeCompra) {
               flag_comprado = true;
               trade.Buy(lote,_Symbol,0,0,0,"Compra a mercado");
            }
        } else {
         // tem posição
         // -- estou comprado
         if (flag_comprado) {
            if (sinalDeVenda) {
               flag_comprado = false;
               trade.Sell(lote, _Symbol, 0,0,0, "Fecha posição!!!");
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
