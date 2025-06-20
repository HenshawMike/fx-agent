from typing import Dict, List, TypedDict, Any, Optional # Corrected import for Optional
import operator # For StateGraph update operations

from langgraph.graph import StateGraph, END

from tradingagents.broker_interface.base import BrokerInterface
# Import our new agents and states
from tradingagents.forex_master.forex_master_agent import ForexMasterAgent
from tradingagents.forex_agents import ( # Updated import style
    DayTraderAgent,
    SwingTraderAgent,
    ScalperAgent,
    PositionTraderAgent
)
from tradingagents.forex_meta.trade_meta_agent import ForexMetaAgent
from tradingagents.forex_utils.forex_states import (
    ForexSubAgentTask,
    ForexTradeProposal,
    AggregatedForexProposals,
    ForexFinalDecision
)
import datetime # For default timestamp

# Define the State for our Forex graph
class ForexGraphState(TypedDict):
    currency_pair: str
    current_simulated_time: str # ISO format string

    # From Master Agent (Initial Processing)
    sub_agent_tasks: List[ForexSubAgentTask]
    market_regime: str

    # For collecting proposals from sub-agents
    # We'll have specific keys for each agent's proposal for simplicity in this skeleton
    scalper_proposal: Optional[ForexTradeProposal]
    day_trader_proposal: Optional[ForexTradeProposal]
    swing_trader_proposal: Optional[ForexTradeProposal]
    position_trader_proposal: Optional[ForexTradeProposal] # Added for PositionTrader
    # This list will be populated by the master_aggregation_node based on above
    proposals_from_sub_agents: List[ForexTradeProposal]

    # From Master Agent (Aggregation)
    aggregated_proposals_for_meta_agent: Optional[AggregatedForexProposals]

    # From Meta Agent
    forex_final_decision: Optional[ForexFinalDecision]

    # To track errors or issues if any node fails
    error_message: Optional[str]


class ForexTradingGraph:
    def __init__(self, broker: BrokerInterface): # Added broker argument
        print("Initializing ForexTradingGraph...")
        self.broker = broker # Store the broker
        self.master_agent = ForexMasterAgent()
        # Pass broker to agents that need it
        self.scalper_agent = ScalperAgent(broker=self.broker)
        self.day_trader_agent = DayTraderAgent(broker=self.broker)
        self.swing_trader_agent = SwingTraderAgent(broker=self.broker)
        self.position_trader_agent = PositionTraderAgent(broker=self.broker) # Added PositionTrader
        self.meta_agent = ForexMetaAgent()

        self.graph = self._setup_graph()
        print("ForexTradingGraph: Graph setup complete.")

    def _setup_graph(self) -> StateGraph:
        # Define the state merger/updater logic if needed, default is dict.update
        # For lists like proposals_from_sub_agents, if nodes return partial lists,
        # a custom merger might be needed. But here, master_aggregation_node creates the full list.

        # graph_state_merger = operator.add # Example, not suitable for TypedDict state generally
        # For TypedDict, the default update mechanism (merging dictionaries) is usually fine
        # if nodes return dicts with keys corresponding to ForexGraphState fields.

        builder = StateGraph(ForexGraphState)

        # Add Nodes
        builder.add_node("master_initial_processing", self.master_agent.initial_processing_node)
        builder.add_node("scalper_processing", self._run_scalper)
        builder.add_node("day_trader_processing", self._run_day_trader)
        builder.add_node("swing_trader_processing", self._run_swing_trader)
        builder.add_node("position_trader_processing", self._run_position_trader) # Added PositionTrader
        # Ensure this node name matches the method name for the wrapper
        builder.add_node("master_aggregation_wrapper", self._run_master_aggregation_wrapper)
        builder.add_node("meta_agent_evaluation", self.meta_agent.evaluate_proposals)

        # Define Edges
        builder.set_entry_point("master_initial_processing")

        builder.add_edge("master_initial_processing", "scalper_processing")
        builder.add_edge("scalper_processing", "day_trader_processing")
        builder.add_edge("day_trader_processing", "swing_trader_processing")
        builder.add_edge("swing_trader_processing", "position_trader_processing") # PositionTrader after Swing

        # After all relevant sub-agents have run, go to master_aggregation_wrapper
        builder.add_edge("position_trader_processing", "master_aggregation_wrapper") # From PositionTrader

        builder.add_edge("master_aggregation_wrapper", "meta_agent_evaluation")

        # The meta_agent_evaluation is the final step in this simple flow
        builder.add_edge("meta_agent_evaluation", END)

        return builder.compile()

    def _run_day_trader(self, state: ForexGraphState) -> Dict[str, Any]:
        print("ForexTradingGraph: Running Day Trader...")
        # Find the DayTrader task from sub_agent_tasks
        day_task = None
        for task in state.get("sub_agent_tasks", []):
            # This matching is simplistic; real tasks might have agent_type field
            if "task_day_" in task.get("task_id", ""):
                day_task = task
                break

        if day_task:
            # The agent expects its task under a specific key in a new state dict
            # It returns a dict like {"day_trader_proposal": ...}
            # This will be merged into the main graph state by LangGraph
            # Pass along the whole state as agents might need other info like current_simulated_time
            return self.day_trader_agent.process_task({"current_day_trader_task": day_task, **state})
        else:
            print("ForexTradingGraph: No Day Trader task found.")
            # Ensure the key is part of the output so StateGraph can merge it.
            return {"day_trader_proposal": None, "error_message": state.get("error_message")}


    def _run_swing_trader(self, state: ForexGraphState) -> Dict[str, Any]:
        print("ForexTradingGraph: Running Swing Trader...")
        swing_task = None
        for task in state.get("sub_agent_tasks", []):
            if "task_swing_" in task.get("task_id", ""):
                swing_task = task
                break

        if swing_task:
            return self.swing_trader_agent.process_task({"current_swing_trader_task": swing_task, **state})
        else:
            print("ForexTradingGraph: No Swing Trader task found.")
            return {"swing_trader_proposal": None, "error_message": state.get("error_message")}

    def _run_scalper(self, state: ForexGraphState) -> Dict[str, Any]:
        print("ForexTradingGraph: Running Scalper...")
        scalper_task = None
        for task in state.get("sub_agent_tasks", []):
            if "task_scalp_" in task.get("task_id", ""):
                scalper_task = task
                break

        if scalper_task:
            return self.scalper_agent.process_task({"current_scalper_task": scalper_task, **state})
        else:
            print("ForexTradingGraph: No Scalper task found.")
            return {"scalper_proposal": None}

    def _run_master_aggregation_wrapper(self, state: ForexGraphState) -> Dict[str, Any]:
        print("ForexTradingGraph: Master Aggregation Wrapper collecting proposals...")
        proposals: List[ForexTradeProposal] = []

        # Collect proposals from all agents that might have run
        if state.get("scalper_proposal"):
            proposals.append(state["scalper_proposal"])
        if state.get("day_trader_proposal"):
            proposals.append(state["day_trader_proposal"])
        if state.get("swing_trader_proposal"):
            proposals.append(state["swing_trader_proposal"])
        if state.get("position_trader_proposal"): # Added PositionTrader
            proposals.append(state["position_trader_proposal"])

        master_aggregation_input_state = state.copy()
        master_aggregation_input_state["proposals_from_sub_agents"] = proposals

        return self.master_agent.aggregation_node(master_aggregation_input_state)


    def invoke_graph(self, currency_pair: str, simulated_time_iso: str) -> Optional[ForexFinalDecision]:
        print(f"ForexTradingGraph: Invoking graph for {currency_pair} at {simulated_time_iso}")
        initial_state = ForexGraphState(
            currency_pair=currency_pair,
            current_simulated_time=simulated_time_iso,
            sub_agent_tasks=[],
            market_regime="Unknown", # Master will assess
            scalper_proposal=None,
            day_trader_proposal=None,
            swing_trader_proposal=None,
            position_trader_proposal=None, # Added for PositionTrader
            proposals_from_sub_agents=[], # Initialize as empty list
            aggregated_proposals_for_meta_agent=None,
            forex_final_decision=None,
            error_message=None
        )

        # Ensure all keys are present in the initial state for TypedDict validation by Langgraph
        # Even if Optional, they should be explicitly None if not set.
        # The above initialization handles this correctly for Optional fields.

        final_state_dict = self.graph.invoke(initial_state) # LangGraph returns a dict

        # Convert dict back to TypedDict for type safety, though it's mostly for static analysis
        # final_state: ForexGraphState = final_state_dict
        # No, LangGraph StateGraph already works with TypedDicts if defined.
        # The output of invoke will match the structure of ForexGraphState.

        if final_state_dict.get("error_message"):
            print(f"Graph execution error: {final_state_dict['error_message']}")
            return None # Or raise an exception

        print(f"ForexTradingGraph: Graph invocation complete. Final decision: {final_state_dict.get('forex_final_decision')}")
        return final_state_dict.get("forex_final_decision")

# Example of how this might be run (will be in the test script)
if __name__ == '__main__':
    print("Manual test of ForexTradingGraph setup:")
    # Import and instantiate the dummy/simulated broker
    from tradingagents.broker_interface.simulated_broker import SimulatedBroker

    sim_broker = SimulatedBroker()
    # IMPORTANT: Update current time in sim_broker for testing get_current_price & get_historical_data
    # Use a fixed time for repeatable direct tests, or now() for dynamic.
    # Using a fixed time similar to what run_forex_test_graph.py might use.
    test_time_dt = datetime.datetime(2023, 10, 27, 10, 0, 0, tzinfo=datetime.timezone.utc)
    sim_broker.update_current_time(test_time_dt.timestamp())

    forex_graph_instance = ForexTradingGraph(broker=sim_broker) # Pass broker

    # Test invocation using the same fixed time for consistency in this direct test
    dummy_time_iso = test_time_dt.isoformat()
    decision = forex_graph_instance.invoke_graph("EURUSD", dummy_time_iso)

    if decision:
        print("\n--- Final Decision from Graph (forex_trading_graph.py direct run) ---")
        # decision is ForexFinalDecision (a TypedDict)
        for key, value in decision.items(): # Iterate through TypedDict items
            print(f"{key}: {value}")
    else:
        print("\n--- No decision or error in graph (forex_trading_graph.py direct run) ---")

def _run_position_trader(self, state: ForexGraphState) -> Dict[str, Any]:
    print("ForexTradingGraph: Running Position Trader...")
    position_task = None
    for task in state.get("sub_agent_tasks", []):
        if "task_pos_" in task.get("task_id", ""): # Or "task_position_"
            position_task = task
            break

    if position_task:
        return self.position_trader_agent.process_task({"current_position_trader_task": position_task, **state})
    else:
        print("ForexTradingGraph: No Position Trader task found.")
        return {"position_trader_proposal": None}
