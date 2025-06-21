from fastapi import FastAPI
from pydantic import BaseModel
import datetime
import random # For dummy broker data
from typing import Optional, List, Dict, Any, TypedDict, Literal # Import Literal

# Attempt to import broker interface and agent classes
try:
    from TradingAgents.tradingagents.broker_interface.base import BrokerInterface, PriceTick, Candlestick
    from TradingAgents.tradingagents.forex_utils.forex_states import ForexTradeProposal # Import ForexTradeProposal
    from TradingAgents.tradingagents.forex_agents.scalper_agent import ScalperAgent
    from TradingAgents.tradingagents.forex_agents.day_trader_agent import DayTraderAgent
    from TradingAgents.tradingagents.forex_agents.swing_trader_agent import SwingTraderAgent
    from TradingAgents.tradingagents.forex_agents.position_trader_agent import PositionTraderAgent
except ImportError as e:
    print(f"Error importing trading agents or broker interface: {e}")
    # Define dummy types if import fails
    class BrokerInterface: pass
    class PriceTick(TypedDict): pass
    class Candlestick(TypedDict): pass
    class ForexTradeProposal(TypedDict): # Define a minimal matching structure for type hinting if real one fails
        rationale: str
        signal: str
        currency_pair: str
        entry_price: Optional[float]
        stop_loss: Optional[float]
        take_profit: Optional[float]
        source_agent_type: str # Simplified, actual agent_id might be part of the instance
        # proposal_id: str # Add other fields if necessary for type consistency in except block

    class ScalperAgent:
        agent_id: str = "dummy_scalper"
        def process_task(self, prompt: str, current_simulated_time_iso: str) -> ForexTradeProposal: pass
    class DayTraderAgent:
        agent_id: str = "dummy_daytrader"
        def process_task(self, prompt: str, current_simulated_time_iso: str) -> ForexTradeProposal: pass
    class SwingTraderAgent:
        agent_id: str = "dummy_swingtrader"
        def process_task(self, prompt: str, current_simulated_time_iso: str) -> ForexTradeProposal: pass
    class PositionTraderAgent:
        agent_id: str = "dummy_positiontrader"
        def process_task(self, prompt: str, current_simulated_time_iso: str) -> ForexTradeProposal: pass

app = FastAPI()

# --- Dummy Broker Implementation ---
class DummyBroker(BrokerInterface):
    def get_current_price(self, symbol: str) -> Optional[PriceTick]:
        print(f"DummyBroker: get_current_price called for {symbol}")
        if "JPY" in symbol.upper():
            bid = round(random.uniform(100.0, 150.0), 3)
            ask = round(bid + random.uniform(0.005, 0.02), 3)
        elif "XAU" in symbol.upper() or "GOLD" in symbol.upper():
            bid = round(random.uniform(1800.0, 2200.0), 2)
            ask = round(bid + random.uniform(0.1, 0.5), 2)
        else: # Standard FX
            bid = round(random.uniform(0.90000, 1.50000), 5)
            ask = round(bid + random.uniform(0.00005, 0.00020), 5)
        return PriceTick(symbol=symbol, timestamp=datetime.datetime.now(datetime.timezone.utc).timestamp(), bid=bid, ask=ask)

    def get_historical_data(self, symbol: str, timeframe_str: str, start_time_unix: float, end_time_unix: float, limit: Optional[int] = None) -> List[Candlestick]:
        print(f"DummyBroker: get_historical_data for {symbol} TF: {timeframe_str} Limit: {limit}")
        bars_to_generate = limit if limit is not None else 200
        candlesticks: List[Candlestick] = []
        current_timestamp_unix = start_time_unix
        pip_size = 0.0001
        price_mean = 1.10000
        price_volatility = 0.0050
        if "JPY" in symbol.upper(): pip_size, price_mean, price_volatility = 0.01, 130.0, 0.5
        elif "XAU" in symbol.upper(): pip_size, price_mean, price_volatility = 0.1, 2000.0, 10.0

        tf_seconds_map = {"M1": 60, "M5": 300, "M15": 900, "M30": 1800, "H1": 3600, "H4": 14400, "D1": 86400, "W1": 604800, "MN1": 2592000}
        time_increment_seconds = tf_seconds_map.get(timeframe_str.upper(), 3600)
        open_price = price_mean
        for _ in range(bars_to_generate):
            if current_timestamp_unix > end_time_unix and candlesticks: break
            close_price = open_price + random.uniform(-price_volatility, price_volatility)
            high_price = max(open_price, close_price) + random.uniform(0, pip_size * 10)
            low_price = min(open_price, close_price) - random.uniform(0, pip_size * 10)
            precision = 5 if pip_size < 0.01 else (3 if pip_size == 0.01 else 2)
            candlesticks.append(Candlestick(
                timestamp=current_timestamp_unix,
                open=round(open_price, precision), high=round(high_price, precision),
                low=round(low_price, precision), close=round(close_price, precision),
                volume=random.randint(100, 10000)
            ))
            open_price = close_price
            current_timestamp_unix += time_increment_seconds
        return candlesticks

    def get_account_info(self) -> Optional[Dict[str, Any]]: return {"balance": 10000, "currency": "USD"}
    def get_open_trades(self, symbol: Optional[str] = None) -> List[Dict[str, Any]]: return []
    def get_pending_orders(self, symbol: Optional[str] = None) -> List[Dict[str, Any]]: return []
    def create_market_order(self, symbol: str, order_type: str, volume: float, **kwargs) -> Optional[Dict[str, Any]]: return {"ticket_id": random.randint(10000,99999), "status": "success"}
    def create_pending_order(self, symbol: str, order_type: str, volume: float, price: float, **kwargs) -> Optional[Dict[str, Any]]: return {"ticket_id": random.randint(10000,99999), "status": "success"}
    def modify_trade(self, ticket_id: int, **kwargs) -> bool: return True
    def close_trade(self, ticket_id: int, **kwargs) -> bool: return True
    def delete_pending_order(self, ticket_id: int) -> bool: return True

# --- Agent Instantiation ---
try:
    dummy_broker_instance = DummyBroker()
    scalper_agent = ScalperAgent(broker=dummy_broker_instance, publisher=None)
    day_trader_agent = DayTraderAgent(broker=dummy_broker_instance, publisher=None)
    swing_trader_agent = SwingTraderAgent(broker=dummy_broker_instance, publisher=None)
    position_trader_agent = PositionTraderAgent(broker=dummy_broker_instance, publisher=None)
    print("Trading agents instantiated successfully with DummyBroker.")
except Exception as e:
    print(f"Failed to instantiate agents: {e}")
    scalper_agent = ScalperAgent(); day_trader_agent = DayTraderAgent(); swing_trader_agent = SwingTraderAgent(); position_trader_agent = PositionTraderAgent()

# --- API Models ---
class ChatPrompt(BaseModel):
    prompt: str

class TradeExecutionPayload(BaseModel):
    agent_id: str
    currency_pair: str
    order_side: Literal["BUY", "SELL"] # Use Literal for specific string values
    entry_price: float
    stop_loss: Optional[float] = None
    take_profit: Optional[float] = None
    volume: Optional[float] = 0.01 # Default volume

# --- API Endpoints ---
@app.post("/chat")
async def chat(chat_prompt: ChatPrompt):
    prompt_text = chat_prompt.prompt
    current_time_iso = datetime.datetime.now(datetime.timezone.utc).isoformat()

    selected_agent_instance: Any = None # To hold the agent instance
    agent_name = "DayTraderAgent" # Default

    # Agent selection logic (ensure agent instances are used, not classes)
    if "scalp" in prompt_text.lower() or "scalper" in prompt_text.lower():
        selected_agent_instance = scalper_agent
        agent_name = "ScalperAgent"
    elif "day trade" in prompt_text.lower() or "daytrader" in prompt_text.lower():
        selected_agent_instance = day_trader_agent
        agent_name = "DayTraderAgent"
    elif "swing" in prompt_text.lower():
        selected_agent_instance = swing_trader_agent
        agent_name = "SwingTraderAgent"
    elif "position" in prompt_text.lower():
        selected_agent_instance = position_trader_agent
        agent_name = "PositionTraderAgent"
    else:
        selected_agent_instance = day_trader_agent # Default to DayTraderAgent
        agent_name = "DayTraderAgent (Default)"

    if not selected_agent_instance:
        return {"response": f"Error: Could not select or initialize trading agent '{agent_name}'.", "agent_used": agent_name, "trade_proposal": None}

    try:
        print(f"Routing to {agent_name} for prompt: '{prompt_text}'")
        # Agent process_task now returns a ForexTradeProposal (TypedDict)
        agent_proposal: ForexTradeProposal = selected_agent_instance.process_task(
            prompt=prompt_text,
            current_simulated_time_iso=current_time_iso
        )

        trade_proposal_data = None
        if agent_proposal['signal'] in ["BUY", "SELL"] and agent_proposal.get('entry_price') is not None:
            trade_proposal_data = {
                "action": agent_proposal['signal'],
                "pair": agent_proposal['currency_pair'],
                "entry_price": agent_proposal['entry_price'],
                "stop_loss": agent_proposal['stop_loss'],
                "take_profit": agent_proposal['take_profit'],
                "agent_id": selected_agent_instance.agent_id # Use the agent_id from the instance
            }

        return {
            "response": agent_proposal['rationale'],
            "agent_used": agent_name,
            "trade_proposal": trade_proposal_data
        }
    except Exception as e:
        print(f"Error processing task with {agent_name}: {e}")
        # import traceback
        # traceback.print_exc()
        return {"response": f"Error processing your request with {agent_name}: {str(e)}", "agent_used": agent_name, "trade_proposal": None}


@app.post("/webhook/trade")
async def webhook_trade(payload: TradeExecutionPayload):
    print(f"Received trade execution payload for agent {payload.agent_id}:")
    print(f"  Pair: {payload.currency_pair}, Side: {payload.order_side}, Entry: {payload.entry_price}")
    print(f"  SL: {payload.stop_loss}, TP: {payload.take_profit}, Volume: {payload.volume}")

    # Conceptual external webhook call
    external_webhook_url = "https://api.broker.com/execute_trade" # Example URL
    print(f"CONCEPTUAL WEBHOOK: Would send POST request to {external_webhook_url} with data: {payload.model_dump_json()}")

    # Simulate a response from the (conceptual) broker
    return {
        "message": "Trade execution webhook received and processed conceptually.",
        "status": "success", # or "failed" based on conceptual call
        "trade_details_processed": payload.model_dump()
    }

# Run instructions (as before)
# export PYTHONPATH=$PYTHONPATH:$(pwd)
# uvicorn TradingAgents.fastapi_backend.main:app --reload --port 8000
# Or from TradingAgents/fastapi_backend:
# export PYTHONPATH=$PYTHONPATH:$(pwd)/../..
# uvicorn main:app --reload --port 8000
