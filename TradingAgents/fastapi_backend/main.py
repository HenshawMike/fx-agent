from fastapi import FastAPI
from pydantic import BaseModel
import datetime
import random # For dummy broker data
import os # <--- ADDED IMPORT OS
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

# Import MT5Broker
try:
    from TradingAgents.tradingagents.broker_interface.mt5_broker import MT5Broker, MT5_AVAILABLE
except ImportError as e:
    print(f"Error importing MT5Broker: {e}")
    MT5Broker = None # type: ignore
    MT5_AVAILABLE = False

app = FastAPI()

# --- MT5 Credentials Model ---
class MT5Credentials(BaseModel):
    login: int
    password: str
    server: str
    path: Optional[str] = None

class MT5CredentialsResponse(BaseModel):
    login: Optional[int] = None
    server: Optional[str] = None
    path: Optional[str] = None
    connected: bool
    message: str
    mt5_library_available: bool

# --- Global MT5 Broker Instance ---
# Initialize with no credentials; they will be set via API
# Agents will use this shared instance.
# We use a placeholder agent_id for now, can be configured if needed per agent later.
if MT5Broker:
    # Attempt to initialize with environment variables as a fallback/default
    # This aligns with existing practices in MT5_TEST_GUIDE.md
    env_mt5_login_str = os.getenv("MT5_LOGIN")
    env_mt5_password = os.getenv("MT5_PASSWORD")
    env_mt5_server = os.getenv("MT5_SERVER")
    env_mt5_path = os.getenv("MT5_PATH")

    initial_creds_available = False
    if env_mt5_login_str and env_mt5_password and env_mt5_server:
        try:
            initial_login = int(env_mt5_login_str)
            initial_credentials = {
                "login": initial_login,
                "password": env_mt5_password,
                "server": env_mt5_server,
                "path": env_mt5_path
            }
            shared_mt5_broker = MT5Broker(agent_id="FastAPIGlobalAgent")
            print("Attempting to connect shared MT5 broker with environment variables...")
            if shared_mt5_broker.connect(initial_credentials):
                print("Shared MT5 broker connected successfully using environment variables.")
            else:
                print("Failed to connect shared MT5 broker using environment variables. It will remain disconnected until new credentials are provided via API.")
            initial_creds_available = True
        except ValueError:
            print("MT5_LOGIN environment variable is not a valid integer. Shared MT5 broker will be initialized without initial connection attempt.")
            shared_mt5_broker = MT5Broker(agent_id="FastAPIGlobalAgent")
    else:
        print("MT5 environment variables (MT5_LOGIN, MT5_PASSWORD, MT5_SERVER) not fully set. Shared MT5 broker will be initialized without initial connection attempt.")
        shared_mt5_broker = MT5Broker(agent_id="FastAPIGlobalAgent")
else:
    shared_mt5_broker = None # type: ignore
    print("MT5Broker class not available. MT5 functionality will be disabled.")

# --- Dummy Broker Implementation (fallback if MT5Broker is not used or fails) ---
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

# --- API Endpoints for MT5 Settings ---
@app.post("/settings/mt5_credentials", response_model=MT5CredentialsResponse)
async def set_mt5_credentials(credentials: MT5Credentials):
    if not shared_mt5_broker:
        return MT5CredentialsResponse(
            connected=False,
            message="MT5Broker is not available in the backend.",
            mt5_library_available=MT5_AVAILABLE
        )

    # Disconnect if already connected with potentially different credentials
    if shared_mt5_broker._connected:
        shared_mt5_broker.disconnect()

    creds_dict = {
        "login": credentials.login,
        "password": credentials.password,
        "server": credentials.server,
        "path": credentials.path
    }

    print(f"Attempting to connect MT5 with new credentials for login: {credentials.login}")
    connection_success = shared_mt5_broker.connect(creds_dict)

    if connection_success:
        return MT5CredentialsResponse(
            login=shared_mt5_broker.credentials.get('login'),
            server=shared_mt5_broker.credentials.get('server'),
            path=shared_mt5_broker.credentials.get('path'),
            connected=True,
            message="MT5 connected successfully.",
            mt5_library_available=MT5_AVAILABLE
        )
    else:
        last_error = ""
        if MT5_AVAILABLE and hasattr(shared_mt5_broker.mt5, 'last_error'): # Access mt5 attribute of broker instance
            error_code, error_message = shared_mt5_broker.mt5.last_error()
            last_error = f" Error: {error_message} (Code: {error_code})"

        return MT5CredentialsResponse(
            login=credentials.login, # Return submitted login
            server=credentials.server, # Return submitted server
            path=credentials.path, # Return submitted path
            connected=False,
            message=f"Failed to connect to MT5.{last_error}",
            mt5_library_available=MT5_AVAILABLE
        )

@app.get("/settings/mt5_credentials", response_model=MT5CredentialsResponse)
async def get_mt5_settings():
    if not shared_mt5_broker:
        return MT5CredentialsResponse(
            connected=False,
            message="MT5Broker is not available in the backend.",
            mt5_library_available=MT5_AVAILABLE
        )

    is_connected = shared_mt5_broker._connected
    current_creds = shared_mt5_broker.credentials

    return MT5CredentialsResponse(
        login=current_creds.get('login') if current_creds else None,
        server=current_creds.get('server') if current_creds else None,
        path=current_creds.get('path') if current_creds else None,
        connected=is_connected,
        message="MT5 connection status retrieved." if is_connected else "MT5 is not currently connected.",
        mt5_library_available=MT5_AVAILABLE
    )

# --- Agent Instantiation ---
# Determine which broker to use
active_broker_instance: Optional[BrokerInterface] = None
if shared_mt5_broker and shared_mt5_broker.mt5_available: # Prioritize MT5 if available
    print("Using shared_mt5_broker for agents.")
    active_broker_instance = shared_mt5_broker
else:
    print("MT5Broker not available or MT5 library not found. Falling back to DummyBroker for agents.")
    active_broker_instance = DummyBroker()


try:
    # Ensure active_broker_instance is not None before passing to agents
    if active_broker_instance is None:
        print("CRITICAL ERROR: No broker instance available (neither MT5 nor Dummy). Agents cannot be initialized.")
        # Depending on desired behavior, could raise an error or try to default to DummyBroker again
        # For now, let agents be uninitialized or error out if this happens.
        scalper_agent = None # type: ignore
        day_trader_agent = None # type: ignore
        swing_trader_agent = None # type: ignore
        position_trader_agent = None # type: ignore
    else:
        scalper_agent = ScalperAgent(broker=active_broker_instance, publisher=None) # type: ignore
        day_trader_agent = DayTraderAgent(broker=active_broker_instance, publisher=None) # type: ignore
        swing_trader_agent = SwingTraderAgent(broker=active_broker_instance, publisher=None) # type: ignore
        position_trader_agent = PositionTraderAgent(broker=active_broker_instance, publisher=None) # type: ignore
        print(f"Trading agents instantiated successfully with {'MT5Broker' if isinstance(active_broker_instance, MT5Broker) else 'DummyBroker'}.")

except Exception as e:
    print(f"Failed to instantiate agents: {e}")
    scalper_agent = ScalperAgent(); day_trader_agent = DayTraderAgent(); swing_trader_agent = SwingTraderAgent(); position_trader_agent = PositionTraderAgent() # Fallback to default init


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
