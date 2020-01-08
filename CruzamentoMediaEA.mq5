//+------------------------------------------------------------------+
//|                                            CruzamentoMediaEA.mq5 |
//|                                                    Lucas Moreira |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Lucas Moreira"
#property link      "https://www.mql5.com"
#property version   "1.00"

#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh>

input int PeriodoLongo = 17; // Péríodo Média Longa
input int PeriodoCurto = 9; // Péríodo Média Curta
input double SL = 3.0; //Stop Loss
input double TP = 5.0; //Take profit
input double BE = 3.0; //Break Even
input double Volume = 5; // Volume
input string inicio =  "09:05"; //Horário de início (entradas)
input string termino =  "17:00"; //Horário de término (entradas)
input string fechamento =  "17:50"; //Horário de fechamento (posições)

int handleMediaLonga, handleMediaCurta;
CTrade negocio;
CSymbolInfo simbolo;

MqlDateTime horario_inicio, horario_termino, horario_fechamento, horario_atual;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

   if(!simbolo.Name(_Symbol))
   {
      Print("Ativo inválido");
      return INIT_FAILED;   
   }

   handleMediaCurta = iCustom(_Symbol, _Period, "MediaMovel", PeriodoCurto);
   handleMediaLonga = iCustom(_Symbol, _Period, "MediaMovel", PeriodoLongo);
   
   if(handleMediaCurta == INVALID_HANDLE || handleMediaLonga == INVALID_HANDLE)
   {
      Print("Erro na criação dos manipuladores");
      return INIT_FAILED;   
   }
     
   if(PeriodoLongo <= PeriodoCurto)
   {
      Print("Parâmetros de médias incorretos"); 
      return INIT_FAILED;   
   }
   
   TimeToStruct(StringToTime(inicio), horario_inicio);
   TimeToStruct(StringToTime(termino), horario_termino);
   TimeToStruct(StringToTime(fechamento), horario_fechamento);
   
   if(horario_inicio.hour > horario_termino.hour || (horario_inicio.hour == horario_termino.hour && horario_inicio.min > horario_termino.min))
   {
      printf("Parâmetros de horários inválidos");
      return INIT_FAILED;
   }

   if(horario_termino.hour > horario_fechamento.hour || (horario_termino.hour == horario_fechamento.hour && horario_termino.min > horario_fechamento.min))
   {
      printf("Parâmetros de horários inválidos");
      return INIT_FAILED;
   }   
   
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   printf("Deinit reason: %d", reason);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

   // Atualiza as infos do símbolo
   if(!simbolo.RefreshRates())
      return;
   
   if(HorarioEntrada())
   {
      if(SemPosicao() && isNewBar())
      {
         int resultado_cruzamento = Cruzamento();
         if(resultado_cruzamento == 1)
            Compra();
         if(resultado_cruzamento == -1)
            Venda();
      }
      
      // EA está posicionaddo
      if(!SemPosicao())
      {
         //BreakEven();
      }
   }
   
   if(HorarioFechamento())
   {
      if(!SemPosicao())
         Fechar();
      
   }
  }
//+------------------------------------------------------------------+

bool HorarioEntrada()
{
   TimeToStruct(TimeCurrent(), horario_atual);
   if(horario_atual.hour >= horario_inicio.hour && horario_atual.hour <= horario_termino.hour)
   {
      if(horario_atual.hour == horario_inicio.hour)
      {
         if(horario_atual.min >= horario_inicio.min)
            return true;
         else
            return false;
      }
      
      if(horario_atual.hour == horario_termino.hour)
      {
         if(horario_atual.min <= horario_termino.min)
            return true;
         else
            return false;
      }      
      
      return true;
   }
   
   return false;
}

bool HorarioFechamento()
{
   TimeToStruct(TimeCurrent(), horario_atual);
   if(horario_atual.hour >= horario_fechamento.hour)
   {
      if(horario_atual.hour == horario_fechamento.hour)
         if(horario_atual.min >= horario_fechamento.min)
            return true;
         else
            return false;
            
      return true;
   }
   return false;
}

void Compra()
{
   double preco = simbolo.Ask();
   double stoploss = simbolo.NormalizePrice(preco - SL);
   double takeprofit = simbolo.NormalizePrice(preco + TP);
   negocio.Buy(Volume, NULL, preco, stoploss, takeprofit, "Compra CruzamentoMediaEA");
}

void Venda()
{
   double preco = simbolo.Ask();
   double stoploss = simbolo.NormalizePrice(preco + SL);
   double takeprofit = simbolo.NormalizePrice(preco - TP);
   negocio.Sell(Volume, NULL, preco, stoploss, takeprofit, "Venda CruzamentoMediaEA");
}

void Fechar()
{
   if(!PositionSelect(_Symbol))
      return;
      
      
   long tipo = PositionGetInteger(POSITION_TYPE);
   if(tipo == POSITION_TYPE_BUY)
   {
     negocio.Sell(Volume, NULL, 0, 0 , 0, "Fechamento CruzamentoMediaEA");
   }
   else
   {
     negocio.Buy(Volume, NULL, 0, 0 , 0, "Fechamento CruzamentoMediaEA"); 
   }
}

bool SemPosicao()
{
   return !PositionSelect(_Symbol);
}

int Cruzamento()
{
   double MediaCurta[], MediaLonga[];
   ArraySetAsSeries(MediaCurta, true);
   ArraySetAsSeries(MediaLonga, true);
   CopyBuffer(handleMediaCurta, 0, 0, 2, MediaCurta);
   CopyBuffer(handleMediaLonga, 0, 0, 2, MediaLonga);
   
   //Compra
   
   if(MediaCurta[1] <= MediaLonga[1] && MediaCurta[0] > MediaLonga[0])
   {
      return 1;
   }   
   
   //Venda
   
   if(MediaCurta[1] >= MediaLonga[1] && MediaCurta[0] < MediaLonga[0])
   {
      return -1;
   }
   
   return 0;
}

void BreakEven() 
{
   if(!PositionSelect(_Symbol))
      return;
      
   double preco_abertura = PositionGetDouble(POSITION_PRICE_OPEN);
   double delta = simbolo.Last() - preco_abertura;
   double stoploss = PositionGetDouble(POSITION_SL);
   double tp_atual = PositionGetDouble(POSITION_TP);
   // verifica se a alteracao ja nao foi feita.
   if (stoploss == preco_abertura)
      return;
      
   ulong position_ticket = PositionGetInteger(POSITION_TICKET);
   
   if(delta >= BE)
   {
      negocio.PositionModify(position_ticket, preco_abertura, tp_atual);
   }
   
}

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
         Print("Eh um novo candle...");
         return(true);
      }
   return(false);
}
